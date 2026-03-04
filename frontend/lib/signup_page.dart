import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'auth_layout.dart'; 
import 'widgets/modern_text_field.dart';
import 'api_config.dart'; 

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _studentIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  String? _selectedCourse;
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = false;
  String _errorMessage = '';
  String _successMessage = '';

  final List<String> _courses = [
    'Bachelor of Science in Tourism Management',
    'Bachelor of Science in Hospitality Management',
    'Bachelor of Entrepreneurship',
    'Bachelor of Arts in Communication',
    'Bachelor of Arts in Political Science',
    'Bachelor of Arts in English Language',
    'Bachelor of Science in Social Work',
    'Bachelor of Science in Biology',
    'Bachelor of Science in Information Technology',
    'Bachelor of Library and Information Science',
    'Bachelor of Music in Music Education',
    'Bachelor of Early Childhood Education',
    'Bachelor of Elementary Education',
    'Bachelor of Special Needs Education',
    'Bachelor of Physical Education',
    'Bachelor of Technology and Livelihood Education',
    'Bachelor of Secondary Education'
  ];

  Future<void> _handleRegister() async {
    // This triggers all the validators in the form
    if (!_formKey.currentState!.validate()) return;
    
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = "Passwords do not match!");
      return;
    }

    setState(() { _isLoading = true; _errorMessage = ''; _successMessage = ''; });

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'student_number': _studentIdController.text.trim(),
          'full_name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'course': _selectedCourse, 
          'password': _passwordController.text.trim(),
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          _successMessage = "Registration successful! You can now log in.";
          _nameController.clear(); 
          _emailController.clear(); 
          _studentIdController.clear(); 
          _selectedCourse = null; 
          _passwordController.clear(); 
          _confirmPasswordController.clear();
        });
      } else {
        setState(() => _errorMessage = data['detail'] ?? 'Registration failed');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Cannot connect to server. Is Python running?');
    } finally {
      setState(() => _isLoading = false);
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
            Transform.translate(
              offset: const Offset(-10, 0),
              child: TextButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white70, size: 14),
                label: const Text('Back to login', style: TextStyle(color: Colors.white70)),
              ),
            ),
            const SizedBox(height: 5),
            
            const Text('Create Account', style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            const Text('Register as a student to participate in the upcoming elections.', style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5)),
            const SizedBox(height: 20),
            
            if (_errorMessage.isNotEmpty)
              Padding(padding: const EdgeInsets.only(bottom: 15), child: Text(_errorMessage, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))),
            if (_successMessage.isNotEmpty)
              Padding(padding: const EdgeInsets.only(bottom: 15), child: Text(_successMessage, style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold))),

            ModernTextField(
              controller: _nameController,
              hintText: 'Full Name (e.g. John Doe)',
              validator: (value) => value == null || value.isEmpty ? 'Name is required' : null,
            ),
            
            // ==========================================
            // VALIDATION: EMAIL 
            // ==========================================
            ModernTextField(
              controller: _emailController,
              hintText: 'University Email',
              validator: (value) {
                if (value == null || value.isEmpty) return 'Email is required';
                // Regex checks for characters before @, after @, and ending in .com or .edu.ph
                if (!RegExp(r'^.+@.+\.(com|edu\.ph)$').hasMatch(value)) {
                  return 'Must end in .com or .edu.ph';
                }
                return null;
              },
            ),
            
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ==========================================
                // VALIDATION: STUDENT ID (7 DIGITS)
                // ==========================================
                Expanded(
                  flex: 2, 
                  child: ModernTextField(
                    controller: _studentIdController,
                    hintText: 'Student ID',
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Required';
                      // Regex checks that the input is exactly 7 digits long, no letters allowed
                      if (!RegExp(r'^\d{7}$').hasMatch(value)) {
                        return 'Must be 7 digits';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 10),
                
                // Course Dropdown
                Expanded(
                  flex: 3, 
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 15.0),
                    child: DropdownButtonFormField<String>(
                      isExpanded: true, 
                      menuMaxHeight: 300, 
                      value: _selectedCourse,
                      hint: const Text('Course', style: TextStyle(color: Colors.black54, fontSize: 13)),
                      icon: const Icon(Icons.arrow_drop_down, color: Colors.black54),
                      dropdownColor: const Color(0xFFE2E2E2),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFE2E2E2),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        errorStyle: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                      items: _courses.map((String course) {
                        return DropdownMenuItem<String>(
                          value: course,
                          child: Text(
                            course,
                            style: const TextStyle(color: Colors.black87, fontSize: 11), 
                            overflow: TextOverflow.ellipsis, 
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() => _selectedCourse = newValue);
                      },
                      validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                    ),
                  ),
                ),
              ],
            ),

            // ==========================================
            // VALIDATION: PASSWORD (MIN 12 CHARACTERS)
            // ==========================================
            ModernTextField(
              controller: _passwordController,
              hintText: 'Password',
              isPassword: true,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Password is required';
                if (value.length < 12) return 'Min. 12 characters required';
                return null;
              },
            ),
            
            // Confirm Password validation updated to check match instantly
            ModernTextField(
              controller: _confirmPasswordController,
              hintText: 'Confirm Password',
              isPassword: true,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Please confirm';
                if (value != _passwordController.text) return 'Passwords do not match';
                return null;
              },
            ),
            
            const SizedBox(height: 10),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber, 
                  foregroundColor: const Color(0xFF000B6B),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isLoading ? null : _handleRegister,
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Color(0xFF000B6B), strokeWidth: 2))
                    : const Text('REGISTER', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              ),
            )
          ],
        ),
      ),
    );
  }
}