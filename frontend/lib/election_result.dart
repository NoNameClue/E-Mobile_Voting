import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'api_config.dart';
import 'dart:typed_data'; // <-- FIX 1: Added for Uint8List
import 'package:excel/excel.dart'
    hide Border; // <-- FIX 2: Only ONE excel import, hiding Border

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

  Future<void> _fetchPolls() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/polls'),
      );
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
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/polls/$_selectedPollId/report'),
      );
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

  // ===========================================================================
  // EXPORT TO EXCEL LOGIC
  // ===========================================================================
  Future<void> _exportToExcel() async {
    if (_reportData == null) return;

    // Create a new Excel Document
    var excel = Excel.createExcel();

    // 1. Create Summary Sheet
    Sheet summarySheet = excel['Summary'];
    excel.setDefaultSheet('Summary');

    String pollTitle = _polls.firstWhere(
      (p) => p['poll_id'] == _selectedPollId,
    )['title'];

    summarySheet.appendRow([TextCellValue('Election Report: $pollTitle')]);
    summarySheet.appendRow([TextCellValue('')]); // Blank row
    summarySheet.appendRow([
      TextCellValue('Total Active Students:'),
      IntCellValue(_reportData!['summary']['total_active_students']),
    ]);
    summarySheet.appendRow([
      TextCellValue('Total Ballots Cast:'),
      IntCellValue(_reportData!['summary']['total_voters']),
    ]);
    summarySheet.appendRow([
      TextCellValue('Voter Turnout:'),
      TextCellValue('${_reportData!['summary']['turnout_percentage']}%'),
    ]);

    // 2. Add Data for each position
    final results = _reportData!['results'] as List;

    for (var positionData in results) {
      summarySheet.appendRow([TextCellValue('')]); // Blank row spacing
      summarySheet.appendRow([
        TextCellValue('--- ${positionData['position'].toUpperCase()} ---'),
      ]);

      // Table Headers
      summarySheet.appendRow([
        TextCellValue('Rank'),
        TextCellValue('Candidate Name'),
        TextCellValue('Party'),
        TextCellValue('Votes'),
        TextCellValue('Percentage'),
        TextCellValue('Margin'),
      ]);

      // Table Data
      for (var candidate in positionData['candidates']) {
        summarySheet.appendRow([
          IntCellValue(candidate['rank']),
          TextCellValue(candidate['name']),
          TextCellValue(candidate['party_name']),
          IntCellValue(candidate['votes']),
          TextCellValue('${candidate['percentage']}%'),
          TextCellValue(
            candidate['margin'] != null ? '+${candidate['margin']}%' : '-',
          ),
        ]);
      }
    }

    // Save and download the file
    final fileBytes = excel.save();
    if (fileBytes != null) {
      // In a web environment, this triggers a browser download.
      // In desktop, you would use path_provider to save it to a local folder.
      await Printing.sharePdf(
        bytes: Uint8List.fromList(fileBytes),
        filename: 'Election_Results_$pollTitle.xlsx',
      );
    }
  }

  // ===========================================================================
  // PRINT TO PDF LOGIC
  // ===========================================================================
