import 'package:flutter/material.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int selectedIndex = 0;

  // Temporary mock values (replace later with API)
  final int totalStudents = 1200;
  final int pendingApprovals = 5;
  final int activePolls = 0;

  final List<String> menuItems = [
    "Dashboard",
    "Users / Account Control",
    "Manage Polls",
    "Manage Candidates",
    "Live Scoreboard",
    "Reports & Data",
  ];

  void logout() {
    // Later: Clear JWT here
    Navigator.pushReplacementNamed(context, '/login');
  }

  Widget buildSidebar(bool isDesktop) {
    return Container(
      width: 250,
      color: const Color(0xFF000B6B),
      child: Column(
        children: [
          const SizedBox(height: 50),
          const Text(
            "ADMIN PANEL",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 30),

          for (int i = 0; i < menuItems.length; i++)
            ListTile(
              title: Text(
                menuItems[i],
                style: TextStyle(
                  color: selectedIndex == i
                      ? Colors.amber
                      : Colors.white,
                ),
              ),
              onTap: () {
                setState(() {
                  selectedIndex = i;
                });
                if (!isDesktop) Navigator.pop(context);
              },
            ),

          const Spacer(),
          const Divider(color: Colors.white54),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.white),
            title: const Text(
              "Logout",
              style: TextStyle(color: Colors.white),
            ),
            onTap: logout,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget buildStatCard(String title, String value) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(color: Colors.grey[700])),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDashboardHome() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Dashboard",
            style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          Wrap(
            spacing: 20,
            runSpacing: 20,
            children: [
              buildStatCard(
                  "Total Registered Students",
                  totalStudents.toString()),
              buildStatCard(
                  "Pending Account Approvals",
                  pendingApprovals.toString()),
              buildStatCard(
                  "Active Polls",
                  activePolls.toString()),
            ],
          ),

          const SizedBox(height: 40),

          if (activePolls == 0)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.how_to_vote,
                        size: 80, color: Colors.grey),
                    const SizedBox(height: 20),
                    const Text(
                      "No Active Elections",
                      style: TextStyle(fontSize: 20),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          selectedIndex = 2; // Go to Polls
                        });
                      },
                      child:
                          const Text("Create Your First Poll"),
                    )
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget buildContent() {
    switch (selectedIndex) {
      case 0:
        return buildDashboardHome();
      case 1:
        return const Center(
            child: Text("Users / Account Control"));
      case 2:
        return const Center(
            child: Text("Manage Polls"));
      case 3:
        return const Center(
            child: Text("Manage Candidates"));
      case 4:
        return const Center(
            child: Text("Live Scoreboard"));
      case 5:
        return const Center(
            child: Text("Reports & Data"));
      default:
        return buildDashboardHome();
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDesktop =
        MediaQuery.of(context).size.width > 900;

    return Scaffold(
      appBar: isDesktop
          ? null
          : AppBar(
              backgroundColor: const Color(0xFF000B6B),
              title: const Text("Admin Panel"),
            ),
      drawer: isDesktop
          ? null
          : Drawer(child: buildSidebar(false)),
      body: Row(
        children: [
          if (isDesktop) buildSidebar(true),
          Expanded(child: buildContent()),
        ],
      ),
    );
  }
}