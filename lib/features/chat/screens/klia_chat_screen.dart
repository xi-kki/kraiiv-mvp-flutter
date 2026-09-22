import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../../core/services/data_service.dart';
import '../../../core/services/klia_chat_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/prototype_widgets.dart';

/// Chat with Klia matching the prototype:
/// "Ask Klia about nutrition..." with warm, keyword-based answers.
class KliaChatScreen extends StatefulWidget {
  const KliaChatScreen({super.key});

  @override
  State<KliaChatScreen> createState() => _KliaChatScreenState();
}

class _KliaChatScreenState extends State<KliaChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_Message> _messages = [];
  bool _awaiting = false;

  @override
  void initState() {
    super.initState();
    _messages.add(_Message(
      content: 'Hey! I\'m Klia, your nutrition coach. Ask me anything about food, health goals, or local ingredients!',
      fromKlia: true,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _awaiting) return;

    _controller.clear();
    setState(() {
      _messages.add(_Message(content: text, fromKlia: false));
      _awaiting = true;
    });
    _scrollToBottom();

    final reply = await KliaChatService.reply(text, _recentContext());
    if (!mounted) return;

    setState(() {
      _messages.add(_Message(content: reply, fromKlia: true));
      _awaiting = false;
    });
    _scrollToBottom();
  }

  List<Map<String, String>> _recentContext() {
    final relevant = _messages.skip(_messages.length > 8 ? _messages.length - 8 : 0).toList();
    return relevant.map((m) => {'role': m.fromKlia ? 'assistant' : 'user', 'content': m.content}).toList();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  String _replyTo(String question) {
    return KliaChatService.replySync(question);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: context.canPop()
            ? IconButton(
                onPressed: () => context.pop(),
                icon: Icon(LucideIcons.arrowLeft, color: AppTheme.foreground),
              )
            : null,
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primary, AppTheme.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.leaf, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Klia',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.foreground,
                  ),
                ),
                Text(
                  'Your AI nutrition coach',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: AppTheme.mutedForeground,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length + (_awaiting ? 1 : 0),
                itemBuilder: (context, index) {
                  if (_awaiting && index == _messages.length) {
                    return _buildTypingBubble();
                  }
                  return _buildBubble(_messages[index]);
                },
              ),
            ),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildBubble(_Message message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: message.fromKlia
            ? MainAxisAlignment.start
            : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (message.fromKlia) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primary, AppTheme.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.leaf, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.fromKlia ? AppTheme.card : AppTheme.primary,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(message.fromKlia ? 4 : AppTheme.radiusXl),
                  topRight: Radius.circular(message.fromKlia ? AppTheme.radiusXl : 4),
                  bottomLeft: Radius.circular(AppTheme.radiusXl),
                  bottomRight: Radius.circular(AppTheme.radiusXl),
                ),
                border: message.fromKlia
                    ? Border.all(color: AppTheme.border)
                    : null,
              ),
              child: Text(
                message.content,
                style: GoogleFonts.inter(
                  fontSize: 14.5,
                  height: 1.55,
                  color: message.fromKlia ? AppTheme.foreground : Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          if (!message.fromKlia) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.gold,
              child: Text(
                DataService.userName.isNotEmpty
                    ? DataService.userName.trim()[0].toUpperCase()
                    : 'U',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingBubble() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primary, AppTheme.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.leaf, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.card,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(AppTheme.radiusXl),
                bottomLeft: Radius.circular(AppTheme.radiusXl),
                bottomRight: Radius.circular(AppTheme.radiusXl),
              ),
              border: Border.all(color: AppTheme.border),
            ),
            child: _TypingIndicator(),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: AppTheme.background,
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.card,
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  border: Border.all(color: AppTheme.border),
                ),
                child: TextField(
                  controller: _controller,
                  onSubmitted: (_) => _send(),
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: AppTheme.foreground,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Ask Klia about nutrition...',
                    hintStyle: GoogleFonts.inter(
                      color: AppTheme.mutedForeground,
                      fontSize: 15,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    prefixIcon: Icon(LucideIcons.messageCircle, color: AppTheme.mutedForeground, size: 20),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primary, AppTheme.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: _awaiting ? null : _send,
                icon: const Icon(LucideIcons.send, color: Colors.white, size: 20),
                tooltip: 'Send',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.15;
            final value = (_controller.value - delay) % 1.0;
            final opacity = (value * 2).clamp(0.0, 1.0);
            final scale = (value * 2).clamp(0.0, 1.0);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Opacity(
                opacity: opacity,
                child: Transform.scale(
                  scale: 0.5 + scale * 0.5,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class _Message {
  final String content;
  final bool fromKlia;

  _Message({required this.content, required this.fromKlia});
}