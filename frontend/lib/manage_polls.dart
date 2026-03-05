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
              const Text("Manage Polls", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text("Create Poll"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
                onPressed: () => _showPollDialog(),
              )
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

                        return Card(
                          margin: const EdgeInsets.only(bottom: 15),
                          child: ListTile(
                            title: Text(poll['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Start: ${poll['start_time'].toString().substring(0, 16)}\nEnd: ${poll['end_time'].toString().substring(0, 16)}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // If it is not published yet, show the Publish button
                                if (!isPublished)
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.campaign, size: 18),
                                    label: const Text("Publish"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green, 
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () => _publishPoll(poll['poll_id']),
                                  )
                                // If published, show a simple badge
                                else
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.green)
                                    ),
                                    child: const Text("PUBLISHED", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                                  ),
                                  
                                const SizedBox(width: 10),
                                IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showPollDialog(existingPoll: poll)),
                                IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deletePoll(poll['poll_id'])),
                              ],
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