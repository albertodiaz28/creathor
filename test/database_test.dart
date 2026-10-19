import 'package:creathor/core/db/app_database.dart';
import 'package:creathor/models/campaign.dart';
import 'package:creathor/models/deadline.dart';
import 'package:creathor/models/expense.dart';
import 'package:creathor/models/income.dart';
import 'package:creathor/providers/deadline_provider.dart';
import 'package:creathor/providers/finance_provider.dart';
import 'package:creathor/providers/grocery_provider.dart';
import 'package:flutter_test/flutter_test.dart';

Campaign campaign({
  String brand = 'Nike',
  double gross = 1000,
  double agency = 15,
  double tax = 21,
  CampaignStatus status = CampaignStatus.production,
  DateTime? draft,
  DateTime? publish,
}) => Campaign(
  brand: brand,
  title: 'Campaña $brand',
  grossFee: gross,
  agencyPct: agency,
  taxPct: tax,
  terms: PaymentTerms.days30,
  status: status,
  createdAt: DateTime.now(),
  draftDeadline: draft,
  publishDate: publish,
);

void main() {
  setUp(() async {
    await AppDatabase.init(inMemory: true);
  });

  tearDown(AppDatabase.close);

  group('Base de datos inicial', () {
    test('arranca vacía salvo el catálogo de supermercados', () async {
      final finance = FinanceProvider();
      final grocery = GroceryProvider();
      final deadlines = DeadlineProvider();
      await Future.wait([finance.load(), grocery.load(), deadlines.load()]);

      expect(finance.campaigns, isEmpty);
      expect(finance.expenses, isEmpty);
      expect(finance.incomes, isEmpty);
      expect(grocery.products, isEmpty);
      expect(grocery.cart, isEmpty);
      expect(deadlines.all, isEmpty);
      expect(
        grocery.supermarkets.map((s) => s.name),
        AppDatabase.defaultSupermarkets,
      );
      expect(finance.monthSummary.net, 0);
    });
  });

  group('Campaign split', () {
    test('calcula neto, IVA y agencia', () {
      final c = campaign(gross: 4000, agency: 15, tax: 20);
      expect(c.agencyCut, 600);
      expect(c.taxCut, 800);
      expect(c.net, 2600);
      expect(c.netPct, 65);
    });
  });

  group('FinanceProvider', () {
    test('crea campaña con entregables y deadlines', () async {
      final finance = FinanceProvider();
      final deadlines = DeadlineProvider();
      await finance.load();

      final draft = DateTime.now().add(const Duration(days: 5));
      final reminders = await finance.createCampaign(
        campaign(
          brand: 'Dyson',
          draft: draft,
          publish: draft.add(const Duration(days: 3)),
        ),
        ['1x Reel IG', '3x Stories'],
      );
      await deadlines.load();

      expect(reminders, 2);
      expect(finance.campaigns.length, 1);
      final created = finance.campaigns.single;
      expect(finance.deliverablesOf(created.id!).length, 2);
      expect(deadlines.all.length, 2);
      expect(deadlines.all.map((d) => d.brand), everyElement('Dyson'));
    });

    test('marcar facturada asigna vencimiento según términos', () async {
      final finance = FinanceProvider();
      await finance.load();
      await finance.createCampaign(campaign(brand: 'Sony'), const []);
      final sony = finance.campaigns.single;
      expect(sony.dueDate, isNull);

      await finance.setStatus(sony, CampaignStatus.pending);
      final updated = finance.campaigns.single;
      expect(updated.status, CampaignStatus.pending);
      expect(updated.dueDate!.difference(updated.invoiceDate!).inDays, 30);
    });

    test('borrar campaña elimina entregables en cascada', () async {
      final finance = FinanceProvider();
      await finance.load();
      await finance.createCampaign(campaign(), ['1x TikTok']);
      final id = finance.campaigns.single.id!;
      expect(finance.deliverablesOf(id), isNotEmpty);

      await finance.deleteCampaign(id);
      expect(finance.campaigns, isEmpty);
      expect(finance.deliverablesOf(id), isEmpty);
    });

    test('gastos con IVA del 21%', () async {
      final finance = FinanceProvider();
      await finance.load();
      await finance.addExpense(
        Expense(
          title: 'Micro',
          amount: 121,
          category: ExpenseCategory.equipment,
          date: DateTime.now(),
        ),
      );
      expect(finance.expenses.single.recoverableVat, closeTo(21, 0.001));
      expect(finance.monthSummary.expenses, 121);
    });

    test(
      'gastos del día a día restan de la hucha pero no son fiscales',
      () async {
        final finance = FinanceProvider();
        await finance.load();
        await finance.createCampaign(
          campaign(gross: 1000, agency: 15, tax: 21),
          const [],
        );
        await finance.addExpense(
          Expense(
            title: 'Compra semanal',
            amount: 80,
            category: ExpenseCategory.food,
            date: DateTime.now(),
            deductiblePct: 0,
          ),
        );
        // Luz al 30% por teletrabajo: 30 € deducibles, 70 € personales.
        await finance.addExpense(
          Expense(
            title: 'Luz',
            amount: 100,
            category: ExpenseCategory.utilities,
            date: DateTime.now(),
            deductiblePct: 30,
          ),
        );
        final s = finance.monthSummary;
        expect(finance.expenses.any((e) => e.isPersonal), isTrue);
        expect(s.expenses, 30);
        expect(s.personalExpenses, 150);
        expect(s.vatRecoverable, closeTo(30 * 0.21 / 1.21, 0.001));
        expect(s.tax, 210);
        // 1000 - 210 - 150 - 180 = 460.
        expect(s.net, 460);
      },
    );

    test('el balance puede quedar en negativo', () async {
      final finance = FinanceProvider();
      await finance.load();
      await finance.addExpense(
        Expense(
          title: 'Alquiler',
          amount: 700,
          category: ExpenseCategory.home,
          date: DateTime.now(),
          deductiblePct: 0,
        ),
      );
      expect(finance.monthSummary.net, -700);
    });

    test('otros ingresos se suman netos, sin IVA, IRPF ni agencia', () async {
      final finance = FinanceProvider();
      await finance.load();
      await finance.createCampaign(
        campaign(gross: 1000, agency: 15, tax: 21),
        const [],
      );
      // Neto de la campaña: 1000 - 150 - 210 = 640.
      expect(finance.monthSummary.net, 640);

      await finance.addIncome(
        Income(title: 'Edición freelance', amount: 500, date: DateTime.now()),
      );
      final s = finance.monthSummary;
      expect(s.otherIncome, 500);
      expect(s.tax, 210);
      expect(s.agency, 150);
      expect(s.net, 1140);
      expect(s.totalIn, 1500);

      // Un ingreso de otro mes no cuenta en el resumen actual.
      await finance.addIncome(
        Income(
          title: 'Antiguo',
          amount: 300,
          date: DateTime.now().subtract(const Duration(days: 62)),
        ),
      );
      expect(finance.monthSummary.otherIncome, 500);
      expect(finance.incomes.length, 2);

      final first = finance.incomes.firstWhere((i) => i.title == 'Antiguo');
      await finance.deleteIncome(first.id!);
      expect(finance.incomes.length, 1);
    });
  });

  group('GroceryProvider', () {
    test('compara la cesta entre supermercados', () async {
      final g = GroceryProvider();
      await g.load();
      final ids = {for (final s in g.supermarkets) s.name: s.id!};
      expect(g.selected!.name, 'Mercadona');

      final leche = await g.quickAdd('Leche avena');
      await g.savePrices(leche, {
        ids['Mercadona']!: 1.35,
        ids['Carrefour']!: 1.69,
        ids['Lidl']!: 1.45,
        ids['Dia']!: 1.55,
      });
      final cafe = await g.quickAdd('Café 250g');
      await g.savePrices(cafe, {
        ids['Mercadona']!: 4.20,
        ids['Carrefour']!: 4.95,
        ids['Lidl']!: 4.50,
        ids['Dia']!: 4.80,
      });

      final quotes = g.quotes;
      expect(quotes.first.supermarket.name, 'Mercadona');
      expect(quotes.first.total, closeTo(5.55, 0.001));

      final saving = g.basketSaving!;
      expect(saving.other.name, 'Carrefour');
      expect(saving.saving, closeTo(1.09, 0.001));
    });

    test('quickAdd reutiliza productos y agrupa cantidades', () async {
      final g = GroceryProvider();
      await g.load();

      final p = await g.quickAdd('Hielo 2kg');
      expect(p.prices, isEmpty);
      await g.quickAdd('hielo 2kg');
      expect(g.cart.length, 1);
      expect(g.cart.single.quantity, 2);
    });

    test('limpiar listos elimina solo los marcados', () async {
      final g = GroceryProvider();
      await g.load();
      await g.quickAdd('Uno');
      await g.quickAdd('Dos');
      await g.toggleChecked(g.cart.first);
      expect(await g.clearChecked(), 1);
      expect(g.cart.length, 1);
    });
  });

  group('DeadlineProvider', () {
    test('filtra por tipo y día, y gestiona tareas', () async {
      final p = DeadlineProvider();
      await p.load();
      final today = DateTime.now();
      await p.add(
        Deadline(
          title: 'Rodaje',
          type: DeadlineType.shoot,
          dateTime: DateTime(today.year, today.month, today.day, 11),
        ),
        tasks: ['Cargar baterías'],
      );
      await p.add(
        Deadline(
          title: 'Draft',
          type: DeadlineType.draft,
          dateTime: DateTime(today.year, today.month, today.day, 18),
          awaitingApproval: true,
        ),
      );
      expect(p.all.length, 2);
      expect(p.awaitingApproval.length, 1);

      p.setTypeFilter(DeadlineType.draft);
      expect(p.visible.map((d) => d.title), ['Draft']);
      p.setTypeFilter(null);

      final rodaje = p.all.firstWhere((d) => d.title == 'Rodaje');
      await p.toggleTask(rodaje.tasks.single);
      expect(p.all.firstWhere((d) => d.id == rodaje.id).tasksDone, 1);

      final draft = p.all.firstWhere((d) => d.title == 'Draft');
      await p.toggleDone(draft);
      expect(p.awaitingApproval, isEmpty);
    });
  });
}
