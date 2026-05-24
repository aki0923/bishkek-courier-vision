import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/theme.dart';
import '../widgets/animated_card.dart';
import '../widgets/loading_indicator.dart';

class ContributionHistoryScreen extends StatefulWidget {
  const ContributionHistoryScreen({super.key});

  @override
  State<ContributionHistoryScreen> createState() =>
      _ContributionHistoryScreenState();
}

class _ContributionHistoryScreenState
    extends State<ContributionHistoryScreen> {
  final ApiService _apiService = ApiService();
  final ScrollController _scrollController = ScrollController();

  List<dynamic> _contributions = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _offset = 0;
  final int _limit = 20;

  // Statistics
  int _totalPoints = 0;
  int _totalPhotos = 0;
  int _totalHints = 0;
  int _totalCodes = 0;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadHistory() async {
    try {
      final response = await _apiService.getContributionHistory(
        limit: _limit,
        offset: 0,
      );

      if (response['status'] == 'success' && mounted) {
        final data = response['data'] as List;

        setState(() {
          _contributions = data;
          _isLoading = false;
          _offset = data.length;
          _hasMore = data.length == _limit;
          _calculateStatistics();
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error loading history: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);

    try {
      final response = await _apiService.getContributionHistory(
        limit: _limit,
        offset: _offset,
      );

      if (response['status'] == 'success' && mounted) {
        final data = response['data'] as List;

        setState(() {
          _contributions.addAll(data);
          _offset += data.length;
          _hasMore = data.length == _limit;
          _isLoadingMore = false;
        });
      } else {
        setState(() => _isLoadingMore = false);
      }
    } catch (e) {
      setState(() => _isLoadingMore = false);
    }
  }

  void _calculateStatistics() {
    int points = 0;
    int photos = 0;
    int hints = 0;
    int codes = 0;

    for (var contribution in _contributions) {
      points += (contribution['points'] as int? ?? 0);

      switch (contribution['type']) {
        case 'photo':
          photos++;
          break;
        case 'hint':
          hints++;
          break;
        case 'code':
          codes++;
          break;
      }
    }

    _totalPoints = points;
    _totalPhotos = photos;
    _totalHints = hints;
    _totalCodes = codes;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('История начислений'),
        backgroundColor: AppTheme.cardDark,
      ),
      body: _isLoading
          ? const CustomLoadingIndicator(
        message: 'Загружаем историю...',
      )
          : RefreshIndicator(
        onRefresh: _loadHistory,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Statistics header
            SliverToBoxAdapter(
              child: _buildStatistics(),
            ),

            // Contributions list
            if (_contributions.isEmpty)
              const SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history,
                        size: 64,
                        color: AppTheme.textSecondary,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Нет вкладов',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    if (index == _contributions.length) {
                      return _isLoadingMore
                          ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      )
                          : const SizedBox.shrink();
                    }

                    return FadeInWidget(
                      delay: Duration(milliseconds: index * 50),
                      child: _ContributionItem(
                        contribution: _contributions[index],
                      ),
                    );
                  },
                  childCount: _contributions.length + (_hasMore ? 1 : 0),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatistics() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatColumn(
                value: '$_totalPoints',
                label: 'Всего баллов',
                color: AppTheme.accentYellow,
              ),
              _StatColumn(
                value: '$_totalPhotos',
                label: 'Фотографий',
                color: AppTheme.primaryBlue,
              ),
              _StatColumn(
                value: '${_totalHints + _totalCodes}',
                label: 'Подсказок',
                color: AppTheme.successGreen,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatColumn({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _ContributionItem extends StatelessWidget {
  final Map<String, dynamic> contribution;

  const _ContributionItem({required this.contribution});

  IconData get _icon {
    switch (contribution['type']) {
      case 'photo':
        return Icons.photo_camera;
      case 'hint':
        return Icons.lightbulb;
      case 'code':
        return Icons.dialpad;
      default:
        return Icons.check_circle;
    }
  }

  String get _typeLabel {
    switch (contribution['type']) {
      case 'photo':
        return 'Фото входа';
      case 'hint':
        return 'Подсказка';
      case 'code':
        return 'Код домофона';
      default:
        return 'Вклад';
    }
  }

  Color get _statusColor {
    switch (contribution['status']) {
      case 'verified':
        return AppTheme.successGreen;
      case 'pending':
        return AppTheme.accentYellow;
      case 'rejected':
        return AppTheme.errorRed;
      default:
        return AppTheme.textSecondary;
    }
  }

  String get _statusLabel {
    switch (contribution['status']) {
      case 'verified':
        return 'Подтверждено';
      case 'pending':
        return 'На проверке';
      case 'rejected':
        return 'Отклонено';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: AnimatedCard(
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _statusColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _icon,
                color: _statusColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contribution['address_name'] ?? 'Адрес',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        _typeLabel,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _statusColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _statusLabel,
                          style: TextStyle(
                            fontSize: 10,
                            color: _statusColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Text(
              '+${contribution['points']}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _statusColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

