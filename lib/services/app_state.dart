import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import '../models/user_model.dart';
import '../models/wallet_model.dart';
import '../models/order_model.dart';
import '../models/booking_model.dart';
import '../models/delivery_model.dart';
import 'supabase_service.dart';
import 'database_service.dart';
import 'flutterwave_service.dart';

class AppState extends ChangeNotifier {
  // User state
  AppUser? _user;
  bool _isLoggedIn = false;
  bool _isAuthenticating = false;
  String? _authError;

  // Service instances
  late final SupabaseService _supabaseService;
  late final DatabaseService _databaseService;

  // Wallet & loyalty
  Wallet _wallet = Wallet(
    balance: 2450.00,
    transactions: [],
    totalSpent: 1230.00,
    totalReceived: 3680.00,
  );

  LoyaltyInfo _loyalty = LoyaltyInfo(
    currentPoints: 2450,
    totalEarned: 5230,
    tier: LoyaltyTier.silver,
    pointsToNextTier: 550,
    availableRewards: [],
  );

  // Getters
  AppUser? get user => _user;
  bool get isLoggedIn => _isLoggedIn;
  bool get isAuthenticating => _isAuthenticating;
  String? get authError => _authError;
  Wallet get wallet => _wallet;
  LoyaltyInfo get loyalty => _loyalty;
  SupabaseService get supabaseService => _supabaseService;
  DatabaseService get databaseService => _databaseService;

