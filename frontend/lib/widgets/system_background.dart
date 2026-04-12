import 'package:flutter/material.dart';

class SystemBackground extends StatelessWidget {
  final Widget child;
  final double opacity;
  final double darkenOverlay; 

  const SystemBackground({
    super.key, 
    required this.child, 
    this.opacity = 0.75, 
    this.darkenOverlay = 0.0, 
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        // 🛠️ CHANGED FROM BLACK TO LIGHT GREY! 
        // This keeps your login screen bright and clean behind the faded image.
        color: const Color(0xFFE5E5E5), 
        image: DecorationImage(
          image: const AssetImage('assets/images/system_bg.jpg'), 
          fit: BoxFit.cover, 
          opacity: opacity, 
          colorFilter: darkenOverlay > 0 
              ? ColorFilter.mode(
                  Colors.black.withOpacity(darkenOverlay), 
                  BlendMode.darken,
                )
              : null,
        ),
      ),
      child: child,
    );
  }
}