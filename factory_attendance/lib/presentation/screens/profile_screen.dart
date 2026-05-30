import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../core/themes/app_colors.dart';
import '../providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<DocumentSnapshot<Map<String, dynamic>>>? _profileFuture;

  @override
  void initState() {
    super.initState();
    _refreshProfile();
  }

  void _refreshProfile() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    _profileFuture = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
  }

  Future<void> _showEditProfileDialog(
    BuildContext context,
    Map<String, dynamic> data,
  ) async {
    final nameController = TextEditingController(
      text: (data['name'] ?? data['fullName'] ?? '').toString(),
    );
    final employeeIdController = TextEditingController(
      text: (data['employeeId'] ?? data['nik'] ?? '').toString(),
    );
    final departmentController = TextEditingController(
      text: (data['department'] ?? data['division'] ?? '').toString(),
    );
    final phoneController = TextEditingController(
      text: (data['phone'] ?? data['phoneNumber'] ?? '').toString(),
    );

    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Edit Profil'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Nama'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Nama wajib diisi.';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: employeeIdController,
                    decoration: const InputDecoration(labelText: 'ID Karyawan'),
                  ),
                  TextFormField(
                    controller: departmentController,
                    decoration: const InputDecoration(labelText: 'Departemen'),
                  ),
                  TextFormField(
                    controller: phoneController,
                    decoration: const InputDecoration(labelText: 'Telepon'),
                    keyboardType: TextInputType.phone,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );

    if (result != true) return;

    if (!formKey.currentState!.validate()) return;

    if (!mounted) return;
    final authProvider = context.read<AuthProvider>();

    try {
      await authProvider.updateProfile(
        name: nameController.text,
        employeeId: employeeIdController.text,
        department: departmentController.text,
        phone: phoneController.text,
      );

      if (!mounted) return;
      setState(_refreshProfile);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil berhasil diperbarui.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _showChangePasswordDialog(BuildContext context) async {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Ubah Password'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: currentController,
                    decoration: const InputDecoration(
                      labelText: 'Password Saat Ini',
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Password saat ini wajib diisi.';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: newController,
                    decoration: const InputDecoration(
                      labelText: 'Password Baru',
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.trim().length < 6) {
                        return 'Password baru minimal 6 karakter.';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: confirmController,
                    decoration: const InputDecoration(
                      labelText: 'Konfirmasi Password Baru',
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value != newController.text) {
                        return 'Password tidak cocok.';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Ubah'),
            ),
          ],
        );
      },
    );

    if (result != true) return;

    if (!formKey.currentState!.validate()) return;

    if (!mounted) return;
    final authProvider = context.read<AuthProvider>();

    try {
      await authProvider.changePassword(
        currentPassword: currentController.text,
        newPassword: newController.text,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password berhasil diubah.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('User belum login')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profil Karyawan',
          style: TextStyle(color: AppColors.white),
        ),
        backgroundColor: AppColors.deepNavy,
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.safetyOrange),
            );
          }

          final data = snapshot.data?.data() ?? <String, dynamic>{};
          final name =
              (data['name'] ?? data['fullName'] ?? user.email ?? '-') as String;
          final employeeId =
              (data['employeeId'] ?? data['nik'] ?? '-') as String;
          final department =
              (data['department'] ?? data['division'] ?? '-') as String;
          final phone = (data['phone'] ?? data['phoneNumber'] ?? '-') as String;
          final role = (data['role'] ?? '-') as String;
          final photoUrl = data['photoUrl'] as String?;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Kartu Identitas Karyawan',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 36,
                            backgroundColor: AppColors.deepNavy.withOpacity(
                              0.1,
                            ),
                            backgroundImage:
                                photoUrl == null || photoUrl.trim().isEmpty
                                ? null
                                : NetworkImage(photoUrl),
                            child: photoUrl == null || photoUrl.trim().isEmpty
                                ? const Icon(
                                    Icons.person,
                                    color: AppColors.deepNavy,
                                    size: 36,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(role.toUpperCase()),
                                const SizedBox(height: 4),
                                Text('ID: $employeeId'),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _InfoRow(label: 'Email', value: user.email ?? '-'),
                      _InfoRow(label: 'Departemen', value: department),
                      _InfoRow(label: 'Telepon', value: phone),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _showEditProfileDialog(context, data),
                icon: const Icon(Icons.edit),
                label: const Text('Edit Profil'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.safetyOrange,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _showChangePasswordDialog(context),
                icon: const Icon(Icons.lock_outline),
                label: const Text('Ubah Password'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.deepNavy,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
