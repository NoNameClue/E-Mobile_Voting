import 'package:flutter/material.dart';
import 'api_service.dart';
import 'responsive_screen.dart';

class MyVotesView extends StatefulWidget {
  const MyVotesView({super.key});

  @override
  State<MyVotesView> createState() => _MyVotesViewState();
  Widget build(BuildContext context) {
    return Scaffold(
      body: ResponsiveScreen(
        child: Column(
          children: [
            Text("My Votes", style: TextStyle(fontSize: 24)),
            MyVotesView(),
          ],
        ),
      ),
    );
  }
}

class _MyVotesViewState extends State<MyVotesView> {

  List polls = [];
  Map<String, dynamic>? selectedPoll;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadVotes();
  }

  Future<void> loadVotes() async {

    try {

      List data = await ApiService.getMyVotes();

      setState(() {
        polls = data;

        if (polls.isNotEmpty) {
          selectedPoll = polls.first as Map<String, dynamic>;
        }

        loading = false;
      });

    } catch (e) {

      setState(() {
        loading = false;
      });

    }

  }

  @override
  Widget build(BuildContext context) {

    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (polls.isEmpty) {
      return const Center(
        child: Text("You haven't participated in any elections yet."),
      );
    }

    List candidates = selectedPoll!["candidates"];

    return Scaffold(

      appBar: AppBar(
        title: const Text("My Votes"),
        backgroundColor: const Color(0xFF000B6B),

        actions: [

          DropdownButtonHideUnderline(

            child: DropdownButton(

              dropdownColor: Colors.white,
              value: selectedPoll,
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white),

              items: polls.map((poll) {

                return DropdownMenuItem(
                  value: poll,
                  child: Text(poll["poll_title"]),
                );

              }).toList(),

              onChanged: (value) {
                setState(() {
                  selectedPoll = value as Map<String, dynamic>;
                });
              },

            ),

          ),

          const SizedBox(width: 20)

        ],
      ),

      body: ListView.builder(

        padding: const EdgeInsets.all(8),

        itemCount: candidates.length,

        itemBuilder: (context, index) {

          var candidate = candidates[index];

          return Card(

            elevation: 1,
            margin: const EdgeInsets.symmetric(vertical: 4),

            child: Padding(

              padding: const EdgeInsets.all(8),

              child: Row(

                children: [

                  CircleAvatar(
                    radius: 25,
                    backgroundImage: candidate["photo"] != null
                        ? NetworkImage(candidate["photo"])
                        : null,
                    child: candidate["photo"] == null
                        ? const Icon(Icons.person)
                        : null,
                  ),

                  const SizedBox(width: 10),

                  Expanded(

                    child: Column(

                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [

                        Text(
                          candidate["position"],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF000B6B),
                            fontSize: 14,
                          ),
                        ),

                        Text(
                          candidate["name"],
                          style: const TextStyle(fontSize: 16),
                        ),

                        Text(
                          candidate["party"] ?? "",
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),

                      ],

                    ),

                  )

                ],

              ),

            ),

          );

        },

      ),

    );

  }

}