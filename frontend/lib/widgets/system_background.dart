import 'package:flutter/material.dart';
import 'dart:ui'; // REQUIRED: For ImageFilter.blur

class SystemBackground extends StatelessWidget {
  final Widget child;
  final double opacity;
  final double darkenOverlay; 
  final bool isFrosted; // NEW: Switch for frosted glass

  const SystemBackground({
    super.key, 
    required this.child, 
    this.opacity = 0.75, 
    this.darkenOverlay = 0.0, 
    this.isFrosted = false, // DEFAULT: False (Login/Register stays clear)
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFE5E5E5), 
        image: DecorationImage(
          image: const AssetImage('assets/images/system_bg.jpg'), 
          fit: BoxFit.cover, 
          opacity: opacity, 
          // If NOT frosted, apply tint directly to the image
          colorFilter: (!isFrosted && darkenOverlay > 0)
              ? ColorFilter.mode(
                  Colors.black.withOpacity(darkenOverlay), 
                  BlendMode.darken,
                )
              : null,
        ),
      ),
      // 🛠️ CONDITIONAL: Apply blur ONLY if isFrosted is true
      child: isFrosted
          ? ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0), // Blur intensity
                child: Container(
                  // Apply tint overlay OVER the blur
                  color: darkenOverlay > 0
                      ? Colors.black.withOpacity(darkenOverlay)
                      : Colors.transparent,
                  child: child,
                ),
              ),
            )
          : child, // Otherwise, just return the child normally
    );
  }
}