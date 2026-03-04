import 'package:flutter/material.dart';

class AuthLayout extends StatelessWidget {
  final Widget formContent;

  const AuthLayout({super.key, required this.formContent});

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 800;

    return Scaffold(
      backgroundColor: isMobile ? Colors.white : const Color(0xFFE5E5E5),
      body: SafeArea(
        // Pass context to the web layout so it can measure screen height
        child: isMobile ? _buildMobileLayout() : _buildWebLayout(context),
      ),
    );
  }

  // ==========================================
  // MOBILE / ANDROID LAYOUT
  // ==========================================
  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            color: const Color(0xFF000B6B),
            padding: const EdgeInsets.all(15),
            child: const Row(
              children: [
                CircleAvatar(backgroundColor: Colors.white, radius: 18, child: Text('Logo', style: TextStyle(color: Colors.black, fontSize: 10))),
                SizedBox(width: 15),
                Text('Leyte Normal University\nSystem Name', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 60, height: 60, decoration: const BoxDecoration(color: Colors.grey, shape: BoxShape.circle)),
              const SizedBox(width: 10),
              Container(width: 60, height: 60, decoration: const BoxDecoration(color: Colors.grey, shape: BoxShape.circle)),
            ],
          ),
          const SizedBox(height: 15),
          const Text('SLOGAN/WELCOME WORDS\nPUT A PICTURE HERE AS WELL', textAlign: TextAlign.center, style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
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
          const Padding(
            padding: EdgeInsets.all(20.0),
            child: Text('V1.2026.03126 | LNUVotingSystem', style: TextStyle(color: Colors.grey, fontSize: 12)),
          )
        ],
      ),
    );
  }

  // ==========================================
  // WEB / CHROME LAYOUT (NOW FULLY SCROLLABLE)
  // ==========================================
  Widget _buildWebLayout(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        // Ensures the layout covers the whole screen even if content is small
        constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Header
            Container(
              color: const Color(0xFF000B6B), 
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      CircleAvatar(backgroundColor: Colors.white, radius: 20, child: Text('Logo', style: TextStyle(color: Colors.black, fontSize: 12))),
                      SizedBox(width: 15),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Leyte Normal University', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          Text('(System Name)', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      )
                    ],
                  ),
                  Row(
                    children: [
                      InteractiveNavText(text: 'ABOUT US', onTap: () {}),
                      const SizedBox(width: 30),
                      InteractiveNavText(text: 'FAQs', onTap: () {}),
                    ],
                  )
                ],
              ),
            ),
            
            // Body Area (No longer restricted by height constraints!)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start, // Allows form to grow naturally
                children: [
                  Expanded(
                    child: Container(
                      height: 500, // Fixed height for the banner
                      margin: const EdgeInsets.only(right: 40),
                      decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(12)),
                      child: const Center(child: Text('SLOGAN/WELCOME WORDS\nPUT A PICTURE HERE AS WELL', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, color: Colors.black54, fontWeight: FontWeight.bold))),
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
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 20, offset: const Offset(0, 10))],
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
              child: Text('V1.2026.03126 | LNUVotingSystem', style: TextStyle(color: Colors.grey, fontSize: 14)),
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
        child: Text(widget.text, style: TextStyle(fontSize: 16, color: isHovered ? Colors.yellow : Colors.white, fontWeight: FontWeight.w500)),
      ),
    );
  }
}