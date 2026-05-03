import 'package:flutter/material.dart';
import '../main.dart'; 
import '../utils/constants.dart';

import 'committee_dashboard.dart'; // We import this to reuse the OverallDataView!
import 'scanner_view.dart';
import 'participants_view.dart';
import 'activities_view.dart';
import 'committees_view.dart';
import 'attendance_screen.dart';

class SuperadminDashboard extends StatefulWidget {
  const SuperadminDashboard({super.key});

  @override
  State<SuperadminDashboard> createState() => _SuperadminDashboardState();
}

class _SuperadminDashboardState extends State<SuperadminDashboard> {
  int _selectedIndex = 0;
  bool _isExpanded = false; // Minimized by default!

  @override
  Widget build(BuildContext context) {
    // 1. ADDED ATTENDANCE SCREEN TO THE PAGES LIST
    final List<Widget> pages = [
      const OverallDataView(), 
      const AttendanceScreen(isAdmin: true), // Index 1: New Attendance Page
      const ScannerView(isAdmin: true),      // Index 2: Shifted down
      const ParticipantsView(),              // Index 3: Shifted down
      const ActivitiesView(),                // Index 4: Shifted down
      const CommitteesView(),                // Index 5: Shifted down
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Row(
        children: [
          // --- ANIMATED SIDEBAR MENU ---
          AnimatedContainer(
            duration: const Duration(milliseconds: 250), 
            width: _isExpanded ? 250 : 80, 
            color: const Color(0xFF1A1A2E), 
            child: Column(
              children: [
                const SizedBox(height: 20),
                
                // Toggle Button
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
                  Text(AppConstants.tagline, style: const TextStyle(color: Colors.amber, fontSize: 12)),
                ],
                const SizedBox(height: 20),
                
                // --- THE MENU ITEMS ---
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      _buildMenuItem(Icons.dashboard, 'Overall Data', 0),
                      _buildMenuItem(Icons.how_to_reg, 'Attendance', 1), // <-- ADDED MENU ITEM
                      _buildMenuItem(Icons.wifi_tethering, 'Scanner', 2), // Shifted index
                      _buildMenuItem(Icons.people, 'Participants Details', 3), // Shifted index
                      _buildMenuItem(Icons.event, 'Activity Details', 4), // Shifted index
                      _buildMenuItem(Icons.admin_panel_settings, 'Committee Details', 5), // Shifted index
                    ],
                  ),
                ),
                
                // --- LOGOUT BUTTON ---
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
              Icon(icon, color: isSelected ? Colors.amber : const Color(0xFFB0B0B0)), 
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