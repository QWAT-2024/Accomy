import 'package:flutter/material.dart';
import 'package:accomy/screens/security/base_outpass_list_page.dart';
import 'package:accomy/screens/security/gate_pass_list.dart';

class HostelInListPage extends BaseOutpassListPage {
  const HostelInListPage({super.key});
  @override
  HostelInListPageState createState() => HostelInListPageState();
}

class HostelInListPageState extends BaseOutpassListPageState<HostelInListPage> {
  static const Color primaryBlue = Color(0xff3f51b5);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Hostel In', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryBlue,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: GatePassList(
        statusFilter: 'hostel_in_pending',
        onActionButtonPressed: (docId, leaveType) => updatePassStatus(docId, 'hostel_in', leaveType: leaveType),
        actionButtonText: 'Mark Hostel In',
        onRevertButtonPressed: (docId, leaveType) {
          if (leaveType == 'Local') {
            updatePassStatus(docId, 'student_out_revert', leaveType: leaveType);
          } else {
            updatePassStatus(docId, 'college_in_revert', leaveType: leaveType);
          }
        },
        revertButtonText: 'Revert In',
      ),
    );
  }
}