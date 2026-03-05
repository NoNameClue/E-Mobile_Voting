import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddCandidatePage extends StatefulWidget {

  final int pollId;

  AddCandidatePage({required this.pollId});

  @override
  _AddCandidatePageState createState() => _AddCandidatePageState();
}

class _AddCandidatePageState extends State<AddCandidatePage> {

  final nameController = TextEditingController();
  final descriptionController = TextEditingController();

  Future<void> addCandidate() async {

    final response = await http.post(
      Uri.parse("http://127.0.0.1:8000/api/candidates"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "poll_id": widget.pollId,
        "name": nameController.text,
        "description": descriptionController.text
      }),
    );

    if (response.statusCode == 200) {

      Navigator.pop(context, true);

    } else {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to add candidate"))
      );

    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: Text("Add Candidate")),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [

            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: "Candidate Name"),
            ),

            SizedBox(height: 10),

            TextField(
              controller: descriptionController,
              decoration: InputDecoration(labelText: "Description"),
            ),

            SizedBox(height: 20),

            ElevatedButton(
              onPressed: addCandidate,
              child: Text("Add Candidate"),
            )

          ],
        ),
      ),
    );
  }
}