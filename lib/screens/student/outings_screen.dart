import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
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
  String? _leaveType;
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
    final Color primaryColor = const Color.fromARGB(255, 13, 40, 92);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: primaryColor,
                  onPrimary: Colors.white,
                  surface: Colors.white,
                  onSurface: Colors.black,
                ), dialogTheme: DialogThemeData(backgroundColor: Colors.white),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        controller.text = DateFormat('MM/dd/yyyy').format(picked);
      });
    }
  }

  Future<void> _requestPass() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final studentDoc = await FirebaseFirestore.instance.collection('students').doc(user.uid).get();
        final studentData = studentDoc.data();
        final String? tutorId = studentData?['tutorId'];

        Map<String, dynamic> outpassData = {
          'userId': user.uid,
          'leaveType': _leaveType,
          'from': _fromController.text,
          'to': _toController.text,
          'destination': _destination,
          'reason': _reason,
          'availBus': _availBus,
          'timestamp': FieldValue.serverTimestamp(),
          'wardenApprovalStatus': 'pending',
        };

        if (_leaveType == 'Home Town (College)') {
          outpassData['tutorApprovalStatus'] = 'pending';
          if (tutorId != null) {
            outpassData['tutorId'] = tutorId;
          }
        }

        final docRef = await FirebaseFirestore.instance.collection('outpass_requests').add(outpassData);

        await docRef.update({'qr_data': docRef.id});

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pass requested successfully!')),
        );
        _formKey.currentState!.reset();
        _fromController.clear();
        _toController.clear();
        setState(() {
          _leaveType = null;
          _availBus = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color.fromARGB(255, 13, 40, 92);

    return Scaffold(
      backgroundColor: Colors.grey[100],
     appBar: PreferredSize(
  preferredSize: const Size.fromHeight(120.0), // Adjust height as needed
  child: AppBar(
    backgroundColor: primaryColor,
    foregroundColor: Colors.white,
    leading: IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => Navigator.of(context).pop(),
    ),
    title: const Text('Outpass Request'),
    actions: [
      IconButton(
        icon: const Icon(Icons.notifications_none),
        onPressed: () {},
      ),
    ],
    bottom: TabBar(
      controller: _tabController,
      labelColor: Colors.white,
      unselectedLabelColor: Colors.white70,
      indicatorColor: Colors.white,
      tabs: const [
        Tab(text: 'Request Pass'),
        Tab(text: 'History'),
      ],
    ),
  ),
),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRequestPassForm(primaryColor),
          _buildHistoryView(),
        ],
      ),
    );
  }

  Widget _buildFormLabel(String label, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          if (icon != null) Icon(icon, size: 18, color: Colors.grey[700]),
          if (icon != null) const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestPassForm(Color primaryColor) {
    // UPDATED: Define a consistent border style for input fields
    const outlineInputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
      borderSide: BorderSide(color: Colors.grey, width: 1.0),
    );

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 2,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFormLabel('Leave Type', icon: Icons.list),
                DropdownButtonFormField<String>(
                  // UPDATED: More explicit decoration to ensure white background
                  decoration: const InputDecoration(
                    hintText: 'Select leave type',
                    filled: true,
                    fillColor: Colors.white,
                    border: outlineInputBorder,
                    enabledBorder: outlineInputBorder,
                    focusedBorder: outlineInputBorder,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                  ),
                  initialValue: _leaveType,
                  items: ['Home Town (College)', 'Home Town (Leave)', 'Local']
                      .map((label) => DropdownMenuItem(
                            value: label,
                            child: Text(label),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _leaveType = value;
                    });
                  },
                  validator: (value) => value == null ? 'Please select a leave type' : null,
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFormLabel('From Date', icon: Icons.calendar_today),
                          TextFormField(
                            controller: _fromController,
                            // UPDATED: More explicit decoration
                            decoration: const InputDecoration(
                              hintText: 'mm/dd/yyyy',
                              filled: true,
                              fillColor: Colors.white,
                              suffixIcon: Icon(Icons.calendar_month),
                              border: outlineInputBorder,
                              enabledBorder: outlineInputBorder,
                              focusedBorder: outlineInputBorder,
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                            ),
                            readOnly: true,
                            onTap: () => _selectDate(context, _fromController),
                            validator: (value) => value!.isEmpty ? 'Select a date' : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFormLabel('To Date', icon: Icons.calendar_today),
                          TextFormField(
                            controller: _toController,
                            // UPDATED: More explicit decoration
                            decoration: const InputDecoration(
                              hintText: 'mm/dd/yyyy',
                              filled: true,
                              fillColor: Colors.white,
                              suffixIcon: Icon(Icons.calendar_month),
                              border: outlineInputBorder,
                              enabledBorder: outlineInputBorder,
                              focusedBorder: outlineInputBorder,
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                            ),
                            readOnly: true,
                            onTap: () => _selectDate(context, _toController),
                            validator: (value) => value!.isEmpty ? 'Select a date' : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildFormLabel('Destination', icon: Icons.location_on),
                TextFormField(
                  decoration: const InputDecoration(
                    hintText: 'Enter destination',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                  ),
                  onSaved: (value) => _destination = value,
                  validator: (value) => value!.isEmpty ? 'Please enter a destination' : null,
                ),
                const SizedBox(height: 20),
                _buildFormLabel('Reason', icon: Icons.chat_bubble_outline),
                TextFormField(
                  decoration: const InputDecoration(
                    hintText: 'Enter reason for outpass',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                  ),
                  maxLines: 4,
                  onSaved: (value) => _reason = value,
                  validator: (value) => value!.isEmpty ? 'Please enter a reason' : null,
                ),
                const SizedBox(height: 10),
                CheckboxListTile(
                  title: const Text("Are you leaving by college bus?"),
                  value: _availBus,
                  onChanged: (bool? value) {
                    setState(() {
                      _availBus = value ?? false;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  activeColor: primaryColor,
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _requestPass,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.send),
                  label: const Text('Submit Request', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
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
          padding: const EdgeInsets.all(8.0),
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
                color: Colors.white,
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['leaveType'] ?? 'Unknown Leave Type',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16, color: Colors.deepPurple),
                      ),
                      const Divider(height: 16),
                      _buildHistoryDetailRow(Icons.calendar_today, 'Period:', '${data['from'] ?? 'N/A'} to ${data['to'] ?? 'N/A'}'),
                      _buildHistoryDetailRow(Icons.location_on, 'Destination:', data['destination'] ?? 'N/A'),
                      _buildHistoryDetailRow(Icons.description, 'Reason:', data['reason'] ?? 'N/A'),
                      _buildHistoryDetailRow(Icons.directions_bus, 'Bus Transport:', (data['availBus'] ?? false) ? 'Yes' : 'No'),
                      _buildHistoryDetailRow(Icons.info_outline, 'Warden Status:', data['wardenApprovalStatus'] ?? 'N/A'),
                      if (data['leaveType'] == 'Home Town (College)')
                        _buildHistoryDetailRow(Icons.info_outline, 'Tutor Status:', data['tutorApprovalStatus'] ?? 'N/A'),
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

  Widget _buildHistoryDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 5),
          Expanded(child: Text(value, style: const TextStyle(color: Colors.black87))),
        ],
      ),
    );
  }
}