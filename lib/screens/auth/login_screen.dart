import 'package:flutter/material.dart';

import '../../services/api_client.dart';
import '../../widgets/auth/auth_styles.dart';
import '../../widgets/auth/google_button.dart';
import '../../widgets/auth/or_divider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _apiClient = ApiClient();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _obscurePassword = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _autoLoginIfRemembered();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _autoLoginIfRemembered() async {
    final success = await _apiClient.tryAutoLogin();
    if (!mounted || !success) {
      return;
    }
    Navigator.pushReplacementNamed(context, '/app');
  }

  Future<void> _login({bool isAutoLogin = false}) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (!isAutoLogin && (email.isEmpty || password.isEmpty)) {
      _showSnack('Enter email and password.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _apiClient.login(
        email: email,
        password: password,
        rememberMe: _rememberMe,
      );
      if (!mounted) {
        return;
      }
      Navigator.pushReplacementNamed(context, '/app');
    } on ApiException catch (e) {
      if (!mounted) {
        return;
      }
      if (!isAutoLogin) {
        _showSnack(e.message);
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      if (!isAutoLogin) {
        _showSnack(
          'Cannot reach API (${e.runtimeType}). '
          'Start the server, then on a real phone use: '
          'flutter run --dart-define=API_BASE_URL=http://YOUR_PC_IP:4000',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6),
              Text('Welcome back,', style: AuthTextStyles.headlineRed),
              Text('Art Lover!', style: AuthTextStyles.headlineBlack),
              const SizedBox(height: 26),
              Text('Email', style: AuthTextStyles.fieldLabel),
              const SizedBox(height: 6),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: authInputDecoration(
                  hintText: 'Enter your mail/phone number',
                ),
              ),
              const SizedBox(height: 14),
              Text('Password', style: AuthTextStyles.fieldLabel),
              const SizedBox(height: 6),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: authInputDecoration(
                  hintText: 'Enter your password',
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: Colors.black54,
                      size: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _rememberMe,
                      activeColor: AuthColors.primaryRed,
                      side: const BorderSide(color: AuthColors.borderGray),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _rememberMe = value ?? false;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Remember me',
                    style: t.bodySmall?.copyWith(color: Colors.black54),
                  ),
                  const Spacer(),
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () =>
                        _showSnack('Forgot password coming soon'),
                    child: Text(
                      'Forgot Password',
                      style: t.bodySmall?.copyWith(
                        color: AuthColors.linkBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ElevatedButton(
                style: primaryPillButtonStyle(),
                onPressed: _isSubmitting ? null : _login,
                child: Text(_isSubmitting ? 'Signing in...' : 'Log- In'),
              ),
              const SizedBox(height: 18),
              const OrDivider(),
              const SizedBox(height: 18),
              GoogleAuthButton(
                label: 'Continue with Google',
                onPressed: () => Navigator.pushReplacementNamed(
                  context,
                  '/onboarding',
                ),
              ),
              const SizedBox(height: 18),
              Center(
                child: Text.rich(
                  TextSpan(
                    text: "Don't have an account? ",
                    style: t.bodySmall?.copyWith(color: Colors.black54),
                    children: [
                      WidgetSpan(
                        alignment: PlaceholderAlignment.baseline,
                        baseline: TextBaseline.alphabetic,
                        child: GestureDetector(
                          onTap: () => Navigator.pushNamed(context, '/signup'),
                          child: Text(
                            'Sign Up',
                            style: t.bodySmall?.copyWith(
                              color: AuthColors.primaryRed,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
