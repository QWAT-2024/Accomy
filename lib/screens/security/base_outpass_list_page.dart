import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

abstract class BaseOutpassListPage extends StatefulWidget {
  const BaseOutpassListPage({super.key});
}

abstract class BaseOutpassListPageState<T extends BaseOutpassListPage> extends State<T> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Future<void> updatePassStatus(String docId, String action, {String? leaveType}) async {
    try {
      Map<String, dynamic> updateData = {};
      String toastMessage = '';

      if (action == 'student_out') {
        updateData = {'currentStage': 'student_out', 'gateOutTimestamp': FieldValue.serverTimestamp()};
        toastMessage = 'Student marked out.';
      } else if (action == 'college_in') {
        updateData = {'currentStage': 'college_in', 'collegeInTimestamp': FieldValue.serverTimestamp()};
        toastMessage = 'Student marked college in.';
      } else if (action == 'hostel_in') {
        updateData = {'currentStage': 'hostel_in', 'hostelInTimestamp': FieldValue.serverTimestamp()};
        toastMessage = 'Student marked hostel in.';
      } else if (action == 'student_out_revert') {
        updateData = {'currentStage': 'approved', 'gateOutTimestamp': null};
        toastMessage = 'Pass reverted to approved.';
      } else if (action == 'college_in_revert') {
        updateData = {'currentStage': 'student_out', 'collegeInTimestamp': null};
        toastMessage = 'Pass reverted to student out.';
      } else if (action == 'hostel_in_revert') {
        if (leaveType == 'Local') {
          updateData = {'currentStage': 'student_out', 'hostelInTimestamp': null};
        } else {
          updateData = {'currentStage': 'college_in', 'hostelInTimestamp': null};
        }
        toastMessage = 'Pass reverted.';
      } else if (action == 'completed_revert') {
        if (leaveType == 'Local') {
          updateData = {'currentStage': 'student_out', 'hostelInTimestamp': null};
        } else {
          updateData = {'currentStage': 'college_in', 'hostelInTimestamp': null};
        }
        toastMessage = 'Completed pass reverted.';
      } else {
        return;
      }

      await _firestore.collection('outpass_requests').doc(docId).update(updateData);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(toastMessage)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update pass status: $e')));
      }
    }
  }
}