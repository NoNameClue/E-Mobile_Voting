import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_config.dart';

class ElectionResultPage extends StatefulWidget {
  const ElectionResultPage({super.key});

  @override
  State<ElectionResultPage> createState() => _ElectionResultPageState();
}

class _ElectionResultPageState extends State<ElectionResultPage> {
  List<dynamic> _polls = [];
  int? _selectedPollId;
  
  Map<String, dynamic>? _reportData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPolls();
  }

  // Gets the list of polls for the dropdown
  Future<void> _fetchPolls() async {
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/polls'));
      if (response.statusCode == 200) {
        final polls = jsonDecode(response.body);
        setState(() {
          _polls = polls;
          if (_polls.isNotEmpty) {
            _selectedPollId = _polls[0]['poll_id'];
            _fetchReport(); // Automatically fetch report for the first poll
          } else {
            _isLoading = false;
          }
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // Fetches the math calculations from Python
  Future<void> _fetchReport() async {
    if (_selectedPollId == null) return;
    setState(() => _isLoading = true);
    
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/polls/$_selectedPollId/report'));
      if (response.statusCode == 200) {
        setState(() {
          _reportData = jsonDecode(response.body);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // Reusable card for the top summary stats
  Widget _buildSummaryCard(String title, String value, IconData icon) {
    return Expanded(
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              CircleAvatar(backgroundColor: const Color(0xFF000B6B).withOpacity(0.1), child: Icon(icon, color: const Color(0xFF000B6B))),
              const SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(30.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Dropdown
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Official Election Report", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  // Poll Selection Dropdown
                  if (_polls.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _selectedPollId,
                          items: _polls.map<DropdownMenuItem<int>>((poll) {
                            return DropdownMenuItem<int>(
                              value: poll['poll_id'],
                              child: Text(poll['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                            );
                          }).toList(),
                          onChanged: (int? newValue) {
                            setState(() {
                              _selectedPollId = newValue;
                              _fetchReport();
                            });
                          },
                        ),
                      ),
                    ),
                  const SizedBox(width: 20),
                  // Print Button
                  ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Use CTRL+P / CMD+P to print this web view.')));
                    },
                    icon: const Icon(Icons.print),
                    label: const Text('Print Report'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18)),
                  )
                ],
              ),
            ],
          ),
          const SizedBox(height: 30),

          // Loading and Error States
          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_reportData == null)
            const Expanded(child: Center(child: Text("No report data found.")))
          else
            // Main Content Area
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top 3 Summary Cards
                    Row(
                      children: [
                        _buildSummaryCard("Total Active Students", _reportData!['summary']['total_active_students'].toString(), Icons.group),
                        const SizedBox(width: 20),
                        _buildSummaryCard("Total Ballots Cast", _reportData!['summary']['total_voters'].toString(), Icons.how_to_vote),
                        const SizedBox(width: 20),
                        _buildSummaryCard("Voter Turnout", "${_reportData!['summary']['turnout_percentage']}%", Icons.pie_chart),
                      ],
                    ),
                    const SizedBox(height: 30),

                    // Generate a Table for each Position
                    ...(_reportData!['results'] as List).map((positionData) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 30),
                        elevation: 3,
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text("Position: ${positionData['position'].toUpperCase()}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF000B6B))),
                              const Divider(),
                              DataTable(
                                headingRowColor: WidgetStateProperty.all(Colors.grey[200]),
                                columns: const [
                                  DataColumn(label: Text('Rank', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Candidate Name', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Party', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Votes', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Percentage', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Margin (Lead)', style: TextStyle(fontWeight: FontWeight.bold))),
                                ],
                                rows: (positionData['candidates'] as List).map((candidate) {
                                  // Typography logic for the Winner
                                  final bool isWinner = candidate['is_winner'];
                                  final textStyle = TextStyle(
                                    fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
                                    color: isWinner ? Colors.green[800] : Colors.black87,
                                  );

                                  return DataRow(
                                    color: isWinner ? WidgetStateProperty.all(Colors.green.withOpacity(0.05)) : null,
                                    cells: [
                                      DataCell(Text('#${candidate['rank']}', style: textStyle)),
                                      DataCell(Row(
                                        children: [
                                          if (isWinner) const Icon(Icons.emoji_events, color: Colors.amber, size: 20),
                                          if (isWinner) const SizedBox(width: 5),
                                          Text(candidate['name'], style: textStyle),
                                        ],
                                      )),
                                      DataCell(Text(candidate['party_name'], style: textStyle)),
                                      DataCell(Text(candidate['votes'].toString(), style: textStyle)),
                                      DataCell(Text('${candidate['percentage']}%', style: textStyle)),
                                      DataCell(Text(
                                        candidate['margin'] != null ? '+${candidate['margin']}%' : '-', 
                                        style: TextStyle(color: candidate['margin'] != null ? Colors.blue[700] : Colors.grey, fontWeight: FontWeight.bold)
                                      )),
                                    ],
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("Total Valid Votes: ${positionData['total_votes']}", 
                                    style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, fontWeight: FontWeight.bold)
                                  ),
                                  Text("Total Candidates: ${(positionData['candidates'] as List).length}", 
                                    style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, fontWeight: FontWeight.bold)
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            )
        ],
      ),
    );
  }
}