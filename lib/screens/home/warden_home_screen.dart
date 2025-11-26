// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';
// import 'package:accomy/screens/student/student_outpass_details_screen.dart'; // Import for navigation

// class _WardenHomeContent extends StatefulWidget {
//   const _WardenHomeContent({super.key});

//   @override
//   State<_WardenHomeContent> createState() => _WardenHomeContentState();
// }

// class _WardenHomeContentState extends State<_WardenHomeContent> with SingleTickerProviderStateMixin {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   User? _currentUser;
//   late TabController _tabController;
//   String? _wardenHostelName; // Add wardenHostelName

//   @override
//   void initState() {
//     super.initState();
//     _currentUser = _auth.currentUser;
//     _tabController = TabController(length: 2, vsync: this);
//     _fetchWardenHostelName(); // Fetch hostel name on init
//   }

//   Future<void> _fetchWardenHostelName() async {
//     if (_currentUser == null) return;
//     try {
//       final doc = await _firestore.collection('staff').doc(_currentUser!.uid).get();
//       if (doc.exists && doc.data() != null) {
//         setState(() {
//           _wardenHostelName = doc.data()!['hostelName'];
//         });
//       }
//     } catch (e) {
//       print('Error fetching warden hostel name: $e');
//     }
//   }

//   @override
//   void dispose() {
//     _tabController.dispose();
//     super.dispose();
//   }

//   Future<void> _updateOutpassStatus(String docId, String status) async {
//     try {
//       await _firestore.collection('outpass_requests').doc(docId).update({
//         'wardenApprovalStatus': status,
//       });
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Outpass status updated to $status by Warden.')),
//       );
//     } catch (e) {
//       print('Error updating outpass status: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to update outpass status: $e')),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_wardenHostelName == null) {
//       return const Center(child: CircularProgressIndicator()); // Show loading while fetching hostel name
//     }
//     return Column(
//       children: [
//         TabBar(
//           controller: _tabController,
//           tabs: const [
//             Tab(text: 'Pending'),
//             Tab(text: 'Approved/Rejected'),
//           ],
//         ),
//         Expanded(
//           child: TabBarView(
//             controller: _tabController,
//             children: [
//               _buildOutpassList(statusFilter: 'pending'),
//               _buildOutpassList(statusFilter: 'approved_rejected'),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildOutpassList({required String statusFilter}) {
//     Query query = _firestore
//         .collection('outpass_requests')
//         .orderBy('timestamp', descending: true); // Remove hostelName filter from query

//     if (statusFilter == 'pending') {
//       query = query.where('wardenApprovalStatus', isEqualTo: 'pending');
//     } else if (statusFilter == 'approved_rejected') {
//       query = query.where('wardenApprovalStatus', whereIn: ['approved', 'rejected']);
//     }

//     return StreamBuilder<QuerySnapshot>(
//       stream: query.snapshots(),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Center(child: CircularProgressIndicator());
//         }
//         if (snapshot.hasError) {
//           return Center(child: Text('Error: ${snapshot.error}'));
//         }
//         if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//           return Center(child: Text('No ${statusFilter.replaceAll('_', '/')} outpass requests found.'));
//         }

//         return FutureBuilder<List<DocumentSnapshot>>(
//           future: _filterOutpassesByHostel(snapshot.data!.docs),
//           builder: (context, filteredSnapshot) {
//             if (filteredSnapshot.connectionState == ConnectionState.waiting) {
//               return const Center(child: CircularProgressIndicator());
//             }
//             if (filteredSnapshot.hasError) {
//               return Center(child: Text('Error filtering outpasses: ${filteredSnapshot.error}'));
//             }
//             final filteredDocs = filteredSnapshot.data ?? [];

//             if (filteredDocs.isEmpty) {
//               return Center(child: Text('No ${statusFilter.replaceAll('_', '/')} outpass requests found for your hostel.'));
//             }

//             return ListView.builder(
//               itemCount: filteredDocs.length,
//               itemBuilder: (context, index) {
//                 final doc = filteredDocs[index];
//                 final data = doc.data() as Map<String, dynamic>;
//                 final timestamp = data['timestamp'] as Timestamp?;
//                 final formattedDate = timestamp != null
//                     ? DateFormat('MMM dd, yyyy - hh:mm a').format(timestamp.toDate())
//                     : 'N/A';

