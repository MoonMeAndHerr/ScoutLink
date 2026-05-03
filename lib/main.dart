import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

// IMPORTANT: Make sure these match your actual file paths!
import 'screens/committee_dashboard.dart';
import 'screens/participant_dashboard.dart'; // Uncomment when created
import 'screens/superadmin_dashboard.dart';
import 'firebase_options.dart'; 
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ScoutLinkApp());
}

// ============================================================================
// APP ENTRY POINT & GLOBAL PREMIUM THEME
// ============================================================================
class ScoutLinkApp extends StatelessWidget {
  const ScoutLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '${AppConstants.appName} | ${AppConstants.tagline}',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // 1. Global Typography: Poppins makes dashboards look incredibly clean
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
        
        // 2. Global Colors
        primaryColor: const Color(0xFF303030),
        scaffoldBackgroundColor: const Color(0xFFF8F9FA), // Soft off-white for web
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF303030),
          primary: const Color(0xFF303030),
        ),
        
        // 4. Global Button Theme: Soft rounded edges, bold text
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: const Color(0xFF303030),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),

        // 5. Global Input Theme: Makes all text fields look premium instantly
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF303030), width: 2),
          ),
          labelStyle: TextStyle(color: Colors.grey.shade600),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}

// ============================================================================
// ANIMATED LOGIN SCREEN
// ============================================================================
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _uidController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  
  bool _isLoading = false;
  String _errorMessage = '';

  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final uid = _uidController.text.trim();
    final pass = _passController.text.trim();

    if (uid.isEmpty || pass.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter both UID and Password.';
        _isLoading = false;
      });
      return;
    }

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('uid', isEqualTo: uid)
          .where('password', isEqualTo: pass)
          .get();

      if (querySnapshot.docs.isEmpty) {
        setState(() => _errorMessage = 'Invalid UID or Password.');
      } else {
        final userData = querySnapshot.docs.first.data();
        final userType = userData['userType'] ?? 'Unknown';

        if (!mounted) return;

        // Route to the correct dashboard
        if (userType == 'SuperAdmin' || userType == 'Superadmin') {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const SuperadminDashboard()));
        } else if (userType == 'Committee') {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const CommitteeDashboard()));
        } else if (userType == 'Participant') {
          // --- UNCOMMENTED AND UPDATED ---
          Navigator.pushReplacement(
            context, 
            MaterialPageRoute(builder: (context) => ParticipantDashboard(
              userUid: userData['uid'] ?? 'Unknown',
              userName: userData['name'] ?? 'Scout',
            ))
          );
        } else {
          setState(() => _errorMessage = 'Error: Unknown user role.');
        }
      }
    } catch (e) {
      setState(() => _errorMessage = 'Database error. Please check your connection.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            // Forces the login box to stay a nice size on massive desktop monitors
            constraints: const BoxConstraints(maxWidth: 450),
            padding: const EdgeInsets.all(24.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(40.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // --- NEW CUSTOM LOGO AREA ---
                    Image.asset(
                      'assets/logo.png',
                      height: 160, // Nice and big for the login page
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 16),
                    const Text('ScoutLink', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF303030))),
                    Text('Welcome back. Please log in.', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
                    const SizedBox(height: 40),

                    // --- ERROR MESSAGE ---
                    if (_errorMessage.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.shade200)),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_errorMessage, style: TextStyle(color: Colors.red.shade700, fontSize: 14))),
                          ],
                        ),
                      ),

                    // --- INPUT FIELDS ---
                    TextField(
                      controller: _uidController,
                      decoration: const InputDecoration(
                        labelText: 'User ID (UID)',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _passController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      onSubmitted: (_) => _handleLogin(), // Allows hitting Enter to login!
                    ),
                    const SizedBox(height: 32),

                    // --- LOGIN BUTTON ---
                    SizedBox(
                      width: double.infinity,
                      height: 56, // Taller button for a modern web feel
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        child: _isLoading
                            ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Access Dashboard', style: TextStyle(fontSize: 18)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          // --- THE MAGIC ANIMATION ---
          .animate()
          .fade(duration: 600.ms, curve: Curves.easeOut)
          .slideY(begin: 0.1, end: 0, duration: 600.ms, curve: Curves.easeOutQuart),
        ),
      ),
    );
  }
}