import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:accomy/screens/student/student_main_screen.dart';
import 'package:accomy/screens/home/staff_home_screen.dart';
import 'package:accomy/screens/home/hosteller_home_screen.dart';
import 'package:accomy/screens/home/gate_security_home_screen.dart';
import 'package:accomy/screens/registration_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _email;
  String? _password;
  String _userType = 'staff'; // 'student' or 'staff'
  String _staffRole = 'tutor'; // Default staff role
  bool _isPasswordVisible = false;
  final _auth = FirebaseAuth.instance;

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      try {
        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: _email!,
          password: _password!,
        );

        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();

        if (userDoc.exists) {
          String userRole = userDoc.get('role');
          bool isRoleCorrect = false;

          if (_userType == 'student' && userRole == 'student') {
            isRoleCorrect = true;
          } else if (_userType == 'staff' &&
              ['tutor', 'warden', 'gate_security', 'staff'].contains(userRole)) {
            isRoleCorrect = true;
          }

          if (isRoleCorrect) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) {
                  switch (userRole) {
                    case 'student':
                      return const StudentMainScreen();
                    case 'staff':
                    case 'tutor':
                    case 'warden':
                    case 'gate_security':
                      return const StaffHomeScreen();
                    default:
                      return const LoginScreen();
                  }
                },
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('The selected role is incorrect.')),
            );
            await _auth.signOut();
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User details not found.')),
          );
          await _auth.signOut();
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 50),
              Center(
                child: Image.asset(
                  'assets/login_vector.jpg',
                  height: 200,
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                'Hello, Welcome',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Experience Hassle-Free Hostel Living!',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Text(
                    'I am',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 20),
                  _buildRoleSelector(),
                ],
              ),
              const SizedBox(height: 20),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'User ID',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your User ID';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _email = value;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      obscureText: !_isPasswordVisible,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.fingerprint),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
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
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    // TODO: Implement forgot password functionality
                  },
                  child: Text(
                    'Forgot Password?',
                    style: TextStyle(color: _userType == 'student' ? Colors.blue : Colors.indigo[900]),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _login,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: _userType == 'student' ? Colors.blue : Colors.indigo[900],
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('LOGIN'),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const RegistrationScreen(),
                    ),
                  );
                },
                child: const Text('Don\'t have an account? Register'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleSelector() {
    final isStudent = _userType == 'student';
    final color = isStudent ? Colors.blue : Colors.indigo[900];

    return GestureDetector(
      onTap: () {
        setState(() {
          _userType = isStudent ? 'staff' : 'student';
        });
      },
      child: Container(
        width: 120,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          children: [
            AnimatedAlign(
              alignment:
                  isStudent ? Alignment.centerRight : Alignment.centerLeft,
              duration: const Duration(milliseconds: 600),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  isStudent ? 'Student' : 'Staff',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            AnimatedAlign(
              alignment:
                  isStudent ? Alignment.centerLeft : Alignment.centerRight,
              duration: const Duration(milliseconds: 600),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: color!, width: 2),
                ),
                child: Icon(
                  isStudent ? Icons.person : Icons.work,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
