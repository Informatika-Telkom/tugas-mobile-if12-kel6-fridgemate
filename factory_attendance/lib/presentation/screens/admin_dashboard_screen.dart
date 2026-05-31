import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/themes/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/attendance_provider.dart';
import 'login_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Admin Dashboard',
            style: TextStyle(color: AppColors.white),
          ),
          backgroundColor: AppColors.deepNavy,
          iconTheme: const IconThemeData(color: AppColors.white),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: AppColors.white),
              onPressed: () async {
                await context.read<AuthProvider>().signOut();
                if (!context.mounted) return;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Overview', icon: Icon(Icons.dashboard_outlined)),
              Tab(text: 'Map', icon: Icon(Icons.map_outlined)),
              Tab(text: 'KPI', icon: Icon(Icons.assessment_outlined)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [_OverviewTab(), _MapOverviewTab(), _KpiTab()],
        ),
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayKey = DateFormat('yyyy-MM-dd').format(now);

    final usersStream = FirebaseFirestore.instance
        .collection('users')
        .snapshots();
    final attendanceStream = FirebaseFirestore.instance
        .collection('attendance_logs')
        .where('type', isEqualTo: 'check_in')
        .snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: usersStream,
      builder: (context, usersSnapshot) {
        if (usersSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.safetyOrange),
          );
        }

        final users = usersSnapshot.data?.docs ?? [];
        final employees = users.where((doc) {
          final role = doc.data()['role']?.toString();
          return !_isAdminRole(role);
        }).toList();
        final employeeIds = employees.map((doc) => doc.id).toSet();

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: attendanceStream,
          builder: (context, attendanceSnapshot) {
            if (attendanceSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.safetyOrange),
              );
            }

            final attendanceLogs = attendanceSnapshot.data?.docs ?? [];
            final attendanceByUser = <String, DateTime>{};
            for (final log in attendanceLogs) {
              final data = log.data();
              final userId = data['userId']?.toString();
              final ts = _resolveLogTime(data);
              if (userId == null || ts == null) continue;
              if (!employeeIds.contains(userId)) continue;
              if (!_matchesToday(data, ts, todayKey, now)) continue;
              if (!_isWithinWorkingHours(ts)) continue;
              if (!attendanceByUser.containsKey(userId) ||
                  ts.isBefore(attendanceByUser[userId]!)) {
                attendanceByUser[userId] = ts;
              }
            }

            final cutoff = DateTime(now.year, now.month, now.day, 7, 0);
            final totalAttendance = attendanceByUser.length;
            final lateCount = attendanceByUser.values
                .where((time) => _isLate(time, cutoff))
                .length;
            final totalEmployees = employees.length;
            final absents = (totalEmployees - totalAttendance).clamp(0, 9999);

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'Total hadir',
                        value: totalAttendance.toString(),
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        title: 'Terlambat',
                        value: lateCount.toString(),
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        title: 'Absen',
                        value: absents.toString(),
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Daftar Karyawan',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ...employees.map((doc) {
                  final data = doc.data();
                  final name = _displayName(data);
                  final department = data['department']?.toString() ?? '-';
                  final email = data['email']?.toString() ?? '-';
                  final role = data['role']?.toString() ?? 'employee';

                  return Card(
                    elevation: 1,
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: AppColors.deepNavy,
                        child: Icon(Icons.person, color: AppColors.white),
                      ),
                      title: Text(name),
                      subtitle: Text('$department • $email'),
                      trailing: Text(role.toUpperCase()),
                    ),
                  );
                }),
              ],
            );
          },
        );
      },
    );
  }
}

class _MapOverviewTab extends StatelessWidget {
  const _MapOverviewTab();

  @override
  Widget build(BuildContext context) {
    final attendanceProvider = context.read<AttendanceProvider>();
    final now = DateTime.now();
    final todayKey = DateFormat('yyyy-MM-dd').format(now);

    final usersStream = FirebaseFirestore.instance
        .collection('users')
        .snapshots();
    final attendanceStream = FirebaseFirestore.instance
        .collection('attendance_logs')
        .where('type', isEqualTo: 'check_in')
        .snapshots();

    final factoryLocation = LatLng(
      attendanceProvider.factoryLat,
      attendanceProvider.factoryLng,
    );

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: usersStream,
      builder: (context, usersSnapshot) {
        if (usersSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.safetyOrange),
          );
        }

