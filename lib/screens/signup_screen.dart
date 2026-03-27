import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../widgets/auth/auth_styles.dart';
import '../widgets/auth/google_button.dart';
import '../widgets/auth/or_divider.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _apiClient = ApiClient();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _retypeController = TextEditingController();

  bool _agree = false;
  bool _obscurePassword = true;
  bool _obscureRetype = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _retypeController.dispose();
    super.dispose();
  }

  void _showComingSoon(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _signUp() async {
    if (_passwordController.text != _retypeController.text) {
      _showComingSoon('Passwords do not match.');
      return;
    }
    if (!_agree) {
      _showComingSoon('Please agree to the terms first.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _apiClient.signup(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) {
        return;
      }
      Navigator.pushReplacementNamed(context, '/onboarding');
    } on ApiException catch (e) {
      if (!mounted) {
        return;
      }
      _showComingSoon(e.message);
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showComingSoon('Unable to reach server. Please try again.');
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6),
              const Text('Hello', style: AuthTextStyles.headlineRed),
              const Text('Art Lover!', style: AuthTextStyles.headlineBlack),
              const SizedBox(height: 26),
              const Text('Email', style: AuthTextStyles.fieldLabel),
              const SizedBox(height: 6),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: authInputDecoration(
                  hintText: 'Enter your mail/phone number',
                ),
              ),
              const SizedBox(height: 14),
              const Text('Password', style: AuthTextStyles.fieldLabel),
              const SizedBox(height: 6),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: authInputDecoration(
                  hintText: 'Create password',
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
              const SizedBox(height: 14),
              const Text('Re-type Password', style: AuthTextStyles.fieldLabel),
              const SizedBox(height: 6),
              TextField(
                controller: _retypeController,
                obscureText: _obscureRetype,
                decoration: authInputDecoration(
                  hintText: 'Re-type your password',
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _obscureRetype = !_obscureRetype;
                      });
                    },
                    icon: Icon(
                      _obscureRetype
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
                      value: _agree,
                      activeColor: AuthColors.primaryRed,
                      side: const BorderSide(color: AuthColors.borderGray),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _agree = value ?? false;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Wrap(
                      children: [
                        const Text(
                          'By signing up, you agree to our ',
                          style:
                              TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                        GestureDetector(
                          onTap: () =>
                              _showComingSoon('Terms/Privacy coming soon'),
                          child: const Text(
                            'Terms of Service & Privacy Policy',
                            style: TextStyle(
                              fontSize: 12,
                              color: AuthColors.primaryRed,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ElevatedButton(
                style: primaryPillButtonStyle(),
                onPressed: _isSubmitting ? null : _signUp,
                child: Text(_isSubmitting ? 'Creating account...' : 'Sign-Up'),
              ),
              const SizedBox(height: 18),
              const OrDivider(),
              const SizedBox(height: 18),
              GoogleAuthButton(
                label: 'Sign-Up using Google',
                onPressed: () => Navigator.pushReplacementNamed(
                  context,
                  '/onboarding',
                ),
              ),
              const SizedBox(height: 18),
              Center(
                child: Text.rich(
                  TextSpan(
                    text: 'Already have an account? ',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                    children: [
                      WidgetSpan(
                        alignment: PlaceholderAlignment.baseline,
                        baseline: TextBaseline.alphabetic,
                        child: GestureDetector(
                          onTap: () => Navigator.pushReplacementNamed(
                            context,
                            '/login',
                          ),
                          child: const Text(
                            'Sign In',
                            style: TextStyle(
                              fontSize: 12,
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

