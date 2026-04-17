import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart'; // Using your dynamic config

class ApiService {

  // static const String baseUrl = "http://127.0.0.1:8000";

  // 1. NEW: Check if user already voted
  static Future<bool> checkVoteStatus(int pollId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';

    final response = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/api/vote/status/$pollId"),
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['has_voted'];
    }
    return false;
  }

  // 2. UPDATED: Accepts dynamic pollId
  static Future submitVote(int pollId, Map selections) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';

    final response = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/api/vote"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "poll_id": pollId, 
        "candidate_ids": selections.values.toList()
      }),
    );

    if (response.statusCode == 403) {
      throw Exception("ALREADY_VOTED");
    } else if (response.statusCode != 200) {
      throw Exception("Server Error");  
    }
  }

  // 3. UPDATED: Accepts dynamic pollId
  static Future<List<dynamic>> fetchCandidates(int pollId) async {
    final response = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/api/candidates/$pollId")
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load candidates");
    }
  }

  static Future<List<dynamic>> getMyVotes() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';

    // Replace this URL with the actual URL to your backend
    final url = Uri.parse("${ApiConfig.baseUrl}/api/users/me/votes");

    final response = await http.get(
      url,
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load history");
    }
  }
} 