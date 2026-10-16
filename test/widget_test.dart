import 'package:creathor/core/db/app_database.dart';
import 'package:creathor/main.dart';
import 'package:creathor/models/campaign.dart';
import 'package:creathor/models/income.dart';
import 'package:creathor/providers/deadline_provider.dart';
import 'package:creathor/providers/finance_provider.dart';
import 'package:creathor/providers/grocery_provider.dart';
import 'package:creathor/screens/finance/campaign_detail_screen.dart';
import 'package:creathor/screens/finance/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';

/// La cabecera tiene una animación infinita ("Creando"), así que no se puede
/// usar pumpAndSettle; se bombea un tiempo fijo.
Future<void> settle(WidgetTester tester) =>
    tester.pump(const Duration(milliseconds: 600));

/// Monta la app sobre una base de datos en memoria. [prepare] permite crear
/// datos antes de pintar la primera frame.
Future<FinanceProvider> pumpApp(
  WidgetTester tester, {
  Future<void> Function(FinanceProvider finance)? prepare,
}) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final finance = FinanceProvider();
  final grocery = GroceryProvider();
  final deadlines = DeadlineProvider();
  await tester.runAsync(() async {
    await AppDatabase.init(inMemory: true);
    await finance.load();
    if (prepare != null) await prepare(finance);
    await Future.wait([grocery.load(), deadlines.load()]);
  });

  await tester.pumpWidget(
    CreathorApp(finance: finance, grocery: grocery, deadlines: deadlines),
  );
  await settle(tester);
  return finance;
}

/// Desplaza la lista del dashboard hasta que [finder] se construya.
Future<void> scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    300,
    scrollable: find
        .descendant(
          of: find.byType(DashboardScreen),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await settle(tester);
}

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await initializeDateFormatting('es');
  });

  tearDown(AppDatabase.close);

  testWidgets('arranca vacía y navega por las cuatro pestañas', (tester) async {
    await pumpApp(tester);

    expect(find.text('Finanzas & Deals ✨'), findsOneWidget);
    await scrollTo(tester, find.text('Nada por aquí'));
    expect(find.text('Nada por aquí'), findsOneWidget);
    await scrollTo(tester, find.text('Sin otros ingresos este mes'));
    expect(find.text('Sin otros ingresos este mes'), findsOneWidget);

    await tester.tap(find.text('Campaña'));
    await settle(tester);
    expect(find.text('Nueva Colaboración 🤝'), findsOneWidget);

    await tester.tap(find.text('Súper'));
    await settle(tester);
    expect(find.text('Cesta vacía'), findsOneWidget);
    expect(find.text('Mercadona'), findsWidgets);

    await tester.tap(find.text('Deadlines'));
    await settle(tester);
    expect(find.text('Deadlines 📅'), findsOneWidget);
    expect(find.text('Sin entregas en este rango'), findsOneWidget);
  });

  testWidgets('muestra otros ingresos netos en el dashboard', (tester) async {
    await pumpApp(
      tester,
      prepare: (f) => f.addIncome(
        Income(title: 'Clases de edición', amount: 500, date: DateTime.now()),
      ),
    );

    final row = find.text('Clases de edición');
    await scrollTo(tester, row);
    expect(row, findsOneWidget);
    // El formato es_ES separa el símbolo con un espacio duro.
    expect(find.textContaining('+500,00'), findsOneWidget);
  });

  testWidgets('abre el detalle de una campaña desde el dashboard', (
    tester,
  ) async {
    await pumpApp(
      tester,
      prepare: (f) async {
        await f.createCampaign(
          Campaign(
            brand: 'Spotify España',
            title: 'Vibras de Verano',
            grossFee: 3200,
            agencyPct: 15,
            taxPct: 21,
            terms: PaymentTerms.days30,
            status: CampaignStatus.production,
            createdAt: DateTime.now(),
          ),
          ['1x Reel IG'],
        );
        await f.setStatus(f.campaigns.single, CampaignStatus.pending);
      },
    );

    final card = find.text('Spotify España');
    await scrollTo(tester, card);
    await tester.tap(card.first);
    await settle(tester);
    await settle(tester);
    expect(find.byType(CampaignDetailScreen), findsOneWidget);
    expect(find.text('Vibras de Verano'), findsOneWidget);
    expect(find.text('Marcar cobrada'), findsOneWidget);
  });
}
