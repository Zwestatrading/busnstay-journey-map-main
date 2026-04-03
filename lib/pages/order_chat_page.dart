import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/order_chat_model.dart';
import '../services/order_chat_service.dart';
import '../theme/app_colors.dart';
import '../main.dart';

/// Full-page live chat for an order.
/// Used by both passenger (sender = passenger) and store (sender = store).
class OrderChatPage extends StatefulWidget {
  final String orderId;
  final String orderCode;
  final ChatSender mySide;
  final String myName;
  final String otherName;

  const OrderChatPage({
    Key? key,
    required this.orderId,
    required this.orderCode,
    required this.mySide,
    required this.myName,
    required this.otherName,
  }) : super(key: key);

  @override
  State<OrderChatPage> createState() => _OrderChatPageState();
}

class _OrderChatPageState extends State<OrderChatPage> {
  final _msgController = TextEditingController();
  final _transportController = TextEditingController();
  final _scrollController = ScrollController();
  late final OrderChatService _chatService;
  bool _showTransportField = false;

  @override
  void initState() {
    super.initState();
    _chatService = AppServices.orderChatService;
    _chatService.markRead(widget.orderId, widget.mySide);
  }

  @override
  void dispose() {
    _msgController.dispose();
    _transportController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send() async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    final transport = _transportController.text.trim();
    _msgController.clear();
    _transportController.clear();
    setState(() => _showTransportField = false);

    await _chatService.sendMessage(
      orderId: widget.orderId,
      sender: widget.mySide,
      senderName: widget.myName,
      message: text,
      transportNote: transport.isNotEmpty ? transport : null,
    );

    // Scroll to bottom after send
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isPassenger = widget.mySide == ChatSender.passenger;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F2E7),
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order ${widget.orderCode}',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'Chat with ${widget.otherName}',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        actions: [
          Icon(Icons.circle, size: 10, color: Colors.greenAccent),
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          // ── Messages list ──
          Expanded(
            child: StreamBuilder<List<OrderChatMessage>>(
              stream: _chatService.messagesStream(widget.orderId),
              initialData: _chatService.getCached(widget.orderId),
              builder: (context, snap) {
                final messages = snap.data ?? [];
                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 56,
                          color: AppColors.primary.withOpacity(0.3),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          isPassenger
                              ? 'Send a note about your transport\nor any special requests'
                              : 'No messages yet.\nPassenger notes will appear here.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.black45,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                  itemCount: messages.length,
                  itemBuilder: (_, i) =>
                      _buildBubble(messages[i]),
                );
              },
            ),
          ),

          // ── Transport note toggle (passenger only) ──
          if (isPassenger && _showTransportField)
            Container(
              color: AppColors.primary.withOpacity(0.08),
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
              child: Row(
                children: [
                  const Icon(Icons.directions_bus, size: 18, color: AppColors.primaryDark),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _transportController,
                      style: GoogleFonts.poppins(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'e.g. Bus 3, Seat 14A — arriving 2:30 PM',
                        hintStyle: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.black38,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _showTransportField = false),
                    child: const Icon(Icons.close, size: 18, color: Colors.black38),
                  ),
                ],
              ),
            ),

          // ── Input bar ──
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            padding: EdgeInsets.fromLTRB(
              8,
              8,
              8,
              8 + MediaQuery.of(context).padding.bottom,
            ),
            child: Row(
              children: [
                if (isPassenger)
                  IconButton(
                    icon: Icon(
                      Icons.directions_bus,
                      color: _showTransportField
                          ? AppColors.primary
                          : Colors.black38,
                    ),
                    tooltip: 'Add transport info',
                    onPressed: () => setState(
                      () => _showTransportField = !_showTransportField,
                    ),
                  ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _msgController,
                      style: GoogleFonts.poppins(fontSize: 14),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: isPassenger
                            ? 'Message store...'
                            : 'Reply to customer...',
                        hintStyle: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.black38,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Material(
                  color: AppColors.primary,
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: _send,
                    customBorder: const CircleBorder(),
                    child: const Padding(
                      padding: EdgeInsets.all(10),
                      child: Icon(Icons.send, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBubble(OrderChatMessage msg) {
    final isMe = msg.sender == widget.mySide;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Transport badge
            if (msg.transportNote != null && msg.transportNote!.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isMe
                      ? Colors.white.withOpacity(0.2)
                      : AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.directions_bus,
                      size: 13,
                      color: isMe ? Colors.white70 : AppColors.primaryDark,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        msg.transportNote!,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isMe ? Colors.white70 : AppColors.primaryDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            // Message text
            Text(
              msg.message,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: isMe ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            // Timestamp + read indicator
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  msg.timeLabel,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: isMe ? Colors.white60 : Colors.black38,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    msg.isRead ? Icons.done_all : Icons.done,
                    size: 13,
                    color: msg.isRead ? Colors.lightBlueAccent : Colors.white60,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
