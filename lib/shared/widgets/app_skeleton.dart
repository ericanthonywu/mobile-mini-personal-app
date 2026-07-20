import 'package:flutter/material.dart';
import 'package:expense_tracker/core/theme/app_colors.dart';

/// A shimmering skeleton placeholder that uses an animated gradient to
/// simulate a "loading" effect. Drop-in replacement for any solid grey box.
///
/// Usage:
///   SkeletonBox(width: double.infinity, height: 72, borderRadius: 12)
class SkeletonBox extends StatefulWidget {
  final double? width;
  final double height;
  final double borderRadius;

  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _anim = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          gradient: LinearGradient(
            begin: Alignment(_anim.value - 1, 0),
            end: Alignment(_anim.value + 1, 0),
            colors: const [
              Color(0xFF16213E), // surfaceVariant
              Color(0xFF222244), // slightly lighter
              Color(0xFF16213E),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
      ),
    );
  }
}

/// A full-width skeleton row with an optional circular avatar on the left.
/// Matches the visual footprint of a transaction card.
class SkeletonTransactionTile extends StatelessWidget {
  const SkeletonTransactionTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Avatar circle
          const SkeletonBox(width: 40, height: 40, borderRadius: 20),
          const SizedBox(width: 12),
          // Text lines
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(
                  width: MediaQuery.sizeOf(context).width * 0.45,
                  height: 13,
                  borderRadius: 6,
                ),
                const SizedBox(height: 7),
                SkeletonBox(
                  width: MediaQuery.sizeOf(context).width * 0.28,
                  height: 10,
                  borderRadius: 6,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Amount
          const SkeletonBox(width: 60, height: 13, borderRadius: 6),
        ],
      ),
    );
  }
}

/// Skeleton matching the _CategoryTile shape (icon circle + two text lines).
class SkeletonCategoryTile extends StatelessWidget {
  const SkeletonCategoryTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const SkeletonBox(width: 36, height: 36, borderRadius: 18),
          const SizedBox(width: 14),
          Expanded(
            child: SkeletonBox(
              width: MediaQuery.sizeOf(context).width * 0.4,
              height: 13,
              borderRadius: 6,
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton for the Budget ring card (ring + stat rows).
class SkeletonBudgetRingCard extends StatelessWidget {
  const SkeletonBudgetRingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Ring circle
          const SkeletonBox(width: 100, height: 100, borderRadius: 50),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonBox(width: double.infinity, height: 12, borderRadius: 6),
                const SizedBox(height: 10),
                const SkeletonBox(width: double.infinity, height: 12, borderRadius: 6),
                const SizedBox(height: 10),
                SkeletonBox(
                  width: MediaQuery.sizeOf(context).width * 0.3,
                  height: 12,
                  borderRadius: 6,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton for the 2-column stats grid in the Budget screen.
class SkeletonStatGrid extends StatelessWidget {
  const SkeletonStatGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: const [
            Expanded(child: SkeletonBox(height: 80, borderRadius: 14)),
            SizedBox(width: 12),
            Expanded(child: SkeletonBox(height: 80, borderRadius: 14)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: const [
            Expanded(child: SkeletonBox(height: 80, borderRadius: 14)),
            SizedBox(width: 12),
            Expanded(child: SkeletonBox(height: 80, borderRadius: 14)),
          ],
        ),
      ],
    );
  }
}
