import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'student_outpass_details_screen.dart';

class OutingsScreen extends StatefulWidget {
  const OutingsScreen({super.key});

  @override
  State<OutingsScreen> createState() => _OutingsScreenState();
}

class _OutingsScreenState extends State<OutingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  String _leaveType = 'Home Town (College)';
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  String? _destination;
  String? _reason;
  bool _availBus = false;
  Stream<QuerySnapshot>? _historyStream;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _historyStream = FirebaseFirestore.instance
          .collection('outpass_requests')
          .where('userId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .snapshots();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        controller.text = DateFormat.yMd().format(picked);
      });
    }
  }

  Future<void> _requestPass() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final docRef =
            await FirebaseFirestore.instance.collection('outpass_requests').add({
          'userId': user.uid,
          'leaveType': _leaveType,
          'from': _fromController.text,
          'to': _toController.text,
          'destination': _destination,
          'reason': _reason,
          'availBus': _availBus,
          'timestamp': FieldValue.serverTimestamp(),
          'status': 'pending',
        });

        final qrImageData = await QrPainter(
          data: docRef.id,
          version: QrVersions.auto,
          gapless: false,
        ).toImageData(200);

        final storageRef = FirebaseStorage.instance
            .ref()
            .child('qr_codes')
            .child('${docRef.id}.png');
        await storageRef.putData(qrImageData!.buffer.asUint8List());
        final downloadUrl = await storageRef.getDownloadURL();

        await docRef.update({'qr_code': downloadUrl});

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pass requested successfully!')),
        );
        _formKey.currentState!.reset();
        _fromController.clear();
        _toController.clear();
        // The StreamBuilder for _historyStream will automatically
        // update when a new document is added to Firestore,
        // so no need to re-initialize the stream here.
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Outpass'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.add), text: 'Request Pass'),
            Tab(icon: Icon(Icons.history), text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRequestPassForm(),
          _buildHistoryView(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildRequestPassForm() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Leave Type', // Added label for clarity
                ),
                value: _leaveType,
                items: ['Home Town (College)', 'Local']
                    .map((label) => DropdownMenuItem(
                          value: label,
                          child: Text(label),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _leaveType = value!;
                  });
                },
                validator: (value) => value == null ? 'Please select a leave type' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _fromController,
                decoration: const InputDecoration(
                  labelText: 'From Date', // Changed label to be more specific
                  prefixIcon: Icon(Icons.calendar_today),
                  border: OutlineInputBorder(),
                ),
                readOnly: true,
                onTap: () => _selectDate(context, _fromController),
                validator: (value) => value!.isEmpty ? 'Please select a start date' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _toController,
                decoration: const InputDecoration(
                  labelText: 'To Date', // Changed label to be more specific
                  prefixIcon: Icon(Icons.calendar_today),
                  border: OutlineInputBorder(),
                ),
                readOnly: true,
                onTap: () => _selectDate(context, _toController),
                validator: (value) => value!.isEmpty ? 'Please select an end date' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Destination',
                  prefixIcon: Icon(Icons.location_city),
                  border: OutlineInputBorder(),
                ),
                onSaved: (value) => _destination = value,
                validator: (value) => value!.isEmpty ? 'Please enter a destination' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Reason',
                  prefixIcon: Icon(Icons.help_outline),
                  border: OutlineInputBorder(),
                ),
                onSaved: (value) => _reason = value,
                validator: (value) => value!.isEmpty ? 'Please enter a reason' : null,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Text('Are you leaving by BUS ?'),
                    const Spacer(),
                    Checkbox(
                      value: _availBus,
                      onChanged: (value) {
                        setState(() {
                          _availBus = value!;
                        });
                      },
                    ),
                    const Text('Avail Bus Transport'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _requestPass,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50), // Make button full width
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Request Pass', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryView() {
    if (_historyStream == null) {
      return const Center(child: Text('Please log in to see your history.'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _historyStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No pass requests found.'));
        }

        return ListView(
          padding: const EdgeInsets.all(8.0), // Added padding for better aesthetics
          children: snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final timestamp = data['timestamp'] as Timestamp?;
            final formattedDate = timestamp != null
                ? DateFormat('MMM dd, yyyy - hh:mm a').format(timestamp.toDate())
                : 'N/A';

            return GestureDetector(
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => StudentOutpassDetailsScreen(outpassId: doc.id),
                ));
              },
              child: Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6), // Adjusted margin
                elevation: 3, // Added elevation for card
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), // Rounded corners
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['leaveType'] ?? 'Unknown Leave Type',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16, color: Colors.deepPurple), // Styled text
                    ),
                    const Divider(height: 16), // Added a divider
                    _buildHistoryDetailRow(Icons.calendar_today, 'Period:', '${data['from'] ?? 'N/A'} to ${data['to'] ?? 'N/A'}'),
                    _buildHistoryDetailRow(Icons.location_on, 'Destination:', data['destination'] ?? 'N/A'),
                    _buildHistoryDetailRow(Icons.description, 'Reason:', data['reason'] ?? 'N/A'),
                    _buildHistoryDetailRow(Icons.bus_alert, 'Bus Transport:', (data['availBus'] ?? false) ? 'Yes' : 'No'),
                    _buildHistoryDetailRow(Icons.info_outline, 'Status:', data['status'] ?? 'N/A'),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Text(
                        'Requested: $formattedDate',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            );
          }).toList(),
        );
      },
    );
  }

  // Helper widget to build consistent detail rows in history
  Widget _buildHistoryDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Expanded(child: Text(value, style: const TextStyle(color: Colors.black87))),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor, // Use theme card color for consistency
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: BottomNavigationBar(
        backgroundColor: Colors.transparent, // Make it transparent to show container's color
        selectedItemColor: Theme.of(context).primaryColor, // Use theme's primary color
        unselectedItemColor: Colors.grey, // Unselected items
        elevation: 0, // No default elevation
        currentIndex: 0, // Assuming Home is the current view or always selected
        onTap: (index) {
          // Handle navigation here if this navbar is meant for global navigation
          // For now, it's just a placeholder.
          if (index == 0) {
            // Navigate to Home or whatever this tab represents
          } else if (index == 1) {
            // Navigate to Chat
          } else if (index == 2) {
            // Navigate to Profile
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