Future<void> _generatePdfAndPrint() async {
    if (_reportData == null) return;

    final pdf = pw.Document();
    String pollTitle = _polls.firstWhere((p) => p['poll_id'] == _selectedPollId)['title'];

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // HEADER
            pw.Header(
              level: 0,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Official Election Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.Text(pollTitle, style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
                  pw.SizedBox(height: 10),
                ],
              ),
            ),
            pw.SizedBox(height: 10),

            // SUMMARY BOX
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey), borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5))),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  pw.Column(children: [pw.Text('Active Students'), pw.Text('${_reportData!['summary']['total_active_students']}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16))]),
                  pw.Column(children: [pw.Text('Ballots Cast'), pw.Text('${_reportData!['summary']['total_voters']}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16))]),
                  pw.Column(children: [pw.Text('Turnout'), pw.Text('${_reportData!['summary']['turnout_percentage']}%', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16))]),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // --- SCALABLE COMPACT TABLES (2 PER PAGE) ---
            pw.Wrap(
              spacing: 0,
              runSpacing: 20, // Forces spacing between tables
              children: (_reportData!['results'] as List).map((positionData) {
                return pw.Container(
                  width: double.infinity, // Ensures it takes full width of A4
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        positionData['position'].toUpperCase(),
                        style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                      ),
                      pw.SizedBox(height: 5),

                      // SCALABLE PDF TABLE
                      pw.TableHelper.fromTextArray(
                        context: context,
                        cellStyle: const pw.TextStyle(fontSize: 10), // Scaled down text to fit better
                        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                        headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
                        data: <List<String>>[
                          <String>['Rank', 'Candidate Name', 'Party', 'Votes', 'Percentage'],
                          ...((positionData['candidates'] as List).map((c) => [
                                '#${c['rank']}',
                                c['name'] + (c['is_winner'] ? ' (Winner)' : ''),
                                c['party_name'],
                                c['votes'].toString(),
                                '${c['percentage']}%',
                              ])),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  // ===========================================================================
  // UI BUILDERS
  // ===========================================================================

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    bool isMobile,
  ) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: isMobile ? 15 : 0),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFF000B6B).withOpacity(0.1),
              child: Icon(icon, color: const Color(0xFF000B6B)),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown() {
    if (_polls.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selectedPollId,
          items: _polls.map<DropdownMenuItem<int>>((poll) {
            return DropdownMenuItem<int>(
              value: poll['poll_id'],
              child: Text(
                poll['title'],
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
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

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 800;

    return Padding(
      padding: EdgeInsets.all(isMobile ? 16.0 : 30.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- HEADER & BUTTONS ---
          if (isMobile)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Election Report",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 15),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _buildDropdown(),
                    ElevatedButton.icon(
                      onPressed: _reportData == null
                          ? null
                          : _generatePdfAndPrint,
                      icon: const Icon(Icons.print),
                      label: const Text('Print / PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _reportData == null ? null : _exportToExcel,
                      icon: const Icon(Icons.table_chart),
                      label: const Text('Export Excel'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Election Report",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    _buildDropdown(),
                    const SizedBox(width: 15),
                    ElevatedButton.icon(
                      onPressed: _reportData == null
                          ? null
                          : _generatePdfAndPrint,
                      icon: const Icon(Icons.print),
                      label: const Text('Print / PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 15,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: _reportData == null ? null : _exportToExcel,
                      icon: const Icon(Icons.table_chart),
                      label: const Text('Export Excel'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 15,
                        ),
                      ),
                    ),
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
                      style: TextStyle(fontSize: 14, color: Colors.grey),
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
                    // SUMMARY CARDS
                    if (isMobile)
                      Column(
                        children: [
                          _buildSummaryCard(
                            "Total Active Students",
                            _reportData!['summary']['total_active_students']
                                .toString(),
                            Icons.group,
                            isMobile,
                          ),
                          _buildSummaryCard(
                            "Total Ballots Cast",
                            _reportData!['summary']['total_voters'].toString(),
                            Icons.how_to_vote,
                            isMobile,
                          ),
                          _buildSummaryCard(
                            "Voter Turnout",
                            "${_reportData!['summary']['turnout_percentage']}%",
                            Icons.pie_chart,
                            isMobile,
                          ),
                        ],
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: _buildSummaryCard(
                              "Total Active Students",
                              _reportData!['summary']['total_active_students']
                                  .toString(),
                              Icons.group,
                              isMobile,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: _buildSummaryCard(
                              "Total Ballots Cast",
                              _reportData!['summary']['total_voters']
                                  .toString(),
                              Icons.how_to_vote,
                              isMobile,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: _buildSummaryCard(
                              "Voter Turnout",
                              "${_reportData!['summary']['turnout_percentage']}%",
                              Icons.pie_chart,
                              isMobile,
                            ),
                          ),
                        ],
                      ),

                    SizedBox(height: isMobile ? 20 : 30),

                    // DATATABLES
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
                              Text(
                                "Position: ${positionData['position'].toUpperCase()}",
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF000B6B),
                                ),
                              ),
                              const Divider(),

                              LayoutBuilder(
                                builder: (context, constraints) {
                                  return SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        minWidth: isMobile
                                            ? 0
                                            : constraints.maxWidth,
                                      ),
                                      child: DataTable(
                                        headingRowColor:
                                            WidgetStateProperty.all(
                                              Colors.grey[200],
                                            ),
                                        columnSpacing: isMobile ? 20 : 50,
                                        columns: const [
                                          DataColumn(
                                            label: Text(
                                              'Rank',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          DataColumn(
                                            label: Text(
                                              'Candidate Name',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          DataColumn(
                                            label: Text(
                                              'Party',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          DataColumn(
                                            label: Text(
                                              'Votes',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          DataColumn(
                                            label: Text(
                                              'Percentage',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          DataColumn(
                                            label: Text(
                                              'Margin',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                        rows: (positionData['candidates'] as List).map((
                                          candidate,
                                        ) {
                                          final bool isWinner =
                                              candidate['is_winner'];
                                          final textStyle = TextStyle(
                                            fontWeight: isWinner
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            color: isWinner
                                                ? Colors.green[800]
                                                : Colors.black87,
                                          );

                                          return DataRow(
                                            color: isWinner
                                                ? WidgetStateProperty.all(
                                                    Colors.green.withOpacity(
                                                      0.05,
                                                    ),
                                                  )
                                                : null,
                                            cells: [
                                              DataCell(
                                                Text(
                                                  '#${candidate['rank']}',
                                                  style: textStyle,
                                                ),
                                              ),
                                              DataCell(
                                                Row(
                                                  children: [
                                                    if (isWinner)
                                                      const Icon(
                                                        Icons.emoji_events,
                                                        color: Colors.amber,
                                                        size: 20,
                                                      ),
                                                    if (isWinner)
                                                      const SizedBox(width: 5),
                                                    Text(
                                                      candidate['name'],
                                                      style: textStyle,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              DataCell(
                                                Text(
                                                  candidate['party_name'],
                                                  style: textStyle,
                                                ),
                                              ),
                                              DataCell(
                                                Text(
                                                  candidate['votes'].toString(),
                                                  style: textStyle,
                                                ),
                                              ),
                                              DataCell(
                                                Text(
                                                  '${candidate['percentage']}%',
                                                  style: textStyle,
                                                ),
                                              ),
                                              DataCell(
                                                Text(
                                                  candidate['margin'] != null
                                                      ? '+${candidate['margin']}%'
                                                      : '-',
                                                  style: TextStyle(
                                                    color:
                                                        candidate['margin'] !=
                                                            null
                                                        ? Colors.blue[700]
                                                        : Colors.grey,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  );
                                },
                              ),

                              const SizedBox(height: 15),

                              // TABLE FOOTER
                              if (isMobile)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Total Valid Votes: ${positionData['total_votes']}",
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontStyle: FontStyle.italic,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      "Total Candidates: ${(positionData['candidates'] as List).length}",
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontStyle: FontStyle.italic,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                )
                              else
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Total Valid Votes: ${positionData['total_votes']}",
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontStyle: FontStyle.italic,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      "Total Candidates: ${(positionData['candidates'] as List).length}",
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontStyle: FontStyle.italic,
                                        fontWeight: FontWeight.bold,
                                      ),
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
            ),
        ],
      ),
    );
  }
}
