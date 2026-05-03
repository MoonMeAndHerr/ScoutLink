import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import '../utils/constants.dart'; 

import '../main.dart'; 
import 'scanner_view.dart';
import 'participants_view.dart';
import 'activities_view.dart';
import 'attendance_screen.dart';

// ============================================================================
// MAIN DASHBOARD LAYOUT & SIDEBAR NAVIGATION
// ============================================================================
class CommitteeDashboard extends StatefulWidget {
  const CommitteeDashboard({super.key});

  @override
  State<CommitteeDashboard> createState() => _CommitteeDashboardState();
}

class _CommitteeDashboardState extends State<CommitteeDashboard> {
  int _selectedIndex = 0;
  bool _isExpanded = false; 

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      const OverallDataView(), 
      const AttendanceScreen(), 
      const ScannerView(),      
      const ParticipantsView(), 
      const ActivitiesView(),   
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Row(
        children: [
          // --- ANIMATED SIDEBAR MENU ---
          AnimatedContainer(
            duration: const Duration(milliseconds: 250), 
            width: _isExpanded ? 250 : 80, 
            color: const Color(0xFF303030),
            child: Column(
              children: [
                const SizedBox(height: 20),
                
                // --- Toggle Button ---
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: _isExpanded ? 16.0 : 0),
                  child: Align(
                    alignment: _isExpanded ? Alignment.centerRight : Alignment.center,
                    child: IconButton(
                      icon: Icon(_isExpanded ? Icons.menu_open : Icons.menu, color: Colors.white),
                      onPressed: () => setState(() => _isExpanded = !_isExpanded),
                      tooltip: _isExpanded ? 'Collapse Menu' : 'Expand Menu',
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // --- CUSTOM LOGO ---
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  height: _isExpanded ? 120 : 50, 
                  child: Image.asset(
                    'assets/logo.png',
                    fit: BoxFit.contain,
                  ),
                ),

                if (_isExpanded) ...[
                  const SizedBox(height: 10),
                  Text(AppConstants.appName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.white)),
                  const Text(AppConstants.tagline, style: TextStyle(color: Colors.blue, fontSize: 12)),
                ],
                const SizedBox(height: 20),
                
                // --- Navigation Links ---
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      _buildMenuItem(Icons.dashboard, 'Overall Data', 0),
                      _buildMenuItem(Icons.how_to_reg, 'Attendance', 1), 
                      _buildMenuItem(Icons.wifi_tethering, 'Scanner', 2), 
                      _buildMenuItem(Icons.people, 'Participants Details', 3), 
                      _buildMenuItem(Icons.event, 'Activity Details', 4), 
                    ],
                  ),
                ),
                
                // --- Logout Button ---
                Tooltip(
                  message: _isExpanded ? '' : 'Logout',
                  preferBelow: false,
                  child: InkWell(
                    onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen())),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Row(
                        mainAxisAlignment: _isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
                        children: [
                          if (_isExpanded) const SizedBox(width: 20),
                          const Icon(Icons.logout, color: Colors.redAccent),
                          if (_isExpanded) ...[
                            const SizedBox(width: 16),
                            const Text('Logout', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                          ]
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // --- MAIN CONTENT AREA ---
          Expanded(child: pages[_selectedIndex]),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, int index) {
    final isSelected = _selectedIndex == index;
    
    return Tooltip(
      message: _isExpanded ? '' : title, 
      preferBelow: false,
      child: InkWell(
        onTap: () => setState(() => _selectedIndex = index),
        child: Container(
          color: isSelected ? const Color(0xFF4A4A4A) : Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: _isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
            children: [
              if (_isExpanded) const SizedBox(width: 20),
              Icon(icon, color: isSelected ? Colors.blue : const Color(0xFFB0B0B0)), 
              if (_isExpanded) ...[
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xFFB0B0B0),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis, 
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// OVERALL DATA VIEW (Mobile Responsive Pie Chart & Live Leaderboard)
// ============================================================================
class OverallDataView extends StatelessWidget {
  const OverallDataView({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0), 
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Overall Data Dashboard',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF303030)),
          ),
          const SizedBox(height: 16),
          
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('activity_tracker').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF303030)));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No activities logged yet.'));
                }

                final docs = snapshot.data!.docs;

                Map<String, int> activityCounts = {};
                Map<String, Map<String, dynamic>> userStats = {};

                for (var doc in docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  
                  String actUid = data['activityUID'] ?? 'Unknown Activity'; 
                  activityCounts[actUid] = (activityCounts[actUid] ?? 0) + 1;

                  String userUid = data['usersUID'] ?? 'Unknown';
                  String userName = data['name'] ?? 'Unknown Participant';

                  if (!userStats.containsKey(userUid)) {
                    userStats[userUid] = {'uid': userUid, 'name': userName, 'count': 0};
                  }
                  userStats[userUid]!['count'] = (userStats[userUid]!['count'] as int) + 1;
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    bool isMobile = constraints.maxWidth < 700;

                    List<Color> colors = [Colors.blue, Colors.red, Colors.green, Colors.orange, Colors.purple, Colors.teal, Colors.indigo];
                    List<PieChartSectionData> pieSections = [];
                    List<Widget> legendItems = [];
                    
                    int colorIndex = 0;
                    activityCounts.forEach((actUid, count) {
                      final color = colors[colorIndex % colors.length];
                      colorIndex++;
                      pieSections.add(
                        PieChartSectionData(color: color, value: count.toDouble(), title: '$count', radius: isMobile ? 50 : 80, titleStyle: TextStyle(fontSize: isMobile ? 14 : 16, fontWeight: FontWeight.bold, color: Colors.white))
                      );
                      legendItems.add(
                        Row(mainAxisSize: MainAxisSize.min, children: [Container(width: 16, height: 16, decoration: BoxDecoration(color: color, shape: BoxShape.circle)), const SizedBox(width: 8), Text(actUid, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))])
                      );
                    });

                    Widget pieChartPanel = Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[300]!)),
                      child: Column(
                        children: [
                          const Text('Attendance by Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: isMobile ? 180 : 250,
                            child: PieChart(PieChartData(sectionsSpace: 2, centerSpaceRadius: isMobile ? 30 : 40, sections: pieSections)),
                          ),
                          const SizedBox(height: 24),
                          Wrap(spacing: 16, runSpacing: 12, alignment: WrapAlignment.center, children: legendItems),
                        ],
                      ),
                    );

                    Widget leaderboardPanel = Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[300]!)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Live Participant Leaderboard', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          const Text('Ranked by total activities completed.'),
                          const Divider(height: 24),
                          
                          // 🚨 THE FIX: If on a computer, wrap the list in Expanded so it scrolls INSIDE the box!
                          if (isMobile) 
                            _buildLeaderboard(userStats.values.toList(), isMobile: true)
                          else 
                            Expanded(child: _buildLeaderboard(userStats.values.toList(), isMobile: false))
                        ],
                      ),
                    );

                    if (isMobile) {
                      return ListView(children: [pieChartPanel, const SizedBox(height: 20), leaderboardPanel]);
                    } else {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 1, child: pieChartPanel),
                          const SizedBox(width: 24),
                          Expanded(flex: 1, child: leaderboardPanel),
                        ],
                      );
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 🌟 THE FIX: Modified to accept the 'isMobile' flag and adjust scroll physics automatically!
  Widget _buildLeaderboard(List<Map<String, dynamic>> users, {required bool isMobile}) {
    users.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

    return ListView.builder(
      // Shrinkwrap prevents crashing on mobile, but is turned off on desktop to allow the Expanded scroll!
      shrinkWrap: isMobile, 
      physics: isMobile ? const NeverScrollableScrollPhysics() : const BouncingScrollPhysics(),
      itemCount: users.length > 50 ? 50 : users.length, 
      itemBuilder: (context, index) {
        var user = users[index];
        int rank = index + 1;
        int count = user['count'];

        Color avatarColor = Colors.grey.shade200;
        Color textColor = Colors.black87;

        if (rank == 1) { avatarColor = Colors.amber; textColor = Colors.white; }
        else if (rank == 2) { avatarColor = Colors.grey.shade400; textColor = Colors.white; }
        else if (rank == 3) { avatarColor = Colors.brown.shade400; textColor = Colors.white; }

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 8),
          color: rank <= 3 ? avatarColor.withOpacity(0.1) : Colors.grey.shade50,
          shape: RoundedRectangleBorder(side: BorderSide(color: rank <= 3 ? avatarColor : Colors.grey.shade300, width: rank <= 3 ? 2 : 1), borderRadius: BorderRadius.circular(8)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: avatarColor,
              child: Text('#$rank', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
            ),
            title: Text(user['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('UID: ${user['uid']}'),
            trailing: Text('$count', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          ),
        );
      },
    );
  }
}