import 'package:flutter/material.dart';

class ResponsiveScreen extends StatelessWidget {
  final Widget child;

  const ResponsiveScreen({super.key, required this.child});

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600 &&
      MediaQuery.of(context).size.width < 1024;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1024;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isDesktop(context) ? 1200 : double.infinity,
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile(context) ? 12 : 24,
                  vertical: 16,
                ),
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}