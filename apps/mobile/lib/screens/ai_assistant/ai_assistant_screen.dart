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
                // If nested or back requested
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
            ),
            title: Text(
              'AIsistenku',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.darkText,
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.cleaning_services_outlined,
                  color: Color(0xFF64748B),
                  size: 20,
                ),
                tooltip: 'Reset Chat',
                onPressed: () {
                  repo.clearChat();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Percakapan telah direset'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
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
                                          Icons.check_circle,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Aksi Berhasil! Stok & Keuangan telah diperbarui 🎉',
                                        ),
                                      ],
                                    ),
                                    backgroundColor: AppColors.successGreen,
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

  Widget _buildTypingIndicator() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFFFFEDD5),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.storefront_rounded,
              color: Color(0xFFC2410C),
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF99F6E4),
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'AIsisten sedang berpikir...',
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
