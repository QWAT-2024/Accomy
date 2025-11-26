import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Import the OutpassCard from the screen you provided.
import 'package:accomy/screens/tutor/tutor_pending_outpass_screen.dart' show OutpassCard;

/// A screen to display the full details of a single outpass request.
class TutorOutpassDetailScreen extends StatelessWidget {
  final String outpassId;

  const TutorOutpassDetailScreen({super.key, required this.outpassId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Outpass Details'),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('outpass_requests')
            .doc(outpassId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Outpass not found.'));
          }

          final doc = snapshot.data!;

          // Reuse the detailed OutpassCard to show all information.
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: OutpassCard(
              doc: doc,
              showFullDetails: true, // A flag to show even more details if needed
            ),
          );
        },
      ),
    );
  }
}