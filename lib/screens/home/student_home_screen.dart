import 'package:flutter/material.dart';
import 'package:accomy/screens/student/outings_screen.dart';
import 'package:accomy/screens/student/complaint_screen.dart';
import 'package:accomy/screens/student/token_screen.dart';
import 'package:accomy/screens/student/meal_plan_screen.dart';

class StudentHomeScreen extends StatelessWidget {
  const StudentHomeScreen({super.key});

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
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildAnnouncementCard(
              'HOSTEL CLOSURE FOR DIWALI', '23 February 2025, 01:30 PM'),
          _buildAnnouncementCard('Announcement 2', 'Details 2'),
        ],
      ),
    );
  }

  Widget _buildAnnouncementCard(String title, String subtitle) {
    return Container(
      width: 250,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
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
SizedBox(
  height: 153, // Adjust as needed
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
