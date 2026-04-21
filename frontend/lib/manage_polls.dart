import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_config.dart';

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

  // 🛠️ THE FIX: Added 'isPublished' to the parameters and JSON body to satisfy Python's PollCreate schema
  Future<void> _savePoll(int? pollId, String title, DateTime start, DateTime end, bool isPublished) async {
    final isUpdating = pollId != null;
    final url = isUpdating ? '${ApiConfig.baseUrl}/api/polls/$pollId' : '${ApiConfig.baseUrl}/api/polls';
        
    final body = jsonEncode({
      'title': title,
      'start_time': start.toIso8601String(), // ISO-8601 format required by Python
      'end_time': end.toIso8601String(),
      'is_published': isPublished,           // 🛠️ REQUIRED: Python 422 error fix
    });

    try {
      final response = isUpdating
          ? await http.put(Uri.parse(url), headers: {'Content-Type': 'application/json'}, body: body)
          : await http.post(Uri.parse(url), headers: {'Content-Type': 'application/json'}, body: body);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isUpdating ? 'Poll updated!' : 'Poll created!')));
        _fetchPolls();
      } else {
        // 🛠️ DEBUG ADDITION: This will print the exact reason FastAPI rejected it to your terminal
        print("ERROR DETAILS: ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to save poll. Check console for details.')));
      }
    } catch (e) {
      print("SERVER ERROR: $e");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Server error')));
    }
  }

  Future<void> _publishPoll(int pollId) async {
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
        _fetchPolls(); 
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to toggle archive status')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Server error')),
      );
    }
  }

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
    
    // 🛠️ THE FIX: Extract current publish status so edits don't accidentally unpublish a poll
    bool isPublished = existingPoll != null ? (existingPoll['is_published'] == true || existingPoll['is_published'] == 1) : false;

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
                    // 🛠️ THE FIX: Pass isPublished boolean to the function
                    _savePoll(existingPoll?['poll_id'], titleController.text, startTime!, endTime!, isPublished);
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
    bool hasActivePoll = _polls.any((poll) {
      if (poll['end_time'] == null) return false;
      DateTime endDate = DateTime.parse(poll['end_time']);
      return endDate.isAfter(DateTime.now());
    });

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Manage Polls", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              Spacer(),
              IconButton(
                icon: Icon(
                  _showArchived ? Icons.list : Icons.archive,
                  color: Colors.white
                ),
                tooltip: _showArchived ? "Show Active Polls" : "Show Archived Polls",
                onPressed: () {
                  setState(() {
                    _showArchived = !_showArchived;
                  });
                },
              ),
              const SizedBox(width: 10),
              
              Tooltip(
                message: hasActivePoll 
                  ? "An election is already active or drafted. Please wait until it ends or delete it." 
                  : "Create a new election",
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text("Create Poll"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hasActivePoll ? Colors.grey.shade500 : Colors.amber, 
                    foregroundColor: hasActivePoll ? Colors.grey.shade700 : Colors.white
                  ),
                  onPressed: hasActivePoll ? null : () => _showPollDialog(),
                ),
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
                        
                        // --- 🛠️ EXPIRED CHECK ---
                        bool isExpired = false;
                        if (poll['end_time'] != null) {
                          DateTime endTime = DateTime.parse(poll['end_time']);
                          isExpired = endTime.isBefore(DateTime.now());
                        }
                        // -------------------------

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
                                if (!isPublished) ...[
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
                                  // --- 🛠️ RED EXPIRED BADGE vs GREEN PUBLISHED BADGE ---
                                  if (isExpired)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.red),
                                      ),
                                      child: const Text(
                                        "EXPIRED",
                                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                    )
                                  else
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.green),
                                      ),
                                      child: const Text(
                                        "PUBLISHED",
                                        style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                    ),
                                  const SizedBox(width: 10),
                                  // -----------------------------------------------------
                                ],
                                  
                                const SizedBox(width: 10),
                                
                                IconButton(
                                  icon: const Icon(Icons.info, color: Colors.amber), 
                                  onPressed: () async {
                                    final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/polls/${poll['poll_id']}/report'));
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