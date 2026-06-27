import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:my_desktop_uploader/constants.dart';
import 'package:my_desktop_uploader/controllers/auth_controller.dart';
import 'package:my_desktop_uploader/controllers/document_controller.dart';
import 'package:my_desktop_uploader/pages/login_page.dart';
import 'package:my_desktop_uploader/pages/main_shell_page.dart';
import 'package:my_desktop_uploader/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  runApp(const SphereDmsApp());
}

class SphereDmsApp extends StatelessWidget {
  const SphereDmsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Sphere DMS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      initialBinding: _AppBindings(),
      initialRoute: AppConstants.routeLogin,
      getPages: [
        GetPage(
          name: AppConstants.routeLogin,
          page: () => const LoginPage(),
          transition: Transition.fadeIn,
          transitionDuration: const Duration(milliseconds: 400),
        ),
        GetPage(
          name: AppConstants.routeDashboard,
          page: () => const MainShellPage(),
          binding: BindingsBuilder(() {
            Get.lazyPut<DocumentController>(() => DocumentController());
          }),
          transition: Transition.fadeIn,
          transitionDuration: const Duration(milliseconds: 400),
          middlewares: [_AuthMiddleware()],
        ),
      ],
    );
  }
}

class _AppBindings extends Bindings {
  @override
  void dependencies() {
    Get.put(AuthController(), permanent: true);
  }
}

class _AuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final auth = Get.find<AuthController>();
    if (!auth.isAuthenticated) {
      return const RouteSettings(name: AppConstants.routeLogin);
    }
    return null;
  }
}
