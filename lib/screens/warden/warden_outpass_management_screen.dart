import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

/// Screen to actively manage pending outpasses and view history.
class WardenPendingOutpassesListScreen extends StatefulWidget {
  const WardenPendingOutpassesListScreen({super.key});

  @override
  State<WardenPendingOutpassesListScreen> createState() =>
      _WardenPendingOutpassesListScreenState();
}

class _WardenPendingOutpassesListScreenState
    extends State<WardenPendingOutpassesListScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _currentUser;
  String? _wardenHostelName;
  int _selectedIndex = 0;

  // State for filters
  DateTimeRange? _selectedDateRange;
  String _selectedSubStatus = 'All'; // 'All', 'approved', 'rejected'

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser;
    _fetchWardenHostelName();
  }

  Future<void> _fetchWardenHostelName() async {
    if (_currentUser == null) return;
    try {
      final doc =
          await _firestore.collection('staff').doc(_currentUser!.uid).get();
      if (doc.exists && doc.data() != null) {
        if (mounted) {
          setState(() {
            _wardenHostelName = doc.data()!['hostelName'];
          });
        }
      }
    } catch (e) {
      print('Error fetching warden hostel name: $e');
    }
  }

  Future<int> _getOutpassCountByHostel(List<String> statuses) async {
    if (_currentUser == null || _wardenHostelName == null) return 0;

    final querySnapshot = await _firestore
        .collection('outpass_requests')
        .where('wardenApprovalStatus', whereIn: statuses)
        .get();

    int count = 0;
    for (var doc in querySnapshot.docs) {
      final data = doc.data();
      final studentDoc =
          await _firestore.collection('students').doc(data['userId']).get();
      if (studentDoc.exists &&
          studentDoc.data()?['hostel'] == _wardenHostelName) {
        count++;
      }
    }
    return count;
  }

  Future<void> _updateOutpassStatus(String docId, String status) async {
    try {
      await _firestore
          .collection('outpass_requests')
          .doc(docId)
          .update({'wardenApprovalStatus': status});
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

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            bool isProcessedTab = _selectedIndex == 1;

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

                  // Status Filter (only for Processed tab)
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

                  // Date Filter
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
                        border: Border.all(color: Colors.grey.shade300),
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

                  // Action Buttons
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
                            setState(
                                () {}); // Trigger a rebuild of the main screen with the selected filters
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
    if (_wardenHostelName == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(color: Colors.white),
        title: const Text('Outpass Requests',
            style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
              onPressed: _showFilterModal,
              icon: const Icon(Icons.filter_list, color: Colors.white)),
        ],
        elevation: 1,
        backgroundColor:
            const Color(0xFF2A3A6A), // Set AppBar background color
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: _buildTabBar(),
        ),
      ),
      body: Container(
        color: Colors.grey.shade100,
        padding:
            const EdgeInsets.only(top: 12.0), // Space between tabs and cards
        child: _buildOutpassList(),
      ),
    );
  }

  Widget _buildTabBar() {
    return FutureBuilder<List<int>>(
      future: Future.wait([
        _getOutpassCountByHostel(['pending']),
        _getOutpassCountByHostel(['approved', 'rejected']),
      ]),
      builder: (context, snapshot) {
        final pendingCount = snapshot.data?[0] ?? 0;
        final processedCount = snapshot.data?[1] ?? 0;

        return Container(
          color: const Color(0xFF2A3A6A), // Match AppBar background
          child: Row(
            children: [
              // Use Expanded to make each tab take up half the screen width
              Expanded(child: _buildTabItem("Pending", pendingCount, 0)),
              Expanded(child: _buildTabItem("Processed", processedCount, 1)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabItem(String title, int count, int index) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
          _selectedDateRange = null;
          _selectedSubStatus = 'All';
        });
      },
      // Use a transparent color to make the whole area clickable
      child: Container(
        color: Colors.transparent,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.center, // Center the text and badge
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : Colors.white.withOpacity(0.7),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white
                        : Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    count.toString(),
                    style: TextStyle(
                      color:
                          isSelected ? const Color(0xFF2A3A6A) : Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // The underline indicator
            Container(
              height: 3,
              color: isSelected ? Colors.white : Colors.transparent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutpassList() {
    List<String> statuses;

    if (_selectedIndex == 0) {
      // Pending Tab
      statuses = ['pending'];
    } else {
      // Processed Tab
      if (_selectedSubStatus == 'All') {
        statuses = ['approved', 'rejected'];
      } else {
        statuses = [_selectedSubStatus];
      }
    }

    return WardenOutpassHistoryScreen(
      statuses: statuses,
      dateRange: _selectedDateRange,
      showActions: _selectedIndex == 0, // Show actions only on Pending tab
      onUpdate: _updateOutpassStatus,
    );
  }
}

/// Screen to display a list of outpasses based on status.
class WardenOutpassHistoryScreen extends StatefulWidget {
  final String? title;
  final List<String> statuses;
  final DateTimeRange? dateRange;
  final bool showActions;
  final Function(String, String)? onUpdate;

  const WardenOutpassHistoryScreen({
    super.key,
    this.title,
    required this.statuses,
    this.dateRange,
    this.showActions = false,
    this.onUpdate,
  });

  @override
  State<WardenOutpassHistoryScreen> createState() =>
      _WardenOutpassHistoryScreenState();
}

class _WardenOutpassHistoryScreenState
    extends State<WardenOutpassHistoryScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _wardenHostelName;

  @override
  void initState() {
    super.initState();
    _fetchWardenHostelName();
  }

  Future<void> _fetchWardenHostelName() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      final doc = await _firestore.collection('staff').doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        if (mounted) {
          setState(() {
            _wardenHostelName = doc.data()!['hostelName'];
          });
        }
      }
    } catch (e) {
      print('Error fetching warden hostel name: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.title != null) {
      return Scaffold(
        body: _buildList(),
      );
    }
    return _buildList();
  }

  Widget _buildList() {
    if (_wardenHostelName == null) {
      return const Center(child: CircularProgressIndicator());
    }

    Query query = _firestore
        .collection('outpass_requests')
        .where('wardenApprovalStatus', whereIn: widget.statuses);

    // Apply date filter if it exists
    if (widget.dateRange != null) {
      query = query.where('timestamp',
          isGreaterThanOrEqualTo: widget.dateRange!.start);
      // Add 1 day to the end date to make it inclusive
      query = query.where('timestamp',
          isLessThanOrEqualTo:
              widget.dateRange!.end.add(const Duration(days: 1)));
    }

    // Always sort by timestamp
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
              child: Text(
                  'No outpass requests found for the selected filters.'));
        }

        return FutureBuilder<List<DocumentSnapshot>>(
          future: _filterOutpassesByHostel(snapshot.data!.docs),
          builder: (context, filteredSnapshot) {
            if (filteredSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final docs = filteredSnapshot.data ?? [];
            if (docs.isEmpty) {
              return const Center(
                  child: Text('No outpass requests found for your hostel.'));
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final doc = docs[index];
                return OutpassCard(
                  doc: doc,
                  showActions: widget.showActions,
                  onUpdate: widget.onUpdate,
                );
              },
            );
          },
        );
      },
    );
  }

  Future<List<DocumentSnapshot>> _filterOutpassesByHostel(
      List<DocumentSnapshot> outpassDocs) async {
    final List<DocumentSnapshot> filteredList = [];
    for (var doc in outpassDocs) {
      final data = doc.data() as Map<String, dynamic>;
      final studentDoc =
          await _firestore.collection('students').doc(data['userId']).get();
      if (studentDoc.exists &&
          studentDoc.data()?['hostel'] == _wardenHostelName) {
        filteredList.add(doc);
      }
    }
    return filteredList;
  }
}

