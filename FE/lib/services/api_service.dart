import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:paper_chat/services/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  Future<Map<String, String>> _getHeaders([Map<String, String>? extraHeaders]) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    
    final headers = <String, String>{
      if (token != null) 'Authorization': 'Bearer $token',
    };
    
    if (extraHeaders != null) {
      headers.addAll(extraHeaders);
    }
    
    return headers;
  }

  /// Lấy danh sách Paper từ Backend
  Future<List<Map<String, dynamic>>> getPapers({
    String? search,
    String? collection,
    String? tag,
    bool? isFavorite,
    String? sort,
  }) async {
    final queryParams = <String, String>{
      if (search != null && search.isNotEmpty) 'search': search,
      if (collection != null && collection.isNotEmpty) 'collection': collection,
      if (tag != null && tag.isNotEmpty) 'tag': tag,
      if (isFavorite != null) 'isFavorite': isFavorite.toString(),
      if (sort != null && sort.isNotEmpty) 'sort': sort,
    };

    final url = Uri.parse('${ApiConfig.baseUrl}/paper')
        .replace(queryParameters: queryParams);
    final response = await _client.get(url, headers: await _getHeaders());

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.cast<Map<String, dynamic>>();
    } else {
      throw Exception(
        'Lỗi lấy danh sách bài báo (${response.statusCode}): ${response.body}',
      );
    }
  }

  Future<Map<String, dynamic>> getPaper(int id) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/paper/$id');
    final response = await _client.get(url, headers: await _getHeaders());
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Lỗi lấy bài báo ($id): ${response.body}');
  }

  /// Tải file bài báo lên Backend
  Future<Map<String, dynamic>> uploadPaper(
    List<int> bytes,
    String fileName, {
    String? title,
    String? authors,
    int? year,
    String? collection,
    String? tags,
    String? abstractText,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/paper/upload');
    final request = http.MultipartRequest('POST', url);
    request.headers.addAll(await _getHeaders());

    request.files.add(
      http.MultipartFile.fromBytes('file', bytes, filename: fileName),
    );

    if (title != null) request.fields['title'] = title;
    if (authors != null) request.fields['authors'] = authors;
    if (year != null) request.fields['year'] = year.toString();
    if (collection != null) request.fields['collection'] = collection;
    if (tags != null) request.fields['tags'] = tags;
    if (abstractText != null) request.fields['abstractText'] = abstractText;

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception(
        'Lỗi tải file bài báo (${response.statusCode}): ${response.body}',
      );
    }
  }

  /// Bật/tắt yêu thích bài báo
  Future<Map<String, dynamic>> toggleFavoritePaper(int id) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/paper/$id/favorite');
    final response = await _client.patch(url, headers: await _getHeaders());

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception(
        'Lỗi thay đổi trạng thái yêu thích (${response.statusCode}): ${response.body}',
      );
    }
  }

  /// Xóa bài báo theo ID
  Future<Map<String, dynamic>> deletePaper(int id) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/paper/$id');
    final response = await _client.delete(url, headers: await _getHeaders());

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception(
        'Lỗi xóa bài báo (${response.statusCode}): ${response.body}',
      );
    }
  }

  /// Lấy danh sách tài liệu từ Backend
  Future<List<Map<String, dynamic>>> getDocuments() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/document');
    final response = await _client.get(url, headers: await _getHeaders());

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.cast<Map<String, dynamic>>();
    } else {
      throw Exception(
        'Lỗi lấy danh sách tài liệu (${response.statusCode}): ${response.body}',
      );
    }
  }

  Future<Map<String, dynamic>> getDocumentProgress(int documentId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/document/$documentId/progress');
    final response = await _client.get(url, headers: await _getHeaders());
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Lỗi lấy tiến độ tài liệu: ${response.body}');
  }

  Future<List<Map<String, dynamic>>> getDocumentChunks(int documentId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/document/$documentId/chunks');
    final response = await _client.get(url, headers: await _getHeaders());
    if (response.statusCode == 200) {
      final jsonList = jsonDecode(response.body) as List<dynamic>;
      return jsonList.cast<Map<String, dynamic>>();
    }
    throw Exception('Lỗi lấy nội dung tài liệu: ${response.body}');
  }

  /// Tải file tài liệu lên Backend
  Future<Map<String, dynamic>> uploadDocument(
    List<int> bytes,
    String fileName,
  ) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/document/upload');
    final request = http.MultipartRequest('POST', url);
    request.headers.addAll(await _getHeaders());

    request.files.add(
      http.MultipartFile.fromBytes('file', bytes, filename: fileName),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception(
        'Lỗi tải file (${response.statusCode}): ${response.body}',
      );
    }
  }

  /// Xóa tài liệu theo ID
  Future<Map<String, dynamic>> deleteDocument(int id) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/document/$id');
    final response = await _client.delete(url, headers: await _getHeaders());

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception(
        'Lỗi xóa tài liệu (${response.statusCode}): ${response.body}',
      );
    }
  }

  /// Tái chỉ mục (Reindex) tài liệu
  Future<Map<String, dynamic>> reindexDocument(int id) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/document/$id/reindex');
    final response = await _client.post(url, headers: await _getHeaders());

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception(
        'Lỗi tái chỉ mục (${response.statusCode}): ${response.body}',
      );
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
      headers: await _getHeaders({'Content-Type': 'application/json'}),
      body: body,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception(
        'Lỗi RAG Chat (${response.statusCode}): ${response.body}',
      );
    }
  }

  /// Lấy lịch sử hỏi đáp từ Backend
  Future<List<Map<String, dynamic>>> getHistory({
    String? userId,
    int take = 20,
  }) async {
    final queryParams = <String, String>{
      if (userId != null) 'userId': userId,
      'take': take.toString(),
    };

    final url = Uri.parse('${ApiConfig.baseUrl}/chat/history')
        .replace(queryParameters: queryParams);
    final response = await _client.get(url, headers: await _getHeaders());

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.cast<Map<String, dynamic>>();
    } else {
      throw Exception(
        'Lỗi lấy lịch sử chat (${response.statusCode}): ${response.body}',
      );
    }
  }
}
