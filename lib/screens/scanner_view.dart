import 'dart:math' as math; 
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart'; 
import '../widgets/hover_card.dart'; 

// ============================================================================
// SCANNER VIEW (Ultra-Optimized for Low Latency & Quota Saving)
// ============================================================================
class ScannerView extends StatefulWidget {
  final bool isAdmin; 
  const ScannerView({super.key, this.isAdmin = false}); 

  @override
  State<ScannerView> createState() => _ScannerViewState();
}

class _ScannerViewState extends State<ScannerView> {
  final FocusNode _rfidFocusNode = FocusNode();
  final TextEditingController _rfidController = TextEditingController();
  
  final FocusNode _manualFocusNode = FocusNode();
  final TextEditingController _manualController = TextEditingController();

  // --- FORM FILTERS ---
  String _formFilterType = 'All';
  String _formFilterVenue = 'All';
  
  // --- LIVE LOG FILTERS ---
  String _logSearchQuery = '';
  String _logFilterActivity = 'All';
  String _logFilterBuilding = 'All';

  // 🌟 SET TO 5 ITEMS PER PAGE
  int _currentPage = 0;
  final int _itemsPerPage = 5; 

  final List<String> _activityTypes = ['All', 'Expedition', 'Exhibition', 'Forum', 'Other'];
  final List<String> _venueCategories = ['All', 'Biological Building', 'Admin Building', 'Physical Building'];

  List<String> _selectedActivityUids = []; 
  String _statusMessage = '';
  Color _statusColor = Colors.transparent;
  
  bool _isScannerFocused = true; 
  bool _isProcessing = false; 

  // 🌟 CACHED STREAMS (Prevents Re-reading DB on every keystroke!)
  late Stream<QuerySnapshot> _usersStream;
  late Stream<QuerySnapshot> _activitiesStream;
  late Stream<QuerySnapshot> _trackerStream;

