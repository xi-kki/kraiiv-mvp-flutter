import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../../../core/services/data_service.dart';
import '../../../core/theme/app_theme.dart';

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

  @override
  void initState() {
    super.initState();
    _messages.addAll([
      const _Message(
        text:
            'Hi, I\'m Klia. I\'ll help you make the path to achieving your '
            'health goals clear.',
        fromKlia: true,
      ),
      const _Message(
        text:
            'You can ask me about nutrition, local foods, or how to maintain '
            'mindful eating habits.',
        fromKlia: true,
      ),
    ]);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(_Message(text: text, fromKlia: false));
      _messages.add(_Message(text: _replyTo(text), fromKlia: true));
      _controller.clear();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _replyTo(String question) {
    final q = question.toLowerCase();
    final name = DataService.userName.split(' ').first;

    if (q.contains('protein')) {
      return 'Great question, $name! Protein can come from legumes and animal '
          'sources — beans, egusi, moi moi, eggs, fish and chicken. Aim for a '
          'palm-sized portion at most meals.';
    }
    if (q.contains('calorie') || q.contains('calories') || q.contains('weight')) {
      return 'For steady energy, focus on balanced plates: carbs, protein and '
          'vegetables together. Scan your meals and I\'ll show you the '
          'calories plus a healthier swap.';
    }
    if (q.contains('fiber') || q.contains('fibre') || q.contains('digest')) {
      return 'Fibre is your friend! Beans, vegetables, fruit and wholegrains '
          'like ofada rice keep you full and your digestion happy.';
    }
    if (q.contains('water') || q.contains('hydrat') || q.contains('drink')) {
      return 'Hydration matters as much as food. Start each day with a glass '
          'of water, and sip through the day — zobo counts too, just watch '
          'the sugar!';
    }
    if (q.contains('local') || q.contains('seasonal') || q.contains('market')) {
      return 'Eating local is a win-win: fresher food, lower cost and support '
          'for farmers near you. Check the Local & Seasonal Ideas on your '
          'home screen!';
    }
    if (q.contains('mindful') || q.contains('distraction')) {
      return 'Mindful eating is simple: no phone, small bites, and notice the '
          'taste. One distraction-free meal a day is a great place to start.';
    }
    if (q.contains('sugar') || q.contains('sweet') || q.contains('snack')) {
      return 'Craving something sweet? Try fruit or a small handful of '
          'groundnuts. If it\'s a real treat moment, enjoy it fully and '
          'mindfully — no guilt.';
    }
    if (q.contains('vegetable') || q.contains('greens')) {
      return 'Vegetables are where the vitamins live! Try ugwu, ewedu, okra '
          'or a fresh salad — and aim for colour on every plate.';
    }
    if (q.contains('streak') || q.contains('ktc') || q.contains('token')) {
      return 'Your streak keeps your KTC growing! Log meals and complete '
          'daily goals to earn more tokens — rewards are waiting in the '
          'Rewards Hub.';
    }
    if (q.contains('hello') || q.contains('hi ') || q == 'hi' || q.contains('hey')) {
      return 'Hello $name! Lovely to hear from you. Ask me about nutrition, '
          'local foods, or mindful eating — I\'m here for you.';
    }
    return 'That\'s a great question, $name! I can help with nutrition, local '
        'foods and mindful eating habits — try asking me about protein, '
        'calories, or eating seasonally.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(LucideIcons.arrowLeft),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: AppTheme.primaryGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.leaf,
                  color: Colors.white, size: 17),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Klia', style: TextStyle(fontSize: 16)),
                Text(
                  'Your AI nutrition coach',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: AppTheme.textMuted,
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
                itemCount: _messages.length,
                itemBuilder: (context, index) =>
                    _buildBubble(_messages[index]),
              ),
            ),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildBubble(_Message message) {
    if (message.fromKlia) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          constraints: const BoxConstraints(maxWidth: 320),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(18),
            ),
            border: Border.all(color: AppTheme.border),
          ),
          child: Text(
            message.text,
            style: const TextStyle(
              fontSize: 14.5,
              height: 1.5,
              color: AppTheme.textDark,
            ),
          ),
        ),
      );
    }
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: const BoxDecoration(
          color: AppTheme.primaryGreen,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(4),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(18),
          ),
        ),
        child: Text(
          message.text,
          style: const TextStyle(
            fontSize: 14.5,
            height: 1.5,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        12,
        10,
        12,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              onSubmitted: (_) => _send(),
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Ask Klia about nutrition...',
                filled: true,
                fillColor: AppTheme.surface,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 10),
          IconButton.filled(
            onPressed: _send,
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(LucideIcons.send, size: 18),
          ),
        ],
      ),
    );
  }
}

class _Message {
  final String text;
  final bool fromKlia;

  const _Message({required this.text, required this.fromKlia});
}
