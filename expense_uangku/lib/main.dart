import 'package:expense_uangku/providers/ExpanseProvider.dart';
import 'package:expense_uangku/providers/transaction_provider.dart';
import 'package:expense_uangku/providers/userProvider.dart';
import 'package:provider/provider.dart';

import 'routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(
        create: (_) =>
            ExpanseProvider()..fetchAllExpanse(), // fetch data dari API
      ),
      ChangeNotifierProvider(
        create: (_) =>
            TransactionProvider()..fetchTransactions(), // fetch data juga
      ),
      ChangeNotifierProvider(create: (_) => UserProvider()),
    ],
    child: MainApp(),
  ));
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: false,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white, // <-- AppBar putih
          elevation: 0, // optional: hilangin shadow
          foregroundColor: Colors.black, // warna teks & icon
        ),
      ),
      routerConfig: appRoutes.router,
    );
  }
}
