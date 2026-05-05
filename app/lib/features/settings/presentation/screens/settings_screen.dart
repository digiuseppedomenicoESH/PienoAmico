import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_logo.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Impostazioni'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.divider),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 8),

          // App info
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.backgroundCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                const AppLogo(iconSize: 28),
                const SizedBox(height: 12),
                const Text(
                  'Trova il carburante più economico\nvicino a te, in tempo reale.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Text(
                    'v1.0.0',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          const Text('INFORMAZIONI', style: AppTextStyles.sectionLabel),
          const SizedBox(height: 10),

          _SettingsGroup(
            items: [
              _SettingsItem(
                icon: Icons.dataset_outlined,
                label: 'Fonte dati',
                subtitle: 'MIMIT — Ministero delle Imprese',
                onTap: null,
              ),
              _SettingsItem(
                icon: Icons.update_rounded,
                label: 'Aggiornamento dati',
                subtitle: 'Ogni giorno alle ore 8:00',
                onTap: null,
              ),
              _SettingsItem(
                icon: Icons.lock_outline_rounded,
                label: 'Privacy',
                subtitle: 'Nessun dato personale raccolto',
                onTap: null,
              ),
            ],
          ),

          const SizedBox(height: 20),
          const Text('LEGENDA PREZZI', style: AppTextStyles.sectionLabel),
          const SizedBox(height: 10),

          _SettingsGroup(
            items: [
              _SettingsItem(
                icon: Icons.circle,
                iconColor: AppColors.prezzoTop,
                label: 'Prezzo conveniente',
                subtitle: 'Nei primi 33% della lista per distanza',
                onTap: null,
              ),
              _SettingsItem(
                icon: Icons.circle,
                iconColor: AppColors.prezzoMid,
                label: 'Prezzo nella media',
                subtitle: 'Tra il 33% e il 67% della lista',
                onTap: null,
              ),
              _SettingsItem(
                icon: Icons.circle,
                iconColor: AppColors.prezzoHigh,
                label: 'Prezzo alto',
                subtitle: 'Sopra il 67% della lista',
                onTap: null,
                isLast: true,
              ),
            ],
          ),

          const SizedBox(height: 40),
          const Center(
            child: Text(
              'Dati open data © MIMIT',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textDisabled,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final List<_SettingsItem> items;
  const _SettingsGroup({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: items.asMap().entries.map((e) {
          final isLast = e.key == items.length - 1;
          return Column(
            children: [
              e.value,
              if (!isLast)
                Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  color: AppColors.divider,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String label;
  final String subtitle;
  final VoidCallback? onTap;
  final bool isLast;

  const _SettingsItem({
    required this.icon,
    this.iconColor,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 18, color: iconColor ?? AppColors.textSecondary),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: AppColors.textDisabled,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
