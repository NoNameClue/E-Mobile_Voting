import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_config.dart';
// import 'responsive_screen.dart';

class ManageParties extends StatefulWidget {
  const ManageParties({super.key});

  @override
  State<ManageParties> createState() => _ManagePartiesState();
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     body: ResponsiveScreen(
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           const Text(
  //             "Manage Parties",
  //             style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
  //           ),

  //           const SizedBox(height: 20),

  //           SingleChildScrollView(
  //             scrollDirection: Axis.horizontal,
  //             child: DataTable(
  //               columns: const [
  //                 DataColumn(label: Text("Party Name")),
  //                 DataColumn(label: Text("Description")),
  //                 DataColumn(label: Text("Members")),
  //                 DataColumn(label: Text("Actions")),
  //               ],
  //               rows: const [],
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }
}

class _ManagePartiesState extends State<ManageParties> {
  List<dynamic> _parties = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchParties();
  }

  Future<void> _fetchParties() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/parties/lineups'));
      if (response.statusCode == 200) {
        setState(() {
          _parties = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load parties');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error connecting to server.')));
      }
    }
  }

  Future<void> _createParty(String partyName) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/parties'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"name": partyName}),
      );

      if (response.statusCode == 200) {
        if (mounted) Navigator.of(context).pop(); // Close modal
        _fetchParties(); // Refresh list
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Party created successfully!', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green));
      } else {
        final errorMsg = jsonDecode(response.body)['detail'] ?? 'Failed to create party.';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMsg, style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Network error. Please try again.')));
    }
  }

  // --- DELETE LOGIC ---
  Future<void> _deleteParty(int partyId) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/api/parties/$partyId'),
      );

      if (response.statusCode == 200) {
        _fetchParties(); // Refresh list
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Party deleted successfully!', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green));
        }
      } else {
        final errorMsg = jsonDecode(response.body)['detail'] ?? 'Failed to delete party.';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMsg, style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Network error. Please try again.')));
    }
  }

  // --- DOUBLE CONFIRMATION DIALOG FLOW ---
  void _showDeleteConfirmation1(int partyId, String partyName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Delete $partyName?"),
        content: const Text("Are you sure you want to delete this party list?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(context); // Close the first dialog
              _showDeleteConfirmation2(partyId, partyName); // Open the second dialog
            },
            child: const Text("Yes, Delete"),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation2(int partyId, String partyName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Final Confirmation", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: const Text("Are you REALLY sure? This action cannot be undone. Any candidates registered under this party will automatically be changed to 'Independent'."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(context); // Close the second dialog
              _deleteParty(partyId);  // Execute the delete API
            },
            child: const Text("Yes, I am absolutely sure"),
          ),
        ],
      ),
    );
  }

  void _showCreatePartyDialog() {
    final TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Create New Party"),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: "Party Name",
              hintText: "e.g. Progressive Youth Party",
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF000B6B), foregroundColor: Colors.white),
              onPressed: () {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Party name cannot be empty")));
                  return;
                }
                _createParty(nameController.text.trim());
              },
              child: const Text("Save / Create"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 700;

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 15,
            runSpacing: 15,
            children: [
              const Text("Manage Parties", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text("Create Party"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                ),
                onPressed: _showCreatePartyDialog,
              )
            ],
          ),
          const SizedBox(height: 10),
          const Text("Create political parties and view their assigned candidate lineups.", style: TextStyle(color: Colors.grey, fontSize: 16)),
          const SizedBox(height: 20),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _parties.isEmpty
                    ? const Center(child: Text("No parties found. Create one to get started!"))
                    : GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: isMobile ? 1 : 3,
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 20,
                          childAspectRatio: isMobile ? 1.2 : 0.85,
                        ),
                        itemCount: _parties.length,
                        itemBuilder: (context, index) {
                          final party = _parties[index];
                          final Map<String, dynamic> lineup = party['lineup'];
                          
                          // Check if this is the Independent party to disable deletion
                          bool isIndependent = party['party_name'].toString().toLowerCase() == "independent";

                          return Card(
                            elevation: 3,
                            color: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // --- UPDATED CARD HEADER WITH DELETE ICON ---
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          party['party_name'].toUpperCase(),
                                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF000B6B)),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (!isIndependent) // Hide delete for Independent
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          onPressed: () => _showDeleteConfirmation1(party['party_id'], party['party_name']),
                                        ),
                                    ],
                                  ),
                                  const Divider(height: 30, thickness: 1),
                                  
                                  // --- CANDIDATE LINEUP ---
                                  Expanded(
                                    child: ListView(
                                      children: lineup.entries.map((entry) {
                                        String position = entry.key;
                                        String? candidateName = entry.value;

                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: 12.0),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              SizedBox(
                                                width: 100,
                                                child: Text(
                                                  position,
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Text(
                                                  candidateName ?? "[ No Candidate Registered ]",
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: candidateName == null ? Colors.grey : Colors.black,
                                                    fontStyle: candidateName == null ? FontStyle.italic : FontStyle.normal,
                                                    fontWeight: candidateName != null ? FontWeight.w500 : FontWeight.normal,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
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