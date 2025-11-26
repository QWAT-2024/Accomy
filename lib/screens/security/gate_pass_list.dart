// lib/screens/security/gate_pass_list.dart

import 'package:accomy/screens/home/outpass_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class GatePassList extends StatelessWidget {
  final String statusFilter;
  final List<String>? leaveTypeFilter;
  final Function(String docId, String? leaveType) onActionButtonPressed;
  final String actionButtonText;
  final Function(String docId, String? leaveType)? onRevertButtonPressed;
  final String? revertButtonText;

  const GatePassList({
    super.key,
    required this.statusFilter,
    this.leaveTypeFilter,
    required this.onActionButtonPressed,
    required this.actionButtonText,
    this.onRevertButtonPressed,
    this.revertButtonText,
  });

  // ... (build, _buildOutpassCard, _buildCardHeader, _buildDetailRow methods remain unchanged) ...

  @override
  Widget build(BuildContext context) {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    Query query = firestore.collection('outpass_requests').orderBy('timestamp', descending: true);
    query = query.where('wardenApprovalStatus', isEqualTo: 'approved');

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xff3f51b5)));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text('No requests found.', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
          );
        }

        final filteredOutpasses = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final leaveType = data['leaveType'];
          final tutorApprovalStatus = data['tutorApprovalStatus'];
          final currentStage = data['currentStage'] ?? 'approved';

          if (leaveType == 'Home Town (College)' && tutorApprovalStatus != 'approved') return false;

          switch (statusFilter) {
            case 'approved': return currentStage == 'approved';
            case 'student_out': return currentStage == 'student_out' && (leaveTypeFilter == null || leaveTypeFilter!.contains(leaveType));
            case 'hostel_in_pending':
              if (leaveType == 'Local') return currentStage == 'student_out';
              return currentStage == 'college_in';
            case 'completed': return currentStage == 'hostel_in';
            default: return false;
          }
        }).toList();

        if (filteredOutpasses.isEmpty) {
          return Center(
            child: Text('No ${statusFilter.replaceAll('_', ' ')} requests found.', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          itemCount: filteredOutpasses.length,
          itemBuilder: (context, index) {
            final doc = filteredOutpasses[index];
            final data = doc.data() as Map<String, dynamic>;
            
            return FutureBuilder<DocumentSnapshot>(
              future: firestore.collection('students').doc(data['userId']).get(),
              builder: (context, studentSnapshot) {
                if (!studentSnapshot.hasData) {
                  return const Card(child: SizedBox(height: 200, child: Center(child: CircularProgressIndicator())));
                }
                
                final studentData = studentSnapshot.data!.data() as Map<String, dynamic>;
                final studentName = studentData['name'] ?? 'Unknown Student';
                final studentRegNo = studentData['regNo'] ?? 'N/A';
                final studentImageUrl = studentData['imageUrl'];

                return _buildOutpassCard(context, doc, data, studentName, studentRegNo, studentImageUrl);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildOutpassCard(BuildContext context, DocumentSnapshot doc, Map<String, dynamic> data, String studentName, String studentRegNo, String? studentImageUrl) {
    final timestamp = data['timestamp'] as Timestamp?;
    final formattedDate = timestamp != null
        ? DateFormat('MMM dd, hh:mm a').format(timestamp.toDate())
        : 'N/A';

    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => OutpassDetailsScreen(outpassId: doc.id))),
      child: Card(
        color: Colors.white,
        elevation: 2,
        shadowColor: Colors.grey.withOpacity(0.1),
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCardHeader(studentName, studentRegNo, data['leaveType'], studentImageUrl),
              const SizedBox(height: 12),
              Divider(color: Colors.grey.shade200, thickness: 1),
              const SizedBox(height: 12),
              _buildDetailRow('From:', data['from'] ?? 'N/A'),
              _buildDetailRow('To:', data['to'] ?? 'N/A'),
              _buildDetailRow('Destination:', data['destination'] ?? 'N/A'),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Reason:', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(data['reason'] ?? 'N/A', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              _buildDetailRow('Requested:', formattedDate),
              const SizedBox(height: 20),
              _buildActionButtons(doc.id, data['leaveType']),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardHeader(String name, String regNo, String leaveType, String? imageUrl) {
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: Colors.grey.shade200,
          backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
          child: imageUrl == null ? Icon(Icons.person, color: Colors.grey.shade500, size: 28) : null,
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
            Text(regNo, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
          ],
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.orange.shade200, width: 1),
          ),
          child: Text(
            leaveType,
            style: TextStyle(color: Colors.orange.shade800, fontWeight: FontWeight.w500, fontSize: 12),
          ),
        ),
      ],
    );
  }
  
  Widget _buildDetailRow(String label, String value) {
     return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
          Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black87)),
        ],
      ),
    );
  }

  // --- IMPROVED BUTTON LOGIC ---
  Widget _buildActionButtons(String docId, String? leaveType) {
    final List<Widget> buttons = [];

    // Add the primary action button if its text is not empty
    if (actionButtonText.isNotEmpty) {
      buttons.add(
        Expanded(
          child: ElevatedButton(
            onPressed: () => onActionButtonPressed(docId, leaveType),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            child: Text(actionButtonText),
          ),
        ),
      );
    }

    // Add the revert button if it exists
    if (revertButtonText != null && onRevertButtonPressed != null) {
      // Add spacing if a primary button is already present
      if (buttons.isNotEmpty) {
        buttons.add(const SizedBox(width: 10));
      }
      buttons.add(
        Expanded(
          child: ElevatedButton(
            onPressed: () => onRevertButtonPressed!(docId, leaveType),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange, // A consistent color for revert actions
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            child: Text(revertButtonText!),
          ),
        ),
      );
    }

    if (buttons.isEmpty) {
      return const SizedBox.shrink(); // Return an empty widget if no buttons are needed
    }

    return Row(children: buttons);
  }
}