import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Comprehensive payment system for Zambia
/// Supports: Mobile Money (MTN, Airtel, Zamtel), Banks, Card Payments
class PaymentService {
  final SupabaseClient supabase;
  
  // Flutterwave configuration
  static const String FLUTTERWAVE_PUBLIC_KEY = 'FLWPUBK_TEST-YOUR-KEY';
  static const String FLUTTERWAVE_SECRET_KEY = 'FLWSECK_TEST-YOUR-KEY';
  static const String FLUTTERWAVE_BASE_URL = 'https://api.flutterwave.com/v3';

  // Payment gateway fees (in percentage)
  static const double MOBILE_MONEY_FEE_PERCENT = 2.5;
  static const double BANK_TRANSFER_FEE_PERCENT = 1.5;
  static const double CARD_PAYMENT_FEE_PERCENT = 3.5;
  
  // Platform fee on each transaction
  static const double PLATFORM_FEE_PERCENT = 10.0;

  PaymentService({required this.supabase});

  // ===== PAYMENT METHODS =====

  /// Get all available payment methods in Zambia
  static Map<String, Map<String, dynamic>> getPaymentMethods() {
    return {
      'mobile_money_mtn': {
        'name': 'MTN Mobile Money',
        'provider': 'MTN',
        'fee_percent': MOBILE_MONEY_FEE_PERCENT,
        'min_amount': 100,
        'max_amount': 10000,
      },
      'mobile_money_airtel': {
        'name': 'Airtel Money',
        'provider': 'Airtel',
        'fee_percent': MOBILE_MONEY_FEE_PERCENT,
        'min_amount': 100,
        'max_amount': 10000,
      },
      'mobile_money_zamtel': {
        'name': 'Zamtel Money',
        'provider': 'Zamtel',
        'fee_percent': MOBILE_MONEY_FEE_PERCENT,
        'min_amount': 50,
        'max_amount': 5000,
      },
      'bank_transfer': {
        'name': 'Bank Transfer',
        'provider': 'Multiple Banks',
        'fee_percent': BANK_TRANSFER_FEE_PERCENT,
        'min_amount': 500,
        'max_amount': 100000,
      },
      'card_payment': {
        'name': 'Card Payment',
        'provider': 'Visa/Mastercard',
        'fee_percent': CARD_PAYMENT_FEE_PERCENT,
        'min_amount': 100,
        'max_amount': 50000,
      },
      'ussd': {
        'name': 'USSD Payment',
        'provider': 'Bank USSD',
        'fee_percent': BANK_TRANSFER_FEE_PERCENT,
        'min_amount': 50,
        'max_amount': 10000,
      },
      'wallet': {
        'name': 'BusNStay Wallet',
        'provider': 'Internal Wallet',
        'fee_percent': 0,
        'min_amount': 1,
        'max_amount': 100000,
      },
    };
  }

  // ===== PAYMENT PROCESSING =====

  /// Initiate a payment transaction
  /// Returns: {'success': bool, 'transaction_id': String, 'payment_url': String?, 'error': String?}
  Future<Map<String, dynamic>> initiatePayment({
    required String paymentMethod,
    required double amount,
    required String phone,
    required String email,
    required String fullName,
    required String orderId,
    required String orderType, // 'delivery', 'hotel_booking', 'restaurant', 'station'
  }) async {
    try {
      // Calculate fees
      final methods = getPaymentMethods();
      final methodConfig = methods[paymentMethod];
      
      if (methodConfig == null) {
        return {
          'success': false,
          'error': 'Invalid payment method',
        };
      }

      // Validate amount
      if (amount < (methodConfig['min_amount'] as num)) {
        return {
          'success': false,
          'error': 'Minimum amount is ${methodConfig['min_amount']}',
        };
      }
      if (amount > (methodConfig['max_amount'] as num)) {
        return {
          'success': false,
          'error': 'Maximum amount is ${methodConfig['max_amount']}',
        };
      }

      final gatewayFee = amount * ((methodConfig['fee_percent'] as num) / 100);
      final platformFee = amount * (PLATFORM_FEE_PERCENT / 100);
      final totalAmount = amount + gatewayFee + platformFee;

      // Create transaction record
      final response = await supabase.from('payments').insert({
        'order_id': orderId,
        'order_type': orderType,
        'payment_method': paymentMethod,
        'amount': amount,
        'gateway_fee': gatewayFee,
        'platform_fee': platformFee,
        'total_amount': totalAmount,
        'phone': phone,
        'email': email,
        'full_name': fullName,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      }).select();

      if (response.isEmpty) {
        return {
          'success': false,
          'error': 'Failed to create transaction',
        };
      }

      final transactionId = response[0]['id'];

      // Route to appropriate payment gateway
      switch (paymentMethod) {
        case 'mobile_money_mtn':
        case 'mobile_money_airtel':
        case 'mobile_money_zamtel':
          return await _processMobileMoneyPayment(
            transactionId: transactionId,
            provider: methodConfig['provider'] as String,
            amount: totalAmount,
            phone: phone,
          );

        case 'card_payment':
          return await _initiateCardPayment(
            transactionId: transactionId,
            amount: totalAmount,
            email: email,
            fullName: fullName,
          );

        case 'bank_transfer':
          return await _initiateBankTransfer(
            transactionId: transactionId,
            amount: totalAmount,
            accountName: fullName,
            email: email,
          );

        case 'ussd':
          return {
            'success': true,
            'transaction_id': transactionId,
            'message': 'USSD payment initialized. Prompt user to complete the bank USSD flow.',
          };

        case 'wallet':
          await supabase.from('payments').update({
            'status': 'completed',
            'gateway_reference': 'wallet_$transactionId',
          }).eq('id', transactionId);

          return {
            'success': true,
            'transaction_id': transactionId,
            'message': 'Wallet payment completed successfully.',
          };

        default:
          return {
            'success': false,
            'error': 'Payment method not supported',
          };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error initiating payment: $e',
      };
    }
  }

