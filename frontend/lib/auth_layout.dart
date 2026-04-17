import 'package:flutter/material.dart';
import 'widgets/realtime_clock.dart';
import 'widgets/system_background.dart';

class AuthLayout extends StatelessWidget {
  final Widget formContent;

  const AuthLayout({super.key, required this.formContent});

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 800;

    return Scaffold(
      backgroundColor: Colors.transparent, 
      body: SystemBackground(
        child: SafeArea(
          child: isMobile ? _buildMobileLayout() : _buildWebLayout(context),
        ),
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
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
            child: Row(
              children: [
                // 🛠️ FORCED LARGER LOGO FOR MOBILE
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: const DecorationImage(
                      image: AssetImage('assets/images/lnu_logo.png'),
                      fit: BoxFit.cover, // Forces it to fill the box
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                const Expanded(
                  child: Text('Leyte Normal University\n(System Name)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                ),
                const RealtimeClock(textColor: Colors.white, isCenterAligned: false),
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
  // WEB / CHROME LAYOUT 
  // ==========================================
  Widget _buildWebLayout(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
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
                  Row(
                    children: [
                      // 🛠️ FORCED MASSIVE LOGO FOR WEB
                      Container(
                        width: 85,
                        height: 85,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: const DecorationImage(
                            image: AssetImage('assets/images/lnu_logo.png'),
                            fit: BoxFit.cover, // Forces it to fill the box
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Leyte Normal University', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                          Text('(System Name)', style: TextStyle(color: Colors.white70, fontSize: 14)),
                        ],
                      )
                    ],
                  ),
                  Row(
                    children: [
                      const RealtimeClock(textColor: Colors.white, isCenterAligned: false),
                      const SizedBox(width: 40), 
                      InteractiveNavText(text: 'ABOUT US', onTap: () {}),
                      const SizedBox(width: 30),
                      InteractiveNavText(text: 'FAQs', onTap: () {}),
                    ],
                  )
                ],
              ),
            ),
            
            // Body Area
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      height: 500, 
                      margin: const EdgeInsets.only(right: 40),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(12)),
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
              child: Text('V1.2026.03126 | LNUVotingSystem', style: TextStyle(color: Colors.white, fontSize: 14)),
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