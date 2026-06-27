import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:my_desktop_uploader/constants.dart';
import 'package:my_desktop_uploader/controllers/auth_controller.dart';
import 'package:my_desktop_uploader/theme/app_theme.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _auth = Get.find<AuthController>();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  // Explicit FocusNodes — required on Flutter Web to avoid the
  // "targetElement == domElement" pointer binding assertion when
  // calling FocusScope.of(context).nextFocus() inside a Transform widget.
  final _usernameFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _animated = false;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    // Post-frame callback ensures the widget tree is fully built before
    // starting animation — prevents web rendering race conditions.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _animCtrl.forward();
        Future.delayed(const Duration(milliseconds: 80), () {
          if (mounted) setState(() => _animated = true);
        });
      }
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    // Dismiss keyboard before network call
    FocusManager.instance.primaryFocus?.unfocus();
    final success = await _auth.login(
      _usernameCtrl.text.trim(),
      _passwordCtrl.text,
    );
    if (success) Get.offAllNamed(AppConstants.routeDashboard);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Row(
        children: [
          // ── Left panel (branding) ──────────────────────────────────
          Expanded(
            flex: 5,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF0D1326),
                    AppTheme.primaryDark,
                    Color(0xFF0A1628),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: -80,
                    left: -80,
                    child: _GlowCircle(size: 300, opacity: 0.08),
                  ),
                  Positioned(
                    bottom: -60,
                    right: -60,
                    child: _GlowCircle(size: 250, opacity: 0.06),
                  ),
                  Positioned(
                    top: 200,
                    right: 40,
                    child: _GlowCircle(size: 120, opacity: 0.04),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(60),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Logo
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                gradient: AppTheme.primaryGradient,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.folder_special_rounded,
                                  color: Colors.white, size: 26),
                            ),
                            const SizedBox(width: 14),
                            const Text(
                              'Sphere DMS',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        // Headline
                        ShaderMask(
                          shaderCallback: (bounds) =>
                              AppTheme.primaryGradient.createShader(bounds),
                          child: const Text(
                            'Your Documents,\nOrganized.',
                            style: TextStyle(
                              fontSize: 46,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.15,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Securely upload, manage, and share all\nyour important files from one place.',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 16,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 48),
                        Wrap(
                          spacing: 12,
                          runSpacing: 10,
                          children: [
                            _FeaturePill(Icons.lock_outline_rounded,
                                'End-to-End Secure'),
                            _FeaturePill(
                                Icons.cloud_done_rounded, 'Cloud Storage'),
                            _FeaturePill(
                                Icons.search_rounded, 'Smart Search'),
                            _FeaturePill(Icons.share_rounded, 'Easy Sharing'),
                          ],
                        ),
                        const Spacer(),
                        const Divider(color: Color(0x14FFFFFF)),
                        const SizedBox(height: 16),
                        const Row(
                          children: [
                            Icon(Icons.copyright,
                                size: 14, color: AppTheme.textSecondary),
                            SizedBox(width: 6),
                            Text(
                              '2025 Sphere DMS · Razor Informatics',
                              style: TextStyle(
                                  color: Color(0x608B92A5), fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Right panel (login form) ──────────────────────────────
          // KEY FIX: Use FadeTransition + AnimatedPadding instead of
          // SlideTransition. SlideTransition uses a Transform matrix widget
          // which causes Flutter Web's pointer binding engine to fail with:
          //   "targetElement == domElement"
          // because the DOM input element's computed offset no longer
          // matches what Flutter expects when inside a CSS transform.
          Expanded(
            flex: 4,
            child: FadeTransition(
              opacity: _fadeAnim,
              child: AnimatedPadding(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOut,
                padding: EdgeInsets.only(top: _animated ? 0 : 28),
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 56, vertical: 40),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Welcome back',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Sign in to access your document vault',
                            style: TextStyle(
                              fontSize: 15,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 40),
                          Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const _Label('Username or Email'),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _usernameCtrl,
                                  focusNode: _usernameFocus,
                                  autofocus: false,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  style: const TextStyle(
                                      color: AppTheme.textPrimary),
                                  decoration: const InputDecoration(
                                    hintText: 'Enter your username',
                                    prefixIcon:
                                        Icon(Icons.person_outline_rounded),
                                  ),
                                  validator: (v) =>
                                      (v?.isEmpty ?? true) ? 'Required' : null,
                                  onFieldSubmitted: (_) {
                                    // Delay focus transfer slightly — avoids
                                    // the web input offset assertion.
                                    _usernameFocus.unfocus();
                                    Future.delayed(
                                        const Duration(milliseconds: 50), () {
                                      if (mounted) {
                                        FocusScope.of(context)
                                            .requestFocus(_passwordFocus);
                                      }
                                    });
                                  },
                                ),
                                const SizedBox(height: 20),
                                const _Label('Password'),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _passwordCtrl,
                                  focusNode: _passwordFocus,
                                  autofocus: false,
                                  obscureText: _obscurePassword,
                                  textInputAction: TextInputAction.done,
                                  style: const TextStyle(
                                      color: AppTheme.textPrimary),
                                  decoration: InputDecoration(
                                    hintText: 'Enter your password',
                                    prefixIcon: const Icon(
                                        Icons.lock_outline_rounded),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                      ),
                                      onPressed: () => setState(() =>
                                          _obscurePassword = !_obscurePassword),
                                    ),
                                  ),
                                  validator: (v) =>
                                      (v?.isEmpty ?? true) ? 'Required' : null,
                                  onFieldSubmitted: (_) => _handleLogin(),
                                ),
                                const SizedBox(height: 32),
                                Obx(() => SizedBox(
                                      height: 52,
                                      child: ElevatedButton(
                                        onPressed: _auth.isLoading
                                            ? null
                                            : _handleLogin,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.primary,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(14),
                                          ),
                                        ),
                                        child: _auth.isLoading
                                            ? const SizedBox(
                                                width: 22,
                                                height: 22,
                                                child:
                                                    CircularProgressIndicator(
                                                  color: Colors.white,
                                                  strokeWidth: 2.5,
                                                ),
                                              )
                                            : const Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    'Sign In',
                                                    style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w700),
                                                  ),
                                                  SizedBox(width: 8),
                                                  Icon(
                                                      Icons
                                                          .arrow_forward_rounded,
                                                      size: 20),
                                                ],
                                              ),
                                      ),
                                    )),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Center(
                            child: TextButton(
                              onPressed: () {
                                _usernameCtrl.text =
                                    'developer@razorinformatics.co.ke';
                                _passwordCtrl.text = '12345678';
                                // Auto-submit after filling
                                Future.delayed(
                                    const Duration(milliseconds: 100),
                                    _handleLogin);
                              },
                              child: const Text(
                                'Use demo credentials',
                                style:
                                    TextStyle(color: AppTheme.textSecondary),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppTheme.textSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  final double size;
  final double opacity;
  const _GlowCircle({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.primary.withValues(alpha: opacity),
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeaturePill(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppTheme.accent),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