  /// Process mobile money payment via Flutterwave
  Future<Map<String, dynamic>> _processMobileMoneyPayment({
    required String transactionId,
    required String provider,
    required double amount,
    required String phone,
  }) async {
    try {
      final payload = {
        'tx_ref': transactionId,
        'amount': amount,
        'currency': 'ZMW',
        'customer': {
          'phone_number': phone,
          'name': 'Customer',
        },
        'customizations': {
          'title': 'BUSNSTAY Payment',
          'description': 'Payment for your order',
          'logo': 'https://your-app/logo.png',
        },
      };

      // Map provider to Flutterwave payment plan
      String accountBank = 'ZM_MOBILE_MONEY';
      if (provider.toLowerCase() == 'mtn') {
        payload['account_bank'] = 'ZM_MTN';
      } else if (provider.toLowerCase() == 'airtel') {
        payload['account_bank'] = 'ZM_AIRTEL';
      }

      // Call Flutterwave API
      final response = await http.post(
        Uri.parse('$FLUTTERWAVE_BASE_URL/charges?type=mobile_money_zambia'),
        headers: {
          'Authorization': 'Bearer $FLUTTERWAVE_SECRET_KEY',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['status'] == 'success') {
          // Update transaction status
          await supabase.from('payments').update({
            'status': 'processing',
            'gateway_reference': result['data']['reference'],
          }).eq('id', transactionId);

          return {
            'success': true,
            'transaction_id': transactionId,
            'message': 'Payment initiated. Please confirm on your phone.',
          };
        }
      }

      return {
        'success': false,
        'error': 'Mobile money payment failed',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Error processing mobile money: $e',
      };
    }
  }

  /// Initiate card payment via Flutterwave
  Future<Map<String, dynamic>> _initiateCardPayment({
    required String transactionId,
    required double amount,
    required String email,
    required String fullName,
  }) async {
    try {
      // Generate Flutterwave payment link
      final payload = {
        'tx_ref': transactionId,
        'amount': amount,
        'currency': 'ZMW',
        'redirect_url': 'https://your-app/payment-callback',
        'customer': {
          'email': email,
          'name': fullName,
        },
        'customizations': {
          'title': 'BUSNSTAY Payment',
          'description': 'Complete your payment securely',
          'logo': 'https://your-app/logo.png',
        },
      };

      final response = await http.post(
        Uri.parse('$FLUTTERWAVE_BASE_URL/payments'),
        headers: {
          'Authorization': 'Bearer $FLUTTERWAVE_SECRET_KEY',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['status'] == 'success') {
          await supabase.from('payments').update({
            'status': 'awaiting_payment',
            'gateway_reference': result['data']['id'].toString(),
          }).eq('id', transactionId);

          return {
            'success': true,
            'transaction_id': transactionId,
            'payment_url': result['data']['link'],
            'message': 'Payment link created. Redirect to complete payment.',
          };
        }
      }

      return {
        'success': false,
        'error': 'Card payment initialization failed',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Error initiating card payment: $e',
      };
    }
  }

  /// Initiate bank transfer payment
  Future<Map<String, dynamic>> _initiateBankTransfer({
    required String transactionId,
    required double amount,
    required String accountName,
    required String email,
  }) async {
    try {
      // Generate bank account details for customer transfer
      const bankDetails = {
        'bank_name': 'Standard Chartered Bank Zambia',
        'account_name': 'BUSNSTAY Limited',
        'account_number': '1234567890',
        'branch': 'Lusaka Main',
        'reference': 'AUTO_TRANSFER'
      };

      // Create bank transfer record
      await supabase.from('payments').update({
        'status': 'awaiting_bank_transfer',
        'bank_details': bankDetails,
      }).eq('id', transactionId);

      return {
        'success': true,
        'transaction_id': transactionId,
        'bank_details': {
          'bank_name': bankDetails['bank_name'],
          'account_name': bankDetails['account_name'],
          'account_number': bankDetails['account_number'],
          'amount': amount,
          'reference': '$transactionId-${accountName.replaceAll(" ", "")}',
        },
        'message': 'Bank transfer initiated. Send payment to the account details.',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Error initiating bank transfer: $e',
      };
    }
  }

