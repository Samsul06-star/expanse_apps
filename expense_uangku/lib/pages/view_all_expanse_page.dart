import 'package:expense_uangku/providers/ExpanseProvider.dart';
import '../../../../routes/name_routes.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart'; // added import

class CategoryStyle {
  final IconData icon;
  final Color color;

  CategoryStyle({required this.icon, required this.color});
}

class ViewAllExpansePage extends StatelessWidget {
  const ViewAllExpansePage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ExpanseProvider>(context);

    final Map<String, CategoryStyle> categoryMap = {
      "Makan": CategoryStyle(icon: Icons.fastfood, color: Colors.red),
      "Transportasi":
          CategoryStyle(icon: Icons.directions_bus, color: Colors.blue),
      "Belanja": CategoryStyle(icon: Icons.shopping_cart, color: Colors.purple),
      "Gaji": CategoryStyle(icon: Icons.attach_money, color: Colors.green),
      "Lainnya": CategoryStyle(icon: Icons.category, color: Colors.grey),
    };

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'View All Expanse',
          style: GoogleFonts.montserrat(
            textStyle: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : (provider.expenses.isEmpty
              ? Center(
                  child: Lottie.asset(
                    'assets/images/transaksi.json',
                    width: 350,
                    height: 350,
                    fit: BoxFit.fill,
                  ),
                )
              : ListView.builder(
                  itemCount: provider.expenses.length,
                  itemBuilder: (context, index) {
                    final item = provider.expenses[index];
                    final style = categoryMap[item.category] ??
                        CategoryStyle(icon: Icons.category, color: Colors.grey);

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      child: Material(
                        elevation: 10,
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            // send both pathParameters and extra in one goNamed call
                            context.goNamed(
                              NameRoutes.detailExpanse,
                              pathParameters: {'id': item.id.toString()},
                              extra: item,
                            );
                          },
                          child: Container(
                            height: 100,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: style.color,
                            ),
                            child: Row(
                              children: [
                                const Gap(20),
                                CircleAvatar(
                                  maxRadius: 30,
                                  backgroundColor: Colors.white,
                                  child: Icon(style.icon, color: style.color),
                                ),
                                const Gap(10),
                                Text(
                                  item.category,
                                  style: GoogleFonts.montserrat(
                                    textStyle: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      "Rp ${item.amount}",
                                      style: GoogleFonts.poppins(
                                        textStyle: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    const Gap(10),
                                    Text(
                                      DateFormat('dd/MM/yyyy HH:mm')
                                          .format(item.date),
                                      style: GoogleFonts.poppins(
                                        textStyle: const TextStyle(
                                          color: Colors.white54,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const Gap(30),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                )),
    );
  }
}
