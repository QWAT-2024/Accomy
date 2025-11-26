import 'package:accomy/screens/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatefulWidget {
  final String uid;

  const ProfileScreen({super.key, required this.uid});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // State variables for password visibility
  bool _isOldPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ===== THIS IS THE NEW, REDESIGNED DIALOG =====
  Future<void> _showChangePasswordDialog(BuildContext context) async {
    _oldPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();

    return showDialog(
      context: context,
      builder: (context) {
        // Use StatefulBuilder to manage the local state of the dialog (for password visibility)
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xff3f51b5).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.lock_reset_rounded, size: 32, color: Color(0xff3f51b5)),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Change Your Password",
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Enter your current password and a new password to update your credentials.",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 24),

                        // Form Fields
                        TextFormField(
                          controller: _oldPasswordController,
                          obscureText: !_isOldPasswordVisible,
                          decoration: _buildInputDecoration(
                            labelText: 'Current Password',
                            prefixIcon: Icons.lock_outline,
                            isVisible: _isOldPasswordVisible,
                            onToggleVisibility: () {
                              setDialogState(() => _isOldPasswordVisible = !_isOldPasswordVisible);
                            },
                          ),
                          validator: (value) => value!.isEmpty ? 'Please enter your current password' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _newPasswordController,
                          obscureText: !_isNewPasswordVisible,
                          decoration: _buildInputDecoration(
                            labelText: 'New Password',
                            prefixIcon: Icons.lock,
                            isVisible: _isNewPasswordVisible,
                            onToggleVisibility: () {
                              setDialogState(() => _isNewPasswordVisible = !_isNewPasswordVisible);
                            },
                          ),
                          validator: (value) {
                            if (value!.isEmpty) return 'Please enter a new password';
                            if (value.length < 6) return 'Password must be at least 6 characters';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: !_isConfirmPasswordVisible,
                          decoration: _buildInputDecoration(
                            labelText: 'Confirm New Password',
                            prefixIcon: Icons.lock,
                            isVisible: _isConfirmPasswordVisible,
                            onToggleVisibility: () {
                              setDialogState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible);
                            },
                          ),
                          validator: (value) {
                            if (value != _newPasswordController.text) return 'Passwords do not match';
                            return null;
                          },
                        ),
                        const SizedBox(height: 32),

                        // Action Buttons
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xff3f51b5),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: _changePassword,
                            child: const Text("Update Password", style: TextStyle(fontSize: 16)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text("Cancel", style: TextStyle(color: Colors.grey.shade700)),
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

  /// Helper method to create styled InputDecoration for password fields
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
        icon: Icon(isVisible ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
        onPressed: onToggleVisibility,
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: Color(0xff3f51b5), width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
    );
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final user = _auth.currentUser;
    final cred = EmailAuthProvider.credential(
      email: user!.email!,
      password: _oldPasswordController.text,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(_newPasswordController.text);

      if (!mounted) return;
      Navigator.of(context).pop(); // Dismiss loading
      Navigator.of(context).pop(); // Dismiss dialog

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated successfully!'), backgroundColor: Colors.green),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Dismiss loading

      String errorMessage = 'An error occurred. Please try again.';
      if (e.code == 'wrong-password') {
        errorMessage = 'The current password you entered is incorrect.';
      } else if (e.code == 'weak-password') {
        errorMessage = 'The new password is too weak.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An unexpected error occurred: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final staffRef = FirebaseFirestore.instance.collection('staff').doc(widget.uid);

    return FutureBuilder<DocumentSnapshot>(
      future: staffRef.get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text("No profile found"));
        }

        var data = snapshot.data!.data() as Map<String, dynamic>;
        final String? imageUrl = data['imageUrl'];

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          child: Column(
            children: [
              _buildProfileHeader(
                context,
                name: data['name'] ?? 'N/A',
                role: data['role'] ?? 'N/A',
                imageUrl: imageUrl,
              ),
              const SizedBox(height: 24),
              _buildPersonalInfoCard(context, data),
              const SizedBox(height: 24),
              _buildActionButtons(context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader(BuildContext context, {required String name, required String role, String? imageUrl}) {
    final bool hasImage = imageUrl != null && imageUrl.isNotEmpty;
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey.shade300,
              backgroundImage: hasImage ? NetworkImage(imageUrl) : null,
              child: !hasImage ? const Icon(Icons.person, size: 50, color: Colors.white) : null,
            ),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xff3f51b5),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              padding: const EdgeInsets.all(4),
              child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(role, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _buildPersonalInfoCard(BuildContext context, Map<String, dynamic> data) {
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
          Text("Personal Information", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildInfoRow(context, icon: Icons.person_outline, iconColor: Colors.blue, label: "FULL NAME", value: data['name'] ?? 'N/A'),
          _buildInfoRow(context, icon: Icons.email_outlined, iconColor: Colors.green, label: "EMAIL", value: data['mailId'] ?? 'N/A'),
          _buildInfoRow(context, icon: Icons.phone_outlined, iconColor: Colors.purple, label: "PHONE NUMBER", value: data['phoneNumber'] ?? 'N/A'),
          _buildInfoRow(context, icon: Icons.work_outline, iconColor: Colors.orange, label: "ROLE", value: data['role'] ?? 'N/A'),
          _buildInfoRow(context, icon: Icons.business_outlined, iconColor: Colors.red, label: "DEPARTMENT", value: data['department'] ?? 'N/A'),
          _buildInfoRow(context, icon: Icons.transgender, iconColor: Colors.blue.shade700, label: "GENDER", value: data['gender'] ?? 'N/A'),
          _buildInfoRow(context, icon: Icons.location_on_outlined, iconColor: Colors.teal, label: "ADDRESS", value: data['address'] ?? 'N/A'),
          _buildInfoRow(context, icon: Icons.badge_outlined, iconColor: Colors.amber, label: "STAFF ID", value: data['staffId'] ?? 'N/A'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, {required IconData icon, required Color iconColor, required String label, required String value}) {
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
                Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600)),
                const SizedBox(height: 2),
                Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
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
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.lock_outline),
            label: const Text("Change Password"),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey.shade800,
              side: BorderSide(color: Colors.grey.shade300),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => _showChangePasswordDialog(context),
          ),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          icon: const Icon(Icons.logout),
          label: const Text("Sign Out"),
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          onPressed: () async {
            await FirebaseAuth.instance.signOut();
            if (!context.mounted) return;
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const LoginScreen()),
              (Route<dynamic> route) => false,
            );
          },
        )
      ],
    );
  }
}