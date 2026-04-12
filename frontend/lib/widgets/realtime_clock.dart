import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';

class RealtimeClock extends StatefulWidget {
  final Color textColor;
  final bool isCenterAligned;

  const RealtimeClock({
    super.key, 
    this.textColor = Colors.black87,
    this.isCenterAligned = false,
  });

  @override
  State<RealtimeClock> createState() => _RealtimeClockState();
}

class _RealtimeClockState extends State<RealtimeClock> {
  late Timer _timer;
  DateTime _currentTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Update the time every single second
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _currentTime = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel(); // Stop the timer when widget is destroyed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Formats: 10:42:47 AM | April 12, 2026
    String formattedTime = DateFormat('hh:mm:ss a').format(_currentTime);
    String formattedDate = DateFormat('MMMM dd, yyyy').format(_currentTime);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: widget.isCenterAligned ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(
          formattedTime, 
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: widget.textColor, letterSpacing: 1.2),
        ),
        Text(
          formattedDate, 
          style: TextStyle(fontSize: 13, color: widget.textColor.withOpacity(0.8)),
        ),
      ],
    );
  }
}