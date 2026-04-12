import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'api_config.dart';
// import 'responsive_screen.dart';

class AdminLiveScoreboard extends StatefulWidget {
  const AdminLiveScoreboard({super.key});

  @override
  State<AdminLiveScoreboard> createState() => _AdminLiveScoreboardState();
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     body: ResponsiveScreen(
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           const Text(
  //             "Live Election Scoreboard",
  //             style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
  //           ),

  //           const SizedBox(height: 20),

  //           SingleChildScrollView(
  //             scrollDirection: Axis.horizontal,
  //             child: DataTable(
  //               columns: const [
  //                 DataColumn(label: Text("Candidate")),
  //                 DataColumn(label: Text("Position")),
  //                 DataColumn(label: Text("Party")),
  //                 DataColumn(label: Text("Votes")),
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

class _AdminLiveScoreboardState extends State<AdminLiveScoreboard> {
  List<dynamic> _polls = [];
  int? _selectedPollId;
  
  Map<String, List<dynamic>> _groupedResults = {};
  bool _isLoading = true;
  Timer? _refreshTimer; // To auto-refresh the live data

  @override
  void initState() {
    super.initState();
    _fetchPolls();
    
    // Auto-refresh the live scoreboard every 10 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_selectedPollId != null) _fetchResults();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel(); // Clean up timer when leaving page
    super.dispose();
  }

  Future<void> _fetchPolls() async {
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/polls'));
      if (response.statusCode == 200) {
        final polls = jsonDecode(response.body);
        setState(() {
          _polls = polls;
          // Default to the published poll, or the first one
          final active = polls.firstWhere((p) => p['is_published'] == true || p['is_published'] == 1, orElse: () => polls.isNotEmpty ? polls[0] : null);
          if (active != null) {
            _selectedPollId = active['poll_id'];
            _fetchResults();
          } else {
            _isLoading = false;
          }
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchResults() async {
    if (_selectedPollId == null) return;
    
    try {
      // Re-using the endpoint we built previously!
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/polls/$_selectedPollId/results'));
      if (response.statusCode == 200) {
        final List<dynamic> results = jsonDecode(response.body);
        
        // Group by position for the charts
        Map<String, List<dynamic>> grouped = {};
        for (var c in results) {
          String pos = c['position'];
          if (!grouped.containsKey(pos)) grouped[pos] = [];
          grouped[pos]!.add(c);
        }

        setState(() {
          _groupedResults = grouped;
          _isLoading = false;
        });
      }
    } catch (e) {
      // Handle silently so the auto-refresh doesn't spam errors
    }
  }

// --- CHART BUILDER WIDGET ---
  Widget _buildPositionChart(String position, List<dynamic> candidates) {
    // Find the max votes to set the Y-axis height appropriately
    double maxVotes = 0;
    for (var c in candidates) {
      if (c['votes'] > maxVotes) maxVotes = c['votes'].toDouble();
    }
    // Add a little headroom above the tallest bar
    maxVotes = maxVotes < 10 ? 10 : maxVotes + (maxVotes * 0.2); 

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 30),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Live: ${position.toUpperCase()}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF000B6B))),
            const SizedBox(height: 30),
            
            // The Bar Chart Container
            SizedBox(
              height: 300,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxVotes,
                  
                  // FIX: Corrected from BarChartTouchData to BarTouchData
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (group) => Colors.black87,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final candidate = candidates[group.x.toInt()];
                        return BarTooltipItem(
                          '${candidate['name']}\n${candidate['votes']} Votes (${candidate['percentage']}%)',
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        );
                      },
                    ),
                  ),
                  
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          final name = candidates[value.toInt()]['name'];
                          // Split name to show first name or initials if too long
                          final shortName = name.split(' ')[0];
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(shortName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          );
                        },
                        reservedSize: 40,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxVotes / 5 > 0 ? maxVotes / 5 : 1,
                    getDrawingHorizontalLine: (value) => const FlLine(color: Colors.black12, strokeWidth: 1),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: candidates.asMap().entries.map((entry) {
                    int idx = entry.key;
                    var c = entry.value;
                    
                    // Highlight the current leader in Green, others in Blue
                    bool isLeader = c['votes'] > 0 && c['votes'] == candidates.map((e) => e['votes']).reduce((a, b) => a > b ? a : b);

                    return BarChartGroupData(
                      x: idx,
                      barRods: [
                        BarChartRodData(
                          toY: c['votes'].toDouble(),
                          color: isLeader ? Colors.green : const Color(0xFF000B6B).withOpacity(0.7),
                          width: 30,
                          borderRadius: const BorderRadius.only(topLeft: Radius.circular(6), topRight: Radius.circular(6)),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

@override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // FIX: Changed Row to Wrap so the layout breaks cleanly onto a new line on mobile
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 15,
            runSpacing: 15,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.bar_chart, size: 30, color: Color.fromARGB(255, 28, 116, 18)),
                  SizedBox(width: 10),
                  Text("Live Scoreboard", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
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
                          _isLoading = true;
                          _fetchResults();
                        });
                      },
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          const Text("Charts automatically update every 10 seconds.", style: TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 30),

          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_groupedResults.isEmpty)
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [

                    Icon(
                      Icons.hourglass_empty,
                      size: 90,
                      color: Colors.grey,
                    ),

                    SizedBox(height: 20),

                    Text(
                      "Awaiting final results",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    SizedBox(height: 10),

                    Text(
                      "Results will appear once voting begins.",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),

                  ],
                ),
              ),
            )
          else
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: _groupedResults.entries.map((entry) {
                    return _buildPositionChart(entry.key, entry.value);
                  }).toList(),
                ),
              ),
            )
        ],
      ),
    );
  }
}