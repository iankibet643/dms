import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mime/mime.dart';
import 'package:my_desktop_uploader/models/models.dart';
import 'package:my_desktop_uploader/services/api_service.dart';

class DocumentController extends GetxController {
  final _api = ApiService();

  // Documents list
  final _documents = <DocumentModel>[].obs;
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

  List<DocumentModel> get documents => _documents;
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
    loadDocuments();
  }

  Future<void> loadDocuments({bool refresh = false}) async {
    if (refresh) {
      _currentPage.value = 1;
      _hasMore.value = true;
      _documents.clear();
    }

    if (!_hasMore.value || _isLoading.value) return;
    _isLoading.value = true;

    try {
      final docs = await _api.getDocuments(
        page: _currentPage.value,
        search: _searchQuery.value.isNotEmpty ? _searchQuery.value : null,
      );

      if (refresh) {
        _documents.assignAll(docs);
      } else {
        _documents.addAll(docs);
      }

      _totalDocuments.value = _documents.length;
      _storageUsed.value =
          _documents.fold(0, (sum, d) => sum + d.size.bytes);

      if (docs.isEmpty) _hasMore.value = false;
      _currentPage.value++;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Could not load documents.',
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

  // ── File Picking ─────────────────────────────────────────────────────

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

  // ── Upload ──────────────────────────────────────────────────────────

  Future<void> uploadSelectedFiles() async {
    if (_selectedFiles.isEmpty) return;

    _isUploading.value = true;
    _uploadProgress.value = 0;
    _uploadResults.clear();

    final files = List<PlatformFile>.from(_selectedFiles);
    int done = 0;

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

        final doc = await _api.uploadDocument(
          fileContent: base64Content,
          fileName: file.name,
          mimeType: mime,
        );

        _uploadResults.add(UploadResult(
          fileName: file.name,
          success: true,
          message: 'Uploaded successfully',
          document: doc,
        ));

        // Add to document list immediately
        _documents.insert(0, doc);
        _totalDocuments.value = _documents.length;
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

  // ── Delete ──────────────────────────────────────────────────────────

  Future<void> deleteDocument(String id) async {
    final deleted = await _api.deleteDocument(id);
    if (deleted) {
      _documents.removeWhere((d) => d.id == id);
      _totalDocuments.value = _documents.length;
      Get.snackbar(
        'Deleted',
        'Document removed successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF2ECC71),
        colorText: Colors.white,
      );
    }
  }
}
