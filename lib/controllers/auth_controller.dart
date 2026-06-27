import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:my_desktop_uploader/constants.dart';
import 'package:my_desktop_uploader/models/models.dart';
import 'package:my_desktop_uploader/services/api_service.dart';

class AuthController extends GetxController {
  final _storage = GetStorage();
  final _api = ApiService();

  final _isAuthenticated = false.obs;
  final _isLoading = false.obs;
  final _user = Rxn<UserModel>();

  bool get isAuthenticated => _isAuthenticated.value;
  bool get isLoading => _isLoading.value;
  UserModel? get user => _user.value;

  String get username => _user.value?.username ?? '';
  String get displayName => _user.value?.fullName ?? username;
  String get avatar => _user.value?.avatar ?? '';

  @override
  void onInit() {
    super.onInit();
    _restoreSession();
  }

  void _restoreSession() {
    final token = _storage.read<String>(AppConstants.tokenKey);
    final userStr = _storage.read<String>(AppConstants.userKey);
    if (token != null && userStr != null) {
      _isAuthenticated.value = true;
      try {
        _user.value = UserModel.fromStorageString(userStr);
      } catch (_) {}
    }
  }

  Future<bool> login(String username, String password) async {
    _isLoading.value = true;
    try {
      final result = await _api.login(username: username, password: password);
      await _storage.write(AppConstants.tokenKey, result.accessToken);
      await _storage.write(
          AppConstants.userKey, result.user.toStorageString());
      _user.value = result.user;
      _isAuthenticated.value = true;
      return true;
    } on ApiError catch (e) {
      Get.snackbar(
        'Login Failed',
        e.message,
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color(0xFFE74C3C),
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
      return false;
    } catch (e) {
      Get.snackbar(
        'Network Error',
        'Could not connect to server. Please check your connection.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color(0xFFE74C3C),
        colorText: Colors.white,
      );
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> refreshProfile() async {
    try {
      final updatedUser = await _api.getProfile();
      _user.value = updatedUser;
      await _storage.write(
          AppConstants.userKey, updatedUser.toStorageString());
    } catch (_) {}
  }

  Future<void> logout() async {
    await _storage.erase();
    _isAuthenticated.value = false;
    _user.value = null;
    Get.offAllNamed(AppConstants.routeLogin);
  }
}
