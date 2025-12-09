import 'package:expense_uangku/models/expanse.dart';
import 'package:expense_uangku/providers/ExpanseProvider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../../../../core/helpers/app_colors.dart';

class ExpansesDayWidget extends StatefulWidget {
  const ExpansesDayWidget({super.key});

  @override
  State<ExpansesDayWidget> createState() => _ExpansesDayWidgetState();
}

class _ExpansesDayWidgetState extends State<ExpansesDayWidget> {
  List<Color> gradientColors = [
    AppColors.contentColorCyan,
    AppColors.contentColorBlue,
  ];

  List<Expanse> getTodayExpenses(List<Expanse> allExpenses) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return allExpenses.where((exp) {
      final expDate = DateTime(exp.date.year, exp.date.month, exp.date.day);
      return expDate.isAtSameMomentAs(today) && exp.type == "Expense";
    }).toList();
  }

  List<FlSpot> getSpots(List<Expanse> expenses) {
    if (expenses.isEmpty) {
      return [FlSpot(0, 0)];
    }

    Map<int, double> hourlyData = {};

    for (var exp in expenses) {
      final hour = exp.date.hour;
      hourlyData[hour] = (hourlyData[hour] ?? 0) + exp.amount / 1000;
    }

    return hourlyData.entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList()
      ..sort((a, b) => a.x.compareTo(b.x));
  }

  double getMaxY(List<FlSpot> spots) {
    if (spots.isEmpty || spots.first.y == 0) return 6;

    final maxValue = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final buffered = maxValue * 1.3;

    if (buffered < 10) {
      return (buffered / 2).ceil() * 2.0;
    } else if (buffered < 100) {
      return (buffered / 10).ceil() * 10.0;
    } else if (buffered < 1000) {
      return (buffered / 50).ceil() * 50.0;
    } else {
      return (buffered / 100).ceil() * 100.0;
    }
  }

  double getLeftInterval(double maxY) {
    if (maxY <= 6) return 1;
    if (maxY <= 20) return 2;
    if (maxY <= 50) return 5;
    if (maxY <= 100) return 10;
    if (maxY <= 200) return 20;
    if (maxY <= 500) return 50;
    if (maxY <= 1000) return 100;
    return 200;
  }

  @override
  Widget build(BuildContext context) {
    final expanseProvider = Provider.of<ExpanseProvider>(context);
    final todayExpenses = getTodayExpenses(expanseProvider.expenses);
    final spots = getSpots(todayExpenses);
    final maxY = getMaxY(spots);

    return AspectRatio(
      aspectRatio: 1.70,
      child: Padding(
        padding: const EdgeInsets.only(
          right: 18,
          left: 12,
          top: 24,
          bottom: 12,
        ),
        child: todayExpenses.isEmpty
            ? Center(
                child: Lottie.asset(
                  'assets/images/transaksi.json',
                  width: 250,
                  height: 250,
                  fit: BoxFit.fill,
                ),
              )
            : LineChart(mainData(spots, maxY)),
      ),
    );
  }

  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    String text = switch (value.toInt()) {
      0 => "0h",
      6 => "6h",
      12 => "12h",
      18 => "18h",
      23 => "23h",
      _ => "",
    };

    return SideTitleWidget(
      meta: meta,
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          fontSize: 11,
        ),
      ),
    );
  }

  LineChartData mainData(List<FlSpot> spots, double maxY) {
    final leftInterval = getLeftInterval(maxY);

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: leftInterval,
        verticalInterval: 6,
        getDrawingHorizontalLine: (_) =>
            const FlLine(color: AppColors.mainGridLineColor, strokeWidth: 1),
        getDrawingVerticalLine: (_) =>
            const FlLine(color: AppColors.mainGridLineColor, strokeWidth: 1),
      ),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 6,
            getTitlesWidget: bottomTitleWidgets,
            reservedSize: 28,
          ),
        ),
        // ✅ HAPUS LEFT TITLES (angka kiri)
        leftTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: const Color(0xff37434d)),
      ),
      minX: 0,
      maxX: 23,
      minY: 0,
      maxY: maxY,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          gradient: LinearGradient(colors: gradientColors),
          barWidth: 4,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: gradientColors.map((c) => c.withOpacity(0.3)).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
