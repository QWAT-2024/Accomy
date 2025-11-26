import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';
import 'package:accomy/screens/security/profile_screen.dart';
import 'package:accomy/screens/security/qr_scanner_screen.dart';
import 'package:accomy/screens/security/student_out_list_page.dart';
import 'package:accomy/screens/security/college_in_list_page.dart';
import 'package:accomy/screens/security/hostel_in_list_page.dart';
import 'package:accomy/screens/security/completed_list_page.dart';

class GateSecurityHomeScreen extends StatefulWidget {
  final String uid;

  const GateSecurityHomeScreen({super.key, required this.uid});

  @override
  State<GateSecurityHomeScreen> createState() => _GateSecurityHomeScreenState();
}

class _GateSecurityHomeScreenState extends State<GateSecurityHomeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  int _selectedIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Stream<int> _getOutpassCount(String statusFilter, {List<String>? leaveTypeFilter}) {
    Query query = _firestore.collection('outpass_requests').where('wardenApprovalStatus', isEqualTo: 'approved');
    return query.snapshots().map((snapshot) {
      final filteredDocs = snapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final leaveType = data['leaveType'];
        final tutorApprovalStatus = data['tutorApprovalStatus'];
        final currentStage = data['currentStage'] ?? 'approved';

        if (leaveType == 'Home Town (College)' && tutorApprovalStatus != 'approved') return false;
        if (statusFilter == 'approved') return currentStage == 'approved';
        if (statusFilter == 'student_out') return currentStage == 'student_out' && (leaveTypeFilter == null || leaveTypeFilter.contains(leaveType));
        if (statusFilter == 'hostel_in_pending') {
          if (leaveType == 'Local') return currentStage == 'student_out';
          return currentStage == 'college_in';
        }
        if (statusFilter == 'completed') return currentStage == 'hostel_in';
        return false;
      }).toList();
      return filteredDocs.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() => _selectedIndex = index);
        },
        children: [
          _buildHomeBody(),
          ProfileScreen(uid: widget.uid),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const QRScannerScreen())),
              backgroundColor: const Color(0xff3f51b5),
              child: const Icon(Icons.widgets_outlined, color: Colors.white),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        elevation: 0,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: SizedBox(
          height: 60.0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              _buildBottomNavItem(Icons.home, 'Home', 0),
              const SizedBox(width: 40),
              _buildBottomNavItem(Icons.person, 'Profile', 1),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    if (_selectedIndex == 1) {
      return AppBar(
        automaticallyImplyLeading: false,
        title: const Text("Profile", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      );
    } else {
      return AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xff3f51b5).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.security, color: Color(0xff3f51b5)),
            ),
            const SizedBox(width: 12),
            const Text('Security Portal', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }
  }

  Widget _buildHomeBody() {
    return ListView(
      padding: const EdgeInsets.all(10.0),
      children: [
        // 1. Increased Lottie animation height
        Lottie.asset(
          'assets/security.json',
          height: 330,
        ),

       
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12, // Reduced spacing
          mainAxisSpacing: 12,  // Reduced spacing
          childAspectRatio: 1.0, // 2. Adjusted aspect ratio to make cards smaller
          children: [
            _buildSummaryCard(
              iconData: Icons.exit_to_app,
              title: 'Student Out',
              subtitle: 'Pending outpasses',
              countStream: _getOutpassCount('approved'),
              color: Colors.red,
              backgroundColor: const Color(0xFFFEECEB),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const StudentOutListPage())),
            ),
            _buildSummaryCard(
              iconData: Icons.school_outlined,
              title: 'College In',
              subtitle: 'Ready for college entry',
              countStream: _getOutpassCount('student_out', leaveTypeFilter: ['Home Town (College)', 'Home Town (Leave)']),
              color: Colors.orange,
              backgroundColor: const Color(0xFFFFF9E8),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const CollegeInListPage())),
            ),
            _buildSummaryCard(
              iconData: Icons.king_bed_outlined,
              title: 'Hostel In',
              subtitle: 'Ready for hostel entry',
              countStream: _getOutpassCount('hostel_in_pending'),
              color: Colors.green,
              backgroundColor: const Color(0xFFEAF9E9),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const HostelInListPage())),
            ),
            _buildSummaryCard(
              iconData: Icons.check_circle_outline,
              title: 'Completed',
              subtitle: 'Finished processes',
              countStream: _getOutpassCount('completed'),
              color: Colors.blue,
              backgroundColor: const Color(0xFFE6F4FE),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const CompletedListPage())),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    final color = isSelected ? const Color(0xff3f51b5) : Colors.grey;
    return Expanded(
      child: InkWell(
        onTap: () => _pageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: color, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  // 3. Modified this widget to make contents smaller
Widget _buildSummaryCard({
  required IconData iconData,
  required String title,
  required String subtitle,
  required Stream<int> countStream,
  required Color color,
  required Color backgroundColor,
  required VoidCallback onTap
}) {
  return Card(
    elevation: 0,
    color: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      // 1. Increased overall padding for better spacing from the edges
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              // 2. Increased padding around the icon
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: backgroundColor, borderRadius: BorderRadius.circular(10)),
              // 3. Made the icon larger
              child: Icon(iconData, color: color, size: 28),
            ),
            // 4. Added more vertical space
            const SizedBox(height: 12),
            // 5. Increased title font size for better readability
            Text(title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            // 6. Increased subtitle font size
            Text(subtitle,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            const Spacer(), // Pushes the bottom row down to fill vertical space
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                StreamBuilder<int>(
                  stream: countStream,
                  builder: (context, snapshot) {
                    // 7. Significantly increased the count font size to be a focal point
                    return Text(
                      snapshot.data?.toString() ?? '0',
                      style: TextStyle(
                          color: color,
                          fontSize: 30,
                          fontWeight: FontWeight.bold),
                    );
                  },
                ),
                // 8. Made the arrow icon slightly larger
                Icon(Icons.arrow_forward_ios,
                    size: 14, color: Colors.grey.shade600),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
}