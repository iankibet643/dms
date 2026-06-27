/// Sphere DMS — App Constants
class AppConstants {
  // API Base URL — update to your server
  static const String baseUrl = 'https://towg.digichama.co.ke/api/v1/';

  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'auth_user';

  // Source system header
  static const String sourceSystem = 'windows';

  // Supported mime types
  static const List<String> supportedMimes = [
    'application/pdf',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'application/vnd.ms-excel',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'application/vnd.ms-powerpoint',
    'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    'image/jpeg',
    'image/png',
    'image/gif',
    'image/webp',
    'text/plain',
    'text/csv',
    'application/zip',
    'application/x-zip-compressed',
    'video/mp4',
    'audio/mpeg',
  ];

  // Max file size (50 MB)
  static const int maxFileSizeBytes = 50 * 1024 * 1024;

  // App routes
  static const String routeLogin = '/login';
  static const String routeDashboard = '/dashboard';
  static const String routeDocuments = '/documents';
  static const String routeDocumentDetail = '/document-detail';
  static const String routeUpload = '/upload';
  static const String routeFolders = '/folders';
  static const String routeProfile = '/profile';
  static const String routeSearch = '/search';
}
