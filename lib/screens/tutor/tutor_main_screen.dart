import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'package:accomy/screens/tutor/tutor_profile_screen.dart';
import 'package:accomy/screens/tutor/tutor_report_screen.dart';
import 'package:accomy/screens/tutor/tutor_pending_outpass_screen.dart';
// A new screen to show details of a single outpass from the activity feed.
import 'package:accomy/screens/tutor/tutor_outpass_detail_screen.dart';

class TutorMainScreen extends StatefulWidget {
  const TutorMainScreen({super.key});

  @override
  State<TutorMainScreen> createState() => _TutorMainScreenState();
}

class _TutorMainScreenState extends State<TutorMainScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _currentUser;
  String? _tutorId;
  String _tutorName = 'Tutor'; // Default name
  int _currentIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser;
    _tutorId = _currentUser?.uid;
    _pageController = PageController();
    _fetchTutorName();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _fetchTutorName() async {
    if (_currentUser == null) return;
    try {
      final doc =
          await _firestore.collection('staff').doc(_currentUser!.uid).get();
      if (doc.exists && doc.data() != null) {
        if (mounted) {
          setState(() {
            _tutorName = doc.data()!['name'] ?? 'Tutor';
          });
        }
      }
    } catch (e) {
      print('Error fetching tutor name: $e');
    }
  }

  /// Fetches the count of outpasses specifically for the current tutor by status.
  Future<int> _getOutpassCountByStatus(List<String> statuses) async {
    if (_tutorId == null) return 0;

    final querySnapshot = await _firestore
        .collection('outpass_requests')
        .where('tutorId', isEqualTo: _tutorId)
        .where('tutorApprovalStatus', whereIn: statuses)
        .get();

    return querySnapshot.docs.length;
  }

  Stream<int> _getPendingOutpassCount() {
    if (_tutorId == null) return Stream.value(0);
    return _firestore
        .collection('outpass_requests')
        .where('tutorId', isEqualTo: _tutorId)
        .where('tutorApprovalStatus', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildHomeContent(),
      if (_tutorId != null)
        TutorReportScreen(tutorId: _tutorId!)
      else
        const Center(child: CircularProgressIndicator()),
      const TutorProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: Colors.grey[50],
      // 1. Conditionally display the AppBar only for the Home tab
      appBar: _currentIndex == 0 ? _buildHomeAppBar() : null,
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          children: pages,
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
            icon: Icon(Icons.home_filled),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assessment_outlined),
            label: 'Reports',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  /// 2. New AppBar for the Home screen
  AppBar _buildHomeAppBar() {
    return AppBar(
      automaticallyImplyLeading: false,
      title: const Text(
        "Tutor Panel",
        style: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 24,
        ),
      ),
      backgroundColor: Colors.grey[50], // Match scaffold background
      elevation: 0,
      actions: [
        IconButton(
          onPressed: () {
            // TODO: Handle notification tap action
          },
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(
                Icons.notifications_none_outlined,
                color: Colors.black54,
                size: 28,
              ),
              Positioned(
                top: -4,
                right: -2,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8), // Add some right padding
      ],
    );
  }

  /// 3. Updated Home Content without the old header
  Widget _buildHomeContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The PageHeader widget has been removed from here.
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
                  "Manage your student outpass requests easily.",
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
                  if (_tutorId != null) {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) =>
                          TutorPendingOutpassScreen(tutorId: _tutorId!),
                    ));
                  }
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
                  if (_tutorId != null) {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) =>
                          TutorPendingOutpassScreen(tutorId: _tutorId!),
                    ));
                  }
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
        StreamBuilder<int>(
          stream: _getPendingOutpassCount(),
          builder: (context, snapshot) {
            final count = snapshot.data;
            return _buildMenuCard(
              icon: Icons.hourglass_empty,
              iconBgColor: Colors.orange,
              title: "Pending Outpasses",
              subtitle: "Review pending student requests",
              count: count,
              onTap: () {
                if (_tutorId != null) {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) =>
                        TutorPendingOutpassScreen(tutorId: _tutorId!),
                  ));
                }
              },
            );
          },
        ),
        const SizedBox(height: 12),
        _buildMenuCard(
          icon: Icons.assessment,
          iconBgColor: Colors.blue,
          title: "Generate Reports",
          subtitle: "View and download outpass history",
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
              blurRadius: 5,
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconBgColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconBgColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            if (count != null && count > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  count.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivityList() {
    if (_tutorId == null) return const Text("Tutor not found.");

    final query = _firestore
        .collection('outpass_requests')
        .where('tutorId', isEqualTo: _tutorId)
        .orderBy('timestamp', descending: true)
        .limit(5);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (snapshot.data!.docs.isEmpty) return const Text("No recent activity found.");

        return Column(
          children: snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return FutureBuilder<DocumentSnapshot>(
              future: _firestore.collection('students').doc(data['userId']).get(),
              builder: (context, studentSnapshot) {
                if (!studentSnapshot.hasData) return const SizedBox.shrink();
                final studentName = studentSnapshot.data?['name'] ?? 'A student';
                return _buildRecentActivityItem(doc.id, data, studentName);
              },
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildRecentActivityItem(String docId, Map<String, dynamic> data, String studentName) {
    final status = data['tutorApprovalStatus'] ?? 'pending';
    final timestamp = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
    
    final Map<String, dynamic> statusConfig = {
      'approved': {'icon': Icons.check_circle, 'color': Colors.green, 'text': 'Outpass Approved'},
      'rejected': {'icon': Icons.cancel, 'color': Colors.red, 'text': 'Outpass Rejected'},
      'pending': {'icon': Icons.hourglass_bottom, 'color': Colors.orange, 'text': 'New Request Submitted'},
    }[status]!;

    return InkWell(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => TutorOutpassDetailScreen(outpassId: docId),
        ));
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 5)],
        ),
        child: Row(
          children: [
            Icon(statusConfig['icon'], color: statusConfig['color']),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(statusConfig['text'], style: const TextStyle(fontWeight: FontWeight.bold)),
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
                style: TextStyle(color: statusConfig['color'], fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}