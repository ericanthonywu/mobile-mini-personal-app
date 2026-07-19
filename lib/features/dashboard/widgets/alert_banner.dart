import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_tracker/core/network/api_client.dart';
import 'package:expense_tracker/core/network/api_endpoints.dart';
import 'package:expense_tracker/core/theme/app_colors.dart';
import 'package:expense_tracker/features/dashboard/models/alert_model.dart';
import 'package:expense_tracker/features/dashboard/providers/alert_provider.dart';

/// Animated amber warning banner shown on the dashboard when there are
/// unresolved email parse-failure alerts.
///
/// Displays:
///   • Alert count + icon in the header
///   • Latest alert message (truncated to 2 lines)
///   • "Tandai Semua Selesai" button to resolve all alerts at once
///
/// Slides in smoothly on first appearance, matching the [AppErrorWidget] pattern.
class AlertBanner extends ConsumerStatefulWidget {
  final List<AlertModel> alerts;

  const AlertBanner({super.key, required this.alerts});

  @override
  ConsumerState<AlertBanner> createState() => _AlertBannerState();
}

class _AlertBannerState extends ConsumerState<AlertBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;
  bool _resolving = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _resolveAll() async {
    if (_resolving) return;
    setState(() => _resolving = true);
    try {
      await ApiClient.instance.post(ApiEndpoints.alertsResolveAll);
      ref.invalidate(alertsProvider);
    } catch (_) {
      // If resolve-all fails, show a snackbar and let user retry
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal menyelesaikan alert. Coba lagi.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _resolving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.alerts.length;
    final latestMessage = widget.alerts.isNotEmpty ? widget.alerts.first.message : '';

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Container(
          margin: const EdgeInsets.only(bottom: 4),
          decoration: BoxDecoration(
            color: AppColors.warning.withOpacity(0.07),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.warning.withOpacity(0.30)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header row ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 12, 0),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.warning,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$count email gagal diproses',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: AppColors.warning,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    // Badge showing count
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        count.toString(),
                        style: const TextStyle(
                          color: AppColors.warning,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Latest alert message ─────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Text(
                  latestMessage,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.45,
                      ),
                ),
              ),

              // ── Action row ───────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: _resolving ? null : _resolveAll,
                      icon: _resolving
                          ? const SizedBox(
                              width: 13,
                              height: 13,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.8,
                                color: AppColors.warning,
                              ),
                            )
                          : const Icon(Icons.check_circle_outline_rounded,
                              size: 15),
                      label: const Text('Tandai Semua Selesai'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.warning,
                        textStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                              color: AppColors.warning.withOpacity(0.4)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