        final users = usersSnapshot.data?.docs ?? [];
        final userNames = <String, String>{};
        final employeeIds = <String>{};
        for (final doc in users) {
          final role = doc.data()['role']?.toString();
          if (_isAdminRole(role)) continue;
          userNames[doc.id] = _displayName(doc.data());
          employeeIds.add(doc.id);
        }

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: attendanceStream,
          builder: (context, attendanceSnapshot) {
            if (attendanceSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.safetyOrange),
              );
            }

            final logs = attendanceSnapshot.data?.docs ?? [];
            final latestByUser =
                <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
            for (final doc in logs) {
              final data = doc.data();
              final userId = data['userId']?.toString();
              final ts = _resolveLogTime(data);
              if (userId == null || ts == null) continue;
              if (!employeeIds.contains(userId)) continue;
              if (!_matchesToday(data, ts, todayKey, now)) continue;
              if (!_isWithinWorkingHours(ts)) continue;

              final existing = latestByUser[userId];
              if (existing == null) {
                latestByUser[userId] = doc;
                continue;
              }

              final existingTs = _resolveLogTime(existing.data());
              if (existingTs == null || ts.isAfter(existingTs)) {
                latestByUser[userId] = doc;
              }
            }

            final markers = latestByUser.entries
                .map((entry) {
                  final data = entry.value.data();
                  final lat = (data['latitude'] as num?)?.toDouble();
                  final lng = (data['longitude'] as num?)?.toDouble();
                  if (lat == null || lng == null) return null;

                  final name = userNames[entry.key] ?? 'Employee';
                  return Marker(
                    markerId: MarkerId(entry.key),
                    position: LatLng(lat, lng),
                    infoWindow: InfoWindow(title: name),
                  );
                })
                .whereType<Marker>()
                .toSet();

            markers.add(
              Marker(
                markerId: const MarkerId('factory'),
                position: factoryLocation,
                infoWindow: const InfoWindow(title: 'Pabrik / Kantor'),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueAzure,
                ),
              ),
            );

            return GoogleMap(
              initialCameraPosition: CameraPosition(
                target: factoryLocation,
                zoom: 14,
              ),
              myLocationEnabled: true,
              markers: markers,
              circles: {
                Circle(
                  circleId: const CircleId('geofence'),
                  center: factoryLocation,
                  radius: attendanceProvider.attendanceRadius,
                  fillColor: Colors.blue.withOpacity(0.2),
                  strokeColor: Colors.blue,
                  strokeWidth: 2,
                ),
              },
            );
          },
        );
      },
    );
  }
}

