import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async'; 
import 'api_config.dart';

class ApplyStaffScreen extends StatefulWidget {
  const ApplyStaffScreen({super.key});

  @override
  State<ApplyStaffScreen> createState() => _ApplyStaffScreenState();
}

class _ApplyStaffScreenState extends State<ApplyStaffScreen> {
  bool _isLoading = true;
  bool _isSubmitting = false;
  String _status = "None"; // None, Pending, Accepted, Rejected
  bool _hasShownRejectDialog = false;

  Timer? _pollingTimer; 

  final TextEditingController _intentCtrl = TextEditingController();
  final TextEditingController _experienceCtrl = TextEditingController();
  final TextEditingController _availabilityCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  @override
  void dispose() {
    _stopPolling(); 
    _intentCtrl.dispose();
    _experienceCtrl.dispose();
    _availabilityCtrl.dispose();
    super.dispose();
  }

  void _startPolling() {
    if (_pollingTimer != null && _pollingTimer!.isActive) return;
    
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _checkStatus(isSilentUpdate: true);
    });
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> _checkStatus({bool isSilentUpdate = false}) async {
    if (!isSilentUpdate) setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token') ?? '';

      // 🚀 CRITICAL FIX: We only call THIS endpoint now, avoiding desyncs completely
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/students/apply-staff/status'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (!mounted) return; 

        setState(() {
          _status = data['status'];
          if (!isSilentUpdate) _isLoading = false;
        });

        // 🚀 MANAGE POLLING STATE
        if (_status == "Pending") {
          _startPolling(); 
        } else {
          _stopPolling(); 
        }

        // Handle Rejection Pop-up
        if (_status == "Rejected" && !_hasShownRejectDialog) {
          _hasShownRejectDialog = true;
          WidgetsBinding.instance.addPostFrameCallback((_) => _showRejectionDialog());
        }
      } else {
        if (!isSilentUpdate) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (!isSilentUpdate) setState(() => _isLoading = false);
    }
  }

  void _showRejectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [Icon(Icons.error_outline, color: Colors.red), SizedBox(width: 10), Text("Application Update")]),
        content: const Text("We regret to inform you that your previous application was not accepted. You may submit a new application below."),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF000B6B), foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context),
            child: const Text("Close & Reapply"),
          )
        ],
      ),
    );
  }

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token') ?? '';

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/students/apply-staff'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode({
          "intent_statement": _intentCtrl.text.trim(),
          "experience": _experienceCtrl.text.trim(),
          "availability": _availabilityCtrl.text.trim()
        }),
      );

      setState(() => _isSubmitting = false);
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Application submitted successfully!"), backgroundColor: Colors.green));
        _intentCtrl.clear();
        _experienceCtrl.clear();
        _availabilityCtrl.clear();
        _checkStatus(); 
      } else {
        final error = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error['detail'] ?? "Submission failed"), backgroundColor: Colors.red));
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Network error. Try again later."), backgroundColor: Colors.red));
    }
  }

  Widget _buildPendingView() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)]),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.amber),
            const SizedBox(height: 20),
            const Text("Application Under Review", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF000B6B))),
            const SizedBox(height: 10),
            const Text("Your application has been submitted to the election administrators. Please wait for their decision.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildAcceptedView() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)]),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.verified, size: 80, color: Colors.green),
            const SizedBox(height: 20),
            const Text("Congratulations!", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF000B6B))),
            const SizedBox(height: 10),
            const Text("You are officially a Student Officer! Log out and log back in to access your new Staff workspace.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildApplicationForm() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)]),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Student Officer Application", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF000B6B))),
              const SizedBox(height: 30),
              TextFormField(
                controller: _intentCtrl,
                maxLines: 3,
                decoration: InputDecoration(labelText: "Statement of Intent", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _experienceCtrl,
                maxLines: 3,
                decoration: InputDecoration(labelText: "Relevant Experience", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _availabilityCtrl,
                decoration: InputDecoration(labelText: "Availability (e.g. Weekdays 3PM)", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF000B6B), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: _isSubmitting ? null : _submitApplication,
                  child: _isSubmitting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text("Submit Application", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: Colors.white));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(30),
      child: _status == "Pending" ? _buildPendingView() : (_status == "Accepted" ? _buildAcceptedView() : _buildApplicationForm()),
    );
  }
}