/// Screen to show the full details of a single outpass request.
class OutpassDetailScreen extends StatelessWidget {
  final String outpassId;

  const OutpassDetailScreen({super.key, required this.outpassId});

  @override
  Widget build(BuildContext context) {
    final docRef =
        FirebaseFirestore.instance.collection('outpass_requests').doc(outpassId);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: const BackButton(color: Colors.black),
        title: const Text('Outpass Details',
            style: TextStyle(color: Colors.black)),
        elevation: 1,
        shadowColor: Colors.grey.shade200,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: docRef.get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: OutpassCard(doc: snapshot.data!, showFullDetails: true),
          );
        },
      ),
    );
  }
}

/// A generic, reusable card widget to display outpass information.
class OutpassCard extends StatelessWidget {
  final DocumentSnapshot doc;
  final bool showActions;
  final bool showFullDetails;
  final Function(String, String)? onUpdate;

  const OutpassCard({
    super.key,
    required this.doc,
    this.showActions = false,
    this.showFullDetails = false,
    this.onUpdate,
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
      color: Colors.white, // Explicitly set card color to white
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 2,
      shadowColor: Colors.grey.shade200,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('students')
              .doc(data['userId'])
              .get(),
          builder: (context, studentSnapshot) {
            if (!studentSnapshot.hasData) {
              return const Center(
                  child: SizedBox(
                      height: 50, child: LinearProgressIndicator()));
            }
            final studentData =
                studentSnapshot.data!.data() as Map<String, dynamic>;
            final studentName = studentData['name'] ?? 'Unknown Student';
            final studentRegNo =
                studentData['registerNumber'] ?? 'Reg-No: N/A';
            final studentImageUrl = studentData['imageUrl'];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: studentImageUrl != null
                          ? NetworkImage(studentImageUrl)
                          : null,
                      child: studentImageUrl == null
                          ? const Icon(Icons.person, color: Colors.grey)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(studentName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 2),
                          Text(studentRegNo,
                              style: TextStyle(
                                  color: Colors.grey.shade600, fontSize: 14)),
                        ],
                      ),
                    ),
                    Chip(
                      label: Text(leaveType,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12)),
                      backgroundColor: chipColor.withOpacity(0.8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      side: BorderSide.none,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Details
                _buildDetailItem("From:", data['from'] ?? 'N/A'),
                _buildDetailItem("To:", data['to'] ?? 'N/A'),
                _buildDetailItem("Destination:", data['destination'] ?? 'N/A'),
                _buildDetailItem("Reason:", data['reason'] ?? 'N/A'),
                _buildDetailItem("Requested:", formattedDate),

                if (showFullDetails) ...[
                  if (data['leaveType'] == 'Home Town (College)')
                    _buildDetailItem('Tutor Status:',
                        data['tutorApprovalStatus']?.toUpperCase() ?? 'N/A'),
                ],

                const SizedBox(height: 16),
                // Approval Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    _buildStatusIndicator(
                        'Tutor', data['tutorApprovalStatus']),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Text("—" * 3,
                          style: TextStyle(color: Colors.grey.shade300)),
                    ),
                    _buildStatusIndicator(
                        'Warden', data['wardenApprovalStatus']),
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
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
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
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
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
            child: Text(value,
                textAlign: TextAlign.end,
                style: const TextStyle(fontWeight: FontWeight.w500)),
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
        Text(role,
            style: TextStyle(
                fontSize: 12,
                color: isPending ? Colors.black : Colors.grey.shade600)),
      ],
    );
  }
}