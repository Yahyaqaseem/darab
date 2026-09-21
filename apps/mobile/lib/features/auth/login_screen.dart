import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../shared_widgets/driver_safe_button.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;

  const LoginScreen({super.key, required this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController(text: '07501234567');
  final _otpController = TextEditingController();
  final _usernameController = TextEditingController(text: 'سائق_أربيل_الخبير');

  bool _isOtpSent = false;
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleSendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || phone.length < 10) {
      setState(() => _errorMessage = 'يرجى إدخال رقم هاتف عراقي صحيح');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      await appState.apiService.requestOtp('+964${phone.startsWith('0') ? phone.substring(1) : phone}');
      
      setState(() {
        _isLoading = false;
        _isOtpSent = true;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'حدث خطأ أثناء إرسال الرمز. تأكد من الاتصال.';
      });
    }
  }

  Future<void> _handleVerifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.isEmpty) {
      setState(() => _errorMessage = 'يرجى إدخال رمز التحقق');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final phone = _phoneController.text.trim();
      final appState = Provider.of<AppState>(context, listen: false);
      await appState.apiService.verifyOtp(
        '+964${phone.startsWith('0') ? phone.substring(1) : phone}',
        otp,
        username: _usernameController.text.trim(),
      );

      setState(() => _isLoading = false);
      widget.onLoginSuccess();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'رمز التحقق غير صحيح أو حدث خطأ';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo & Slogan
                Center(
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryEmerald,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryEmerald.withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.navigation_rounded,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'دَرْب — DARB',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Cairo',
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '«اعرف الطريق قبل لا تمشيه.»',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.secondarySandDark,
                    fontFamily: 'Cairo',
                  ),
                ),
                const SizedBox(height: 40),

                // Form Container
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkCard : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        _isOtpSent ? 'أدخل رمز التحقق' : 'تسجيل الدخول كسائق',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isOtpSent
                          ? 'أدخل الرمز المكون من 6 أرقام (الرمز التجريبي: 123456)'
                          : 'أدخل رقم هاتفك العراقي لاستلام تنبيهات الطريق والملاحة',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? AppTheme.textLightSecondary : AppTheme.textDarkSecondary,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      const SizedBox(height: 20),

                      if (!_isOtpSent) ...[
                        TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          textDirection: TextDirection.ltr,
                          decoration: InputDecoration(
                            labelText: 'رقم الهاتف',
                            prefixIcon: const Icon(Icons.phone_iphone_rounded),
                            prefixText: '+964 ',
                            prefixStyle: const TextStyle(fontWeight: FontWeight.bold),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                            filled: true,
                            fillColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _usernameController,
                          decoration: InputDecoration(
                            labelText: 'الاسم المستعار (سائق مجهول)',
                            prefixIcon: const Icon(Icons.person_outline_rounded),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                            filled: true,
                            fillColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                          ),
                        ),
                      ] else ...[
                        TextField(
                          controller: _otpController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
                          maxLength: 6,
                          decoration: InputDecoration(
                            hintText: '123456',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                            filled: true,
                            fillColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                          ),
                        ),
                      ],

                      if (_errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(color: AppTheme.alertRed, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                        ),
                      ],

                      const SizedBox(height: 24),
                      if (_isLoading)
                        const Center(child: CircularProgressIndicator())
                      else
                        DriverSafeButton(
                          label: _isOtpSent ? 'تأكيد ودخول' : 'إرسال رمز التحقق',
                          icon: _isOtpSent ? Icons.check_circle_outline : Icons.arrow_forward_rounded,
                          onPressed: _isOtpSent ? _handleVerifyOtp : _handleSendOtp,
                        ),

                      if (_isOtpSent) ...[
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () => setState(() => _isOtpSent = false),
                          child: const Text('تغيير رقم الهاتف', style: TextStyle(fontFamily: 'Cairo')),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
