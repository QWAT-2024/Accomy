import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

/// Screen for tutors to manage pending outpasses and view history.
class TutorPendingOutpassScreen extends StatefulWidget {
  final String tutorId;

  const TutorPendingOutpassScreen({super.key, required this.tutorId});

  @override
  State<TutorPendingOutpassScreen> createState() =>
      _TutorPendingOutpassScreenState();
}

// 1. Added SingleTickerProviderStateMixin for the TabController
class _TutorPendingOutpassScreenState extends State<TutorPendingOutpassScreen> with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // Use a TabController to sync the AppBar tabs and the TabBarView
  late TabController _tabController;

  // State for filters
  DateTimeRange? _selectedDateRange;
  String _selectedSubStatus = 'All'; // 'All', 'approved', 'rejected'

  @override
  void initState() {
    super.initState();
    // Initialize the TabController with 2 tabs
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Fetches the count of outpasses for the current tutor based on status.
  Future<int> _getOutpassCountByTutor(List<String> statuses) async {
    final querySnapshot = await _firestore
        .collection('outpass_requests')
        .where('tutorId', isEqualTo: widget.tutorId)
        .where('tutorApprovalStatus', whereIn: statuses)
        .get();
    return querySnapshot.docs.length;
  }

  /// Updates the status of a specific outpass document in Firestore.
  Future<void> _updateOutpassStatus(String docId, String status) async {
    try {
      await _firestore
          .collection('outpass_requests')
          .doc(docId)
          .update({'tutorApprovalStatus': status});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Outpass status updated to $status.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update outpass status: $e')),
      );
    }
  }

  /// Shows a dialog to edit the status of an already processed outpass.
  Future<void> _showEditStatusDialog(String docId, String currentStatus) async {
    String? selectedStatus = currentStatus;

    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0),
              ),
              title: const Text(
                'Edit Approval Status',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              content: DropdownButtonFormField<String>(
                initialValue: selectedStatus,
                items: ['approved', 'rejected']
                    .map((label) => DropdownMenuItem(
                          value: label,
                          child: Text(label.toUpperCase()),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() {
                      selectedStatus = value;
                    });
                  }
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: const BorderSide(color: Color(0xFF1A237E)),
                  ),
                  labelText: 'Status',
                ),
              ),
              actionsAlignment: MainAxisAlignment.end,
              actions: <Widget>[
                TextButton(
                  child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A237E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: const Text('SAVE'),
                  onPressed: () {
                    if (selectedStatus != null && selectedStatus != currentStatus) {
                      _updateOutpassStatus(docId, selectedStatus!);
                    }
                    Navigator.of(dialogContext).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Shows a modal bottom sheet for filtering outpass requests.
  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            bool isProcessedTab = _tabController.index == 1;

            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Filter Options',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  if (isProcessedTab) ...[
                    const Text('Status',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        ChoiceChip(
                          label: const Text('All'),
                          selected: _selectedSubStatus == 'All',
                          onSelected: (selected) {
                            if (selected) {
                              setModalState(() => _selectedSubStatus = 'All');
                            }
                          },
                        ),
                        const SizedBox(width: 10),
                        ChoiceChip(
                          label: const Text('Approved'),
                          selected: _selectedSubStatus == 'approved',
                          onSelected: (selected) {
                            if (selected) {
                              setModalState(
                                  () => _selectedSubStatus = 'approved');
                            }
                          },
                        ),
                        const SizedBox(width: 10),
                        ChoiceChip(
                          label: const Text('Rejected'),
                          selected: _selectedSubStatus == 'rejected',
                          onSelected: (selected) {
                            if (selected) {
                              setModalState(
                                  () => _selectedSubStatus = 'rejected');
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                  const Text('Date Range',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: () async {
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        initialDateRange: _selectedDateRange,
                      );
                      if (picked != null) {
                        setModalState(() {
                          _selectedDateRange = picked;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedDateRange == null
                                ? 'Select a date range'
                                : '${DateFormat.yMd().format(_selectedDateRange!.start)} - ${DateFormat.yMd().format(_selectedDateRange!.end)}',
                          ),
                          const Icon(Icons.calendar_today_outlined),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _selectedDateRange = null;
                              _selectedSubStatus = 'All';
                            });
                            Navigator.pop(context);
                          },
                          child: const Text('Clear Filters'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {}); // Rebuild the main screen
                            Navigator.pop(context);
                          },
                          child: const Text('Apply'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      // 2. New unified AppBar with integrated tabs
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A237E), // Dark blue theme
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: const Text('Outpass Requests',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            onPressed: _showFilterModal,
            icon: const Icon(Icons.filter_list, color: Colors.white),
          ),
        ],
        // The TabBar is now part of the AppBar
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3.0,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            _buildTabWithBadge("Pending", ['pending']),
            _buildTabWithBadge("Processed", ['approved', 'rejected']),
          ],
        ),
      ),
      // 3. Simplified body using TabBarView
      body: TabBarView(
        controller: _tabController,
        children: [
          // Content for Pending Tab
          _buildOutpassList(
            statuses: ['pending'],
            showActions: true,
            showEditAction: false,
          ),
          // Content for Processed Tab
          _buildOutpassList(
            statuses: _selectedSubStatus == 'All'
                ? ['approved', 'rejected']
                : [_selectedSubStatus],
            showActions: false,
            showEditAction: true,
          ),
        ],
      ),
    );
  }

  /// Helper widget to build a tab with a notification badge
  Widget _buildTabWithBadge(String title, List<String> statuses) {
    return FutureBuilder<int>(
      future: _getOutpassCountByTutor(statuses),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        return Tab(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(title),
              if (count > 0) ...[
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 10,
                  backgroundColor: Colors.white,
                  child: Text(
                    count.toString(),
                    style: const TextStyle(
                      color: Color(0xFF1A237E),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  /// Builds the list of outpasses based on the provided configuration.
  Widget _buildOutpassList({
    required List<String> statuses,
    required bool showActions,
    required bool showEditAction,
  }) {
    return TutorOutpassHistoryList(
      tutorId: widget.tutorId,
      statuses: statuses,
      dateRange: _selectedDateRange,
      showActions: showActions,
      showEditAction: showEditAction,
      onUpdate: _updateOutpassStatus,
      onEdit: _showEditStatusDialog,
    );
  }
}

// (The TutorOutpassHistoryList and OutpassCard widgets remain unchanged below)


/// A widget to display a list of outpasses for a tutor based on status.
class TutorOutpassHistoryList extends StatelessWidget {
  final String tutorId;
  final List<String> statuses;
  final DateTimeRange? dateRange;
  final bool showActions;
  final bool showEditAction;
  final Function(String, String)? onUpdate;
  final Function(String, String)? onEdit;

  const TutorOutpassHistoryList({
    super.key,
    required this.tutorId,
    required this.statuses,
    this.dateRange,
    this.showActions = false,
    this.showEditAction = false,
    this.onUpdate,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    Query query = FirebaseFirestore.instance
        .collection('outpass_requests')
        .where('tutorId', isEqualTo: tutorId)
        .where('tutorApprovalStatus', whereIn: statuses);

    if (dateRange != null) {
      query = query.where('timestamp', isGreaterThanOrEqualTo: dateRange!.start);
      query = query.where('timestamp',
          isLessThanOrEqualTo: dateRange!.end.add(const Duration(days: 1)));
    }

    query = query.orderBy('timestamp', descending: true);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
              child:
                  Text('No outpass requests found for the selected filters.'));
        }

        final docs = snapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            return OutpassCard(
              doc: doc,
              showActions: showActions,
              showEditAction: showEditAction,
              onUpdate: onUpdate,
              onEdit: onEdit,
            );
          },
        );
      },
    );
  }
}

