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
  
  bool _isLoading = false; // <-- Ensures it doesn't start in a loading state
  bool _obscurePassword = true; 
  String _errorMessage = '';

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() { 
      _isLoading = true; 
      _errorMessage = ''; 
    });

    try {
      // Added a 10-second timeout so the app doesn't hang if Python isn't running
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text.trim(),
          'password': _passwordController.text.trim(),
        }),
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        final token = data['access_token'];
        
        await prefs.setString('jwt_token', token);

        // --- JWT DECODING & RBAC LOGIC ---
// --- JWT DECODING & RBAC LOGIC ---
        String userRole = 'Student'; // Default fallback
        final tokenParts = token.split('.');
        
        if (tokenParts.length == 3) {
          final payload = jsonDecode(
              utf8.decode(base64Url.decode(base64Url.normalize(tokenParts[1]))));
              
          userRole = payload['role'] ?? 'Student';
          
          await prefs.setString('role', userRole);
          
          // --- THE CRITICAL FIX IS HERE ---
          // Ensure we are getting a valid List, even if the backend sends null or a string by mistake
          List<dynamic> rawPermissions = [];
          if (payload['permissions'] != null) {
            if (payload['permissions'] is String) {
               // Sometimes SQLAlchemy JSON columns return as a stringified JSON
               rawPermissions = jsonDecode(payload['permissions']);
            } else if (payload['permissions'] is List) {
               rawPermissions = payload['permissions'];
            }
          }
          
          // Save it to SharedPreferences as a JSON string
          await prefs.setString('permissions', jsonEncode(rawPermissions)); 
          // ---------------------------------
          
        } else {
          // Fallback if the token format fails
          userRole = data['role'] ?? 'Student';
          await prefs.setString('role', userRole);
        }
        // ---------------------------------

        if (!mounted) return;
        
        // Route Admin AND Staff to the admin dashboard
        if (userRole == 'Admin' || userRole == 'Staff') {
          Navigator.pushReplacementNamed(context, '/admin_dashboard');
        } else {
          Navigator.pushReplacementNamed(context, '/student_home');
        }
      } else {
        setState(() => _errorMessage = data['detail'] ?? 'Login failed');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Cannot connect to server. Is your Python backend running?');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      formContent: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Welcome Back', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Please enter your university details to sign in and vote.', style: TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 30),
            
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 15), 
                child: Text(_errorMessage, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))
              ),

            // Standardized Email Field
            TextFormField(
              controller: _emailController,
              style: const TextStyle(color: Colors.black87), // Changed text to black
              decoration: InputDecoration(
                hintText: 'University Email',
                hintStyle: const TextStyle(color: Colors.black54), // Changed hint to dark grey
                filled: true,
                fillColor: Colors.white, // Changed background to solid white
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
              validator: (value) => value == null || value.isEmpty ? 'Email is required' : null,
            ),
            const SizedBox(height: 15),

            // Standardized Password Field with Toggle
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              style: const TextStyle(color: Colors.black87), // Changed text to black
              decoration: InputDecoration(
                hintText: 'Password',
                hintStyle: const TextStyle(color: Colors.black54), // Changed hint to dark grey
                filled: true,
                fillColor: Colors.white, // Changed background to solid white
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                suffixIcon: IconButton(
                  // Changed icon color to dark grey so it's visible on white
                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.black54),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (value) => value == null || value.isEmpty ? 'Password is required' : null,
            ),
            const SizedBox(height: 25),
            
            // Sign In Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  disabledBackgroundColor: Colors.amber.withOpacity(0.7), // Prevents button from going dark!
                  foregroundColor: const Color(0xFF000B6B),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isLoading ? null : _handleLogin,
                child: _isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Color(0xFF000B6B), strokeWidth: 2))
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
          ],
        ),
      ),
    );
  }
}