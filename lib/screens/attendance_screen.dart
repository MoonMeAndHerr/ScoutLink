import 'dart:math' as math; 
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart'; 
import '../widgets/hover_card.dart'; 

// ============================================================================
// ATTENDANCE VIEW (Ultra-Optimized for Low Latency & Quota Saving)
// ============================================================================
class AttendanceScreen extends StatefulWidget {
  final bool isAdmin; 
  const AttendanceScreen({super.key, this.isAdmin = false}); 

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final FocusNode _rfidFocusNode = FocusNode();
  final TextEditingController _rfidController = TextEditingController();
  
  final FocusNode _manualFocusNode = FocusNode();
  final TextEditingController _manualController = TextEditingController();

  String _statusMessage = '';
  Color _statusColor = Colors.transparent;
  
  // 🌟 THE LOCKS
  bool _isScannerFocused = true; 
  bool _isProcessing = false; 

  // 🌟 PAGINATION & SEARCH STATE (Optimized to 5 items per page)
  String _searchQuery = '';
  int _currentPage = 0;
  final int _itemsPerPage = 5;

  // 🌟 CACHED STREAM (Prevents Re-reading DB on every keystroke!)
  late Stream<QuerySnapshot> _attendanceStream;

  @override
  void initState() {
    super.initState();
    
    // INITIALIZE STREAM ONCE. 
    // .limit(100) ensures we only pull the most recent logs, saving massive amounts of data.
    _attendanceStream = FirebaseFirestore.instance.collection('attendance')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots();

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
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _statusMessage = '');
      });
    }
  }

  // --- PROCESSING LOGIC (WITH IC SUPPORT & ANTI-DUPLICATE LOCK) ---
  Future<void> _processAttendance({String? rfidValue, String? manualUid}) async {
    if (_isProcessing) return; // 🚨 Blocks double-taps!
    if ((rfidValue == null || rfidValue.isEmpty) && (manualUid == null || manualUid.isEmpty)) return;

    setState(() => _isProcessing = true); // 🚨 Lock engaged

    try {
      final firestore = FirebaseFirestore.instance;
      Query userQuery = firestore.collection('users').where('userType', isEqualTo: 'Participant');
      QuerySnapshot querySnapshot;

      if (rfidValue != null) {
        querySnapshot = await userQuery.where('rfid', isEqualTo: rfidValue).get();
      } else {
        // Try UID first, fallback to IC
        querySnapshot = await userQuery.where('uid', isEqualTo: manualUid).get();
        if (querySnapshot.docs.isEmpty) {
          querySnapshot = await userQuery.where('ic', isEqualTo: manualUid).get();
        }
      }

      if (querySnapshot.docs.isEmpty) {
        _setStatus(rfidValue != null ? "Unregistered Card" : "UID or IC Does Not Exist", Colors.red[700]!);
      } else {
        final userData = querySnapshot.docs.first.data() as Map<String, dynamic>;
        final String usersUID = userData['uid'] ?? '';
        final String userName = userData['name'] ?? 'Unknown Name'; 

        if (usersUID.isEmpty) {
          _setStatus("Participant is missing a UID. Please update their profile.", Colors.orange[700]!);
        } else {
          final docCheck = await firestore.collection('attendance').doc(usersUID).get();
          
          if (!docCheck.exists) {
            await firestore.collection('attendance').doc(usersUID).set({
              'rfid': userData['rfid'] ?? 'Manual Entry',
              'uid': usersUID,
              'name': userName, 
              'category': userData['category'] ?? 'Unknown',
              'timestamp': FieldValue.serverTimestamp(),
            });
            _setStatus("Attendance Recorded: $userName", Colors.green[700]!);
          } else {
            _setStatus("Already Checked In: $userName", Colors.orange[700]!);
          }
        }
      }
    } catch (e) {
      _setStatus("Database Error. Check connection.", Colors.red[700]!);
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false); // 🚨 Lock released
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

  Future<void> _deleteEntry(String uid, String userName) async {
    final bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Attendance', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to remove this attendance record for $userName?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white), onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    ) ?? false;

    if (confirm) {
      await FirebaseFirestore.instance.collection('attendance').doc(uid).delete();
      _setStatus("Deleted attendance for $userName", Colors.orange[700]!);
    }
    
    if (!mounted) return;
    FocusScope.of(context).requestFocus(_rfidFocusNode);
  }

  Widget _buildScannerForm(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Record Participant Attendance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),

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
                Icon(Icons.how_to_reg, color: _isScannerFocused ? Colors.green[700] : Colors.grey),
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
            onSubmitted: (val) => _processAttendance(rfidValue: val),
          ),
        ),

        const Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Center(child: Text('— OR —', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
        ),

        TextField(
          controller: _manualController,
          focusNode: _manualFocusNode,
          onSubmitted: (val) => _processAttendance(manualUid: val.trim()), 
          decoration: InputDecoration(
            labelText: 'Manual UID or IC Entry (e.g., STARK0001 or 010203...)',
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: const Icon(Icons.send, color: Colors.blue),
              onPressed: () => _processAttendance(manualUid: _manualController.text.trim()),
            ),
          ),
        ),
      ],
    );
  }

  // 🌟 Pagination Widget
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
                color: isSelected ? Colors.teal : Colors.grey[200],
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
            color: _currentPage > 0 ? Colors.teal : Colors.grey,
          ),
          ...pageButtons,
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _currentPage < totalPages - 1 ? () => setState(() => _currentPage++) : null,
            color: _currentPage < totalPages - 1 ? Colors.teal : Colors.grey,
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
                Text('Main Event Check-in', style: TextStyle(fontSize: isMobile ? 24 : 28, fontWeight: FontWeight.bold, color: const Color(0xFF303030))),
                SizedBox(height: isMobile ? 16 : 24),
                
                Container(
                  padding: EdgeInsets.all(isMobile ? 16 : 24),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFB0B0B0), width: 2)),
                  child: _buildScannerForm(isMobile), 
                ).animate().fade(duration: 500.ms).slideY(begin: 0.05, end: 0, duration: 500.ms, curve: Curves.easeOutQuad),
                
                const SizedBox(height: 16),

                if (_statusMessage.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(color: _statusColor.withOpacity(0.1), border: Border.all(color: _statusColor, width: 2), borderRadius: BorderRadius.circular(8)),
                    child: Text(_statusMessage, style: TextStyle(color: _statusColor, fontSize: 16, fontWeight: FontWeight.bold), textAlign: isMobile ? TextAlign.center : TextAlign.left),
                  ).animate().fade(duration: 200.ms).scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1)), 
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Live Check-in Log', style: TextStyle(fontSize: isMobile ? 18 : 20, fontWeight: FontWeight.bold, color: const Color(0xFF303030))),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Search Check-ins by Name or UID',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    fillColor: Colors.white,
                    filled: true,
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.toLowerCase().trim();
                      _currentPage = 0; // Reset pagination on search
                    });
                  },
                ),
                const SizedBox(height: 16),
                
                StreamBuilder<QuerySnapshot>(
                  stream: _attendanceStream, // 🌟 USE THE CACHED STREAM
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: Color(0xFF303030))));
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No participants checked in yet.', style: TextStyle(color: Colors.grey[500]))));

                    var allScans = snapshot.data!.docs;

                    // Apply Search Filter Locally
                    if (_searchQuery.isNotEmpty) {
                      allScans = allScans.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final name = (data['name'] ?? '').toString().toLowerCase();
                        final uid = (data['uid'] ?? '').toString().toLowerCase();
                        return name.contains(_searchQuery) || uid.contains(_searchQuery);
                      }).toList();
                    }

                    if (allScans.isEmpty) return Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No matching check-ins found in the recent log.', style: TextStyle(color: Colors.grey[500]))));

                    // 🌟 PAGINATION MATH 🌟
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
                            final usersUID = data['uid'] ?? 'No UID';
                            
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
                                          decoration: const BoxDecoration(color: Colors.teal, borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16))),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.how_to_reg, color: Colors.white, size: 28),
                                              const SizedBox(width: 12),
                                              const Expanded(child: Text('Attendance Details', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18))),
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
                                            Text('UID: $usersUID', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                            const SizedBox(height: 4),
                                            Text('Category: ${data['category'] ?? 'Unknown'}', style: TextStyle(fontSize: 16, color: Colors.grey.shade700)),
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
                                                _deleteEntry(usersUID, name);
                                              }
                                            )
                                        ],
                                      )
                                    );
                                  },
                                  child: ListTile(
                                    contentPadding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 20, vertical: 8),
                                    leading: const CircleAvatar(backgroundColor: Colors.teal, child: Icon(Icons.check, color: Colors.white)),
                                    title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    subtitle: Text('UID: $usersUID  |  ${data['category'] ?? 'Unknown'}', style: TextStyle(fontSize: isMobile ? 12 : 14), maxLines: 1, overflow: TextOverflow.ellipsis),
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
                        // 🌟 MOUNT THE PAGINATION WIDGET AT THE BOTTOM
                        _buildPagination(totalPages),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}