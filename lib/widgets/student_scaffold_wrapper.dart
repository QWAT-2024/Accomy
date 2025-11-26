import 'package:flutter/material.dart';

class StudentScaffoldWrapper extends StatefulWidget {
  final Widget child;

  const StudentScaffoldWrapper({super.key, required this.child});

  @override
  State<StudentScaffoldWrapper> createState() => _StudentScaffoldWrapperState();
}

class _StudentScaffoldWrapperState extends State<StudentScaffoldWrapper> {
  // _selectedIndex is always 0 to visually highlight Home on sub-pages
  final int _selectedIndex = 0;

  void _onItemTapped(int index) {
    // Pop the current sub-route and pass the desired main tab index back
    Navigator.of(context).pop(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          selectedItemColor: Colors.indigo[900],
          elevation: 0,
          currentIndex: _selectedIndex, // Always 0 to highlight Home
          onTap: _onItemTapped,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat),
              label: 'Chat',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