class _KpiTab extends StatelessWidget {
  const _KpiTab();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final startOfWeek = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 6));

    final usersStream = FirebaseFirestore.instance
        .collection('users')
        .snapshots();
    final attendanceStream = FirebaseFirestore.instance
        .collection('attendance_logs')
        .where('type', isEqualTo: 'check_in')
        .snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: usersStream,
      builder: (context, usersSnapshot) {
        if (usersSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.safetyOrange),
          );
        }

        final users = usersSnapshot.data?.docs ?? [];
        final employees = users.where((doc) {
          final role = doc.data()['role']?.toString();
          return !_isAdminRole(role);
        }).toList();
        final employeeIds = employees.map((doc) => doc.id).toSet();

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: attendanceStream,
          builder: (context, attendanceSnapshot) {
            if (attendanceSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.safetyOrange),
              );
            }

            final logs = attendanceSnapshot.data?.docs ?? [];
            final dailyAttendance = List.generate(7, (_) => <String>{});
            final dailyLate = List.generate(7, (_) => <String>{});
            final hourlyCounts = List.filled(24, 0);

            for (final doc in logs) {
              final data = doc.data();
              final userId = data['userId']?.toString();
              final ts = _resolveLogTime(data);
              if (userId == null || ts == null) continue;
              if (!employeeIds.contains(userId)) continue;

              final dayStart = DateTime(
                now.year,
                now.month,
                now.day,
              ).subtract(const Duration(days: 6));
              final dayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
              if (ts.isBefore(dayStart) || ts.isAfter(dayEnd)) continue;
              if (!_isWithinWorkingHours(ts)) continue;

              final index = ts.difference(startOfWeek).inDays;
              if (index < 0 || index > 6) continue;

              dailyAttendance[index].add(userId);

              final cutoff = DateTime(ts.year, ts.month, ts.day, 7, 0);
              if (_isLate(ts, cutoff)) {
                dailyLate[index].add(userId);
              }

              hourlyCounts[ts.hour] = hourlyCounts[ts.hour] + 1;
            }

            final totalEmployees = employees.length;
            final attendanceRates = dailyAttendance
                .map((set) => _percentage(set.length, totalEmployees))
                .toList();
            final lateTrend = dailyLate
                .map((set) => set.length.toDouble())
                .toList();

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Weekly Attendance Rate (%)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 240,
                  child: _buildBarChart(
                    values: attendanceRates,
                    maxY: 100,
                    labels: _lastSevenDaysLabels(startOfWeek),
                    color: Colors.green,
                    leftInterval: 20,
                    leftReservedSize: 36,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Late Trend (7 hari)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 240,
                  child: _buildBarChart(
                    values: lateTrend,
                    maxY: (lateTrend.reduce(_maxDouble) + 2).clamp(4, 20),
                    labels: _lastSevenDaysLabels(startOfWeek),
                    color: Colors.orange,
                    leftInterval: 1,
                    leftReservedSize: 32,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Hourly Distribution',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 260,
                  child: _buildBarChart(
                    values: hourlyCounts.map((v) => v.toDouble()).toList(),
                    maxY: (hourlyCounts.reduce((a, b) => a > b ? a : b) + 2)
                        .toDouble(),
                    labels: List.generate(24, (index) => index.toString()),
                    color: Colors.blue,
                    leftInterval: 2,
                    leftReservedSize: 32,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

Widget _buildBarChart({
  required List<double> values,
  required List<String> labels,
  required double maxY,
  required Color color,
  double leftInterval = 1,
  double leftReservedSize = 32,
}) {
  return BarChart(
    BarChartData(
      maxY: maxY,
      gridData: FlGridData(show: true),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: leftInterval,
            reservedSize: leftReservedSize,
          ),
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index < 0 || index >= labels.length) {
                return const SizedBox.shrink();
              }
              return SideTitleWidget(
                axisSide: meta.axisSide,
                child: Text(
                  labels[index],
                  style: const TextStyle(fontSize: 10),
                ),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      barGroups: List.generate(values.length, (index) {
        return BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: values[index],
              color: color,
              borderRadius: BorderRadius.circular(4),
              width: 12,
            ),
          ],
        );
      }),
    ),
  );
}

List<String> _lastSevenDaysLabels(DateTime startOfWeek) {
  return List.generate(7, (index) {
    final date = startOfWeek.add(Duration(days: index));
    return '${date.day}/${date.month}';
  });
}

String _displayName(Map<String, dynamic> data) {
  return (data['name'] ?? data['fullName'] ?? data['email'] ?? '-').toString();
}

bool _isAdminRole(String? role) {
  final normalized = role?.toLowerCase() ?? '';
  return normalized == 'admin' || normalized == 'hrd';
}

double _percentage(int numerator, int denominator) {
  if (denominator <= 0) return 0;
  return (numerator / denominator) * 100;
}

double _maxDouble(double a, double b) => a > b ? a : b;

DateTime? _resolveLogTime(Map<String, dynamic> data) {
  final serverTs = data['timestamp'] as Timestamp?;
  final clientTs = data['clientTimestamp'] as Timestamp?;
  if (serverTs != null) return serverTs.toDate();
  if (clientTs != null) return clientTs.toDate();
  return null;
}

bool _matchesToday(
  Map<String, dynamic> data,
  DateTime timestamp,
  String todayKey,
  DateTime today,
) {
  final dateKey = data['dateKey']?.toString();
  if (dateKey != null && dateKey == todayKey) return true;
  return _isSameDay(timestamp, today);
}

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

bool _isWithinWorkingHours(DateTime time) {
  final start = DateTime(time.year, time.month, time.day, 4, 0);
  final end = DateTime(time.year, time.month, time.day, 17, 0);
  return !time.isBefore(start) && !time.isAfter(end);
}

bool _isLate(DateTime time, DateTime cutoff) {
  return time.isAfter(cutoff);
}
