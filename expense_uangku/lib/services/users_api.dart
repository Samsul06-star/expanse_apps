import 'dart:convert';
import 'dart:typed_data';
import 'package:mime/mime.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:io';
import 'package:expense_uangku/core/variables/variabels.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:expense_uangku/models/user.dart';

class UsersApi {
  // Login: POST /login
  // body: {"email":"john@example.com","password":"secret123"}
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('${Variables.urlApi}/login');

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final body = _tryDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final token = _extractToken(body);
        final userJson = _extractUserJson(body);
        if (userJson != null) {
          await saveUser(userJson);
        }

        if (token != null && token.isNotEmpty) {
          await saveToken(token);
          return {
            'success': true,
            'token': token,
            'user': userJson,
            'body': body
          };
        }

        return {
          'success': false,
          'message': 'Token tidak ditemukan',
          'body': body,
          'user': userJson
        };
      } else {
        final message =
            _tryGetMessage(body) ?? 'Login gagal (${response.statusCode})';
        return {'success': false, 'message': message, 'body': body};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Register: POST /register
  // body: {"full_name":"John Doe","email":"john@example.com","password":"secret123"}
  static Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('${Variables.urlApi}/register');

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'full_name': fullName,
          'email': email,
          'password': password,
        }),
      );

      final body = _tryDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final token = _extractToken(body);
        final userJson = _extractUserJson(body);
        if (userJson != null) {
          await saveUser(userJson);
        }

        if (token != null && token.isNotEmpty) {
          await saveToken(token);
          return {
            'success': true,
            'token': token,
            'user': userJson,
            'body': body
          };
        }

        return {'success': true, 'body': body, 'user': userJson};
      } else {
        final message =
            _tryGetMessage(body) ?? 'Register gagal (${response.statusCode})';
        return {'success': false, 'message': message, 'body': body};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Save token ke SharedPreferences
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

// filepath: [users_api.dart](http://_vscodecontentref_/1)
  static Future<bool> deleteToken() async {
    final prefs = await SharedPreferences.getInstance();
    final had = prefs.containsKey('auth_token');
    await prefs.remove('auth_token');
    return had;
  }

  // Save user ke SharedPreferences
  // save user json and normalize avatar to full URL if needed
  static Future<void> saveUser(Map<String, dynamic> userJson) async {
    final prefs = await SharedPreferences.getInstance();
    final m = Map<String, dynamic>.from(userJson);

    if (m.containsKey('avatar') &&
        m['avatar'] != null &&
        m['avatar'].toString().isNotEmpty) {
      final avatarVal = m['avatar'].toString();
      if (!avatarVal.startsWith('http')) {
        m['avatar'] = '${Variables.urlApi}/$avatarVal';
      }
    }

    await prefs.setString('auth_user', jsonEncode(m));
  }

  static Future<Map<String, dynamic>?> getUserJson() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('auth_user');
    if (raw == null || raw.isEmpty) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }

  static Future<void> deleteUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_user');
  }

  // Authorization header helper
  static Future<Map<String, String>> authorizationHeader() async {
    final token = await getToken();
    if (token != null && token.isNotEmpty) {
      return {'Authorization': 'Bearer $token'};
    }
    return {};
  }

  static Future<Map<String, dynamic>?> updateUser({
    required int userId,
    String? fullName,
    String? birthDate, // Use 'YYYY-MM-DD'
    File? avatarFile,
  }) async {
    final token = await getToken();
    if (token == null || token.isEmpty) {
      return {'success': false, 'message': 'Not authenticated'};
    }

    final uri = Uri.parse('${Variables.urlApi}/users/$userId');
    final request = http.MultipartRequest('PUT', uri);
    request.headers['Authorization'] = 'Bearer $token';

    if (fullName != null && fullName.trim().isNotEmpty) {
      request.fields['full_name'] = fullName.trim();
    }

    if (birthDate != null && birthDate.trim().isNotEmpty) {
      request.fields['birth_date'] = birthDate.trim();
    }

    if (avatarFile != null && await avatarFile.exists()) {
      final mimeType = lookupMimeType(avatarFile.path) ?? 'image/jpeg';
      final parts = mimeType.split('/');
      request.files.add(await http.MultipartFile.fromPath(
        'avatar',
        avatarFile.path,
        contentType: MediaType(parts[0], parts[1]),
      ));
    }

    try {
      final streamed = await request.send();
      final responseStr = await streamed.stream.bytesToString();
      final status = streamed.statusCode;

      final body = _tryDecode(responseStr);
      if (status == 200 || status == 201) {
        // If backend returns user object, save it
        final userJson = _extractUserJson(body);
        if (userJson != null) {
          await saveUser(userJson);
        }
        return {
          'success': true,
          'body': body,
          'user': userJson,
        };
      } else {
        final msg = _tryGetMessage(body) ?? 'Update failed ($status)';
        return {'success': false, 'message': msg, 'body': body};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // fetch avatar bytes using Bearer token auth; return bytes or null
  static Future<Uint8List?> fetchAvatarBytes(String avatarUrlOrPath) async {
    final token = await getToken();
    if (token == null || token.isEmpty) return null;

    // allow avatarUrlOrPath to be either full url or filename

    Uri uri = Uri.parse('${Variables.urlApi}/$avatarUrlOrPath');

    final res = await http.get(uri, headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'image/*',
    });

    if (res.statusCode == 200) {
      return res.bodyBytes;
    }
    return null;
  }

  // Helpers
  static dynamic _tryDecode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      return jsonDecode(raw);
    } catch (_) {
      return null;
    }
  }

  static String? _extractToken(dynamic body) {
    if (body == null) return null;

    if (body is Map) {
      if (body['token'] is String) return body['token'];
      if (body['access_token'] is String) return body['access_token'];
      if (body['data'] is Map) {
        if (body['data']['token'] is String) return body['data']['token'];
        if (body['data']['access_token'] is String)
          return body['data']['access_token'];
      }
    }

    return null;
  }

  static Map<String, dynamic>? _extractUserJson(dynamic body) {
    if (body == null) return null;

    if (body is Map) {
      if (body['user'] is Map) return Map<String, dynamic>.from(body['user']);
      if (body['data'] is Map) {
        final data = body['data'];
        if (data['user'] is Map) return Map<String, dynamic>.from(data['user']);
        // If data itself is user object
        if (data.containsKey('id') && data.containsKey('email'))
          return Map<String, dynamic>.from(data);
      }
      // If top-level contains user fields
      if (body.containsKey('id') && body.containsKey('email')) {
        return Map<String, dynamic>.from(body);
      }
    }

    return null;
  }

  static String? _tryGetMessage(dynamic body) {
    if (body is Map) {
      if (body['message'] is String) return body['message'];
      if (body['error'] is String) return body['error'];
      if (body['data'] is Map && body['data']['message'] is String)
        return body['data']['message'];
    }
    return null;
  }
}
