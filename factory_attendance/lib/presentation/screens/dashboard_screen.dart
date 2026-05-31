import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/themes/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/attendance_provider.dart';
import 'login_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import 'camera_screen.dart' as camera_screen;

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Timer? _timer;
  String _timeString = '';
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _timeString = _formatDateTime(DateTime.now());
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (Timer t) => _getTime(),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final attendanceProvider = context.read<AttendanceProvider>();
      final user = FirebaseAuth.instance.currentUser;
      attendanceProvider.startLocationStream();
      if (user != null) {
        attendanceProvider.calculateWeeklyStats(user.uid);
        attendanceProvider.fetchHistory(user.uid);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _getTime() {
    final DateTime now = DateTime.now();
    final String formattedDateTime = _formatDateTime(now);
    if (mounted) {
      setState(() {
        _timeString = formattedDateTime;
      });
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('HH:mm:ss').format(dateTime);
  }

  Future<void> _handleLogout(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.signOut();

    if (!context.mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  Future<void> _handleAttendance(String type) async {
    final attendanceProvider = context.read<AttendanceProvider>();
    final user = FirebaseAuth.instance.currentUser;
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    if (user == null) return;

    try {
      if (type == 'check_in') {
        // TODO: Uncomment ini nanti jika sudah selesai testing kamera
        // if (!attendanceProvider.isInArea) {
        //   scaffoldMessenger.showSnackBar(
        //     const SnackBar(content: Text('Anda berada di luar area absensi!')),
        //   );
        //   return;
        // }

        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const camera_screen.CameraScreen()),
        );

        if (result is camera_screen.SelfieCaptureResult && result.success) {
          await attendanceProvider.checkIn(
            user.uid,
            selfiePath: result.filePath,
          );
        } else {
          return; // Cancelled or failed
        }
      } else {
        await attendanceProvider.checkOut(user.uid);
      }
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Berhasil merekam absensi ($type)')),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final attendanceProvider = context.watch<AttendanceProvider>();
    final user = FirebaseAuth.instance.currentUser;

    final LatLng factoryLocation = LatLng(
      attendanceProvider.factoryLat,
      attendanceProvider.factoryLng,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Dashboard - ${authProvider.userRole}',
          style: const TextStyle(color: AppColors.white),
        ),
        backgroundColor: AppColors.deepNavy,
        actions: [
          IconButton(
            icon: const Icon(Icons.badge, color: AppColors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.history, color: AppColors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HistoryScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.white),
            onPressed: () => _handleLogout(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Bagian Atas: Peta
          Expanded(
            flex: 2,
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: factoryLocation,
                    zoom: 15,
                  ),
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  markers: {
                    Marker(
                      markerId: const MarkerId('factory'),
                      position: factoryLocation,
                      infoWindow: const InfoWindow(title: 'Pabrik / Kantor'),
                    ),
                  },
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
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                ),
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.deepNavy.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _timeString,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bagian Tengah & Bawah: Status, Action & Stats
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.all(24.0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // User Info & Status
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.deepNavy,
                        child: Icon(
                          Icons.person,
                          size: 30,
                          color: AppColors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.email ?? 'Unknown',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              authProvider.userRole.toUpperCase(),
                              style: const TextStyle(
                                color: AppColors.safetyOrange,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: attendanceProvider.isInArea
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: attendanceProvider.isInArea
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                        child: Text(
                          attendanceProvider.isInArea
                              ? "Status: In Area 🟢"
                              : "Status: Outside Area 🔴",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: attendanceProvider.isInArea
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Text(
                    'Jarak saat ini: ${attendanceProvider.currentDistance.toStringAsFixed(1)} meter',
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const Spacer(),

                  // Action Buttons
                  if (attendanceProvider.isLoading)
                    const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.safetyOrange,
                      ),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: attendanceProvider.canCheckIn
                                ? () => _handleAttendance('check_in')
                                : null,
                            icon: const Icon(Icons.login),
                            label: const Text('CHECK-IN'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: attendanceProvider.canCheckOut
                                ? () => _handleAttendance('check_out')
                                : null,
                            icon: const Icon(Icons.logout),
                            label: const Text('CHECK-OUT'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  const Spacer(),

                  // Weekly Stats
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Weekly Stats',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'Total Kehadiran (7 Hari Terakhir)',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            color: AppColors.deepNavy,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${attendanceProvider.weeklyAttendanceCount}',
                            style: const TextStyle(
                              color: AppColors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
