import 'package:flutter/foundation.dart'; 
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'auth_layout.dart'; 
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
  
  bool _agreedToTerms = false;

  XFile? _profileImage;
  Uint8List? _profileImageBytes;
  final ImagePicker _picker = ImagePicker();

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

  void _evaluatePasswordStrength(String password) {
    List<String> missing = [];
    int metConditions = 0;

    if (password.length >= 12) metConditions++; else missing.add("12+ characters");
    if (RegExp(r'[A-Z]').hasMatch(password)) metConditions++; else missing.add("uppercase letter");
    if (RegExp(r'[a-z]').hasMatch(password)) metConditions++; else missing.add("lowercase letter");
    if (RegExp(r'[0-9]').hasMatch(password)) metConditions++; else missing.add("number");
    if (RegExp(r'[.,?!@#\$%]').hasMatch(password)) metConditions++; else missing.add("special character (.,?!@#\$%)");

    int strength = 0;
    if (password.isEmpty) strength = 0;
    else if (metConditions <= 2) strength = 1; 
    else if (metConditions <= 4) strength = 2; 
    else if (metConditions == 5) strength = 3; 

    setState(() {
      _passwordStrength = strength;
      _missingRequirements = missing;
    });
  }

  Widget _buildPasswordStrengthIndicator() {
    if (_passwordController.text.isEmpty) return const SizedBox.shrink();

    Color strengthColor = Colors.grey;
    String strengthLabel = "";

    if (_passwordStrength == 1) { strengthColor = Colors.redAccent; strengthLabel = "Weak"; } 
    else if (_passwordStrength == 2) { strengthColor = Colors.orangeAccent; strengthLabel = "Fair"; } 
    else if (_passwordStrength == 3) { strengthColor = Colors.greenAccent; strengthLabel = "Strong"; }

    return Padding(
      padding: const EdgeInsets.only(top: 5.0, bottom: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Container(height: 6, decoration: BoxDecoration(color: _passwordStrength >= 1 ? strengthColor : Colors.white24, borderRadius: BorderRadius.circular(10)))),
              const SizedBox(width: 5),
              Expanded(child: Container(height: 6, decoration: BoxDecoration(color: _passwordStrength >= 2 ? strengthColor : Colors.white24, borderRadius: BorderRadius.circular(10)))),
              const SizedBox(width: 5),
              Expanded(child: Container(height: 6, decoration: BoxDecoration(color: _passwordStrength >= 3 ? strengthColor : Colors.white24, borderRadius: BorderRadius.circular(10)))),
              const SizedBox(width: 10),
              Text(strengthLabel, style: TextStyle(color: strengthColor, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
          if (_missingRequirements.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Text("Missing: ${_missingRequirements.join(', ')}", style: const TextStyle(color: Colors.orangeAccent, fontSize: 11, height: 1.3)),
            ),
        ],
      ),
    );
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, 
      builder: (BuildContext dialogContext) {
        bool hasScrolledToBottom = false;
        final ScrollController scrollController = ScrollController();

        return StatefulBuilder(
          builder: (context, setModalState) {
            scrollController.addListener(() {
              if (scrollController.position.pixels >= scrollController.position.maxScrollExtent - 20) {
                if (!hasScrolledToBottom) {
                  setModalState(() => hasScrolledToBottom = true);
                }
              }
            });

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.gavel, color: Color(0xFF000B6B)),
                  SizedBox(width: 10),
                  Text("Terms & Conditions", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF000B6B))),
                ],
              ),
              content: SizedBox(
                width: 500, 
                height: 400, 
                child: Column(
                  children: [
                    if (!hasScrolledToBottom)
                      Container(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: const Text("Please read to the bottom to agree.", style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    Expanded(
                      child: Scrollbar(
                        controller: scrollController,
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                          controller: scrollController,
                          padding: const EdgeInsets.only(right: 15.0),
                          child: const Text(
                            """TERMS AND CONDITIONS (T&C)

These Terms and Conditions constitute a legally binding contract between the Leyte Normal University (LNU) eMobile Voting System ("Service Provider", "We", "Us") and you, the user ("User", "Student"). By registering an account, you agree to be bound by these Terms.

1. ACCEPTABLE USE & RULES
You agree to use this system solely for the purpose of participating in official student elections. You are strictly prohibited from:
- Attempting to bypass security measures, hack, or exploit the system.
- Registering multiple accounts or using another student's identity.
- Spamming, harassing, or interfering with the voting process of others.
- Using any automated scripts, bots, or data scraping tools.
Violations of these rules may result in immediate academic disciplinary action.

2. INTELLECTUAL PROPERTY
All content within the LNU eMobile Voting app, including but not limited to the source code, design, logos, text, graphics, and databases, is the exclusive intellectual property of the developers and Leyte Normal University. You may not copy, distribute, or modify any part of this system.

3. LIMITATION OF LIABILITY
The Service Provider limits its legal responsibility for any damages, errors, or service interruptions. While we strive to maintain 100% uptime, we are not liable for technical glitches, network failures, or temporary outages that may prevent a vote from being cast at a specific time.

4. ACCOUNT TERMINATION
The University Electoral Board reserves the right to suspend, deactivate, or permanently delete user accounts without prior notice if a violation of these Terms is detected. Account termination includes the nullification of any fraudulent votes cast.

5. DATA PRIVACY & CONSENT
By registering, you consent to the collection and processing of your personal data (Name, Student ID, Course, Photo) strictly for voter verification and election integrity. Your data will be handled in compliance with the Data Privacy Act. Your actual ballot selections remain completely anonymous and encrypted.

6. GOVERNING LAW
These Terms shall be governed by and construed in accordance with the laws of the Republic of the Philippines and the institutional policies of Leyte Normal University. Any disputes arising from this agreement shall be subject to the exclusive jurisdiction of the university tribunal or relevant local courts.

7. DISCLAIMERS
This system is provided on an "AS IS" and "AS AVAILABLE" basis. We disclaim all warranties, whether express or implied, regarding the accuracy of third-party content and the absolute reliability of the service under extreme unforeseen circumstances.

By scrolling to the bottom and clicking "I Agree", you acknowledge that you have read, understood, and agreed to be legally bound by these Terms and Conditions.""",
                            style: TextStyle(fontSize: 13, height: 1.5, color: Colors.black87),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() => _agreedToTerms = false);
                    Navigator.pop(context);
                  },
                  child: const Text("Cancel", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hasScrolledToBottom ? const Color(0xFF000B6B) : Colors.grey.shade300,
                    foregroundColor: hasScrolledToBottom ? Colors.white : Colors.grey.shade500,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: hasScrolledToBottom
                      ? () {
                          setState(() => _agreedToTerms = true);
                          Navigator.pop(context);
                        }
                      : null,
                  child: const Text("I Agree"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_passwordStrength < 3) {
      setState(() => _errorMessage = "Please meet all password requirements before registering.");
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = "Passwords do not match!");
      return;
    }

    if (!_agreedToTerms) {
      setState(() => _errorMessage = "You must read and agree to the Terms and Conditions.");
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
          _agreedToTerms = false;
          
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

            // 🛠️ REPLACED: Now using native TextFormField with inputFormatters
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _firstNameController,
                    inputFormatters: [LengthLimitingTextInputFormatter(50)],
                    style: const TextStyle(color: Colors.black87),
                    decoration: InputDecoration(
                      hintText: 'First Name',
                      hintStyle: const TextStyle(color: Colors.black54),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                    validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _middleNameController,
                    inputFormatters: [LengthLimitingTextInputFormatter(50)],
                    style: const TextStyle(color: Colors.black87),
                    decoration: InputDecoration(
                      hintText: 'M.I.',
                      hintStyle: const TextStyle(color: Colors.black54),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            
            TextFormField(
              controller: _lastNameController,
              inputFormatters: [LengthLimitingTextInputFormatter(50)],
              style: const TextStyle(color: Colors.black87),
              decoration: InputDecoration(
                hintText: 'Last Name',
                hintStyle: const TextStyle(color: Colors.black54),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
              validator: (value) => value == null || value.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 15),
            
            TextFormField(
              controller: _emailController,
              inputFormatters: [LengthLimitingTextInputFormatter(100)],
              style: const TextStyle(color: Colors.black87),
              decoration: InputDecoration(
                hintText: 'LNU Email',
                hintStyle: const TextStyle(color: Colors.black54),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Email is required';
                if (!value.trim().toLowerCase().endsWith('@lnu.edu.ph')) {
                  return 'Must end in @lnu.edu.ph';
                }
                return null;
              },
            ),
            const SizedBox(height: 15),
            
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
              onChanged: _evaluatePasswordStrength, 
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

            FormField<bool>(
              validator: (value) => _agreedToTerms ? null : 'You must agree to the Terms and Conditions',
              builder: (FormFieldState<bool> state) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: _agreedToTerms,
                          onChanged: (value) {
                            if (value == true) {
                              _showTermsDialog();
                            } else {
                              setState(() => _agreedToTerms = false);
                            }
                          },
                          fillColor: WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.selected)) {
                              return Colors.amber; 
                            }
                            return Colors.white;
                          }),
                          checkColor: const Color(0xFF000B6B), 
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _showTermsDialog(),
                            child: const Text(
                              "I have read and agree to the Terms and Conditions",
                              style: TextStyle(
                                color: Colors.white, 
                                fontSize: 13,
                                decoration: TextDecoration.underline,
                                decorationColor: Colors.white
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (state.hasError)
                      Padding(
                        padding: const EdgeInsets.only(left: 12.0, bottom: 10.0),
                        child: Text(
                          state.errorText!,
                          style: TextStyle(color: Colors.red.shade300, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      )
                  ],
                );
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