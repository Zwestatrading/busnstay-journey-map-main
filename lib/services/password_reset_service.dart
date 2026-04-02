import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PasswordResetService extends ChangeNotifier {
  final supabaseClient = Supabase.instance.client;
  
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  String? _resetEmail;
  String? _resetToken;
  int _otpAttempts = 0;
  final int _maxOtpAttempts = 3;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  String? get resetEmail => _resetEmail;
  bool get hasValidToken => _resetToken != null;

  /// Request password reset - sends OTP/magic link via email
  Future<bool> requestPasswordReset(String email) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      // Use Supabase's built-in password recovery
      final response = await supabaseClient.auth.resetPasswordForEmail(
        email,
        redirectTo: 'io.supabase.flutter://reset-callback/',
      );

      _resetEmail = email;
      _otpAttempts = 0;
      _successMessage = 'Password reset link sent to $email. Check your inbox!';
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to send reset link: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      print('Password reset request error: $e');
      return false;
    }
  }

  /// Verify reset token and update password
  Future<bool> resetPasswordWithToken({
    required String token,
    required String newPassword,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      // Exchange token for new password
      final response = await supabaseClient.auth.verifyOTP(
        email: _resetEmail!,
        token: token,
        type: OtpType.recovery,
      );

      if (response.user != null) {
        // Now update password
        await supabaseClient.auth.updateUser(
          UserAttributes(password: newPassword),
        );

        _successMessage = 'Password updated successfully!';
        _resetToken = null;
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _errorMessage = 'Invalid reset token';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to reset password: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      print('Password reset error: $e');
      return false;
    }
  }

  /// Clear state
  void reset() {
    _errorMessage = null;
    _successMessage = null;
    _resetEmail = null;
    _resetToken = null;
    _otpAttempts = 0;
    _isLoading = false;
    notifyListeners();
  }
}
