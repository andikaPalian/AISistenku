import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/ai_chat_model.dart';
import 'ai_business_summary_widget.dart';
import 'ai_action_card.dart';
import 'ai_caption_card.dart';

/// Message bubble for both User and AI responses with rich interactive card rendering.
class AiMessageBubble extends StatelessWidget {
  final AiChatMessage message;
  final VoidCallback? onConfirmAction;

  const AiMessageBubble({
    super.key,
    required this.message,
    this.onConfirmAction,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.sender == ChatSender.user;

    if (isUser) {
      return _buildUserBubble(context);
    } else {
      return _buildAiBubble(context);
    }
  }

  Widget _buildUserBubble(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16, left: 48),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF0F766E),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(6),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(18),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F766E).withOpacity(0.18),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          message.text,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Colors.white,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildAiBubble(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bot Avatar Chip (matches mockup)
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

          // AI Response Card
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                border: Border.all(
                  color: const Color(0xFF99F6E4).withOpacity(0.8),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Text description
                  Text(
                    message.text,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF1E293B),
                      height: 1.45,
                    ),
                  ),

                  // 1. Business Summary Card
                  if (message.type == AiMessageType.businessSummary &&
                      message.extraData != null) ...[
                    AiBusinessSummaryWidget(
                      revenue: message.extraData!['revenue'] ?? 1250000.0,
                      profit: message.extraData!['profit'] ?? 450000.0,
                      bestSeller: message.extraData!['bestSeller'] ??
                          'Iced Aren Latte',
                    ),
                  ],

                  // 2. Action Confirmation Card
                  if (message.type == AiMessageType.actionConfirm &&
                      message.actionPayload != null) ...[
                    AiActionCard(
                      payload: message.actionPayload!,
                      onConfirm: onConfirmAction,
                    ),
                  ],

                  // 3. Marketing & Caption Card
                  if (message.type == AiMessageType.contentCaption &&
                      message.actionPayload != null) ...[
                    AiCaptionCard(
                      payload: message.actionPayload!,
                    ),
                  ],

                  // 4. Stock Alert Card
                  if (message.type == AiMessageType.stockAlert &&
                      message.extraData != null) ...[
                    _buildStockAlertList(context, message.extraData!['lowItems']),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockAlertList(BuildContext context, dynamic items) {
    if (items == null || items is! List || items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7).withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Column(
        children: items.map<Widget>((item) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      size: 14,
                      color: Color(0xFFD97706),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${item['name']}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkText,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Sisa ${item['qty']} ${item['unit']}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFDC2626),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