//                 return FutureBuilder<DocumentSnapshot>(
//                   future: _firestore.collection('students').doc(data['userId']).get(),
//                   builder: (context, studentSnapshot) {
//                     String studentName = 'Loading...';
//                     if (studentSnapshot.connectionState == ConnectionState.done && studentSnapshot.hasData) {
//                       studentName = studentSnapshot.data!['name'] ?? 'Unknown Student';
//                     } else if (studentSnapshot.hasError) {
//                       studentName = 'Error fetching student name';
//                     }

//                     return Card(
//                       margin: const EdgeInsets.all(8.0),
//                       elevation: 3,
//                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//                       child: Padding(
//                         padding: const EdgeInsets.all(16.0),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text('Student: $studentName', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
//                             Text('Leave Type: ${data['leaveType'] ?? 'N/A'}'),
//                             Text('From: ${data['from'] ?? 'N/A'} To: ${data['to'] ?? 'N/A'}'),
//                             Text('Destination: ${data['destination'] ?? 'N/A'}'),
//                             Text('Reason: ${data['reason'] ?? 'N/A'}'),
//                             Text('Requested: $formattedDate'),
//                             Text('Warden Status: ${data['wardenApprovalStatus'] ?? 'N/A'}'),
//                             if (data['leaveType'] == 'Home Town (College)')
//                               Text('Tutor Status: ${data['tutorApprovalStatus'] ?? 'N/A'}'),
//                             const SizedBox(height: 10),
//                             Row(
//                               mainAxisAlignment: MainAxisAlignment.end,
//                               children: [
//                                 ElevatedButton(
//                                   onPressed: () => _updateOutpassStatus(doc.id, 'approved'),
//                                   style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
//                                   child: const Text('Approve'),
//                                 ),
//                                 const SizedBox(width: 10),
//                                 ElevatedButton(
//                                   onPressed: () => _updateOutpassStatus(doc.id, 'rejected'),
//                                   style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
//                                   child: const Text('Reject'),
//                                 ),
//                               ],
//                             ),
//                           ],
//                         ),
//                       ),
//                     );
//                   },
//                 );
//               },
//             );
//           },
//         );
//       },
//     );
//   }

//   // Helper function to filter outpasses by student's hostel
//   Future<List<DocumentSnapshot>> _filterOutpassesByHostel(List<DocumentSnapshot> outpassDocs) async {
//     final List<DocumentSnapshot> filteredList = [];
//     for (var doc in outpassDocs) {
//       final data = doc.data() as Map<String, dynamic>;
//       final studentDoc = await _firestore.collection('students').doc(data['userId']).get();
//       if (studentDoc.exists && studentDoc.data() != null) {
//         final studentHostel = studentDoc.data()!['hostel'];
//         if (studentHostel == _wardenHostelName) {
//           filteredList.add(doc);
//         }
//       }
//     }
//     return filteredList;
//   }

//   Future<void> _showEditStatusDialog(BuildContext context, String docId, String currentStatus) async {
//     String? selectedStatus = currentStatus;
//     await showDialog(
//       context: context,
//       builder: (BuildContext dialogContext) {
//         return AlertDialog(
//           title: const Text('Edit Warden Approval Status'),
//           content: DropdownButtonFormField<String>(
//             value: selectedStatus,
//             items: ['approved', 'rejected']
//                 .map((label) => DropdownMenuItem(
//                       value: label,
//                       child: Text(label.toUpperCase()),
//                     ))
//                 .toList(),
//             onChanged: (value) {
//               selectedStatus = value;
//             },
//             decoration: const InputDecoration(
//               border: OutlineInputBorder(),
//               labelText: 'Status',
//             ),
//           ),
//           actions: <Widget>[
//             TextButton(
//               child: const Text('Cancel'),
//               onPressed: () {
//                 Navigator.of(dialogContext).pop();
//               },
//             ),
//             ElevatedButton(
//               child: const Text('Save'),
//               onPressed: () {
//                 if (selectedStatus != null && selectedStatus != currentStatus) {
//                   _updateOutpassStatus(docId, selectedStatus!);
//                 }
//                 Navigator.of(dialogContext).pop();
//               },
//             ),
//           ],
//         );
//       },
//     );
//   }
// }
