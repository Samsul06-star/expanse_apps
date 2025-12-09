import 'package:expense_uangku/services/users_api.dart';
import 'package:expense_uangku/providers/ExpanseProvider.dart';
import 'package:expense_uangku/providers/transaction_provider.dart';
import 'package:expense_uangku/routes/app_routes.dart';
import 'package:expense_uangku/routes/name_routes.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailC = TextEditingController();
  final passwordC = TextEditingController();
  bool isPasswordVisible = false;
  bool isLoading = false;

  @override
  void dispose() {
    emailC.dispose();
    passwordC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Gap(40),

                // Logo / Icon
                Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet,
                      size: 50,
                      color: Colors.blueAccent,
                    ),
                  ),
                ),

                const Gap(30),

                // Title
                Text(
                  'Welcome Back!',
                  style: GoogleFonts.montserrat(
                    textStyle: const TextStyle(
                      color: Colors.black,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  textAlign: TextAlign.center,
                ),

                const Gap(10),

                Text(
                  'Login to continue managing your expenses',
                  style: GoogleFonts.poppins(
                    textStyle: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                  textAlign: TextAlign.center,
                ),

                const Gap(40),

                // Email Field
                Text(
                  'Email',
                  style: GoogleFonts.poppins(
                    textStyle: const TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Gap(8),
                TextField(
                  controller: emailC,
                  keyboardType: TextInputType.emailAddress,
                  style: GoogleFonts.poppins(
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter your email',
                    hintStyle: GoogleFonts.poppins(
                      textStyle: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                    prefixIcon:
                        const Icon(Icons.email_outlined, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: Colors.blueAccent, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 15, vertical: 16),
                  ),
                ),

                const Gap(20),

                // Password Field
                Text(
                  'Password',
                  style: GoogleFonts.poppins(
                    textStyle: const TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Gap(8),
                TextField(
                  controller: passwordC,
                  obscureText: !isPasswordVisible,
                  style: GoogleFonts.poppins(
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter your password',
                    hintStyle: GoogleFonts.poppins(
                      textStyle: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                    prefixIcon:
                        const Icon(Icons.lock_outline, color: Colors.grey),
                    suffixIcon: IconButton(
                      icon: Icon(
                        isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          isPasswordVisible = !isPasswordVisible;
                        });
                      },
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: Colors.blueAccent, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 15, vertical: 16),
                  ),
                ),

                const Gap(10),

                const Gap(30),

                // Login Button
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          // Validasi
                          if (emailC.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text("Email tidak boleh kosong")),
                            );
                            return;
                          }

                          if (passwordC.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text("Password tidak boleh kosong")),
                            );
                            return;
                          }

                          setState(() => isLoading = true);

                          try {
                            final res = await UsersApi.login(
                              email: emailC.text.trim(),
                              password: passwordC.text,
                            );

                            if (res['success'] == true) {
                              // save token already done in UsersApi.login but ensure it.
                              if (res['token'] != null)
                                await UsersApi.saveToken(res['token']);

                              // save user json if present
                              if (res['user'] != null && res['user'] is Map) {
                                await UsersApi.saveUser(
                                    Map<String, dynamic>.from(res['user']));
                              }

                              // set logged in
                              appRoutes.auth.setLoggedIn(true);

                              // re-fetch expanse and recompute totals
                              final expProv = Provider.of<ExpanseProvider>(
                                  context,
                                  listen: false);
                              final txProv = Provider.of<TransactionProvider>(
                                  context,
                                  listen: false);

                              await expProv.fetchAllExpanse();
                              txProv.computeFromExpanses(expProv.expenses);

                              if (mounted) {
                                context.goNamed(NameRoutes.home);
                              }
                            } else {
                              final msg = res['message'] ??
                                  (res['body'] is Map
                                      ? (res['body']['message'] ??
                                          res['body']['error'])
                                      : 'Login gagal');
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(msg.toString())),
                              );
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          } finally {
                            if (mounted) setState(() => isLoading = false);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    minimumSize: const Size(double.infinity, 55),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          "Login",
                          style: GoogleFonts.poppins(
                            textStyle: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                ),

                const Gap(20),

                // Register Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: GoogleFonts.poppins(
                        textStyle: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        context
                            .push('/register'); // Sesuaikan dengan route Anda
                      },
                      child: Text(
                        'Register',
                        style: GoogleFonts.poppins(
                          textStyle: const TextStyle(
                            color: Colors.blueAccent,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
