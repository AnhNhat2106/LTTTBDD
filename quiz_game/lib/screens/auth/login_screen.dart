import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscure = true;
  bool _isLogin = true;
  bool _loading = false;

  final _auth = AuthService();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      if (_isLogin) {
        await _auth.signInWithEmail(
          email: _email.text.trim(),
          password: _password.text.trim(),
        );
      } else {
        await _auth.signUpWithEmail(
          email: _email.text.trim(),
          password: _password.text.trim(),
        );
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg.replaceFirst('Exception: ', ''))),
    );
  }

  Future<void> _resetPassword() async {
    if (_email.text.trim().isEmpty) {
      _showError('Nhập email để khôi phục mật khẩu');
      return;
    }
    setState(() => _loading = true);
    try {
      await _auth.sendPasswordResetEmail(_email.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã gửi email đặt lại mật khẩu')),
        );
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;
    final title = _isLogin ? 'Đăng nhập' : 'Tạo tài khoản';
    final action = _isLogin ? 'Đăng nhập' : 'Đăng ký';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 📧 Email
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: const Icon(Icons.email_outlined),
                      filled: true,
                      fillColor: color.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Vui lòng nhập email';
                      }
                      final ok = RegExp(r'^\S+@\S+\.\S+$').hasMatch(v.trim());
                      if (!ok) return 'Email không hợp lệ';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // 🔒 Mật khẩu
                  TextFormField(
                    controller: _password,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () => setState(() {
                          _obscure = !_obscure;
                        }),
                      ),
                      filled: true,
                      fillColor: color.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Vui lòng nhập mật khẩu';
                      if (v.length < 6) return 'Ít nhất 6 ký tự';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // 🔘 Nút đăng nhập / đăng ký
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : Text(action),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 🔄 Quên mật khẩu + Chuyển chế độ
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: _loading ? null : _resetPassword,
                        child: const Text('Quên mật khẩu?'),
                      ),
                      TextButton(
                        onPressed: _loading
                            ? null
                            : () => setState(() => _isLogin = !_isLogin),
                        child: Text(
                          _isLogin
                              ? 'Chưa có tài khoản? Đăng ký'
                              : 'Đã có tài khoản? Đăng nhập',
                          style: TextStyle(color: color.primary),
                        ),
                      ),
                    ],
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
