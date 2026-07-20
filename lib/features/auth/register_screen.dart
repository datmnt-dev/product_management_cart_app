import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/router.dart';
import '../../core/utils/validators.dart';
import '../../state/auth_controller.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final result = await context.read<AuthController>().register(
      fullName: _fullNameController.text,
      email: _emailController.text,
      password: _passwordController.text,
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
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Đăng ký tài khoản')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Tạo tài khoản mới',
                      style: tt.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tài khoản đăng ký mới sẽ có mặc định vai trò Customer.',
                      style: tt.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Visual role badge container ──
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            cs.secondary.withValues(alpha: .12),
                            cs.secondary.withValues(alpha: .03),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: cs.secondary.withValues(alpha: .25),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: cs.secondary.withValues(alpha: .16),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.shopping_basket_outlined,
                              color: cs.secondary,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Vai trò: Customer',
                                  style: tt.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: cs.secondary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Quyền mua sắm, quản lý giỏ hàng, đặt hàng & thanh toán.',
                                  style: tt.bodySmall?.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Form fields ──
                    TextFormField(
                      controller: _fullNameController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Họ và tên',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (value) =>
                          Validators.requiredText(value, 'họ tên'),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Địa chỉ Email',
                        hintText: 'you@domain.com',
                        prefixIcon: Icon(Icons.alternate_email),
                      ),
                      validator: Validators.email,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.next,
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
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        labelText: 'Xác nhận mật khẩu',
                        prefixIcon: const Icon(Icons.lock_person_outlined),
                        suffixIcon: IconButton(
                          tooltip: _obscureConfirmPassword
                              ? 'Hiện mật khẩu'
                              : 'Ẩn mật khẩu',
                          onPressed: () {
                            setState(
                              () => _obscureConfirmPassword =
                                  !_obscureConfirmPassword,
                            );
                          },
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: (value) => Validators.confirmPassword(
                        value,
                        _passwordController.text,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Actions ──
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
                                Icon(Icons.how_to_reg_outlined),
                                SizedBox(width: 8),
                                Text('Đăng ký tài khoản'),
                              ],
                            ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _isSubmitting
                          ? null
                          : () => context.go(AppRoutes.login),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Quay lại đăng nhập'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
