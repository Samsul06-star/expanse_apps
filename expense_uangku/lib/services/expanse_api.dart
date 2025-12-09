import 'dart:convert';
import 'package:expense_uangku/core/variables/variabels.dart';
import 'package:http/http.dart' as http;
import '../models/expanse.dart';
import 'package:expense_uangku/services/users_api.dart'; // added import

class ExpanseService {
  final http.Client client = http.Client();

  // Helper: build headers with authorization if token exists
  Future<Map<String, String>> _authorizationHeaders() async {
    final token = await UsersApi.getToken();
    final headers = {"Content-Type": "application/json"};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // Helper: extract user id from JWT token payload (if the token payload contains user_id)
  int? _getUserIdFromToken(String? token) {
    if (token == null || token.isEmpty) return null;
    try {
      final parts = token.split('.');
      if (parts.length < 2) return null;
      var payload = parts[1];

      // pad base64 string if needed
      final requiredPadding = payload.length % 4;
      if (requiredPadding > 0) {
        payload = payload.padRight(payload.length + (4 - requiredPadding), '=');
      }

      final decoded = utf8.decode(base64Url.decode(payload));
      final Map<String, dynamic> jsonPayload = jsonDecode(decoded);
      // common claim names: user_id, id, sub, userId
      final uid = jsonPayload['user_id'] ??
          jsonPayload['userId'] ??
          jsonPayload['id'] ??
          jsonPayload['sub'];
      if (uid == null) return null;

      if (uid is int) return uid;
      if (uid is String) {
        return int.tryParse(uid);
      }
      return null;
    } catch (e) {
      // decoding failed
      print('decode token failed: $e');
      return null;
    }
  }

  // ============================
  // ADD EXPANSE
  // ============================
  Future<Expanse?> addExpanse(
    String category,
    String type,
    int amount,
    String description,
    DateTime date,
  ) async {
    // Format tanggal ke UTC ISO 8601
    final isoDate = date.toUtc().toIso8601String();

    try {
      final headers = await _authorizationHeaders();
      final token = await UsersApi.getToken();
      final userId = _getUserIdFromToken(token);

      // Don't hardcode user_id anymore — include if available
      final requestBody = {
        if (userId != null) "user_id": userId,
        "category": category,
        "type": type,
        "amount": amount,
        "description": description,
        "date": isoDate,
      };

      print("=== REQUEST ===");
      print("URL: ${Variables.urlApi}/expenses");
      print("Headers: $headers");
      print("Body: ${jsonEncode(requestBody)}");

      final response = await client.post(
        Uri.parse("${Variables.urlApi}/expenses"),
        headers: headers,
        body: jsonEncode(requestBody),
      );

      print("=== RESPONSE ===");
      print("Status: ${response.statusCode}");
      print("Body: ${response.body}");

      if (response.statusCode == 201 || response.statusCode == 200) {
        return Expanse.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      print("=== ERROR ===");
      print("addExpanse error: $e");
      return null;
    }
  }

  // ============================
  // GET ALL EXPANSE
  // ============================
  Future<List<Expanse>> getAllExpanse() async {
    try {
      final headers = await _authorizationHeaders();

      final response = await client.get(
        Uri.parse("${Variables.urlApi}/expenses"),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is List) {
          return data.map((e) => Expanse.fromJson(e)).toList();
        } else {
          // Kalau backend kirim objek, bukan list
          return [];
        }
      }

      return [];
    } catch (e) {
      print("Error getAllExpanse: $e");
      return [];
    }
  }

  // ============================
  // GET BY ID
  // ============================
  Future<Expanse?> getExpanse(int id) async {
    try {
      final headers = await _authorizationHeaders();

      final response = await client.get(
        Uri.parse("${Variables.urlApi}/expenses/$id"),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return Expanse.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ============================
  // UPDATE EXPANSE
  // ============================
  Future<Expanse?> updateExpanse(int id, Expanse data) async {
    try {
      final headers = await _authorizationHeaders();

      final response = await client.put(
        Uri.parse("${Variables.urlApi}/expenses/$id"),
        headers: headers,
        body: jsonEncode({
          "category": data.category,
          "type": data.type,
          "amount": data.amount,
          "description": data.description,
          "date": data.date.toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return Expanse.fromJson(body);
      }

      return null;
    } catch (e) {
      print("updateExpanse error: $e");
      return null;
    }
  }

  // ============================
  // DELETE EXPANSE
  // ============================
  Future<bool> deleteExpanse(int id) async {
    try {
      final headers = await _authorizationHeaders();

      final response = await client.delete(
        Uri.parse("${Variables.urlApi}/expenses/$id"),
        headers: headers,
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
