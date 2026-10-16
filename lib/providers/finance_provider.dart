import 'package:flutter/foundation.dart';

import '../models/campaign.dart';
import '../models/deadline.dart';
import '../models/expense.dart';
import '../models/income.dart';
import '../repositories/campaign_repository.dart';
import '../repositories/deadline_repository.dart';
import '../repositories/expense_repository.dart';
import '../repositories/income_repository.dart';

/// Totales del mes para la tarjeta hero del dashboard.
class MonthSummary {
  const MonthSummary({
    required this.gross,
    required this.tax,
    required this.agency,
    required this.expenses,
    required this.vatRecoverable,
    this.otherIncome = 0,
  });

  /// Facturado bruto de campañas.
  final double gross;
  final double tax;
  final double agency;
  final double expenses;
  final double vatRecoverable;

  /// Ingresos netos de otros trabajos: entran íntegros, sin IVA ni IRPF.
  final double otherIncome;

  /// Todo lo que entra este mes: bruto de campañas + ingresos netos.
  double get totalIn => gross + otherIncome;

  double get net =>
      (gross - tax - agency - expenses + otherIncome).clamp(0, double.infinity);

  double _pct(double v) => totalIn == 0 ? 0 : (v / totalIn).clamp(0, 1);
  double get netPct => _pct(net);
  double get taxPct => _pct(tax);
  double get agencyPct => _pct(agency);
  double get expensesPct => _pct(expenses);

  static const empty = MonthSummary(
    gross: 0,
    tax: 0,
    agency: 0,
    expenses: 0,
    vatRecoverable: 0,
  );
}

class FinanceProvider extends ChangeNotifier {
  FinanceProvider({
    CampaignRepository? campaigns,
    ExpenseRepository? expenses,
    DeadlineRepository? deadlines,
    IncomeRepository? incomes,
  }) : _campaigns = campaigns ?? CampaignRepository(),
       _expenses = expenses ?? ExpenseRepository(),
       _deadlines = deadlines ?? DeadlineRepository(),
       _incomes = incomes ?? IncomeRepository();

  final CampaignRepository _campaigns;
  final ExpenseRepository _expenses;
  final DeadlineRepository _deadlines;
  final IncomeRepository _incomes;

  List<Campaign> _all = [];
  Map<int, List<Deliverable>> _deliverables = {};
  List<Expense> _expenseList = [];
  List<Income> _incomeList = [];
  bool _loaded = false;
  bool _hideAmounts = false;
  CampaignStatus? _filter = CampaignStatus.pending;

  bool get loaded => _loaded;
  bool get hideAmounts => _hideAmounts;
  CampaignStatus? get filter => _filter;
  List<Campaign> get campaigns => _all;
  List<Expense> get expenses => _expenseList;
  List<Income> get incomes => _incomeList;

  List<Campaign> get filtered =>
      _filter == null ? _all : _all.where((c) => c.status == _filter).toList();

  int countFor(CampaignStatus s) => _all.where((c) => c.status == s).length;

  List<Deliverable> deliverablesOf(int campaignId) =>
      _deliverables[campaignId] ?? const [];

  /// Resumen "1 Reel + 2 Stories" de una campaña.
  String deliverableSummary(int campaignId) {
    final list = deliverablesOf(campaignId);
    if (list.isEmpty) return 'Sin entregables';
    return list.take(3).map((d) => d.name).join(' + ') +
        (list.length > 3 ? ' +${list.length - 3}' : '');
  }