  AppState() {
    _supabaseService = SupabaseService();
    _databaseService = DatabaseService();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      await _supabaseService.initialize();
      if (_supabaseService.isAuthenticated()) {
        await _restoreSession();
      }
    } catch (e) {
      print('Error initializing Supabase: $e');
    }
  }

  // ============ AUTHENTICATION ============
  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
    required UserRole role,
  }) async {
    _isAuthenticating = true;
    _authError = null;
    notifyListeners();

    try {
      final authUser = await _supabaseService.signUp(
        email: email,
        password: password,
        name: name,
        role: role,
      );

      if (authUser != null) {
        _user = AppUser(
          id: authUser.id,
          name: name,
          email: email,
          phone: '+260 97 123 4567',
          role: role,
          memberSince: DateTime.now(),
        );
        _isLoggedIn = true;
        _initDemoData();
      }
      _isAuthenticating = false;
      notifyListeners();
      return true;
    } catch (e) {
      _authError = e.toString();
      _isAuthenticating = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
    required UserRole role,
  }) async {
    _isAuthenticating = true;
    _authError = null;
    notifyListeners();

    try {
      final authUser = await _supabaseService.signIn(
        email: email,
        password: password,
      );

      if (authUser != null) {
        final profile = await _supabaseService.getUserProfile(authUser.id);
        _user = AppUser(
          id: authUser.id,
          name: profile?['name'] ?? 'User',
          email: email,
          phone: profile?['phone'] ?? '+260 97 123 4567',
          role: role,
          memberSince: DateTime.parse(profile?['member_since'] ?? DateTime.now().toIso8601String()),
        );
        _isLoggedIn = true;
        await _restoreWalletFromDatabase();
        _initDemoData();
      }
      _isAuthenticating = false;
      notifyListeners();
      return true;
    } catch (e) {
      _authError = e.toString();
      _isAuthenticating = false;
      notifyListeners();
      return false;
    }
  }

  // Demo login for testing
  void demoLogin(String email, UserRole role) {
    _user = AppUser(
      id: 'user_demo_${role.toString().split('.').last}',
      name: _demoNameForRole(role),
      email: email.isNotEmpty ? email : 'demo@busnstay.com',
      phone: '+260 97 123 4567',
      role: role,
      memberSince: DateTime(2024, 3, 15),
    );
    _isLoggedIn = true;
    _initDemoData();
    notifyListeners();
  }

  Future<void> _restoreSession() async {
    final currentUser = _supabaseService.getCurrentUser();
    if (currentUser != null) {
      final profile = await _supabaseService.getUserProfile(currentUser.id);
      _user = AppUser(
        id: currentUser.id,
        name: profile?['name'] ?? 'User',
        email: currentUser.email ?? '',
        phone: profile?['phone'] ?? '+260 97 123 4567',
        role: _parseRole(profile?['role'] ?? 'passenger'),
        memberSince: DateTime.parse(profile?['member_since'] ?? DateTime.now().toIso8601String()),
      );
      _isLoggedIn = true;
      await _restoreWalletFromDatabase();
      notifyListeners();
    }
  }

  Future<void> logout() async {
    try {
      await _supabaseService.signOut();
      await _databaseService.clearAllData();
      _user = null;
      _isLoggedIn = false;
      _authError = null;
      _wallet = Wallet(balance: 0, transactions: [], totalSpent: 0, totalReceived: 0);
      notifyListeners();
    } catch (e) {
      print('Error during logout: $e');
    }
  }

  // ============ WALLET OPERATIONS ============
  Future<void> addFunds(double amount, PaymentMethod method) async {
    final tx = WalletTransaction(
      id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
      userId: _user?.id ?? 'guest',
      amount: amount,
      type: TransactionType.credit,
      method: method,
      status: TransactionStatus.completed,
      description: 'Added funds via ${method.name}',
      date: DateTime.now(),
      reference: 'REF_${DateTime.now().millisecondsSinceEpoch}',
    );

    // Save to local database immediately
    await _databaseService.insertTransaction(tx);

    // Update wallet
    _wallet = Wallet(
      balance: _wallet.balance + amount,
      transactions: [tx, ..._wallet.transactions],
      totalSpent: _wallet.totalSpent,
      totalReceived: _wallet.totalReceived + amount,
    );

    // Update loyalty points (1 point per K10)
    final pointsEarned = (amount / 10).toInt();
    _loyalty = LoyaltyInfo(
      currentPoints: _loyalty.currentPoints + pointsEarned,
      totalEarned: _loyalty.totalEarned + pointsEarned,
      tier: _calculateTier(_loyalty.currentPoints + pointsEarned),
      pointsToNextTier: _getPointsToNextTier(_loyalty.currentPoints + pointsEarned),
      availableRewards: _loyalty.availableRewards,
    );

    notifyListeners();

    // Sync to Supabase when online
    if (_supabaseService.isAuthenticated()) {
      try {
        await _supabaseService.client.from('transactions').insert({
          'id': tx.id,
          'user_id': _user?.id,
          'type': tx.type.toString().split('.').last,
          'amount': tx.amount,
          'method': tx.method.toString().split('.').last,
          'status': tx.status.toString().split('.').last,
          'description': tx.description,
          'reference': tx.reference,
        });
      } catch (e) {
        print('Error syncing to Supabase: $e');
      }
    }
  }

  Future<void> transferFunds(double amount, String recipient) async {
    if (amount > _wallet.balance) return;

    final tx = WalletTransaction(
      id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
      userId: _user?.id ?? 'guest',
      amount: amount,
      type: TransactionType.debit,
      method: PaymentMethod.wallet,
      status: TransactionStatus.completed,
      description: 'Transfer to $recipient',
      date: DateTime.now(),
      reference: 'TXN_${DateTime.now().millisecondsSinceEpoch}',
    );

    await _databaseService.insertTransaction(tx);

    _wallet = Wallet(
      balance: _wallet.balance - amount,
      transactions: [tx, ..._wallet.transactions],
      totalSpent: _wallet.totalSpent + amount,
      totalReceived: _wallet.totalReceived,
    );

    notifyListeners();
  }

  Future<void> withdrawFunds(double amount) async {
    if (amount > _wallet.balance) return;

    final tx = WalletTransaction(
      id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
      userId: _user?.id ?? 'guest',
      amount: amount,
      type: TransactionType.debit,
      method: PaymentMethod.mobileMoneyMTN,
      status: TransactionStatus.processing,
      description: 'Withdrawal to mobile money',
      date: DateTime.now(),
      reference: 'WD_${DateTime.now().millisecondsSinceEpoch}',
    );

    await _databaseService.insertTransaction(tx);

    _wallet = Wallet(
      balance: _wallet.balance - amount,
      transactions: [tx, ..._wallet.transactions],
      totalSpent: _wallet.totalSpent + amount,
      totalReceived: _wallet.totalReceived,
    );

    notifyListeners();
  }

  // ============ LOYALTY OPERATIONS ============
  Future<bool> redeemReward(String rewardId) async {
    final reward = _loyalty.availableRewards.firstWhere(
      (r) => r.id == rewardId,
      orElse: () => LoyaltyReward(id: '', title: '', pointsCost: 0),
    );

    if (reward.id.isEmpty || _loyalty.currentPoints < reward.pointsCost) {
      return false;
    }

    _loyalty = LoyaltyInfo(
      currentPoints: _loyalty.currentPoints - reward.pointsCost,
      totalEarned: _loyalty.totalEarned,
      tier: _loyalty.tier,
      pointsToNextTier: _loyalty.pointsToNextTier,
      availableRewards: _loyalty.availableRewards.map((r) {
        if (r.id == rewardId) {
          return LoyaltyReward(
            id: r.id,
            title: r.title,
            pointsCost: r.pointsCost,
            category: r.category,
            isRedeemed: true,
          );
        }
        return r;
      }).toList(),
    );

    notifyListeners();
    return true;
  }

  // ============ FLUTTERWAVE PAYMENT ============
  Future<bool> processFlutterwavePayment({
    required double amount,
    required String paymentMethod,
    required String phone,
    required String email,
    required String fullName,
  }) async {
    try {
      final reference = 'FLW_${DateTime.now().millisecondsSinceEpoch}';

      final success = await FlutterwaveService.processPayment(
        reference: reference,
        amount: amount,
        paymentMethod: paymentMethod,
        phone: phone,
        email: email,
        fullName: fullName,
      );

      if (success) {
        // Calculate platform fee
        final platformFee = FlutterwaveService.calculatePlatformFee(amount);
        final netAmount = amount - platformFee;

        // Add transaction with fee info
        await addFunds(netAmount, _parsePaymentMethod(paymentMethod));
        return true;
      }
      return false;
    } catch (e) {
      print('Payment processing error: $e');
      return false;
    }
  }

  // ============ HELPER METHODS ============
  void _initDemoData() {
    _wallet = Wallet(
      balance: 2450.00,
      transactions: _demoTransactions(),
      totalSpent: 1230.00,
      totalReceived: 3680.00,
    );
    _loyalty = LoyaltyInfo(
      currentPoints: 2450,
      totalEarned: 5230,
      tier: LoyaltyTier.silver,
      pointsToNextTier: 550,
      availableRewards: _demoRewards(),
    );
  }

  Future<void> _restoreWalletFromDatabase() async {
    if (_user == null) return;
    final transactions = await _databaseService.getTransactions(_user!.id);
    if (transactions.isNotEmpty) {
      double totalReceived = 0;
      double totalSpent = 0;
      for (var tx in transactions) {
        if (tx.type == TransactionType.credit) {
          totalReceived += tx.amount;
        } else {
          totalSpent += tx.amount;
        }
      }

      _wallet = Wallet(
        balance: totalReceived - totalSpent,
        transactions: transactions,
        totalSpent: totalSpent,
        totalReceived: totalReceived,
      );
    }
  }

  String _demoNameForRole(UserRole role) {
    switch (role) {
      case UserRole.passenger:
        return 'Traveler';
      case UserRole.busOperator:
        return 'Bus Operator';
      case UserRole.restaurantAdmin:
        return 'Restaurant Manager';
      case UserRole.deliveryAgent:
        return 'Delivery Agent';
      case UserRole.hotelManager:
        return 'Hotel Manager';
      case UserRole.platformAdmin:
        return 'System Admin';
      case UserRole.guest:
        return 'Guest';
    }
  }

  UserRole _parseRole(String roleString) {
    return UserRole.values.firstWhere(
      (e) => e.toString().split('.').last == roleString,
      orElse: () => UserRole.passenger,
    );
  }

  PaymentMethod _parsePaymentMethod(String method) {
    switch (method.toLowerCase()) {
      case 'mobile_money_mtn':
      case 'mtn':
        return PaymentMethod.mobileMoneyMTN;
      case 'mobile_money_airtel':
      case 'airtel':
        return PaymentMethod.mobileMoneyAirtel;
      case 'card':
        return PaymentMethod.card;
      case 'bank':
        return PaymentMethod.bankTransfer;
      case 'ussd':
        return PaymentMethod.ussd;
      default:
        return PaymentMethod.mobileMoneyMTN;
    }
  }

  LoyaltyTier _calculateTier(int points) {
    if (points < 1000) return LoyaltyTier.bronze;
    if (points < 2000) return LoyaltyTier.silver;
    if (points < 5000) return LoyaltyTier.gold;
    return LoyaltyTier.platinum;
  }

  int _getPointsToNextTier(int currentPoints) {
    if (currentPoints < 1000) return 1000 - currentPoints;
    if (currentPoints < 2000) return 2000 - currentPoints;
    if (currentPoints < 5000) return 5000 - currentPoints;
    return 0;
  }

  List<WalletTransaction> _demoTransactions() {
    return [
      WalletTransaction(
        id: 'tx_001',
        userId: 'user_demo',
        amount: 500.0,
        type: TransactionType.credit,
        method: PaymentMethod.mobileMoneyMTN,
        status: TransactionStatus.completed,
        description: 'Added funds via MTN',
        date: DateTime.now().subtract(const Duration(days: 2)),
      ),
      WalletTransaction(
        id: 'tx_002',
        userId: 'user_demo',
        amount: 150.0,
        type: TransactionType.debit,
        method: PaymentMethod.wallet,
        status: TransactionStatus.completed,
        description: 'Bus fare: Lusaka to Livingstone',
        date: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
  }

  List<LoyaltyReward> _demoRewards() {
    return [
      LoyaltyReward(
        id: 'reward_001',
        title: 'Free Bus Ride',
        pointsCost: 500,
        category: 'Travel',
      ),
      LoyaltyReward(
        id: 'reward_002',
        title: '50% Hotel Discount',
        pointsCost: 1000,
        category: 'Accommodation',
      ),
      LoyaltyReward(
        id: 'reward_003',
        title: 'Free Meal',
        pointsCost: 300,
        category: 'Food',
      ),
    ];
  }

  // Demo data generators
  List<FoodOrder> getDemoOrders() {
    return [
      FoodOrder(
        id: 'ORD-001',
        customerName: 'John Mansa',
        items: [
          OrderItem(name: 'Nshima', quantity: 1, price: 25.0),
          OrderItem(name: 'Chicken', quantity: 1, price: 45.0),
        ],
        status: OrderStatus.pending,
        orderTime: DateTime.now(),
        specialInstructions: 'Extra spicy',
        deliveryFee: 5.0,
      ),
      FoodOrder(
        id: 'ORD-002',
        customerName: 'Grace Tembo',
        items: [
          OrderItem(name: 'Ifisashi', quantity: 1, price: 30.0),
          OrderItem(name: 'Rice', quantity: 1, price: 15.0),
        ],
        status: OrderStatus.accepted,
        orderTime: DateTime.now().subtract(const Duration(minutes: 15)),
        specialInstructions: 'Less salt',
        deliveryFee: 5.0,
      ),
    ];
  }

  List<HotelBooking> getDemoBookings() {
    return [
      HotelBooking(
        id: 'BK-001',
        guestName: 'Mwansa Siwale',
        roomNumber: '301',
        roomType: 'Deluxe',
        checkIn: DateTime.now(),
        checkOut: DateTime.now().add(const Duration(days: 2)),
        guests: 2,
        pricePerNight: 250.0,
        status: BookingStatus.confirmed,
      ),
    ];
  }

  List<HotelRoom> getDemoRooms() {
    return [
      HotelRoom(
        id: 'R-001',
        number: '101',
        type: 'Standard',
        pricePerNight: 150.0,
        capacity: 2,
        isAvailable: true,
        amenities: ['WiFi', 'AC', 'TV'],
      ),
      HotelRoom(
        id: 'R-002',
        number: '301',
        type: 'Deluxe',
        pricePerNight: 250.0,
        capacity: 2,
        isAvailable: false,
        amenities: ['WiFi', 'AC', 'TV', 'Mini Bar'],
      ),
    ];
  }

  List<DeliveryJob> getDemoDeliveries() {
    return [
      DeliveryJob(
        id: 'DEL-001',
        pickupAddress: 'Nando\'s, Cairo Road',
        deliveryAddress: 'Ridgeway, Lusaka',
        distance: 8.5,
        fee: 12.0,
        customerName: 'Bwalya Mvula',
        phone: '+260 97 123 4567',
        status: DeliveryStatus.available,
        createdAt: DateTime.now(),
        itemDescription: 'Food order - 2 items',
      ),
    ];
  }

  List<BusJourney> getDemoJourneys() {
    return [
      BusJourney(
        id: 'J-001',
        origin: 'Lusaka',
        destination: 'Livingstone',
        departure: DateTime.now().add(const Duration(hours: 2)),
        arrival: DateTime.now().add(const Duration(hours: 8)),
        price: 120.0,
        totalSeats: 52,
        bookedSeats: 35,
        busNumber: 'BUS-001',
      ),
    ];
  }
}
