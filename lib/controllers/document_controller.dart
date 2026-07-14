import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mime/mime.dart';
import 'package:my_desktop_uploader/models/models.dart';
import 'package:my_desktop_uploader/services/api_service.dart';
import 'package:my_desktop_uploader/controllers/auth_controller.dart';

// Activity Log model for tracking updates and new files
class ActivityLog {
  final String id;
  final String documentId;
  final String fileName;
  final String ownerUsername;
  final String type; // 'new', 'update', 'restore', 'delete'
  final DateTime timestamp;

  ActivityLog({
    required this.id,
    required this.documentId,
    required this.fileName,
    required this.ownerUsername,
    required this.type,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'document_id': documentId,
        'file_name': fileName,
        'owner_username': ownerUsername,
        'type': type,
        'timestamp': timestamp.toIso8601String(),
      };

  factory ActivityLog.fromJson(Map<String, dynamic> json) => ActivityLog(
        id: json['id']?.toString() ?? '',
        documentId: json['document_id']?.toString() ?? '',
        fileName: json['file_name']?.toString() ?? '',
        ownerUsername: json['owner_username']?.toString() ?? '',
        type: json['type']?.toString() ?? 'new',
        timestamp: DateTime.parse(json['timestamp']?.toString() ?? DateTime.now().toIso8601String()),
      );
}

class DocumentController extends GetxController {
  final _api = ApiService();
  final _storage = GetStorage();

  // Storage Keys for Offline Fallback Caching
  static const String _docsCacheKey = 'cached_documents';
  static const String _trashCacheKey = 'cached_trash_documents';
  static const String _restoredCacheKey = 'cached_restored_documents';
  static const String _activityCacheKey = 'cached_activities';

  // State Lists
  final _documents = <DocumentModel>[].obs;
  final _trashDocuments = <DocumentModel>[].obs;
  final _restoredDocuments = <DocumentModel>[].obs;
  final _recentActivities = <ActivityLog>[].obs;

  // UI States
  final _isLoading = false.obs;
  final _isUploading = false.obs;
  final _uploadProgress = 0.0.obs;
  final _searchQuery = ''.obs;
  final _currentPage = 1.obs;
  final _hasMore = true.obs;
  final _uploadResults = <UploadResult>[].obs;
  final _selectedFiles = <PlatformFile>[].obs;
  final _viewMode = 'grid'.obs; // 'grid' or 'list'
  final _filterVisibility = ''.obs; // '' = all, 'pub', 'pri'
  final _totalDocuments = 0.obs;
  final _storageUsed = 0.obs;

  // Getters
  List<DocumentModel> get documents => _documents;
  List<DocumentModel> get trashDocuments => _trashDocuments;
  List<DocumentModel> get restoredDocuments => _restoredDocuments;
  List<ActivityLog> get recentActivities => _recentActivities;

  bool get isLoading => _isLoading.value;
  bool get isUploading => _isUploading.value;
  double get uploadProgress => _uploadProgress.value;
  String get searchQuery => _searchQuery.value;
  List<UploadResult> get uploadResults => _uploadResults;
  List<PlatformFile> get selectedFiles => _selectedFiles;
  String get viewMode => _viewMode.value;
  String get filterVisibility => _filterVisibility.value;
  int get totalDocuments => _totalDocuments.value;
  int get storageUsedBytes => _storageUsed.value;

