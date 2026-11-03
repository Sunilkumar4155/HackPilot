
import 'package:flutter/material.dart';

import '../models/hackathon.dart';
import '../services/auth_service.dart';
import '../services/google_auth_service.dart';
import 'signup_screen.dart';
import 'main_navigation.dart';

const Color _ink = Color(0xFFF5F7FA);
const Color _muted = Color(0xFFA1B1C4);
const Color _paper = Color(0xFF07090D);
const Color _purple = Color(0xFFFF6818);
const Color _line = Color(0xFF202A35);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.returnTo = 0, this.pendingBookmark});

  final int returnTo;
  final Hackathon? pendingBookmark;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final authService = AuthService();
  final googleAuthService = GoogleAuthService();

  bool hidePassword = true;
  bool isLoading = false;
  bool isGoogleLoading = false;

  @override
  void dispose() {
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

  void openHome() {
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => MainNavigation(
          initialIndex: widget.returnTo,
          pendingBookmark: widget.pendingBookmark,
        ),
      ),
      (route) => false,
    );
  }

  Future<void> login() async {
    if (isLoading || isGoogleLoading) return;

    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      showMessage('Please enter your email and password.');
      return;
    }

    setState(() => isLoading = true);

    try {
      final result = await authService.login(email, password);

      if (!mounted) return;

      if (result == null) {
        openHome();
      } else {
        showMessage(result);
      }
    } catch (e) {
      showMessage('Login failed. Please check your credentials.');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> loginWithGoogle() async {
    if (isLoading || isGoogleLoading) return;

    setState(() => isGoogleLoading = true);

    try {
      await googleAuthService.signInWithGoogle();

      if (!mounted) return;
      openHome();
    } catch (e) {
      showMessage('Google sign-in failed. Please try again.');
      debugPrint('Google sign-in error: $e');
    } finally {
      if (mounted) {
        setState(() => isGoogleLoading = false);
      }
    }
  }

  InputDecoration fieldDecoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        fontSize: 14,
        color: _muted,
      ),
      prefixIcon: Icon(icon, color: _muted),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFF0B1017),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 18,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: _line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: _line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(
          color: _purple,
          width: 1.5,
        ),
      ),
    );
  }

  Widget feature({
    required String number,
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          number,
          style: const TextStyle(
            fontSize: 11,
            color: _purple,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: _ink,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 10,
            color: _muted,
          ),
        ),
      ],
    );
  }

  Widget editorialPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFF101720),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Row(
            children: [
              Icon(
                Icons.auto_awesome,
                color: _purple,
                size: 22,
              ),
              SizedBox(width: 10),
              Flexible(
                child: Text(
                  'HACKPILOT • YOUR INNOVATION. OUR DIRECTION.',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w800,
                    color: _ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Text(
            'Ideas are\nbetter when\nthey meet.',
            style: TextStyle(
              fontSize: 42,
              height: 1.08,
              letterSpacing: -1.3,
              fontWeight: FontWeight.w800,
              color: _ink,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Discover exciting hackathons, connect with '
            'like-minded people, and turn your ideas into '
            'something meaningful.',
            style: TextStyle(
              fontSize: 14,
              height: 1.8,
              color: Color(0xFFA1B1C4),
            ),
          ),
          const SizedBox(height: 28),
          Container(height: 1, color: const Color(0xFFD5C7E1)),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: feature(
                  number: '01',
                  title: 'Discover',
                  subtitle: 'Find events',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: feature(
                  number: '02',
                  title: 'Connect',
                  subtitle: 'Build teams',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: feature(
                  number: '03',
                  title: 'Create',
                  subtitle: 'Win together',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget loginForm() {
    final busy = isLoading || isGoogleLoading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'WELCOME BACK',
          style: TextStyle(
            color: _purple,
            fontSize: 11,
            letterSpacing: 2,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Sign in.',
          style: TextStyle(
            fontSize: 42,
            height: 1.1,
            letterSpacing: -1.4,
            fontWeight: FontWeight.w800,
            color: _ink,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Your next big idea is waiting.',
          style: TextStyle(
            fontSize: 14,
            color: _muted,
          ),
        ),
        const SizedBox(height: 28),

        const Text(
          'EMAIL ADDRESS',
          style: TextStyle(
            fontSize: 10,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w800,
            color: _ink,
          ),
        ),
        const SizedBox(height: 9),
        TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          decoration: fieldDecoration(
            hint: 'name@example.com',
            icon: Icons.mail_outline,
          ),
        ),

        const SizedBox(height: 20),

        const Text(
          'PASSWORD',
          style: TextStyle(
            fontSize: 10,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w800,
            color: _ink,
          ),
        ),
        const SizedBox(height: 9),
        TextField(
          controller: passwordController,
          obscureText: hidePassword,
          autofillHints: const [AutofillHints.password],
          onSubmitted: (_) {
            if (!busy) login();
          },
          decoration: fieldDecoration(
            hint: 'Enter your password',
            icon: Icons.lock_outline,
            suffix: IconButton(
              onPressed: () {
                setState(() => hidePassword = !hidePassword);
              },
              icon: Icon(
                hidePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: _muted,
              ),
            ),
          ),
        ),

        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {
              showMessage(
                'Password reset is not configured yet.',
              );
            },
            child: const Text(
              'Forgot password?',
              style: TextStyle(
                fontSize: 12,
                color: _purple,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),

        const SizedBox(height: 10),

        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: busy ? null : login,
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: _purple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
              ),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Sign in to your account',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: 10),
                      Icon(Icons.arrow_forward, size: 18),
                    ],
                  ),
          ),
        ),

        const SizedBox(height: 22),

        Row(
          children: [
            Expanded(child: Container(height: 1, color: _line)),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'OR CONTINUE WITH',
                style: TextStyle(
                  fontSize: 10,
                  color: _muted,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Expanded(child: Container(height: 1, color: _line)),
          ],
        ),

        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton(
            onPressed: busy ? null : loginWithGoogle,
            style: OutlinedButton.styleFrom(
              backgroundColor: const Color(0xFF101720),
              foregroundColor: _ink,
              side: const BorderSide(color: _line),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
              ),
            ),
            child: isGoogleLoading
                ? const SizedBox(
                    width: 21,
                    height: 21,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.g_mobiledata,
                        size: 30,
                        color: Color(0xFF4285F4),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Continue with Google',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
          ),
        ),

        const SizedBox(height: 20),

        Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'New to HACKPILOT? ',
                style: TextStyle(
                  fontSize: 12,
                  color: _muted,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SignupScreen(
                        returnTo: widget.returnTo,
                        pendingBookmark: widget.pendingBookmark,
                      ),
                    ),
                  );
                },
                child: const Text(
                  'Create an account',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: _purple,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _paper,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final desktop = constraints.maxWidth >= 900;

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: desktop ? 40 : 18,
                vertical: 24,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _purple,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: const Icon(
                              Icons.explore_rounded,
                              color: Colors.white,
                              size: 23,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Flexible(
                            child: Text(
                              'HACKPILOT',
                              style: TextStyle(
                                fontSize: 12,
                                letterSpacing: 1.3,
                                fontWeight: FontWeight.w900,
                                color: _ink,
                              ),
                            ),
                          ),
                          if (desktop) ...[
                            const Spacer(),
                            const Text(
                              'A BETTER WAY TO BUILD',
                              style: TextStyle(
                                fontSize: 10,
                                letterSpacing: 1.4,
                                color: _muted,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 30),

                      if (desktop)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 11,
                              child: editorialPanel(),
                            ),
                            const SizedBox(width: 44),
                            Expanded(
                              flex: 9,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 20),
                                child: loginForm(),
                              ),
                            ),
                          ],
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            editorialPanel(),
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0B1017),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: _line),
                              ),
                              child: loginForm(),
                            ),
                          ],
                        ),

                      const SizedBox(height: 28),

                      const Center(
                        child: Text(
                          'DISCOVER  ·  CONNECT  ·  CREATE',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 1.5,
                            color: _muted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
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
