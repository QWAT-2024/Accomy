import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TokenScreen extends StatefulWidget {
  const TokenScreen({super.key});

  @override
  State<TokenScreen> createState() => _TokenScreenState();
}

class _TokenScreenState extends State<TokenScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _currentUser;

  List<Map<String, dynamic>> _foodTokens = [];
  final Map<String, int> _selectedTokens = {};
  Map<String, int> _currentFoodTokens = {};
  bool _isLoading = true;

  // --- NO CHANGES TO DATA LOGIC ---
  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser;
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
    });
    await _fetchFoodTokens();
    await _fetchCurrentStudentTokens();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchFoodTokens() async {
    try {
      final querySnapshot = await _firestore.collection('foodTokens').get();
      if (mounted) {
        setState(() {
          _foodTokens = querySnapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();
          for (var token in _foodTokens) {
            _selectedTokens[token['name']] = 0;
          }
        });
      }
    } catch (e) {
      print('Error fetching food tokens: $e');
    }
  }

  Future<void> _fetchCurrentStudentTokens() async {
    if (_currentUser == null) return;
    try {
      final doc = await _firestore.collection('students').doc(_currentUser!.uid).get();
      if (mounted && doc.exists && doc.data() != null) {
        setState(() {
          _currentFoodTokens = Map<String, int>.from(doc.data()!['selectedFoodTokens'] ?? {});
        });
      }
    } catch (e) {
      print('Error fetching current student tokens: $e');
    }
  }

  void _updateSelectedToken(String name, int quantity) {
    setState(() {
      _selectedTokens[name] = quantity;
    });
  }

  Future<void> _submitTokens() async {
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in.')),
      );
      return;
    }

    final tokensToSubmit = _selectedTokens.entries
        .where((entry) => entry.value > 0)
        .fold<Map<String, int>>({}, (map, entry) {
          map[entry.key] = entry.value;
          return map;
        });

    if (tokensToSubmit.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one food item.')),
      );
      return;
    }

    try {
      await _firestore.collection('students').doc(_currentUser!.uid).set(
        {'selectedFoodTokens': tokensToSubmit},
        SetOptions(merge: true),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Food tokens submitted successfully!')),
      );
      await _fetchCurrentStudentTokens();
      if (mounted) {
        setState(() {
          for (var key in _selectedTokens.keys.toList()) {
            _selectedTokens[key] = 0;
          }
        });
      }
    } catch (e) {
      print('Error submitting tokens: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit tokens: $e')),
      );
    }
  }
  // --- END OF DATA LOGIC ---

  Map<String, dynamic> _getIconForFood(String foodName) {
    switch (foodName.toLowerCase()) {
      case 'apple':
        return {'icon': Icons.apple, 'backgroundColor': Colors.red.shade100, 'iconColor': Colors.red.shade700};
      case 'banana':
        return {'icon': Icons.eco_rounded, 'backgroundColor': Colors.yellow.shade100, 'iconColor': Colors.yellow.shade800};
      case 'bread':
        return {'icon': Icons.bakery_dining, 'backgroundColor': Colors.orange.shade100, 'iconColor': Colors.orange.shade800};
      case 'milk':
        return {'icon': Icons.local_cafe, 'backgroundColor': Colors.blue.shade100, 'iconColor': Colors.blue.shade800};
      case 'cheese':
        return {'icon': Icons.cake_outlined, 'backgroundColor': Colors.yellow.shade200, 'iconColor': Colors.amber.shade900};
      case 'egg':
        return {'icon': Icons.egg_outlined, 'backgroundColor': Colors.grey.shade200, 'iconColor': Colors.orange.shade900};
      case 'chicken':
        return {'icon': Icons.kebab_dining, 'backgroundColor': const Color.fromARGB(255, 255, 226, 226), 'iconColor': const Color.fromARGB(255, 210, 51, 51)};
      case 'cauliflower chilli':
        return {'icon': Icons.local_florist_outlined, 'backgroundColor': Colors.green.shade100, 'iconColor': Colors.green.shade800};
      default:
        return {'icon': Icons.fastfood, 'backgroundColor': Colors.grey.shade200, 'iconColor': Colors.grey.shade700};
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color.fromARGB(255, 28, 54, 105);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      // REMOVED: The AppBar is no longer part of the Scaffold.
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // NEW: The custom image header is the first widget.
                _buildHeader(context),
                
                // The rest of the body content follows, wrapped in an Expanded
                // widget to ensure it fills the remaining space correctly.
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                        child: Text(
                          'Current Food Tokens',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      _currentFoodTokens.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16.0),
                              child: Text('No active food tokens.', style: TextStyle(color: Colors.grey)),
                            )
                          : SizedBox(
                              height: 110,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                itemCount: _currentFoodTokens.length,
                                itemBuilder: (context, index) {
                                  final entry = _currentFoodTokens.entries.elementAt(index);
                                  return _buildCurrentTokenSquareCard(
                                    entry.key,
                                    entry.value,
                                  );
                                },
                              ),
                            ),
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                        child: Text(
                          'Available Food Tokens',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        child: _foodTokens.isEmpty
                            ? const Center(child: Text('No food items available.'))
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                itemCount: _foodTokens.length,
                                itemBuilder: (context, index) {
                                  final token = _foodTokens[index];
                                  final String name = token['name'] ?? 'Unknown';
                                  final int maxCount = token['maxCount'] ?? 0;
                                  final int selectedQuantity = _selectedTokens[name] ?? 0;

                                  return _buildAvailableTokenRow(
                                    name,
                                    maxCount,
                                    selectedQuantity,
                                    (quantity) => _updateSelectedToken(name, quantity),
                                    primaryColor,
                                  );
                                },
                              ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: ElevatedButton.icon(
                          onPressed: _submitTokens,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.check),
                          label: const Text('Submit Food Tokens', style: TextStyle(fontSize: 16)),
                        ),
                      ),
                    ],
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
          Image.asset(
            'assets/food-2.jpg', // Use your new image here
            fit: BoxFit.cover,
            color: Colors.black.withOpacity(0.2),
            colorBlendMode: BlendMode.darken,
          ),
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 8.0, top: 4.0),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                    onPressed: () => Navigator.of(context).pop(),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withOpacity(0.2),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Food Tokens',
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

  Widget _buildCurrentTokenSquareCard(String name, int quantity) {
    final foodInfo = _getIconForFood(name);
    final Color backgroundColor = foodInfo['backgroundColor'];
    final Color iconColor = foodInfo['iconColor'];

    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 12.0),
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.white.withOpacity(0.7),
            child: Icon(foodInfo['icon'], color: iconColor, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: iconColor,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            'Qty: $quantity',
            style: TextStyle(
              fontSize: 12,
              color: iconColor.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableTokenRow(String name, int maxCount, int selectedQuantity, Function(int) onChanged, Color primaryColor) {
    final foodInfo = _getIconForFood(name);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      shadowColor: Colors.grey.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: foodInfo['backgroundColor'],
              child: Icon(foodInfo['icon'], color: foodInfo['iconColor']),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text('Max: $maxCount', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            Row(
              children: [
                InkWell(
                  onTap: selectedQuantity > 0 ? () => onChanged(selectedQuantity - 1) : null,
                  customBorder: const CircleBorder(),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: selectedQuantity > 0 ? Colors.grey : Colors.grey.shade300),
                    ),
                    child: Icon(
                      Icons.remove,
                      color: selectedQuantity > 0 ? Colors.black87 : Colors.grey.shade300,
                    ),
                  ),
                ),
                SizedBox(
                  width: 30,
                  child: Text(
                    selectedQuantity.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                InkWell(
                  onTap: selectedQuantity < maxCount ? () => onChanged(selectedQuantity + 1) : null,
                  customBorder: const CircleBorder(),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: selectedQuantity < maxCount ? primaryColor : Colors.grey.shade300,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add, color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}