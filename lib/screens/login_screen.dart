import 'package:bhumidurianapp/screens/Home_screen.dart';
import 'package:bhumidurianapp/screens/register_screen.dart';
import 'package:bhumidurianapp/services/api_baru.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isLoading = false;

  late final AnimationController _animController;
  late final AnimationController _fadeController;
  late final Animation<double> _elevationAnim;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _elevationAnim = Tween<double>(begin: 8.0, end: 16.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
    );

    _animController.repeat(reverse: true);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _fadeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    setState(() => _isLoading = true);

    try {
      final result = await ApiBaru.loginUser(email: email, password: password);
      setState(() => _isLoading = false);

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Login berhasil'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(onAddToCart: (item) {}),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Login gagal'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Gradient Background
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFFFFDE7),
                    Color(0xFFFFF9C4),
                    Color(0xFFFFF59D),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),

            // Decorative circles
            Positioned(
              top: -40,
              right: -40,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
            ),
            Positioned(
              bottom: -60,
              left: -60,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
            ),

            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16), // vertical padding dari 32 -> 16
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Column(
                    children: [
                      const SizedBox(height: 12),

                      // Logo with animation (diperkecil menjadi 110x110)
                      AnimatedBuilder(
                        animation: _elevationAnim,
                        builder: (context, child) {
                          return Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFDD835).withOpacity(0.35),
                                  blurRadius: _elevationAnim.value,
                                  spreadRadius: _elevationAnim.value / 4,
                                  offset: Offset(0, _elevationAnim.value / 2),
                                ),
                              ],
                            ),
                            child: Container(
                              width: 110, // sebelumnya 140
                              height: 110, // sebelumnya 140
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFDD835),
                                    Color(0xFFFFEB3B),
                                    Color(0xFFFFF176),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
                              ),
                              child: Center(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Image.asset(
                                    'assets/logobumidurian.png',
                                    width: 74, // menyesuaikan ukuran logo di dalam
                                    height: 74,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 20), // logo -> text (dari 32 -> 20)

                      // Welcome text (font size dari 32 -> 28)
                      const Text(
                        "Selamat Datang!",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2C2C2C),
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Silakan masuk untuk melanjutkan",
                        style: TextStyle(
                          fontSize: 13, // lebih ringkas
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 24), // text -> form (dari 36 -> 24)

                      // Login Form Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24), // form padding dari 28 -> 24
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24), // sedikit lebih compact
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 26,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Email field
                              _buildModernTextField(
                                controller: _emailController,
                                hintText: "Email",
                                icon: Icons.email_rounded,
                                keyboardType: TextInputType.emailAddress,
                                hintSize: 13,
                                verticalPadding: 16, // input padding vertical 16 (sebelumnya 18)
                              ),

                              const SizedBox(height: 16), // antar input dari 20 -> 16

                              // Password field
                              _buildPasswordField(
                                hintSize: 13,
                                verticalPadding: 16,
                              ),

                              const SizedBox(height: 12), // dari 16 -> 12

                              // Remember me & Forgot password
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      SizedBox(
                                        width: 20, // checkbox dari 24 -> 20
                                        height: 20,
                                        child: Checkbox(
                                          value: _rememberMe,
                                          onChanged: (val) => setState(() => _rememberMe = val ?? false),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          activeColor: const Color(0xFFFDD835),
                                          checkColor: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        "Remember me",
                                        style: TextStyle(
                                          color: Colors.grey[700],
                                          fontSize: 13, // font kecil
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const ForgotPasswordScreen(),
                                        ),
                                      );
                                    },
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      minimumSize: const Size(50, 30),
                                    ),
                                    child: const Text(
                                      "Forgot password?",
                                      style: TextStyle(
                                        color: Color(0xFFFF6B35),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 20), // section spacing dari 28 -> 20

                              // Login Button (height dari 56 -> 52)
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _handleLogin,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFDD835),
                                    foregroundColor: Colors.black87,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14), // sedikit lebih bulat tapi tidak terlalu
                                    ),
                                    elevation: 0,
                                    shadowColor: const Color(0xFFFDD835).withOpacity(0.45),
                                  ).copyWith(
                                    elevation: MaterialStateProperty.resolveWith<double>(
                                      (Set<MaterialState> states) {
                                        if (states.contains(MaterialState.pressed)) return 0;
                                        return 6;
                                      },
                                    ),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.black87),
                                        )
                                      : const Text(
                                          "Log In",
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                ),
                              ),

                              const SizedBox(height: 18),

                              // Divider with text
                              Row(
                                children: [
                                  Expanded(child: Divider(color: Colors.grey[300], thickness: 1)),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    child: Text(
                                      "Or continue with",
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  Expanded(child: Divider(color: Colors.grey[300], thickness: 1)),
                                ],
                              ),

                              const SizedBox(height: 18),

                              // Social Login Buttons (60x60)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _socialButton(FontAwesomeIcons.google, const Color(0xFFDB4437), size: 60),
                                  const SizedBox(width: 12),
                                  _socialButton(FontAwesomeIcons.instagram, null, size: 60),
                                  const SizedBox(width: 12),
                                  _socialButton(FontAwesomeIcons.facebookF, const Color(0xFF1877F2), size: 60),
                                ],
                              ),

                              const SizedBox(height: 16), // bottom spacing dari 30 -> 16

                              // Sign up link
                              Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Don't have an account? ",
                                      style: TextStyle(
                                        color: Colors.grey[700],
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (_) => const RegisterScreen()),
                                        );
                                      },
                                      child: const Text(
                                        "Sign Up",
                                        style: TextStyle(
                                          color: Color(0xFFFDD835),
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13,
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

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    double hintSize = 13,
    double verticalPadding = 16,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          hintText,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C2C2C),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          validator: (value) {
            if (value == null || value.isEmpty) return '$hintText wajib diisi';
            if (keyboardType == TextInputType.emailAddress && !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
              return 'Format email tidak valid';
            }
            return null;
          },
          decoration: InputDecoration(
            hintText: "Enter your $hintText",
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: hintSize),
            prefixIcon: Icon(icon, color: const Color(0xFFFDD835), size: 20),
            filled: true,
            fillColor: const Color(0xFFFAFAFA),
            contentPadding: EdgeInsets.symmetric(vertical: verticalPadding, horizontal: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[200]!, width: 1.2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[200]!, width: 1.2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFFDD835), width: 1.8),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1.8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField({double hintSize = 13, double verticalPadding = 16}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Password",
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C2C2C),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          validator: (value) => (value == null || value.isEmpty) ? 'Password wajib diisi' : null,
          decoration: InputDecoration(
            hintText: "Enter your password",
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: hintSize),
            prefixIcon: const Icon(Icons.lock_rounded, color: Color(0xFFFDD835), size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                color: Colors.grey[600],
                size: 20,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            filled: true,
            fillColor: const Color(0xFFFAFAFA),
            contentPadding: EdgeInsets.symmetric(vertical: verticalPadding, horizontal: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[200]!, width: 1.2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[200]!, width: 1.2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFFDD835), width: 1.8),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1.8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _socialButton(IconData icon, Color? iconColor, {double size = 60}) {
    Widget iconWidget;
    if (icon == FontAwesomeIcons.instagram) {
      iconWidget = ShaderMask(
        shaderCallback: (Rect bounds) {
          return const LinearGradient(
            colors: [
              Color(0xFFFEDA75),
              Color(0xFFFA7E1E),
              Color(0xFFD62976),
              Color(0xFF962FBF),
              Color(0xFF4F5BD5),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds);
        },
        child: FaIcon(icon, size: size * 0.4, color: Colors.white),
      );
    } else {
      iconWidget = FaIcon(icon, size: size * 0.4, color: iconColor ?? Colors.black87);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // TODO: implement social login handlers
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(child: iconWidget),
        ),
      ),
    );
  }
}
