import 'package:flutter/material.dart';
import 'package:accomy/screens/security/base_outpass_list_page.dart';
import 'package:accomy/screens/security/gate_pass_list.dart';

class CompletedListPage extends BaseOutpassListPage {
  const CompletedListPage({super.key});
  @override
  CompletedListPageState createState() => CompletedListPageState();
}

class CompletedListPageState extends BaseOutpassListPageState<CompletedListPage> {
  static const Color primaryBlue = Color(0xff3f51b5);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Completed', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryBlue,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: GatePassList(
        statusFilter: 'completed',
        onActionButtonPressed: (docId, leaveType) {}, // No action
        actionButtonText: '', // No button text, so it won't be displayed
        onRevertButtonPressed: (docId, leaveType) => updatePassStatus(docId, 'completed_revert', leaveType: leaveType),
        revertButtonText: 'Revert Completed',
      ),
    );
  }
}