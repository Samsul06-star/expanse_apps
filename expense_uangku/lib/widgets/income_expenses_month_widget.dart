import 'package:expense_uangku/models/expanse.dart';
import 'package:expense_uangku/providers/ExpanseProvider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../../../../core/helpers/app_colors.dart';

class IncomeExpensesWidget extends StatefulWidget {
  const IncomeExpensesWidget({super.key});

  final Color incomeColor = AppColors.contentColorGreen;
  final Color expenseColor = AppColors.contentColorRed;

  @override
  State<IncomeExpensesWidget> createState() => _IncomeExpensesWidgetState();
}

class _IncomeExpensesWidgetState extends State<IncomeExpensesWidget> {
  final double barWidth = 7;
  final NumberFormat currencyFormat = NumberFormat('#,###');

  // ✅ Group data per hari
  List<Map<String, dynamic>> groupDataByDay(List<Expanse> expenses) {
    Map<String, Map<String, double>> temp = {};

    for (var e in expenses) {
      final dateKey = DateFormat('yyyy-MM-dd').format(e.date);
      temp.putIfAbsent(dateKey, () => {"Income": 0.0, "Expense": 0.0});
      temp[dateKey]![e.type] = temp[dateKey]![e.type]! + e.amount.toDouble();
    }

    var sortedKeys = temp.keys.toList()..sort();

    return sortedKeys.map((k) {
      return {
        "date": k,
        "Income": temp[k]!["Income"]!,
        "Expense": temp[k]!["Expense"]!,
      };
    }).toList();
  }

  // ✅ Generate bar groups
  List<BarChartGroupData> generateBarGroups(
      List<Map<String, dynamic>> groupedData) {
    return List.generate(groupedData.length, (i) {
      final income = groupedData[i]["Income"]!;
      final expense = groupedData[i]["Expense"]!;

      return BarChartGroupData(
        x: i,
        barsSpace: 4,
        barRods: [
          BarChartRodData(
            toY: income,
            color: widget.incomeColor,
            width: barWidth,
          ),
          BarChartRodData(
            toY: expense,
            color: widget.expenseColor,
            width: barWidth,
          ),
        ],
      );
    });
  }

  double getAdaptiveFontSize(double amount) {
    final length = amount.toInt().toString().length;
    if (length <= 4) return 12;
    if (length <= 6) return 11;
    if (length <= 8) return 10;
    if (length <= 10) return 9;
    return 8;
  }

  @override
  Widget build(BuildContext context) {
    final expanseProvider = Provider.of<ExpanseProvider>(context);
    final groupedData = groupDataByDay(expanseProvider.expenses);

    if (groupedData.isEmpty) {
      return Center(
        child: Lottie.asset(
          'assets/images/transaksi.json',
          width: 300,
          height: 300,
          fit: BoxFit.fill,
        ),
      );
    }

    final barGroups = generateBarGroups(groupedData);
    final maxY = groupedData
        .map((e) => e["Income"]! > e["Expense"]! ? e["Income"]! : e["Expense"]!)
        .reduce((a, b) => a > b ? a : b);

    return AspectRatio(
      aspectRatio: 1.2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Income & Expenses",
              style: TextStyle(color: Colors.white, fontSize: 22),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: BarChart(
                BarChartData(
                  maxY: maxY * 1.2,
                  barGroups: barGroups,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final value = rod.toY;
                        return BarTooltipItem(
                          currencyFormat.format(value),
                          TextStyle(
                            color: Colors.white,
                            fontSize: getAdaptiveFontSize(value),
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) =>
                            _leftTitles(value, meta),
                        reservedSize: 45,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) =>
                            _bottomTitles(value, meta, groupedData),
                        reservedSize: 28,
                      ),
                    ),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _leftTitles(double value, TitleMeta meta) {
    final intValue = value.toInt();
    String formatted;

    if (intValue >= 1000000) {
      formatted = "${(intValue / 1000000).toStringAsFixed(1)}M";
    } else if (intValue >= 1000) {
      formatted = "${(intValue / 1000).round()}K";
    } else {
      formatted = intValue.toString();
    }

    return SideTitleWidget(
      meta: meta,
      space: 4,
      child: Text(
        formatted,
        style: const TextStyle(
          color: Colors.grey,
          fontWeight: FontWeight.bold,
          fontSize: 9,
        ),
      ),
    );
  }

  Widget _bottomTitles(
      double value, TitleMeta meta, List<Map<String, dynamic>> groupedData) {
    int index = value.toInt();
    if (index < 0 || index >= groupedData.length) return const SizedBox();

    String day = groupedData[index]["date"].split('-')[2];

    return SideTitleWidget(
      meta: meta,
      space: 4,
      child: Text(
        day,
        style: const TextStyle(
          color: Colors.grey,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
