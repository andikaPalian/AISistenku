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
          backgroundColor: AppColors.pageBackground,
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
                  width: 30,
                  height: 30,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.tealBackgrounds,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.lightTealBorder, width: 1.2),
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
                    Text(
                      'AIsistenku',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkText,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.successGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Copilot Aktif',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: AppColors.mutedText,
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
              child: Divider(height: 1, color: AppColors.lightTealBorder),
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
              // ── Scrollable Chat Feed ──────────────────────────────
              Expanded(
                child: ListView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  children: [
                    // 1. Welcome Greeting Hero
                    const AiWelcomeHero(userName: 'Budi'),
                    const SizedBox(height: 16),

                    // 2. Quick Action Prompt Chips
                    AiQuickPrompts(
                      onSelectPrompt: _handleSendMessage,
                    ),
                    const SizedBox(height: 24),

                    // 3. Chat Messages History
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
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Aksi berhasil! Stok & Keuangan telah sinkron.',
                                        ),
                                      ],
                                    ),
                                    backgroundColor: AppColors.primaryTeal,
                                    duration: Duration(seconds: 3),
                                  ),
                                );
                              }
                            : null,
                      );
                    }),

                    // 4. Typing / Thinking Indicator
                    if (isTyping) ...[
                      _buildTypingIndicator(),
                    ],
                  ],
                ),
              ),

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Mulai Sesi Baru?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        content: Text(
          'Riwayat percakapan sebelumnya akan direset. Anda dapat memulai konsultasi baru dengan AIsistenku.',
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.mutedText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Batal',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.mutedText),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryTeal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              repo.clearChat();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Percakapan telah direset ke sesi baru'),
                  backgroundColor: AppColors.primaryTeal,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Reset Chat'),
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
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.lightTealBorder,
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryTeal.withValues(alpha: 0.08),
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
              border: Border.all(
                color: AppColors.lightTealBorder,
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'AIsistenku sedang menganalisis...',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: AppColors.mutedText,
                  ),
                ),
                const SizedBox(width: 8),
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.primaryTeal),
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
