import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:accomy/screens/login_screen.dart';
import 'package:accomy/screens/student/student_main_screen.dart';
import 'package:accomy/screens/home/gate_security_home_screen.dart';
import 'package:accomy/screens/tutor/tutor_main_screen.dart'; // Updated import
import 'package:accomy/screens/warden/warden_main_screen.dart'; // Added import

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final user = snapshot.data;

        if (user == null) {
          print('DEBUG: AuthWrapper - No user logged in, redirecting to LoginScreen.');
          return const LoginScreen();
        }

        // User is logged in, now determine role
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('students').doc(user.uid).get(),
          builder: (context, studentSnapshot) {
            if (studentSnapshot.connectionState == ConnectionState.waiting) {
              print('DEBUG: AuthWrapper - Checking student role (waiting).');
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }
            if (studentSnapshot.hasData && studentSnapshot.data!.exists) {
              print('DEBUG: AuthWrapper - User is a student, redirecting to StudentMainScreen.');
              // Pass the fetched document snapshot to the main screen
              return StudentMainScreen(userData: studentSnapshot.data!);
            }

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('staff').doc(user.uid).get(),
              builder: (context, staffSnapshot) {
                if (staffSnapshot.connectionState == ConnectionState.waiting) {
                  print('DEBUG: AuthWrapper - Checking staff role (waiting).');
                  return const Scaffold(body: Center(child: CircularProgressIndicator()));
                }
                if (staffSnapshot.hasData && staffSnapshot.data!.exists) {
                  print('DEBUG: AuthWrapper - Staff data: ${staffSnapshot.data!.data()}'); // Print raw staff data
                  final role = staffSnapshot.data!.get('role');
                  print('DEBUG: AuthWrapper - User is staff with role: $role, redirecting accordingly.');
                  switch (role) {
                    case 'Tutor':
                      return const TutorMainScreen();
                    case 'Warden':
                      return const WardenMainScreen(); // Navigate to WardenMainScreen
                    case 'Security':
                      return GateSecurityHomeScreen(uid: user.uid);
                    default:
                      // If staff role is not recognized, redirect to login
                      return const LoginScreen();
                  }
                }

                print('DEBUG: AuthWrapper - User not found in students or staff, redirecting to LoginScreen.');
                return const LoginScreen();
              },
            );
          },
        );
      },
    );
  }
}