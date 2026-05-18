import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'api_config.dart';

class StaffApplicationsPage extends StatefulWidget {
  const StaffApplicationsPage({super.key});

  @override
  State<StaffApplicationsPage> createState() =>
      _StaffApplicationsPageState();
}

class _StaffApplicationsPageState
    extends State<StaffApplicationsPage> {

  List applications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchApplications();
  }

  Future<void> fetchApplications() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/staff-applications'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        applications = jsonDecode(response.body);
        isLoading = false;
      });
    }
  }

  Future<void> approveApplication(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';

    final response = await http.put(
      Uri.parse(
        '${ApiConfig.baseUrl}/api/staff-applications/$id/approve',
      ),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      fetchApplications();
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> declineApplication(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';

    final response = await http.put(
      Uri.parse(
        '${ApiConfig.baseUrl}/api/staff-applications/$id/decline',
      ),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      fetchApplications();
      if (mounted) Navigator.pop(context);
    }
  }

  void showApplicationModal(dynamic app) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(app['student_name']),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [

                  Text(
                    "Student Number",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(app['student_number']),

                  const SizedBox(height: 20),

                  Text(
                    "Intent",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(app['intent']),

                  const SizedBox(height: 20),

                  Text(
                    "Qualifications",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(app['qualifications'] ?? ''),

                  const SizedBox(height: 20),

                  Text(
                    "Status: ${app['status']}",
                    style: TextStyle(
                      color: app['status'] == 'Approved'
                          ? Colors.green
                          : app['status'] == 'Declined'
                              ? Colors.red
                              : Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            if (app['status'] == 'Pending') ...[
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => declineApplication(
                  app['application_id'],
                ),
                child: const Text("Decline"),
              ),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => approveApplication(
                  app['application_id'],
                ),
                child: const Text("Approve"),
              ),
            ],

            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  Color getStatusColor(String status) {
    switch (status) {
      case "Approved":
        return Colors.green;
      case "Declined":
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            "Staff Applications",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 30),

          Expanded(
            child: isLoading
                ? const Center(
                    child:
                        CircularProgressIndicator(),
                  )
                : applications.isEmpty
                    ? const Center(
                        child: Text(
                          "No applications found",
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount:
                            applications.length,
                        itemBuilder:
                            (context, index) {

                          final app =
                              applications[index];

                          return Card(
                            margin:
                                const EdgeInsets.only(
                              bottom: 15,
                            ),
                            child: ListTile(
                              onTap: () =>
                                  showApplicationModal(
                                      app),

                              title: Text(
                                app['student_name'],
                                style: const TextStyle(
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),

                              subtitle: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,
                                children: [
                                  Text(
                                      app['student_number']),
                                  const SizedBox(
                                      height: 5),
                                  Text(
                                    app['status'],
                                    style: TextStyle(
                                      color:
                                          getStatusColor(
                                        app['status'],
                                      ),
                                      fontWeight:
                                          FontWeight
                                              .bold,
                                    ),
                                  ),
                                ],
                              ),

                              trailing:
                                  app['status'] ==
                                          'Pending'
                                      ? Row(
                                          mainAxisSize:
                                              MainAxisSize
                                                  .min,
                                          children: [

                                            ElevatedButton(
                                              style:
                                                  ElevatedButton
                                                      .styleFrom(
                                                backgroundColor:
                                                    Colors.red,
                                                foregroundColor:
                                                    Colors.white,
                                              ),
                                              onPressed:
                                                  () =>
                                                      declineApplication(
                                                app[
                                                    'application_id'],
                                              ),
                                              child:
                                                  const Text(
                                                "Decline",
                                              ),
                                            ),

                                            const SizedBox(
                                                width:
                                                    10),

                                            ElevatedButton(
                                              style:
                                                  ElevatedButton
                                                      .styleFrom(
                                                backgroundColor:
                                                    Colors.green,
                                                foregroundColor:
                                                    Colors.white,
                                              ),
                                              onPressed:
                                                  () =>
                                                      approveApplication(
                                                app[
                                                    'application_id'],
                                              ),
                                              child:
                                                  const Text(
                                                "Approve",
                                              ),
                                            ),
                                          ],
                                        )
                                      : null,
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}