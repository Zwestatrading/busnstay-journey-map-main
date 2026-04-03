import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/order_model.dart';

class OrderDocumentService {
  static final DateFormat _compactDate = DateFormat('yyyyMMdd');
  static final DateFormat _readableDate = DateFormat('dd MMM yyyy, HH:mm');

  String generateOrderNumber({required String orderId, DateTime? createdAt}) {
    final issuedAt = createdAt ?? DateTime.now();
    final sanitized = orderId.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
    final suffix = sanitized.length >= 4
        ? sanitized.substring(sanitized.length - 4)
        : sanitized.padLeft(4, '0');
    return 'FO-${_compactDate.format(issuedAt)}-$suffix';
  }

  String generateInvoiceNumber(FoodOrder order) {
    return 'INV-${generateOrderNumber(orderId: order.id, createdAt: order.orderTime).replaceFirst('FO-', '')}';
  }

  String generateOrderNumberFromRecord(Map<String, dynamic> record) {
    return generateOrderNumber(
      orderId: record['id']?.toString() ?? '0000',
      createdAt: DateTime.tryParse(record['created_at']?.toString() ?? '') ??
          DateTime.tryParse(record['orderTime']?.toString() ?? ''),
    );
  }

  FoodOrder foodOrderFromRecord(Map<String, dynamic> record) {
    final rawItems = record['items'] as List<dynamic>? ??
        record['order_items'] as List<dynamic>? ??
        const [];

    final items = rawItems.map((item) {
      final map = Map<String, dynamic>.from(item as Map);
      final menuItem = map['menu_items'] is Map
          ? Map<String, dynamic>.from(map['menu_items'] as Map)
          : const <String, dynamic>{};

      return OrderItem(
        name: (map['name'] ?? map['item_name'] ?? menuItem['name'] ?? 'Item')
            .toString(),
        quantity: (map['quantity'] as num?)?.toInt() ?? 1,
        price: (map['price'] as num?)?.toDouble() ??
            (map['unit_price'] as num?)?.toDouble() ??
            (menuItem['price'] as num?)?.toDouble() ??
            0,
        specialRequest:
            map['specialRequest']?.toString() ?? map['special_request']?.toString(),
      );
    }).toList();

    return FoodOrder.fromJson({
      'id': record['id'],
      'order_number': record['order_number'] ?? generateOrderNumberFromRecord(record),
      'invoice_number': record['invoice_number'],
      'customer_id': record['customer_id'],
      'customer_name': record['customer_name'],
      'customer_phone': record['customer_phone'],
      'restaurant_id': record['restaurant_id'],
      'restaurant_name': record['restaurant_name'],
      'town_id': record['town_id'],
      'town_name': record['town_name'],
      'journey_id': record['journey_id'],
      'items': items.map((item) => item.toJson()).toList(),
      'status': record['status'],
      'created_at': record['created_at'] ?? record['orderTime'],
      'payment_confirmed_at': record['payment_confirmed_at'],
      'special_instructions': record['special_instructions'],
      'delivery_fee': record['delivery_fee'],
      'platform_fee': record['platform_fee'],
      'estimated_bus_arrival_time': record['estimated_bus_arrival_time'],
      'delivery_address': record['delivery_address'],
      'pickup_address': record['pickup_address'],
      'accepted_at': record['accepted_at'],
      'accepted_by': record['accepted_by'],
    });
  }

  Future<Uint8List> generateApprovedOrderInvoice({
    required FoodOrder order,
    String approvedBy = 'Restaurant Manager',
  }) async {
    final invoiceNumber = order.invoiceNumberValue ?? generateInvoiceNumber(order);
    final approvedAt = order.approvedAt ?? DateTime.now();
    final document = pw.Document();

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'BusNStay Approved Order Invoice',
                    style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(order.restaurantName),
                ],
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: pw.BoxDecoration(
                  color: PdfColors.green100,
                  borderRadius: pw.BorderRadius.circular(12),
                ),
                child: pw.Text('APPROVED', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ),
            ],
          ),
          pw.SizedBox(height: 18),
          _infoGrid([
            _infoItem('Order Number', order.orderNumber),
            _infoItem('Invoice Number', invoiceNumber),
            _infoItem('Approved At', _readableDate.format(approvedAt)),
            _infoItem('Approved By', order.approvedBy ?? approvedBy),
            _infoItem('Customer', order.customerName),
            _infoItem('Town', order.townName),
          ]),
          pw.SizedBox(height: 18),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
            cellAlignment: pw.Alignment.centerLeft,
            headers: const ['Item', 'Qty', 'Unit Price', 'Line Total'],
            data: order.items
                .map(
                  (item) => [
                    item.name,
                    '${item.quantity}',
                    'K${item.price.toStringAsFixed(2)}',
                    'K${item.total.toStringAsFixed(2)}',
                  ],
                )
                .toList(),
          ),
          pw.SizedBox(height: 12),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Container(
              width: 220,
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _amountLine('Subtotal', order.subtotal),
                  _amountLine('Delivery Fee', order.deliveryFee),
                  _amountLine('Platform Fee', order.platformFee),
                  pw.Divider(),
                  _amountLine('Approved Total', order.total, bold: true),
                ],
              ),
            ),
          ),
          if ((order.specialInstructions ?? '').isNotEmpty) ...[
            pw.SizedBox(height: 16),
            pw.Text('Special Instructions', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Text(order.specialInstructions!),
          ],
        ],
      ),
    );

    return document.save();
  }

  Future<Uint8List> generateRestaurantSalesReport({
    required String restaurantName,
    required DateTime generatedAt,
    required List<FoodOrder> orders,
    Map<String, dynamic>? dailyRevenue,
    Map<String, dynamic>? monthlyRevenue,
  }) async {
    final document = pw.Document();
    final totalRevenue = orders.fold<double>(0, (sum, order) => sum + order.total);

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          pw.Text(
            '$restaurantName Sales Report',
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text('Generated ${_readableDate.format(generatedAt)}'),
          pw.SizedBox(height: 18),
          _infoGrid([
            _infoItem('Approved Orders', '${orders.length}'),
            _infoItem('Approved Revenue', 'K${totalRevenue.toStringAsFixed(2)}'),
            _infoItem('Daily Payout', 'K${dailyRevenue?['restaurant_payout'] ?? '0.00'}'),
            _infoItem('Monthly Payout', 'K${monthlyRevenue?['restaurant_payout'] ?? '0.00'}'),
          ]),
          pw.SizedBox(height: 18),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.orange700),
            headers: const ['Order #', 'Customer', 'Status', 'Approved Total'],
            data: orders
                .map(
                  (order) => [
                    order.orderNumber,
                    order.customerName,
                    order.statusLabel,
                    'K${order.total.toStringAsFixed(2)}',
                  ],
                )
                .toList(),
          ),
        ],
      ),
    );

    return document.save();
  }

  pw.Widget _infoGrid(List<pw.Widget> children) {
    return pw.Wrap(spacing: 12, runSpacing: 12, children: children);
  }

  pw.Widget _infoItem(String label, String value) {
    return pw.Container(
      width: 240,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          pw.SizedBox(height: 4),
          pw.Text(value, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  pw.Widget _amountLine(String label, double value, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: bold ? pw.TextStyle(fontWeight: pw.FontWeight.bold) : null),
          pw.Text('K${value.toStringAsFixed(2)}', style: bold ? pw.TextStyle(fontWeight: pw.FontWeight.bold) : null),
        ],
      ),
    );
  }
}