import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ============================================================================
// ACTIVITY FORM SCREEN (Add & Update + Venue Category Dropdown)
// ============================================================================
class ActivityFormScreen extends StatefulWidget {
  final Map<String, dynamic>? existingData;
  final String? docId;

  const ActivityFormScreen({super.key, this.existingData, this.docId});

  @override
  State<ActivityFormScreen> createState() => _ActivityFormScreenState();
}

class _ActivityFormScreenState extends State<ActivityFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _uidController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  
  String? _selectedType;
  String? _selectedVenue;

  final List<String> _activityTypes = ['Expedition', 'Exhibition', 'Forum', 'Other'];
  
  final List<String> _venueCategories = [
    'Biological Building', 
    'Admin Building', 
    'Physical Building'
  ];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingData != null) {
      _uidController.text = widget.existingData!['uid'] ?? '';
      _nameController.text = widget.existingData!['name'] ?? '';
      
      String? existingType = widget.existingData!['activityType'];
      if (_activityTypes.contains(existingType)) {
        _selectedType = existingType;
      }

      String? existingVenue = widget.existingData!['venueCategory'];
      if (_venueCategories.contains(existingVenue)) {
        _selectedVenue = existingVenue;
      }
    }
  }

  @override
  void dispose() {
    _uidController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveActivity() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedType == null || _selectedVenue == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both a Type and a Venue!'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final String uid = _uidController.text.trim();
      final firestore = FirebaseFirestore.instance;

      if (widget.docId == null) {
        final duplicateCheck = await firestore.collection('activities').where('uid', isEqualTo: uid).get();
        if (duplicateCheck.docs.isNotEmpty) {
          setState(() => _isLoading = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Activity UID "$uid" already exists!'), backgroundColor: Colors.red),
            );
          }
          return;
        }
      }

      // --- BULLETPROOF MAP DECLARATION ---
      final Map<String, dynamic> activityData = <String, dynamic>{
        'uid': uid,
        'name': _nameController.text.trim(),
        'activityType': _selectedType,
        'venueCategory': _selectedVenue, 
      };

      if (widget.docId == null) {
        activityData['createdAt'] = FieldValue.serverTimestamp();
        await firestore.collection('activities').add(activityData);
      } else {
        await firestore.collection('activities').doc(widget.docId).update(activityData);
      }

      if (mounted) {
        Navigator.pop(context); 
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.docId == null ? 'Activity Added!' : 'Activity Updated!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Database Error. Check connection.'), backgroundColor: Colors.red),
        );
      }
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
        title: Text(isUpdate ? 'Update Activity' : 'Add New Activity', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF303030),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600), 
            padding: const EdgeInsets.all(24.0),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade300, width: 1),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Activity Details', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF303030))),
                      const SizedBox(height: 24),
                      
                      TextFormField(
                        controller: _uidController,
                        enabled: !isUpdate, 
                        // CONST REMOVED HERE
                        decoration: InputDecoration(
                          labelText: 'Activity UID (e.g., EXPE004)',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.badge),
                        ),
                        validator: (value) => value == null || value.trim().isEmpty ? 'UID is required' : null,
                      ),
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _nameController,
                        // CONST REMOVED HERE
                        decoration: InputDecoration(
                          labelText: 'Activity Name',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.event_note),
                        ),
                        validator: (value) => value == null || value.trim().isEmpty ? 'Name is required' : null,
                      ),
                      const SizedBox(height: 16),
                      
                      DropdownButtonFormField<String>(
                        value: _selectedType,
                        // CONST REMOVED HERE
                        decoration: InputDecoration(
                          labelText: 'Activity Type',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.category),
                        ),
                        items: _activityTypes.map((type) {
                          return DropdownMenuItem(value: type, child: Text(type));
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedType = val),
                        validator: (value) => value == null ? 'Type is required' : null,
                      ),
                      const SizedBox(height: 16),

                      DropdownButtonFormField<String>(
                        value: _selectedVenue,
                        // CONST REMOVED HERE
                        decoration: InputDecoration(
                          labelText: 'Venue Category',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.location_on),
                        ),
                        items: _venueCategories.map((venue) {
                          return DropdownMenuItem(value: venue, child: Text(venue));
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedVenue = val),
                        validator: (value) => value == null ? 'Venue is required' : null,
                      ),
                      const SizedBox(height: 32),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF303030),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: _isLoading ? null : _saveActivity,
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text(isUpdate ? 'Update Database' : 'Save Activity', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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