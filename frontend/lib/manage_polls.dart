import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_config.dart';
// import 'responsive_screen.dart';

class ManagePolls extends StatefulWidget {
  const ManagePolls({super.key});

  @override
  State<ManagePolls> createState() => _ManagePollsState();
}

class _ManagePollsState extends State<ManagePolls> {
  List<dynamic> _polls = [];
  bool _isLoading = true;
  bool _showArchived = false;

  @override
  void initState() {
    super.initState();
    _fetchPolls();
  }

  Future<void> _fetchPolls() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/polls'));
      if (response.statusCode == 200) {
        setState(() {
          _polls = jsonDecode(response.body);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to load polls')));
    }
  }

  Future<void> _savePoll(int? pollId, String title, DateTime start, DateTime end) async {
    final isUpdating = pollId != null;
    final url = isUpdating ? '${ApiConfig.baseUrl}/api/polls/$pollId' : '${ApiConfig.baseUrl}/api/polls';
        
    final body = jsonEncode({
      'title': title,
      'start_time': start.toIso8601String(),
      'end_time': end.toIso8601String(),
      'status': 'Draft' // Always default to draft when saving/editing
    });

    try {
      final response = isUpdating
          ? await http.put(Uri.parse(url), headers: {'Content-Type': 'application/json'}, body: body)
          : await http.post(Uri.parse(url), headers: {'Content-Type': 'application/json'}, body: body);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isUpdating ? 'Poll updated!' : 'Poll created!')));
        _fetchPolls();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Server error')));
    }
  }

  // --- NEW PUBLISH FUNCTION ---
  Future<void> _publishPoll(int pollId) async {
    // Optional: You could add a confirmation dialog here before publishing
    try {
      final response = await http.put(Uri.parse('${ApiConfig.baseUrl}/api/polls/$pollId/publish'));
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Poll officially published!')));
        _fetchPolls();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error publishing poll')));
    }
  }

  Future<void> _deletePoll(int pollId) async {
    try {
      final response = await http.delete(Uri.parse('${ApiConfig.baseUrl}/api/polls/$pollId'));
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Poll deleted')));
        _fetchPolls();
      }
    } catch (e) {}
  }

  // ===== ADD THESE BELOW _deletePoll() =====

  void _confirmDelete(int pollId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Confirm Delete"),
          content: const Text("Are you sure? This cannot be undone."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.pop(context);
                _deletePoll(pollId);
              },
              child: const Text("Confirm Delete"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _toggleArchivePoll(int pollId, bool currentlyArchived) async {
    final url = currentlyArchived
        ? '${ApiConfig.baseUrl}/api/polls/$pollId/unarchive'
        : '${ApiConfig.baseUrl}/api/polls/$pollId/archive';

    try {
      final response = await http.put(Uri.parse(url));
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(currentlyArchived ? 'Poll unarchived' : 'Poll archived'),
          ),
        );
        _fetchPolls(); // reload from backend
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to toggle archive status')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Server error')),
      );
    }
  }

  // Future<void> _archivePoll(int pollId) async {
  //   try {
  //     final response = await http.put(
  //       Uri.parse('${ApiConfig.baseUrl}/api/polls/$pollId/archive'),
  //     );

  //     if (response.statusCode == 200) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(content: Text('Poll archived')),
  //       );
  //       _fetchPolls();
  //     }
  //   } catch (e) {}
  // }

  // Future<void> _unarchivePoll(int pollId) async {
  //   try {
  //     final response = await http.put(
  //       Uri.parse('${ApiConfig.baseUrl}/api/polls/$pollId'),
  //       headers: {'Content-Type': 'application/json'},
  //       body: jsonEncode({'is_archived': false}),
  //     );

  //     if (response.statusCode == 200) {
  //       // Update local list so UI reflects the change immediately
  //       setState(() {
  //         _polls = _polls.map((poll) {
  //           if (poll['poll_id'] == pollId) {
  //             poll['is_archived'] = false; // Mark as active
  //           }
  //           return poll;
  //         }).toList();
  //       });

  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(content: Text('Poll unarchived')),
  //       );
  //     } else {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('Failed to unarchive poll (code ${response.statusCode})')),
  //       );
  //     }
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Failed to unarchive poll')),
  //     );
  //   }
  // }

  void _openPollDetails(int pollId, String title) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: FutureBuilder(
            future: http.get(Uri.parse('${ApiConfig.baseUrl}/api/candidates/$pollId')),
            builder: (context, snapshot) {

              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(30),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final List candidates = jsonDecode(snapshot.data!.body);

              Map<String, List<dynamic>> grouped = {};
              for (var c in candidates) {
                String party = c['party_name'] ?? 'Independent';
                grouped.putIfAbsent(party, () => []).add(c);
              }

              return Container(
                padding: const EdgeInsets.all(20),
                width: 500,
                height: 500,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),

                    Expanded(
                      child: ListView(
                        children: grouped.entries.map((entry) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(entry.key,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF000B6B),
                                ),
                              ),
                              const SizedBox(height: 10),

                              ...entry.value.map((candidate) {
                                return ListTile(
                                  leading: const Icon(Icons.person),
                                  title: Text(candidate['name']),
                                  subtitle: Text(candidate['position']),
                                );
                              }),

                              const Divider(),
                            ],
                          );
                        }).toList(),
                      ),
                    ),

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Close"),
                      ),
                    )
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<DateTime?> _pickDateTime(DateTime? initialDate) async {
    DateTime? date = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (date == null) return null;
    if (!mounted) return null;
    TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate ?? DateTime.now()),
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  void _showPollDialog({Map<String, dynamic>? existingPoll}) {
    final TextEditingController titleController = TextEditingController(text: existingPoll?['title'] ?? '');
    DateTime? startTime = existingPoll != null ? DateTime.parse(existingPoll['start_time']) : null;
    DateTime? endTime = existingPoll != null ? DateTime.parse(existingPoll['end_time']) : null;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(existingPoll == null ? 'Create New Poll (Draft)' : 'Edit Poll'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Poll Title', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 20),
                    ListTile(
                      title: const Text('Start Time'),
                      subtitle: Text(startTime?.toString().substring(0, 16) ?? 'Select start date & time'),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final dt = await _pickDateTime(startTime);
                        if (dt != null) setDialogState(() => startTime = dt);
                      },
                    ),
                    ListTile(
                      title: const Text('End Time'),
                      subtitle: Text(endTime?.toString().substring(0, 16) ?? 'Select end date & time'),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final dt = await _pickDateTime(endTime);
                        if (dt != null) setDialogState(() => endTime = dt);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () {
                    if (titleController.text.isEmpty || startTime == null || endTime == null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
                      return;
                    }
                    Navigator.pop(context);
                    _savePoll(existingPoll?['poll_id'], titleController.text, startTime!, endTime!);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF000B6B), foregroundColor: Colors.white),
                  child: const Text('Save Poll'),
                )
              ],
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Manage Polls", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              Spacer(),
              IconButton(
                icon: Icon(
                  _showArchived ? Icons.list : Icons.archive,
                  color: Colors.black,
                ),
                tooltip: _showArchived ? "Show Active Polls" : "Show Archived Polls",
                onPressed: () {
                  setState(() {
                    _showArchived = !_showArchived;
                  });
                },
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text("Create Poll"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
                onPressed: () => _showPollDialog(),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _polls.isEmpty 
                  ? const Center(child: Text('No polls created yet.'))
                  : ListView.builder(
                      itemCount: _polls.length,
                      itemBuilder: (context, index) {
                        final poll = _polls[index];
                        final bool isPublished = poll['is_published'] == true || poll['is_published'] == 1;
                        final bool isArchived = poll['is_archived'] == true || poll['is_archived'] == 1;

                        // Skip items depending on toggle
                        if (_showArchived != isArchived) {
                          return const SizedBox.shrink();
                        }

                        return InkWell(
                          onTap: () => _openPollDetails(poll['poll_id'], poll['title']),
                          child: Card(
                            margin: const EdgeInsets.only(bottom: 15),
                            child: ListTile(
                            title: Text(poll['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Start: ${poll['start_time'].toString().substring(0, 16)}\nEnd: ${poll['end_time'].toString().substring(0, 16)}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // If it is not published yet, show the Publish button
                                // ACTION BUTTONS LOGIC
                                if (!isPublished) ...[
                                  // ✅ DRAFT POLL ACTIONS

                                  // 🔥 PUBLISH BUTTON (ONLY HERE)
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.campaign, size: 18),
                                    label: const Text("Publish"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () => _publishPoll(poll['poll_id']),
                                  ),

                                  const SizedBox(width: 8),

                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    tooltip: "Edit Poll",
                                    onPressed: () => _showPollDialog(existingPoll: poll),
                                  ),

                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    tooltip: "Delete Poll",
                                    onPressed: () => _confirmDelete(poll['poll_id']),
                                  ),
                                ] else ...[
                                  // ✅ PUBLISHED POLL ACTIONS

                                  // Show published badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.green),
                                    ),
                                    child: const Text(
                                      "PUBLISHED",
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(width: 10),

                                  // Archive / Unarchive
                                  // IconButton(
                                  //   icon: Icon(
                                  //     isArchived ? Icons.unarchive : Icons.archive,
                                  //     color: Colors.grey,
                                  //   ),
                                  //   tooltip: isArchived ? "Unarchive Poll" : "Archive Poll",
                                  //   onPressed: () => _toggleArchivePoll(
                                  //     poll['poll_id'],
                                  //     isArchived,
                                  //   ),
                                  // ),
                                ],
                                  
                                const SizedBox(width: 10),
                                
                                // NEW INFO SUMMARY BUTTON ADDED HERE
                                IconButton(
                                  icon: const Icon(Icons.info, color: Colors.amber), 
                                  onPressed: () async {
                                    final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/polls/${poll['poll_id']}/summary'));
                                    if (res.statusCode == 200) {
                                      final data = jsonDecode(res.body);
                                      if (!mounted) return;
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: Text(poll['title']),
                                          content: Text("Total Candidates: ${data['total_candidates']}\nParticipating Parties: ${data['total_parties']}"),
                                          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close"))],
                                        )
                                      );
                                    }
                                  }
                                ),

                                IconButton(
                                  icon: Icon(
                                    poll['is_archived'] == true || poll['is_archived'] == 1
                                        ? Icons.unarchive
                                        : Icons.archive,
                                    color: poll['is_archived'] == true || poll['is_archived'] == 1
                                        ? Colors.green
                                        : Colors.orange,
                                  ),
                                  tooltip: poll['is_archived'] == true || poll['is_archived'] == 1
                                      ? 'Unarchive Poll'
                                      : 'Archive Poll',
                                  onPressed: () => _toggleArchivePoll(
                                    poll['poll_id'],
                                    poll['is_archived'] == true || poll['is_archived'] == 1,
                                  ),
                                ),

                              //  if (!isPublished && !isArchived)
                              //   IconButton(
                              //     icon: const Icon(Icons.edit, color: Colors.blue),
                              //     onPressed: () => _showPollDialog(existingPoll: poll),
                              //   ),

                              // if (!isPublished && !isArchived)
                              //   IconButton(
                              //     icon: const Icon(Icons.delete, color: Colors.red),
                              //     onPressed: () => _deletePoll(poll['poll_id']),
                              //   ),

                              // if (isArchived)
                              //   IconButton(
                              //     icon: const Icon(Icons.unarchive, color: Colors.orange),
                              //     tooltip: 'Unarchive Poll',
                              //     onPressed: () => _unarchivePoll(poll['poll_id']),
                              //   ),
                              ],
                            ),
                          ),
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