import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:accomy/screens/login_screen.dart'; // Make sure this path is correct

class ProfileScreen extends StatefulWidget {
  final DocumentSnapshot userData;
  const ProfileScreen({super.key, required this.userData});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  User? _user;
  Map<String, dynamic>? _userData;
  String? _tutorName;
  String? _imageUrl;
  bool _isLoading = true;

  // State for password visibility
  bool _isOldPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _getUserData();
  }

  Future<void> _getUserData() async {
    _user = _auth.currentUser;
    if (_user != null) {
      final doc = await _firestore.collection('students').doc(_user!.uid).get();
      if (mounted) {
        setState(() {
          _userData = doc.data();
          _imageUrl = _userData?['imageUrl'];
        });
      }

      if (_userData != null && _userData!['tutorId'] != null) {
        await _getTutorName(_userData!['tutorId']);
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _getTutorName(String tutorId) async {
    final doc = await _firestore.collection('staff').doc(tutorId).get();
    if (mounted) {
      setState(() {
        _tutorName = doc.data()?['name'];
        _isLoading = false;
      });
    }
  }

  Future<void> _pickAndUploadImage() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final String userId = _user!.uid;
      final Reference storageRef =
          _storage.ref().child('profile_images').child('$userId.jpg');

      final UploadTask uploadTask = storageRef.putFile(File(image.path));
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      await _firestore
          .collection('students')
          .doc(userId)
          .update({'imageUrl': downloadUrl});

      if (mounted) {
        setState(() {
          _imageUrl = downloadUrl;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload image: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    await _auth.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  void _showChangePasswordDialog() {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final TextEditingController currentPasswordController =
        TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController =
        TextEditingController();
    bool isChangingPassword = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0)),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 13, 40, 92)
                                .withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.lock_reset_rounded,
                              size: 32,
                              color: Color.fromARGB(255, 13, 40, 92)),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Change Your Password",
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Enter your current password and a new password to update your credentials.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 14, color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: currentPasswordController,
                          obscureText: !_isOldPasswordVisible,
                          decoration: _buildInputDecoration(
                            labelText: 'Current Password',
                            prefixIcon: Icons.lock_outline,
                            isVisible: _isOldPasswordVisible,
                            onToggleVisibility: () {
                              setDialogState(() =>
                                  _isOldPasswordVisible = !_isOldPasswordVisible);
                            },
                          ),
                          validator: (value) => value!.isEmpty
                              ? 'Please enter your current password'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: newPasswordController,
                          obscureText: !_isNewPasswordVisible,
                          decoration: _buildInputDecoration(
                            labelText: 'New Password',
                            prefixIcon: Icons.lock,
                            isVisible: _isNewPasswordVisible,
                            onToggleVisibility: () {
                              setDialogState(() =>
                                  _isNewPasswordVisible = !_isNewPasswordVisible);
                            },
                          ),
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'Please enter a new password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: confirmPasswordController,
                          obscureText: !_isConfirmPasswordVisible,
                          decoration: _buildInputDecoration(
                            labelText: 'Confirm New Password',
                            prefixIcon: Icons.lock,
                            isVisible: _isConfirmPasswordVisible,
                            onToggleVisibility: () {
                              setDialogState(() => _isConfirmPasswordVisible =
                                  !_isConfirmPasswordVisible);
                            },
                          ),
                          validator: (value) {
                            if (value != newPasswordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color.fromARGB(255, 13, 40, 92),
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: isChangingPassword
                                ? null
                                : () async {
                                    if (formKey.currentState!.validate()) {
                                      setDialogState(() {
                                        isChangingPassword = true;
                                      });

                                      User? user = _auth.currentUser;
                                      final cred = EmailAuthProvider.credential(
                                          email: user!.email!,
                                          password:
                                              currentPasswordController.text);

                                      try {
                                        await user
                                            .reauthenticateWithCredential(
                                                cred);
                                        await user.updatePassword(
                                            newPasswordController.text);

                                        if (!mounted) return;
                                        Navigator.of(context).pop();
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content: Text(
                                                  'Password changed successfully!'),
                                              backgroundColor: Colors.green),
                                        );
                                      } on FirebaseAuthException catch (e) {
                                        String message = 'An error occurred.';
                                        if (e.code == 'wrong-password') {
                                          message =
                                              'The current password you entered is incorrect.';
                                        } else if (e.code ==
                                            'weak-password') {
                                          message =
                                              'The new password is too weak.';
                                        }
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content: Text(message),
                                              backgroundColor: Colors.red),
                                        );
                                      } finally {
                                        setDialogState(() {
                                          isChangingPassword = false;
                                        });
                                      }
                                    }
                                  },
                            child: isChangingPassword
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text("Update Password",
                                    style: TextStyle(fontSize: 16)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text("Cancel",
                              style: TextStyle(color: Colors.grey.shade700)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  InputDecoration _buildInputDecoration({
    required String labelText,
    required IconData prefixIcon,
    required bool isVisible,
    required VoidCallback onToggleVisibility,
  }) {
    return InputDecoration(
      labelText: labelText,
      prefixIcon: Icon(prefixIcon, color: Colors.grey.shade600),
      suffixIcon: IconButton(
        icon: Icon(isVisible ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey),
        onPressed: onToggleVisibility,
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide:
            const BorderSide(color: Color.fromARGB(255, 13, 40, 92), width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ===== 1. APPBAR REMOVED FROM HERE =====
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _userData == null
                ? const Center(child: Text('No user data found.'))
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 24.0),
                    child: Column(
                      children: [
                        _buildProfileHeader(
                          context,
                          name: _userData!['name'] ?? 'N/A',
                          rollNumber: _userData!['rollNumber'] ?? 'N/A',
                          imageUrl: _imageUrl,
                        ),
                        const SizedBox(height: 24),
                        _buildPersonalInfoCard(context, _userData!),
                        const SizedBox(height: 24),
                        _buildActionButtons(context),
                      ],
                    ),
                  ),
      ),
    );
  }

  // ===== 2. THIS ENTIRE METHOD HAS BEEN REMOVED =====
  // PreferredSizeWidget _buildCustomHeader() { ... }

  Widget _buildProfileHeader(BuildContext context,
      {required String name, required String rollNumber, String? imageUrl}) {
    final bool hasImage = imageUrl != null && imageUrl.isNotEmpty;
    return Column(
      children: [
        // This Stack now includes the camera icon to allow changing the picture
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: 70,
              backgroundColor: Colors.grey.shade300,
              backgroundImage: hasImage ? NetworkImage(imageUrl) : null,
              child: !hasImage
                  ? const Icon(Icons.person, size: 50, color: Colors.white)
                  : null,
            ),
            GestureDetector(
              onTap: _pickAndUploadImage,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 13, 40, 92),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                padding: const EdgeInsets.all(4),
                child:
                    const Icon(Icons.camera_alt, color: Colors.white, size: 16),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          name,
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          rollNumber,
          style: Theme.of(context)
              .textTheme
              .bodyLarge
              ?.copyWith(color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildPersonalInfoCard(
      BuildContext context, Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Personal Information",
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(context,
              icon: Icons.email_outlined,
              iconColor: Colors.green,
              label: "EMAIL",
              value: data['mailId'] ?? 'N/A'),
          _buildInfoRow(context,
              icon: Icons.home_outlined,
              iconColor: Colors.orange,
              label: "HOSTEL",
              value: data['hostel'] ?? 'N/A'),
          _buildInfoRow(context,
              icon: Icons.room_outlined,
              iconColor: Colors.purple,
              label: "ROOM NO",
              value: data['roomNumber'] ?? 'N/A'),
          _buildInfoRow(context,
              icon: Icons.person_search_outlined,
              iconColor: Colors.blue,
              label: "TUTOR",
              value: _tutorName ?? 'N/A'),
          _buildInfoRow(context,
              icon: Icons.phone_outlined,
              iconColor: Colors.red,
              label: "PHONE",
              value: data['phoneNumber'] ?? 'N/A'),
          _buildInfoRow(context,
              icon: Icons.location_on_outlined,
              iconColor: Colors.teal,
              label: "PRIMARY ADDRESS",
              value: data['address1'] ?? 'N/A'),
          _buildInfoRow(context,
              icon: Icons.location_city_outlined,
              iconColor: Colors.amber,
              label: "SECONDARY ADDRESS",
              value: data['address2'] ?? 'N/A'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context,
      {required IconData icon,
      required Color iconColor,
      required String label,
      required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.lock_outline),
            label: const Text("Change Password"),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey.shade800,
              side: BorderSide(color: Colors.grey.shade300),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              _showChangePasswordDialog();
            },
          ),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          icon: const Icon(Icons.logout),
          label: const Text("Sign Out"),
          style: TextButton.styleFrom(
            foregroundColor: Colors.red,
          ),
          onPressed: _logout,
        )
      ],
    );
  }
}