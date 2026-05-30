import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import '../../core/themes/app_colors.dart';
import '../../domain/entities/attendance_entity.dart';
import 'attendance_detail_screen.dart';
import '../providers/attendance_provider.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  static const List<String> _statusOptions = [
    'Semua',
    'Hadir',
    'Telat',
    'Izin',
    'Alpha',
  ];

  String _selectedStatus = 'Semua';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        context.read<AttendanceProvider>().fetchHistory(user.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final attendanceProvider = context.watch<AttendanceProvider>();
    final filteredHistory = _filterHistory(attendanceProvider.history);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Riwayat Absensi',
          style: TextStyle(color: AppColors.white),
        ),
        backgroundColor: AppColors.deepNavy,
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: attendanceProvider.isLoading && attendanceProvider.history.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.safetyOrange),
            )
          : attendanceProvider.history.isEmpty
          ? const Center(child: Text("Belum ada riwayat absensi"))
          : Column(
              children: [
                _buildStatusFilters(),
                Expanded(
                  child: filteredHistory.isEmpty
                      ? const Center(
                          child: Text("Tidak ada data untuk filter ini"),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredHistory.length,
                          itemBuilder: (context, index) {
                            final log = filteredHistory[index];
                            final isCheckIn = log.type == 'check_in';
                            final dateStr = DateFormat(
                              'dd MMM yyyy, HH:mm',
                            ).format(log.timestamp);
                            final statusLabel = _normalizeStatus(log);
                            final isNewDate =
                                index == 0 ||
                                !_isSameDate(
                                  filteredHistory[index - 1].timestamp,
                                  log.timestamp,
                                );

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (isNewDate) _buildDateHeader(log.timestamp),
                                Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ListTile(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              AttendanceDetailScreen(log: log),
                                        ),
                                      );
                                    },
                                    leading: CircleAvatar(
                                      backgroundColor: isCheckIn
                                          ? Colors.green.withOpacity(0.1)
                                          : Colors.red.withOpacity(0.1),
                                      child: Icon(
                                        isCheckIn ? Icons.login : Icons.logout,
                                        color: isCheckIn
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                    ),
                                    title: Text(
                                      isCheckIn ? "CHECK IN" : "CHECK OUT",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isCheckIn
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        Text(
                                          dateStr,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          "Jarak: ${log.distance.toStringAsFixed(1)}m | Status: $statusLabel",
                                        ),
                                      ],
                                    ),
                                    trailing: const Icon(Icons.chevron_right),
                                    isThreeLine: true,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatusFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: _statusOptions.map((status) {
          final isSelected = _selectedStatus == status;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(status),
              selected: isSelected,
              selectedColor: AppColors.safetyOrange.withOpacity(0.2),
              onSelected: (_) {
                setState(() {
                  _selectedStatus = status;
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDateHeader(DateTime timestamp) {
    final label = DateFormat('dd MMM yyyy').format(timestamp);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: AppColors.deepNavy,
        ),
      ),
    );
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  List<AttendanceEntity> _filterHistory(List<AttendanceEntity> history) {
    if (_selectedStatus == 'Semua') return history;

    return history.where((log) {
      final normalized = _normalizeStatus(log).toLowerCase();
      return normalized == _selectedStatus.toLowerCase();
    }).toList();
  }

  String _normalizeStatus(AttendanceEntity log) {
    final raw = log.status.trim().toLowerCase();

    if (raw.isEmpty || raw == 'in area') {
      return 'Hadir';
    }

    if (raw.contains('telat') || raw.contains('late')) {
      return 'Telat';
    }

    if (raw.contains('izin')) {
      return 'Izin';
    }

    if (raw.contains('alpha')) {
      return 'Alpha';
    }

    return log.status;
  }
}
