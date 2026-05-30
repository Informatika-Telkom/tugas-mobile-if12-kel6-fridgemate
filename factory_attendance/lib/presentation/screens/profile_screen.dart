import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/themes/app_colors.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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
        future: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get(),
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
