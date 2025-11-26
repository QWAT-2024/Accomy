import 'package:flutter/material.dart';
import 'package:accomy/screens/security/base_outpass_list_page.dart';
import 'package:accomy/screens/security/gate_pass_list.dart';

class StudentOutListPage extends BaseOutpassListPage {
  const StudentOutListPage({super.key});
  @override
  StudentOutListPageState createState() => StudentOutListPageState();
}

class StudentOutListPageState extends BaseOutpassListPageState<StudentOutListPage> {
  // Define the custom blue color
  static const Color primaryBlue = Color(0xff3f51b5);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // A very light grey background to make the white cards pop
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Student Out',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: primaryBlue,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: GatePassList(
        statusFilter: 'approved',
        onActionButtonPressed: (docId, leaveType) => updatePassStatus(docId, 'student_out', leaveType: leaveType),
        actionButtonText: 'Mark Out',
        // No revert button is needed for this design
      ),
    );
  }
}