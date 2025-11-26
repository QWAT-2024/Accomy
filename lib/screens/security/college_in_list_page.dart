import 'package:flutter/material.dart';
import 'package:accomy/screens/security/base_outpass_list_page.dart';
import 'package:accomy/screens/security/gate_pass_list.dart';

class CollegeInListPage extends BaseOutpassListPage {
  const CollegeInListPage({super.key});
  @override
  CollegeInListPageState createState() => CollegeInListPageState();
}

class CollegeInListPageState extends BaseOutpassListPageState<CollegeInListPage> {
  static const Color primaryBlue = Color(0xff3f51b5);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('College In', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryBlue,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: GatePassList(
        statusFilter: 'student_out',
        leaveTypeFilter: ['Home Town (College)', 'Home Town (Leave)'],
        onActionButtonPressed: (docId, leaveType) => updatePassStatus(docId, 'college_in', leaveType: leaveType),
        actionButtonText: 'Mark College In',
        onRevertButtonPressed: (docId, leaveType) => updatePassStatus(docId, 'student_out_revert', leaveType: leaveType),
        revertButtonText: 'Revert Out',
      ),
    );
  }
}