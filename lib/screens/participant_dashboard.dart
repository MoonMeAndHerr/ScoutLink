import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../main.dart'; 
import '../widgets/hover_card.dart';
import '../utils/constants.dart';

// ============================================================================
// PARTICIPANT DASHBOARD & NAVIGATION
// ============================================================================
class ParticipantDashboard extends StatefulWidget {
  final String userUid;
  final String userName;

  const ParticipantDashboard({super.key, required this.userUid, required this.userName});

  @override
  State<ParticipantDashboard> createState() => _ParticipantDashboardState();
}

class _ParticipantDashboardState extends State<ParticipantDashboard> {
  int _selectedIndex = 0;
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    bool isMobileScreen = MediaQuery.of(context).size.width < 700;
    
    final List<Widget> pages = [
      _MyProgressView(userUid: widget.userUid, userName: widget.userName),
      _MyHistoryView(userUid: widget.userUid),
      const _EventDirectoryView(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8), 
      body: Row(
        children: [
          // --- ANIMATED SIDEBAR MENU ---
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            // On mobile, if collapsed, make it very thin to save space
            width: _isExpanded ? (isMobileScreen ? 200 : 250) : (isMobileScreen ? 60 : 80),
            color: const Color(0xFF1E293B), 
            child: Column(
              children: [
                const SizedBox(height: 20),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: _isExpanded ? 16.0 : 0),
                  child: Align(
                    alignment: _isExpanded ? Alignment.centerRight : Alignment.center,
                    child: IconButton(
                      icon: Icon(_isExpanded ? Icons.menu_open : Icons.menu, color: Colors.white),
                      onPressed: () => setState(() => _isExpanded = !_isExpanded),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  height: _isExpanded ? 80 : 30,
                  child: Image.asset('assets/logo.png', fit: BoxFit.contain),
                ),

                if (_isExpanded) ...[
                  const SizedBox(height: 16),
                  Text(AppConstants.appName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobileScreen ? 18 : 22, color: Colors.white)),
                  Text(AppConstants.tagline, style: const TextStyle(color: Colors.tealAccent, fontSize: 10)),
                ],
                const SizedBox(height: 32),

                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      _buildMenuItem(Icons.dashboard, 'My Dashboard', 0, isMobileScreen),
                      _buildMenuItem(Icons.history_edu, 'My Passport', 1, isMobileScreen),
                      _buildMenuItem(Icons.explore, 'Event Directory', 2, isMobileScreen),
                    ],
                  ),
                ),

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
          Expanded(child: pages[_selectedIndex]),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, int index, bool isMobileScreen) {
    final isSelected = _selectedIndex == index;
    return Tooltip(
      message: _isExpanded ? '' : title,
      preferBelow: false,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedIndex = index;
            if (isMobileScreen) _isExpanded = false; // Auto-close menu on mobile after clicking
          });
        },
        child: Container(
          color: isSelected ? Colors.teal.withOpacity(0.2) : Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: _isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
            children: [
              if (_isExpanded) const SizedBox(width: 20),
              Icon(icon, color: isSelected ? Colors.tealAccent : Colors.grey.shade400),
              if (_isExpanded) ...[
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(color: isSelected ? Colors.white : Colors.grey.shade400, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
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
// 1. MY PROGRESS VIEW (Mobile Optimized)
// ============================================================================
class _MyProgressView extends StatelessWidget {
  final String userUid;
  final String userName;

  const _MyProgressView({required this.userUid, required this.userName});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Breakpoints for responsive design
        bool isMobile = constraints.maxWidth < 900; 
        bool isVerySmallPhone = constraints.maxWidth < 400;

        return SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16.0 : 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 🌟 THE WELCOME BANNER 🌟 ---
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(isMobile ? 24 : 32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.teal.shade800, Colors.teal.shade400], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.teal.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
                  image: DecorationImage(image: const AssetImage('assets/logo.png'), fit: BoxFit.contain, alignment: Alignment.centerRight, colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.05), BlendMode.dstIn))
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.rocket_launch, color: Colors.white, size: 14), 
                        const SizedBox(width: 8), 
                        Text('STARK 2026: MAY 2ND', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: isMobile ? 10 : 12, letterSpacing: 1.5))
                      ]),
                    ),
                    const SizedBox(height: 16),
                    Text('Welcome back,\n$userName!', style: TextStyle(fontSize: isMobile ? 24 : 32, fontWeight: FontWeight.bold, color: Colors.white, height: 1.2)),
                    const SizedBox(height: 8),
                    Text(AppConstants.tagline, style: TextStyle(fontSize: isMobile ? 14 : 16, color: Colors.teal.shade100, fontWeight: FontWeight.w600, fontStyle: FontStyle.italic)),
                  ],
                ),
              ).animate().fade(duration: 600.ms).slideY(begin: 0.1, end: 0),
              
              const SizedBox(height: 24),

              // --- 🌟 THEMATIC STATUS INDICATORS 🌟 ---
              isMobile 
              ? Column(
                  children: [
                    Row(children: [Expanded(child: _buildStatusCard(Icons.wb_sunny, 'Climate', '32°C Clear', Colors.orange, isVerySmallPhone)), const SizedBox(width: 12), Expanded(child: _buildStatusCard(Icons.satellite_alt, 'Network', 'Connected', Colors.blue, isVerySmallPhone))]),
                    const SizedBox(height: 12),
                    Row(children: [Expanded(child: _buildStatusCard(Icons.flag, 'Phase', 'Exploration', Colors.green, isVerySmallPhone)), const SizedBox(width: 12), Expanded(child: _buildStatusCard(Icons.memory, 'System', 'Optimal', Colors.purple, isVerySmallPhone))]),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: _buildStatusCard(Icons.wb_sunny, 'Expedition Climate', '32°C Clear', Colors.orange, false)), const SizedBox(width: 16),
                    Expanded(child: _buildStatusCard(Icons.satellite_alt, 'RFID Network', 'Connected', Colors.blue, false)), const SizedBox(width: 16),
                    Expanded(child: _buildStatusCard(Icons.flag, 'Event Phase', 'Exploration', Colors.green, false)), const SizedBox(width: 16),
                    Expanded(child: _buildStatusCard(Icons.memory, 'System Status', 'Optimal', Colors.purple, false)),
                  ],
                ).animate().fade(delay: 200.ms).slideY(begin: 0.1, end: 0),

              const SizedBox(height: 24),

              // --- 🌟 MAIN DASHBOARD WIDGETS 🌟 ---
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('activity_tracker').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator()));
                  
                  Map<String, Map<String, dynamic>> userStats = {};
                  if (snapshot.hasData) {
                    for (var doc in snapshot.data!.docs) {
                      final data = doc.data() as Map<String, dynamic>;
                      String uId = data['usersUID'] ?? 'Unknown';
                      String uName = data['name'] ?? 'Unknown Participant';
                      if (!userStats.containsKey(uId)) { userStats[uId] = {'uid': uId, 'name': uName, 'count': 0}; }
                      userStats[uId]!['count'] = (userStats[uId]!['count'] as int) + 1;
                    }
                  }

                  var rankedList = userStats.values.toList()..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
                  int myCount = userStats[userUid]?['count'] ?? 0;
                  int myRank = myCount == 0 ? 0 : rankedList.indexWhere((u) => u['uid'] == userUid) + 1;
                  int totalActiveUsers = rankedList.length;

                  String percentileText = "Unranked";
                  if (myRank > 0 && totalActiveUsers > 1) {
                    double percentile = ((totalActiveUsers - myRank) / (totalActiveUsers - 1)) * 100;
                    if (percentile >= 90) percentileText = "Top 10%";
                    else if (percentile >= 75) percentileText = "Top 25%";
                    else if (percentile >= 50) percentileText = "Top 50%";
                    else percentileText = "Bottom 50%";
                  } else if (myRank == 1 && totalActiveUsers == 1) {
                    percentileText = "Top 1%"; 
                  }

                  return Flex(
                    direction: isMobile ? Axis.vertical : Axis.horizontal,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- LEFT COLUMN ---
                      Expanded(
                        flex: isMobile ? 0 : 5,
                        child: Column(
                          children: [
                            // 1. Mission Progress Card
                            StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance.collection('activities').snapshots(),
                              builder: (context, actSnapshot) {
                                int totalActivities = actSnapshot.hasData ? actSnapshot.data!.docs.length : 0;
                                int safeTotal = totalActivities > 0 ? totalActivities : 1; 
                                double progressRatio = (myCount / safeTotal).clamp(0.0, 1.0);

                                return Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.all(isMobile ? 20 : 32),
                                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Text('Mission Progress', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                                                const SizedBox(height: 8),
                                                Row(
                                                  crossAxisAlignment: CrossAxisAlignment.end,
                                                  children: [
                                                    // Shrunk the font size to prevent overflow!
                                                    Text('$myCount', style: TextStyle(fontSize: isMobile ? 40 : 56, fontWeight: FontWeight.bold, height: 1.0, color: const Color(0xFF303030))),
                                                    Padding(
                                                      padding: const EdgeInsets.only(bottom: 4.0, left: 4.0),
                                                      child: Text('/ $totalActivities', style: TextStyle(fontSize: isMobile ? 18 : 24, fontWeight: FontWeight.bold, color: Colors.grey)),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Text('Activities Completed', style: TextStyle(fontSize: isMobile ? 12 : 14, fontWeight: FontWeight.w600, color: Colors.grey)),
                                              ],
                                            ),
                                          ),
                                          Column(
                                            children: [
                                              CircleAvatar(radius: isMobile ? 28 : 36, backgroundColor: Colors.amber.withOpacity(0.15), child: Text(myRank == 0 ? '-' : '#$myRank', style: TextStyle(color: Colors.amber, fontSize: isMobile ? 20 : 24, fontWeight: FontWeight.bold))),
                                              const SizedBox(height: 8),
                                              Text('Rank', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber, fontSize: isMobile ? 14 : 16)),
                                            ],
                                          )
                                        ],
                                      ),
                                      const SizedBox(height: 24),

                                      // The Total Progress Bar
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('${(progressRatio * 100).toInt()}% Done', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF303030))),
                                          Text('${totalActivities - myCount} left', style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: LinearProgressIndicator(value: progressRatio, minHeight: 12, backgroundColor: Colors.grey.shade200, color: Colors.teal),
                                      ),
                                      const SizedBox(height: 24),
                                      
                                      // Percentile Badge
                                      Container(
                                        width: double.infinity, padding: EdgeInsets.all(isMobile ? 12 : 16),
                                        decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.teal.shade200)),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.insights, color: Colors.teal.shade700, size: isMobile ? 18 : 24), const SizedBox(width: 8),
                                            Flexible(child: Text('You are in the $percentileText!', style: TextStyle(color: Colors.teal.shade900, fontWeight: FontWeight.bold, fontSize: isMobile ? 12 : 14))),
                                          ],
                                        ),
                                      )
                                    ],
                                  ),
                                ).animate().fade(delay: 300.ms).slideY(begin: 0.1, end: 0);
                              }
                            ),

                            const SizedBox(height: 24),

                            // 2. LIVE LEADERBOARD
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(isMobile ? 20 : 24),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Global Leaderboard', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF303030))),
                                  const Text('Top 10 most active explorers!', style: TextStyle(color: Colors.grey, fontSize: 13)),
                                  const SizedBox(height: 16),
                                  
                                  rankedList.isEmpty 
                                    ? const Text('No activities logged by anyone yet.') 
                                    : ListView.builder(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        itemCount: rankedList.length > 10 ? 10 : rankedList.length,
                                        itemBuilder: (context, index) {
                                          var user = rankedList[index];
                                          int rank = index + 1;
                                          bool isMe = user['uid'] == userUid;

                                          Color avatarColor = Colors.grey.shade200;
                                          Color textColor = Colors.black87;

                                          if (rank == 1) { avatarColor = Colors.amber; textColor = Colors.white; }
                                          else if (rank == 2) { avatarColor = Colors.grey.shade400; textColor = Colors.white; }
                                          else if (rank == 3) { avatarColor = Colors.brown.shade400; textColor = Colors.white; }

                                          return Card(
                                            elevation: 0,
                                            margin: const EdgeInsets.only(bottom: 8),
                                            color: isMe ? Colors.teal.shade50 : (rank <= 3 ? avatarColor.withOpacity(0.1) : Colors.white),
                                            shape: RoundedRectangleBorder(
                                              side: BorderSide(color: isMe ? Colors.teal : (rank <= 3 ? avatarColor : Colors.grey.shade200), width: isMe || rank <= 3 ? 2 : 1), 
                                              borderRadius: BorderRadius.circular(8)
                                            ),
                                            child: ListTile(
                                              contentPadding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16),
                                              leading: CircleAvatar(radius: isMobile ? 16 : 20, backgroundColor: avatarColor, child: Text('#$rank', style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: isMobile ? 12 : 14))),
                                              title: Text(isMe ? 'You ($userName)' : user['name'], style: TextStyle(fontWeight: FontWeight.bold, color: isMe ? Colors.teal.shade800 : Colors.black87, fontSize: isMobile ? 14 : 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                                              trailing: Text('${user['count']}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 16 : 20)),
                                            ),
                                          );
                                        },
                                      )
                                ],
                              ),
                            ).animate().fade(delay: 400.ms).slideY(begin: 0.1, end: 0),
                          ],
                        ),
                      ),

                      SizedBox(width: isMobile ? 0 : 24, height: isMobile ? 24 : 0),

                      // --- RIGHT COLUMN ---
                      Expanded(
                        flex: isMobile ? 0 : 3,
                        child: Column(
                          children: [
                            // 1. STARK Boarding PASS (Overlap Fixed!)
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                    decoration: const BoxDecoration(color: Color(0xFF1E293B), borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('STARK ACCESS PASS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.0, fontSize: 14)),
                                        Icon(Icons.fingerprint, color: Colors.tealAccent, size: 20),
                                      ],
                                    ),
                                  ),
                                  // Wrapped in Stack to safely put the watermark behind everything without causing layout overlaps
                                  Stack(
                                    children: [
                                      Positioned(
                                        right: -20, top: 0, bottom: 0,
                                        child: Opacity(
                                          opacity: 0.05,
                                          child: Image.asset('assets/logo.png', width: 150, fit: BoxFit.contain),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(24.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('PARTICIPANT', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 2.0)),
                                            const SizedBox(height: 4),
                                            Text(userName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF303030)), maxLines: 1, overflow: TextOverflow.ellipsis),
                                            const SizedBox(height: 24),
                                            Row(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      const Text('UID CODE', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 2.0)),
                                                      const SizedBox(height: 4),
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                        decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(8)),
                                                        child: Text(userUid, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.teal.shade700), maxLines: 1, overflow: TextOverflow.ellipsis),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.end,
                                                  children: [
                                                    const Text('YEAR', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 2.0)),
                                                    const SizedBox(height: 4),
                                                    Text('2026', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(children: List.generate(20, (index) => Expanded(child: Container(color: index % 2 == 0 ? Colors.transparent : Colors.grey.shade300, height: 2)))),
                                  Padding(
                                    padding: const EdgeInsets.all(20.0),
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: List.generate(
                                            25, 
                                            (index) => Container(
                                              margin: const EdgeInsets.symmetric(horizontal: 1.5),
                                              width: index % 3 == 0 ? 3 : (index % 5 == 0 ? 4 : 1.5),
                                              height: 35,
                                              color: const Color(0xFF1E293B),
                                            )
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Text('Tap physical RFID at booths', style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ).animate().fade(delay: 500.ms).slideY(begin: 0.1, end: 0),

                            const SizedBox(height: 24),

                            // 2. Basecamp Briefing
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(isMobile ? 20 : 24),
                              decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.indigo.shade100)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.campaign, color: Colors.indigo.shade400, size: 20),
                                      const SizedBox(width: 8),
                                      Text('Basecamp Briefing', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo.shade900)),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  _buildAnnouncement('Welcome to STARK 2026!', 'Make sure to grab your physical kit at the main registration desk before exploring.'),
                                  const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider()),
                                  _buildAnnouncement('STEM Run Alert', 'The Scout STEM Run will begin promptly as scheduled. Check the directory.'),
                                ],
                              ),
                            ).animate().fade(delay: 600.ms).slideY(begin: 0.1, end: 0),
                          ],
                        ),
                      ),
                    ],
                  );
                }
              ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildStatusCard(IconData icon, String title, String value, Color color, bool isVerySmallPhone) {
    return Container(
      width: double.infinity, 
      padding: EdgeInsets.symmetric(vertical: isVerySmallPhone ? 12 : 16, horizontal: isVerySmallPhone ? 12 : 16), 
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: color.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: isVerySmallPhone ? 16 : 18),
              const SizedBox(width: 6),
              Expanded(child: Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: isVerySmallPhone ? 10 : 11, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: isVerySmallPhone ? 14 : 16, color: Colors.grey.shade800), maxLines: 1, overflow: TextOverflow.ellipsis), 
        ],
      ),
    );
  }

  Widget _buildAnnouncement(String title, String body) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(padding: EdgeInsets.only(top: 2.0), child: Icon(Icons.arrow_right, color: Colors.indigo, size: 16)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo.shade900, fontSize: 13)),
              const SizedBox(height: 2),
              Text(body, style: TextStyle(color: Colors.indigo.shade500, fontSize: 12, height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// 2. MY HISTORY VIEW (Passport - Removed 'Verified' & Added Real Names!)
// ============================================================================
class _MyHistoryView extends StatelessWidget {
  final String userUid;
  const _MyHistoryView({required this.userUid});

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 700;

    return Padding(
      padding: EdgeInsets.all(isMobile ? 16.0 : 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('My Passport', style: TextStyle(fontSize: isMobile ? 24 : 28, fontWeight: FontWeight.bold, color: const Color(0xFF303030))),
          Text('A timeline of everywhere you have explored.', style: TextStyle(fontSize: isMobile ? 14 : 16, color: Colors.grey)),
          const SizedBox(height: 24),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('activity_tracker').where('usersUID', isEqualTo: userUid).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history_toggle_off, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text("You haven't scanned into any activities yet.\nGo explore the Event Directory!", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                    ],
                  ));
                }

                var history = snapshot.data!.docs;
                history.sort((a, b) {
                  Timestamp? tA = (a.data() as Map)['timestamp'] as Timestamp?;
                  Timestamp? tB = (b.data() as Map)['timestamp'] as Timestamp?;
                  if (tA == null) return 1; if (tB == null) return -1;
                  return tB.compareTo(tA); 
                });

                return ListView.builder(
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final data = history[index].data() as Map<String, dynamic>;
                    final activityUid = data['activityUID'] ?? 'Unknown Activity';
                    
                    String timeStr = 'Just now';
                    if (data['timestamp'] != null) {
                      DateTime dt = (data['timestamp'] as Timestamp).toDate();
                      timeStr = '${dt.day}/${dt.month}/${dt.year} at ${dt.hour > 12 ? dt.hour - 12 : dt.hour}:${dt.minute.toString().padLeft(2, '0')} ${dt.hour >= 12 ? 'PM' : 'AM'}';
                    }
                    
                    return HoverCard(
                      child: Card(
                        elevation: 0, color: Colors.white, margin: const EdgeInsets.only(bottom: 1),
                        shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 20, vertical: 12),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(isMobile ? 8 : 12),
                                decoration: BoxDecoration(color: Colors.teal.shade50, shape: BoxShape.circle),
                                child: Icon(Icons.verified, color: Colors.teal.shade600, size: isMobile ? 20 : 24),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // 🌟 NEW: FutureBuilder to fetch the actual Activity Name instead of just the code!
                                    FutureBuilder<QuerySnapshot>(
                                      future: FirebaseFirestore.instance.collection('activities').where('uid', isEqualTo: activityUid).limit(1).get(),
                                      builder: (context, actSnapshot) {
                                        String displayName = activityUid; // Fallback to code
                                        if (actSnapshot.hasData && actSnapshot.data!.docs.isNotEmpty) {
                                          displayName = actSnapshot.data!.docs.first['name'] ?? activityUid;
                                        }
                                        return Text(displayName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 14 : 16));
                                      }
                                    ),
                                    const SizedBox(height: 4),
                                    Text('Scanned: $timeStr', style: TextStyle(color: Colors.grey.shade500, fontSize: isMobile ? 12 : 14)),
                                    Text('Code: $activityUid', style: TextStyle(color: Colors.grey.shade400, fontSize: 10)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ).animate(delay: (index * 40).clamp(0, 500).ms).fade().slideX(begin: 0.05, end: 0);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 3. EVENT DIRECTORY VIEW (ListView on Mobile to prevent squishing)
// ============================================================================
class _EventDirectoryView extends StatelessWidget {
  const _EventDirectoryView();

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 700;

    return Padding(
      padding: EdgeInsets.all(isMobile ? 16.0 : 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Event Directory', style: TextStyle(fontSize: isMobile ? 24 : 28, fontWeight: FontWeight.bold, color: const Color(0xFF303030))),
          Text('Find your next adventure.', style: TextStyle(fontSize: isMobile ? 14 : 16, color: Colors.grey)),
          const SizedBox(height: 24),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('activities').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("No activities posted yet."));

                final activities = snapshot.data!.docs;
                
                // 🌟 Mobile Fix: Use a vertical ListView instead of a squished GridView on phones!
                if (isMobile) {
                  return ListView.builder(
                    itemCount: activities.length,
                    itemBuilder: (context, index) {
                      final data = activities[index].data() as Map<String, dynamic>;
                      return _buildDirectoryCard(data, isMobile, index);
                    },
                  );
                }

                // Desktop/Tablet view remains a nice grid
                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 400,
                    childAspectRatio: 2.5,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: activities.length,
                  itemBuilder: (context, index) {
                    final data = activities[index].data() as Map<String, dynamic>;
                    return _buildDirectoryCard(data, isMobile, index);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDirectoryCard(Map<String, dynamic> data, bool isMobile, int index) {
    final name = data['name'] ?? 'Unknown Activity';
    final type = data['activityType'] ?? 'General';
    final venue = data['venueCategory'] ?? 'TBA';

    return HoverCard(
      child: Card(
        elevation: 0, color: Colors.white,
        margin: EdgeInsets.only(bottom: isMobile ? 1 : 0), // Add margin only on list view
        shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(isMobile ? 12 : 16),
                decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.explore, color: Colors.indigo.shade400, size: isMobile ? 24 : 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 14 : 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4, // Added runSpacing so tags wrap nicely if they are too long
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(4)),
                          child: Text(type, style: TextStyle(fontSize: 10, color: Colors.blue.shade700, fontWeight: FontWeight.bold)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(4)),
                          child: Text(venue, style: TextStyle(fontSize: 10, color: Colors.orange.shade800, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate(delay: (index * 40).clamp(0, 500).ms).fade().slideY(begin: 0.1, end: 0);
  }
}