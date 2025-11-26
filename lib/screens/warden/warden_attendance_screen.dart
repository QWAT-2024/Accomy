import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class WardenAttendanceScreen extends StatefulWidget {
  const WardenAttendanceScreen({super.key});

  @override
  State<WardenAttendanceScreen> createState() => _WardenAttendanceScreenState();
}

class _WardenAttendanceScreenState extends State<WardenAttendanceScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _currentUser;
  String? _wardenHostelName;
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _dateController = TextEditingController();
  String _searchQuery = '';
  String _searchType = 'roomNumber'; // 'roomNumber' or 'rollNumber'
  Map<String, String> _attendanceStatus = {}; // studentId -> 'P' or 'A'
  Map<String, String> _initialAttendanceStatus = {}; // To track changes

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser;
    _updateDateText();
    _fetchWardenHostelNameAndInitialData();
  }

  Future<void> _fetchWardenHostelNameAndInitialData() async {
    await _fetchWardenHostelName();
    if (_wardenHostelName != null) {
      _fetchAttendanceForSelectedDate();
    }
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

  void _updateDateText() {
    _dateController.text = DateFormat('MM/dd/yyyy').format(_selectedDate);
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2025).add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1A237E), // Accent color for selection
              onPrimary: Colors.white, // Text on accent color
              surface: Colors.white, // Background of the calendar
              onSurface: Colors.black87, // Text color on the calendar
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF1A237E), // OK/Cancel button text color
              ),
            ), dialogTheme: DialogThemeData(backgroundColor: Colors.white),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _updateDateText();
      });
      _fetchAttendanceForSelectedDate();
    }
  }

  Future<void> _fetchAttendanceForSelectedDate() async {
    if (_wardenHostelName == null) return;
    final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
    try {
      final snapshot = await _firestore
          .collection('attendance')
          .where('date', isEqualTo: formattedDate)
          .get();

      final fetchedAttendance = <String, String>{};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final studentId = data['studentId'] as String;
        final status = data['status'] as String;

        final studentDoc =
            await _firestore.collection('students').doc(studentId).get();
        if (studentDoc.exists &&
            studentDoc.data() != null &&
            studentDoc.data()!['hostel'] == _wardenHostelName) {
          fetchedAttendance[studentId] = status;
        }
      }
      if (mounted) {
        setState(() {
          _attendanceStatus = {...fetchedAttendance};
          _initialAttendanceStatus = {...fetchedAttendance};
        });
      }
    } catch (e) {
      print('Error fetching attendance: $e');
    }
  }

  void _stageAttendance(String studentId, String status) {
    setState(() {
      _attendanceStatus[studentId] = status;
    });
  }

  Future<void> _saveAttendance() async {
    if (_currentUser == null || _wardenHostelName == null) return;
    final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
    int updatedCount = 0;

    WriteBatch batch = _firestore.batch();

    _attendanceStatus.forEach((studentId, status) {
      if (_initialAttendanceStatus[studentId] != status) {
        final attendanceDocId = '${studentId}_$formattedDate';
        final docRef = _firestore.collection('attendance').doc(attendanceDocId);
        batch.set(
            docRef,
            {
              'studentId': studentId,
              'date': formattedDate,
              'status': status,
              'wardenId': _currentUser!.uid,
              'timestamp': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true));
        updatedCount++;
      }
    });

    try {
      await batch.commit();
      setState(() {
        _initialAttendanceStatus = {..._attendanceStatus};
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Successfully saved attendance for $updatedCount student(s).')),
      );
    } catch (e) {
      print('Error saving attendance: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save attendance: $e')),
      );
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _wardenHostelName == null
          ? const Center(child: CircularProgressIndicator())
          : Padding( // Wrap the main Column with Padding
              padding: const EdgeInsets.only(top: 40.0), // Add desired space from the top
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0), // Only horizontal padding now
                    color: Colors.white,
                    child: Column(
                      children: [
                        // Date Selector
                        TextFormField(
                          controller: _dateController,
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: 'Select Date',
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.calendar_today),
                              onPressed: () => _selectDate(context),
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                borderSide: BorderSide.none),
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Search Bar
                        TextField(
                          decoration: InputDecoration(
                            hintText:
                                'Search by ${_searchType == 'roomNumber' ? 'Room Number' : 'Roll Number'}',
                            prefixIcon: const Icon(Icons.search),
                            filled: true,
                            fillColor: Colors.grey[100],
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                borderSide: BorderSide.none),
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                borderSide: BorderSide.none),
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 0),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                        ),
                        // Radio Buttons
                        Row(
                          children: [
                            Radio<String>(
                              value: 'roomNumber',
                              groupValue: _searchType,
                              onChanged: (value) {
                                setState(() {
                                  _searchType = value!;
                                });
                              },
                            ),
                            const Text('Room Number'),
                            Radio<String>(
                              value: 'rollNumber',
                              groupValue: _searchType,
                              onChanged: (value) {
                                setState(() {
                                  _searchType = value!;
                                });
                              },
                            ),
                            const Text('Roll Number'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Student List
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: _firestore
                          .collection('students')
                          .where('hostel', isEqualTo: _wardenHostelName)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Center(child: Text('Error: ${snapshot.error}'));
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Center(
                              child: Text('No students found for your hostel.'));
                        }

                        final students = snapshot.data!.docs.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final roomNumber =
                              data['roomNumber']?.toString().toLowerCase() ?? '';
                          final rollNumber =
                              data['rollNumber']?.toString().toLowerCase() ?? '';

                          if (_searchQuery.isEmpty) {
                            return true;
                          } else if (_searchType == 'roomNumber') {
                            return roomNumber
                                .contains(_searchQuery.toLowerCase());
                          } else {
                            return rollNumber
                                .contains(_searchQuery.toLowerCase());
                          }
                        }).toList();

                        if (students.isEmpty) {
                          return const Center(
                              child: Text('No matching students found.'));
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.only(bottom: 80, top: 10),
                          itemCount: students.length,
                          itemBuilder: (context, index) {
                            final student = students[index];
                            final studentData =
                                student.data() as Map<String, dynamic>;
                            final studentId = student.id;
                            final currentStatus = _attendanceStatus[studentId];

                            return Card(
                              color: Colors.white,
                              elevation: 1,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 16.0, vertical: 6.0),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            studentData['name'] ?? 'N/A',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Roll: ${studentData['rollNumber'] ?? 'N/A'}',
                                            style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey.shade600),
                                          ),
                                          Text(
                                            'Room: ${studentData['roomNumber'] ?? 'N/A'}',
                                            style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey.shade600),
                                          ),
                                        ],
                                      ),
                                    ),
                                    _buildAttendanceButton(
                                        studentId, 'P', currentStatus),
                                    const SizedBox(width: 8),
                                    _buildAttendanceButton(
                                        studentId, 'A', currentStatus),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _saveAttendance,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A237E),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child:
                const Text('Save Attendance', style: TextStyle(fontSize: 16)),
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceButton(
      String studentId, String status, String? currentStatus) {
    bool isSelected = currentStatus == status;
    Color color = status == 'P' ? Colors.green : Colors.red;

    return GestureDetector(
      onTap: () => _stageAttendance(studentId, status),
      child: Container(
        width: 48,
        height: 36,
        decoration: BoxDecoration(
            color: isSelected ? color : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color, width: 1.5)),
        child: Center(
          child: Text(
            status,
            style: TextStyle(
              color: isSelected ? Colors.white : color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}