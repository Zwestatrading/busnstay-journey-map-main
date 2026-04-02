import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/wallet_model.dart';
import '../models/order_model.dart';

class DatabaseService {
  static const String _databaseName = 'busnstay.db';
  static const int _databaseVersion = 1;

  static Database? _database;

  Future<Database> get database async {
    _database ??= await _initializeDatabase();
    return _database!;
  }

  Future<Database> _initializeDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _createTables,
    );
  }

  Future<void> _createTables(Database db, int version) async {
    // Transactions table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS transactions (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        method TEXT NOT NULL,
        status TEXT NOT NULL,
        description TEXT,
        date TEXT NOT NULL,
        reference TEXT,
        syncedToServer INTEGER DEFAULT 0
      )
    ''');

    // Orders table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS orders (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        restaurantId TEXT,
        status TEXT NOT NULL,
        totalAmount REAL NOT NULL,
        items TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        deliveryAddress TEXT,
        syncedToServer INTEGER DEFAULT 0
      )
    ''');

    // Deliveries table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS deliveries (
        id TEXT PRIMARY KEY,
        agentId TEXT NOT NULL,
        status TEXT NOT NULL,
        pickupAddress TEXT NOT NULL,
        deliveryAddress TEXT NOT NULL,
        fee REAL NOT NULL,
        createdAt TEXT NOT NULL,
        syncedToServer INTEGER DEFAULT 0
      )
    ''');

    // Bookings table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS bookings (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        hotelId TEXT,
        roomId TEXT,
        status TEXT NOT NULL,
        checkIn TEXT NOT NULL,
        checkOut TEXT NOT NULL,
        totalPrice REAL NOT NULL,
        createdAt TEXT NOT NULL,
        syncedToServer INTEGER DEFAULT 0
      )
    ''');

    // Queue table for pending operations
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sync_queue (
        id TEXT PRIMARY KEY,
        operation TEXT NOT NULL,
        tableName TEXT NOT NULL,
        data TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        syncedAt TEXT
      )
    ''');
  }

  // TRANSACTION OPERATIONS
  Future<void> insertTransaction(WalletTransaction transaction) async {
    final db = await database;
    await db.insert('transactions', {
      'id': transaction.id,
      'userId': 'local',
      'type': transaction.type.toString().split('.').last,
      'amount': transaction.amount,
      'method': transaction.method.toString().split('.').last,
      'status': transaction.status.toString().split('.').last,
      'description': transaction.description,
      'date': transaction.date.toIso8601String(),
      'reference': transaction.reference,
      'syncedToServer': 0,
    });
  }

  Future<List<WalletTransaction>> getTransactions(String userId) async {
    final db = await database;
    final maps = await db.query(
      'transactions',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
    );

    return maps
        .map((map) => WalletTransaction(
              id: map['id'] as String,
              type: _parseTransactionType(map['type'] as String),
              amount: map['amount'] as double,
              method: _parsePaymentMethod(map['method'] as String),
              status: _parseTransactionStatus(map['status'] as String),
              description: (map['description'] as String?) ?? '',
              date: DateTime.parse(map['date'] as String),
              reference: map['reference'] as String?,
            ))
        .toList();
  }

  // ORDER OPERATIONS
  Future<void> insertOrder(FoodOrder order) async {
    final db = await database;
    await db.insert('orders', {
      'id': order.id,
      'userId': 'current_user',
      'status': order.status.toString().split('.').last,
      'totalAmount': order.items.fold<double>(
          0, (sum, item) => sum + (item.price * item.quantity)),
      'items': order.items.map((i) => '${i.name}:${i.quantity}').join(','),
      'createdAt': order.orderTime.toIso8601String(),
      'syncedToServer': 0,
    });
  }

  Future<List<FoodOrder>> getPendingOrders() async {
    final db = await database;
    final maps = await db.query(
      'orders',
      where: 'status IN (?, ?)',
      whereArgs: ['pending', 'accepted'],
      orderBy: 'createdAt DESC',
    );
    return _mapOrdersFromDb(maps);
  }

  // DELIVERY OPERATIONS
  Future<void> insertDelivery(Map<String, dynamic> delivery) async {
    final db = await database;
    await db.insert('deliveries', delivery);
  }

  Future<List<Map<String, dynamic>>> getAvailableDeliveries() async {
    final db = await database;
    return await db.query('deliveries', where: 'status = ?', whereArgs: ['available']);
  }

  // SYNC QUEUE OPERATIONS
  Future<void> addToSyncQueue({
    required String id,
    required String operation,
    required String tableName,
    required Map<String, dynamic> data,
  }) async {
    final db = await database;
    await db.insert('sync_queue', {
      'id': id,
      'operation': operation,
      'tableName': tableName,
      'data': _encodeData(data),
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getPendingSyncQueue() async {
    final db = await database;
    return await db.query('sync_queue', where: 'syncedAt IS NULL');
  }

  Future<void> markAsSynced(String queueId) async {
    final db = await database;
    await db.update(
      'sync_queue',
      {'syncedAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [queueId],
    );
  }

  // HELPER METHODS
  String _encodeData(Map<String, dynamic> data) {
    return data.entries.map((e) => '${e.key}=${e.value}').join('&');
  }

  TransactionType _parseTransactionType(String type) {
    return TransactionType.values.firstWhere(
      (e) => e.toString().split('.').last == type,
      orElse: () => TransactionType.credit,
    );
  }

  PaymentMethod _parsePaymentMethod(String method) {
    return PaymentMethod.values.firstWhere(
      (e) => e.toString().split('.').last == method,
      orElse: () => PaymentMethod.mobileMoney,
    );
  }

  TransactionStatus _parseTransactionStatus(String status) {
    return TransactionStatus.values.firstWhere(
      (e) => e.toString().split('.').last == status,
      orElse: () => TransactionStatus.pending,
    );
  }

  List<FoodOrder> _mapOrdersFromDb(List<Map<String, dynamic>> maps) {
    return maps
        .map((map) => FoodOrder(
              id: map['id'],
              customerId: map['customer_id'] ?? '',
              customerName: map['customer_name'] ?? 'Customer',
              customerPhoneNumber: map['customer_phone'] ?? '',
              restaurantId: map['restaurant_id'] ?? '',
              restaurantName: map['restaurant_name'] ?? 'Unknown',
              townId: map['town_id'] ?? '',
              townName: map['town_name'] ?? 'Unknown',
              journeyId: map['journey_id'] ?? '',
              items: [],
              status: _parseOrderStatus(map['status']),
              orderTime: DateTime.parse(map['createdAt']),
              specialInstructions: map['special_instructions'] ?? '',
              deliveryFee: (map['delivery_fee'] as num?)?.toDouble() ?? 0,
              platformFee: (map['platform_fee'] as num?)?.toDouble() ?? 0,
            ))
        .toList();
  }

  OrderStatus _parseOrderStatus(String status) {
    return OrderStatus.values.firstWhere(
      (e) => e.toString().split('.').last == status,
      orElse: () => OrderStatus.pending,
    );
  }

  // Clear all data (for logout)
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('transactions');
    await db.delete('orders');
    await db.delete('deliveries');
    await db.delete('bookings');
  }
}
