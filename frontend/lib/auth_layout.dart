import 'package:flutter/material.dart';
import 'widgets/realtime_clock.dart';
import 'widgets/system_background.dart';

class AuthLayout extends StatelessWidget {
  final Widget formContent;

  const AuthLayout({super.key, required this.formContent});

  void _showAboutUs(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Color(0xFF000B6B)),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                "About Us", 
                style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF000B6B)),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "The Leyte Normal University (LNU) eMobile Voting System is a modern, secure, and accessible platform designed to streamline student elections. It ensures election integrity, eliminates manual tallying errors, and provides a seamless voting experience.",
                  style: TextStyle(fontSize: 14, height: 1.5),
                ),
                const SizedBox(height: 20),
                const Text("Meet the Team", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF000B6B))),
                const Divider(),
                _buildTeamMember("Dorothy A. Magdaraog", "Project Manager / UI & UX Designer / Full-Stack Developer"),
                _buildTeamMember("Carl David T. Pura", "Lead Developer / Full-Stack Developer / QA Tester"),
                _buildTeamMember("Jasmine T. Villaruel", "Full-Stack Developer / Database Administrator"),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showFAQs(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.help_outline, color: Color(0xFF000B6B)),
            SizedBox(width: 10),
            Expanded( 
              child: Text(
                "Frequently Asked Questions", 
                style: TextStyle(
                  color: Color(0xFF000B6B), 
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2, 
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildFAQItem("How do I register to vote?", "Click on 'Sign Up' and use your official LNU Email and Student ID. Once your details are verified by the system, you can log in."),
                _buildFAQItem("Is my vote strictly confidential?", "Yes. The system encrypts all ballot submissions. Administrators can see THAT you voted, but never WHO you voted for."),
                _buildFAQItem("Can I change my vote after submitting?", "No. To maintain election integrity, all submitted ballots are final and cannot be modified or retracted."),
                _buildFAQItem("What if I forgot my password?", "Please contact the M.I.S or system administrators to request a secure password reset."),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamMember(String name, String role) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.person, size: 20, color: Colors.amber),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(role, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Q: $question", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
          const SizedBox(height: 4),
          Text("A: $answer", style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.4)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 800;

    return Scaffold(
      backgroundColor: Colors.transparent, 
      body: SystemBackground(
        child: SafeArea(
          child: isMobile ? _buildMobileLayout(context) : _buildWebLayout(context),
        ),
      ),
    );
  }

  // MOBILE / ANDROID LAYOUT
  Widget _buildMobileLayout(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [

          // MOBILE HEADER: SLIMMED DOWN
          Container(
            color: const Color(0xFF000B6B),
            // CHANGED: Reduced vertical padding from 15 to 4
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 4), 
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60, // Logo height untouched
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: const DecorationImage(
                      image: AssetImage('assets/images/lnu_logo.png'),
                      fit: BoxFit.cover, 
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                const Expanded(
                  child: Text('Leyte Normal University\n(eMobile Voting)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                ),
                const RealtimeClock(textColor: Colors.white, isCenterAligned: false),
              ],
            ),
          ),
          const SizedBox(height: 30),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'assets/images/slogan_image_mobile.png', 
                fit: BoxFit.contain, 
                width: double.infinity, 
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: const Color(0xFF000B6B),
              borderRadius: BorderRadius.circular(15),
            ),
            child: formContent,
          ),
          
          // Mobile Footer Links
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () => _showAboutUs(context),
                      child: const Text("About Us", style: TextStyle(color: Colors.white70, decoration: TextDecoration.underline)),
                    ),
                    const Text("|", style: TextStyle(color: Colors.white54)),
                    TextButton(
                      onPressed: () => _showFAQs(context),
                      child: const Text("FAQs", style: TextStyle(color: Colors.white70, decoration: TextDecoration.underline)),
                    ),
                  ],
                ),
                const Text('V1.0.1 | LNUVotingSystem', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          )
        ],
      ),
    );
  }

  // WEB / CHROME LAYOUT 
 
  Widget _buildWebLayout(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [

            Container(
              color: const Color(0xFF000B6B), 
              // CHANGED: Reduced vertical padding from 15 to 4. 
              // Note: If you want it even slimmer, change 'vertical: 4' to 'vertical: 0'.
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 4), 
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 85, // Logo width untouched
                        height: 85, // Logo height untouched
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: const DecorationImage(
                            image: AssetImage('assets/images/lnu_logo.png'),
                            fit: BoxFit.cover, 
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Leyte Normal University', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)), // Text size untouched
                          Text('(eMobile Voting)', style: TextStyle(color: Colors.white70, fontSize: 14)), // Text size untouched
                        ],
                      )
                    ],
                  ),
                  Row(
                    children: [
                      const RealtimeClock(textColor: Colors.white, isCenterAligned: false),
                      const SizedBox(width: 40), 
                      InteractiveNavText(text: 'ABOUT US', onTap: () => _showAboutUs(context)),
                      const SizedBox(width: 30),
                      InteractiveNavText(text: 'FAQs', onTap: () => _showFAQs(context)),
                    ],
                  )
                ],
              ),
            ),
            
            // Body Area
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(right: 40),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 450), 
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Image.asset(
                              'assets/images/slogan_image.png', 
                              fit: BoxFit.contain, 
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  Expanded(
                    child: Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 450),
                        padding: const EdgeInsets.all(40),
                        decoration: BoxDecoration(
                          color: const Color(0xFF000B6B),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 20, offset: const Offset(0, 10))],
                        ),
                        child: formContent, 
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Footer
            const Padding(
              padding: EdgeInsets.all(15.0),
              child: Text('V1.0.1 | LNUVotingSystem', style: TextStyle(color: Colors.white, fontSize: 14)),
            )
          ],
        ),
      ),
    );
  }
}

class InteractiveNavText extends StatefulWidget {
  final String text;
  final VoidCallback onTap;
  const InteractiveNavText({super.key, required this.text, required this.onTap});
  @override
  State<InteractiveNavText> createState() => _InteractiveNavTextState();
}

class _InteractiveNavTextState extends State<InteractiveNavText> {
  bool isHovered = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Text(widget.text, style: TextStyle(fontSize: 16, color: isHovered ? Colors.amber : Colors.white, fontWeight: FontWeight.w500)),
      ),
    );
  }
}