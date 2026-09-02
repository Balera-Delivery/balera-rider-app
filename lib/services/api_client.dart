import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic details;

  ApiException(this.message, {this.statusCode, this.details});

  @override
  String toString() => message;
}

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  static const String _tokenKey = 'balera_rider_auth_token';
  String? _authToken;

  String? get token => _authToken;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString(_tokenKey);
    final savedUrl = prefs.getString('custom_server_url');
    if (savedUrl != null && savedUrl.isNotEmpty) {
      ApiConstants.customBaseUrl = savedUrl;
    }
  }

  Future<void> updateBaseUrl(String newUrl) async {
    ApiConstants.customBaseUrl = newUrl.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('custom_server_url', newUrl.trim());
  }

  Future<void> saveToken(String token) async {
    _authToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> clearToken() async {
    _authToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  Map<String, String> _buildHeaders({Map<String, String>? extraHeaders}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_authToken != null && _authToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    if (extraHeaders != null) {
      headers.addAll(extraHeaders);
    }
    return headers;
  }

  Uri _buildUri(String path, [Map<String, dynamic>? queryParameters]) {
    final base = ApiConstants.activeBaseUrl.replaceAll(RegExp(r'/+$'), '');
    final cleanPath = path.startsWith('/') ? path : '/$path';
    final fullUrl = '$base$cleanPath';

    if (queryParameters != null && queryParameters.isNotEmpty) {
      final stringParams = queryParameters.map(
        (key, value) => MapEntry(key, value.toString()),
      );
      return Uri.parse(fullUrl).replace(queryParameters: stringParams);
    }
    return Uri.parse(fullUrl);
  }

  ApiException _socketError() {
    return ApiException(
      'Cannot connect to server at ${ApiConstants.activeBaseUrl}.\n\n'
      '• Over USB: Run "adb reverse tcp:5000 tcp:5000" in terminal.\n'
      '• Over Wi-Fi: Switch to http://192.168.0.135:5000 using the Server Settings icon at the top.',
    );
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      final uri = _buildUri(path, queryParameters);
      final response = await http.get(uri, headers: _buildHeaders());
      return _handleResponse(response);
    } on SocketException {
      throw _socketError();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network request failed: ${e.toString()}');
    }
  }

  Future<dynamic> post(String path, {dynamic body}) async {
    try {
      final uri = _buildUri(path);
      final response = await http.post(
        uri,
        headers: _buildHeaders(),
        body: body != null ? jsonEncode(body) : null,
      );
      return _handleResponse(response);
    } on SocketException {
      throw _socketError();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network request failed: ${e.toString()}');
    }
  }

  Future<dynamic> put(String path, {dynamic body}) async {
    try {
      final uri = _buildUri(path);
      final response = await http.put(
        uri,
        headers: _buildHeaders(),
        body: body != null ? jsonEncode(body) : null,
      );
      return _handleResponse(response);
    } on SocketException {
      throw _socketError();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network request failed: ${e.toString()}');
    }
  }

  Future<dynamic> patch(String path, {dynamic body}) async {
    try {
      final uri = _buildUri(path);
      final response = await http.patch(
        uri,
        headers: _buildHeaders(),
        body: body != null ? jsonEncode(body) : null,
      );
      return _handleResponse(response);
    } on SocketException {
      throw _socketError();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network request failed: ${e.toString()}');
    }
  }

  Future<dynamic> delete(String path) async {
    try {
      final uri = _buildUri(path);
      final response = await http.delete(uri, headers: _buildHeaders());
      return _handleResponse(response);
    } on SocketException {
      throw _socketError();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network request failed: ${e.toString()}');
    }
  }

  dynamic _handleResponse(http.Response response) {
    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      decoded = response.body;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
        return decoded['data'];
      }
      return decoded;
    } else {
      String errorMessage = 'Request failed with status ${response.statusCode}';
      if (decoded is Map<String, dynamic>) {
        if (decoded['message'] != null && decoded['message'].toString().isNotEmpty) {
          errorMessage = decoded['message'].toString();
        } else if (decoded['error'] != null && decoded['error'].toString().isNotEmpty) {
          errorMessage = decoded['error'].toString();
        }
      }
      throw ApiException(errorMessage, statusCode: response.statusCode, details: decoded);
    }
  }
}
