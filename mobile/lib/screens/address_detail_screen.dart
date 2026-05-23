import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/address_model.dart';
import '../utils/theme.dart';
import 'contribute_screen.dart';

class AddressDetailScreen extends StatefulWidget {
  final AddressModel address;

  const AddressDetailScreen({
    super.key,
    required this.address,
  });

  @override
  State<AddressDetailScreen> createState() => _AddressDetailScreenState();
}

class _AddressDetailScreenState extends State<AddressDetailScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _addressDetails;

  @override
  void initState() {
    super.initState();
    _loadAddressDetails();
  }

  Future<void> _loadAddressDetails() async {
    setState(() => _isLoading = true);

    // TODO: Load from API
    // Simulating API call for now
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _addressDetails = {
        'entrance_photos': [
          {
            'id': 1,
            'photo_url': 'https://via.placeholder.com/400x300',
            'entrance_number': 2,
            'uploaded_at': '2026-05-20 14:30:00'
          }
        ],
        'intercom_codes': [
          {
            'id': 1,
            'code': '123#4567',
            'entrance_number': 2,
            'gate_number': 'Калитка №2',
            'verified_count': 5
          }
        ],
        'hints': [
          {
            'id': 1,
            'hint_text': 'Вход справа от аптеки «Неман». Через двор до второго подъезда.',
            'helpful_count': 12,
            'created_at': '2026-05-18 10:15:00'
          }
        ]
      };
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with Image
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppTheme.cardDark,
            flexibleSpace: FlexibleSpaceBar(
              background: _addressDetails != null &&
                  _addressDetails!['entrance_photos'].isNotEmpty
                  ? CachedNetworkImage(
                imageUrl: _addressDetails!['entrance_photos'][0]
                ['photo_url'],
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: AppTheme.cardDark,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: AppTheme.cardDark,
                  child: const Icon(
                    Icons.home,
                    size: 64,
                    color: AppTheme.textSecondary,
                  ),
                ),
              )
                  : Container(
                color: AppTheme.cardDark,
                child: const Icon(
                  Icons.home,
                  size: 64,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: _isLoading
                ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(),
              ),
            )
                : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.address.name,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 16,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              widget.address.address,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildInfoChips(),
                    ],
                  ),
                ),

                // Intercom Codes Section
                if (_addressDetails!['intercom_codes'].isNotEmpty)
                  _buildIntercomCodesSection(),

                // Hints Section
                if (_addressDetails!['hints'].isNotEmpty)
                  _buildHintsSection(),

                // Photos Gallery
                if (_addressDetails!['entrance_photos'].length > 1)
                  _buildPhotosGallery(),

                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),

      // Floating Action Button
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ContributeScreen(address: widget.address),
            ),
          );
        },
        backgroundColor: AppTheme.primaryBlue,
        icon: const Icon(Icons.add_a_photo),
        label: const Text('Помочь коллегам'),
      ),
    );
  }

  Widget _buildInfoChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _InfoChip(
          icon: Icons.door_front_door,
          label: '${widget.address.totalEntrances} подъезда',
        ),
        if (widget.address.hasSecurity)
          const _InfoChip(
            icon: Icons.security,
            label: 'Есть охрана',
            color: AppTheme.errorRed,
          ),
        _InfoChip(
          icon: Icons.photo_camera,
          label:
          '${_addressDetails!['entrance_photos'].length} фото',
          color: AppTheme.successGreen,
        ),
      ],
    );
  }

  Widget _buildIntercomCodesSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            icon: Icons.dialpad,
            title: 'Коды домофонов',
          ),
          const SizedBox(height: 12),
          ..._addressDetails!['intercom_codes']
              .map<Widget>((code) => _IntercomCodeCard(code: code))
              .toList(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHintsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            icon: Icons.lightbulb,
            title: 'Подсказки от курьеров',
          ),
          const SizedBox(height: 12),
          ..._addressDetails!['hints']
              .map<Widget>((hint) => _HintCard(hint: hint))
              .toList(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPhotosGallery() {
    final photos = _addressDetails!['entrance_photos'] as List;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            icon: Icons.photo_library,
            title: 'Все фото входов',
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: photos.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: photos[index]['photo_url'],
                      width: 160,
                      height: 120,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: AppTheme.cardDark,
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _InfoChip({
    required this.icon,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: (color ?? AppTheme.primaryBlue).withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: color ?? AppTheme.primaryBlue,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: color ?? AppTheme.primaryBlue,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionHeader({
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryBlue, size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _IntercomCodeCard extends StatelessWidget {
  final Map<String, dynamic> code;

  const _IntercomCodeCard({required this.code});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.accentYellow.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Code Display
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.accentYellow.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  code['code'],
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.accentYellow,
                    letterSpacing: 2,
                  ),
                ),
              ),
              const Spacer(),
              // Copy Button
              IconButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: code['code']));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Код скопирован'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.copy, color: AppTheme.primaryBlue),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (code['gate_number'] != null) ...[
            Row(
              children: [
                const Icon(
                  Icons.door_front_door,
                  size: 16,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  code['gate_number'],
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              const Icon(
                Icons.verified,
                size: 16,
                color: AppTheme.successGreen,
              ),
              const SizedBox(width: 6),
              Text(
                'Проверено ${code['verified_count']} раз',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HintCard extends StatelessWidget {
  final Map<String, dynamic> hint;

  const _HintCard({required this.hint});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person,
                  size: 16,
                  color: AppTheme.primaryBlue,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Курьер делится опытом',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              Text(
                '👍 ${hint['helpful_count']}',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            hint['hint_text'],
            style: const TextStyle(
              fontSize: 15,
              color: AppTheme.textPrimary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}