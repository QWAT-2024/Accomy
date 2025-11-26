import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // For date formatting

class RaiseComplaintScreen extends StatefulWidget {
  const RaiseComplaintScreen({super.key});

  @override
  State<RaiseComplaintScreen> createState() => _RaiseComplaintScreenState();
}

class _RaiseComplaintScreenState extends State<RaiseComplaintScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Form fields for Raise Complaint
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _descriptionController = TextEditingController();
  String? _selectedComplaintType;
  String _hostelName = 'Fetching...';
  User? _currentUser;
  bool _isLoading = true; // For fetching student data and submitting complaint

  // For View Complaints
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchStudentData();
  }

  Future<void> _fetchStudentData() async {
    _currentUser = _auth.currentUser;
    if (_currentUser != null) {
      final studentDoc = await _firestore.collection('students').doc(_currentUser!.uid).get();
      if (mounted) {
        if (studentDoc.exists && studentDoc.data() != null) {
          setState(() {
            _hostelName = studentDoc.data()!['hostel'] ?? 'N/A';
            _isLoading = false;
          });
        } else {
          setState(() {
            _hostelName = 'Not found';
            _isLoading = false;
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _hostelName = 'Not logged in';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _submitComplaint() async {
    if (_formKey.currentState!.validate()) {
      if (_currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not logged in.')),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        await _firestore.collection('complaints').add({
          'studentId': _currentUser!.uid,
          'hostelName': _hostelName,
          'complaintType': _selectedComplaintType,
          'description': _descriptionController.text.trim(),
          'timestamp': FieldValue.serverTimestamp(),
          'status': 'Pending', // Initial status
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Complaint submitted successfully!')),
        );
        _descriptionController.clear();
        setState(() {
          _selectedComplaintType = null;
          _isLoading = false;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit complaint: $e')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Define the consistent primary color
    final Color primaryColor = const Color.fromARGB(255, 28, 54, 105);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Complaint Management'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Raise Complaint', icon: Icon(Icons.edit)),
            Tab(text: 'View Complaints', icon: Icon(Icons.list_alt)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRaiseComplaintForm(primaryColor),
          _buildViewComplaintsList(primaryColor),
        ],
      ),
    );
  }

  Widget _buildRaiseComplaintForm(Color primaryColor) {
    if (_isLoading && _hostelName == 'Fetching...') {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Hostel Name',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54),
              ),
              const SizedBox(height: 8),
              Text(
                _hostelName,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                dropdownColor: Colors.white,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: 'Select Complaint Type',
                  prefixIcon: Icon(Icons.category_outlined, color: Colors.grey[600]),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(color: primaryColor, width: 2.0),
                  ),
                ),
                initialValue: _selectedComplaintType,
                items: <String>[
                  'Water related issue',
                  'Electricity related issue',
                  'Maintenance related issue',
                  'Food related issue',
                  'Administrative related issue',
                ].map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedComplaintType = newValue;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a complaint type';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _descriptionController,
                maxLines: 5,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  labelText: 'Description',
                  hintText: 'Enter a detailed description...',
                  alignLabelWithHint: true,
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(bottom: 80),
                    child: Icon(Icons.description_outlined, color: Colors.grey[600]),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
                   border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(color: primaryColor, width: 2.0),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  if (value.length < 10) {
                    return 'Description must be at least 10 characters long';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              Center(
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitComplaint,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                          )
                        : const Text('Submit Complaint'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildViewComplaintsList(Color primaryColor) {
    if (_currentUser == null) {
      return const Center(
        child: Text('Please log in to view your complaints.'),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('complaints')
          .where('studentId', isEqualTo: _currentUser!.uid)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No complaints submitted yet.'));
        }

        final complaints = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: complaints.length,
          itemBuilder: (context, index) {
            final complaint = complaints[index].data() as Map<String, dynamic>;
            final timestamp = (complaint['timestamp'] as Timestamp?)?.toDate();
            final formattedDate = timestamp != null
                ? DateFormat('dd MMM yyyy, hh:mm a').format(timestamp)
                : 'N/A';

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      complaint['complaintType'] ?? 'N/A',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor),
                    ),
                    const Divider(height: 16),
                    _buildComplaintDetailRow(
                        Icons.home_work_outlined, 'Hostel:', complaint['hostelName'] ?? 'N/A'),
                    _buildComplaintDetailRow(
                        Icons.description_outlined, 'Description:', complaint['description'] ?? 'N/A'),
                    _buildComplaintDetailRow(
                        Icons.info_outline,
                        'Status:',
                        complaint['status'] ?? 'N/A',
                        valueColor: complaint['status'] == 'Pending'
                            ? Colors.orange.shade700
                            : complaint['status'] == 'Resolved'
                                ? Colors.green.shade700
                                : Colors.red.shade700),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Text(
                        'Submitted: $formattedDate',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildComplaintDetailRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 5),
          Expanded(
              child: Text(
            value,
            style: TextStyle(color: valueColor ?? Colors.black87, fontWeight: valueColor != null ? FontWeight.bold : FontWeight.normal),
          )),
        ],
      ),
    );
  }
}