import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme/app_theme.dart';
import 'home_screen.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _obscurePassword = true;
  bool _rememberMe = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkRememberedLogin();
  }

  Future<void> _checkRememberedLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool('remember_me') ?? false;

    if (rememberMe && mounted) {
      final savedEmail = prefs.getString('email') ?? '';
      final savedPassword = prefs.getString('password') ?? '';

      setState(() {
        _emailController.text = savedEmail;
        _passwordController.text = savedPassword;
        _rememberMe = true;
      });

      if (savedEmail == 'user@example.com' && savedPassword == '1234') {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      }
    }
  }

  void _performLogin() async {
    setState(() => _isLoading = true);
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email == 'user@example.com' && password == '1234') {
      if (_rememberMe) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('remember_me', true);
        await prefs.setString('email', email);
        await prefs.setString('password', password);
      }
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Invalid email or password',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            backgroundColor: AppTheme.errorColor,
            elevation: 6,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.pastelBlue, Colors.blue.shade100],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 40),
              ZoomIn(
                duration: const Duration(milliseconds: 600),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Image.asset(
                      'assets/logo.png',
                      height: 120,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.videocam,
                        size: 120,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ZoomIn(
                duration: const Duration(milliseconds: 700),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "YOLOFusion",
                      style: Theme.of(context).textTheme.displayLarge,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Advanced Vision Solutions",
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFFE6F0FA), // pastel blue top
                        Color(0xFFFFFFFF), // white bottom
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        spreadRadius: 1,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        TextField(
                          controller: _emailController,
                          style: Theme.of(context).textTheme.bodyMedium,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _passwordController,
                          style: Theme.of(context).textTheme.bodyMedium,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                color: AppTheme.primaryBlue,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Checkbox(
                                  value: _rememberMe,
                                  activeColor: AppTheme.primaryBlue,
                                  checkColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      _rememberMe = value ?? false;
                                    });
                                  },
                                ),
                                Text(
                                  "Remember Me",
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                            TextButton(
                              onPressed: () {
                                // Implement forgot password logic
                              },
                              child: Text(
                                "Forgot Password?",
                                style: GoogleFonts.poppins(
                                  color: AppTheme.primaryBlue,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          child: _isLoading
                              ? const Center(
                            child: CircularProgressIndicator(
                              color: AppTheme.primaryBlue,
                            ),
                          )
                              : ElevatedButton(
                            onPressed: _performLogin,
                            child: Text(
                              "Login", // Fixed typo from "Logn" to "Login"
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              // Implement Google sign-in
                            },
                            icon: Image.asset(
                              'assets/google_icon.png',
                              height: 24,
                              errorBuilder: (context, error, stackTrace) => const Icon(
                                Icons.g_mobiledata,
                                size: 24,
                                color: AppTheme.textDark,
                              ),
                            ),
                            label: Text(
                              "Continue with Google",
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              // Implement Apple sign-in
                            },
                            icon: Image.asset(
                              'assets/apple.png',
                              height: 24,
                              errorBuilder: (context, error, stackTrace) => const Icon(
                                Icons.apple,
                                size: 24,
                                color: AppTheme.textDark,
                              ),
                            ),
                            label: Text(
                              "Continue with Apple",
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Don't have an account? ",
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              GestureDetector(
                                onTap: () {
                                  // Navigate to Create Account
                                },
                                child: Text(
                                  "Sign Up",
                                  style: GoogleFonts.poppins(
                                    color: AppTheme.primaryBlue,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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