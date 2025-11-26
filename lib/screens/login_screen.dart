import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart'; // Import the lottie package
import 'package:accomy/screens/student/student_main_screen.dart';
import 'package:accomy/screens/tutor/tutor_main_screen.dart'; // Updated import for Tutor
import 'package:accomy/screens/warden/warden_main_screen.dart';
import 'package:accomy/screens/home/gate_security_home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _email;
  String? _password;
  String _userType = 'Student'; // 'Student' or 'Staff'
  bool _isPasswordVisible = false;
  final _auth = FirebaseAuth.instance;

  // Define a consistent dark blue color
  static const Color darkBlueColor = Color(0xFF1A237E);

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      try {
        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: _email!,
          password: _password!,
        );

        if (mounted) {
          if (_userType == 'Student') {
            DocumentSnapshot studentDoc = await FirebaseFirestore.instance
                .collection('students')
                .doc(userCredential.user!.uid)
                .get();

            if (studentDoc.exists) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => StudentMainScreen(userData: studentDoc)),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Student details not found.')),
              );
              await _auth.signOut();
            }
          } else { // Staff login
            DocumentSnapshot staffDoc = await FirebaseFirestore.instance
                .collection('staff')
                .doc(userCredential.user!.uid)
                .get();

            if (staffDoc.exists) {
              String userRole = staffDoc.get('role');

              Widget destination;

              if (userRole.toLowerCase() == 'security') {
                destination = GateSecurityHomeScreen(uid: userCredential.user!.uid);
              } else if (userRole.toLowerCase() == 'warden') {
                destination = const WardenMainScreen();
              } else if (userRole.toLowerCase() == 'tutor') {
                destination = const TutorMainScreen();
              } else {
                // fallback if role not recognized
                destination = const TutorMainScreen();
              }
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => destination),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Staff details not found.')),
              );
              await _auth.signOut();
            }
          }
        }
      } on FirebaseAuthException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Login failed.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30), // Reduced top padding
              Center(
                // Use Lottie for the animation
                child: Lottie.asset(
                  'assets/login.json', // Your animation file
                  height: 330, // Further increased animation size
                ),
              ),
              const SizedBox(height: 15), // Reduced space
              Text(
                'Hello, Welcome',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Experience Hassle-Free Hostel Living!',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 20),
              
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildUserTypeSelector(),
                    const SizedBox(height: 20.0),

                    // Email Address Field
                    const Text(
                      'Email Address',
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 6.0),
                    TextFormField(
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: 'Enter your email',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        prefixIcon: const Icon(Icons.email_outlined, color: Colors.grey),
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty || !value.contains('@')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _email = value;
                      },
                    ),
                    const SizedBox(height: 16.0),

                    // Password Field
                    const Text(
                      'Password',
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 6.0),
                    TextFormField(
                      obscureText: !_isPasswordVisible,
                      decoration: InputDecoration(
                        hintText: 'Enter your password',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _password = value;
                      },
                    ),
                    const SizedBox(height: 10),

                    // Forgot Password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          // TODO: Implement forgot password
                        },
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(
                            color: darkBlueColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Sign In Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: darkBlueColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          elevation: 5,
                        ),
                        icon: const Icon(Icons.login),
                        label: Text(
                          'Sign In as $_userType',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget builder for the full-width user type toggle selector
  Widget _buildUserTypeSelector() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildToggleButton('Student'),
          _buildToggleButton('Staff'),
        ],
      ),
    );
  }

  // Helper widget to build each option in the toggle selector
  Widget _buildToggleButton(String title) {
    bool isSelected = _userType == title;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _userType = title;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? darkBlueColor : Colors.transparent,
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                title == 'Student' ? Icons.school : Icons.co_present,
                color: isSelected ? Colors.white : Colors.grey[700],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isSelected ? Colors.white : Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}