  /// Agrega las campañas activas (no cobradas en meses anteriores), los
  /// gastos y los ingresos netos de otros trabajos del mes en curso.
  MonthSummary get monthSummary {
    final now = DateTime.now();
    bool sameMonth(DateTime d) => d.year == now.year && d.month == now.month;

    final active = _all.where(
      (c) => c.status != CampaignStatus.paid || sameMonth(c.createdAt),
    );
    double gross = 0, tax = 0, agency = 0;
    for (final c in active) {
      gross += c.grossFee;
      tax += c.taxCut;
      agency += c.agencyCut;
    }
    final monthExpenses = _expenseList.where((e) => sameMonth(e.date));
    double exp = 0, vat = 0;
    for (final e in monthExpenses) {
      exp += e.deductibleAmount;
      vat += e.recoverableVat;
    }
    final other = _incomeList
        .where((i) => sameMonth(i.date))
        .fold<double>(0, (sum, i) => sum + i.amount);
    return MonthSummary(
      gross: gross,
      tax: tax,
      agency: agency,
      expenses: exp,
      vatRecoverable: vat,
      otherIncome: other,
    );
  }

  Future<void> load() async {
    _all = await _campaigns.all();
    _deliverables = await _campaigns.deliverablesByCampaign();
    _expenseList = await _expenses.all();
    _incomeList = await _incomes.all();
    _loaded = true;
    notifyListeners();
  }

  void toggleHideAmounts() {
    _hideAmounts = !_hideAmounts;
    notifyListeners();
  }

  void setFilter(CampaignStatus? s) {
    _filter = s;
    notifyListeners();
  }

  // ---------- Campañas ----------

  /// Crea la campaña y agenda sus deadlines (draft y publicación si existen).
  /// Devuelve el número de avisos añadidos al calendario.
  Future<int> createCampaign(Campaign c, List<String> deliverables) async {
    final id = await _campaigns.insert(c, deliverables);
    var reminders = 0;
    if (c.draftDeadline != null) {
      await _deadlines.insert(
        Deadline(
          campaignId: id,
          title: 'Entrega Draft a ${c.brand}',
          description: deliverables.isEmpty
              ? null
              : 'Primer borrador: ${deliverables.join(', ')}',
          type: DeadlineType.draft,
          dateTime: c.draftDeadline!,
        ),
        tasks: const ['Subir link de aprobación'],
      );
      reminders++;
    }
    if (c.publishDate != null) {
      await _deadlines.insert(
        Deadline(
          campaignId: id,
          title: 'Publicación ${c.brand}',
          type: DeadlineType.publish,
          dateTime: c.publishDate!,
        ),
        tasks: const ['Programar a hora de máxima audiencia'],
      );
      reminders++;
    }
    await load();
    return reminders;
  }

  Future<void> updateCampaign(Campaign c) async {
    await _campaigns.update(c);
    await load();
  }

  Future<void> setStatus(Campaign c, CampaignStatus status) async {
    var updated = c.copyWith(status: status);
    if (status == CampaignStatus.pending && c.invoiceDate == null) {
      final now = DateTime.now();
      updated = updated.copyWith(
        invoiceDate: now,
        dueDate: now.add(Duration(days: c.terms.days)),
      );
    }
    await _campaigns.update(updated);
    await load();
  }

  Future<void> deleteCampaign(int id) async {
    await _campaigns.delete(id);
    await load();
  }

  Future<void> cycleDeliverable(Deliverable d) async {
    await _campaigns.updateDeliverable(d.copyWith(status: d.status.next));
    await load();
  }

  Future<void> addDeliverable(int campaignId, String name) async {
    await _campaigns.addDeliverable(campaignId, name);
    await load();
  }

  Future<void> deleteDeliverable(int id) async {
    await _campaigns.deleteDeliverable(id);
    await load();
  }

  // ---------- Gastos ----------

  Future<void> addExpense(Expense e) async {
    await _expenses.insert(e);
    await load();
  }

  Future<void> deleteExpense(int id) async {
    await _expenses.delete(id);
    await load();
  }

  // ---------- Otros ingresos ----------

  Future<void> addIncome(Income i) async {
    await _incomes.insert(i);
    await load();
  }

  Future<void> deleteIncome(int id) async {
    await _incomes.delete(id);
    await load();
  }
}
