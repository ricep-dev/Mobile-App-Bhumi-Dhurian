import 'package:bhumidurianapp/widgets/common/custom_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _alamatController = TextEditingController();
  final TextEditingController _telponController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  late final AnimationController _logoAnimController;
  late final Animation<double> _logoElevationAnim;
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();

    _logoAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _logoElevationAnim = Tween<double>(begin: 6.0, end: 14.0).animate(
      CurvedAnimation(parent: _logoAnimController, curve: Curves.easeInOut),
    );
    _logoAnimController.repeat(reverse: true);

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _logoAnimController.dispose();
    _fadeController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _alamatController.dispose();
    _telponController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    CustomSnackBar.showLoading(context, "Memproses pendaftaran...");

    final url = Uri.parse("http://192.168.31.101:9090/api/v1/register");
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": _usernameController.text.trim(),
          "email": _emailController.text.trim(),
          "password": _passwordController.text,
          "alamat": _alamatController.text.trim(),
          "nohp": _telponController.text.trim(),
        }),
      );

      CustomSnackBar.hideLoading(context);
      setState(() => _isLoading = false);

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        CustomSnackBar.showRegistrationSuccess(context);
        // optionally pop to login after success:
        // Navigator.pop(context);
      } else {
        CustomSnackBar.showError(
          context,
          responseData['error'] ??
              responseData['message'] ??
              'Pendaftaran gagal',
        );
      }
    } catch (e) {
      CustomSnackBar.hideLoading(context);
      setState(() => _isLoading = false);
      CustomSnackBar.showError(context, "Terjadi kesalahan koneksi");
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Column(
                    children: [
                      const SizedBox(height: 12),

                      // Logo (diperkecil sesuai login)
                      AnimatedBuilder(
                        animation: _logoElevationAnim,
                        builder: (context, child) {
                          return Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFFFDD835,
                                  ).withOpacity(0.35),
                                  blurRadius: _logoElevationAnim.value,
                                  spreadRadius: _logoElevationAnim.value / 4,
                                  offset: Offset(
                                    0,
                                    _logoElevationAnim.value / 2,
                                  ),
                                ),
                              ],
                            ),
                            child: Container(
                              width: 110,
                              height: 110,
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
                                    width: 74,
                                    height: 74,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 20),

                      const Text(
                        "Buat Akun Baru",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2C2C2C),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Isi datamu untuk membuat akun baru",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Form card (style consistent dengan login)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
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
                            children: [
                              _buildModernTextField(
                                controller: _usernameController,
                                hintText: "Username",
                                icon: Icons.person_2_rounded,
                              ),
                              const SizedBox(height: 14),
                              _buildModernTextField(
                                controller: _emailController,
                                hintText: "Email",
                                icon: Icons.email_rounded,
                                keyboardType: TextInputType.emailAddress,
                              ),
                              const SizedBox(height: 14),
                              _buildModernTextField(
                                controller: _alamatController,
                                hintText: "Alamat",
                                icon: Icons.location_on_rounded,
                              ),
                              const SizedBox(height: 14),
                              _buildModernTextField(
                                controller: _telponController,
                                hintText: "No Telpon",
                                icon: Icons.phone_rounded,
                                keyboardType: TextInputType.phone,
                              ),

                              const SizedBox(height: 14),

                              // Password field (consistent)
                              Column(
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
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty)
                                        return 'Password wajib diisi';
                                      if (value.length < 6)
                                        return 'Minimal 6 karakter';
                                      return null;
                                    },
                                    decoration: InputDecoration(
                                      hintText: "Masukkan password",
                                      hintStyle: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 13,
                                      ),
                                      prefixIcon: const Icon(
                                        Icons.lock_rounded,
                                        color: Color(0xFFFDD835),
                                        size: 20,
                                      ),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_off_rounded
                                              : Icons.visibility_rounded,
                                          color: Colors.grey[600],
                                          size: 20,
                                        ),
                                        onPressed:
                                            () => setState(
                                              () =>
                                                  _obscurePassword =
                                                      !_obscurePassword,
                                            ),
                                      ),
                                      filled: true,
                                      fillColor: const Color(0xFFFAFAFA),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            vertical: 16,
                                            horizontal: 14,
                                          ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: Colors.grey[200]!,
                                          width: 1.2,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: Colors.grey[200]!,
                                          width: 1.2,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: Color(0xFFFDD835),
                                          width: 1.8,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 18),

                              // Register button
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _registerUser,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFDD835),
                                    foregroundColor: Colors.black87,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    elevation: 0,
                                    shadowColor: const Color(
                                      0xFFFDD835,
                                    ).withOpacity(0.45),
                                  ).copyWith(
                                    elevation:
                                        MaterialStateProperty.resolveWith<
                                          double
                                        >((states) {
                                          if (states.contains(
                                            MaterialState.pressed,
                                          ))
                                            return 0;
                                          return 6;
                                        }),
                                  ),
                                  child:
                                      _isLoading
                                          ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              color: Colors.black87,
                                            ),
                                          )
                                          : const Text(
                                            "Register",
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 15,
                                            ),
                                          ),
                                ),
                              ),

                              const SizedBox(height: 18),

                              // Divider with text
                              Row(
                                children: [
                                  Expanded(
                                    child: Divider(
                                      color: Colors.grey[300],
                                      thickness: 1,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    child: Text(
                                      "Or register with",
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Divider(
                                      color: Colors.grey[300],
                                      thickness: 1,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),

                              // Social buttons (konsisten desain)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _socialButton(
                                    FontAwesomeIcons.google,
                                    const Color(0xFFDB4437),
                                    size: 60,
                                  ),
                                  const SizedBox(width: 12),
                                  _socialButton(
                                    FontAwesomeIcons.instagram,
                                    null,
                                    size: 60,
                                  ),
                                  const SizedBox(width: 12),
                                  _socialButton(
                                    FontAwesomeIcons.facebookF,
                                    const Color(0xFF1877F2),
                                    size: 60,
                                  ),
                                ],
                              ),

                              const SizedBox(height: 14),

                              // Login link
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Sudah punya akun? ",
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => Navigator.pop(context),
                                    child: const Text(
                                      "Login",
                                      style: TextStyle(
                                        color: Color(0xFFFDD835),
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
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

  // Reuse modern text field style like LoginScreen
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
            if (keyboardType == TextInputType.emailAddress &&
                !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value))
              return 'Format email tidak valid';
            return null;
          },
          decoration: InputDecoration(
            hintText: "Enter your $hintText",
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: hintSize),
            prefixIcon: Icon(icon, color: const Color(0xFFFDD835), size: 20),
            filled: true,
            fillColor: const Color(0xFFFAFAFA),
            contentPadding: EdgeInsets.symmetric(
              vertical: verticalPadding,
              horizontal: 14,
            ),
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
              borderSide: const BorderSide(
                color: Color(0xFFFDD835),
                width: 1.8,
              ),
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
      iconWidget = FaIcon(
        icon,
        size: size * 0.4,
        color: iconColor ?? Colors.black87,
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // TODO: implement social register (OAuth) jika ingin
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
