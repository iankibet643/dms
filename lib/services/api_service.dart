import 'package:dio/dio.dart';
import 'package:get_storage/get_storage.dart';
import 'package:my_desktop_uploader/constants.dart';
import 'package:my_desktop_uploader/models/models.dart';

class ApiService {
  late final Dio _dio;
  final _storage = GetStorage();

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
      headers: {
        'Accept': 'application/json',
        'x-source-system': AppConstants.sourceSystem,
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = _storage.read<String>(AppConstants.tokenKey);
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onResponse: (response, handler) {
        // Log response for debugging
        // ignore: avoid_print
        print('[API] ${response.requestOptions.method} '
            '${response.requestOptions.path} '
            '→ ${response.statusCode}');
        handler.next(response);
      },
      onError: (error, handler) {
        // ignore: avoid_print
        print('[API ERROR] ${error.requestOptions.path}: '
            '${error.message} | ${error.response?.statusCode}');
        handler.next(error);
      },
    ));
  }

  // ── Auth ────────────────────────────────────────────────────────────────

  Future<AuthResponse> login({
    required String username,
    required String password,
    String device = 'Desktop App',
  }) async {
    try {
      // Use URL-encoded form data (not multipart) for CORS compatibility
      // on Flutter Web. Multipart triggers a CORS preflight that most
      // Laravel APIs reject unless explicitly configured.
      final response = await _dio.post(
        'login',
        data: {
          'username': username,
          'password': password,
          'device': device,
        },
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
          validateStatus: (status) => status != null && status < 600,
        ),
      );

      // ignore: avoid_print
      print('[LOGIN] status=${response.statusCode} data=${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return AuthResponse.fromJson(response.data as Map<String, dynamic>);
      }

      final err = ApiError.fromJson(
        response.data as Map<String, dynamic>? ?? {},
        statusCode: response.statusCode,
      );
      throw err;
    } on DioException catch (e) {
      // ignore: avoid_print
      print('[LOGIN DioError] ${e.type}: ${e.message}');
      throw ApiError(
        message: e.type == DioExceptionType.connectionTimeout ||
                e.type == DioExceptionType.receiveTimeout
            ? 'Request timed out. Check your connection.'
            : e.message ?? 'Network error',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<UserModel> getProfile() async {
    final response = await _dio.get('user');
    if (response.statusCode == 200) {
      final data = (response.data as Map<String, dynamic>)['data']
          as Map<String, dynamic>;
      return UserModel.fromJson(data);
    }
    throw ApiError.fromJson(
      response.data as Map<String, dynamic>? ?? {},
      statusCode: response.statusCode,
    );
  }

  // ── Documents ───────────────────────────────────────────────────────────

  Future<List<DocumentModel>> getDocuments({
    int page = 1,
    String? search,
    String? folderId,
  }) async {
    final params = <String, dynamic>{'page': page};
    if (search != null && search.isNotEmpty) params['q'] = search;
    if (folderId != null) params['folder_id'] = folderId;

    final response = await _dio.get('documents', queryParameters: params);

    if (response.statusCode == 200) {
      final body = response.data as Map<String, dynamic>;
      final List items = body['data'] as List? ?? [];
      return items
          .map((e) => DocumentModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<DocumentModel> uploadDocument({
    required String fileContent,
    required String fileName,
    required String mimeType,
  }) async {
    final formData = FormData.fromMap({
      'file_content': fileContent,
      'file_name': fileName,
      'mime_type': mimeType,
    });

    final response = await _dio.post(
      'upload',
      data: formData,
      options: Options(
        validateStatus: (status) => status != null && status < 500,
        contentType: 'multipart/form-data',
      ),
    );

    if (response.statusCode == 200 ||
        response.statusCode == 201 ||
        response.statusCode == 202) {
      final body = response.data as Map<String, dynamic>;
      return DocumentModel.fromJson(body['data'] as Map<String, dynamic>);
    }

    throw ApiError.fromJson(
      response.data as Map<String, dynamic>? ?? {},
      statusCode: response.statusCode,
    );
  }

  Future<bool> deleteDocument(String id) async {
    final response = await _dio.delete('documents/$id');
    return response.statusCode == 200 || response.statusCode == 204;
  }

  Future<List<DocumentModel>> searchDocuments(String query) async {
    final response = await _dio.get('search', queryParameters: {'q': query});
    if (response.statusCode == 200) {
      final body = response.data as Map<String, dynamic>;
      final List items = body['data'] as List? ?? [];
      return items
          .map((e) => DocumentModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }
}
