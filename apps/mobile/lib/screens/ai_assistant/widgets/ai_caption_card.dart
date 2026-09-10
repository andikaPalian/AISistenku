import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/ai_chat_model.dart';

/// Interactive card for marketing ideas, social media captions, and copywriting with copy-to-clipboard.
class AiCaptionCard extends StatelessWidget {
  final AiActionPayload payload;

  const AiCaptionCard({
    super.key,
    required this.payload,
  });

  void _copyCaption(BuildContext context) {
    final fullText =
        '${payload.captionText ?? ''}\n\n${payload.hashtags?.join(' ') ?? ''}';
    Clipboard.setData(ClipboardData(text: fullText));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Caption berhasil disalin ke Clipboard!'),
          ],
        ),
        backgroundColor: AppColors.primaryTeal,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.lightTealBorder,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Platform Badge & Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryTeal.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt_outlined,
                      color: AppColors.primaryTeal,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    payload.captionTitle ?? 'Ide Konten & Promo',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkText,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.tealBackgrounds,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.lightTealBorder),
                ),
                child: Text(
                  payload.platform ?? 'Instagram',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryTeal,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Caption Content Container
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.tealBackgrounds,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.lightTealBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payload.captionText ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: AppColors.darkText,
                    height: 1.5,
                  ),
                ),
                if (payload.hashtags != null &&
                    payload.hashtags!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: payload.hashtags!.map((tag) {
                      return Text(
                        tag,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryTeal,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Action: 1-Click Copy Button
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton.icon(
              onPressed: () => _copyCaption(context),
              icon: const Icon(
                Icons.copy_rounded,
                size: 16,
                color: Colors.white,
              ),
              label: Text(
                'Salin Caption',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryTeal,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
