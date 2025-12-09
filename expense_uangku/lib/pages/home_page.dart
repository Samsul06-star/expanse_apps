import 'package:expense_uangku/providers/ExpanseProvider.dart';
import 'package:expense_uangku/providers/transaction_provider.dart';
import 'package:expense_uangku/providers/userProvider.dart';
import 'package:lottie/lottie.dart';

import '../../../../routes/name_routes.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:expense_uangku/services/users_api.dart';
import '../models/user.dart';

class CategoryStyle {
  final IconData icon;
  final Color color;

  CategoryStyle({required this.icon, required this.color});
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  double _getBalanceFontSize(double balance) {
    final absBalance = balance.abs(); // Ambil nilai absolut

    if (absBalance < 1000000) {
      return 35; // < 1 juta → font 35
    } else if (absBalance < 10000000) {
      return 30; // < 10 juta → font 30
    } else if (absBalance < 100000000) {
      return 26; // < 100 juta → font 26
    } else if (absBalance < 1000000000) {
      return 22; // < 1 miliar → font 22
    } else {
      return 18; // >= 1 miliar → font 18
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUser(context);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // ✅ Reload data setiap kali halaman muncul kembali
    _loadUser(context);
  }

  Future<void> _loadUser(BuildContext context) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    final json = await UsersApi.getUserJson(); // backend kamu
    if (json != null) {
      userProvider.setUser(User.fromJson(json));
    }
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, CategoryStyle> categoryMap = {
      "Makan": CategoryStyle(icon: Icons.fastfood, color: Colors.red),
      "Transportasi":
          CategoryStyle(icon: Icons.directions_bus, color: Colors.blue),
      "Belanja": CategoryStyle(icon: Icons.shopping_cart, color: Colors.purple),
      "Gaji": CategoryStyle(icon: Icons.attach_money, color: Colors.green),
      "Lainnya": CategoryStyle(icon: Icons.category, color: Colors.grey),
    };

    final expanseProvider = Provider.of<ExpanseProvider>(context);
    final transactionProvider = Provider.of<TransactionProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final userName = userProvider.user?.name ?? 'Guest';
// hanya 3 data expanse terbaru
    final latestExpanse = expanseProvider.latestThree;

// summary data
    final totalBalance = transactionProvider.balance;
    final income = transactionProvider.totalIncome;
    final expenses = transactionProvider.totalExpenses;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ================= HEADER =================
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                      radius: 25,
                      backgroundImage:
                          AssetImage("assets/images/samsul_bahri.jpg")),
                  Gap(10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome !',
                        style: GoogleFonts.montserrat(
                          textStyle: const TextStyle(
                            color: Colors.black26,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Gap(5),
                      Text(
                        userName,
                        style: GoogleFonts.montserrat(
                          textStyle: const TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Spacer(),
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
                    )),
                  ),
                ],
              ),
            ),

            // ================= BALANCE CARD =================
            Padding(
              padding: const EdgeInsets.all(20),
              child: PhysicalModel(
                color: Colors.transparent,
                elevation: 10,
                child: Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.blueAccent,
                        Colors.lightBlueAccent,
                      ],
                    ),
                  ),
                  child: Column(
                    children: [
                      const Gap(20),
                      Text(
                        'Total Balance',
                        style: GoogleFonts.montserrat(
                          textStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Gap(10),

                      // ====== TOTAL BALANCE DYNAMIC ======
                      Text(
                        NumberFormat.currency(
                          locale: 'id_ID',
                          symbol: 'Rp. ',
                          decimalDigits: 0,
                        ).format(totalBalance),
                        style: GoogleFonts.poppins(
                          textStyle: TextStyle(
                            color: Colors.white,
                            fontSize: _getBalanceFontSize(
                                totalBalance), // ✅ Dynamic font size
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                      const Gap(20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          // ====== INCOME ======
                          Row(
                            children: [
                              const CircleAvatar(
                                backgroundColor: Colors.white,
                                child: Icon(Icons.arrow_upward_outlined,
                                    color: Colors.green),
                              ),
                              const Gap(10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Income',
                                    style: GoogleFonts.poppins(
                                      textStyle: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 100, // Batasi lebar 100px
                                    child: Text(
                                      NumberFormat.currency(
                                        locale: 'id_ID',
                                        symbol: 'Rp. ',
                                        decimalDigits: 0,
                                      ).format(income),
                                      style: GoogleFonts.poppins(
                                        textStyle: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),

                          // ====== EXPENSES ======
                          Row(
                            children: [
                              const CircleAvatar(
                                backgroundColor: Colors.white,
                                child: Icon(Icons.arrow_downward_outlined,
                                    color: Colors.red),
                              ),
                              const Gap(10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Expenses',
                                    style: GoogleFonts.poppins(
                                      textStyle: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 100, // Batasi lebar 100px
                                    child: Text(
                                      NumberFormat.currency(
                                        locale: 'id_ID',
                                        symbol: 'Rp. ',
                                        decimalDigits: 0,
                                      ).format(expenses),
                                      style: GoogleFonts.poppins(
                                        textStyle: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ================= TRANSACTIONS TITLE =================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Transactions',
                    style: GoogleFonts.montserrat(
                      textStyle: const TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      context.goNamed(NameRoutes.viewAllExpanse);
                    },
                    child: Text(
                      'View All',
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

            // ================= LIST TRANSAKSI -> 3 TERBARU =================

            Expanded(
              child: latestExpanse.isEmpty
                  ? Center(
                      child: Lottie.asset(
                        'assets/images/transaksi.json',
                        width: 350,
                        height: 350,
                        fit: BoxFit.fill,
                      ),
                    )
                  : ListView.builder(
                      itemCount: latestExpanse.length,
                      itemBuilder: (context, index) {
                        final exp = latestExpanse[index];
                        final style = categoryMap[exp.category] ??
                            CategoryStyle(
                                icon: Icons.category, color: Colors.grey);

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
                                context.goNamed(
                                  NameRoutes.detailExpanse,
                                  pathParameters: {
                                    'id': exp.id.toString()
                                  }, // ✅ Kirim ID
                                );
                              },
                              child: Container(
                                height: 100,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  color: style
                                      .color, // Warna container sesuai kategori
                                ),
                                child: Row(
                                  children: [
                                    const Gap(20),
                                    CircleAvatar(
                                      maxRadius: 30,
                                      backgroundColor: Colors.white,
                                      child: Icon(style.icon,
                                          color: style
                                              .color), // Icon sesuai kategori
                                    ),
                                    const Gap(10),
                                    Text(
                                      exp.category,
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          "Rp. ${exp.amount}",
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
                                              .format(exp.date),
                                          style: GoogleFonts.poppins(
                                            textStyle: const TextStyle(
                                              color: Colors.white54,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        )
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
                    ),
            )
          ],
        ),
      ),
    );
  }
}