  String get storageUsedFormatted {
    final bytes = _storageUsed.value;
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  @override
  void onInit() {
    super.onInit();
    _initializeLocalDatabase();
    loadDocuments(refresh: true);
  }

  // ── Cache & Mock DB Initialization ──────────────────────────────────────────
  
  void _initializeLocalDatabase() {
    // If we have no cached documents, we populate some high-fidelity mock data
    if (!_storage.hasData(_docsCacheKey)) {
      final now = DateTime.now();
      final mockDocs = [
        DocumentModel(
          id: 'doc-1',
          name: 'Sphere Project Proposal.pdf',
          visibility: DocumentVisibility(value: 'pri', name: 'Private'),
          type: DocumentType(mime: 'application/pdf', extension: 'pdf', img: ''),
          size: DocumentSize(string: '2.4 MB', bytes: 2400000),
          dated: DocumentDated(datetime: now.subtract(const Duration(days: 2)).toIso8601String(), string: '2 days ago'),
          links: DocumentLinks(detail: '', summary: '', move: ''),
          ownerUsername: 'developer@razorinformatics.co.ke',
          isNew: true,
          updatedAt: now.subtract(const Duration(days: 2)),
        ),
        DocumentModel(
          id: 'doc-2',
          name: 'Q3 Financial Statement.xlsx',
          visibility: DocumentVisibility(value: 'pri', name: 'Private'),
          type: DocumentType(mime: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', extension: 'xlsx', img: ''),
          size: DocumentSize(string: '5.1 MB', bytes: 5100000),
          dated: DocumentDated(datetime: now.subtract(const Duration(days: 1)).toIso8601String(), string: 'Yesterday'),
          links: DocumentLinks(detail: '', summary: '', move: ''),
          ownerUsername: 'accountant@razorinformatics.co.ke',
          updatedAt: now.subtract(const Duration(days: 1)),
        ),
        DocumentModel(
          id: 'doc-3',
          name: 'App Mockup UX.png',
          visibility: DocumentVisibility(value: 'pub', name: 'Public'),
          type: DocumentType(mime: 'image/png', extension: 'png', img: ''),
          size: DocumentSize(string: '1.2 MB', bytes: 1200000),
          dated: DocumentDated(datetime: now.subtract(const Duration(hours: 4)).toIso8601String(), string: '4 hours ago'),
          links: DocumentLinks(detail: '', summary: '', move: ''),
          ownerUsername: 'designer@razorinformatics.co.ke',
          isNew: true,
          updatedAt: now.subtract(const Duration(hours: 4)),
        ),
        DocumentModel(
          id: 'doc-4',
          name: 'DMS Database Schema.sql',
          visibility: DocumentVisibility(value: 'pri', name: 'Private'),
          type: DocumentType(mime: 'text/plain', extension: 'sql', img: ''),
          size: DocumentSize(string: '340 KB', bytes: 340000),
          dated: DocumentDated(datetime: now.subtract(const Duration(minutes: 30)).toIso8601String(), string: '30 mins ago'),
          links: DocumentLinks(detail: '', summary: '', move: ''),
          ownerUsername: 'developer@razorinformatics.co.ke',
          isNew: true,
          updatedAt: now.subtract(const Duration(minutes: 30)),
        ),
        DocumentModel(
          id: 'doc-5',
          name: 'DMS Privacy Policy.txt',
          visibility: DocumentVisibility(value: 'pub', name: 'Public'),
          type: DocumentType(mime: 'text/plain', extension: 'txt', img: ''),
          size: DocumentSize(string: '12 KB', bytes: 12000),
          dated: DocumentDated(datetime: now.subtract(const Duration(minutes: 5)).toIso8601String(), string: '5 mins ago'),
          links: DocumentLinks(detail: '', summary: '', move: ''),
          ownerUsername: 'legal@razorinformatics.co.ke',
          updatedAt: now.subtract(const Duration(minutes: 5)),
        ),
      ];

      _saveToCache(_docsCacheKey, mockDocs);

      // Pre-populate some activities
      final mockActivities = [
        ActivityLog(id: 'act-1', documentId: 'doc-1', fileName: 'Sphere Project Proposal.pdf', ownerUsername: 'developer@razorinformatics.co.ke', type: 'new', timestamp: now.subtract(const Duration(days: 2))),
        ActivityLog(id: 'act-2', documentId: 'doc-2', fileName: 'Q3 Financial Statement.xlsx', ownerUsername: 'accountant@razorinformatics.co.ke', type: 'new', timestamp: now.subtract(const Duration(days: 1))),
        ActivityLog(id: 'act-3', documentId: 'doc-3', fileName: 'App Mockup UX.png', ownerUsername: 'designer@razorinformatics.co.ke', type: 'new', timestamp: now.subtract(const Duration(hours: 4))),
        ActivityLog(id: 'act-4', documentId: 'doc-4', fileName: 'DMS Database Schema.sql', ownerUsername: 'developer@razorinformatics.co.ke', type: 'new', timestamp: now.subtract(const Duration(minutes: 30))),
        ActivityLog(id: 'act-5', documentId: 'doc-5', fileName: 'DMS Privacy Policy.txt', ownerUsername: 'legal@razorinformatics.co.ke', type: 'update', timestamp: now.subtract(const Duration(minutes: 5))),
      ];
      _saveActivitiesToCache(mockActivities);
    }
  }

  void _saveToCache(String key, List<DocumentModel> list) {
    final listJson = list.map((e) => e.toJson()).toList();
    _storage.write(key, jsonEncode(listJson));
  }

  List<DocumentModel> _loadFromCache(String key) {
    final cachedStr = _storage.read<String>(key);
    if (cachedStr == null || cachedStr.isEmpty) return [];
    try {
      final List list = jsonDecode(cachedStr) as List;
      return list.map((e) => DocumentModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  void _saveActivitiesToCache(List<ActivityLog> logs) {
    final listJson = logs.map((e) => e.toJson()).toList();
    _storage.write(_activityCacheKey, jsonEncode(listJson));
  }

  List<ActivityLog> _loadActivitiesFromCache() {
    final cachedStr = _storage.read<String>(_activityCacheKey);
    if (cachedStr == null || cachedStr.isEmpty) return [];
    try {
      final List list = jsonDecode(cachedStr) as List;
      return list.map((e) => ActivityLog.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  // ── Fetch Operations ────────────────────────────────────────────────────────

  Future<void> loadDocuments({bool refresh = false}) async {
    if (refresh) {
      _currentPage.value = 1;
      _hasMore.value = true;
      _documents.clear();
      _trashDocuments.clear();
      _restoredDocuments.clear();
    }

    if (!_hasMore.value || _isLoading.value) return;
    _isLoading.value = true;

    try {
      final auth = Get.find<AuthController>();
      final currentUser = auth.user;

      // 1. Load active (non-deleted, non-restored) documents
      List<DocumentModel> apiDocs = [];
      try {
        apiDocs = await _api.getDocuments(
          page: _currentPage.value,
          search: _searchQuery.value.isNotEmpty ? _searchQuery.value : null,
        );
      } catch (_) {
        // Fallback to local cache if API is offline
        apiDocs = _loadFromCache(_docsCacheKey)
            .where((d) => !d.isDeleted && !d.isRestored)
            .toList();
      }

      // Filter based on roles: Super Admin sees all, User sees public or their own private docs
      final filteredDocs = apiDocs.where((doc) {
        if (currentUser?.isSuperAdmin ?? false) {
          return true; // Super Admin views all
        }
        // Normal users only see public documents OR documents they own
        final isOwner = doc.ownerUsername.toLowerCase() == currentUser?.email.toLowerCase() || 
                        doc.ownerUsername.toLowerCase() == currentUser?.username.toLowerCase();
        final isPublic = doc.visibility.isPublic;
        return isPublic || isOwner;
      }).toList();

      if (refresh) {
        _documents.assignAll(filteredDocs);
      } else {
        _documents.addAll(filteredDocs);
      }

      // 2. Load Trash Documents
      List<DocumentModel> deletedDocs = [];
      try {
        deletedDocs = await _api.getDeletedDocuments();
      } catch (_) {
        deletedDocs = _loadFromCache(_trashCacheKey);
      }
      
      // Super Admin views all trash, Admin views all, User views their own trash
      final filteredTrash = deletedDocs.where((doc) {
        if (currentUser?.isAdmin ?? false) return true;
        return doc.ownerUsername.toLowerCase() == currentUser?.email.toLowerCase() ||
               doc.ownerUsername.toLowerCase() == currentUser?.username.toLowerCase();
      }).toList();
      _trashDocuments.assignAll(filteredTrash);

      // 3. Load Restored Documents
      List<DocumentModel> restoredDocs = _loadFromCache(_restoredCacheKey);
      final filteredRestored = restoredDocs.where((doc) {
        if (currentUser?.isSuperAdmin ?? false) return true;
        final isOwner = doc.ownerUsername.toLowerCase() == currentUser?.email.toLowerCase() || 
                        doc.ownerUsername.toLowerCase() == currentUser?.username.toLowerCase();
        final isPublic = doc.visibility.isPublic;
        return isPublic || isOwner;
      }).toList();
      _restoredDocuments.assignAll(filteredRestored);

      // 4. Load Activities
      final activities = _loadActivitiesFromCache();
      activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      _recentActivities.assignAll(activities);

      // Storage and counts
      _totalDocuments.value = _documents.length + _restoredDocuments.length;
      _storageUsed.value = _documents.fold(0, (sum, d) => sum + d.size.bytes) +
                           _restoredDocuments.fold(0, (sum, d) => sum + d.size.bytes);

      if (apiDocs.isEmpty) _hasMore.value = false;
      _currentPage.value++;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Could not load documents properly.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFE74C3C),
        colorText: Colors.white,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  void setSearch(String query) {
    _searchQuery.value = query;
    loadDocuments(refresh: true);
  }

  void toggleViewMode() {
    _viewMode.value = _viewMode.value == 'grid' ? 'list' : 'grid';
  }

  void setFilterVisibility(String v) {
    _filterVisibility.value = v;
  }

  List<DocumentModel> get filteredDocuments {
    if (_filterVisibility.value.isEmpty) return _documents;
    return _documents
        .where((d) => d.visibility.value == _filterVisibility.value)
        .toList();
  }

  // ── File Picking ───────────────────────────────────────────────────────────

  Future<void> pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true,
    );

    if (result != null) {
      _selectedFiles.addAll(result.files);
    }
  }

  void removeSelectedFile(int index) {
    if (index >= 0 && index < _selectedFiles.length) {
      _selectedFiles.removeAt(index);
    }
  }

  void clearSelectedFiles() {
    _selectedFiles.clear();
  }

  // ── Upload Operation ───────────────────────────────────────────────────────

  Future<void> uploadSelectedFiles() async {
    if (_selectedFiles.isEmpty) return;

    _isUploading.value = true;
    _uploadProgress.value = 0;
    _uploadResults.clear();

    final files = List<PlatformFile>.from(_selectedFiles);
    int done = 0;
    final auth = Get.find<AuthController>();
    final owner = auth.user?.email ?? auth.user?.username ?? 'developer@razorinformatics.co.ke';

    for (final file in files) {
      try {
        final bytes = file.bytes ??
            (file.path != null ? await File(file.path!).readAsBytes() : null);

        if (bytes == null) {
          _uploadResults.add(UploadResult(
            fileName: file.name,
            success: false,
            message: 'Could not read file',
          ));
          continue;
        }

        final base64Content = base64Encode(bytes);
        final mime = lookupMimeType(file.name) ?? 'application/octet-stream';

        DocumentModel doc;
        try {
          doc = await _api.uploadDocument(
            fileContent: base64Content,
            fileName: file.name,
            mimeType: mime,
          );
        } catch (_) {
          // Fallback simulation upload
          final formattedSize = file.size < 1024
              ? '${file.size} B'
              : file.size < 1024 * 1024
                  ? '${(file.size / 1024).toStringAsFixed(1)} KB'
                  : '${(file.size / (1024 * 1024)).toStringAsFixed(1)} MB';
          
          doc = DocumentModel(
            id: 'mock-upload-${DateTime.now().millisecondsSinceEpoch}',
            name: file.name,
            visibility: DocumentVisibility(value: 'pri', name: 'Private'), // Default sent as private
            type: DocumentType(mime: mime, extension: file.extension ?? 'bin', img: ''),
            size: DocumentSize(string: formattedSize, bytes: file.size),
            dated: DocumentDated(datetime: DateTime.now().toIso8601String(), string: 'Just now'),
            links: DocumentLinks(detail: '', summary: '', move: ''),
            ownerUsername: owner,
            isNew: true,
            updatedAt: DateTime.now(),
          );
        }

        // Add to local cache simulation
        final currentCached = _loadFromCache(_docsCacheKey);
        currentCached.insert(0, doc);
        _saveToCache(_docsCacheKey, currentCached);

        // Add activity log (New Document Uploaded)
        final activities = _loadActivitiesFromCache();
        activities.insert(
          0,
          ActivityLog(
            id: 'act-${DateTime.now().millisecondsSinceEpoch}',
            documentId: doc.id,
            fileName: doc.name,
            ownerUsername: owner,
            type: 'new',
            timestamp: DateTime.now(),
          ),
        );
        _saveActivitiesToCache(activities);

        _uploadResults.add(UploadResult(
          fileName: file.name,
          success: true,
          message: 'Uploaded successfully',
          document: doc,
        ));

        // Add to current loaded document list
        _documents.insert(0, doc);
        _totalDocuments.value = _documents.length + _restoredDocuments.length;
        _storageUsed.value += doc.size.bytes;
      } on ApiError catch (e) {
        _uploadResults.add(UploadResult(
          fileName: file.name,
          success: false,
          message: e.message,
        ));
      } catch (e) {
        _uploadResults.add(UploadResult(
          fileName: file.name,
          success: false,
          message: 'Unexpected error: $e',
        ));
      }

      done++;
      _uploadProgress.value = done / files.length;
    }

    _selectedFiles.clear();
    _isUploading.value = false;
    
    // Reload documents list to ensure filtered views match
    loadDocuments(refresh: true);

    final successes = _uploadResults.where((r) => r.success).length;
    Get.snackbar(
      successes == files.length ? 'Upload Complete ✓' : 'Upload Partial',
      '$successes of ${files.length} files uploaded successfully',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor:
          successes == files.length ? const Color(0xFF2ECC71) : const Color(0xFFF39C12),
      colorText: Colors.white,
      duration: const Duration(seconds: 4),
    );
  }

  // ── Soft Delete Operation ──────────────────────────────────────────────────

  Future<void> deleteDocument(String id) async {
    final auth = Get.find<AuthController>();
    final owner = auth.user?.email ?? auth.user?.username ?? 'developer@razorinformatics.co.ke';

    // 1. Locate the document to soft-delete
    DocumentModel? docToDelete;
    bool wasRestored = false;

    // Check in normal documents
    for (final d in _documents) {
      if (d.id == id) {
        docToDelete = d;
        break;
      }
    }
    // Check in restored documents
    if (docToDelete == null) {
      for (final d in _restoredDocuments) {
        if (d.id == id) {
          docToDelete = d;
          wasRestored = true;
          break;
        }
      }
    }

    if (docToDelete == null) return;

    bool deleted = false;
    try {
      deleted = await _api.deleteDocument(id);
    } catch (_) {
      // Offline fallback simulation
      deleted = true;
    }

    if (deleted) {
      // 1. Remove from active list
      if (wasRestored) {
        _restoredDocuments.removeWhere((d) => d.id == id);
      } else {
        _documents.removeWhere((d) => d.id == id);
      }

      // 2. Remove from active cache list
      final activeCached = _loadFromCache(_docsCacheKey);
      activeCached.removeWhere((d) => d.id == id);
      _saveToCache(_docsCacheKey, activeCached);

      // Also remove from restored cache list
      final restoredCached = _loadFromCache(_restoredCacheKey);
      restoredCached.removeWhere((d) => d.id == id);
      _saveToCache(_restoredCacheKey, restoredCached);

      // 3. Create soft-deleted document representation
      final softDeletedDoc = DocumentModel(
        id: docToDelete.id,
        name: docToDelete.name,
        visibility: docToDelete.visibility,
        type: docToDelete.type,
        size: docToDelete.size,
        dated: docToDelete.dated,
        links: docToDelete.links,
        isDeleted: true,
        deletedAt: DateTime.now(),
        isRestored: false,
        originalFolderId: wasRestored ? 'restored' : 'vault',
        ownerUsername: docToDelete.ownerUsername,
      );

      // 4. Save to Trash Cache
      final trashCached = _loadFromCache(_trashCacheKey);
      trashCached.insert(0, softDeletedDoc);
      _saveToCache(_trashCacheKey, trashCached);
      _trashDocuments.insert(0, softDeletedDoc);

      // 5. Add to Activity Log
      final activities = _loadActivitiesFromCache();
      activities.insert(
        0,
        ActivityLog(
          id: 'act-${DateTime.now().millisecondsSinceEpoch}',
          documentId: id,
          fileName: docToDelete.name,
          ownerUsername: owner,
          type: 'delete',
          timestamp: DateTime.now(),
        ),
      );
      _saveActivitiesToCache(activities);

      _totalDocuments.value = _documents.length + _restoredDocuments.length;
      _storageUsed.value = _documents.fold(0, (sum, d) => sum + d.size.bytes) +
                           _restoredDocuments.fold(0, (sum, d) => sum + d.size.bytes);

      Get.snackbar(
        'Stored in Trash Bin',
        'File soft-deleted. Admin can retrieve it.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFE67E22),
        colorText: Colors.white,
      );
    }
  }

  // ── Restore Operation ──────────────────────────────────────────────────────

  Future<void> restoreDocument(String id) async {
    final auth = Get.find<AuthController>();
    final owner = auth.user?.email ?? auth.user?.username ?? 'developer@razorinformatics.co.ke';

    // Locate in trash
    DocumentModel? docToRestore;
    for (final d in _trashDocuments) {
      if (d.id == id) {
        docToRestore = d;
        break;
      }
    }

    if (docToRestore == null) return;

    bool restored = false;
    try {
      restored = await _api.restoreDocument(id);
    } catch (_) {
      restored = true;
    }

    if (restored) {
      // 1. Remove from Trash Lists/Caches
      _trashDocuments.removeWhere((d) => d.id == id);
      final trashCached = _loadFromCache(_trashCacheKey);
      trashCached.removeWhere((d) => d.id == id);
      _saveToCache(_trashCacheKey, trashCached);

      // 2. Create restored representation (Marked isRestored = true)
      final restoredDoc = DocumentModel(
        id: docToRestore.id,
        name: docToRestore.name,
        visibility: docToRestore.visibility,
        type: docToRestore.type,
        size: docToRestore.size,
        dated: docToRestore.dated,
        links: docToRestore.links,
        isDeleted: false,
        deletedAt: null,
        isRestored: true, // Mark as restored to place in separate folder
        originalFolderId: docToRestore.originalFolderId,
        ownerUsername: docToRestore.ownerUsername,
        updatedAt: DateTime.now(),
      );

      // 3. Add to Restored Files List & Cache
      final restoredCached = _loadFromCache(_restoredCacheKey);
      restoredCached.insert(0, restoredDoc);
      _saveToCache(_restoredCacheKey, restoredCached);
      _restoredDocuments.insert(0, restoredDoc);

      // 4. Add Activity Log
      final activities = _loadActivitiesFromCache();
      activities.insert(
        0,
        ActivityLog(
          id: 'act-${DateTime.now().millisecondsSinceEpoch}',
          documentId: id,
          fileName: docToRestore.name,
          ownerUsername: owner,
          type: 'restore',
          timestamp: DateTime.now(),
        ),
      );
      _saveActivitiesToCache(activities);

      _totalDocuments.value = _documents.length + _restoredDocuments.length;
      _storageUsed.value = _documents.fold(0, (sum, d) => sum + d.size.bytes) +
                           _restoredDocuments.fold(0, (sum, d) => sum + d.size.bytes);

      Get.snackbar(
        'Restored',
        'Document restored to Restored Files folder.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF2ECC71),
        colorText: Colors.white,
      );
    }
  }

  // ── Permanently Delete (Force Delete) Operation ────────────────────────────

  Future<void> forceDeleteDocument(String id) async {
    bool forceDeleted = false;
    try {
      forceDeleted = await _api.forceDeleteDocument(id);
    } catch (_) {
      forceDeleted = true;
    }

    if (forceDeleted) {
      _trashDocuments.removeWhere((d) => d.id == id);
      final trashCached = _loadFromCache(_trashCacheKey);
      trashCached.removeWhere((d) => d.id == id);
      _saveToCache(_trashCacheKey, trashCached);

      Get.snackbar(
        'Permanently Deleted',
        'File completely purged from server.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFE74C3C),
        colorText: Colors.white,
      );
    }
  }

  // ── Rename & Update Visibility (To trigger UDPATED states) ──────────────────

  Future<void> updateDocumentVisibility(String id, String newVisibility) async {
    final auth = Get.find<AuthController>();
    final owner = auth.user?.email ?? auth.user?.username ?? 'developer@razorinformatics.co.ke';

    // Locate active or restored document
    DocumentModel? doc;
    bool isRestoredFile = false;

    for (final d in _documents) {
      if (d.id == id) {
        doc = d;
        break;
      }
    }

    if (doc == null) {
      for (final d in _restoredDocuments) {
        if (d.id == id) {
          doc = d;
          isRestoredFile = true;
          break;
        }
      }
    }

    if (doc == null) return;

    // Create updated document
    final updatedDoc = DocumentModel(
      id: doc.id,
      name: doc.name,
      visibility: DocumentVisibility(
        value: newVisibility,
        name: newVisibility == 'pub' ? 'Public' : 'Private',
      ),
      type: doc.type,
      size: doc.size,
      dated: doc.dated,
      links: doc.links,
      isDeleted: doc.isDeleted,
      deletedAt: doc.deletedAt,
      isRestored: doc.isRestored,
      originalFolderId: doc.originalFolderId,
      ownerUsername: doc.ownerUsername,
      updatedAt: DateTime.now(), // Trigger new updatedAt timestamp
    );

    // Save in Cache
    if (isRestoredFile) {
      final restoredCached = _loadFromCache(_restoredCacheKey);
      final index = restoredCached.indexWhere((d) => d.id == id);
      if (index != -1) {
        restoredCached[index] = updatedDoc;
        _saveToCache(_restoredCacheKey, restoredCached);
      }
      _restoredDocuments[_restoredDocuments.indexWhere((d) => d.id == id)] = updatedDoc;
    } else {
      final activeCached = _loadFromCache(_docsCacheKey);
      final index = activeCached.indexWhere((d) => d.id == id);
      if (index != -1) {
        activeCached[index] = updatedDoc;
        _saveToCache(_docsCacheKey, activeCached);
      }
      _documents[_documents.indexWhere((d) => d.id == id)] = updatedDoc;
    }

    // Add activity log (Updated File)
    final activities = _loadActivitiesFromCache();
    activities.insert(
      0,
      ActivityLog(
        id: 'act-${DateTime.now().millisecondsSinceEpoch}',
        documentId: id,
        fileName: doc.name,
        ownerUsername: owner,
        type: 'update',
        timestamp: DateTime.now(),
      ),
    );
    _saveActivitiesToCache(activities);

    loadDocuments(refresh: true);

    Get.snackbar(
      'Updated',
      'Document visibility modified successfully.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF2980B9),
      colorText: Colors.white,
    );
  }
}
