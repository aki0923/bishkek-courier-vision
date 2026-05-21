import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/theme.dart';
import 'map_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _courierIdController = TextEditingController();
  String _selectedAggregator = 'yandex_pro';
  bool _isLoading = false;

  @override
  void dispose() {
    _courierIdController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_courierIdController.text.isEmpty) {
      _showError('Введите ID курьера');
      return;
    }

    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.login(_courierIdController.text, _selectedAggregator);

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const MapScreen()));
    } else {
      _showError('Ошибка входа. Проверьте ID курьера');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: AppTheme.errorRed));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.location_on, size: 64, color: Colors.white),
              ),

              const SizedBox(height: 32),

              // Title
              Text(
                'Bishkek Courier Vision',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              // Subtitle
              Text(
                'Навигация последних 100 метров',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 48),

              // Aggregator Selection
              Text('Выберите агрегатор', style: Theme.of(context).textTheme.bodyLarge),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _AggregatorButton(
                      label: 'Yandex Pro',
                      icon: Icons.local_taxi,
                      isSelected: _selectedAggregator == 'yandex_pro',
                      color: AppTheme.accentYellow,
                      onTap: () {
                        setState(() => _selectedAggregator = 'yandex_pro');
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _AggregatorButton(
                      label: 'Glovo',
                      icon: Icons.delivery_dining,
                      isSelected: _selectedAggregator == 'glovo',
                      color: AppTheme.cardDark,
                      onTap: () {
                        setState(() => _selectedAggregator = 'glovo');
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Courier ID Input
              TextField(
                controller: _courierIdController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'ID курьера',
                  hintText: 'Введите ваш ID',
                  prefixIcon: Icon(Icons.badge, color: AppTheme.primaryBlue),
                ),
              ),

              const SizedBox(height: 32),

              // Login Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Войти'),
                ),
              ),

              const SizedBox(height: 16),

              // Info Text
              Text(
                'Доступ только для верифицированных курьеров',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AggregatorButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _AggregatorButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isSelected ? color : AppTheme.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? color : Colors.transparent, width: 2),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: isSelected ? Colors.white : AppTheme.textSecondary),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
