import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {

  static const String baseUrl = "http://10.0.2.2:8000";

  static Future submitVote(Map selections) async {

  final response = await http.post(
    Uri.parse("$baseUrl/api/vote"),
    headers: {
      "Content-Type": "application/json",
    },
    body: jsonEncode({
      "poll_id": 1,
      "candidate_ids": selections.values.toList()
    }),
  );

  if (response.statusCode != 200) {
    throw Exception("Vote failed");  
  }

}

  static Future<List<dynamic>> fetchCandidates() async {

  final response = await http.get(
    Uri.parse("$baseUrl/api/candidates")
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception("Failed to load candidates");
  }
}
}