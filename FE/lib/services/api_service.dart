import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:paper_chat/services/api_config.dart';

class ApiService {
  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  /// Lấy danh sách tài liệu từ Backend
  Future<List<Map<String, dynamic>>> getDocuments() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/document');
    final response = await _client.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Lỗi lấy danh sách tài liệu (${response.statusCode}): ${response.body}');
    }
  }

  /// Tải file tài liệu lên Backend
  Future<Map<String, dynamic>> uploadDocument(List<int> bytes, String fileName) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/document/upload');
    final request = http.MultipartRequest('POST', url);

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: fileName,
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Lỗi tải file (${response.statusCode}): ${response.body}');
    }
  }

  /// Xóa tài liệu theo ID
  Future<Map<String, dynamic>> deleteDocument(int id) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/document/$id');
    final response = await _client.delete(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Lỗi xóa tài liệu (${response.statusCode}): ${response.body}');
    }
  }

  /// Tái chỉ mục (Reindex) tài liệu
  Future<Map<String, dynamic>> reindexDocument(int id) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/document/$id/reindex');
    final response = await _client.post(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Lỗi tái chỉ mục (${response.statusCode}): ${response.body}');
    }
  }

  /// Gửi câu hỏi RAG đến Backend
  Future<Map<String, dynamic>> askQuestion({
    required String question,
    int? documentId,
    String? userId,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/chat/ask');
    final body = jsonEncode({
      'question': question,
      if (documentId != null) 'documentId': documentId,
      if (userId != null) 'userId': userId,
    });

    final response = await _client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Lỗi RAG Chat (${response.statusCode}): ${response.body}');
    }
  }

  /// Lấy lịch sử hỏi đáp từ Backend
  Future<List<Map<String, dynamic>>> getHistory({String? userId, int take = 20}) async {
    final queryParams = <String, String>{
      if (userId != null) 'userId': userId,
      'take': take.toString(),
    };

    final url = Uri.parse('${ApiConfig.baseUrl}/chat/history').replace(queryParameters: queryParams);
    final response = await _client.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Lỗi lấy lịch sử chat (${response.statusCode}): ${response.body}');
    }
  }
}
