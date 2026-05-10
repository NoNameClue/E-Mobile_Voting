import 'package:flutter/foundation.dart'; 
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'auth_layout.dart'; 
import 'widgets/modern_text_field.dart';
import 'api_config.dart'; 

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _middleNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _studentIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  String? _selectedCourse;
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = false;
  String _errorMessage = '';
  String _successMessage = '';

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  
  XFile? _profileImage;
  Uint8List? _profileImageBytes;
  final ImagePicker _picker = ImagePicker();

  // 🛠️ ADDED: Password Strength State Variables
  int _passwordStrength = 0; 
  List<String> _missingRequirements = [
    "12+ characters", 
    "uppercase", 
    "lowercase", 
    "number", 
    "special character (.,?!@#\$%)"
  ];

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

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes(); 
      setState(() {
        _profileImage = pickedFile;
        _profileImageBytes = bytes;
      });
    }
  }

  // 🛠️ ADDED: Real-time Password Strength Evaluation Logic
  void _evaluatePasswordStrength(String password) {
    List<String> missing = [];
    int metConditions = 0;

    // 1. Length >= 12
    if (password.length >= 12) {
      metConditions++;
    } else {
      missing.add("12+ characters");
    }

    // 2. Uppercase Letter
    if (RegExp(r'[A-Z]').hasMatch(password)) {
      metConditions++;
    } else {
      missing.add("uppercase letter");
    }

    // 3. Lowercase Letter
    if (RegExp(r'[a-z]').hasMatch(password)) {
      metConditions++;
    } else {
      missing.add("lowercase letter");
    }

    // 4. Number
    if (RegExp(r'[0-9]').hasMatch(password)) {
      metConditions++;
    } else {
      missing.add("number");
    }

    // 5. Special Character
    if (RegExp(r'[.,?!@#\$%]').hasMatch(password)) {
      metConditions++;
    } else {
      missing.add("special character (.,?!@#\$%)");
    }

    // Determine Strength Level (0 = None, 1 = Weak, 2 = Fair, 3 = Strong)
    int strength = 0;
    if (password.isEmpty) {
      strength = 0;
    } else if (metConditions <= 2) {
      strength = 1; // Weak
    } else if (metConditions <= 4) {
      strength = 2; // Fair
    } else if (metConditions == 5) {
      strength = 3; // Strong
    }

    setState(() {
      _passwordStrength = strength;
      _missingRequirements = missing;
    });
  }

  // 🛠️ ADDED: Password Strength UI Indicator
  Widget _buildPasswordStrengthIndicator() {
    if (_passwordController.text.isEmpty) return const SizedBox.shrink();

    Color strengthColor = Colors.grey;
    String strengthLabel = "";

    if (_passwordStrength == 1) {
      strengthColor = Colors.redAccent;
      strengthLabel = "Weak";
    } else if (_passwordStrength == 2) {
      strengthColor = Colors.orangeAccent;
      strengthLabel = "Fair";
    } else if (_passwordStrength == 3) {
      strengthColor = Colors.greenAccent;
      strengthLabel = "Strong";
    }

    return Padding(
      padding: const EdgeInsets.only(top: 5.0, bottom: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: _passwordStrength >= 1 ? strengthColor : Colors.white24,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: _passwordStrength >= 2 ? strengthColor : Colors.white24,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: _passwordStrength >= 3 ? strengthColor : Colors.white24,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                strengthLabel,
                style: TextStyle(color: strengthColor, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ],
          ),
          if (_missingRequirements.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Text(
                "Missing: ${_missingRequirements.join(', ')}",
                style: const TextStyle(color: Colors.orangeAccent, fontSize: 11, height: 1.3),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    
    // 🛠️ ADDED: Prevent submission if password is not strictly strong
    if (_passwordStrength < 3) {
      setState(() => _errorMessage = "Please meet all password requirements before registering.");
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = "Passwords do not match!");
      return;
    }

    setState(() { _isLoading = true; _errorMessage = ''; _successMessage = ''; });

    try {
      var request = http.MultipartRequest('POST', Uri.parse('${ApiConfig.baseUrl}/api/register'));
      
      request.fields['student_number'] = _studentIdController.text.trim();
      request.fields['first_name'] = _firstNameController.text.trim();
      request.fields['middle_name'] = _middleNameController.text.trim();
      request.fields['last_name'] = _lastNameController.text.trim();
      
      request.fields['email'] = _emailController.text.trim();
      request.fields['course'] = _selectedCourse!;
      request.fields['password'] = _passwordController.text.trim();

      if (_profileImage != null && _profileImageBytes != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'photo', 
          _profileImageBytes!,
          filename: _profileImage!.name,
        ));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          _successMessage = "Registration successful! You can now log in.";
          _firstNameController.clear(); 
          _middleNameController.clear(); 
          _lastNameController.clear(); 
          _emailController.clear(); 
          _studentIdController.clear(); 
          _selectedCourse = null; 
          _passwordController.clear(); 
          _confirmPasswordController.clear();
          
          _profileImage = null; 
          _profileImageBytes = null; 
          
          // Reset password strength UI
          _passwordStrength = 0;
          _missingRequirements = ["12+ characters", "uppercase", "lowercase", "number", "special character (.,?!@#\$%)"];
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

            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white.withOpacity(0.1),
                  backgroundImage: _profileImageBytes != null ? MemoryImage(_profileImageBytes!) : null,
                  child: _profileImageBytes == null
                      ? const Icon(Icons.camera_alt, color: Colors.white70, size: 30)
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: ModernTextField(
                    controller: _firstNameController,
                    hintText: 'First Name',
                    validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ModernTextField(
                    controller: _middleNameController,
                    hintText: 'M.I.',
                  ),
                ),
              ],
            ),
            
            ModernTextField(
              controller: _lastNameController,
              hintText: 'Last Name',
              validator: (value) => value == null || value.isEmpty ? 'Required' : null,
            ),
            
            ModernTextField(
              controller: _emailController,
              hintText: 'LNU Email',
              validator: (value) {
                if (value == null || value.isEmpty) return 'Email is required';
                if (!value.trim().toLowerCase().endsWith('@lnu.edu.ph')) {
                  return 'Must end in @lnu.edu.ph';
                }
                return null;
              },
            ),
            
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2, 
                  child: TextFormField(
                    controller: _studentIdController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(7), 
                    ],
                    style: const TextStyle(color: Colors.black87),
                    decoration: InputDecoration(
                      hintText: 'Student ID',
                      hintStyle: const TextStyle(color: Colors.black54),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Required';
                      if (value.trim().length != 7) return 'Must be exactly 7 digits';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 10),
                
                Expanded(
                  flex: 3, 
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 15.0),
                    child: DropdownButtonFormField<String>(
                      isExpanded: true, 
                      menuMaxHeight: 300, 
                      initialValue: _selectedCourse,
                      hint: const Text('Course', style: TextStyle(color: Colors.black54, fontSize: 13)),
                      icon: const Icon(Icons.arrow_drop_down, color: Colors.black54),
                      dropdownColor: Colors.white,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
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

            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              style: const TextStyle(color: Colors.black87),
              onChanged: _evaluatePasswordStrength, // 🛠️ ADDED: Real-time listener
              decoration: InputDecoration(
                hintText: 'Password',
                hintStyle: const TextStyle(color: Colors.black54),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                errorStyle: TextStyle(color: Colors.red.shade300, fontWeight: FontWeight.w600),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.black54),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Password is required';
                if (_passwordStrength < 3) return 'Please meet all password requirements';
                return null;
              },
            ),
            
            // 🛠️ ADDED: The visual indicator below the password field
            _buildPasswordStrengthIndicator(),

            const SizedBox(height: 5), 
            
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              style: const TextStyle(color: Colors.black87),
              decoration: InputDecoration(
                hintText: 'Confirm Password',
                hintStyle: const TextStyle(color: Colors.black54),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility, color: Colors.black54),
                  onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Please confirm';
                if (value != _passwordController.text) return 'Passwords do not match';
                return null;
              },
            ),
            const SizedBox(height: 15),
            
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