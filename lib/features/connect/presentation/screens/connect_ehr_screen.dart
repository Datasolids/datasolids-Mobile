// Connect EHR — provider picker. Matches the "Mobile: Connect EHR" reference.
//
// Epic MyChart routes into the health-system search (the only provider wired
// to a live backend directory today). The others are shown but flagged as
// not-yet-available so the patient understands what's coming.

import 'package:datasolids_mobile/core/theme/app_colors.dart';
import 'package:datasolids_mobile/features/connect/presentation/widgets/flow_bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ConnectEhrScreen extends StatelessWidget {
  const ConnectEhrScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgCream,
      bottomNavigationBar: const FlowBottomNav(activeIndex: 1),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(12, 8, 20, 18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, size: 22),
                    color: AppColors.navy900,
                    onPressed: () => context.pop(),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Connect EHR',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Sync data from your providers',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'SELECT PROVIDER',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.6,
                        color: AppColors.textSubtle,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _ProviderCard(
                      monogram: 'EP',
                      title: 'Epic MyChart',
                      subtitle: 'Used by Mayo Clinic, Cleveland Clinic, etc.',
                      onTap: () => context.push('/connect/epic'),
                    ),
                    const SizedBox(height: 14),
                    _ProviderCard(
                      monogram: 'CE',
                      title: 'Cerner HealtheLife',
                      subtitle: 'Used by Banner Health, UPMC, etc.',
                      onTap: () => _comingSoon(context, 'Cerner HealtheLife'),
                    ),
                    const SizedBox(height: 14),
                    _ProviderCard(
                      monogram: 'AT',
                      title: 'AthenaHealth',
                      subtitle: 'Used by independent clinics & specialists',
                      onTap: () => _comingSoon(context, 'AthenaHealth'),
                    ),
                    const SizedBox(height: 14),
                    _OtherProviderCard(
                      onTap: () => context.push('/connect/epic'),
                    ),
                    const SizedBox(height: 24),
                    const _EncryptedFooter(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _comingSoon(BuildContext context, String name) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$name support is coming soon — Epic is available now.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _ProviderCard extends StatelessWidget {
  const _ProviderCard({
    required this.monogram,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String monogram;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border.withOpacity(0.7)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.bgCream,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                monogram,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy900,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.textSubtle, size: 20),
          ],
        ),
      ),
    );
  }
}

class _OtherProviderCard extends StatelessWidget {
  const _OtherProviderCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.border,
            width: 1.4,
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              child: Icon(Icons.add, color: AppColors.navy900, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Other Provider',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Search by hospital name or zip code',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EncryptedFooter extends StatelessWidget {
  const _EncryptedFooter();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.lock_outline, size: 14, color: AppColors.textSubtle),
        const SizedBox(width: 6),
        Text(
          'END-TO-END ENCRYPTED CONNECTION',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
            color: AppColors.textSubtle,
          ),
        ),
      ],
    );
  }
}
