import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:accomy/screens/login_screen.dart';
import 'package:accomy/screens/student/student_main_screen.dart';
import 'package:accomy/screens/home/tutor_home_screen.dart';
import 'package:accomy/screens/home/warden_home_screen.dart';
import 'package:accomy/screens/home/gate_security_home_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    _redirect();
  }

  Future<void> _redirect() async {
    await Future.delayed(const Duration(seconds: 2)); // Simulate a splash screen

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
      return;
    }

    DocumentSnapshot studentDoc =
        await FirebaseFirestore.instance.collection('students').doc(user.uid).get();

    if (studentDoc.exists) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const StudentMainScreen()),
      );
      return;
    }

    DocumentSnapshot staffDoc =
        await FirebaseFirestore.instance.collection('staff').doc(user.uid).get();

    if (staffDoc.exists) {
      final role = staffDoc.get('role');
      if (role == 'Security') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const GateSecurityHomeScreen()),
        );
      } else if (role == 'Tutor') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const TutorHomeScreen()),
        );
      } else if (role == 'Warden') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const WardenHomeScreen()),
        );
      }
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
