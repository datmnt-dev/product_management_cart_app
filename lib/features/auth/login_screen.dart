import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/router.dart';
import '../../core/theme/app_motion.dart';
import '../../core/utils/validators.dart';
import '../../data/models/user_role.dart';
import '../../state/auth_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _rememberMe = true;
  bool _obscurePassword = true;
  bool _isSubmitting = false;
  AppRole _selectedDemoRole = AppRole.customer;

  @override
  void initState() {
    super.initState();
    _rememberMe = context.read<AuthController>().rememberMe;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final result = await context.read<AuthController>().login(
      email: _emailController.text,
      password: _passwordController.text,
      rememberMe: _rememberMe,
    );

    if (!mounted) return;

    setState(() => _isSubmitting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        behavior: SnackBarBehavior.floating,
      ),
    );

    if (result.success) {
      context.go(AppRoutes.products);
    }
  }

  void _fillDemo(AppRole role, String email) {
    setState(() {
      _selectedDemoRole = role;
      _emailController.text = email;
      _passwordController.text = '123456';
      _rememberMe = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      body: Stack(
        children: [
          // ── Background decorations ──
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cs.primary.withValues(alpha: .06),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cs.secondary.withValues(alpha: .04),
              ),
            ),
          ),

          // ── Main scroll content ──
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ── Brand header with enter motion ──
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: 1),
                          duration: AppMotion.enter,
                          curve: AppMotion.enterCurve,
                          builder: (context, t, child) {
                            if (AppMotion.reduceMotion(context)) {
                              return child!;
                            }
                            return Opacity(
                              opacity: t,
                              child: Transform.translate(
                                offset: Offset(0, 16 * (1 - t)),
                                child: child,
                              ),
                            );
                          },
                          child: Center(
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 24),
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    cs.primary,
                                    cs.primary.withValues(alpha: .85),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: cs.primary.withValues(alpha: .18),
                                    blurRadius: 25,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 46,
                                    height: 46,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: .18),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.shopping_bag_outlined,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'StoreFlow',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 20,
                                          letterSpacing: -.3,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Premium Shopping Hub',
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: .7,
                                          ),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // ── Welcome titles ──
                        Text(
                          'Chào mừng quay trở lại',
                          textAlign: TextAlign.center,
                          style: tt.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: -.4,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Đăng nhập tài khoản demo hoặc nhập thông tin của bạn bên dưới',
                          textAlign: TextAlign.center,
                          style: tt.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 26),

                        // ── Interactive demo selection panels ──
                        const Text(
                          'Chọn tài khoản Demo nhanh:',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Chỉ dùng cho môi trường demo / lab. Mật khẩu: 123456',
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _DemoPanel(
                              role: AppRole.admin,
                              email: 'admin@store.local',
                              isSelected: _selectedDemoRole == AppRole.admin,
                              onTap: _fillDemo,
                            ),
                            const SizedBox(width: 8),
                            _DemoPanel(
                              role: AppRole.manager,
                              email: 'manager@store.local',
                              isSelected: _selectedDemoRole == AppRole.manager,
                              onTap: _fillDemo,
                            ),
                            const SizedBox(width: 8),
                            _DemoPanel(
                              role: AppRole.customer,
                              email: 'customer@store.local',
                              isSelected: _selectedDemoRole == AppRole.customer,
                              onTap: _fillDemo,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // ── Form fields ──
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Địa chỉ Email',
                            hintText: 'name@domain.com',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: Validators.email,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submit(),
                          decoration: InputDecoration(
                            labelText: 'Mật khẩu',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              tooltip: _obscurePassword
                                  ? 'Hiện mật khẩu'
                                  : 'Ẩn mật khẩu',
                              onPressed: () {
                                setState(
                                  () => _obscurePassword = !_obscurePassword,
                                );
                              },
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                          validator: Validators.password,
                        ),
                        const SizedBox(height: 6),

                        // ── Remember Me ──
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          value: _rememberMe,
                          onChanged: (val) => setState(() => _rememberMe = val),
                          title: Text(
                            'Duy trì đăng nhập',
                            style: tt.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),

                        // ── Submit actions ──
                        FilledButton(
                          onPressed: _isSubmitting ? null : _submit,
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.login_outlined),
                                    SizedBox(width: 8),
                                    Text('Đăng nhập'),
                                  ],
                                ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _isSubmitting
                              ? null
                              : () => context.go(AppRoutes.register),
                          icon: const Icon(Icons.person_add_outlined),
                          label: const Text('Tạo tài khoản mới'),
                        ),
                      ],
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

class _DemoPanel extends StatelessWidget {
  const _DemoPanel({
    required this.role,
    required this.email,
    required this.isSelected,
    required this.onTap,
  });

  final AppRole role;
  final String email;
  final bool isSelected;
  final void Function(AppRole role, String email) onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: isSelected
              ? role.accentColor.withValues(alpha: .12)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? role.accentColor
                : cs.outlineVariant.withValues(alpha: .45),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: role.accentColor.withValues(alpha: .15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => onTap(role, email),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          role.icon,
                          size: 22,
                          color: isSelected
                              ? role.accentColor
                              : cs.onSurfaceVariant,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          role.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: isSelected ? role.accentColor : cs.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Positioned(
                      top: -6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: role.accentColor,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 10,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
