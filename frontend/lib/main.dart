// import 'package:flutter/material.dart';
// import 'login_page.dart';
// import 'signup_page.dart';
// import 'student_dashboard.dart';
// import 'admin_dashboard.dart';
// import 'responsive_screen.dart';

// void main() {
//   runApp(const LnuVotingApp());
// }

// class LnuVotingApp extends StatelessWidget {
//   const LnuVotingApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'LNU Voting System',
//       theme: ThemeData(
//         primaryColor: const Color(0xFF000B6B),
//         scaffoldBackgroundColor: const Color(0xFFE5E5E5),
//         fontFamily: 'Roboto',
//       ),

//       debugShowCheckedModeBanner: false,

//       // THIS becomes your first screen
//       home: Scaffold(
//         body: ResponsiveScreen(
//           child: Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 const Text(
//                   "LNU Voting System",
//                   style: TextStyle(
//                     fontSize: 32,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),

//                 const SizedBox(height: 20),

//                 ElevatedButton(
//                   onPressed: () =>
//                       Navigator.pushNamed(context, '/login'),
//                   child: const Text("Login"),
//                 ),

//                 ElevatedButton(
//                   onPressed: () =>
//                       Navigator.pushNamed(context, '/signup'),
//                   child: const Text("Sign Up"),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),

//       routes: {
//         '/login': (context) => const LoginPage(),
//         '/signup': (context) => const SignupPage(),
//         '/student_home': (context) => const StudentDashboard(),
//         '/admin_dashboard': (context) => const AdminDashboard(),
//       },
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'login_page.dart';
import 'signup_page.dart';
import 'student_dashboard.dart';
import 'admin_dashboard.dart';
// import 'responsive_screen.dart';

void main() {
  runApp(const LnuVotingApp());
}

class LnuVotingApp extends StatelessWidget {
  const LnuVotingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LNU Voting System',
      theme: ThemeData(
        primaryColor: const Color(0xFF000B6B),
        scaffoldBackgroundColor: const Color(0xFFE5E5E5), 
        fontFamily: 'Roboto',
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignupPage(),
        '/student_home': (context) => const StudentDashboard(),     
        '/admin_dashboard': (context) => const AdminDashboard(), 
      },
      debugShowCheckedModeBanner: false,
    );
    // return Scaffold(
    //   body: ResponsiveScreen(
    //     child: Center(
    //       child: Column(
    //         children: [
    //           Text("LNU Voting System", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
    //           SizedBox(height: 20),
    //           ElevatedButton(
    //             onPressed: () => Navigator.pushNamed(context, '/login'),
    //             child: Text("Login"),
    //           ),
    //           ElevatedButton(
    //             onPressed: () => Navigator.pushNamed(context, '/signup'),
    //             child: Text("Sign Up"),
    //           ),
    //         ],
    //         )
    //     )
    //     )
    // );
  }
}
