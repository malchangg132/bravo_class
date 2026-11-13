import 'dart:convert';

import 'package:http/http.dart' as http;

import 'config.dart';

class SupaException implements Exception {
  SupaException(this.status, this.body);
  final int status;
  final String body;
  @override
  String toString() => 'SupaException($status): $body';
}

/// Klien REST Supabase (PostgREST) yang sederhana.
class Supa {
  static const _timeout = Duration(seconds: 10);

  static Map<String, String> _headers([String? prefer]) => {
        'apikey': kSupabaseKey,
        'Authorization': 'Bearer $kSupabaseKey',
        'Content-Type': 'application/json',
        if (prefer != null) 'Prefer': prefer,
      };

  static Uri _uri(String path, [Map<String, String>? q]) =>
      Uri.parse('$kSupabaseUrl/rest/v1/$path').replace(queryParameters: q);

  static dynamic _decode(http.Response r) {
    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw SupaException(r.statusCode, utf8.decode(r.bodyBytes));
    }
    if (r.bodyBytes.isEmpty) return null;
    return jsonDecode(utf8.decode(r.bodyBytes));
  }

  static Future<List<dynamic>> select(String table, Map<String, String> q) async {
    final r = await http.get(_uri(table, q), headers: _headers()).timeout(_timeout);
    return _decode(r) as List<dynamic>;
  }

  static Future<void> insert(String table, Map<String, dynamic> body) async {
    final r = await http
        .post(_uri(table),
            headers: _headers('return=minimal'), body: jsonEncode(body))
        .timeout(_timeout);
    _decode(r);
  }

  static Future<void> patch(
      String table, Map<String, String> filter, Map<String, dynamic> body) async {
    final r = await http
        .patch(_uri(table, filter),
            headers: _headers('return=minimal'), body: jsonEncode(body))
        .timeout(_timeout);
    _decode(r);
  }

  static Future<void> delete(String table, Map<String, String> filter) async {
    final r = await http
        .delete(_uri(table, filter), headers: _headers('return=minimal'))
        .timeout(_timeout);
    _decode(r);
  }

  static Future<dynamic> rpc(String fn, Map<String, dynamic> args) async {
    final r = await http
        .post(_uri('rpc/$fn'), headers: _headers(), body: jsonEncode(args))
        .timeout(_timeout);
    return _decode(r);
  }
}