  // ===== PAYMENT VERIFICATION =====

  /// Verify payment status
  /// Checks with gateway to confirm payment completion
  Future<Map<String, dynamic>> verifyPayment(String transactionId) async {
    try {
      final payment =
          await supabase.from('payments').select().eq('id', transactionId).single() as Map;

      if (payment['status'] == 'completed') {
        return {
          'verified': true,
          'status': 'completed',
          'message': 'Payment verified successfully',
        };
      }

      // For payments not yet verified, check with gateway
      if (payment['gateway_reference'] != null) {
        final gatewayRef = payment['gateway_reference'];

        // Query Flutterwave API
        final response = await http.get(
          Uri.parse('$FLUTTERWAVE_BASE_URL/transactions/$gatewayRef/verify'),
          headers: {
            'Authorization': 'Bearer $FLUTTERWAVE_SECRET_KEY',
          },
        );

        if (response.statusCode == 200) {
          final result = jsonDecode(response.body);
          if (result['status'] == 'success' && result['data']['status'] == 'successful') {
            // Update payment as completed
            await supabase.from('payments').update({
              'status': 'completed',
              'verified_at': DateTime.now().toIso8601String(),
            }).eq('id', transactionId);

            return {
              'verified': true,
              'status': 'completed',
              'message': 'Payment verified',
            };
          }
        }
      }

      return {
        'verified': false,
        'status': payment['status'],
        'message': 'Payment not yet completed',
      };
    } catch (e) {
      return {
        'verified': false,
        'error': 'Error verifying payment: $e',
      };
    }
  }

  // ===== PAYMENT HISTORY =====

  /// Get payment history for a user
  Future<List<Map<String, dynamic>>> getPaymentHistory({
    required String userId,
  }) async {
    try {
      final response = await supabase
          .from('payments')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error fetching payment history: $e');
      return [];
    }
  }

  /// Get payment details
  Future<Map<String, dynamic>?> getPaymentDetails(String transactionId) async {
    try {
      final response =
          await supabase.from('payments').select().eq('id', transactionId).single();

      return response as Map<String, dynamic>;
    } catch (e) {
      print('❌ Error fetching payment details: $e');
      return null;
    }
  }

  // ===== REFUNDS =====

  /// Initiate refund for a payment
  Future<Map<String, dynamic>> refundPayment({
    required String transactionId,
    required String reason,
  }) async {
    try {
      final payment = await supabase
          .from('payments')
          .select()
          .eq('id', transactionId)
          .single() as Map;

      if (payment['status'] != 'completed') {
        return {
          'success': false,
          'error': 'Can only refund completed payments',
        };
      }

      // Process refund with gateway
      final response = await http.post(
        Uri.parse('$FLUTTERWAVE_BASE_URL/refund'),
        headers: {
          'Authorization': 'Bearer $FLUTTERWAVE_SECRET_KEY',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'id': payment['gateway_reference'],
          'amount': payment['total_amount'],
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['status'] == 'success') {
          // Update payment status
          await supabase.from('payments').update({
            'status': 'refunded',
            'refund_reason': reason,
            'refunded_at': DateTime.now().toIso8601String(),
          }).eq('id', transactionId);

          return {
            'success': true,
            'message': '✅ Refund processed successfully',
          };
        }
      }

      return {
        'success': false,
        'error': 'Refund processing failed',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Error processing refund: $e',
      };
    }
  }

  // ===== UTILITIES =====

  /// Validate Zambian phone number
  static bool isValidZambianPhone(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'\D'), '');
    if (cleaned.startsWith('260')) {
      return cleaned.length == 12; // 260 + 9 digits
    } else if (cleaned.startsWith('0')) {
      return cleaned.length == 10; // 0 + 9 digits
    }
    return false;
  }

  /// Format currency
  static String formatCurrency(double amount, String currency) {
    switch (currency) {
      case 'ZMW':
        return 'K${amount.toStringAsFixed(2)}';
      case 'USD':
        return '\$${amount.toStringAsFixed(2)}';
      default:
        return '${amount.toStringAsFixed(2)} $currency';
    }
  }

  /// Convert ZMW to USD (using current exchange rate)
  static Future<double> convertZMWtoUSD(double zmw) async {
    // In production, fetch real exchange rates from API
    const exchangeRate = 0.052; // 1 ZMW ≈ 0.052 USD (sample)
    return zmw * exchangeRate;
  }
}
