import 'package:expense_uangku/providers/ExpanseProvider.dart';
import 'package:expense_uangku/providers/transaction_provider.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class CategoryStyle {
  final IconData icon;
  final Color color;

  CategoryStyle({required this.icon, required this.color});
}

class AddExpansePage extends StatefulWidget {
  const AddExpansePage({super.key});

  @override
  State<AddExpansePage> createState() => _AddExpansePageState();
}

class _AddExpansePageState extends State<AddExpansePage> {
  final amountC = TextEditingController();
  final descC = TextEditingController();

  String? selectedCategory;
  String? selectedType;
  DateTime selectedDate = DateTime.now();

  final categories = ["Makan", "Transportasi", "Belanja", "Gaji", "Lainnya"];
  final types = ["Income", "Expense"];

  final Map<String, CategoryStyle> categoryMap = {
    "Makan": CategoryStyle(icon: Icons.fastfood, color: Colors.red),
    "Transportasi":
        CategoryStyle(icon: Icons.directions_bus, color: Colors.blue),
    "Belanja": CategoryStyle(icon: Icons.shopping_cart, color: Colors.purple),
    "Gaji": CategoryStyle(icon: Icons.attach_money, color: Colors.green),
    "Lainnya": CategoryStyle(icon: Icons.category, color: Colors.grey),
  };

  @override
  void initState() {
    super.initState();

    amountC.addListener(() {
      String text = amountC.text.replaceAll('.', '');
      if (text.isEmpty) return;
      final value = int.tryParse(text);
      if (value == null) return;
      final formatted = NumberFormat.decimalPattern('id_ID').format(value);
      if (formatted != amountC.text) {
        amountC.value = amountC.value.copyWith(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final style = selectedCategory != null
        ? categoryMap[selectedCategory!]!
        : CategoryStyle(icon: Icons.category, color: Colors.grey);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.close),
                  ),
                ),
                const Gap(10),
                Text(
                  'Add Expanse',
                  style: GoogleFonts.montserrat(
                    textStyle: const TextStyle(
                      color: Colors.black,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  textAlign: TextAlign.start,
                ),
                const Gap(25),

                // Preview kategori
                if (selectedCategory != null)
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 25,
                        backgroundColor: style.color,
                        child: Icon(style.icon, color: Colors.white),
                      ),
                      const Gap(10),
                      Text(
                        selectedCategory!,
                        style: GoogleFonts.montserrat(
                          textStyle: const TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    ],
                  ),
                if (selectedCategory != null) const Gap(15),

                // Amount dengan format ribuan
                _input(
                  controller: amountC,
                  hint: "Amount (Rp.)",
                  type: TextInputType.number,
                ),
                const Gap(15),

                // Category dropdown
                _dropdown(
                  hint: "Category",
                  value: selectedCategory,
                  items: categories,
                  onChanged: (v) => setState(() => selectedCategory = v),
                ),
                const Gap(15),

                // Type dropdown
                _dropdown(
                  hint: "Income atau Expense",
                  value: selectedType,
                  items: types,
                  onChanged: (v) => setState(() => selectedType = v),
                ),
                const Gap(15),

                // Date picker
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
                      selectedDate.toUtc().toIso8601String(),
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

                // Description
                _input(
                  controller: descC,
                  hint: "Description",
                  type: TextInputType.multiline,
                  maxLines: 4,
                ),
                const Gap(25),

                ElevatedButton(
                  onPressed: () async {
                    // Parse amount
                    final rawAmount = amountC.text.replaceAll('.', '');
                    final amount = int.tryParse(rawAmount) ?? 0;

                    // Validasi semua field
                    if (selectedCategory == null || selectedCategory!.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text("Pilih kategori terlebih dahulu")),
                      );
                      return;
                    }

                    if (selectedType == null || selectedType!.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text("Pilih tipe (Income/Expense)")),
                      );
                      return;
                    }

                    if (amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text("Masukkan jumlah yang valid")),
                      );
                      return;
                    }

                    if (descC.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text("Deskripsi tidak boleh kosong")),
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
                      // ✅ PAKAI PROVIDER untuk add data
                      final expanseProvider =
                          Provider.of<ExpanseProvider>(context, listen: false);
                      final transactionProvider =
                          Provider.of<TransactionProvider>(context,
                              listen: false);

                      final success = await expanseProvider.addExpanse(
                        category: selectedCategory!,
                        type: selectedType!,
                        amount: amount,
                        description: descC.text.trim(),
                        date: selectedDate,
                      );

                      // Close loading
                      if (context.mounted) Navigator.pop(context);

                      if (success) {
                        // ✅ Refresh transaction provider juga biar balance update
                        await transactionProvider.refreshAfterAdd();

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Berhasil menambahkan data!"),
                              backgroundColor: Colors.green,
                              duration: Duration(seconds: 2),
                            ),
                          );

                          // ✅ Kembali ke HomePage (otomatis update karena provider sudah notifyListeners)
                          context.pop();
                        }
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  "Gagal menambahkan data. Cek koneksi Anda"),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      // Close loading jika masih ada
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
                    "Add Expanse",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
                const Gap(20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _input({
    required TextEditingController controller,
    required String hint,
    required TextInputType type,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: type,
      textAlign: TextAlign.start,
      maxLines: maxLines,
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
