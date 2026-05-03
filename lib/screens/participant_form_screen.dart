import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import '../utils/constants.dart'; // <-- IMPORTING YOUR NEW BRAIN

class ParticipantFormScreen extends StatefulWidget {
  final Map<String, dynamic>? existingData;
  final String? docId;

  const ParticipantFormScreen({super.key, this.existingData, this.docId});

  @override
  State<ParticipantFormScreen> createState() => _ParticipantFormScreenState();
}

class _ParticipantFormScreenState extends State<ParticipantFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  String? _selectedCategory;
  String? _entryType;
  
  final FocusNode _rfidFocusNode = FocusNode();
  bool _isRfidFocused = false;

  final List<String> _entryTypes = ['Single Entry', 'Bulk Entry'];

  final Map<String, TextEditingController> _ctrls = {
    'uid': TextEditingController(), 'password': TextEditingController(), 'rfid': TextEditingController(),
    'email': TextEditingController(), 'name': TextEditingController(), 'ic': TextEditingController(),
    'phone': TextEditingController(), 'emergency': TextEditingController(), 'health': TextEditingController(),
    'matric': TextEditingController(), 'course': TextEditingController(), 'school': TextEditingController(),
    'schoolCode': TextEditingController()
  };

  final Map<String, String?> _drops = {
    'blood': null, 'eating': null, 'gender': null, 'ethnicity': null, 'scoutCat': null,
    'compReg': null, 'compChoice': null, 'compSlot': null, 'fee': null, 'tee': null,
    'campus': null, 'state': null, 'district': null
  };

  @override
  void initState() {
    super.initState();
    _rfidFocusNode.addListener(() {
      setState(() => _isRfidFocused = _rfidFocusNode.hasFocus);
    });

    if (widget.existingData != null) {
      final data = widget.existingData!;
      
      _selectedCategory = data['category'];
      _entryType = 'Single Entry';

      _ctrls.forEach((key, ctrl) {
        if (data.containsKey(key)) ctrl.text = data[key].toString();
      });

      // --- USING AppConstants EVERYWHERE HERE ---
      if (AppConstants.campuses.contains(data['campus'])) _drops['campus'] = data['campus'];
      if (AppConstants.bloodTypes.contains(data['blood'])) _drops['blood'] = data['blood'];
      if (AppConstants.eatingHabits.contains(data['eating'])) _drops['eating'] = data['eating'];
      if (AppConstants.genders.contains(data['gender'])) _drops['gender'] = data['gender'];
      if (AppConstants.ethnicities.contains(data['ethnicity'])) _drops['ethnicity'] = data['ethnicity'];
      if (AppConstants.scoutCats.contains(data['scoutCat'] ?? data['scoutCategory'] ?? data['membership'])) _drops['scoutCat'] = data['scoutCat'] ?? data['scoutCategory'] ?? data['membership'];
      if (['Yes', 'No'].contains(data['compReg'])) _drops['compReg'] = data['compReg'];
      if (AppConstants.compChoices.contains(data['compChoice'])) _drops['compChoice'] = data['compChoice'];
      if (AppConstants.slots.contains(data['compSlot'])) _drops['compSlot'] = data['compSlot'];
      if (AppConstants.teeSizes.contains(data['tee'])) _drops['tee'] = data['tee'];
      
      if (AppConstants.stateDistricts.keys.contains(data['state'])) {
        _drops['state'] = data['state'];
        if (AppConstants.stateDistricts[data['state']]!.contains(data['district'])) {
          _drops['district'] = data['district'];
        }
      }

      String feeToCheck = data['fee'] ?? data['feePaid'] ?? '';
      if (_selectedCategory == 'IIUM Community' && AppConstants.iiumFees.contains(feeToCheck)) _drops['fee'] = feeToCheck;
      if (_selectedCategory == 'Public Community' && AppConstants.publicFees.contains(feeToCheck)) _drops['fee'] = feeToCheck;
    }
  }

  @override
  void dispose() {
    _rfidFocusNode.dispose();
    for (var ctrl in _ctrls.values) { ctrl.dispose(); }
    super.dispose();
  }

  Future<void> _saveSingleEntry() async {
    setState(() => _isLoading = true);

    try {
      final uid = _ctrls['uid']!.text.trim();
      
      if (uid.isNotEmpty && widget.docId == null) {
        final duplicateCheck = await FirebaseFirestore.instance.collection('users').where('uid', isEqualTo: uid).get();
        if (duplicateCheck.docs.isNotEmpty) {
          setState(() => _isLoading = false);
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('UID "$uid" already exists!'), backgroundColor: Colors.red));
          return;
        }
      }

      Map<String, dynamic> data = {
        'userType': 'Participant',
        'category': _selectedCategory ?? '', 
      };

      if (widget.docId == null) {
        data['createdAt'] = FieldValue.serverTimestamp();
      }

      _ctrls.forEach((key, ctrl) {
        data[key] = ctrl.text.trim(); 
      });

      _drops.forEach((key, val) {
        data[key] = val ?? ''; 
      });

      if (widget.docId == null) {
        await FirebaseFirestore.instance.collection('users').add(data);
      } else {
        await FirebaseFirestore.instance.collection('users').doc(widget.docId).update(data);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.docId == null ? 'Participant Saved!' : 'Participant Updated!'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error saving data.'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleBulkUpload() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['csv'], withData: true);
      if (result == null || result.files.single.bytes == null) return;

      setState(() => _isLoading = true);

      final bytes = result.files.single.bytes!;
      final csvString = utf8.decode(bytes);
      List<List<dynamic>> csvTable = const CsvToListConverter(shouldParseNumbers: false).convert(csvString);

      if (csvTable.length < 2) throw Exception("CSV is empty or missing data.");

      final headers = csvTable.first.map((e) => e.toString().trim()).toList();
      int successCount = 0;

      for (var i = 1; i < csvTable.length; i++) {
        final row = csvTable[i];
        if (row.isEmpty || row[0].toString().trim().isEmpty) continue;

        Map<String, dynamic> docData = {
          'userType': 'Participant', 
          'category': _selectedCategory ?? '', 
          'createdAt': FieldValue.serverTimestamp(),
        };

        for (var j = 0; j < headers.length; j++) {
          if (j < row.length) {
            docData[headers[j]] = row[j].toString().trim();
          }
        }
        await FirebaseFirestore.instance.collection('users').add(docData);
        successCount++;
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Successfully imported $successCount participants!'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error processing CSV. Check format.'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getCsvInstructions() {
    if (_selectedCategory == 'School Group') {
      return "A1 (uid) | B1 (password) | C1 (school) | D1 (schoolCode) | E1 (teacherName) | F1 (teacherPhone) | G1 (name) | H1 (ic) | I1 (gender) | J1 (ethnicity) | K1 (membership) | L1 (state) | M1 (district) | N1 (fee) | O1 (tee)";
    } else if (_selectedCategory == 'IIUM Community') {
      return "A1 (uid) | B1 (password) | C1 (name) | D1 (email) | E1 (phone) | F1 (emergency) | G1 (ic) | H1 (blood) | I1 (gender) | J1 (ethnicity) | K1 (health) | L1 (eating) | M1 (scoutCat) | N1 (matric) | O1 (campus) | P1 (course) | Q1 (compReg) | R1 (compChoice) | S1 (compSlot) | T1 (fee) | U1 (tee)";
    } else {
      return "A1 (uid) | B1 (password) | C1 (name) | D1 (email) | E1 (phone) | F1 (emergency) | G1 (ic) | H1 (blood) | I1 (gender) | J1 (ethnicity) | K1 (health) | L1 (eating) | M1 (scoutCat) | N1 (state) | O1 (district) | P1 (school) | Q1 (compReg) | R1 (compChoice) | S1 (compSlot) | T1 (fee) | U1 (tee)";
    }
  }

  Widget _buildDropdown(String label, String key, List<String> items, {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: _drops[key],
        decoration: InputDecoration(labelText: label),
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: (val) => setState(() => _drops[key] = val),
        isExpanded: true, 
      ),
    );
  }

  Widget _buildField(String label, String key, {bool required = false, bool isRow = false}) {
    Widget field = TextFormField(
      controller: _ctrls[key],
      decoration: InputDecoration(labelText: label),
    );
    return isRow ? field : Padding(padding: const EdgeInsets.only(bottom: 16), child: field);
  }

  @override
  Widget build(BuildContext context) {
    final bool isUpdate = widget.docId != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(title: Text(isUpdate ? 'Update Participant' : 'Registration Form', style: const TextStyle(color: Colors.white)), backgroundColor: const Color(0xFF303030), iconTheme: const IconThemeData(color: Colors.white)),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('1. Registration Type', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF303030))),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: const InputDecoration(labelText: 'Category'),
                        // --- CALLED FROM CONSTANTS ---
                        items: AppConstants.categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                        onChanged: (val) => setState(() {
                          _selectedCategory = val;
                          _entryType = val == 'School Group' ? 'Bulk Entry' : null;
                          _drops['state'] = null; _drops['district'] = null; _drops['campus'] = null; _drops['fee'] = null;
                        }),
                      ),
                      
                      if (_selectedCategory != null && _selectedCategory != 'School Group') ...[
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _entryType,
                          decoration: const InputDecoration(labelText: 'Type of Entry'),
                          items: _entryTypes.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                          onChanged: (val) => setState(() => _entryType = val),
                        ),
                      ],

                      const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Divider()),

                      if (_entryType == 'Bulk Entry') ...[
                        const Text('CSV Bulk Import', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blue[200]!)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(children: [Icon(Icons.info_outline, color: Colors.blue), SizedBox(width: 8), Text('CSV Header Guide', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 16))]),
                              const SizedBox(height: 12),
                              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)), child: Text(_getCsvInstructions(), style: const TextStyle(fontFamily: 'monospace', fontSize: 13, height: 1.5, fontWeight: FontWeight.w600))),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity, height: 80,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.upload_file, size: 32), label: const Text('Select & Upload .CSV File', style: TextStyle(fontSize: 18)),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[100], foregroundColor: Colors.blue[800], elevation: 0, side: BorderSide(color: Colors.blue[300]!, width: 2)),
                            onPressed: _isLoading ? null : _handleBulkUpload,
                          ),
                        ),
                        if (_isLoading) const Padding(padding: EdgeInsets.only(top: 16), child: Center(child: CircularProgressIndicator())),
                      ] 
                      else if (_entryType == 'Single Entry') ...[
                        
                        const Text('System Login Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        Row(children: [ Expanded(child: _buildField('System UID', 'uid', isRow: true)), const SizedBox(width: 16), Expanded(child: _buildField('Password', 'password', isRow: true)) ]),
                        const SizedBox(height: 16),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(bottom: 16),
                          child: TextFormField(
                            controller: _ctrls['rfid'], focusNode: _rfidFocusNode,
                            decoration: InputDecoration(
                              labelText: _isRfidFocused ? 'Scanner Active - Tap Card Now...' : 'RFID Tag ID',
                              labelStyle: TextStyle(color: _isRfidFocused ? Colors.green[700] : Colors.grey[600], fontWeight: _isRfidFocused ? FontWeight.bold : FontWeight.normal),
                              prefixIcon: Icon(Icons.wifi_tethering, color: _isRfidFocused ? Colors.green[700] : Colors.grey),
                              filled: true, fillColor: _isRfidFocused ? Colors.green[50] : Colors.white,
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.green[700]!, width: 2)),
                            ),
                            onFieldSubmitted: (_) => FocusScope.of(context).unfocus(), 
                          ),
                        ),

                        const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Divider()),

                        const Text('Participant Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        Row(children: [ Expanded(child: _buildField('Full Name', 'name', isRow: true)), const SizedBox(width: 16), Expanded(child: _buildField('Email Address', 'email', isRow: true)) ]),
                        const SizedBox(height: 16),
                        Row(children: [ Expanded(child: _buildField('Phone Number', 'phone', isRow: true)), const SizedBox(width: 16), Expanded(child: _buildField('Emergency Contact', 'emergency', isRow: true)) ]),
                        const SizedBox(height: 16),
                        Row(children: [ Expanded(child: _buildField('IC Number', 'ic', isRow: true)), const SizedBox(width: 16), Expanded(child: _buildDropdown('Blood Type', 'blood', AppConstants.bloodTypes)) ]),
                        
                        _buildDropdown('Scout Category / Age', 'scoutCat', AppConstants.scoutCats),
                        Row(children: [ Expanded(child: _buildDropdown('Gender', 'gender', AppConstants.genders)), const SizedBox(width: 16), Expanded(child: _buildDropdown('Ethnicity', 'ethnicity', AppConstants.ethnicities)) ]),
                        Row(children: [ Expanded(child: _buildField('Health Issues/Allergies', 'health', isRow: true)), const SizedBox(width: 16), Expanded(child: _buildDropdown('Eating Habit', 'eating', AppConstants.eatingHabits)) ]),

                        const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Divider()),
                        
                        const Text('Location Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),

                        if (_selectedCategory == 'IIUM Community') ...[
                          Row(children: [ Expanded(child: _buildField('Matric Number', 'matric', isRow: true)), const SizedBox(width: 16), Expanded(child: _buildDropdown('Campus', 'campus', AppConstants.campuses)) ]),
                          _buildField('Course', 'course'),
                        ] else ...[
                          Row(
                            children: [ 
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _drops['state'], decoration: const InputDecoration(labelText: 'State'),
                                  items: AppConstants.stateDistricts.keys.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                                  onChanged: (val) => setState(() { _drops['state'] = val; _drops['district'] = null; }), 
                                )
                              ), 
                              const SizedBox(width: 16), 
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _drops['district'], decoration: const InputDecoration(labelText: 'District'),
                                  items: _drops['state'] == null ? [] : AppConstants.stateDistricts[_drops['state']]!.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                                  onChanged: _drops['state'] == null ? null : (val) => setState(() => _drops['district'] = val),
                                  hint: Text(_drops['state'] == null ? 'Select State first' : 'Select District'),
                                )
                              ) 
                            ]
                          ),
                          const SizedBox(height: 16),
                          Row(children: [ Expanded(child: _buildField('School/Institution Name', 'school', isRow: true)), const SizedBox(width: 16), Expanded(child: _buildField('School Code', 'schoolCode', isRow: true)) ]),
                        ],

                        const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Divider()),
                        
                        const Text('Event Selection', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),

                        _buildDropdown('Competition Registration', 'compReg', ['Yes', 'No']),
                        if (_drops['compReg'] == 'Yes') ...[
                          Row(children: [ Expanded(child: _buildDropdown('Competition Choice', 'compChoice', AppConstants.compChoices)), const SizedBox(width: 16), Expanded(child: _buildDropdown('Slot', 'compSlot', AppConstants.slots)) ]),
                        ],

                        Row(children: [
                          Expanded(child: _buildDropdown('Fee Option', 'fee', _selectedCategory == 'IIUM Community' ? AppConstants.iiumFees : AppConstants.publicFees)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildDropdown('STEM Run Tee Size', 'tee', AppConstants.teeSizes))
                        ]),

                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity, height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _saveSingleEntry,
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF303030), foregroundColor: Colors.white),
                            child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text(isUpdate ? 'Update Participant' : 'Submit Registration'),
                          ),
                        ),
                      ]
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