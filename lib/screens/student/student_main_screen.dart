import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:accomy/screens/home/student_home_screen.dart';
import 'package:accomy/screens/student/announcements_screen.dart';
import 'package:accomy/screens/student/profile_screen.dart';

class StudentMainScreen extends StatefulWidget {
  final DocumentSnapshot userData;

  const StudentMainScreen({super.key, required this.userData});

  @override
  State<StudentMainScreen> createState() => _StudentMainScreenState();
}

class _StudentMainScreenState extends State<StudentMainScreen> {
  int _selectedIndex = 0;
  late final PageController _pageController;

  String? _selectedAnnouncementId;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  void _navigateToTab(int index, {String? announcementId}) {
    setState(() {
      _selectedIndex = index;
      _selectedAnnouncementId = announcementId;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.ease,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
            // BUG FIX: Do NOT clear the announcement ID here.
            // It will be cleared when the user taps a bottom nav item.
          });
        },
        children: [
          StudentHomeScreen(
            onNavigateToMainTab: _navigateToTab,
            userData: widget.userData,
          ),
          AnnouncementsScreen(
            selectedAnnouncementId: _selectedAnnouncementId,
          ),
          ProfileScreen(userData: widget.userData),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 212, 212, 212),
            blurRadius: 5,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: BottomNavigationBar(
        backgroundColor: Colors.transparent,
        selectedItemColor: const Color.fromARGB(255, 13, 40, 92),
        elevation: 0,
        currentIndex: _selectedIndex,
        // Tapping a nav item will correctly pass a null announcementId,
        // clearing any previous selection.
        onTap: (index) => _navigateToTab(index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.campaign),
            label: 'Announcements',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}