import 'package:expense_uangku/routes/name_routes.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:expense_uangku/services/users_api.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:expense_uangku/providers/ExpanseProvider.dart';
import 'package:expense_uangku/providers/transaction_provider.dart';
import 'package:expense_uangku/routes/app_routes.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class SettingProfilePage extends StatefulWidget {
  const SettingProfilePage({super.key});

  @override
  State<SettingProfilePage> createState() => _SettingProfilePageState();
}

class _SettingProfilePageState extends State<SettingProfilePage> {
  // Controllers
  final TextEditingController nameController =
      TextEditingController(text: "Arief Smith");
  final TextEditingController dobController = TextEditingController();

  File? imageFile;

  // Pick Image
  Future<void> pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (picked != null) {
      setState(() {
        imageFile = File(picked.path);
        avatarBytes = null;
      });
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Logout')),
        ],
      ),
    );

    if (confirm != true) return;

    final expanseProv = Provider.of<ExpanseProvider>(context, listen: false);
    final txProv = Provider.of<TransactionProvider>(context, listen: false);

    // clear app state first
    expanseProv.clear();
    txProv.clear();

    // delete token and user
    await UsersApi.deleteToken();
    await UsersApi.deleteUser();

    // notify router and navigate
    appRoutes.auth.setLoggedIn(false);
    if (mounted) {
      context.goNamed(NameRoutes.login);
    }
  }

  String? initialAvatarUrl;
  int? userId;
  bool isSaving = false;
  Uint8List? avatarBytes; // loaded bytes for protected image

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final userJson = await UsersApi.getUserJson();
    if (userJson != null) {
      setState(() {
        userId = (userJson['id'] is int
            ? userJson['id']
            : int.tryParse('${userJson['id']}'));
        nameController.text =
            (userJson['full_name'] ?? userJson['name'] ?? '').toString();
        final birth = userJson['birth_date'] ?? userJson['birthDate'];
        if (birth != null) {
          // adapt to yyyy-mm-dd or ISO
          try {
            final d = DateTime.parse(birth.toString());
            dobController.text =
                '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
          } catch (_) {
            dobController.text = birth.toString();
          }
        }
        initialAvatarUrl = (userJson['avatar'] ?? '').toString();
      });

      // load avatar bytes if avatar exists
      if (initialAvatarUrl != null && initialAvatarUrl!.isNotEmpty) {
        final bytes = await UsersApi.fetchAvatarBytes(initialAvatarUrl!);
        if (bytes != null) {
          if (mounted) {
            setState(() {
              avatarBytes = bytes;
            });
          }
        }
      }
    }
  }

  Future<void> _saveProfile() async {
    if (isSaving) return;
    if (nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Name cannot be empty')));
      return;
    }
    if (userId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('User id not found')));
      return;
    }

    setState(() => isSaving = true);

    try {
      final res = await UsersApi.updateUser(
        userId: userId!,
        fullName: nameController.text.trim(),
        birthDate: dobController.text.trim().isEmpty
            ? null
            : dobController.text.trim(),
        avatarFile: imageFile,
      );

      if (res != null && res['success'] == true) {
        // get updated user and refresh local UI
        final updatedUser = await UsersApi.getUserJson();
        if (updatedUser != null) {
          setState(() {
            initialAvatarUrl = (updatedUser['avatar'] ?? '').toString();
            nameController.text =
                (updatedUser['full_name'] ?? updatedUser['name'] ?? '')
                    .toString();
            imageFile = null; // we've uploaded it, show server image
            avatarBytes = null; // we'll re-fetch below
          });
        }

        // re-fetch bytes for protected endpoint and show
        if (initialAvatarUrl != null && initialAvatarUrl!.isNotEmpty) {
          final bytes = await UsersApi.fetchAvatarBytes(initialAvatarUrl!);
          if (bytes != null && mounted) {
            setState(() {
              avatarBytes = bytes;
            });
          }
        }

        // optional: update UserProvider (if implemented) or Home UI
        final userProv = Provider.of<ExpanseProvider>(context,
            listen: false); // if you have UserProvider: swap accordingly

        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Profile updated')));
      } else {
        final msg = res != null && res['message'] != null
            ? res['message']
            : 'Update failed';
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg.toString())));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageWidget = imageFile != null
        ? DecorationImage(image: FileImage(imageFile!), fit: BoxFit.cover)
        : (avatarBytes != null
            ? DecorationImage(
                image: MemoryImage(avatarBytes!), fit: BoxFit.cover)
            : (initialAvatarUrl != null && initialAvatarUrl!.isNotEmpty
                ? DecorationImage(
                    image: NetworkImage(initialAvatarUrl!),
                    fit: BoxFit.cover,
                  )
                : const DecorationImage(
                    image: AssetImage("assets/images/samsul_bahri.jpg"),
                    fit: BoxFit.cover,
                  )));

    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
        title: Text(
          'Setting Profile',
          style: GoogleFonts.montserrat(
            textStyle: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          const Gap(30),

          // ===============================
          // PROFILE PICTURE
          // ===============================
          // Center(
          //   child: Stack(
          //     children: [
          //       // Foto profil
          //       Container(
          //         width: 180,
          //         height: 180,
          //         decoration: BoxDecoration(
          //           shape: BoxShape.circle,
          //           color: Colors.grey.shade300,
          //           image: imageWidget,
          //         ),
          //       ),

          //       // Tombol camera
          //       Positioned(
          //         bottom: 8,
          //         right: 8,
          //         child: InkWell(
          //           onTap: pickImage,
          //           child: Container(
          //             padding: const EdgeInsets.all(10),
          //             decoration: const BoxDecoration(
          //               color: Colors.blueAccent,
          //               shape: BoxShape.circle,
          //             ),
          //             child: const Icon(
          //               Icons.camera_alt,
          //               color: Colors.white,
          //               size: 22,
          //             ),
          //           ),
          //         ),
          //       ),
          //     ],
          //   ),
          // ),

          const Gap(20),

          // ===============================
          // NAME
          // ===============================
          TextField(
            controller: nameController,
            cursorColor: Colors.grey,
            decoration: InputDecoration(
              labelText: "Name",
              labelStyle: const TextStyle(color: Colors.grey),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Colors.blueAccent, width: 2),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          const Gap(20),

          // ===============================
          // DATE OF BIRTH
          // ===============================
          TextField(
            controller: dobController,
            readOnly: true,
            onTap: () async {
              DateTime? date = await showDatePicker(
                context: context,
                firstDate: DateTime(1950),
                lastDate: DateTime.now(),
                initialDate: DateTime.now(),
              );
              if (date != null) {
                dobController.text = "${date.day}-${date.month}-${date.year}";
              }
            },
            decoration: InputDecoration(
              labelText: "Date of Birth",
              labelStyle: const TextStyle(color: Colors.grey),
              suffixIcon: const Icon(Icons.calendar_month),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Colors.blueAccent, width: 2),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          const Gap(30),

          // ===============================
          // SAVE BUTTON
          // ===============================
          ElevatedButton(
            onPressed: isSaving ? null : _saveProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              minimumSize: const Size(double.infinity, 45),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: isSaving
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5))
                : const Text("Save",
                    style: TextStyle(color: Colors.white, fontSize: 16)),
          ),

          const Gap(30),
        ],
      ),

      // Tambahkan floating button logout
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _handleLogout,
        icon: const Icon(Icons.logout),
        label: const Text('Logout'),
        backgroundColor: Colors.redAccent,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
