import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../../core/constants/app_constants.dart';
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

  String _normalizeIraqiPhone(String input) {
    String cleaned = input.replaceAll(RegExp(r'[^\d+]'), '').trim();
    if (cleaned.startsWith('+964')) {
      cleaned = cleaned.substring(4);
    } else if (cleaned.startsWith('00964')) {
      cleaned = cleaned.substring(5);
    } else if (cleaned.startsWith('964')) {
      cleaned = cleaned.substring(3);
    }
    if (cleaned.startsWith('0')) {
      cleaned = cleaned.substring(1);
    }
    return '+964$cleaned';
  }

  Future<void> _handleSendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || phone.length < 9) {
      setState(() => _errorMessage = 'يرجى إدخال رقم هاتف عراقي صحيح');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final normalizedPhone = _normalizeIraqiPhone(phone);
      debugPrint('[OTP REQUEST] Target: ${appState.apiService.baseUrl}/auth/request-otp');
      debugPrint('[OTP REQUEST] Normalized Phone: $normalizedPhone');
      
      final res = await appState.apiService.requestOtp(normalizedPhone);
      debugPrint('[OTP SUCCESS] Response received: ${res['message']}');
      
      setState(() {
        _isLoading = false;
        _isOtpSent = true;
      });
    } on DioException catch (e) {
      debugPrint('[OTP ERROR] DioException: status=${e.response?.statusCode}, type=${e.type}, msg=${e.message}');
      String msg;
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        msg = 'تعذر الاتصال بالسيرفر (${AppConstants.defaultApiUrl}). تأكد من تشغيل السيرفر ومن اتصال هاتفك بنفس الشبكة.';
      } else if (e.response != null) {
        final serverMsg = e.response?.data?['message'];
        if (serverMsg is List) {
          msg = serverMsg.join(', ');
        } else if (serverMsg is String) {
          msg = serverMsg;
        } else {
          msg = 'خطأ من السيرفر (${e.response?.statusCode})';
        }
      } else {
        msg = 'خطأ في الاتصال: ${e.message}';
      }
      setState(() {
        _isLoading = false;
        _errorMessage = msg;
      });
    } catch (e) {
      debugPrint('[OTP ERROR] Unexpected error: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'خطأ غير متوقع: $e';
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
      final normalizedPhone = _normalizeIraqiPhone(phone);
      debugPrint('[VERIFY REQUEST] Target: ${appState.apiService.baseUrl}/auth/verify-otp');
      debugPrint('[VERIFY REQUEST] Phone: $normalizedPhone');
      
      final res = await appState.apiService.verifyOtp(
        normalizedPhone,
        otp,
        username: _usernameController.text.trim(),
      );
      debugPrint('[VERIFY SUCCESS] User authenticated: ${res['user']?['username']}');

      setState(() => _isLoading = false);
      widget.onLoginSuccess();
    } on DioException catch (e) {
      debugPrint('[VERIFY ERROR] DioException: status=${e.response?.statusCode}, type=${e.type}');
      String msg;
      if (e.response?.statusCode == 401) {
        msg = e.response?.data?['message'] ?? 'رمز التحقق غير صحيح أو انتهت صلاحيته (رمز الاختبار: 123456)';
      } else if (e.type == DioExceptionType.connectionTimeout ||
                 e.type == DioExceptionType.connectionError) {
        msg = 'تعذر الاتصال بالسيرفر أثناء التحقق. تأكد من اتصال الشبكة.';
      } else if (e.response != null) {
        final serverMsg = e.response?.data?['message'];
        msg = serverMsg is List ? serverMsg.join(', ') : (serverMsg?.toString() ?? 'خطأ في التحقق (${e.response?.statusCode})');
      } else {
        msg = 'خطأ في التحقق: ${e.message}';
      }
      setState(() {
        _isLoading = false;
        _errorMessage = msg;
      });
    } catch (e) {
      debugPrint('[VERIFY ERROR] Unexpected error: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'رمز التحقق غير صحيح أو حدث خطأ: $e';
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
                          style: const TextStyle(color: AppTheme.alertRed, fontWeight: FontWeight.bold),
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
                          child: const Text('تغيير رقم الهاتف', style: TextStyle()),
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
