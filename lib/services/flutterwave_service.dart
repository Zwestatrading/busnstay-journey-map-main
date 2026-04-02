class FlutterwaveService {
  // Flutterwave credentials - These should be in environment variables
  static const String publicKey = 'FLWPUBK_TEST-YOUR-KEY'; // Use your Flutterwave test key
  static const String encryptionKey = 'your-encryption-key'; // From Flutterwave dashboard

  // Get exchange rate (approximation for trading)
  static double getZMWToUSDRate() {
    // This would typically come from an API, using fixed rate for demo
    return 0.048; // 1 ZMW ≈ 0.048 USD (adjust based on current rates)
  }

  // Format Zambian currency
  static String formatZMW(double amount) {
    return 'K${amount.toStringAsFixed(2)}';
  }

  // Format USD currency
  static String formatUSD(double amount) {
    return '\$${amount.toStringAsFixed(2)}';
  }

  // Convert ZMW to USD
  static double zmwToUSD(double zmw) {
    return zmw * getZMWToUSDRate();
  }

  // Convert USD to ZMW
  static double usdToZMW(double usd) {
    return usd / getZMWToUSDRate();
  }

  // Calculate platform fee (10%)
  static double calculatePlatformFee(double amount) {
    return amount * 0.10;
  }

  // Get net amount after fee
  static double getNetAmount(double amount) {
    return amount - calculatePlatformFee(amount);
  }

  // Payment methods supported
  static const List<String> paymentMethods = [
    'Mobile Money (MTN)',
    'Mobile Money (Airtel)',
    'Mobile Money (Zamtel)',
    'Card Payment',
    'Bank Transfer',
    'USSD',
  ];

  // Get payment method display name
  static String getPaymentMethodDisplay(String method) {
    switch (method) {
      case 'mobile_money_mtn':
        return 'MTN Mobile Money';
      case 'mobile_money_airtel':
        return 'Airtel Money';
      case 'mobile_money_zamtel':
        return 'Zamtel Money';
      case 'card':
        return 'Card Payment';
      case 'bank':
        return 'Bank Transfer';
      case 'ussd':
        return 'USSD Payment';
      default:
        return method;
    }
  }

  // Validate phone number for mobile money (Zambia format)
  static bool isValidZambianPhone(String phone) {
    // Zambian numbers: +260-based or 0-based format
    final cleaned = phone.replaceAll(RegExp(r'\D'), '');
    if (cleaned.startsWith('260')) {
      return cleaned.length == 12; // 260 + 9 digits
    } else if (cleaned.startsWith('0')) {
      return cleaned.length == 10; // 0 + 9 digits
    }
    return false;
  }

  // Process payment with Flutterwave
  // This would typically be called from the payment modal
  static Future<bool> processPayment({
    required String reference,
    required double amount,
    required String paymentMethod,
    required String phone,
    required String email,
    required String fullName,
  }) async {
    // In production, this would use the actual Flutterwave SDK
    // For now, we return a simulated response
    print('Processing payment:');
    print('  Amount: K${amount.toStringAsFixed(2)}');
    print('  Method: $paymentMethod');
    print('  Phone: $phone');
    print('  Reference: $reference');

    // Simulate payment processing delay
    await Future.delayed(const Duration(seconds: 2));

    // In production, validate response from Flutterwave
    return true; // Simulated success
  }

  // Verify payment after completion
  static Future<bool> verifyPayment(String transactionId) async {
    // This would query Flutterwave API to verify transaction
    // Simulated for demo
    await Future.delayed(const Duration(milliseconds: 500));
    return true;
  }
}
