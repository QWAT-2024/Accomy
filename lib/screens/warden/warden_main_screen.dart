import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:accomy/screens/warden/warden_profile_screen.dart';
import 'package:accomy/screens/warden/warden_report_screen.dart';
import 'package:accomy/screens/warden/warden_attendance_screen.dart';
import 'package:accomy/screens/warden/warden_outpass_management_screen.dart';

// Main entry point for the Warden's UI
class WardenMainScreen extends StatefulWidget {
  const WardenMainScreen({super.key});

  @override
  State<WardenMainScreen> createState() => _WardenMainScreenState();
}

class _WardenMainScreenState extends State<WardenMainScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _currentUser;
  String? _wardenHostelName;
  String _wardenName = 'Warden'; // Default name
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser;
    _fetchWardenDetails();
  }

  Future<void> _fetchWardenDetails() async {
    if (_currentUser == null) return;
    try {
      final doc =
          await _firestore.collection('staff').doc(_currentUser!.uid).get();
      if (doc.exists && doc.data() != null) {
        if (mounted) {
          setState(() {
            _wardenName = doc.data()!['name'] ?? 'Warden';
            _wardenHostelName = doc.data()!['hostelName'];
          });
        }
      }
    } catch (e) {
      print('Error fetching warden details: $e');
    }
  }

  Future<int> _getOutpassCountByStatus(List<String> statuses) async {
    if (_currentUser == null || _wardenHostelName == null) return 0;

    final querySnapshot = await _firestore
        .collection('outpass_requests')
        .where('wardenApprovalStatus', whereIn: statuses)
        .get();

    int count = 0;
    for (var doc in querySnapshot.docs) {
      final data = doc.data();
      final studentDoc =
          await _firestore.collection('students').doc(data['userId']).get();
      if (studentDoc.exists &&
          studentDoc.data()?['hostel'] == _wardenHostelName) {
        count++;
      }
    }
    return count;
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      _buildHomeContent(),
      if (_currentUser != null) WardenReportScreen(wardenId: _currentUser!.uid),
      const WardenAttendanceScreen(),
      const WardenProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: screens,
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF2A3A6A),
        unselectedItemColor: Colors.grey.shade600,
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
              icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.description_outlined), label: 'Reports'),
          BottomNavigationBarItem(
              icon: Icon(Icons.check_circle_outline), label: 'Attendance'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }

  // MODIFICATION: Wrapped the AppBar in PreferredSize to add space at the top.
  PreferredSizeWidget _buildAppBar() {
    // The amount of vertical space you want to add above the AppBar.
    const double topSpacing = 20.0;

    // We use PreferredSize to give the AppBar a new, larger height.
    return PreferredSize(
      // The total height is the default AppBar height plus our custom spacing.
      preferredSize: Size.fromHeight(kToolbarHeight + topSpacing),
      child: Container(
        // The color of the spaced area.
        color: Colors.grey[50],
        // Add padding to the top to create the visual space.
        padding: const EdgeInsets.only(top: topSpacing),
        child: AppBar(
          backgroundColor: Colors.grey[50],
          elevation: 0,
          automaticallyImplyLeading: false,
          titleSpacing: 16,
          title: Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFF2A3A6A),
                child: Icon(Icons.school, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Warden Portal",
                    style: TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  Text(
                    "Warden Dashboard",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: IconButton(
                onPressed: () {
                  // Handle notification tap
                },
                icon: Icon(
                  Icons.notifications_none_outlined,
                  color: Colors.grey.shade700,
                  size: 28,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildHomeContent() {
    if (_wardenHostelName == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          _buildWelcomeBanner(),
          const SizedBox(height: 24),
          _buildStatsSection(),
          const SizedBox(height: 24),
          _buildMenuSection(),
          const SizedBox(height: 24),
          const Text("Recent Activity",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildRecentActivityList(),
        ],
      ),
    );
  }

Widget _buildWelcomeBanner() {
    return Container(
      width: double.infinity,
      height: 150.0,
      padding: const EdgeInsets.all(24),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [ Color.fromARGB(255, 13, 40, 92), Color.fromARGB(255, 50, 96, 212)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -15,
            bottom: -15,
            child: Icon(
              Icons.school,
              size: 130,
              color: Colors.white.withOpacity(0.15),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Welcome Back!",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Manage your outpass requests easily",
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return FutureBuilder<List<int>>(
      future: Future.wait([
        _getOutpassCountByStatus(['approved']),
        _getOutpassCountByStatus(['rejected']),
      ]),
      builder: (context, snapshot) {
        final approvedCount = snapshot.data?[0] ?? 0;
        final rejectedCount = snapshot.data?[1] ?? 0;

        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.check_circle,
                color: Colors.green,
                label: "Approved",
                count: approvedCount,
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const WardenOutpassHistoryScreen(
                      title: 'Approved Outpasses',
                      statuses: ['approved'],
                    ),
                  ));
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                icon: Icons.cancel,
                color: Colors.red,
                label: "Rejected",
                count: rejectedCount,
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const WardenOutpassHistoryScreen(
                      title: 'Rejected Outpasses',
                      statuses: ['rejected'],
                    ),
                  ));
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color color,
    required String label,
    required int count,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 5)
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(count.toString(),
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                Text(label, style: TextStyle(color: Colors.grey.shade600)),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildMenuSection() {
    return Column(
      children: [
        FutureBuilder<int>(
          future: _getOutpassCountByStatus(['pending']),
          builder: (context, snapshot) {
            final count = snapshot.data;
            return _buildMenuCard(
              icon: Icons.hourglass_empty,
              iconBgColor: Colors.orange,
              title: "Pending Outpasses",
              subtitle: "Review your pending requests",
              count: count,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (context) =>
                    const WardenPendingOutpassesListScreen(),
              )),
            );
          },
        ),
        const SizedBox(height: 12),
        _buildMenuCard(
          icon: Icons.assessment,
          iconBgColor: Colors.blue,
          title: "Generate Reports",
          subtitle: "Download your outpass history",
          onTap: () => _onItemTapped(1),
        ),
      ],
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    int? count,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 5)
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: iconBgColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: iconBgColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(subtitle,
                      style: TextStyle(
                          color: Colors.grey.shade600, fontSize: 14)),
                ],
              ),
            ),
            if (count != null && count > 0)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(12)),
                child: Text(count.toString(),
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios,
                size: 16, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivityList() {
    final query = _firestore
        .collection('outpass_requests')
        .orderBy('timestamp', descending: true)
        .limit(5);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        return FutureBuilder<List<DocumentSnapshot>>(
          future: _filterOutpassesByHostel(snapshot.data!.docs),
          builder: (context, filteredSnapshot) {
            if (!filteredSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            if (filteredSnapshot.data!.isEmpty) {
              return const Text("No recent activity found.");
            }

            return Column(
              children: filteredSnapshot.data!.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return FutureBuilder<DocumentSnapshot>(
                  future:
                      _firestore.collection('students').doc(data['userId']).get(),
                  builder: (context, studentSnapshot) {
                    if (!studentSnapshot.hasData) {
                      return const SizedBox.shrink();
                    }
                    final studentName =
                        studentSnapshot.data?['name'] ?? 'A student';
                    return _buildRecentActivityItem(doc.id, data, studentName);
                  },
                );
              }).toList(),
            );
          },
        );
      },
    );
  }

  Widget _buildRecentActivityItem(
      String docId, Map<String, dynamic> data, String studentName) {
    final status = data['wardenApprovalStatus'] ?? 'pending';
    final timestamp =
        (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();

    final Map<String, dynamic> statusConfig = {
      'approved': {
        'icon': Icons.check_circle,
        'color': Colors.green,
        'text': 'Outpass Approved'
      },
      'rejected': {
        'icon': Icons.cancel,
        'color': Colors.red,
        'text': 'Outpass Rejected'
      },
      'pending': {
        'icon': Icons.hourglass_bottom,
        'color': Colors.orange,
        'text': 'New Request Submitted'
      },
    }[status]!;

    return InkWell(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => OutpassDetailScreen(outpassId: docId),
        ));
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 5)
          ],
        ),
        child: Row(
          children: [
            Icon(statusConfig['icon'], color: statusConfig['color']),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(statusConfig['text'],
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    'For $studentName • ${timeago.format(timestamp)}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: statusConfig['color'].withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                status.replaceFirst(status[0], status[0].toUpperCase()),
                style: TextStyle(
                    color: statusConfig['color'],
                    fontWeight: FontWeight.bold,
                    fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<List<DocumentSnapshot>> _filterOutpassesByHostel(
      List<DocumentSnapshot> outpassDocs) async {
    final List<DocumentSnapshot> filteredList = [];
    for (var doc in outpassDocs) {
      final data = doc.data() as Map<String, dynamic>;
      final studentDoc =
          await _firestore.collection('students').doc(data['userId']).get();
      if (studentDoc.exists && studentDoc.data() != null) {
        final studentHostel = studentDoc.data()!['hostel'];
        if (studentHostel == _wardenHostelName) {
          filteredList.add(doc);
        }
      }
    }
    return filteredList;
  }
}