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

  // 🛠️ Formats raw ISO string from database to "Month DD, YYYY at HH:MM AM/PM"
  String _formatDateString(String? isoString) {
    if (isoString == null) return 'N/A';
    try {
      DateTime dt = DateTime.parse(isoString).toLocal();
      return _formatDateTimeObj(dt);
    } catch (e) {
      return isoString; 
    }
  }

  // 🛠️ Formats Flutter DateTime objects for the Dialog menus
  String _formatDateTimeObj(DateTime? dt) {
    if (dt == null) return 'Select date & time';
    List<String> months = [
      'January', 'February', 'March', 'April', 'May', 'June', 
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    String amPm = dt.hour >= 12 ? 'PM' : 'AM';
    int hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    String minute = dt.minute.toString().padLeft(2, '0');
    return "${months[dt.month - 1]} ${dt.day}, ${dt.year} at $hour:$minute $amPm";
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

  Future<void> _savePoll(int? pollId, String title, DateTime start, DateTime end, bool isPublished) async {
    final isUpdating = pollId != null;
    final url = isUpdating ? '${ApiConfig.baseUrl}/api/polls/$pollId' : '${ApiConfig.baseUrl}/api/polls';
        
    final body = jsonEncode({
      'title': title,
      'start_time': start.toIso8601String(), 
      'end_time': end.toIso8601String(),
      'is_published': isPublished,           
    });

    try {
      final response = isUpdating
          ? await http.put(Uri.parse(url), headers: {'Content-Type': 'application/json'}, body: body)
          : await http.post(Uri.parse(url), headers: {'Content-Type': 'application/json'}, body: body);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isUpdating ? 'Poll updated!' : 'Poll created!')));
        _fetchPolls();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to save poll. Check console for details.')));
      }
    } catch (e) {
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

  // 🛠️ NEW: Publish Summary Interceptor Dialog
  void _showPublishConfirmationDialog(int pollId, String title) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text("Publish Election: $title", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF000B6B))),
          content: SizedBox(
            width: 500,
            height: 400,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50, 
                    borderRadius: BorderRadius.circular(8), 
                    border: Border.all(color: Colors.amber.shade400)
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("WARNING: IRREVERSIBLE ACTION", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange, fontSize: 13)),
                            const SizedBox(height: 4),
                            Text("Once published, this election is permanently locked. You will NOT be able to add, edit, or remove parties and candidates to prevent voter fraud. Please carefully review the final roster below.", style: TextStyle(color: Colors.grey.shade800, fontSize: 12)),
                          ],
                        )
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text("Official Candidate Roster", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const Divider(),
                Expanded(
                  child: FutureBuilder(
                    future: http.get(Uri.parse('${ApiConfig.baseUrl}/api/candidates/$pollId')),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.statusCode != 200) {
                        return const Center(child: Text("Failed to load roster."));
                      }

                      final List candidates = jsonDecode(snapshot.data!.body);
                      if (candidates.isEmpty) {
                        return const Center(child: Text("⚠️ No candidates registered.\nAre you sure you want to publish an empty poll?", textAlign: TextAlign.center, style: TextStyle(color: Colors.red)));
                      }

                      // Group by party
                      Map<String, List<dynamic>> grouped = {};
                      for (var c in candidates) {
                        String party = c['party_name'] ?? 'Independent';
                        grouped.putIfAbsent(party, () => []).add(c);
                      }

                      return ListView(
                        children: grouped.entries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 15),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4)),
                                  child: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF000B6B))),
                                ),
                                ...entry.value.map((candidate) {
                                  return ListTile(
                                    dense: true,
                                    visualDensity: const VisualDensity(vertical: -2),
                                    leading: const Icon(Icons.person, size: 18, color: Colors.grey),
                                    title: Text(candidate['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    subtitle: Text(candidate['position'], style: const TextStyle(fontSize: 12)),
                                  );
                                }),
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
              icon: const Icon(Icons.campaign, size: 18),
              label: const Text("Confirm & Publish", style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.pop(context); // Close Modal
                _publishPoll(pollId);   // Execute Publish API
              },
            ),
          ],
        );
      },
    );
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
                      title: const Text('Start Time', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(_formatDateTimeObj(startTime)), 
                      trailing: const Icon(Icons.calendar_today, color: Color(0xFF000B6B)),
                      onTap: () async {
                        final dt = await _pickDateTime(startTime);
                        if (dt != null) setDialogState(() => startTime = dt);
                      },
                    ),
                    const Divider(),
                    ListTile(
                      title: const Text('End Time', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(_formatDateTimeObj(endTime)), 
                      trailing: const Icon(Icons.calendar_today, color: Color(0xFF000B6B)),
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
              const Spacer(),
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
                  ? const Center(child: Text('No polls created yet.', style: TextStyle(color: Colors.white)))
                  : ListView.builder(
                      itemCount: _polls.length,
                      itemBuilder: (context, index) {
                        final poll = _polls[index];
                        final bool isPublished = poll['is_published'] == true || poll['is_published'] == 1;
                        final bool isArchived = poll['is_archived'] == true || poll['is_archived'] == 1;
                        
                        bool isExpired = false;
                        if (poll['end_time'] != null) {
                          DateTime endTime = DateTime.parse(poll['end_time']);
                          isExpired = endTime.isBefore(DateTime.now());
                        }

                        if (_showArchived != isArchived) {
                          return const SizedBox.shrink();
                        }

                        return InkWell(
                          onTap: () => _openPollDetails(poll['poll_id'], poll['title']),
                          child: Card(
                            margin: const EdgeInsets.only(bottom: 15),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              title: Text(poll['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF000B6B))),
                              
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  'Start: ${_formatDateString(poll['start_time'])}\nEnd: ${_formatDateString(poll['end_time'])}', 
                                  style: const TextStyle(height: 1.5, color: Colors.black87)
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (!isPublished) ...[
                                    // 🛠️ REPLACED: Intercepts the publish action to show the summary modal
                                    ElevatedButton.icon(
                                      icon: const Icon(Icons.campaign, size: 18),
                                      label: const Text("Publish"),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                      ),
                                      onPressed: () => _showPublishConfirmationDialog(poll['poll_id'], poll['title']),
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