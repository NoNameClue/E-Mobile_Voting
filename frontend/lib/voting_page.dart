import 'package:flutter/material.dart';
import 'api_service.dart';
import 'thank_you_page.dart';

class VotingPage extends StatefulWidget {
  const VotingPage({super.key});

  @override
  State<VotingPage> createState() => _VotingPageState();
}

class _VotingPageState extends State<VotingPage> {

  int currentPositionIndex = 0;

  Map<String, int?> selections = {};

  Map<String, List<dynamic>> candidatesByPosition = {};

  List<String> positions = [];

  bool isLoading = true;

  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadCandidates();
  }

  // ================================
  // FETCH CANDIDATES FROM DATABASE
  // ================================
  Future<void> loadCandidates() async {

    try {

      List candidates = await ApiService.fetchCandidates();

      Map<String, List<dynamic>> grouped = {};

      for (var candidate in candidates) {

        String position = candidate["position"];

        if (!grouped.containsKey(position)) {
          grouped[position] = [];
        }

        grouped[position]!.add(candidate);

      }

      setState(() {

        candidatesByPosition = grouped;
        positions = grouped.keys.toList();
        isLoading = false;

      });

    } catch (e) {

      setState(() {
        isLoading = false;
        errorMessage = "Failed to load candidates.";
      });

    }

  }

  // ================================
  // NEXT POSITION
  // ================================
  void nextPosition() {

    if (currentPositionIndex < positions.length - 1) {

      setState(() {
        currentPositionIndex++;
      });

    } else {

      submitBallot();

    }

  }

  // ================================
  // SUBMIT VOTE
  // ================================
  void submitBallot() async {

    try {

      await ApiService.submitVote(selections);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const ThankYouPage(),
        ),
      );

    } catch (e) {

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Already Voted"),
          content: const Text("You have already submitted a ballot."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            )
          ],
        ),
      );

    }

  }

  @override
  Widget build(BuildContext context) {

    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        body: Center(child: Text(errorMessage!)),
      );
    }

    if (positions.isEmpty) {
      return const Scaffold(
        body: Center(child: Text("No candidates available.")),
      );
    }

    String currentPosition = positions[currentPositionIndex];

    List candidates = candidatesByPosition[currentPosition]!;

    return Scaffold(

      appBar: AppBar(
        title: Text("Vote for $currentPosition"),
      ),

      body: Column(

        children: [

          Expanded(

            child: ListView.builder(

              itemCount: candidates.length,

              itemBuilder: (context, index) {

                var candidate = candidates[index];

                return Card(

                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),

                  child: RadioListTile<int>(

                    contentPadding: const EdgeInsets.all(12),

                    title: Row(
                      children: [

                        // Candidate Photo
                        CircleAvatar(
                          radius: 25,
                          backgroundImage: candidate["photo"] != null
                              ? NetworkImage(candidate["photo"])
                              : null,
                          child: candidate["photo"] == null
                              ? const Icon(Icons.person)
                              : null,
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [

                              Text(
                                candidate["name"],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),

                              Text(
                                candidate["party"] ?? "",
                                style: const TextStyle(
                                  color: Colors.grey,
                                ),
                              ),

                              if (candidate["bio"] != null)
                                Text(
                                  candidate["bio"],
                                  style: const TextStyle(
                                    fontSize: 12,
                                  ),
                                ),

                            ],
                          ),
                        ),

                      ],
                    ),

                    value: candidate["candidate_id"],

                    groupValue: selections[currentPosition],

                    onChanged: (value) {

                      setState(() {

                        selections[currentPosition] = value;

                      });

                    },

                  ),

                );

              },

            ),

          ),

          Padding(

            padding: const EdgeInsets.all(16),

            child: SizedBox(

              width: double.infinity,

              child: ElevatedButton(

                onPressed: selections[currentPosition] == null
                    ? null
                    : nextPosition,

                child: Text(
                  currentPositionIndex == positions.length - 1
                      ? "Submit Ballot"
                      : "Next",
                ),

              ),

            ),

          ),

        ],

      ),

    );

  }

}