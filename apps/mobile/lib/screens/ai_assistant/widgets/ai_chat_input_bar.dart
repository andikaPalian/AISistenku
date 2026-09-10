import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';

/// Bottom chat input bar with textfield, voice mic simulation, and submit button.
class AiChatInputBar extends StatefulWidget {
  final ValueChanged<String> onSendMessage;
  final bool isTyping;

  const AiChatInputBar({
    super.key,
    required this.onSendMessage,
    this.isTyping = false,
  });

  @override
  State<AiChatInputBar> createState() => _AiChatInputBarState();
}

class _AiChatInputBarState extends State<AiChatInputBar> {
  final TextEditingController _controller = TextEditingController();
  bool _isListening = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty || widget.isTyping) return;

    widget.onSendMessage(text);
    _controller.clear();
  }

  void _toggleVoiceListening() {
    setState(() {
      _isListening = !_isListening;
    });

    if (_isListening) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.mic_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Mendengarkan suara: "Beli susu UHT 5 liter seharga 95rb"...'),
            ],
          ),
          backgroundColor: const Color(0xFF0F766E),
          duration: const Duration(seconds: 2),
        ),
      );

      // Simulate speech to text transcription after 1.8s
      Future.delayed(const Duration(milliseconds: 1800), () {
        if (mounted && _isListening) {
          setState(() {
            _controller.text = 'Saya baru beli susu UHT 5L seharga 95rb';
            _isListening = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        10,
        16,
        MediaQuery.of(context).viewInsets.bottom > 0 ? 12 : 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(color: AppColors.lightTealBorder, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Voice Input Mic Button
            GestureDetector(
              onTap: _toggleVoiceListening,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _isListening
                      ? AppColors.dangerBg
                      : AppColors.tealBackgrounds,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _isListening
                        ? AppColors.destructive
                        : AppColors.lightTealBorder,
                    width: 1.2,
                  ),
                ),
                child: Icon(
                  _isListening
                      ? Icons.mic_rounded
                      : Icons.mic_none_rounded,
                  color: _isListening
                      ? AppColors.destructive
                      : AppColors.primaryTeal,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Rounded Input Field
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.tealBackgrounds,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.lightTealBorder,
                    width: 1.2,
                  ),
                ),
                child: TextField(
                  controller: _controller,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _handleSend(),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.darkText,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Tanya apa saja ke AIsistenku...',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.mutedText,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Send Button (Brand Primary Teal Circle)
            GestureDetector(
              onTap: _handleSend,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryTeal,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryTeal.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: widget.isTyping
                    ? const Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
