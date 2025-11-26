import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class MealPlanScreen extends StatefulWidget {
  const MealPlanScreen({super.key});

  @override
  State<MealPlanScreen> createState() => _MealPlanScreenState();
}

class _MealPlanScreenState extends State<MealPlanScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _currentUser;

  DateTime _selectedDate = DateTime.now();
  Map<String, dynamic>? _mealPlanData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser;
    _fetchMealPlanForDate(_selectedDate);
  }

  Future<void> _fetchMealPlanForDate(DateTime date) async {
    setState(() {
      _isLoading = true;
      _mealPlanData = null;
    });

    if (_currentUser == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      String documentId = DateFormat('yyyy-MM-dd').format(date);
      final doc = await _firestore.collection('mealPlans').doc(documentId).get();

      if (doc.exists && doc.data() != null) {
        setState(() {
          _mealPlanData = doc.data();
        });
      } else {
        setState(() {
          _mealPlanData = {}; // Use an empty map to signify "no plan"
        });
      }
    } catch (e) {
      print('Error fetching meal plan: $e');
      setState(() {
        _mealPlanData = {}; // Handle error case
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _goToPreviousWeek() {
    setState(() {
      _selectedDate = _selectedDate.subtract(const Duration(days: 7));
      // No need to call fetch here, it will be handled by the date selector logic if needed
    });
  }

  void _goToNextWeek() {
    setState(() {
      _selectedDate = _selectedDate.add(const Duration(days: 7));
      // No need to call fetch here, it will be handled by the date selector logic if needed
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      // REMOVED: The AppBar is no longer here.
      body: Column(
        children: [
          // NEW: The custom image header is now the first widget.
          _buildHeader(context),
          _buildDateSelector(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _mealPlanData == null || _mealPlanData!.isEmpty
                    ? Center(
                        child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'No meal plan has been uploaded for ${DateFormat('MMMM d').format(_selectedDate)}.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
                      ))
                    : SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Column(
                          children: [
                            _buildMealCard(
                              title: 'Morning',
                              time: '7:00 - 10:00 AM',
                              icon: Icons.wb_sunny_outlined,
                              iconColor: Colors.orange,
                              mealData: _mealPlanData!['morning'] ?? {},
                            ),
                            const SizedBox(height: 16),
                            _buildMealCard(
                              title: 'Afternoon',
                              time: '12:00 - 2:00 PM',
                              icon: Icons.fastfood_outlined,
                              iconColor: Colors.redAccent,
                              mealData: _mealPlanData!['afternoon'] ?? {},
                            ),
                            const SizedBox(height: 16),
                            _buildMealCard(
                              title: 'Evening',
                              time: '6:00 - 8:00 PM',
                              icon: Icons.dinner_dining_outlined,
                              iconColor: Colors.blue,
                              mealData: _mealPlanData!['evening'] ?? {},
                            ),
                            const SizedBox(height: 16),
                            _buildMealCard(
                              title: 'Night',
                              time: '9:00 - 10:00 PM',
                              icon: Icons.nightlight_round_outlined,
                              iconColor: Colors.purple,
                              mealData: _mealPlanData!['night'] ?? {},
                            ),
                             const SizedBox(height: 16),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  // --- NEW HEADER WIDGET ---
  Widget _buildHeader(BuildContext context) {
    final headerHeight = MediaQuery.of(context).size.height * 0.25;

    return SizedBox(
      height: headerHeight,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Background Image
          Image.asset(
            'assets/foods.jpg',
            fit: BoxFit.cover,
            // Add a dark overlay for better text contrast
            color: Colors.black.withOpacity(0.2),
            colorBlendMode: BlendMode.darken,
          ),

          // 2. UI Elements on top (Back button and Title)
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row with Back Button
                Padding(
                  padding: const EdgeInsets.only(left: 8.0, top: 4.0),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                    onPressed: () => Navigator.of(context).pop(),
                    // Add a subtle background for better visibility against complex images
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withOpacity(0.2),
                    ),
                  ),
                ),

                // Bottom Row with Title
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Weekly Meal Plan',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          blurRadius: 8.0,
                          color: Colors.black54,
                          offset: Offset(2.0, 2.0),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    DateTime startOfWeek = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
    DateTime endOfWeek = startOfWeek.add(const Duration(days: 6));
    final Color primaryColor = const Color.fromARGB(255, 28, 54, 105);


    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 4)
          )
        ]
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _goToPreviousWeek,
                ),
                Text(
                  'Week of ${DateFormat('MMM d').format(startOfWeek)}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _goToNextWeek,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 7,
              // Center the selected date initially
              controller: ScrollController(initialScrollOffset: (55.0 + 8.0) * (_selectedDate.weekday -1)),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemBuilder: (context, index) {
                DateTime date = startOfWeek.add(Duration(days: index));
                bool isSelected = date.day == _selectedDate.day &&
                    date.month == _selectedDate.month &&
                    date.year == _selectedDate.year;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDate = date;
                    });
                    _fetchMealPlanForDate(date);
                  },
                  child: Container(
                    width: 55,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: isSelected ? primaryColor : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? primaryColor : Colors.grey.shade300,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('E').format(date).toUpperCase(), // MON, TUE
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('d').format(date), // Day number
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealCard({
    required String title,
    required String time,
    required IconData icon,
    required Color iconColor,
    required dynamic mealData,
  }) {
    String items = 'Not available';
    int calories = 0;

    if (mealData is Map && mealData.isNotEmpty) {
      items = mealData['items'] as String? ?? 'Not available';
      calories = (mealData['calories'] as num?)?.toInt() ?? 0;
    }

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: iconColor.withOpacity(0.1),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    time,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            items,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade800, height: 1.5),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Calories: $calories',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}