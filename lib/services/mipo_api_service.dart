import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class MipoApiService {
  static const String baseUrl = 'http://192.168.110.9/mipo_backend';

  static Future<Map<String, dynamic>> getSchedulesAndPet(int userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api_schedules.php?user_id=$userId'),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> manageSchedule(Map<String, dynamic> payload) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api_schedules.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    return jsonDecode(response.body);
  }

  static Future<List<dynamic>> getUserFiles(int userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api_files.php?user_id=$userId'),
    );
    final data = jsonDecode(response.body);
    return data['files'] ?? [];
  }

  static Future<Map<String, dynamic>> uploadFile({
    required int userId,
    required File file,
    required String kategoriFolder,
    required String deskripsiKonten,
  }) async {
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/api_files.php'));
    request.fields['action'] = 'upload';
    request.fields['user_id'] = userId.toString();
    request.fields['kategori_folder'] = kategoriFolder;
    request.fields['deskripsi_konten'] = deskripsiKonten;
    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> askSmartAi({
    required int userId,
    required String message,
    required String history,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api_smart_ai.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'action': 'chat',
        'user_id': userId,
        'message': message,
        'history': history,
      }),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> approveAiSchedules({
    required int userId,
    required List<dynamic> schedules,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api_smart_ai.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'action': 'approve_schedule',
        'user_id': userId,
        'schedules': schedules,
      }),
    );
    return jsonDecode(response.body);
  }
}