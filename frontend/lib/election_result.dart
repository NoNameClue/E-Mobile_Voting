import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_config.dart';
import 'responsive_screen.dart';

class ElectionResultPage extends StatefulWidget {
  const ElectionResultPage({super.key});

  @override
  State<ElectionResultPage> createState() => _ElectionResultPageState();
   Widget build(BuildContext context) {
    return Scaffold(
      body: ResponsiveScreen(
        child: Column(
          children: [
            Text("Election Results", style: TextStyle(fontSize: 24)),
            ElectionResultPage(),
          ],
        ),
      ),
    );
  }
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

  Future<void> _fetchPolls() async {
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/polls'));
      if (response.statusCode == 200) {
        final polls = jsonDecode(response.body);
        setState(() {
          _polls = polls;
          if (_polls.isNotEmpty) {
            _selectedPollId = _polls[0]['poll_id'];
            _fetchReport();
          } else {
            _isLoading = false;
          }
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

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

  // Responsive Summary Card
  Widget _buildSummaryCard(String title, String value, IconData icon, bool isMobile) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: isMobile ? 15 : 0),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFF000B6B).withOpacity(0.1), 
              child: Icon(icon, color: const Color(0xFF000B6B))
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 5),
                  Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  // Helper widget for the dropdown
  Widget _buildDropdown() {
    if (_polls.isEmpty) return const SizedBox.shrink();
    return Container(
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
    );
  }

  // Helper widget for the print button
  Widget _buildPrintButton() {
    return ElevatedButton.icon(
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Use CTRL+P / CMD+P to print.')));
      },
      icon: const Icon(Icons.print),
      label: const Text('Print'),
      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determine screen width to switch between Web (Desktop) and Android (Mobile) layouts
    final bool isMobile = MediaQuery.of(context).size.width < 800;

    return Padding(
      padding: EdgeInsets.all(isMobile ? 16.0 : 30.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          // --- RESPONSIVE HEADER ---
          if (isMobile)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Election Report", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _buildDropdown(),
                    _buildPrintButton(),
                  ],
                ),
              ],
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Election Report", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    _buildDropdown(),
                    const SizedBox(width: 15),
                    _buildPrintButton(),
                  ],
                ),
              ],
            ),
            
          SizedBox(height: isMobile ? 20 : 30),

          // --- MAIN CONTENT ---
          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_reportData == null)
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [

                    Icon(
                      Icons.assessment_outlined,
                      size: 90,
                      color: Colors.grey,
                    ),

                    SizedBox(height: 20),

                    Text(
                      "Awaiting Election Results",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    SizedBox(height: 10),

                    Text(
                      "The report will appear once voting data is available.",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),

                  ],
                ),
              ),
            )
          else
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    
                    // --- RESPONSIVE SUMMARY CARDS ---
                    if (isMobile)
                      Column(
                        children: [
                          _buildSummaryCard("Total Active Students", _reportData!['summary']['total_active_students'].toString(), Icons.group, isMobile),
                          _buildSummaryCard("Total Ballots Cast", _reportData!['summary']['total_voters'].toString(), Icons.how_to_vote, isMobile),
                          _buildSummaryCard("Voter Turnout", "${_reportData!['summary']['turnout_percentage']}%", Icons.pie_chart, isMobile),
                        ],
                      )
                    else
                      Row(
                        children: [
                          Expanded(child: _buildSummaryCard("Total Active Students", _reportData!['summary']['total_active_students'].toString(), Icons.group, isMobile)),
                          const SizedBox(width: 20),
                          Expanded(child: _buildSummaryCard("Total Ballots Cast", _reportData!['summary']['total_voters'].toString(), Icons.how_to_vote, isMobile)),
                          const SizedBox(width: 20),
                          Expanded(child: _buildSummaryCard("Voter Turnout", "${_reportData!['summary']['turnout_percentage']}%", Icons.pie_chart, isMobile)),
                        ],
                      ),
                      
                    SizedBox(height: isMobile ? 20 : 30),

                    // --- DATATABLES ---
                    ...(_reportData!['results'] as List).map((positionData) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 30),
                        elevation: 3,
                        color: Colors.white,
                        child: Padding(
                          padding: EdgeInsets.all(isMobile ? 15 : 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text("Position: ${positionData['position'].toUpperCase()}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF000B6B))),
                              const Divider(),
                              
                              // FIX: Use LayoutBuilder to stretch the table edge-to-edge on Web, 
                              // while keeping the scrolling behavior for both Web and Mobile.
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  return SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        // On web (!isMobile), force the table to stretch to the card's full width.
                                        // On mobile, keep it at 0 to leave the UI completely untouched.
                                        minWidth: isMobile ? 0 : constraints.maxWidth,
                                      ),
                                      child: DataTable(
                                        headingRowColor: WidgetStateProperty.all(Colors.grey[200]),
                                        columnSpacing: isMobile ? 20 : 50, // tighter spacing on mobile
                                        columns: const [
                                          DataColumn(label: Text('Rank', style: TextStyle(fontWeight: FontWeight.bold))),
                                          DataColumn(label: Text('Candidate Name', style: TextStyle(fontWeight: FontWeight.bold))),
                                          DataColumn(label: Text('Party', style: TextStyle(fontWeight: FontWeight.bold))),
                                          DataColumn(label: Text('Votes', style: TextStyle(fontWeight: FontWeight.bold))),
                                          DataColumn(label: Text('Percentage', style: TextStyle(fontWeight: FontWeight.bold))),
                                          DataColumn(label: Text('Margin', style: TextStyle(fontWeight: FontWeight.bold))),
                                        ],
                                        rows: (positionData['candidates'] as List).map((candidate) {
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
                                    ),
                                  );
                                },
                              ),
                              
                              const SizedBox(height: 15),
                              
                              // --- RESPONSIVE TABLE FOOTER ---
                              if (isMobile)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Total Valid Votes: ${positionData['total_votes']}", 
                                      style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, fontWeight: FontWeight.bold)
                                    ),
                                    const SizedBox(height: 5),
                                    Text("Total Candidates: ${(positionData['candidates'] as List).length}", 
                                      style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, fontWeight: FontWeight.bold)
                                    ),
                                  ],
                                )
                              else
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