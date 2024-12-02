import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:todoapp/models/todo.dart';
import 'package:todoapp/models/user.dart';

class ApiService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final String baseUrl = 'http://172.20.10.2:8000/api';

  Map<String, String> get _headers => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'X-Requested-With': 'XMLHttpRequest',
      };

  Future<Map<String, String>> _getAuthHeaders() async {
    final headers = Map<String, String>.from(_headers);
    final token = await _storage.read(key: 'token');
    if (token != null) {
      final bearerToken = token.startsWith('Bearer ') ? token : 'Bearer $token';
      headers['Authorization'] = bearerToken;
      print("Token $bearerToken");
    } else {
      print("Token null");
    }
    return headers;
  }

  Future<String?> _getCsrfToken() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/sanctum/csrf-cookie'),
        headers: _headers,
      );
      print('CSRF Response Status: ${response.statusCode}');
      print('CSRF Response Headers: ${response.headers}');

      final cookies = response.headers['set-cookie'];
      if (cookies != null) {
        final xsrfToken = cookies.split(';').firstWhere(
              (cookie) => cookie.trim().startsWith('XSRF-TOKEN='),
              orElse: () => '',
            );
        if (xsrfToken.isNotEmpty) {
          return Uri.decodeComponent(xsrfToken.split('=')[1]);
        }
      }
    } catch (e) {
      print('Error fetching CSRF token: $e');
    }
    return null;
  }

  Future<bool> hasValidToken() async {
    final token = await _storage.read(key: 'token');
    return token != null;
  }

  Future<User> register(String name, String email, String password,
      String passwordConfirmation) async {
    try {
      final headers = await _getAuthHeaders();
      final csrfToken = await _getCsrfToken();
      if (csrfToken != null) {
        headers['X-XSRF-TOKEN'] = csrfToken;
      }
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: headers,
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'password_confirmation': passwordConfirmation,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final user = User.fromJson(data['user']);
        user.token = data['token'];
        await _storage.write(key: 'token', value: user.token);
        return user;
      } else {
        throw _handleError(response);
      }
    } catch (e) {
      print('Error registering user: $e');
      throw _handleError(e);
    }
  }

  Future<User> login(String email, String password) async {
    try {
      final headers = await _getAuthHeaders();
      final csrfToken = await _getCsrfToken();
      if (csrfToken != null) {
        headers['X-XSRF-TOKEN'] = csrfToken;
      }
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: headers,
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = User.fromJson(data['user']);
        final token = data['token'].toString();
        user.token = token;
        await _storage.write(key: 'token', value: token);
        return user;
      } else {
        throw _handleError(response);
      }
    } catch (e) {
      print('Error logging in user: $e');
      throw _handleError(e);
    }
  }

  Future<List<Todo>> getTodos() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/todos'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final List<dynamic> data = responseData['todos'] ?? [];
        return data.map((todo) => Todo.fromJson(todo)).toList();
      } else {
        print("Error getting todos: ${response.body}");
        throw _handleError(response);
      }
    } catch (e) {
      print('Error getting todos: $e');
      throw _handleError(e);
    }
  }

  Future<Todo> createTodo(String title, String description) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/todos'),
        headers: headers,
        body: jsonEncode({
          'title': title,
          'description': description,
        }),
      );

      if (response.statusCode == 201) {
        return Todo.fromJson(jsonDecode(response.body));
      } else {
        throw _handleError(response);
      }
    } catch (e) {
      print('Create todo error: $e');
      throw _handleError(e);
    }
  }

  Future<Todo> updateTodo(Todo todo) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/todos/${todo.id}'),
        headers: headers,
        body: jsonEncode(todo.toJson()),
      );

      if (response.statusCode == 200) {
        return Todo.fromJson(jsonDecode(response.body));
      } else {
        throw _handleError(response);
      }
    } catch (e) {
      print('Update todo error: $e');
      throw _handleError(e);
    }
  }

  Future<void> deleteTodo(String id) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/todos/$id'),
        headers: headers,
      );

      if (response.statusCode != 204 && response.statusCode != 200) {
        throw _handleError(response);
      }
    } catch (e) {
      print('Delete todo error: $e');
      throw _handleError(e);
    }
  }

  Future<void> clearToken() async {
    await _storage.delete(key: 'token');
  }

  Future<void> logout() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/logout'),
        headers: headers,
      );
      if (response.statusCode != 401 && response.statusCode != 200) {
        throw _handleError(response);
      }
    } catch (e) {
      print('Logout error: $e');
      await clearToken();
      throw _handleError(e);
    }
  }

  String _handleError(dynamic error) {
    if (error is http.Response) {
      print('Error Response Status: ${error.statusCode}');
      print('Error Response Headers: ${error.headers}');
      print('Error Response Body: ${error.body}');
      try {
        final data = jsonDecode(error.body);
        return data['message'] ?? 'Something went wrong';
      } catch (_) {
        return 'Something went wrong';
      }
    }
    return error.toString();
  }
}
