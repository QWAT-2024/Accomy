import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';

class StudentOutpassDetailsScreen extends StatelessWidget {
  final String outpassId;

  const StudentOutpassDetailsScreen({super.key, required this.outpassId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Outpass Details'),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('outpass_requests').doc(outpassId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Outpass not found.'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Leave Type: ${data['leaveType'] ?? 'N/A'}'),
                Text('From: ${data['from'] ?? 'N/A'}'),
                Text('To: ${data['to'] ?? 'N/A'}'),
                Text('Destination: ${data['destination'] ?? 'N/A'}'),
                Text('Reason: ${data['reason'] ?? 'N/A'}'),
                Text('Avail Bus: ${data['availBus'] ?? false ? 'Yes' : 'No'}'),
                Text('Status: ${data['status'] ?? 'N/A'}'),
                const SizedBox(height: 20),
                if (data['qr_data'] != null)
                  Center(
                    child: QrImageView(
                      data: data['qr_data'],
                      version: QrVersions.auto,
                      size: 200.0,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
