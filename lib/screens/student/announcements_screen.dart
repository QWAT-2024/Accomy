import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;

class AnnouncementsScreen extends StatefulWidget {
  final String? selectedAnnouncementId;

  const AnnouncementsScreen({super.key, this.selectedAnnouncementId});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  DateTimeRange? _selectedDateRange;
  bool _isDescending = true;
  final GlobalKey _selectedItemKey = GlobalKey();
  bool _initialScrollDone = false;

  @override
  void didUpdateWidget(AnnouncementsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedAnnouncementId != oldWidget.selectedAnnouncementId &&
        widget.selectedAnnouncementId != null) {
      setState(() {
        _initialScrollDone = false;
      });
    }
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Filter & Sort', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                  const SizedBox(height: 20),
                  const Text('Sort by Timestamp'),
                  Row(
                    children: [
                      const Text('Ascending'),
                      Radio<bool>(
                        value: false,
                        groupValue: _isDescending,
                        onChanged: (value) {
                          setState(() => _isDescending = value!);
                          setModalState(() {});
                        },
                      ),
                      const Text('Descending'),
                      Radio<bool>(
                        value: true,
                        groupValue: _isDescending,
                        onChanged: (value) {
                          setState(() => _isDescending = value!);
                          setModalState(() {});
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text('Filter by Date Range'),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () async {
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2101),
                        initialDateRange: _selectedDateRange,
                      );
                      if (picked != null) {
                        setState(() => _selectedDateRange = picked);
                        setModalState(() {});
                      }
                    },
                    child: Text(_selectedDateRange == null
                        ? 'Select Date Range'
                        : '${DateFormat.yMMMd().format(_selectedDateRange!.start)} - ${DateFormat.yMMMd().format(_selectedDateRange!.end)}'),
                  ),
                  if (_selectedDateRange != null)
                    TextButton(
                      onPressed: () {
                        setState(() => _selectedDateRange = null);
                        setModalState(() {});
                      },
                      child: const Text('Clear Date Range'),
                    ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Done')),
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
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 13, 40, 92),
        automaticallyImplyLeading: false,
        elevation: 0,
        toolbarHeight: 135,
        title: const SizedBox.shrink(),
        flexibleSpace: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Replaced Text with a Column for Title and Subtitle
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Announcements',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                      Text(
                        'Stay Informed. Stay Ahead.',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.filter_list, color: Colors.white, size: 28),
                    onPressed: _showFilterDialog,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: () {
            Query query = FirebaseFirestore.instance
                .collection('announcements')
                .orderBy('timestamp', descending: _isDescending);
            if (_selectedDateRange != null) {
              query = query
                  .where('timestamp', isGreaterThanOrEqualTo: _selectedDateRange!.start)
                  .where('timestamp', isLessThanOrEqualTo: _selectedDateRange!.end.add(const Duration(days: 1)));
            }
            return query.snapshots();
          }(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return const Center(child: Text('Something went wrong'));
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('No announcements'));
            
            final docs = snapshot.data!.docs;

            if (widget.selectedAnnouncementId != null && !_initialScrollDone) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_selectedItemKey.currentContext != null) {
                  Scrollable.ensureVisible(
                    _selectedItemKey.currentContext!,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                  );
                  setState(() {
                    _initialScrollDone = true;
                  });
                }
              });
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
              children: docs.map((DocumentSnapshot document) {
                final isHighlighted = document.id == widget.selectedAnnouncementId;
                return AnnouncementCard(
                  key: isHighlighted ? _selectedItemKey : null,
                  data: document.data()! as Map<String, dynamic>,
                  isHighlighted: isHighlighted,
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }
}

class AnnouncementCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final bool isHighlighted;
  const AnnouncementCard({super.key, required this.data, this.isHighlighted = false});

  @override
  State<AnnouncementCard> createState() => _AnnouncementCardState();
}

class _AnnouncementCardState extends State<AnnouncementCard> {
  bool _isExpanded = false;
  bool _isExpandable = false;

  @override
  void initState() {
    super.initState();
    if (widget.isHighlighted) {
      _isExpanded = true;
    }
  }

  @override
  void didUpdateWidget(covariant AnnouncementCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isHighlighted && !oldWidget.isHighlighted) {
      setState(() {
        _isExpanded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.data['title'] as String? ?? 'No Title';
    final description = widget.data['description'] as String? ?? 'No Description';
    final timestamp = widget.data['timestamp'] as Timestamp?;
    final postedBy = widget.data['postedBy'] as String? ?? 'N/A';
    
    return Card(
      elevation: widget.isHighlighted ? 6 : 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: widget.isHighlighted
            ? BorderSide(color: Theme.of(context).primaryColorDark, width: 2)
            : BorderSide.none,
      ),
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17.0)),
              const SizedBox(height: 8.0),
              LayoutBuilder(
                builder: (context, constraints) {
                  final descriptionStyle = TextStyle(color: Colors.grey.shade700, height: 1.4);
                  final textPainter = TextPainter(
                    text: TextSpan(text: description, style: descriptionStyle),
                    maxLines: 2,
                    textDirection: ui.TextDirection.ltr,
                  )..layout(maxWidth: constraints.maxWidth);

                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    if (_isExpandable != textPainter.didExceedMaxLines) {
                      setState(() => _isExpandable = textPainter.didExceedMaxLines);
                    }
                  });

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        description,
                        maxLines: _isExpanded ? null : 2,
                        overflow: _isExpanded ? null : TextOverflow.ellipsis,
                        style: descriptionStyle,
                      ),
                      if (_isExpandable)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: InkWell(
                              onTap: () => setState(() => _isExpanded = !_isExpanded),
                              child: Text(
                                _isExpanded ? 'Read Less' : 'Read More',
                                style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16.0),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      timestamp != null ? DateFormat('MMM d, yyyy, hh:mm a').format(timestamp.toDate()) : 'No date',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12.0),
                    ),
                  ),
                  Text(
                    'Posted by: $postedBy',
                    style: TextStyle(color: Colors.grey.shade800, fontSize: 12.0, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}