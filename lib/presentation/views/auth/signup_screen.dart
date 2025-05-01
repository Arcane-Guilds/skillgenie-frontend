import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/auth/signup_viewmodel.dart';
import '../../../core/services/service_locator.dart';
import '../../widgets/avatar_widget.dart'; // Adjust path if needed
import '../../../core/theme/app_theme.dart'; // Adjust path if needed


class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => serviceLocator<SignUpViewModel>(),
      child: const SignUpScreenContent(),
    );
  }
}

class SignUpScreenContent extends StatefulWidget {
  const SignUpScreenContent({super.key});

  @override
  State createState() => _SignUpScreenContentState();
}

class _SignUpScreenContentState extends State<SignUpScreenContent> {
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _ageController = TextEditingController();
  bool _hasNavigated = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SignUpViewModel>(
      builder: (context, viewModel, child) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (viewModel.isSignedUp && viewModel.userId != null && viewModel.userId!.isNotEmpty && !_hasNavigated) {
            _hasNavigated = true;
            print("Navigating to Quiz Screen with User ID: ${viewModel.userId}");
            GoRouter.of(context).go('/quiz/${viewModel.userId}');
          }
        });

        print("isSignedUp: ${viewModel.isSignedUp}, userId: ${viewModel.userId}");
        return Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const GenieAvatar(
                      state: AvatarState.idle,
                      size: 120,
                      message: "Let's create your profile!",
                    ),
                    const SizedBox(height: 24),
                    Card(
                      color: AppTheme.surfaceColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              if (viewModel.errorMessage != null)
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  color: Colors.red[100],
                                  child: Text(
                                    viewModel.errorMessage!,
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                ),
                              const SizedBox(height: 16),
                              _buildTextFormField(
                                controller: _usernameController,
                                hintText: 'Username',
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your username';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              _buildTextFormField(
                                controller: _ageController,
                                hintText: 'Age',
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your age';
                                  }
                                  if (int.tryParse(value) == null) {
                                    return 'Please enter a valid age';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Providing your age ensures you get the right SkillGenie experience. For more details, please visit our Privacy Policy.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildTextFormField(
                                controller: _emailController,
                                hintText: 'Email',
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your email';
                                  }
                                  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}');
                                  if (!emailRegex.hasMatch(value)) {
                                    return 'Please enter a valid email';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              _buildTextFormField(
                                controller: _passwordController,
                                hintText: 'Password',
                                obscureText: !_isPasswordVisible,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isPasswordVisible
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: Colors.grey,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isPasswordVisible = !_isPasswordVisible;
                                    });
                                  },
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a password';
                                  }
                                  if (value.length < 8) {
                                    return 'Password must be at least 8 characters long';
                                  }
                                  if (!RegExp(r'^(?=.*[A-Z]).*$').hasMatch(value)) {
                                    return 'Password must contain at least one uppercase letter';
                                  }
                                  if (!RegExp(r'^(?=.*[!?=@#\$&*~\.\.\.]).*$').hasMatch(value)) {
                                    return 'Password must contain at least one special character (!@#\$&*~=?)';
                                  }
                                  if (!RegExp(r'^(?=.*[0-9]).*$').hasMatch(value)) {
                                    return 'Password must contain at least one number';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: viewModel.isLoading
                                      ? null
                                      : () {
                                    if (_formKey.currentState!.validate()) {
                                      viewModel.signUp(
                                        context,
                                        username: _usernameController.text,
                                        email: _emailController.text,
                                        password: _passwordController.text,
                                        age: int.parse(_ageController.text),
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryColor,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: viewModel.isLoading
                                      ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation(Colors.white),
                                    ),
                                  )
                                      : const Text(
                                    'CREATE ACCOUNT',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(child: Divider(color: Colors.grey[300])),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Text(
                                      'OR',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  Expanded(child: Divider(color: Colors.grey[300])),
                                ],
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.facebook, color: Colors.blue),
                                  label: const Text(
                                    'FACEBOOK',
                                    style: TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  onPressed: viewModel.isLoading
                                      ? null
                                      : viewModel.signUpWithFacebook,
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    side: const BorderSide(color: Colors.blue),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              const Text(
                                'By signing in to SkillGenie, you agree to our Terms and Privacy Policy.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text('Have an account?'),
                                  TextButton(
                                    onPressed: () {
                                      GoRouter.of(context).go('/login');
                                    },
                                    child: const Text(
                                      'LOG IN',
                                      style: TextStyle(
                                        color: Colors.blue,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
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
          ),
        );
      },
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String hintText,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        suffixIcon: suffixIcon,
      ),
      validator: validator,
    );
  }
}