  @override
  void initState() {
    super.initState();
    
    // INITIALIZE STREAMS ONCE. 
    // .limit(100) ensures we only pull the most recent logs, saving massive amounts of data.
    _usersStream = FirebaseFirestore.instance.collection('users').where('userType', isEqualTo: 'Participant').snapshots();
    _activitiesStream = FirebaseFirestore.instance.collection('activities').snapshots();
    _trackerStream = FirebaseFirestore.instance.collection('activity_tracker').orderBy('timestamp', descending: true).limit(100).snapshots();

    _rfidFocusNode.addListener(() {
      setState(() => _isScannerFocused = _rfidFocusNode.hasFocus);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_rfidFocusNode);
    });
  }

  @override
  void dispose() {
    _rfidFocusNode.dispose();
    _rfidController.dispose();
    _manualFocusNode.dispose();
    _manualController.dispose();
    super.dispose();
  }

  void _setStatus(String message, Color color) {
    setState(() {
      _statusMessage = message;
      _statusColor = color;
    });
    if (color != Colors.red[700]) {
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) setState(() => _statusMessage = '');
      });
    }
  }

  Future<void> _processActivityScan({String? rfidValue, String? manualUid}) async {
    if (_isProcessing) return; 
    
    if ((rfidValue == null || rfidValue.isEmpty) && (manualUid == null || manualUid.isEmpty)) return;

    if (_selectedActivityUids.isEmpty) {
      _setStatus("Please select at least one Activity.", Colors.orange[700]!);
      _rfidController.clear();
      _manualController.clear();
      if (mounted && rfidValue != null) FocusScope.of(context).requestFocus(_rfidFocusNode);
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final firestore = FirebaseFirestore.instance;
      Query userQuery = firestore.collection('users').where('userType', isEqualTo: 'Participant');
      QuerySnapshot querySnapshot;

      if (rfidValue != null) {
        querySnapshot = await userQuery.where('rfid', isEqualTo: rfidValue).get();
      } else {
        querySnapshot = await userQuery.where('uid', isEqualTo: manualUid).get();
        if (querySnapshot.docs.isEmpty) {
          querySnapshot = await userQuery.where('ic', isEqualTo: manualUid).get();
        }
      }

      if (querySnapshot.docs.isEmpty) {
        _setStatus(rfidValue != null ? "Unregistered Card" : "UID or IC Does Not Exist", Colors.red[700]!);
        return;
      }

      final userData = querySnapshot.docs.first.data() as Map<String, dynamic>;
      final String usersUID = userData['uid'] ?? '';
      final String userName = userData['name'] ?? 'Unknown Name'; 

      if (usersUID.isEmpty) {
        _setStatus("Participant profile error: Missing UID.", Colors.red[700]!);
        return;
      }

      final attendanceCheck = await firestore.collection('attendance').doc(usersUID).get();
      if (!attendanceCheck.exists) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(children: [Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 32), SizedBox(width: 8), Text('Attendance Missing!')]),
              content: Text("Participant $userName hasn't checked in yet!\n\nPlease ask them to visit the main registration desk to mark their attendance before joining activities.", style: const TextStyle(fontSize: 16)),
              actions: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                  onPressed: () {
                    Navigator.pop(context);
                    if (rfidValue != null) FocusScope.of(context).requestFocus(_rfidFocusNode);
                  },
                  child: const Text('OK, Understood'),
                ),
              ],
            ),
          );
        }
        return; 
      }

      int successCount = 0;
      int duplicateCount = 0;

      for (String actUid in _selectedActivityUids) {
        final activityQuery = await firestore
            .collection('activity_tracker')
            .where('usersUID', isEqualTo: usersUID)
            .where('activityUID', isEqualTo: actUid)
            .get();

        if (activityQuery.docs.isEmpty) {
          await firestore.collection('activity_tracker').add({
            'rfid': userData['rfid'] ?? 'Manual Entry',
            'usersUID': usersUID,
            'activityUID': actUid,
            'timestamp': FieldValue.serverTimestamp(),
            'name': userName, 
          });
          successCount++;
        } else {
          duplicateCount++;
        }
      }

      if (successCount > 0 && duplicateCount == 0) {
        _setStatus("Activity logged: $userName", Colors.green[700]!);
      } else if (successCount > 0 && duplicateCount > 0) {
        _setStatus("Partial Log: $userName ($successCount added, $duplicateCount already done)", Colors.orange[700]!);
      } else {
        _setStatus("Already logged for all selected activities: $userName", Colors.red[700]!);
      }
      
    } catch (e) {
      _setStatus("Database Error. Check connection.", Colors.red[700]!);
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
        _rfidController.clear();
        _manualController.clear();
        if (rfidValue != null) {
          FocusScope.of(context).requestFocus(_rfidFocusNode);
        } else {
          FocusScope.of(context).requestFocus(_manualFocusNode);
        }
      }
    }
  }

  Future<void> _deleteEntry(String docId, String userName) async {
    final bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Activity Log', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to remove this activity record for $userName?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      await FirebaseFirestore.instance.collection('activity_tracker').doc(docId).delete();
      _setStatus("Deleted activity record for $userName", Colors.orange[700]!);
    }
    
    if (!mounted) return;
    FocusScope.of(context).requestFocus(_rfidFocusNode);
  }

  void _showMultiSelectDialog(List<DocumentSnapshot> availableDocs) {
    List<String> tempSelected = List.from(_selectedActivityUids);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Select Target Activities', style: TextStyle(fontWeight: FontWeight.bold)),
              contentPadding: const EdgeInsets.only(top: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              content: SizedBox(
                width: 400, 
                child: availableDocs.isEmpty 
                  ? const Padding(padding: EdgeInsets.all(24.0), child: Text("No activities match the current filters."))
                  : ListView(
                      shrinkWrap: true,
                      children: availableDocs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final uid = data['uid'].toString();
                        final name = data['name'].toString();
                        final isChecked = tempSelected.contains(uid);

                        return CheckboxListTile(
                          activeColor: const Color(0xFF303030),
                          title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(uid),
                          value: isChecked,
                          onChanged: (bool? value) {
                            setDialogState(() {
                              if (value == true) {
                                tempSelected.add(uid);
                              } else {
                                tempSelected.remove(uid);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
              ),
              actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context), 
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey))
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF303030), foregroundColor: Colors.white),
                  onPressed: () {
                    setState(() => _selectedActivityUids = List.from(tempSelected));
                    Navigator.pop(context);
                    FocusScope.of(context).requestFocus(_rfidFocusNode); 
                  },
                  child: const Text('Confirm Selection'),
                ),
              ],
            );
          }
        );
      }
    );
  }

  Widget _buildScannerForm(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('1. Select Target Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: isMobile ? double.infinity : 200,
              child: DropdownButtonFormField<String>(
                isExpanded: true,
                value: _formFilterType,
                decoration: const InputDecoration(labelText: 'Filter by Type', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                items: _activityTypes.map((type) => DropdownMenuItem(value: type, child: Text(type, maxLines: 1, overflow: TextOverflow.ellipsis))).toList(),
                onChanged: (val) => setState(() {
                  _formFilterType = val!;
                  _selectedActivityUids.clear(); 
                }),
              ),
            ),
            SizedBox(
              width: isMobile ? double.infinity : 250,
              child: DropdownButtonFormField<String>(
                isExpanded: true,
                value: _formFilterVenue,
                decoration: const InputDecoration(labelText: 'Filter by Venue', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                items: _venueCategories.map((venue) => DropdownMenuItem(value: venue, child: Text(venue, maxLines: 1, overflow: TextOverflow.ellipsis))).toList(),
                onChanged: (val) => setState(() {
                  _formFilterVenue = val!;
                  _selectedActivityUids.clear(); 
                }),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        StreamBuilder<QuerySnapshot>(
          stream: _activitiesStream, // USE CACHED STREAM
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const LinearProgressIndicator(color: Color(0xFF303030));
            
            var docs = snapshot.data!.docs;
            
            if (_formFilterType != 'All') {
              docs = docs.where((doc) => (doc.data() as Map<String, dynamic>)['activityType'] == _formFilterType).toList();
            }
            if (_formFilterVenue != 'All') {
              docs = docs.where((doc) => (doc.data() as Map<String, dynamic>)['venueCategory'] == _formFilterVenue).toList();
            }

            return InkWell(
              onTap: () => _showMultiSelectDialog(docs),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: _selectedActivityUids.isEmpty ? Colors.grey[400]! : const Color(0xFF303030), width: _selectedActivityUids.isEmpty ? 1 : 2), 
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _selectedActivityUids.isEmpty 
                          ? "Select Activities..." 
                          : "${_selectedActivityUids.length} Activities Selected for Log",
                        style: TextStyle(
                          fontSize: 16, 
                          fontWeight: _selectedActivityUids.isEmpty ? FontWeight.normal : FontWeight.bold,
                          color: _selectedActivityUids.isEmpty ? Colors.grey[600] : const Color(0xFF303030),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(Icons.checklist, color: _selectedActivityUids.isEmpty ? Colors.grey : const Color(0xFF303030)),
                  ],
                ),
              ),
            );
          },
        ),
        
        const SizedBox(height: 32),
        const Text('2. Log Activity Participation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),

        GestureDetector(
          onTap: () => FocusScope.of(context).requestFocus(_rfidFocusNode),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _isScannerFocused ? Colors.green[50] : Colors.grey[100],
              border: Border.all(color: _isScannerFocused ? Colors.green : Colors.grey[300]!, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.wifi_tethering, color: _isScannerFocused ? Colors.green[700] : Colors.grey),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    _isScannerFocused ? 'RFID Scanner Active (Tap Card Now)' : 'RFID Scanner Paused (Click to Reactivate)',
                    style: TextStyle(fontWeight: FontWeight.bold, color: _isScannerFocused ? Colors.green[700] : Colors.grey[600]),
                  ),
                ),
              ],
            ),
          ),
        ),

        SizedBox(
          height: 0, width: 0,
          child: TextField(
            controller: _rfidController,
            focusNode: _rfidFocusNode,
            onSubmitted: (val) => _processActivityScan(rfidValue: val),
          ),
        ),

        const Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Center(child: Text('— OR —', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
        ),

        TextField(
          controller: _manualController,
          focusNode: _manualFocusNode,
          onSubmitted: (val) => _processActivityScan(manualUid: val.trim()), 
          decoration: InputDecoration(
            labelText: 'Participant UID or IC (e.g., STARK0001 or 010203...)', 
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: const Icon(Icons.send, color: Colors.blue),
              onPressed: () => _processActivityScan(manualUid: _manualController.text.trim()),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPagination(int totalPages) {
    if (totalPages <= 1) return const SizedBox.shrink();

    List<Widget> pageButtons = [];
    int startPage = math.max(0, _currentPage - 2);
    int endPage = math.min(totalPages - 1, _currentPage + 2);

    for (int i = startPage; i <= endPage; i++) {
      bool isSelected = _currentPage == i;
      pageButtons.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: InkWell(
            onTap: () => setState(() => _currentPage = i),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF303030) : Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${i + 1}',
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null,
            color: _currentPage > 0 ? const Color(0xFF303030) : Colors.grey,
          ),
          ...pageButtons,
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _currentPage < totalPages - 1 ? () => setState(() => _currentPage++) : null,
            color: _currentPage < totalPages - 1 ? const Color(0xFF303030) : Colors.grey,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isMobile = constraints.maxWidth < 700; 

        return SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 16.0 : 32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Activity Booth Tracker', style: TextStyle(fontSize: isMobile ? 24 : 28, fontWeight: FontWeight.bold, color: const Color(0xFF303030))),
                SizedBox(height: isMobile ? 16 : 24),
                
                Container(
                  padding: EdgeInsets.all(isMobile ? 16 : 24),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFB0B0B0), width: 2)),
                  child: isMobile 
                    ? Column(children: [_buildScannerForm(isMobile)])
                    : _buildScannerForm(isMobile), 
                ).animate().fade(duration: 500.ms).slideY(begin: 0.05, end: 0, duration: 500.ms, curve: Curves.easeOutQuad),
                
                const SizedBox(height: 16),

                if (_statusMessage.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(color: _statusColor.withOpacity(0.1), border: Border.all(color: _statusColor, width: 2), borderRadius: BorderRadius.circular(8)),
                    child: Text(
                      _statusMessage,
                      style: TextStyle(color: _statusColor, fontSize: 16, fontWeight: FontWeight.bold),
                      textAlign: isMobile ? TextAlign.center : TextAlign.left,
                    ),
                  ).animate().fade(duration: 200.ms).scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1)), 
                
                const SizedBox(height: 16),
                Text('Live Activity Log', style: TextStyle(fontSize: isMobile ? 18 : 20, fontWeight: FontWeight.bold, color: const Color(0xFF303030))),
                const SizedBox(height: 12),

                StreamBuilder<QuerySnapshot>(
                  stream: _usersStream, // USE CACHED STREAM
                  builder: (context, userSnapshot) {
                    Map<String, String> uidToIc = {};
                    if (userSnapshot.hasData) {
                      for (var doc in userSnapshot.data!.docs) {
                        final d = doc.data() as Map<String, dynamic>;
                        uidToIc[d['uid'] ?? ''] = (d['ic'] ?? '').toString().toLowerCase();
                      }
                    }

                    return StreamBuilder<QuerySnapshot>(
                      stream: _activitiesStream, // USE CACHED STREAM
                      builder: (context, actSnapshot) {
                        Map<String, String> actToVenue = {};
                        List<DropdownMenuItem<String>> actItems = [const DropdownMenuItem(value: 'All', child: Text("All Activities", maxLines: 1, overflow: TextOverflow.ellipsis))];
                        List<String> venues = ['All'];

                        if (actSnapshot.hasData) {
                          for (var doc in actSnapshot.data!.docs) {
                            final d = doc.data() as Map<String, dynamic>;
                            actToVenue[d['uid'] ?? ''] = d['venueCategory'] ?? 'Unknown';
                            actItems.add(DropdownMenuItem(value: d['uid'], child: Text("${d['uid']} - ${d['name']}", maxLines: 1, overflow: TextOverflow.ellipsis)));
                            if (!venues.contains(d['venueCategory'])) venues.add(d['venueCategory'] ?? 'Unknown');
                          }
                        }

                        List<DropdownMenuItem<String>> venueItems = venues.map((v) => DropdownMenuItem(value: v, child: Text(v == 'All' ? 'All Buildings' : v, maxLines: 1, overflow: TextOverflow.ellipsis))).toList();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[300]!)),
                              child: Wrap(
                                spacing: 12, runSpacing: 12,
                                children: [
                                  SizedBox(
                                    width: isMobile ? double.infinity : 250,
                                    child: TextField(
                                      decoration: const InputDecoration(labelText: 'Search Name, UID, or IC', prefixIcon: Icon(Icons.search), border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                                      onChanged: (val) => setState(() {
                                        _logSearchQuery = val.toLowerCase().trim();
                                        _currentPage = 0;
                                      }),
                                    )
                                  ),
                                  SizedBox(
                                    width: isMobile ? double.infinity : 200,
                                    child: DropdownButtonFormField<String>(
                                      isExpanded: true,
                                      value: _logFilterActivity,
                                      decoration: const InputDecoration(labelText: 'Filter Activity', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                                      items: actItems,
                                      onChanged: (val) => setState(() {
                                        _logFilterActivity = val!;
                                        _currentPage = 0;
                                      }),
                                    )
                                  ),
                                  SizedBox(
                                    width: isMobile ? double.infinity : 200,
                                    child: DropdownButtonFormField<String>(
                                      isExpanded: true,
                                      value: _logFilterBuilding,
                                      decoration: const InputDecoration(labelText: 'Filter Building', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                                      items: venueItems,
                                      onChanged: (val) => setState(() {
                                        _logFilterBuilding = val!;
                                        _currentPage = 0;
                                      }),
                                    )
                                  ),
                                ]
                              )
                            ),
                            const SizedBox(height: 16),
                            
                            StreamBuilder<QuerySnapshot>(
                              stream: _trackerStream, // USE CACHED AND LIMITED STREAM!
                              builder: (context, trackSnapshot) {
                                if (trackSnapshot.connectionState == ConnectionState.waiting) return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: Color(0xFF303030))));
                                if (!trackSnapshot.hasData || trackSnapshot.data!.docs.isEmpty) return Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No activities logged yet.', style: TextStyle(color: Colors.grey[500]))));

                                var allScans = trackSnapshot.data!.docs;

                                if (_logFilterActivity != 'All') {
                                  allScans = allScans.where((doc) => (doc.data() as Map)['activityUID'] == _logFilterActivity).toList();
                                }
                                if (_logFilterBuilding != 'All') {
                                  allScans = allScans.where((doc) {
                                    String actUid = (doc.data() as Map)['activityUID'] ?? '';
                                    return actToVenue[actUid] == _logFilterBuilding;
                                  }).toList();
                                }
                                if (_logSearchQuery.isNotEmpty) {
                                  allScans = allScans.where((doc) {
                                    var d = doc.data() as Map<String, dynamic>;
                                    String name = (d['name'] ?? '').toString().toLowerCase();
                                    String uid = (d['usersUID'] ?? '').toString().toLowerCase();
                                    String ic = uidToIc[d['usersUID']] ?? ''; 
                                    return name.contains(_logSearchQuery) || uid.contains(_logSearchQuery) || ic.contains(_logSearchQuery);
                                  }).toList();
                                }

                                if (allScans.isEmpty) return Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No scans match your filters.', style: TextStyle(color: Colors.grey[500]))));

                                int totalPages = (allScans.length / _itemsPerPage).ceil();
                                if (_currentPage >= totalPages && totalPages > 0) {
                                  _currentPage = totalPages - 1; 
                                }
                                
                                var paginatedScans = allScans.skip(_currentPage * _itemsPerPage).take(_itemsPerPage).toList();

                                return Column(
                                  children: [
                                    ListView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: paginatedScans.length,
                                      itemBuilder: (context, index) {
                                        final data = paginatedScans[index].data() as Map<String, dynamic>;
                                        final name = data['name'] ?? 'Unknown';
                                        final usersUID = data['usersUID'] ?? 'No UID';
                                        final actUid = data['activityUID'] ?? 'Unknown Act';
                                        final docId = paginatedScans[index].id;
                                        
                                        return HoverCard(
                                          child: Card(
                                            elevation: 0, color: Colors.white, margin: const EdgeInsets.only(bottom: 1), 
                                            shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(8)),
                                            child: InkWell(
                                              borderRadius: BorderRadius.circular(8),
                                              onTap: () {
                                                showDialog(
                                                  context: context,
                                                  builder: (ctx) => AlertDialog(
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                                    titlePadding: const EdgeInsets.all(0),
                                                    title: Container(
                                                      padding: const EdgeInsets.all(20),
                                                      decoration: const BoxDecoration(color: Color(0xFF303030), borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16))),
                                                      child: Row(
                                                        children: [
                                                          const Icon(Icons.local_activity, color: Colors.white, size: 28),
                                                          const SizedBox(width: 12),
                                                          const Expanded(child: Text('Activity Log Details', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18))),
                                                          IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(ctx), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                                                        ],
                                                      ),
                                                    ),
                                                    content: Column(
                                                      mainAxisSize: MainAxisSize.min,
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF303030))),
                                                        const SizedBox(height: 16),
                                                        Text('Participant UID: $usersUID', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                                        const SizedBox(height: 4),
                                                        Text('Activity Code: $actUid', style: TextStyle(fontSize: 16, color: Colors.grey.shade700)),
                                                      ],
                                                    ),
                                                    actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                                    actions: [
                                                      if (widget.isAdmin)
                                                        ElevatedButton.icon(
                                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                                                          icon: const Icon(Icons.delete, size: 18), label: const Text('Delete Record'),
                                                          onPressed: () {
                                                            Navigator.pop(ctx);
                                                            _deleteEntry(docId, name);
                                                          }
                                                        )
                                                    ],
                                                  )
                                                );
                                              },
                                              child: ListTile(
                                                contentPadding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 20, vertical: 8),
                                                leading: const CircleAvatar(backgroundColor: Color(0xFF303030), child: Icon(Icons.local_activity, color: Colors.white)),
                                                title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                                                subtitle: Text('UID: $usersUID  |  Activity: $actUid', style: TextStyle(fontSize: isMobile ? 12 : 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                                                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                                              ),
                                            ),
                                          ),
                                        )
                                        .animate(delay: (index * 20).clamp(0, 300).ms)
                                        .fade(duration: 400.ms)
                                        .slideY(begin: 0.1, end: 0, duration: 400.ms, curve: Curves.easeOutQuad);
                                      },
                                    ),
                                    _buildPagination(totalPages),
                                  ],
                                );
                              }
                            )
                          ]
                        );
                      }
                    );
                  }
                )
              ],
            ),
          ),
        );
      },
    );
  }
}