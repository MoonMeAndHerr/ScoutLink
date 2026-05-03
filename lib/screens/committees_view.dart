import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../widgets/hover_card.dart';

// ============================================================================
// COMMITTEES VIEW (Ultra-Optimized + Pagination + Position Color-Coding)
// ============================================================================
class CommitteesView extends StatefulWidget {
  final bool isAdmin;
  const CommitteesView({super.key, this.isAdmin = false});

  @override
  State<CommitteesView> createState() => _CommitteesViewState();
}

class _CommitteesViewState extends State<CommitteesView> {
  // 🌟 PAGINATION & SEARCH STATE
  String _searchQuery = '';
  int _currentPage = 0;
  final int _itemsPerPage = 5;

  // 🌟 CACHED STREAM
  late Stream<QuerySnapshot> _committeesStream;

  @override
  void initState() {
    super.initState();
    _committeesStream = FirebaseFirestore.instance
        .collection('users')
        .where('userType', isEqualTo: 'Committee') 
        .snapshots();
  }

  // 🌟 DYNAMIC COLOR CODER FOR POSITIONS
  Color _getPositionColor(String position) {
    final lowerPos = position.toLowerCase();
    if (lowerPos.contains('president') || lowerPos.contains('director') || lowerPos.contains('manager') || lowerPos.contains('chairperson')) {
      return Colors.amber.shade700; // Gold for High Council
    }
    if (lowerPos.contains('secretary')) {
      return Colors.blue; 
    }
    if (lowerPos.contains('treasurer') || lowerPos.contains('finance')) {
      return Colors.green; 
    }
    if (lowerPos.contains('head') || lowerPos.contains('lead') || lowerPos.contains('coordinator')) {
      return Colors.deepOrange; // Orange for HODs
    }
    if (lowerPos.contains('admin')) {
      return Colors.red; 
    }
    return Colors.purple; // Default for standard Committee members
  }

  // --- DELETE LOGIC ---
  Future<void> _deleteCommittee(String docId, String name) async {
    final bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove Committee Member', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to remove $name from the committee system?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      await FirebaseFirestore.instance.collection('users').doc(docId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$name removed successfully.'), backgroundColor: Colors.orange));
      }
    }
  }

  // --- DIALOG HELPER WIDGETS ---
  Widget _buildSectionTitle(String title, Color themeColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: themeColor)),
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

  // --- COMMITTEE DETAILS POP-UP ---
  void _showCommitteeDetails(BuildContext context, Map<String, dynamic> data, String docId, Color positionColor) {
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
                CircleAvatar(backgroundColor: positionColor, child: const Icon(Icons.admin_panel_settings, color: Colors.white)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data['name']?.toString().isEmpty == false ? data['name'] : 'Unnamed Member', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                      Text(data['position']?.toString().isEmpty == false ? data['position'] : 'Committee Member', style: const TextStyle(color: Colors.grey, fontSize: 14)),
                    ],
                  ),
                ),
                IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
              ],
            ),
          ),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Staff Profile', positionColor),
                  _detailRow('UID / Staff ID', data['uid']),
                  _detailRow('Assigned Position', data['position']),
                  _detailRow('Department', data['department'] ?? data['bureau']),
                  
                  const Divider(height: 32),
                  _buildSectionTitle('Contact Details', positionColor),
                  _detailRow('Phone', data['phone']),
                  _detailRow('Email', data['email']),
                ],
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            if (widget.isAdmin)
              TextButton.icon(
                icon: const Icon(Icons.delete, color: Colors.red), 
                label: const Text('Remove', style: TextStyle(color: Colors.red)),
                onPressed: () {
                  Navigator.pop(context);
                  _deleteCommittee(docId, data['name'] ?? 'Member');
                },
              )
            else 
              const SizedBox.shrink(),

            if (widget.isAdmin)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: positionColor, foregroundColor: Colors.white),
                icon: const Icon(Icons.edit, size: 18), 
                label: const Text('Edit Details'),
                onPressed: () {
                  Navigator.pop(context);
                  // Add navigation to an Edit Form here if needed
                },
              )
            else
              TextButton(
                onPressed: () => Navigator.pop(context), 
                child: const Text('Close', style: TextStyle(color: Colors.grey))
              ),
          ],
        );
      }
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Committee Directory', style: TextStyle(fontSize: isMobile ? 24 : 28, fontWeight: FontWeight.bold, color: const Color(0xFF303030))),
                    if (widget.isAdmin)
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
                        icon: const Icon(Icons.person_add),
                        label: const Text('Add Member'),
                        onPressed: () {
                          // Navigation to Add Form
                        },
                      )
                  ],
                ),
                SizedBox(height: isMobile ? 16 : 24),
                
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Search by Name, Position, or Department',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    fillColor: Colors.white,
                    filled: true,
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.toLowerCase().trim();
                      _currentPage = 0; 
                    });
                  },
                ),
                const SizedBox(height: 24),
                
                StreamBuilder<QuerySnapshot>(
                  stream: _committeesStream, 
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: Color(0xFF303030))));
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No committee members found.', style: TextStyle(color: Colors.grey[500]))));

                    var allCommittees = snapshot.data!.docs;

                    if (_searchQuery.isNotEmpty) {
                      allCommittees = allCommittees.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final name = (data['name'] ?? '').toString().toLowerCase();
                        final position = (data['position'] ?? '').toString().toLowerCase();
                        final dept = (data['department'] ?? data['bureau'] ?? '').toString().toLowerCase();
                        return name.contains(_searchQuery) || position.contains(_searchQuery) || dept.contains(_searchQuery);
                      }).toList();
                    }

                    if (allCommittees.isEmpty) return Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No members match your search.', style: TextStyle(color: Colors.grey[500]))));

                    int totalPages = (allCommittees.length / _itemsPerPage).ceil();
                    if (_currentPage >= totalPages && totalPages > 0) {
                      _currentPage = totalPages - 1; 
                    }
                    var paginatedMembers = allCommittees.skip(_currentPage * _itemsPerPage).take(_itemsPerPage).toList();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Showing ${allCommittees.length} Committee Members', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
                        const SizedBox(height: 12),
                        
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: paginatedMembers.length,
                          itemBuilder: (context, index) {
                            final data = paginatedMembers[index].data() as Map<String, dynamic>;
                            final docId = paginatedMembers[index].id;
                            final name = data['name'] ?? 'Unknown Member';
                            final position = data['position'] ?? 'Committee';
                            final uid = data['uid'] ?? 'No UID';
                            
                            // 🌟 GET THE DYNAMIC COLOR BASED ON THE POSITION
                            final Color positionColor = _getPositionColor(position);
                            
                            return HoverCard(
                              child: Card(
                                elevation: 0, color: Colors.white, margin: const EdgeInsets.only(bottom: 1), 
                                shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(8)),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(8),
                                  onTap: () => _showCommitteeDetails(context, data, docId, positionColor),
                                  child: ListTile(
                                    contentPadding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 20, vertical: 12),
                                    leading: CircleAvatar(backgroundColor: positionColor, child: const Icon(Icons.admin_panel_settings, color: Colors.white)),
                                    title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    // 🌟 REPLACED DEPARTMENT WITH UID
                                    subtitle: Text('UID: $uid', style: TextStyle(fontSize: isMobile ? 12 : 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    trailing: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: positionColor.withOpacity(0.1), 
                                        borderRadius: BorderRadius.circular(12), 
                                        border: Border.all(color: positionColor.withOpacity(0.5))
                                      ),
                                      child: Text(position, style: TextStyle(color: positionColor, fontWeight: FontWeight.bold, fontSize: 12)),
                                    ),
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