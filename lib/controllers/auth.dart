// controllers/auth_controller.dart
import 'dart:convert';

import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class AuthController extends GetxController {
  final _storage = GetStorage();
  final _isAuthenticated = false.obs;
  final _authToken = ''.obs;
  final _username = ''.obs;
  final _isLoading = false.obs;

  bool get isAuthenticated => _isAuthenticated.value;
  String get authToken => _authToken.value;
  String get username => _username.value;
  bool get isLoading => _isLoading.value;

  @override
  void onInit() {
    super.onInit();
    _loadSavedLogin();
  }

  void _loadSavedLogin() {
    final token = _storage.read('auth_token');
    final user = _storage.read('username');
    if (token != null && user != null) {
      _authToken.value = token;
      _username.value = user;
      _isAuthenticated.value = true;
    }
  }

  Future<bool> login(String email, String password) async {
    print('Login attempt → $email');

    if (email.isEmpty || password.isEmpty) {
      Get.snackbar('Error', 'Please enter email and password',
          backgroundColor: Colors.red);
      return false;
    }

    _isLoading.value = true;

    try {
      final response = await dio.Dio().post(
        'https://uat.solution.co.ke/api/v1/login', // Update this once you find the correct path
        data: {"email": email.trim(), "password": password},
        options: dio.Options(
          contentType: 'application/json',
          validateStatus: (status) => status! < 500,
        ),
      );

      print('Status: ${response.statusCode}');
      print(
          'Body preview: ${response.data.toString().substring(0, 200)}...'); // Truncate long HTML

      // NEW: Detect HTML response (404 page)
      if (response.data.toString().contains('<!DOCTYPE html>') ||
          response.data.toString().contains('<html>')) {
        print('Detected HTML 404 - wrong endpoint');
        Get.snackbar(
            'Server Error', 'Endpoint not found. Check with backend team.',
            backgroundColor: Colors.red);
        return false;
      }

      // Parse as JSON only if not HTML
      if (response.statusCode == 200) {
        Map<String, dynamic> json;
        try {
          json = response.data is Map<String, dynamic>
              ? response.data
              : jsonDecode(response.data.toString());
        } catch (parseError) {
          print('JSON parse error: $parseError');
          Get.snackbar('Error', 'Invalid server response',
              backgroundColor: Colors.red);
          return false;
        }

        final token = json['token'] as String?;
        final username = json['user']?['username'] ??
            json['user']?['email'] ??
            email.split('@').first;

        if (token == null || token.isEmpty) {
          Get.snackbar('Error', 'No token received',
              backgroundColor: Colors.red);
          return false;
        }

        await _storage.write('auth_token', token);
        await _storage.write('username', username);

        _authToken.value = token;
        _username.value = username;
        _isAuthenticated.value = true;

        print('Login successful!');
        Get.offAllNamed('/dashboard');
        Get.snackbar('Success', 'Welcome $username',
            backgroundColor: Colors.green, colorText: Colors.white);
        return true;
      } else {
        String msg = 'Login failed';
        if (response.data is Map<String, dynamic>) {
          msg = response.data['message']?.toString() ?? msg;
        } else if (response.data is String) {
          msg = response.data;
        }
        Get.snackbar('Failed', msg,
            backgroundColor: Colors.red, colorText: Colors.white);
        return false;
      }
    } on dio.DioException catch (e) {
      print('Dio error: ${e.message}');
      String msg = 'Network error';
      if (e.response != null) {
        final body = e.response!.data.toString();
        if (body.contains('<!DOCTYPE html>') || body.contains('<html>')) {
          msg = 'Endpoint not found (404). Check URL with backend.';
        } else if (e.response!.data is Map<String, dynamic>) {
          msg =
              e.response!.data['message']?.toString() ?? 'Invalid credentials';
        } else {
          msg = body;
        }
      }
      Get.snackbar('Error', msg,
          backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    } catch (e) {
      print('Unexpected error: $e');
      Get.snackbar('Error', 'Unexpected: $e', backgroundColor: Colors.red);
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> logout() async {
    await _storage.erase();
    _authToken.value = '';
    _username.value = '';
    _isAuthenticated.value = false;
    Get.offAllNamed('/login');
  }
}
