import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'auth_layout.dart'; 
import 'api_config.dart'; 

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = false; 
  bool _obscurePassword = true; 
  String _errorMessage = '';

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    http.Response response;
    
    try {
      response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text.trim(),
          'password': _passwordController.text.trim(),
        }),
      ).timeout(const Duration(seconds: 10));
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Network error. Cannot connect to server.';
      });
      return;
    }

    setState(() => _isLoading = false);

    if (response.statusCode == 200) {
      try {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        
        await prefs.setString('jwt_token', data['access_token']);
        
        bool isStudentOfficer = false;
        bool isMultiRole = data['multi_role'] == true;
        String role = 'Student';
        List<String> perms = [];

        // 🛠️ FIX: Bulletproof parsing that targets exactly the right map, whether nested or flat.
        var userData = data.containsKey('user') && data['user'] != null ? data['user'] : data;

        isStudentOfficer = userData['is_student_officer'] == 1 || userData['is_student_officer'] == true;
        role = userData['role'] ?? 'Student';
        
        // 🛠️ FIX: Bulletproof list casting. Converts List<dynamic> to strictly List<String>
        var rawPerms = userData['permissions'] ?? data['permissions'];
        if (rawPerms != null) {
          if (rawPerms is String) {
            try {
              var decoded = jsonDecode(rawPerms);
              if (decoded is List) {
                perms = decoded.map((e) => e.toString()).toList();
              }
            } catch (_) {}
          } else if (rawPerms is List) {
            perms = rawPerms.map((e) => e.toString()).toList();
          }
        }
        
        // Proceed with Navigation
        if ((role == 'Student' && isStudentOfficer) || isMultiRole) {
          if (!mounted) return;
          _showRoleSelectionDialog(data, prefs, perms);
        } else {
          await prefs.setString('role', role);
          await prefs.setString('permissions', jsonEncode(perms));
          _navigateBasedOnRole(role);
        }
      } catch (e) {
        setState(() => _errorMessage = 'Data Parsing Error: $e');
      }
    } else {
      try {
        final errorData = jsonDecode(response.body);
        setState(() => _errorMessage = errorData['detail'] ?? 'Login failed. Please check your credentials.');
      } catch (e) {
        setState(() => _errorMessage = 'Login failed with status ${response.statusCode}');
      }
    }
  }

  void _showRoleSelectionDialog(Map<String, dynamic> data, SharedPreferences prefs, List<String> perms) {
    showDialog(
      context: context,
      barrierDismissible: false, 
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.switch_account, color: Color(0xFF000B6B)),
              SizedBox(width: 10),
              Text("Select Workspace", style: TextStyle(color: Color(0xFF000B6B), fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text("Your account has multiple roles. Where would you like to go?"),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber, 
                foregroundColor: const Color(0xFF000B6B),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0, 
              ),
              onPressed: () async {
                await prefs.setString('role', 'Student');
                if (!mounted) return;
                Navigator.pop(context);
                _navigateBasedOnRole('Student');
              },
              child: const Text("Continue as Student", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 10), 
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF000B6B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                await prefs.setString('role', 'Staff');
                await prefs.setString('permissions', jsonEncode(perms));
                if (!mounted) return;
                Navigator.pop(context);
                _navigateBasedOnRole('Staff');
              },
              child: const Text("Enter Staff Panel"),
            ),
          ],
        );
      },
    );
  }

  void _navigateBasedOnRole(String role) {
    if (role == 'Admin' || role == 'Staff') {
      Navigator.pushReplacementNamed(context, '/admin_dashboard', arguments: {'loginSuccess': true});
    } else {
      Navigator.pushReplacementNamed(context, '/student_dashboard', arguments: {'loginSuccess': true});
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      formContent: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.how_to_vote, size: 60, color: Colors.white),
            const SizedBox(height: 10),
            
            const Text(
              'LNU eMobile Voting',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.amber, 
                letterSpacing: 1.2,
              ),
            ),
            const Text(
              'Secure Student Election System',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            
            const SizedBox(height: 30),

            if (_errorMessage.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 15),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(_errorMessage, style: const TextStyle(color: Colors.red, fontSize: 13)),
                    ),
                  ],
                ),
              ),

            // -----------------------------------------------------
            // UPDATED: WHITE EMAIL TEXT FIELD
            // -----------------------------------------------------
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Colors.black87), // Dark text
              decoration: InputDecoration(
                labelText: 'Student / Admin Email',
                labelStyle: const TextStyle(color: Colors.grey), // Darker label
                prefixIcon: const Icon(Icons.email, color: Colors.amber),
                filled: true,
                fillColor: Colors.white, // Solid white background
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Please enter your email';
                if (!value.contains('@')) return 'Enter a valid email address';
                return null;
              },
            ),
            
            const SizedBox(height: 15),

            // -----------------------------------------------------
            // UPDATED: WHITE PASSWORD TEXT FIELD
            // -----------------------------------------------------
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              style: const TextStyle(color: Colors.black87), // Dark text
              decoration: InputDecoration(
                labelText: 'Password',
                labelStyle: const TextStyle(color: Colors.grey), // Darker label
                prefixIcon: const Icon(Icons.lock, color: Colors.amber),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    color: Colors.grey, // Darker eye icon
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                filled: true,
                fillColor: Colors.white, // Solid white background
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Please enter your password';
                return null;
              },
            ),
            
            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber, 
                  foregroundColor: const Color(0xFF000B6B), 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 5,
                ),
                child: _isLoading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Color(0xFF000B6B), strokeWidth: 2))
                  : const Text('SIGN IN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              ),
            ),
            
            const SizedBox(height: 25),
            const Divider(color: Colors.white24, thickness: 1),
            const SizedBox(height: 20),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Don't have an account? ", style: TextStyle(color: Colors.white70)),
                InkWell(
                  onTap: () => Navigator.pushNamed(context, '/signup'),
                  child: const Text('Sign Up', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 25),
            
            InkWell(
              onTap: () => Navigator.pushNamed(context, '/file_party'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24)
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.assignment_ind, color: Colors.amber, size: 18),
                    SizedBox(width: 10),
                    Text('File for Party Candidacy', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}