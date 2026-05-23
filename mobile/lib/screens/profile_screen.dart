import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/theme.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _profileData;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);

    // TODO: Load from API
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _profileData = {
        'user': {
          'courier_id': '4821',
          'aggregator': 'yandex_pro',
          'balance': 110,
          'multiplier': 1.2,
          'weekly_contributions': 5,
          'status': 'helper'
        },
        'statistics': {
          'total_contributions': 15,
          'photos_submitted': 8,
          'hints_shared': 4,
          'codes_added': 3,
          'verified_contributions': 12,
          'pending_review': 3
        },
        'weekly_goal': {
          'current_count': 5,
          'target': 10,
          'progress_percent': 50,
          'multiplier_target': 1.5,
          'status_target': 'Эксперт',
          'remaining': 5
        },
        'recent_contributions': [
          {
            'id': 1,
            'address_name': 'ЖК Асанбай Сити, Блок 3',
            'type': 'photo',
            'points': 10,
            'created_at': '2 часа назад'
          },
          {
            'id': 2,
            'address_name': 'ЖК Южные Ворота, корп. 2',
            'type': 'code',
            'points': 15,
            'created_at': '5 часов назад'
          },
        ]
      };
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль'),
        backgroundColor: AppTheme.cardDark,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _handleLogout(authProvider),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadProfile,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBalanceCard(),
              const SizedBox(height: 20),
              _buildWeeklyGoalCard(),
              const SizedBox(height: 20),
              _buildStatisticsCard(),
              const SizedBox(height: 20),
              _buildRecentActivity(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    final user = _profileData!['user'];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryBlue, Color(0xFF2E5CFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Курьер #${user['courier_id']}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.accentYellow,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        user['aggregator'] == 'yandex_pro'
                            ? 'Yandex Pro'
                            : 'Glovo',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.backgroundDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Баланс',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${user['balance']}',
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              const Padding(
                padding: EdgeInsets.only(bottom: 12.0),
                child: Text(
                  'БАЛЛОВ',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
              ),
            ],
          ),
          if (user['multiplier'] > 1.0) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.accentYellow.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.accentYellow,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.bolt,
                    color: AppTheme.accentYellow,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Активен бонус x${user['multiplier']}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    'К стоимости следующих 10 заказов',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWeeklyGoalCard() {
    final goal = _profileData!['weekly_goal'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.emoji_events,
                color: AppTheme.accentYellow,
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
              Text(
                '${goal['current_count']}/${goal['target']} фото',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: goal['progress_percent'] / 100.0,
              minHeight: 12,
              backgroundColor: AppTheme.backgroundDark,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppTheme.successGreen,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'До множителя x${goal['multiplier_target']} осталось ${goal['remaining']} вкладов',
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCard() {
    final stats = _profileData!['statistics'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Статистика',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  icon: Icons.check_circle,
                  value: '${stats['verified_contributions']}',
                  label: 'Подтверждено',
                  color: AppTheme.successGreen,
                ),
              ),
              Expanded(
                child: _StatItem(
                  icon: Icons.pending,
                  value: '${stats['pending_review']}',
                  label: 'На проверке',
                  color: AppTheme.accentYellow,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppTheme.backgroundDark),
          const SizedBox(height: 16),
          _StatRow(
            icon: Icons.photo_camera,
            label: 'Фото добавлено',
            value: '${stats['photos_submitted']}',
          ),
          const SizedBox(height: 12),
          _StatRow(
            icon: Icons.lightbulb,
            label: 'Подсказок создано',
            value: '${stats['hints_shared']}',
          ),
          const SizedBox(height: 12),
          _StatRow(
            icon: Icons.dialpad,
            label: 'Кодов добавлено',
            value: '${stats['codes_added']}',
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    final activity = _profileData!['recent_contributions'] as List;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'История начислений',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...activity.map((item) => _ActivityItem(item: item)).toList(),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () {
            // TODO: Navigate to full history
          },
          child: const Text('Смотреть всю историю →'),
        ),
      ],
    );
  }

  Future<void> _handleLogout(AuthProvider authProvider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: const Text('Выйти из аккаунта?'),
        content: const Text(
          'Вы можете войти снова в любое время',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
            ),
            child: const Text('Выйти'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await authProvider.logout();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
      );
    }
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
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
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryBlue),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final Map<String, dynamic> item;

  const _ActivityItem({required this.item});

  IconData get _iconForType {
    switch (item['type']) {
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

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.successGreen.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _iconForType,
              size: 20,
              color: AppTheme.successGreen,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['address_name'],
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  item['created_at'],
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '+${item['points']}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.successGreen,
            ),
          ),
        ],
      ),
    );
  }
}