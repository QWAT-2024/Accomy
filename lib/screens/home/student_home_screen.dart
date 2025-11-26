import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:accomy/screens/student/outings_screen.dart';
import 'package:accomy/screens/student/raise_complaint_screen.dart';
import 'package:accomy/screens/student/token_screen.dart';
import 'package:accomy/screens/student/meal_plan_screen.dart';

class StudentHomeScreen extends StatefulWidget {
  final void Function(int, {String? announcementId}) onNavigateToMainTab;
  final DocumentSnapshot userData;

  const StudentHomeScreen({
    super.key,
    required this.onNavigateToMainTab,
    required this.userData,
  });

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
      appBar: _buildCustomHeader(),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Recent Announcements',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildAnnouncements(),
              const SizedBox(height: 24),
              const Text(
                'Quick Services',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildGridMenu(context),
            ],
          ),
        ),
      ),
    );
  }
  
  PreferredSizeWidget _buildCustomHeader() {
    final Map<String, dynamic> data =
        widget.userData.data() as Map<String, dynamic>;
    final String name = data['name'] ?? 'Student';
    final String? imageUrl = data['imageUrl'];

    return AppBar(
      backgroundColor: const Color.fromARGB(255, 13, 40, 92),
      automaticallyImplyLeading: false,
      elevation: 0,
      toolbarHeight: 135,
      title: const SizedBox.shrink(),
      flexibleSpace: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left-side content
              Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundImage: imageUrl != null && imageUrl.isNotEmpty
                        ? NetworkImage(imageUrl)
                        : const NetworkImage(
                            'https://www.pngitem.com/pimgs/m/146-1468479_my-profile-icon-blank-profile-picture-circle-hd.png'),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Welcome Back',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Right-side content
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications_none,
                    color: Colors.white, size: 28),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnnouncements() {
    return SizedBox(
      height: 160,
      child: StreamBuilder<QuerySnapshot>(
        stream: _announcementsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No announcements'));
          }
          final announcements = snapshot.data!.docs;
          return AnnouncementsPageView(
            announcements: announcements,
            onNavigateToMainTab: widget.onNavigateToMainTab,
          );
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
      childAspectRatio: 0.95,
      children: [
        _buildGridItem(
          context,
          'Outpass/Leave',
          const OutingsScreen(),
          'assets/Outpass_leave.json',
        ),
        _buildGridItem(
          context,
          'Meal Plan',
          const MealPlanScreen(),
          'assets/meal_plan.json',
        ),
        _buildGridItem(
          context,
          'Raise Complaint',
          const RaiseComplaintScreen(),
          'assets/complaints.json',
        ),
        _buildGridItem(
          context,
          'Food Token',
          const TokenScreen(),
          'assets/Food_token.json',
        ),
      ],
    );
  }

  Widget _buildGridItem(BuildContext context, String title, Widget screen,
      String lottieAsset) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context)
            .push(
              MaterialPageRoute(builder: (context) => screen),
            )
            .then((result) {
          if (result is int) {
            widget.onNavigateToMainTab(result);
          }
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(255, 200, 200, 200),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 130,
              width: 130,
              child: Lottie.asset(lottieAsset),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AnnouncementsPageView extends StatefulWidget {
  final List<DocumentSnapshot> announcements;
  final void Function(int, {String? announcementId}) onNavigateToMainTab;

  const AnnouncementsPageView({
    super.key,
    required this.announcements,
    required this.onNavigateToMainTab,
  });

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
      viewportFraction: 0.85,
      initialPage: _currentPage,
    );
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 4), (Timer timer) {
      if (!mounted) return;
      if (_currentPage < 10000 - 1) {
        _currentPage++;
      } else {
        _currentPage = (widget.announcements.isNotEmpty)
            ? 5000 - (5000 % widget.announcements.length)
            : 0;
      }
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 400),
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

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'N/A';
    final now = DateTime.now();
    final difference = now.difference(timestamp.toDate());

    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.announcements.isEmpty) {
      return const Center(child: Text("No announcements available"));
    }
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: 10000,
            itemBuilder: (context, index) {
              final announcementIndex = index % widget.announcements.length;
              DocumentSnapshot document =
                  widget.announcements[announcementIndex];
              
              return _buildAnnouncementCard(document);
            },
            onPageChanged: (int page) {
              if (mounted) {
                setState(() {
                  _currentPage = page;
                });
              }
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.announcements.length, (index) {
            return Container(
              width: 8.0,
              height: 8.0,
              margin:
                  const EdgeInsets.symmetric(vertical: 10.0, horizontal: 2.0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (_currentPage % widget.announcements.length) == index
                    ? Theme.of(context).primaryColor
                    : Colors.grey.withOpacity(0.5),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildAnnouncementCard(DocumentSnapshot document) {
    Map<String, dynamic> data = document.data()! as Map<String, dynamic>;
    final title = data['title'] ?? 'No Title';
    final description = data['description'] ?? '';
    final timestamp = data['timestamp'] as Timestamp?;
    final timeAgo = _formatTimestamp(timestamp);

    return GestureDetector(
      onTap: () {
        widget.onNavigateToMainTab(1, announcementId: document.id);
      },
      child: Container(
        // FIX: Added vertical margin to prevent shadow clipping
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Text(
                description,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              timeAgo,
              style: const TextStyle(color: Colors.black54, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}