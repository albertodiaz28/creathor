import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'core/db/app_database.dart';
import 'core/theme/app_theme.dart';
import 'providers/deadline_provider.dart';
import 'providers/finance_provider.dart';
import 'providers/grocery_provider.dart';
import 'screens/shell/main_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es');
  await AppDatabase.init();

  final finance = FinanceProvider();
  final grocery = GroceryProvider();
  final deadlines = DeadlineProvider();
  await Future.wait([finance.load(), grocery.load(), deadlines.load()]);

  runApp(CreathorApp(finance: finance, grocery: grocery, deadlines: deadlines));
}

class CreathorApp extends StatelessWidget {
  const CreathorApp({
    super.key,
    required this.finance,
    required this.grocery,
    required this.deadlines,
  });

  final FinanceProvider finance;
  final GroceryProvider grocery;
  final DeadlineProvider deadlines;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: finance),
        ChangeNotifierProvider.value(value: grocery),
        ChangeNotifierProvider.value(value: deadlines),
      ],
      child: MaterialApp(
        title: 'Kreator',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        locale: const Locale('es', 'ES'),
        supportedLocales: const [Locale('es', 'ES'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const MainShell(),
      ),
    );
  }
}
