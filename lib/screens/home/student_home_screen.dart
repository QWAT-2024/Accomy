import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:accomy/screens/student/outings_screen.dart';
import 'package:accomy/screens/student/complaint_screen.dart';
import 'package:accomy/screens/student/token_screen.dart';
import 'package:accomy/screens/student/meal_plan_screen.dart';
import 'package:intl/intl.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  final Stream<QuerySnapshot> _announcementsStream = FirebaseFirestore.instance
      .collection('announcements')
      .orderBy('timestamp', descending: true)
      .snapshots();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Announcements',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildAnnouncements(),
              const SizedBox(height: 24),
              _buildGridMenu(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnnouncements() {
    return SizedBox(
      height: 100,
      child: StreamBuilder<QuerySnapshot>(
        stream: _announcementsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Text('Something went wrong');
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No announcements'));
          }

          final announcements = snapshot.data!.docs;
          return AnnouncementsPageView(announcements: announcements);
        },
      ),
    );
  }

  Widget _buildGridMenu(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildGridItem(context, 'Outings / Leave', 'assets/outing.png', const OutingsScreen()),
        _buildGridItem(context, 'Raise a complaint', 'assets/complaint.png', const ComplaintScreen()),
        _buildGridItem(context, 'Get your token', 'assets/token.png', const TokenScreen()),
        _buildGridItem(context, 'Meal plan', 'assets/meal.png', const MealPlanScreen()),
      ],
    );
  }

  Widget _buildGridItem(BuildContext context, String title, String imagePath, Widget screen) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => screen),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(255, 223, 232, 239).withOpacity(0.6),
              spreadRadius: 1,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontSize: 16,
                  ),
                ),
              ),
              Expanded(
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AnnouncementsPageView extends StatefulWidget {
  final List<DocumentSnapshot> announcements;

  const AnnouncementsPageView({super.key, required this.announcements});

  @override
  State<AnnouncementsPageView> createState() => _AnnouncementsPageViewState();
}

class _AnnouncementsPageViewState extends State<AnnouncementsPageView> {
  late PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    if (widget.announcements.isNotEmpty) {
      _currentPage = 5000 - (5000 % widget.announcements.length);
    }
    _pageController = PageController(
      viewportFraction: 0.8,
      initialPage: _currentPage,
    );
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 3), (Timer timer) {
      if (_currentPage < 10000 - 1) {
        _currentPage++;
      } else {
        if (widget.announcements.isNotEmpty) {
          _currentPage = 5000 - (5000 % widget.announcements.length);
        } else {
          _currentPage = 0;
        }
      }
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeIn,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _pageController,
      itemCount: 10000, // A large number for "infinite" effect
      itemBuilder: (context, index) {
        final announcementIndex = index % widget.announcements.length;
        DocumentSnapshot document = widget.announcements[announcementIndex];
        Map<String, dynamic> data = document.data()! as Map<String, dynamic>;
        final timestamp = data['timestamp'] as Timestamp?;
        final formattedDate = timestamp != null
            ? DateFormat('MMM dd, yyyy - hh:mm a').format(timestamp.toDate())
            : 'N/A';
        return _buildAnnouncementCard(data['title'] ?? 'No Title', formattedDate);
      },
      onPageChanged: (int page) {
        setState(() {
          _currentPage = page;
        });
      },
    );
  }

  Widget _buildAnnouncementCard(String title, String subtitle) {
    return Container(
      width: 250,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 223, 232, 239).withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.blue),
          ),
        ],
      ),
    );
  }
}
