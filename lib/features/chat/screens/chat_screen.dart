import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import '../../../providers/chat_provider.dart';
import '../../../data/models/chat_message_model.dart';
import '../../../data/services/api_service.dart';
import '../../../core/widgets/nyutji_notif.dart';
import '../../../core/widgets/shimmer_loading.dart';
import 'package:cached_network_image/cached_network_image.dart';

// ── Riverpod Provider ─────────────────────────────────────────────────────────
final chatProvider = ChangeNotifierProvider.autoDispose<ChatProvider>(
  (ref) => ChatProvider(),
);

class ChatScreen extends ConsumerStatefulWidget {
  static String? activeOrderNumber;
  static String? activeChannel;

  final String orderNumber;
  final String channel; // 'PL_ML', 'PL_KL', atau 'ML_KL'
  final String partnerName;
  final String partnerRole;
  final String? partnerPhoto;

  const ChatScreen({
    super.key,
    required this.orderNumber,
    required this.channel,
    required this.partnerName,
    required this.partnerRole,
    this.partnerPhoto,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _refreshTimer;
  bool _isFirstLoad = true;

  String _myId = '';
  String _myName = '';
  String _myRole = '';

  static const Color _primaryTeal = Color(0xFF0D9488);
  static const Color _bgLight = Color(0xFFF5F5F5);

  @override
  void initState() {
    super.initState();
    ChatScreen.activeOrderNumber = widget.orderNumber;
    ChatScreen.activeChannel = widget.channel;
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    
    String myId = '';
    String myName = '';
    
    final userDataStr = prefs.getString('user_data');
    if (userDataStr != null) {
      try {
        final userData = jsonDecode(userDataStr);
        myId = (userData['identifier'] ?? userData['email'] ?? userData['phone_number'] ?? '').toString();
        myName = (userData['name'] ?? '').toString();
      } catch (e) {
        debugPrint('Error parsing user_data: $e');
      }
    }
    
    setState(() {
      _myId = myId;
      _myName = myName;
      _myRole = prefs.getString('role') ?? '';
    });
    // Muat pesan setelah user info tersedia
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchMessages();
      // Refresh pesan setiap 15 detik (throttle akan filter di provider)
      _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
        _fetchMessages(force: true);
      });
    });
  }

  Future<void> _fetchMessages({bool force = false}) async {
    if (!mounted) return;
    await ref
        .read(chatProvider)
        .fetchMessages(widget.orderNumber, widget.channel, force: force);
    if (mounted) {
      setState(() {
        _isFirstLoad = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        if (animated) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        } else {
          _scrollController.jumpTo(
            _scrollController.position.maxScrollExtent,
          );
        }
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty || _myId.isEmpty) return;

    _msgController.clear();

    final success = await ref.read(chatProvider).sendMessage(
          widget.orderNumber,
          widget.channel,
          text,
          _myId,
          _myName,
          _myRole,
        );

    if (!success && mounted) {
      NyutjiNotif.showError(context, 'Gagal mengirim pesan. Coba lagi.');
    }
    _scrollToBottom();
  }

  Future<void> _initiateCall() async {
    try {
      final result = await ApiService()
          .initiateCall(widget.orderNumber, widget.channel);
      if (mounted) {
        NyutjiNotif.showInfo(
          context,
          'Memanggil ${widget.partnerName}... Room: ${result['roomId'] ?? ''}',
        );
      }
    } catch (e) {
      if (mounted) {
        NyutjiNotif.showError(context, 'Gagal melakukan panggilan: $e');
      }
    }
  }

  @override
  void dispose() {
    if (ChatScreen.activeOrderNumber == widget.orderNumber &&
        ChatScreen.activeChannel == widget.channel) {
      ChatScreen.activeOrderNumber = null;
      ChatScreen.activeChannel = null;
    }
    _refreshTimer?.cancel();
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return DateFormat('HH:mm').format(dt);
    }
    return DateFormat('d MMM, HH:mm', 'id_ID').format(dt);
  }

  String _channelLabel(String channel) {
    switch (channel) {
      case 'PL_ML':
        return 'Pelanggan ↔ Mitra';
      case 'PL_KL':
        return 'Pelanggan ↔ Kurir';
      case 'ML_KL':
        return 'Mitra ↔ Kurir';
      default:
        return channel;
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(chatProvider);
    final bottom = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: _bgLight,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Channel Label
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            color: _primaryTeal.withValues(alpha: 0.08),
            child: Text(
              'Saluran: ${_channelLabel(widget.channel)} • #${widget.orderNumber}',
              style: GoogleFonts.montserrat(
                fontSize: 11,
                color: _primaryTeal,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Messages Area
          Expanded(
            child: RefreshIndicator(
              color: _primaryTeal,
              onRefresh: () => _fetchMessages(force: true),
              child: provider.isLoading && _isFirstLoad
                  ? _buildSkeletonLoading()
                  : provider.messages.isEmpty
                      ? _buildEmptyState()
                      : _buildMessageList(provider.messages),
            ),
          ),

          // Input Area
          _buildInputArea(provider, bottom),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      surfaceTintColor: Colors.transparent,
      titleSpacing: 0,
      leading: IconButton(
        icon: const Icon(LucideIcons.arrowLeft, size: 20),
        color: const Color(0xFF111111),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _primaryTeal.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            clipBehavior: Clip.antiAlias,
            child: widget.partnerPhoto != null && widget.partnerPhoto!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: widget.partnerPhoto!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(strokeWidth: 2, color: _primaryTeal),
                    ),
                    errorWidget: (context, url, error) => Center(
                      child: Text(
                        widget.partnerName.isNotEmpty ? widget.partnerName[0].toUpperCase() : '?',
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _primaryTeal,
                        ),
                      ),
                    ),
                  )
                : Center(
                    child: Text(
                      widget.partnerName.isNotEmpty
                          ? widget.partnerName[0].toUpperCase()
                          : '?',
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _primaryTeal,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.partnerName,
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF111111),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  widget.partnerRole == 'ML'
                      ? 'Mitra Laundry'
                      : widget.partnerRole == 'KL'
                          ? 'Kurir'
                          : 'Pelanggan',
                  style: GoogleFonts.montserrat(
                    fontSize: 11,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // Tombol Panggilan VoIP
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: GestureDetector(
            onTap: _initiateCall,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _primaryTeal,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                LucideIcons.phone,
                size: 18,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMessageList(List<ChatMessageModel> messages) {
    return ListView.builder(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: messages.length,
      itemBuilder: (ctx, index) {
        final msg = messages[index];
        final isMe = msg.senderId == _myId;

        // Tampilkan label tanggal jika beda hari
        final showDateLabel = index == 0 ||
            messages[index - 1].createdAt.day != msg.createdAt.day;

        return Column(
          children: [
            if (showDateLabel) _buildDateLabel(msg.createdAt),
            _buildMessageBubble(msg, isMe),
          ],
        );
      },
    );
  }

  Widget _buildDateLabel(DateTime dt) {
    final now = DateTime.now();
    String label;
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      label = 'Hari ini';
    } else if (dt.year == now.year &&
        dt.month == now.month &&
        dt.day == now.day - 1) {
      label = 'Kemarin';
    } else {
      label = DateFormat('EEEE, d MMMM y', 'id_ID').format(dt);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: 11,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessageModel msg, bool isMe) {
    const bubbleTeal = Color(0xFF0D9488);
    const bubbleBgMe = bubbleTeal;
    const bubbleBgOther = Colors.white;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            // Avatar lawan
            Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: _primaryTeal.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  msg.senderName.isNotEmpty
                      ? msg.senderName[0].toUpperCase()
                      : '?',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _primaryTeal,
                  ),
                ),
              ),
            ),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.72,
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? bubbleBgMe : bubbleBgOther,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMe ? 18 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMe)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text(
                        msg.senderName,
                        style: GoogleFonts.montserrat(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _primaryTeal,
                        ),
                      ),
                    ),
                  Text(
                    msg.message,
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: isMe ? Colors.white : const Color(0xFF111111),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Text(
                      _formatTime(msg.createdAt),
                      style: GoogleFonts.montserrat(
                        fontSize: 10,
                        color: isMe
                            ? Colors.white.withValues(alpha: 0.7)
                            : Colors.grey[400],
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildInputArea(ChatProvider provider, double bottomPadding) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(16, 10, 16, 10 + bottomPadding),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _msgController,
                maxLines: 4,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF111111),
                ),
                decoration: InputDecoration(
                  hintText: 'Ketik pesan...',
                  hintStyle: GoogleFonts.montserrat(
                    fontSize: 13,
                    color: Colors.grey[400],
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Tombol Kirim
          GestureDetector(
            onTap: provider.isSending ? null : _sendMessage,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: provider.isSending
                    ? Colors.grey[300]
                    : _primaryTeal,
                shape: BoxShape.circle,
                boxShadow: provider.isSending
                    ? []
                    : [
                        BoxShadow(
                          color: _primaryTeal.withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Center(
                child: provider.isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        LucideIcons.sendHorizontal,
                        size: 20,
                        color: Colors.white,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _primaryTeal.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.messageCircle,
              size: 36,
              color: _primaryTeal,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Mulai Percakapan',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF111111),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Belum ada pesan di saluran ini.\nKirim pesan pertama kamu!',
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 13,
              color: Colors.grey[500],
              fontWeight: FontWeight.w400,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonLoading() {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: 6,
      itemBuilder: (ctx, index) {
        final isRight = index.isEven;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            mainAxisAlignment:
                isRight ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!isRight)
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: ShimmerLoading(width: 28, height: 28, borderRadius: 14),
                ),
              ShimmerLoading(
                width: (index % 3 == 0) ? 200 : (index % 3 == 1) ? 150 : 120,
                height: 44,
                borderRadius: 16,
              ),
            ],
          ),
        );
      },
    );
  }
}