/// A generic, reusable card widget to display outpass information.
class OutpassCard extends StatelessWidget {
  final DocumentSnapshot doc;
  final bool showActions;
  final bool showFullDetails;
  final bool showEditAction;
  final Function(String, String)? onUpdate;
  final Function(String, String)? onEdit;

  const OutpassCard({
    super.key,
    required this.doc,
    this.showActions = false,
    this.showFullDetails = false,
    this.showEditAction = false,
    this.onUpdate,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
    final formattedDate = timestamp != null
        ? DateFormat('MMM dd, hh:mm a').format(timestamp)
        : 'N/A';
    
    final leaveType = data['leaveType'] ?? 'Leave';
    final Map<String, Color> leaveTypeColors = {
      'Medical': Colors.orange,
      'Personal': Colors.blue,
      'Home Town (College)': Colors.purple,
    };
    final chipColor = leaveTypeColors[leaveType] ?? Colors.grey;

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 2,
      shadowColor: Colors.grey.shade200,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('students').doc(data['userId']).get(),
          builder: (context, studentSnapshot) {
            if (!studentSnapshot.hasData) {
              return const Center(child: SizedBox(height: 50, child: LinearProgressIndicator()));
            }
            final studentData = studentSnapshot.data!.data() as Map<String, dynamic>;
            final studentName = studentData['name'] ?? 'Unknown Student';
            final studentRegNo = studentData['registerNumber'] ?? 'Reg-No: N/A';
            final studentImageUrl = studentData['imageUrl'];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: studentImageUrl != null ? NetworkImage(studentImageUrl) : null,
                      child: studentImageUrl == null ? const Icon(Icons.person, color: Colors.grey) : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(studentName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 2),
                          Text(studentRegNo, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                        ],
                      ),
                    ),
                    Chip(
                      label: Text(leaveType, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      backgroundColor: chipColor.withOpacity(0.8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      side: BorderSide.none,
                    ),
                    if (showEditAction && onEdit != null)
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: IconButton(
                          splashRadius: 20,
                          icon: Icon(Icons.edit_outlined, color: Colors.grey.shade700, size: 20),
                          onPressed: () => onEdit!(doc.id, data['tutorApprovalStatus']),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildDetailItem("From:", data['from'] ?? 'N/A'),
                _buildDetailItem("To:", data['to'] ?? 'N/A'),
                _buildDetailItem("Destination:", data['destination'] ?? 'N/A'),
                _buildDetailItem("Reason:", data['reason'] ?? 'N/A'),
                _buildDetailItem("Requested:", formattedDate),
                
                if (showFullDetails) ...[
                  if (data['leaveType'] == 'Home Town (College)')
                    _buildDetailItem('Tutor Status:', data['tutorApprovalStatus']?.toUpperCase() ?? 'N/A'),
                ],

                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    _buildStatusIndicator('Tutor', data['tutorApprovalStatus']),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Text("—" * 3, style: TextStyle(color: Colors.grey.shade300)),
                    ),
                    _buildStatusIndicator('Warden', data['wardenApprovalStatus']),
                  ],
                ),
                
                if (showActions && onUpdate != null) ...[
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.check, size: 18),
                          label: const Text('Approve'),
                          onPressed: () => onUpdate!(doc.id, 'approved'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.close, size: 18),
                          label: const Text('Reject'),
                          onPressed: () => onUpdate!(doc.id, 'rejected'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  )
                ]
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w500)
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(String role, String? status) {
    IconData iconData;
    Color iconColor;
    Color backgroundColor;
    bool isPending = false;

    switch (status) {
      case 'approved':
        iconData = Icons.check;
        iconColor = Colors.white;
        backgroundColor = Colors.green;
        break;
      case 'rejected':
        iconData = Icons.close;
        iconColor = Colors.white;
        backgroundColor = Colors.red;
        break;
      default: // pending
        iconData = Icons.access_time;
        iconColor = Colors.grey.shade700;
        backgroundColor = Colors.grey.shade300;
        isPending = true;
    }

    return Column(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: backgroundColor,
          child: Icon(iconData, color: iconColor, size: 20),
        ),
        const SizedBox(height: 6),
        Text(role, style: TextStyle(fontSize: 12, color: isPending ? Colors.black : Colors.grey.shade600)),
      ],
    );
  }
}
