import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';


class WardenReportScreen extends StatefulWidget {
  final String wardenId;

  const WardenReportScreen({super.key, required this.wardenId});

  @override
  State<WardenReportScreen> createState() => _WardenReportScreenState();
}

class _WardenReportScreenState extends State<WardenReportScreen> with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  TabController? _tabController;
  final List<String> _statuses = ['All', 'Pending', 'Approved', 'Rejected'];

  // Date range state variables
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();

  List<Map<String, dynamic>> _outpassData = [];
  bool _isLoading = true;
  String? _wardenHostelName;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statuses.length, vsync: this);
    _tabController!.addListener(_handleTabSelection);
    _updateDateText();
    _fetchWardenHostelName().then((_) {
      _fetchOutpassReports();
    });
  }

  @override
  void dispose() {
    _tabController?.removeListener(_handleTabSelection);
    _tabController?.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  void _handleTabSelection() {
    // We only fetch when the tab controller's animation is done
    if (!_tabController!.indexIsChanging) {
      _fetchOutpassReports();
    }
  }
  
  void _updateDateText() {
    _startDateController.text = DateFormat('MMM dd, yyyy').format(_startDate);
    _endDateController.text = DateFormat('MMM dd, yyyy').format(_endDate);
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
       builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1A237E),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ), dialogTheme: DialogThemeData(backgroundColor: Colors.white),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
        _updateDateText();
      });
      // After picking a new date, fetch the reports
      _fetchOutpassReports();
    }
  }


  Future<void> _fetchWardenHostelName() async {
    try {
      final wardenDoc =
          await _firestore.collection('staff').doc(widget.wardenId).get();
      if (wardenDoc.exists && wardenDoc.data() != null) {
        if (mounted) {
          setState(() {
            _wardenHostelName = wardenDoc.data()!['hostelName'];
          });
        }
      }
    } catch (e) {
      print('Error fetching warden hostel name: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching warden data: $e')),
        );
      }
    }
  }

  Future<void> _fetchOutpassReports() async {
    if (_wardenHostelName == null) {
       if (mounted) setState(() => _isLoading = false);
      return;
    }

    setState(() {
      _isLoading = true;
      _outpassData = [];
    });
    
    final selectedStatus = _statuses[_tabController!.index];

    try {
      Query query = _firestore
          .collection('outpass_requests')
          .where('timestamp', isGreaterThanOrEqualTo: _startDate)
          .where('timestamp', isLessThanOrEqualTo: _endDate.add(const Duration(days: 1)))
          .orderBy('timestamp', descending: true);

      final querySnapshot = await query.get();

      List<Map<String, dynamic>> fetchedData = [];
      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        final studentDoc =
            await _firestore.collection('students').doc(data['userId']).get();
        if (!studentDoc.exists) continue;

        final studentData = studentDoc.data()!;
        final studentHostelName = studentData['hostel'];

        if (studentHostelName != _wardenHostelName) {
          continue;
        }

        String overallStatus = _getOverallStatus(data);
        
        if (selectedStatus != 'All' && overallStatus != selectedStatus) {
          continue;
        }

        fetchedData.add({
          'studentName': studentData['name'] ?? 'N/A',
          'rollNo': studentData['rollNumber'] ?? 'N/A',
          'leaveType': data['leaveType'] ?? 'N/A',
          'from': data['from'] ?? 'N/A',
          'to': data['to'] ?? 'N/A',
          'destination': data['destination'] ?? 'N/A',
          'reason': data['reason'] ?? 'N/A',
          'tutorApprovalStatus': data['tutorApprovalStatus'] ?? 'N/A',
          'wardenApprovalStatus': data['wardenApprovalStatus'] ?? 'N/A',
          'requestedDate': DateFormat('MMM dd, yyyy - hh:mm a')
              .format((data['timestamp'] as Timestamp).toDate()),
          'overallStatus': overallStatus,
        });
      }

      if (mounted) {
        setState(() {
          _outpassData = fetchedData;
        });
      }
    } catch (e) {
      print('Error fetching outpass reports: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching reports: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getOverallStatus(Map<String, dynamic> data) {
    final leaveType = data['leaveType'];
    final tutorStatus = data['tutorApprovalStatus'];
    final wardenStatus = data['wardenApprovalStatus'];

    if (leaveType == 'Home Town (College)') {
      if (tutorStatus == 'rejected' || wardenStatus == 'rejected') {
        return 'Rejected';
      } else if (tutorStatus == 'pending' || wardenStatus == 'pending') {
        return 'Pending';
      } else if (tutorStatus == 'approved' && wardenStatus == 'approved') {
        return 'Approved';
      }
    } else {
      if (wardenStatus == 'rejected') {
        return 'Rejected';
      } else if (wardenStatus == 'pending') {
        return 'Pending';
      } else if (wardenStatus == 'approved') {
        return 'Approved';
      }
    }
    return 'Unknown';
  }
  
  Future<void> _downloadExcelReport() async {
    if (_outpassData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No data to export.")));
      return;
    }
    
    // Check for storage permission
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      await Permission.storage.request();
    }
    
    if (await Permission.storage.isGranted) {
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Reports'];

      List<String> headers = [
        "Student Name", "Roll No", "Leave Type", "From", "To", "Destination",
        "Reason", "Tutor Status", "Warden Status", "Requested Date", "Overall Status"
      ];
      sheetObject.appendRow(headers.map((e) => TextCellValue(e)).toList());

      for (var data in _outpassData) {
        sheetObject.appendRow([
          TextCellValue(data['studentName']),
          TextCellValue(data['rollNo']),
          TextCellValue(data['leaveType']),
          TextCellValue(data['from']),
          TextCellValue(data['to']),
          TextCellValue(data['destination']),
          TextCellValue(data['reason']),
          TextCellValue(data['tutorApprovalStatus']),
          TextCellValue(data['wardenApprovalStatus']),
          TextCellValue(data['requestedDate']),
          TextCellValue(data['overallStatus']),
        ]);
      }
      
      try {
        final directory = await getExternalStorageDirectory(); // Use external storage
        final path = '${directory!.path}/Outpass_Reports_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';
        final file = File(path);
        await file.writeAsBytes(excel.encode()!);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Report saved to $path")));
      } catch (e) {
        print("Error saving excel file: $e");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error saving report: $e")));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Storage permission is required to save the report.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20.0), // Added SizedBox for extra top spacing
             Container(
              padding: const EdgeInsets.all(16.0),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: _buildDateTextField(context, 'From', _startDateController, true),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDateTextField(context, 'To', _endDateController, false),
                  ),
                ],
              ),
            ),
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                tabs: _statuses.map((status) => Tab(text: status)).toList(),
                labelColor: const Color(0xFF1A237E),
                unselectedLabelColor: Colors.grey[600],
                indicatorColor: const Color(0xFF1A237E),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _outpassData.isEmpty
                      ? Center(
                          child: Text(
                            'No outpass data found for the selected criteria.',
                            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 80.0),
                          itemCount: _outpassData.length,
                          itemBuilder: (context, index) {
                            final data = _outpassData[index];
                            return _buildReportCard(data);
                          },
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _downloadExcelReport,
        backgroundColor: const Color(0xFF1A237E),
        icon: const Icon(Icons.download, color: Colors.white),
        label: const Text("Download as Excel", style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildDateTextField(BuildContext context, String label,
      TextEditingController controller, bool isStartDate) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: const Icon(Icons.calendar_today),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0), borderSide: BorderSide.none),
      ),
      onTap: () => _selectDate(context, isStartDate),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'Approved':
        color = Colors.green;
        break;
      case 'Rejected':
        color = Colors.red;
        break;
      case 'Pending':
        color = Colors.orange;
        break;
      default:
        color = Colors.grey;
    }
    return Chip(
      label: Text(status, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
      backgroundColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildReportCard(Map<String, dynamic> data) {
    bool requiresTutor = data['leaveType'] == 'Home Town (College)';
    String fromToDate = 'From: ${data['from']} To: ${data['to']}';
    String leaveType = data['leaveType'].replaceAll(' (College)', '').replaceAll(' (Hostel)', '');

    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16.0),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['studentName'],
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Roll: ${data['rollNo']}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _buildStatusChip(data['overallStatus']),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(
            '$leaveType | $fromToDate',
            style: const TextStyle(fontSize: 13),
          ),
        ),
        children: [
          const Divider(height: 1, indent: 16, endIndent: 16),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 _buildDetailRow('Destination:', data['destination']),
                 _buildDetailRow('Reason:', data['reason']),
                 _buildDetailRow('Requested On:', data['requestedDate']),
                const Divider(height: 24),
                 _buildDetailRow('Warden Status:', data['wardenApprovalStatus']),
                 if (requiresTutor)
                   _buildDetailRow('Tutor Status:', data['tutorApprovalStatus']),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}