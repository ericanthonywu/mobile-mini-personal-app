import 'package:flutter/material.dart';
import 'package:expense_tracker/core/network/api_client.dart';
import 'package:expense_tracker/core/theme/app_colors.dart';

/// A polished, reusable error widget that shows contextual icon + message
/// based on the [ApiErrorType]. Always shows a retry button.
///
/// Usage:
/// ```dart
/// error: (e, _) => AppErrorWidget(
///   error: e,
///   onRetry: () => ref.invalidate(someProvider),
/// ),
/// ```
class AppErrorWidget extends StatefulWidget {
  /// The raw error object — we'll extract type + message internally.
  final Object error;
  final VoidCallback onRetry;

  /// Optional label override; if null we derive from the error.
  final String? label;

  const AppErrorWidget({
    super.key,
    required this.error,
    required this.onRetry,
    this.label,
  });

  @override
  State<AppErrorWidget> createState() => _AppErrorWidgetState();
}

class _AppErrorWidgetState extends State<AppErrorWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final apiError = parseApiError(widget.error);
    final config = _ErrorConfig.from(apiError.type);

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: config.borderColor.withValues(alpha: 0.35)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon with coloured background pill
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: config.iconColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(config.icon, size: 26, color: config.iconColor),
              ),
              const SizedBox(height: 14),

              // Title
              Text(
                config.title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),

              // Message
              Text(
                widget.label ?? apiError.message,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Retry button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: widget.onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Coba Lagi'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: config.iconColor,
                    side: BorderSide(color: config.borderColor.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Inline config mapping error type → icon / colours / title
// ---------------------------------------------------------------------------

class _ErrorConfig {
  final IconData icon;
  final Color iconColor;
  final Color borderColor;
  final String title;

  const _ErrorConfig({
    required this.icon,
    required this.iconColor,
    required this.borderColor,
    required this.title,
  });

  factory _ErrorConfig.from(ApiErrorType type) {
    switch (type) {
      case ApiErrorType.connection:
        return const _ErrorConfig(
          icon: Icons.wifi_off_rounded,
          iconColor: AppColors.warning,
          borderColor: AppColors.warning,
          title: 'Tidak Ada Koneksi',
        );
      case ApiErrorType.timeout:
        return const _ErrorConfig(
          icon: Icons.timer_off_rounded,
          iconColor: AppColors.secondary,
          borderColor: AppColors.secondary,
          title: 'Koneksi Timeout',
        );
      case ApiErrorType.serverError:
        return const _ErrorConfig(
          icon: Icons.dns_rounded,
          iconColor: AppColors.error,
          borderColor: AppColors.error,
          title: 'Server Bermasalah',
        );
      case ApiErrorType.clientError:
        return const _ErrorConfig(
          icon: Icons.block_rounded,
          iconColor: AppColors.warning,
          borderColor: AppColors.warning,
          title: 'Permintaan Gagal',
        );
      case ApiErrorType.unknown:
        return const _ErrorConfig(
          icon: Icons.error_outline_rounded,
          iconColor: AppColors.error,
          borderColor: AppColors.error,
          title: 'Terjadi Kesalahan',
        );
    }
  }
}
