import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/address_model.dart';
import '../utils/theme.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';


class ContributeScreen extends StatefulWidget {
  final AddressModel address;

  const ContributeScreen({
    super.key,
    required this.address,
  });

  @override
  State<ContributeScreen> createState() => _ContributeScreenState();
}

class _ContributeScreenState extends State<ContributeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _hintController = TextEditingController();
  final _codeController = TextEditingController();
  final _gateNumberController = TextEditingController();

  String _contributionType = 'photo'; // photo, hint, code
  File? _selectedImage;
  int? _selectedEntrance;
  bool _isSubmitting = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _hintController.dispose();
    _codeController.dispose();
    _gateNumberController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      _showError('Ошибка при выборе фото: $e');
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: AppTheme.primaryBlue),
                  title: const Text('Сделать фото'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library, color: AppTheme.primaryBlue),
                  title: const Text('Выбрать из галереи'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // В методе _submitContribution заменить симуляцию на реальный API вызов:

  Future<void> _submitContribution() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Type-specific validation
    if (_contributionType == 'photo' && _selectedImage == null) {
      _showError('Пожалуйста, добавьте фото входа');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final apiService = ApiService();

      // Prepare photo data
      String? photoData;
      if (_contributionType == 'photo' && _selectedImage != null) {
        final bytes = await _selectedImage!.readAsBytes();
        photoData = base64Encode(bytes);
      }

      // Submit contribution
      final response = await apiService.submitContribution(
        addressId: widget.address.id,
        type: _contributionType,
        photoData: photoData,
        hintText: _contributionType == 'hint' ? _hintController.text : null,
        code: _contributionType == 'code' ? _codeController.text : null,
        entranceNumber: _selectedEntrance,
        gateNumber: _contributionType == 'code' ? _gateNumberController.text : null,
      );

      setState(() => _isSubmitting = false);

      if (mounted) {
        if (response['status'] == 'success') {
          // Update user balance
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          authProvider.updateBalance(response['data']['new_balance']);
          authProvider.incrementWeeklyContributions();

          _showSuccessDialog(response['data']);
        } else if (response['status'] == 'rejected') {
          _showRejectionDialog(response);
        } else {
          _showError(response['message'] ?? 'Ошибка при отправке');
        }
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      _showError('Ошибка: $e');
    }
  }



  void _showSuccessDialog(Map<String, dynamic> data) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.successGreen.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                size: 64,
                color: AppTheme.successGreen,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Вклад подтвержден!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'ИИ подтвердил достоверность ${_contributionType == 'photo' ? 'фото' : 'данных'}',
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.accentYellow.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.stars,
                    color: AppTheme.accentYellow,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '+${data['points_earned']} баллов',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.accentYellow,
                    ),
                  ),
                ],
              ),
            ),
            if (data['ai_confidence'] != null) ...[
              const SizedBox(height: 12),
              Text(
                'Уверенность AI: ${(data['ai_confidence'] * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Close contribute screen
                },
                child: const Text('Отлично!'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRejectionDialog(Map<String, dynamic> response) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: const Row(
          children: [
            Icon(Icons.warning, color: AppTheme.errorRed),
            SizedBox(width: 8),
            Text('Вклад отклонен'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              response['message'] ?? 'ИИ не смог подтвердить данные',
              style: const TextStyle(fontSize: 16),
            ),
            if (response['details'] != null) ...[
              const SizedBox(height: 12),
              Text(
                response['details'],
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Понятно'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Очищаем форму, чтобы попробовать снова
              setState(() {
                _selectedImage = null;
              });
            },
            child: const Text('Попробовать снова'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorRed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Помочь коллегам'),
        backgroundColor: AppTheme.cardDark,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Address Info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: AppTheme.primaryBlue,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.address.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.address.address,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Contribution Type Selector
              const Text(
                'Что хотите добавить?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _ContributionTypeCard(
                      icon: Icons.photo_camera,
                      label: 'Фото входа',
                      points: '+10',
                      isSelected: _contributionType == 'photo',
                      onTap: () => setState(() => _contributionType = 'photo'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ContributionTypeCard(
                      icon: Icons.lightbulb,
                      label: 'Подсказка',
                      points: '+5',
                      isSelected: _contributionType == 'hint',
                      onTap: () => setState(() => _contributionType = 'hint'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ContributionTypeCard(
                      icon: Icons.dialpad,
                      label: 'Код',
                      points: '+15',
                      isSelected: _contributionType == 'code',
                      onTap: () => setState(() => _contributionType = 'code'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Dynamic Form based on type
              if (_contributionType == 'photo') _buildPhotoForm(),
              if (_contributionType == 'hint') _buildHintForm(),
              if (_contributionType == 'code') _buildCodeForm(),

              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitContribution,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Text('Отправить на проверку'),
                ),
              ),

              const SizedBox(height: 16),

              // Info Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primaryBlue.withOpacity(0.3),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppTheme.primaryBlue,
                      size: 20,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'За каждый вклад вы получите +10 баллов после проверки ИИ',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
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

  Widget _buildPhotoForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Фото входа / подъезда',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _showImageSourceDialog,
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.primaryBlue.withOpacity(0.3),
                width: 2,
                style: BorderStyle.solid,
              ),
            ),
            child: _selectedImage != null
                ? ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.file(
                _selectedImage!,
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            )
                : const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_a_photo,
                  size: 48,
                  color: AppTheme.primaryBlue,
                ),
                SizedBox(height: 12),
                Text(
                  'Сделать фото',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.primaryBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Сфотографируйте вход или ориентир',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<int>(
          decoration: const InputDecoration(
            labelText: 'Номер подъезда (опционально)',
            prefixIcon: Icon(Icons.door_front_door),
          ),
          value: _selectedEntrance,
          dropdownColor: AppTheme.cardDark,
          items: List.generate(
            widget.address.totalEntrances,
                (index) => DropdownMenuItem(
              value: index + 1,
              child: Text('Подъезд ${index + 1}'),
            ),
          ),
          onChanged: (value) => setState(() => _selectedEntrance = value),
        ),
      ],
    );
  }

  Widget _buildHintForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Подсказка для коллег',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _hintController,
          maxLines: 4,
          maxLength: 200,
          decoration: const InputDecoration(
            hintText: 'Например: код домофона 123#, вход через двор до второго подъезда',
            prefixIcon: Icon(Icons.edit),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Введите подсказку';
            }
            if (value.length < 10) {
              return 'Подсказка слишком короткая (минимум 10 символов)';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildCodeForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Код домофона',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _codeController,
          keyboardType: TextInputType.text,
          decoration: const InputDecoration(
            hintText: '123#4567',
            prefixIcon: Icon(Icons.dialpad),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Введите код домофона';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _gateNumberController,
          decoration: const InputDecoration(
            labelText: 'Номер калитки (опционально)',
            hintText: 'Калитка №2',
            // Меняем Icons.gate на Icons.fence (или любую другую существующую)
            prefixIcon: Icon(Icons.fence),
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<int>(
          decoration: const InputDecoration(
            labelText: 'Номер подъезда (опционально)',
            prefixIcon: Icon(Icons.door_front_door),
          ),
          value: _selectedEntrance,
          dropdownColor: AppTheme.cardDark,
          items: List.generate(
            widget.address.totalEntrances,
                (index) => DropdownMenuItem(
              value: index + 1,
              child: Text('Подъезд ${index + 1}'),
            ),
          ),
          onChanged: (value) => setState(() => _selectedEntrance = value),
        ),
      ],
    );
  }
}

class _ContributionTypeCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String points;
  final bool isSelected;
  final VoidCallback onTap;

  const _ContributionTypeCard({
    required this.icon,
    required this.label,
    required this.points,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryBlue
              : AppTheme.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryBlue
                : AppTheme.primaryBlue.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected
                  ? Colors.white
                  : AppTheme.textSecondary,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              points,
              style: TextStyle(
                fontSize: 12,
                color: isSelected
                    ? AppTheme.accentYellow
                    : AppTheme.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}