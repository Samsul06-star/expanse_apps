import 'package:expense_uangku/providers/ExpanseProvider.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../routes/name_routes.dart';
import '../widgets/expanses_day_widget.dart';
import '../widgets/income_expenses_month_widget.dart';

class AnalyticPage extends StatelessWidget {
  const AnalyticPage({super.key});

  @override
  Widget build(BuildContext context) {
    final expanseProvider = Provider.of<ExpanseProvider>(context);

    // ✅ Hitung total expense hari ini
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final todayExpenses = expanseProvider.expenses.where((exp) {
      final expDate = DateTime(exp.date.year, exp.date.month, exp.date.day);
      return expDate.isAtSameMomentAs(today) && exp.type == "Expense";
    }).toList();

    final todayTotal = todayExpenses.fold(0, (sum, exp) => sum + exp.amount);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Gap(10),
                  Text(
                    'Analytic Report',
                    style: GoogleFonts.montserrat(
                      textStyle: const TextStyle(
                        color: Colors.black,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey[350],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: IconButton(
                        onPressed: () {
                          context.goNamed(NameRoutes.settingProfile);
                        },
                        icon: const Icon(Icons.settings),
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ✅ Bar Chart Income/Expense per Hari
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              child: Container(
                width: double.infinity,
                height: 500,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: const Color(0xff203858),
                ),
                child: const IncomeExpensesWidget(),
              ),
            ),

            // ✅ Header Hari Ini dengan Total Expense
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Expense per Hari Ini",
                    style: GoogleFonts.montserrat(
                      textStyle: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      NumberFormat.currency(
                        locale: 'id_ID',
                        symbol: 'IDR ',
                        decimalDigits: 0,
                      ).format(todayTotal),
                      style: GoogleFonts.montserrat(
                        decoration: TextDecoration.underline,
                        textStyle: const TextStyle(
                          color: Colors.black26,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ✅ Line Chart Expense per Jam Hari Ini
            Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xff203858),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const ExpansesDayWidget(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
