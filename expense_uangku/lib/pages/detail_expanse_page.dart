import 'package:expense_uangku/models/expanse.dart';
import 'package:expense_uangku/providers/ExpanseProvider.dart';
import 'package:expense_uangku/providers/transaction_provider.dart';
import 'package:expense_uangku/services/expanse_api.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart'; // ✅ Jangan lupa import

class DetailExpansePage extends StatefulWidget {
  final int expanseId;

  const DetailExpansePage({super.key, required this.expanseId});

  @override
  State<DetailExpansePage> createState() => _DetailExpansePageState();
}

class _DetailExpansePageState extends State<DetailExpansePage> {
  final descC = TextEditingController();
  final amountC = TextEditingController();

  DateTime selectedDate = DateTime.now();
  String? selectedCategory;
  String? selectedType;

  bool isLoading = true;
  Expanse? currentExpanse;

  final categories = ["Makan", "Transportasi", "Belanja", "Gaji", "Lainnya"];
  final types = ["Income", "Expense"];

  final Map<String, Map<String, dynamic>> categoryMap = {
    "Makan": {"icon": Icons.fastfood, "color": Colors.redAccent},
    "Transportasi": {"icon": Icons.directions_bus, "color": Colors.blueAccent},
    "Belanja": {"icon": Icons.shopping_bag, "color": Colors.purple},
    "Gaji": {"icon": Icons.attach_money, "color": Colors.green},
    "Lainnya": {"icon": Icons.category, "color": Colors.grey},
  };

  @override
  void initState() {
    super.initState();
    _loadExpanseData();

    amountC.addListener(() {
      final text = amountC.text.replaceAll('.', '').replaceAll('Rp', '').trim();
      if (text.isEmpty) return;
      final value = int.tryParse(text);
      if (value == null) return;
      final formatted = formatNumber(value);
      if (formatted != amountC.text) {
        amountC.value = amountC.value.copyWith(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
      }
    });
  }

  Future<void> _loadExpanseData() async {
    setState(() => isLoading = true);

    try {
      final expanse = await ExpanseService().getExpanse(widget.expanseId);

      if (expanse != null) {
        setState(() {
          currentExpanse = expanse;
          selectedCategory = expanse.category;
          selectedType = expanse.type;
          descC.text = expanse.description;
          selectedDate = expanse.date;
          amountC.text = formatNumber(expanse.amount);
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Data tidak ditemukan")),
          );
          context.pop();
        }
      }
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  String formatNumber(int value) {
    final formatter = NumberFormat.decimalPattern('id_ID');
    return formatter.format(value);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text(
            'Detail Expanse',
            style: GoogleFonts.montserrat(
              textStyle: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.blueAccent,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final icon = categoryMap[selectedCategory]!["icon"] as IconData;
    final color = categoryMap[selectedCategory]!["color"] as Color;

    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Detail Expanse',
          style: GoogleFonts.montserrat(
            textStyle: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Gap(20),
              CircleAvatar(
                radius: 50,
                backgroundColor: color.withOpacity(0.2),
                child: Icon(icon, size: 50, color: color),
              ),
              const Gap(25),

              _dropdown(
                hint: "Kategori",
                value: selectedCategory,
                items: categories,
                onChanged: (v) => setState(() => selectedCategory = v),
              ),
              const Gap(15),

              _input(
                  controller: amountC,
                  hint: "Amount (Rp.)",
                  keyboardType: TextInputType.number),
              const Gap(15),

              _dropdown(
                hint: "Income atau Expense",
                value: selectedType,
                items: types,
                onChanged: (v) => setState(() => selectedType = v),
              ),
              const Gap(15),

              GestureDetector(
                onTap: () async {
                  final result = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (result != null) setState(() => selectedDate = result);
                },
                child: Container(
                  height: 55,
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  alignment: Alignment.centerLeft,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: Text(
                    "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
                    style: GoogleFonts.poppins(
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const Gap(15),

              _input(controller: descC, hint: "Description", maxLines: 3),
              const Gap(25),

              // ✅ UPDATE BUTTON - IMPLEMENT LOGIC
              ElevatedButton(
                onPressed: () async {
                  final rawAmount = amountC.text.replaceAll('.', '');
                  final amount = int.tryParse(rawAmount) ?? 0;

                  // Validasi
                  if (selectedCategory == null ||
                      selectedType == null ||
                      amount <= 0 ||
                      descC.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Lengkapi semua field")),
                    );
                    return;
                  }

                  // Show loading
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                  );

                  try {
                    // ✅ Buat object Expanse baru dengan data yang diupdate
                    final updatedExpanse = Expanse(
                      id: widget.expanseId,
                      userId: currentExpanse!.userId,
                      category: selectedCategory!,
                      type: selectedType!,
                      amount: amount,
                      description: descC.text.trim(),
                      date: selectedDate,
                    );

                    // ✅ Update via provider
                    final expanseProvider =
                        Provider.of<ExpanseProvider>(context, listen: false);
                    final transactionProvider =
                        Provider.of<TransactionProvider>(context,
                            listen: false);

                    final success = await expanseProvider.updateExpanse(
                      widget.expanseId,
                      updatedExpanse,
                    );

                    // Close loading
                    if (context.mounted) Navigator.pop(context);

                    if (success) {
                      // ✅ Refresh transaction summary
                      await transactionProvider.refreshAfterAdd();

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Berhasil update data!"),
                            backgroundColor: Colors.green,
                            duration: Duration(seconds: 2),
                          ),
                        );
                        context.pop(true); // ✅ Kembali dengan signal berhasil
                      }
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Gagal update data"),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    // Close loading
                    if (context.mounted) Navigator.pop(context);

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Error: $e"),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Update Expanse",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),

              const Gap(10),

              // ✅ DELETE BUTTON - IMPLEMENT LOGIC
              TextButton(
                onPressed: () async {
                  // ✅ Konfirmasi delete
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(
                        "Hapus Transaksi?",
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      content: Text(
                        "Data yang dihapus tidak bisa dikembalikan.",
                        style: GoogleFonts.poppins(),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(
                            "Batal",
                            style: GoogleFonts.poppins(color: Colors.grey),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          child: Text(
                            "Hapus",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );

                  if (confirm != true) return;

                  // Show loading
                  if (mounted) {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => const Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  try {
                    // ✅ Delete via provider
                    final expanseProvider =
                        Provider.of<ExpanseProvider>(context, listen: false);
                    final transactionProvider =
                        Provider.of<TransactionProvider>(context,
                            listen: false);

                    final success =
                        await expanseProvider.deleteExpanse(widget.expanseId);

                    // Close loading
                    if (context.mounted) Navigator.pop(context);

                    if (success) {
                      // ✅ Refresh transaction summary
                      await transactionProvider.refreshAfterAdd();

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Berhasil menghapus data!"),
                            backgroundColor: Colors.green,
                            duration: Duration(seconds: 2),
                          ),
                        );
                        context.pop(true); // ✅ Kembali dengan signal berhasil
                      }
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Gagal menghapus data"),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    // Close loading
                    if (context.mounted) Navigator.pop(context);

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Error: $e"),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: Text(
                  "Delete Expanse",
                  style: GoogleFonts.montserrat(
                    textStyle: const TextStyle(
                      color: Colors.red,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _input({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: GoogleFonts.poppins(
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black,
        ),
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(
          textStyle: const TextStyle(
            color: Colors.grey,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blue, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      ),
    );
  }

  Widget _dropdown({
    required String hint,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      height: 55,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(
            hint,
            style: GoogleFonts.poppins(
              textStyle: const TextStyle(
                  color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ),
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
