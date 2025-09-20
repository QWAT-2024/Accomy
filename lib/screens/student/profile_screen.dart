import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:accomy/screens/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _user;
  Map<String, dynamic>? _userData;
  String? _tutorName;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _getUserData();
  }

  Future<void> _getUserData() async {
    _user = _auth.currentUser;
    if (_user != null) {
      final doc = await _firestore.collection('students').doc(_user!.uid).get();
      setState(() {
        _userData = doc.data();
      });
      if (_userData!['tutorId'] != null) {
        _getTutorName(_userData!['tutorId']);
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _getTutorName(String tutorId) async {
    final doc = await _firestore.collection('staff').doc(tutorId).get();
    setState(() {
      _tutorName = doc.data()!['name'];
      _isLoading = false;
    });
  }

  Future<void> _logout() async {
    await _auth.signOut();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _userData == null
              ? const Center(child: Text('No user data found.'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      _buildDetailCard('Name', _userData!['name'] ?? 'N/A'),
                      _buildDetailCard('Email', _userData!['mailId'] ?? 'N/A'),
                      _buildDetailCard('Roll No', _userData!['rollNumber'] ?? 'N/A'),
                      _buildDetailCard('Hostel Name', _userData!['hostel'] ?? 'N/A'),
                      _buildDetailCard('Room No', _userData!['roomNumber'] ?? 'N/A'),
                      _buildDetailCard('Tutor', _tutorName ?? 'N/A'),
                      _buildDetailCard('Phone', _userData!['phoneNumber'] ?? 'N/A'),
                      _buildDetailCard('Primary Address', _userData!['address1'] ?? 'N/A'),
                      _buildDetailCard('Secondary Address', _userData!['address1'] ?? 'N/A'),
                      const SizedBox(height: 30),
                      Center(
                        child: ElevatedButton(
                          onPressed: _logout,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.cyan,
                            padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                            textStyle: const TextStyle(fontSize: 16),
                          ),
                          child: const Text('Logout'),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildDetailCard(String title, String value) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.cyan),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
