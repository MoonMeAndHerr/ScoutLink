import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../widgets/hover_card.dart';

// ============================================================================
// ACTIVITIES VIEW (Ultra-Optimized + Pagination + Cached Streams)
// ============================================================================
class ActivitiesView extends StatefulWidget {
  final bool isAdmin;
  const ActivitiesView({super.key, this.isAdmin = false});

  @override
  State<ActivitiesView> createState() => _ActivitiesViewState();
}

class _ActivitiesViewState extends State<ActivitiesView> {
  // 🌟 PAGINATION & SEARCH STATE
  String _searchQuery = '';
  int _currentPage = 0;
  final int _itemsPerPage = 5; // Keeps UI blazing fast!

  // 🌟 CACHED STREAM (The ultimate quota saver)
  late Stream<QuerySnapshot> _activitiesStream;

  @override
  void initState() {
    super.initState();
    // Fetch the activities ONCE when the page loads.
    _activitiesStream = FirebaseFirestore.instance.collection('activities').snapshots();
  }

  // --- DELETE LOGIC ---
  Future<void> _deleteActivity(String docId, String name) async {
    final bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Activity', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to permanently delete $name? This will NOT delete past attendance logs, but it removes the activity from the catalog.'),
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
      await FirebaseFirestore.instance.collection('activities').doc(docId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$name deleted successfully.'), backgroundColor: Colors.orange));
      }
    }
  }

  // --- DIALOG HELPER WIDGETS ---
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
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

  // --- ACTIVITY DETAILS POP-UP (With the layout fix!) ---
  void _showActivityDetails(BuildContext context, Map<String, dynamic> data, String docId) {
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
                const CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.event, color: Colors.white)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data['name']?.toString().isEmpty == false ? data['name'] : 'Unnamed Activity', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                      Text(data['uid']?.toString().isEmpty == false ? data['uid'] : 'No Code', style: const TextStyle(color: Colors.grey, fontSize: 14)),
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
                  _buildSectionTitle('Activity Details'),
                  _detailRow('Activity Code', data['uid']),
                  _detailRow('Category', data['activityType']),
                  _detailRow('Venue/Building', data['venueCategory']),
                  
                  // You can easily add more fields here if your database has them!
                  // _detailRow('Capacity', data['capacity']),
                  // _detailRow('Instructor', data['instructor']),
                ],
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          // 🌟 The layout fix: Splits buttons left and right!
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            // LEFT SIDE
            if (widget.isAdmin)
              TextButton.icon(
                icon: const Icon(Icons.delete, color: Colors.red), 
                label: const Text('Delete', style: TextStyle(color: Colors.red)),
                onPressed: () {
                  Navigator.pop(context);
                  _deleteActivity(docId, data['name'] ?? 'Activity');
                },
              )
            else 
              const SizedBox.shrink(),
              
            // RIGHT SIDE
            if (widget.isAdmin)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                icon: const Icon(Icons.edit, size: 18), 
                label: const Text('Edit Details'),
                onPressed: () {
                  Navigator.pop(context);
                  // Add your navigation to an Edit Form here if needed
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Activity Catalog', style: TextStyle(fontSize: isMobile ? 24 : 28, fontWeight: FontWeight.bold, color: const Color(0xFF303030))),
                    if (widget.isAdmin)
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Activity'),
                        onPressed: () {
                          // Add your navigation to an Add Activity Form here!
                        },
                      )
                  ],
                ),
                SizedBox(height: isMobile ? 16 : 24),
                
                // 🌟 SEARCH BAR (Locally filters the cached stream!)
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Search by Activity Name, Code, or Venue',
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
                  stream: _activitiesStream, 
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: Color(0xFF303030))));
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No activities created yet.', style: TextStyle(color: Colors.grey[500]))));

                    var allActivities = snapshot.data!.docs;

                    // LOCAL SEARCH (0 Extra Quota Reads!)
                    if (_searchQuery.isNotEmpty) {
                      allActivities = allActivities.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final name = (data['name'] ?? '').toString().toLowerCase();
                        final uid = (data['uid'] ?? '').toString().toLowerCase();
                        final venue = (data['venueCategory'] ?? '').toString().toLowerCase();
                        final type = (data['activityType'] ?? '').toString().toLowerCase();
                        return name.contains(_searchQuery) || uid.contains(_searchQuery) || venue.contains(_searchQuery) || type.contains(_searchQuery);
                      }).toList();
                    }

                    if (allActivities.isEmpty) return Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No activities match your search.', style: TextStyle(color: Colors.grey[500]))));

                    // 🌟 PAGINATION SLICING
                    int totalPages = (allActivities.length / _itemsPerPage).ceil();
                    if (_currentPage >= totalPages && totalPages > 0) {
                      _currentPage = totalPages - 1; 
                    }
                    var paginatedActivities = allActivities.skip(_currentPage * _itemsPerPage).take(_itemsPerPage).toList();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Showing ${allActivities.length} Activities', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
                        const SizedBox(height: 12),
                        
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: paginatedActivities.length,
                          itemBuilder: (context, index) {
                            final data = paginatedActivities[index].data() as Map<String, dynamic>;
                            final docId = paginatedActivities[index].id;
                            final name = data['name'] ?? 'Unknown Activity';
                            final uid = data['uid'] ?? 'No Code';
                            final venue = data['venueCategory'] ?? 'Unknown Venue';
                            final type = data['activityType'] ?? 'Unknown Type';
                            
                            return HoverCard(
                              child: Card(
                                elevation: 0, color: Colors.white, margin: const EdgeInsets.only(bottom: 1), 
                                shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(8)),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(8),
                                  onTap: () => _showActivityDetails(context, data, docId),
                                  child: ListTile(
                                    contentPadding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 20, vertical: 12),
                                    leading: const CircleAvatar(backgroundColor: Color(0xFF303030), child: Icon(Icons.event, color: Colors.white)),
                                    title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    subtitle: Text('Code: $uid  |  Venue: $venue', style: TextStyle(fontSize: isMobile ? 12 : 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    trailing: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blue.shade200)),
                                      child: Text(type, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12)),
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