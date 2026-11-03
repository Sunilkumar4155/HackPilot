
import 'package:flutter/material.dart';

import '../models/hackathon.dart';
import '../services/auth_service.dart';
import 'main_navigation.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key, this.returnTo = 0, this.pendingBookmark});

  final int returnTo;
  final Hackathon? pendingBookmark;

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final AuthService authService = AuthService();

  bool obscurePassword = true;
  bool isLoading = false;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> createAccount() async {
    if (isLoading) return;

    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      showMessage('Please fill in all fields.');
      return;
    }

    if (!email.contains('@') || !email.contains('.')) {
      showMessage('Please enter a valid email address.');
      return;
    }

    if (password.length < 6) {
      showMessage('Password must contain at least 6 characters.');
      return;
    }

    setState(() => isLoading = true);

    try {
      final String? result = await authService.signup(email, password);

      if (!mounted) return;

      if (result == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully!'),
            behavior: SnackBarBehavior.floating,
          ),
        );

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => MainNavigation(
              initialIndex: widget.returnTo,
              pendingBookmark: widget.pendingBookmark,
            ),
          ),
          (route) => false,
        );
      } else {
        showMessage(result);
      }
    } catch (e) {
      if (!mounted) return;
      showMessage('Unable to create account. Please try again.');
      debugPrint('Signup error: $e');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  InputDecoration fieldDecoration({
    required String label,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFF0B1017),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF202A35)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color(0xFFFF6818),
          width: 1.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07090D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF07090D),
        foregroundColor: const Color(0xFFF5F7FA),
        elevation: 0,
        title: const Text(
          'HACKPILOT • CREATE ACCOUNT',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 12),

                      Container(
                        width: 86,
                        height: 86,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFF101720),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Icon(
                          Icons.person_add_alt_1_rounded,
                          size: 43,
                          color: Color(0xFFFF6818),
                        ),
                      ),

                      const SizedBox(height: 24),

                      const Text(
                        'Join the community.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.7,
                          color: Color(0xFFF5F7FA),
                        ),
                      ),

                      const SizedBox(height: 10),

                      const Text(
                        'Create your account and find your next '
                        'hackathon team.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          color: Color(0xFFA1B1C4),
                        ),
                      ),

                      const SizedBox(height: 32),

                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0B1017),
                          borderRadius: BorderRadius.circular(11),
                          border: Border.all(
                            color: const Color(0xFF202A35),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'HACKPILOT ACCOUNT',
                              style: TextStyle(
                                fontSize: 11,
                                letterSpacing: 1.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFFF6818),
                              ),
                            ),

                            const SizedBox(height: 22),

                            TextField(
                              controller: nameController,
                              textCapitalization:
                                  TextCapitalization.words,
                              autofillHints: const [
                                AutofillHints.name,
                              ],
                              decoration: fieldDecoration(
                                label: 'Full Name',
                                icon: Icons.person_outline,
                              ),
                            ),

                            const SizedBox(height: 18),

                            TextField(
                              controller: emailController,
                              keyboardType: TextInputType.emailAddress,
                              autofillHints: const [
                                AutofillHints.email,
                              ],
                              decoration: fieldDecoration(
                                label: 'Email Address',
                                icon: Icons.mail_outline,
                              ),
                            ),

                            const SizedBox(height: 18),

                            TextField(
                              controller: passwordController,
                              obscureText: obscurePassword,
                              autofillHints: const [
                                AutofillHints.newPassword,
                              ],
                              onSubmitted: (_) {
                                if (!isLoading) createAccount();
                              },
                              decoration: fieldDecoration(
                                label: 'Password',
                                icon: Icons.lock_outline,
                                suffix: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      obscurePassword =
                                          !obscurePassword;
                                    });
                                  },
                                  icon: Icon(
                                    obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 10),

                            const Text(
                              'Use at least 6 characters for your password.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFFA1B1C4),
                              ),
                            ),

                            const SizedBox(height: 26),

                            SizedBox(
                              height: 52,
                              child: ElevatedButton(
                                onPressed: isLoading
                                    ? null
                                    : createAccount,
                                style: ElevatedButton.styleFrom(
                                  elevation: 0,
                                  backgroundColor:
                                      const Color(0xFFFF6818),
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: const Color(0xFF29313A),
                                  disabledForegroundColor: const Color(0xFFA1B1C4),
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(10),
                                  ),
                                ),
                                child: isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child:
                                            CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Create Account',
                                            style: TextStyle(
                                              fontWeight:
                                                  FontWeight.w700,
                                              fontSize: 14,
                                            ),
                                          ),
                                          SizedBox(width: 10),
                                          Icon(
                                            Icons.arrow_forward,
                                            size: 18,
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 22),

                      Center(
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment:
                              WrapCrossAlignment.center,
                          children: [
                            const Text(
                              'Already have an account?',
                              style: TextStyle(
                                color: Color(0xFFA1B1C4),
                                fontSize: 13,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: const Text(
                                'Sign in',
                                style: TextStyle(
                                  color: Color(0xFFFF6818),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
