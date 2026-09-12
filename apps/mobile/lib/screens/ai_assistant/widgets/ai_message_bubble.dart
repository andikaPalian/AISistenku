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
          color: const Color(0xFF111111), // Solid Black Pill
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(4),
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          message.text,
          style: GoogleFonts.inter(
            fontSize: 13.5,
            fontWeight: FontWeight.w400,
            color: Colors.white,
            height: 1.45,
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
          // Official AIsistenku Avatar Logo
          Container(
            width: 34,
            height: 34,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: const Color(0xFF111111), // Solid black circle
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

          // AI Response Card
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white, // Crisp white card
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Text description
                  Text(
                    message.text,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: AppColors.darkText,
                      height: 1.45,
                    ),
                  ),

                  // 1. Business Summary Card
                  if (message.type == AiMessageType.businessSummary &&
                      message.extraData != null) ...[
                    AiBusinessSummaryWidget(
                      revenue: (message.extraData!['revenue'] as num?) ?? 0,
                      profit: (message.extraData!['profit'] as num?) ??
                          (((message.extraData!['revenue'] as num?) ?? 0) -
                              ((message.extraData!['expense'] as num?) ?? 0)),
                      bestSeller: (message.extraData!['bestSeller'] ??
                              'Iced Aren Latte')
                          .toString(),
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
        color: AppColors.warningBg, // Use pure warning color
        borderRadius: BorderRadius.circular(12),
        // No border
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
                      size: 15,
                      color: AppColors.warningOrange,
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.dangerBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Sisa ${item['qty']} ${item['unit']}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.dangerText,
                    ),
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
