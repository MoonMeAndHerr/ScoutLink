import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ============================================================================
// COMMITTEE FORM SCREEN (Comprehensive Data Collection)
// ============================================================================
class CommitteeFormScreen extends StatefulWidget {
  final Map<String, dynamic>? existingData;
  final String? docId;

  const CommitteeFormScreen({super.key, this.existingData, this.docId});

  @override
  State<CommitteeFormScreen> createState() => _CommitteeFormScreenState();
}

class _CommitteeFormScreenState extends State<CommitteeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers for all our text fields
  final TextEditingController _uidController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _matricController = TextEditingController();
  final TextEditingController _icController = TextEditingController();
  final TextEditingController _courseController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  String? _selectedPosition;

  // The exhaustive list of committee positions
  final List<String> _positions = [
    'Mainboard', 
    'Preparation and Technical', 
    'Forum', 
    'Publication and Promotion', 
    'Special Task', 
    'Retail', 
    'Exhibition', 
    'Expedition', 
    'Registration', 
    'Sponsorship', 
    'Catering', 
    'Protocol'
  ];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill the form if we are updating an existing committee member
    if (widget.existingData != null) {
      _uidController.text = widget.existingData!['uid'] ?? '';
      _nameController.text = widget.existingData!['name'] ?? '';
      _matricController.text = widget.existingData!['matric'] ?? '';
      _icController.text = widget.existingData!['ic'] ?? '';
      _courseController.text = widget.existingData!['course'] ?? '';
      _passwordController.text = widget.existingData!['password'] ?? '';
      
      String? existingPos = widget.existingData!['position'];
      if (_positions.contains(existingPos)) {
        _selectedPosition = existingPos;
      }
    }
  }

  @override
  void dispose() {
    _uidController.dispose();
    _nameController.dispose();
    _matricController.dispose();
    _icController.dispose();
    _courseController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _saveCommittee() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a Position!'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final String uid = _uidController.text.trim();
      final firestore = FirebaseFirestore.instance;

      // Duplicate check for new entries
      if (widget.docId == null) {
        final duplicateCheck = await firestore.collection('users').where('uid', isEqualTo: uid).get();
        if (duplicateCheck.docs.isNotEmpty) {
          setState(() => _isLoading = false);
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('UID "$uid" already exists!'), backgroundColor: Colors.red));
          return;
        }
      }

      // Package our comprehensive data up
      final Map<String, dynamic> committeeData = <String, dynamic>{
        'uid': uid,
        'name': _nameController.text.trim(),
        'matric': _matricController.text.trim(),
        'ic': _icController.text.trim(),
        'course': _courseController.text.trim().toUpperCase(),
        'password': _passwordController.text.trim(),
        'position': _selectedPosition,
        'userType': 'Committee', // Hardcoded role!
      };

      if (widget.docId == null) {
        committeeData['createdAt'] = FieldValue.serverTimestamp();
        await firestore.collection('users').add(committeeData);
      } else {
        await firestore.collection('users').doc(widget.docId).update(committeeData);
      }

      if (mounted) {
        Navigator.pop(context); 
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.docId == null ? 'Committee Added!' : 'Committee Updated!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Database Error.'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isUpdate = widget.docId != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(isUpdate ? 'Update Committee' : 'Add Committee Member', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF303030),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600), 
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade300, width: 1)),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Official Details', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF303030))),
                      const SizedBox(height: 24),
                      
                      TextFormField(
                        controller: _uidController, enabled: !isUpdate,
                        decoration: const InputDecoration(labelText: 'System UID (e.g., COMM001)', prefixIcon: Icon(Icons.badge)),
                        validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        decoration: const InputDecoration(labelText: 'Login Password', prefixIcon: Icon(Icons.lock)),
                        validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
                      ),
                      
                      const Divider(height: 48), // Visual break
                      
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person)),
                        validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _matricController,
                        decoration: const InputDecoration(labelText: 'Matric Number', prefixIcon: Icon(Icons.numbers)),
                        validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _icController,
                        decoration: const InputDecoration(labelText: 'IC Number', prefixIcon: Icon(Icons.credit_card)),
                        validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _courseController,
                        decoration: const InputDecoration(labelText: 'Course Code', hintText: 'e.g., KOS, FCS, LAWS, AHAS KIRKHS', prefixIcon: Icon(Icons.school)),
                        validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      
                      DropdownButtonFormField<String>(
                        value: _selectedPosition,
                        decoration: const InputDecoration(labelText: 'Bureau Position', prefixIcon: Icon(Icons.work)),
                        items: _positions.map((pos) => DropdownMenuItem(value: pos, child: Text(pos))).toList(),
                        onChanged: (val) => setState(() => _selectedPosition = val),
                        validator: (value) => value == null ? 'Required' : null,
                      ),
                      
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity, height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveCommittee,
                          child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text(isUpdate ? 'Update Database' : 'Save Member'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}