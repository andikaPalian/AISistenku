import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../models/ai_chat_model.dart';
import 'widgets/ai_welcome_hero.dart';
import 'widgets/ai_quick_prompts.dart';
import 'widgets/ai_message_bubble.dart';
import 'widgets/ai_chat_input_bar.dart';

/// Main AI Assistant Screen (Tab 3 - Center FAB).
///
/// Functions as an Intelligent Copilot & Creative Marketing Agent for UMKM owners.
/// Handles natural language business analysis, purchase & stock detection,
/// and creative social media caption generation.
class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    AiChatRepository.instance.fetchMessagesFromBackend();
  }

  void _scrollToBottom() {
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

  void _handleSendMessage(String text) {
    AiChatRepository.instance.sendMessage(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AiChatRepository.instance,
      builder: (context, _) {
        final repo = AiChatRepository.instance;
        final messages = repo.messages;
        final isTyping = repo.isTyping;

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC), // Slate 50 background to make white cards pop
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.darkText,
              ),
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
            ),
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  padding: const EdgeInsets.all(5),
                  decoration: const BoxDecoration(
                    color: Color(0xFF111111),
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset(
                    'assets/icons/logoAisitenku.png',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF111111),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            'AI',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF22C55E), // Vibrant Green
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Sistenku',
                          style: GoogleFonts.poppins(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFF22C55E),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Copilot Bisnis Aktif',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            centerTitle: true,
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(1),
              child: Divider(height: 1, color: Color(0xFFE2E8F0)),
            ),
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.refresh_rounded,
                  color: AppColors.mutedText,
                  size: 22,
                ),
                tooltip: 'Reset Chat',
                onPressed: () => _showResetDialog(context, repo),
              ),
            ],
          ),
          body: Column(
            children: [
              // ── Scrollable Chat Feed or Welcome Empty State ───────
              Expanded(
                child: messages.isEmpty
                    ? SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                        child: AiWelcomeHero(
                          userName: 'Budi',
                          onSelectPrompt: _handleSendMessage,
                        ),
                      )
                    : ListView(
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                        children: [
                          // Subtle Session Badge
                          Center(
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Hari Ini',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ),

                          // Chat Messages History
                          ...messages.map((msg) {
                            return AiMessageBubble(
                              message: msg,
                              onConfirmAction: msg.actionPayload != null
                                  ? () {
                                      repo.confirmAction(
                                        msg.actionPayload!.actionId,
                                      );
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Row(
                                            children: [
                                              Icon(
                                                Icons.check_circle_rounded,
                                                color: Color(0xFF22C55E),
                                                size: 18,
                                              ),
                                              SizedBox(width: 8),
                                              Text(
                                                'Aksi berhasil! Stok & Keuangan telah sinkron.',
                                              ),
                                            ],
                                          ),
                                          backgroundColor: Color(0xFF111111),
                                          duration: Duration(seconds: 3),
                                        ),
                                      );
                                    }
                                  : null,
                            );
                          }),

                          // Typing / Thinking Indicator
                          if (isTyping) ...[
                            _buildTypingIndicator(),
                          ],
                        ],
                      ),
              ),

              // ── Quick Action Suggestion Chips (Docked right above input bar) ──
              if (messages.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AiQuickPrompts(
                    onSelectPrompt: _handleSendMessage,
                  ),
                ),
              ],

              // ── Bottom Chat Input Bar ──────────────────────────────
              AiChatInputBar(
                onSendMessage: _handleSendMessage,
                isTyping: isTyping,
              ),
            ],
          ),
        );
      },
    );
  }

  void _showResetDialog(BuildContext context, AiChatRepository repo) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Mulai Sesi Baru?',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 17,
            color: AppColors.darkText,
          ),
        ),
        content: Text(
          'Riwayat percakapan sebelumnya akan direset. Anda dapat memulai konsultasi baru dengan AIsistenku.',
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.mutedText),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Batal',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: AppColors.mutedText,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF111111), // Solid Black Pill
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              repo.clearChat();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Percakapan telah direset ke sesi baru'),
                  backgroundColor: Color(0xFF111111),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: Text(
              'Reset Chat',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          // Official Logo in typing indicator
          Container(
            width: 36,
            height: 36,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: const Color(0xFF111111), // Solid black background
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Image.asset(
              'assets/icons/logoAisitenku.png',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'AIsisten sedang menganalisis data...',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(width: 8),
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFF22C55E)), // Vibrant Green spinner
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
