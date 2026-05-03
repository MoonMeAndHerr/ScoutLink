import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../widgets/hover_card.dart';
// Note: Ensure your ParticipantFormScreen is imported correctly here if needed!
// import 'participant_form_screen.dart'; 

// ============================================================================
// PARTICIPANTS VIEW (Ultra-Optimized + Pagination + Cached Streams)
// ============================================================================
class ParticipantsView extends StatefulWidget {
  final bool isAdmin;
  const ParticipantsView({super.key, this.isAdmin = false});

  @override
  State<ParticipantsView> createState() => _ParticipantsViewState();
}

class _ParticipantsViewState extends State<ParticipantsView> {
  // 🌟 PAGINATION & SEARCH STATE
  String _searchQuery = '';
  int _currentPage = 0;
  final int _itemsPerPage = 5; // Keeps the UI blazing fast!

  // 🌟 CACHED STREAM (The ultimate quota saver)
  late Stream<QuerySnapshot> _participantsStream;

  @override
  void initState() {
    super.initState();
    // Fetch the participants ONCE when the page loads.
    _participantsStream = FirebaseFirestore.instance
        .collection('users')
        .where('userType', isEqualTo: 'Participant')
        .snapshots();
  }

  // --- DELETE LOGIC ---
  Future<void> _deleteParticipant(String docId, String name) async {
    final bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Participant', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to completely remove $name from the system? This cannot be undone.'),
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
      await FirebaseFirestore.instance.collection('users').doc(docId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$name deleted successfully.'), backgroundColor: Colors.orange));
      }
    }
  }

  // --- DIALOG HELPER WIDGETS ---
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
    );
  }

  Widget _detailRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 140, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
          Expanded(child: Text(value?.toString().isNotEmpty == true ? value.toString() : '-', style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  // --- PARTICIPANT DETAILS POP-UP (With the layout fix!) ---
  void _showParticipantDetails(BuildContext context, Map<String, dynamic> data, String docId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          titlePadding: const EdgeInsets.all(0),
          title: Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(color: Color(0xFF303030), borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16))),
            child: Row(
              children: [
                const CircleAvatar(backgroundColor: Colors.teal, child: Icon(Icons.person, color: Colors.white)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data['name']?.toString().isEmpty == false ? data['name'] : 'Unnamed Participant', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                      Text(data['uid']?.toString().isEmpty == false ? data['uid'] : 'No UID', style: const TextStyle(color: Colors.grey, fontSize: 14)),
                    ],
                  ),
                ),
                IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
              ],
            ),
          ),
          content: SizedBox(
            width: 600,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Registration Info'),
                  _detailRow('UID', data['uid']),
                  _detailRow('Category', data['category']),
                  _detailRow('Fee Paid', data['fee'] ?? data['feePaid']), 
                  _detailRow('Tee Size', data['tee']),
                  _detailRow('RFID Tag', data['rfid']),

                  const Divider(height: 32),
                  _buildSectionTitle('Personal Details'),
                  _detailRow('Email', data['email']),
                  _detailRow('Phone', data['phone']),
                  _detailRow('Emergency', data['emergency']),
                  _detailRow('IC Number', data['ic']),

                  const Divider(height: 32),
                  _buildSectionTitle('Live Activity Log'),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('activity_tracker')
                        .where('usersUID', isEqualTo: data['uid'])
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) return const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()));
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Padding(padding: EdgeInsets.all(8.0), child: Text('No activities visited yet.', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)));

                      var activities = snapshot.data!.docs;
                      activities.sort((a, b) {
                        Timestamp? tA = (a.data() as Map)['timestamp'] as Timestamp?;
                        Timestamp? tB = (b.data() as Map)['timestamp'] as Timestamp?;
                        if (tA == null) return 1; if (tB == null) return -1;
                        return tB.compareTo(tA);
                      });

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: activities.length,
                        itemBuilder: (context, index) {
                          final actData = activities[index].data() as Map<String, dynamic>;
                          String timeStr = 'Just now';
                          if (actData['timestamp'] != null) {
                            DateTime dt = (actData['timestamp'] as Timestamp).toDate();
                            timeStr = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                          }
                          return Card(
                            elevation: 0, color: Colors.blue.shade50,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.blue.shade200)),
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              dense: true,
                              leading: const Icon(Icons.local_activity, color: Colors.blue),
                              title: Text('Activity: ${actData['activityUID']}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                              trailing: Text(timeStr, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          // 🌟 The layout fix: Splits buttons left and right!
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            // LEFT SIDE
            TextButton.icon(
              icon: const Icon(Icons.delete, color: Colors.red), 
              label: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.pop(context);
                _deleteParticipant(docId, data['name'] ?? 'Participant');
              },
            ),
            // RIGHT SIDE
            Wrap(
              spacing: 8, runSpacing: 8,
              alignment: WrapAlignment.end,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                  icon: const Icon(Icons.inventory, size: 18), 
                  label: const Text('Checklist'),
                  onPressed: () {
                    // Add your Checklist dialog logic here!
                  },
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                  icon: const Icon(Icons.edit, size: 18), 
                  label: const Text('Edit Details'),
                  onPressed: () {
                    Navigator.pop(context);
                    // Navigator.push(context, MaterialPageRoute(builder: (context) => ParticipantFormScreen(existingData: data, docId: docId)));
                  },
                ),
              ],
            ),
          ],
        );
      }
    );
  }

  // 🌟 PAGINATION WIDGET
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
                Text('Participants Directory', style: TextStyle(fontSize: isMobile ? 24 : 28, fontWeight: FontWeight.bold, color: const Color(0xFF303030))),
                SizedBox(height: isMobile ? 16 : 24),
                
                // 🌟 SEARCH BAR (Locally filters the cached stream!)
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Search by Name, UID, or IC Number',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    fillColor: Colors.white,
                    filled: true,
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.toLowerCase().trim();
                      _currentPage = 0; // Reset pagination!
                    });
                  },
                ),
                const SizedBox(height: 24),
                
                // 🌟 THE MASTER STREAM
                StreamBuilder<QuerySnapshot>(
                  stream: _participantsStream, 
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: Color(0xFF303030))));
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No participants registered yet.', style: TextStyle(color: Colors.grey[500]))));

                    var allParticipants = snapshot.data!.docs;

                    // LOCAL SEARCH (0 Extra Quota Reads!)
                    if (_searchQuery.isNotEmpty) {
                      allParticipants = allParticipants.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final name = (data['name'] ?? '').toString().toLowerCase();
                        final uid = (data['uid'] ?? '').toString().toLowerCase();
                        final ic = (data['ic'] ?? '').toString().toLowerCase();
                        return name.contains(_searchQuery) || uid.contains(_searchQuery) || ic.contains(_searchQuery);
                      }).toList();
                    }

                    if (allParticipants.isEmpty) return Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No participants match your search.', style: TextStyle(color: Colors.grey[500]))));

                    // 🌟 PAGINATION SLICING
                    int totalPages = (allParticipants.length / _itemsPerPage).ceil();
                    if (_currentPage >= totalPages && totalPages > 0) {
                      _currentPage = totalPages - 1; 
                    }
                    var paginatedUsers = allParticipants.skip(_currentPage * _itemsPerPage).take(_itemsPerPage).toList();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Showing ${allParticipants.length} Participants', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
                        const SizedBox(height: 12),
                        
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: paginatedUsers.length,
                          itemBuilder: (context, index) {
                            final data = paginatedUsers[index].data() as Map<String, dynamic>;
                            final docId = paginatedUsers[index].id;
                            final name = data['name'] ?? 'Unknown';
                            final uid = data['uid'] ?? 'No UID';
                            final category = data['category'] ?? 'Uncategorized';
                            
                            return HoverCard(
                              child: Card(
                                elevation: 0, color: Colors.white, margin: const EdgeInsets.only(bottom: 1), 
                                shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(8)),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(8),
                                  onTap: () => _showParticipantDetails(context, data, docId),
                                  child: ListTile(
                                    contentPadding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 20, vertical: 12),
                                    leading: const CircleAvatar(backgroundColor: Color(0xFF303030), child: Icon(Icons.person, color: Colors.white)),
                                    title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    subtitle: Text('UID: $uid  |  $category', style: TextStyle(fontSize: isMobile ? 12 : 14), maxLines: 1, overflow: TextOverflow.ellipsis),
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
                        
                        // 🌟 THE PAGINATION BAR
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