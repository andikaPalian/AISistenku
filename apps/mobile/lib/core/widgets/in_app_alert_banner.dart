import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../../models/notification_model.dart';

/// Floating In-App Notification Alert Banner that slides down from top of screen.
class InAppAlertBanner {
  static OverlayEntry? _currentEntry;

  static void show(
    BuildContext context, {
    required String title,
    required String message,
    NotificationType type = NotificationType.stockAlert,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 4),
  }) {
    _currentEntry?.remove();
    _currentEntry = null;

    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    // Store in NotificationRepository history
    NotificationRepository.instance.addNotification(
      AppNotification(
        id: 'notif_',
        title: title,
        message: message,
        type: type,
        timestamp: DateTime.now(),
        isRead: false,
        actionLabel: actionLabel,
      ),
    );

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => _InAppAlertWidget(
        title: title,
        message: message,
        type: type,
        actionLabel: actionLabel,
        onAction: () {
          entry.remove();
          if (_currentEntry == entry) _currentEntry = null;
          onAction?.call();
        },
        onDismiss: () {
          entry.remove();
          if (_currentEntry == entry) _currentEntry = null;
        },
        duration: duration,
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);
  }
}

class _InAppAlertWidget extends StatefulWidget {
  final String title;
  final String message;
  final NotificationType type;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback onDismiss;
  final Duration duration;

  const _InAppAlertWidget({
    required this.title,
    required this.message,
    required this.type,
    this.actionLabel,
    this.onAction,
    required this.onDismiss,
    required this.duration,
  });

  @override
  State<_InAppAlertWidget> createState() => _InAppAlertWidgetState();
}

class _InAppAlertWidgetState extends State<_InAppAlertWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();

    Future.delayed(widget.duration, () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  void _dismiss() async {
    await _controller.reverse();
    if (mounted) {
      widget.onDismiss();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: GestureDetector(
              onVerticalDragUpdate: (details) {
                if (details.primaryDelta != null && details.primaryDelta! < -4) {
                  _dismiss();
                }
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: widget.type.color.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.type.color.withValues(alpha: 0.12),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category Icon
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: widget.type.bgColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        widget.type.icon,
                        size: 22,
                        color: widget.type.color,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Title & Message & Action
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  widget.title,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.darkText,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              GestureDetector(
                                onTap: _dismiss,
                                child: const Icon(
                                  Icons.close_rounded,
                                  size: 18,
                                  color: AppColors.mutedText,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            widget.message,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF475569),
                              height: 1.35,
                            ),
                          ),
                          if (widget.actionLabel != null) ...[
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: widget.onAction ?? _dismiss,
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: widget.type.color,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  widget.actionLabel!,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
