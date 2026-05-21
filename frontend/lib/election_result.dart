import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'api_config.dart';
import 'dart:typed_data'; 
import 'package:excel/excel.dart' hide Border;

class ElectionResultPage extends StatefulWidget {
  final bool isAdmin; 
  const ElectionResultPage({super.key, this.isAdmin = true});

  @override
  State<ElectionResultPage> createState() => _ElectionResultPageState();
}

class _ElectionResultPageState extends State<ElectionResultPage> {
  List<dynamic> _polls = [];
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
        setState(() {
          List all = jsonDecode(response.body);
          _polls = widget.isAdmin ? all : all.where((p) => p['is_published'] == true).toList();
          _polls.sort((a, b) {
            DateTime dateA = a['start_time'] != null ? DateTime.parse(a['start_time']) : DateTime(2000);
            DateTime dateB = b['start_time'] != null ? DateTime.parse(b['start_time']) : DateTime(2000);
            return dateB.compareTo(dateA); 
          });
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // Helper method to format dates cleanly without needing the intl package
  String _formatDate(String? dateString) {
    if (dateString == null) return "Unknown Date";
    try {
      DateTime date = DateTime.parse(dateString);
      List<String> months = [
        'January', 'February', 'March', 'April', 'May', 'June', 
        'July', 'August', 'September', 'October', 'November', 'December'
      ];
      return "${months[date.month - 1]} ${date.day}, ${date.year}";
    } catch (e) {
      return "Unknown Date";
    }
  }

  Future<void> _openResultPopup(int pollId, String pollTitle) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.amber)),
    );

    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/polls/$pollId/report'));
      
      if (!mounted) return;
      Navigator.pop(context);

      if (response.statusCode == 200) {
        final reportData = jsonDecode(response.body);
        _showDetailedModal(pollTitle, reportData);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to load report data.')));
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Network error. Cannot fetch results.')));
    }
  }

  Future<void> _exportToExcel(Map<String, dynamic> reportData, String pollTitle) async {
    var excel = Excel.createExcel();
    Sheet summarySheet = excel['Summary'];
    excel.setDefaultSheet('Summary');

    summarySheet.appendRow([TextCellValue('Election Report: $pollTitle')]);
    summarySheet.appendRow([TextCellValue('')]); 
    summarySheet.appendRow([TextCellValue('Total Active Students:'), IntCellValue(reportData['summary']['total_active_students'])]);
    summarySheet.appendRow([TextCellValue('Total Ballots Cast:'), IntCellValue(reportData['summary']['total_voters'])]);
    summarySheet.appendRow([TextCellValue('Voter Turnout:'), TextCellValue('${reportData['summary']['turnout_percentage']}%')]);

    final results = reportData['results'] as List;

    for (var positionData in results) {
      summarySheet.appendRow([TextCellValue('')]); 
      summarySheet.appendRow([TextCellValue('--- ${positionData['position'].toUpperCase()} ---')]);
      summarySheet.appendRow([TextCellValue('Rank'), TextCellValue('Candidate Name'), TextCellValue('Party'), TextCellValue('Votes'), TextCellValue('Percentage'), TextCellValue('Margin')]);
      for (var candidate in positionData['candidates']) {
        summarySheet.appendRow([
          IntCellValue(candidate['rank']), TextCellValue(candidate['name']), TextCellValue(candidate['party_name']), IntCellValue(candidate['votes']), TextCellValue('${candidate['percentage']}%'), TextCellValue(candidate['margin'] != null ? '+${candidate['margin']}%' : '-')
        ]);
      }
    }

    final fileBytes = excel.save();
    if (fileBytes != null) {
      await Printing.sharePdf(bytes: Uint8List.fromList(fileBytes), filename: 'Election_Results_$pollTitle.xlsx');
    }
  }

  Future<void> _generatePdfAndPrint(Map<String, dynamic> reportData, String pollTitle) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        // 🚀 We removed the repetitive footer logic here.
        build: (pw.Context context) {
          return [
            pw.Header(level: 0, child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [pw.Text('Official Election Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)), pw.Text(pollTitle, style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700)), pw.SizedBox(height: 10)])),
            pw.SizedBox(height: 10),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey), borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5))),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  pw.Column(children: [pw.Text('Active Students'), pw.Text('${reportData['summary']['total_active_students']}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16))]),
                  pw.Column(children: [pw.Text('Ballots Cast'), pw.Text('${reportData['summary']['total_voters']}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16))]),
                  pw.Column(children: [pw.Text('Turnout'), pw.Text('${reportData['summary']['turnout_percentage']}%', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16))]),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Wrap(
              spacing: 0,
              runSpacing: 20, 
              children: (reportData['results'] as List).map((positionData) {
                return pw.Container(
                  width: double.infinity, 
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(positionData['position'].toUpperCase(), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                      pw.SizedBox(height: 5),
                      pw.TableHelper.fromTextArray(
                        context: context,
                        cellStyle: const pw.TextStyle(fontSize: 10), 
                        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                        headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
                        data: <List<String>>[
                          <String>['Rank', 'Candidate Name', 'Party', 'Votes', 'Percentage'],
                          ...((positionData['candidates'] as List).map((c) => [
                                '#${c['rank']}', c['name'] + (c['is_winner'] ? ' (Winner)' : ''), c['party_name'], c['votes'].toString(), '${c['percentage']}%',
                              ])),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            
            // 🚀 NEW: Signature block placed only at the very end of the document.
            pw.SizedBox(height: 40),
            pw.Container(
              alignment: pw.Alignment.centerRight,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                mainAxisSize: pw.MainAxisSize.min,
                children: [
                  pw.Text("Certified by:", style: const pw.TextStyle(fontSize: 10)),
                  pw.SizedBox(height: 30),
                  pw.Container(width: 150, height: 1, color: PdfColors.black),
                  pw.SizedBox(height: 5),
                  pw.Container(
                    width: 150,
                    alignment: pw.Alignment.center,
                    child: pw.Text("PRESIDING OFFICER", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  void _showDetailedModal(String pollTitle, Map<String, dynamic> reportData) {
    bool isMobile = MediaQuery.of(context).size.width < 800;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          insetPadding: EdgeInsets.all(isMobile ? 15 : 40),
          child: Container(
            width: 1000, 
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                // HEADER
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(color: Color(0xFF000B6B), borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Detailed Election Tally", style: TextStyle(color: Colors.amber, fontSize: 14, fontWeight: FontWeight.bold)),
                            Text(pollTitle, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 30), onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                ),

                // ACTION BUTTONS (Print / Excel) - ONLY IF ADMIN
                if (widget.isAdmin)
                  Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _generatePdfAndPrint(reportData, pollTitle),
                          icon: const Icon(Icons.print),
                          label: const Text('Print / PDF'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          onPressed: () => _exportToExcel(reportData, pollTitle),
                          icon: const Icon(Icons.table_chart),
                          label: const Text('Export Excel'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        ),
                      ],
                    ),
                  ),

                // SUMMARY CARDS
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15.0),
                  child: isMobile 
                    ? Column(
                        children: [
                          _buildSummaryCard("Total Active Students", reportData['summary']['total_active_students'].toString(), Icons.group),
                          const SizedBox(height: 10),
                          _buildSummaryCard("Total Ballots Cast", reportData['summary']['total_voters'].toString(), Icons.how_to_vote),
                          const SizedBox(height: 10),
                          _buildSummaryCard("Voter Turnout", "${reportData['summary']['turnout_percentage']}%", Icons.pie_chart),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(child: _buildSummaryCard("Total Active Students", reportData['summary']['total_active_students'].toString(), Icons.group)),
                          const SizedBox(width: 15),
                          Expanded(child: _buildSummaryCard("Total Ballots Cast", reportData['summary']['total_voters'].toString(), Icons.how_to_vote)),
                          const SizedBox(width: 15),
                          Expanded(child: _buildSummaryCard("Voter Turnout", "${reportData['summary']['turnout_percentage']}%", Icons.pie_chart)),
                        ],
                      ),
                ),

                const SizedBox(height: 15),

                // DATA TABLES
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: (reportData['results'] as List).map((positionData) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 25),
                          elevation: 2,
                          color: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: EdgeInsets.all(isMobile ? 15 : 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  "Position: ${positionData['position'].toUpperCase()}", 
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF000B6B))
                                ),
                                const Divider(),
                                
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    return SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(minWidth: constraints.maxWidth),
                                        child: DataTable(
                                          headingRowColor: WidgetStateProperty.all(Colors.grey[100]),
                                          columnSpacing: isMobile ? 15 : 30,
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
                                            final textStyle = TextStyle(fontWeight: isWinner ? FontWeight.bold : FontWeight.normal, color: isWinner ? Colors.green[800] : Colors.black87);

                                            return DataRow(
                                              color: isWinner ? WidgetStateProperty.all(Colors.green.withOpacity(0.05)) : null,
                                              cells: [
                                                DataCell(Text('#${candidate['rank']}', style: textStyle)),
                                                DataCell(Row(mainAxisSize: MainAxisSize.min, children: [if (isWinner) const Icon(Icons.emoji_events, color: Colors.amber, size: 20), if (isWinner) const SizedBox(width: 5), Text(candidate['name'], style: textStyle)])),
                                                DataCell(Text(candidate['party_name'], style: textStyle)),
                                                DataCell(Text(candidate['votes'].toString(), style: textStyle)),
                                                DataCell(SizedBox(width: 120, child: Row(children: [Expanded(child: Stack(children: [Container(height: 8, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(16))), FractionallySizedBox(widthFactor: (candidate['percentage'] ?? 0) / 100, child: Container(height: 8, decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(16))))])), const SizedBox(width: 6), Text('${candidate['percentage']}%', style: textStyle.copyWith(fontSize: 12))]))),
                                                DataCell(Builder(builder: (_) {
                                                  final margin = candidate['margin'];
                                                  final isTie = margin == 0;
                                                  String displayText; Color displayColor;
                                                  if (margin == null) { displayText = '-'; displayColor = Colors.grey; } else if (isTie) { displayText = 'Tie'; displayColor = Colors.orange; } else { displayText = '+${margin}%'; displayColor = Colors.blue.shade700; }
                                                  return Text(displayText, style: TextStyle(color: displayColor, fontWeight: FontWeight.bold));
                                                })),
                                              ],
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    );
                                  }
                                ),
                                const SizedBox(height: 15),
                                const Divider(),
                                Wrap(
                                  alignment: WrapAlignment.spaceBetween,
                                  children: [
                                    Text("Total Valid Votes: ${positionData['total_votes']}", style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, fontWeight: FontWeight.bold)),
                                    Text("Total Candidates: ${(positionData['candidates'] as List).length}", style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Row(
          children: [
            CircleAvatar(backgroundColor: const Color(0xFF000B6B).withOpacity(0.1), child: Icon(icon, color: const Color(0xFF000B6B))),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 900;

    return Padding(
      padding: EdgeInsets.all(isMobile ? 15.0 : 30.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Election Results Archive", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 10),
          const Text("Select a past or current election below to view the detailed outcome.", style: TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 30),

          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator(color: Colors.white)))
          else if (_polls.isEmpty)
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inbox, size: 80, color: Colors.white54),
                    SizedBox(height: 20),
                    Text("No Election Polls Found", style: TextStyle(fontSize: 20, color: Colors.white)),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _polls.length,
                itemBuilder: (context, index) {
                  final poll = _polls[index];
                  bool isEnded = poll['status'] == 'Ended';
                  bool isUpcoming = poll['status'] == 'Upcoming';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)),
                                child: const Icon(Icons.bar_chart_rounded, size: 30, color: Color(0xFF000B6B)),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(poll['title'] ?? 'Untitled Poll', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF000B6B))),
                                    const SizedBox(height: 5),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isEnded ? Colors.red.shade100 : (isUpcoming ? Colors.orange.shade100 : Colors.green.shade100),
                                            borderRadius: BorderRadius.circular(8)
                                          ),
                                          child: Text(
                                            poll['status'].toUpperCase(), 
                                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isEnded ? Colors.red.shade800 : (isUpcoming ? Colors.orange.shade800 : Colors.green.shade800))
                                          ),
                                        ),
                                        // 🚀 NEW: Replaced ID with beautifully formatted Start Date
                                        Padding(
                                          padding: const EdgeInsets.only(left: 10),
                                          child: Text("Started on ${_formatDate(poll['start_time'])}", style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                                        )
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF000B6B),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                                ),
                                onPressed: isUpcoming || poll['status'] == 'Draft' ? null : () => _openResultPopup(poll['poll_id'], poll['title']),
                                child: const Text("View Full Results", style: TextStyle(fontWeight: FontWeight.bold)),
                              )
                            ],
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