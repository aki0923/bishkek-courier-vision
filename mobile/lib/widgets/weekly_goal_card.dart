import 'package:flutter/material.dart';
import '../utils/theme.dart';

class WeeklyGoalCard extends StatefulWidget {
  final int currentCount;
  final int target;
  final double progressPercent;
  final double multiplierTarget;
  final String statusTarget;
  final int remaining;
  final bool allAchieved;

  const WeeklyGoalCard({
    super.key,
    required this.currentCount,
    required this.target,
    required this.progressPercent,
    required this.multiplierTarget,
    required this.statusTarget,
    required this.remaining,
    required this.allAchieved,
  });

  @override
  State<WeeklyGoalCard> createState() => _WeeklyGoalCardState();
}

class _WeeklyGoalCardState extends State<WeeklyGoalCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: widget.progressPercent / 100.0,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(WeeklyGoalCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progressPercent != widget.progressPercent) {
      _progressAnimation = Tween<double>(
        begin: _progressAnimation.value,
        end: widget.progressPercent / 100.0,
      ).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: widget.allAchieved
            ? Border.all(color: AppTheme.successGreen, width: 2)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                widget.allAchieved
                    ? Icons.emoji_events
                    : Icons.track_changes,
                color: widget.allAchieved
                    ? AppTheme.successGreen
                    : AppTheme.accentYellow,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'Цель недели',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${widget.currentCount}/${widget.target}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Animated progress bar
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, _) {
              return Stack(
                children: [
                  Container(
                    height: 14,
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundDark,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: _progressAnimation.value,
                    child: Container(
                      height: 14,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: widget.allAchieved
                              ? [AppTheme.successGreen, AppTheme.successGreen]
                              : [AppTheme.primaryBlue, AppTheme.accentYellow],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: (widget.allAchieved
                                ? AppTheme.successGreen
                                : AppTheme.primaryBlue)
                                .withOpacity(0.4),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 16),

          // Status message
          if (widget.allAchieved)
            Row(
              children: [
                const Icon(
                  Icons.celebration,
                  color: AppTheme.successGreen,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Все цели выполнены! Множитель x${widget.multiplierTarget} активен',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.successGreen,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: AppTheme.textSecondary,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'До множителя x${widget.multiplierTarget} осталось ${widget.remaining} вкладов',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),

          const SizedBox(height: 12),

          // Next status
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: AppTheme.accentYellow.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.star,
                  color: AppTheme.accentYellow,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Следующий статус: ${widget.statusTarget}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.accentYellow,
                    fontWeight: FontWeight.w600,
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

