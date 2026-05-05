import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/extensions/double_ext.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/distributore.dart';
import 'price_badge.dart';

class FuelMap extends StatefulWidget {
  final List<Distributore> distributori;
  final List<PriceTier> tiers;
  final double userLat;
  final double userLon;

  const FuelMap({
    super.key,
    required this.distributori,
    required this.tiers,
    required this.userLat,
    required this.userLon,
  });

  @override
  State<FuelMap> createState() => _FuelMapState();
}

class _FuelMapState extends State<FuelMap> {
  final _mapController = MapController();
  Distributore? _selected;
  int? _selectedIndex;

  static const _zoom = 13.5;

  Color _tierColor(PriceTier t) => switch (t) {
        PriceTier.best => AppColors.prezzoTop,
        PriceTier.mid  => AppColors.prezzoMid,
        PriceTier.high => AppColors.prezzoHigh,
      };

  void _onMarkerTap(Distributore d, int index) {
    setState(() {
      _selected = d;
      _selectedIndex = index;
    });
    _mapController.move(
      LatLng(d.latitudine, d.longitudine),
      _mapController.camera.zoom,
    );
  }

  void _dismiss() => setState(() {
        _selected = null;
        _selectedIndex = null;
      });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: LatLng(widget.userLat, widget.userLon),
            initialZoom: _zoom,
            onTap: (_, __) => _dismiss(),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.pienoamico.app',
              maxZoom: 19,
            ),
            MarkerLayer(
              markers: widget.distributori.asMap().entries.map((e) {
                final i = e.key;
                final d = e.value;
                final isSelected = _selectedIndex == i;
                return Marker(
                  point: LatLng(d.latitudine, d.longitudine),
                  width: isSelected ? 76 : 64,
                  height: isSelected ? 44 : 36,
                  alignment: Alignment.topCenter,
                  child: GestureDetector(
                    onTap: () => _onMarkerTap(d, i),
                    child: _PriceMarker(
                      prezzo: d.prezzoBest,
                      color: _tierColor(widget.tiers[i]),
                      isSelected: isSelected,
                    ),
                  ),
                );
              }).toList(),
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: LatLng(widget.userLat, widget.userLon),
                  width: 20,
                  height: 20,
                  child: _UserMarker(),
                ),
              ],
            ),
          ],
        ),

        // Bottone centra su di me
        Positioned(
          right: 12,
          bottom: _selected != null ? 228 : 16,
          child: _CenterButton(
            onTap: () => _mapController.move(
              LatLng(widget.userLat, widget.userLon),
              _zoom,
            ),
          ),
        ),

        // Card stazione selezionata
        if (_selected != null && _selectedIndex != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _StationCard(
              distributore: _selected!,
              tierColor: _tierColor(widget.tiers[_selectedIndex!]),
              onClose: _dismiss,
              onDetail: () => context.push(
                '/detail/${_selected!.id}',
                extra: _selected,
              ),
            ),
          ),
      ],
    );
  }
}

// ── Marker prezzo ─────────────────────────────────────────────────────────────

class _PriceMarker extends StatelessWidget {
  final double? prezzo;
  final Color color;
  final bool isSelected;

  const _PriceMarker({
    required this.prezzo,
    required this.color,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: color,
              width: isSelected ? 0 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: isSelected ? 0.4 : 0.2),
                blurRadius: isSelected ? 8 : 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            prezzo != null
                ? prezzo!.toStringAsFixed(3).replaceAll('.', ',')
                : '—',
            style: TextStyle(
              fontSize: isSelected ? 13 : 11,
              fontWeight: FontWeight.w800,
              color: isSelected ? Colors.white : color,
              letterSpacing: -0.3,
              height: 1,
            ),
          ),
        ),
        CustomPaint(
          size: const Size(10, 6),
          painter: _TrianglePainter(
            color: isSelected ? color : Colors.white,
            borderColor: color,
          ),
        ),
      ],
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  final Color borderColor;
  const _TrianglePainter({required this.color, required this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_TrianglePainter old) =>
      old.color != color || old.borderColor != borderColor;
}

// ── Marker utente ─────────────────────────────────────────────────────────────

class _UserMarker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.4),
            blurRadius: 8,
          ),
        ],
      ),
    );
  }
}

// ── Bottone centra ────────────────────────────────────────────────────────────

class _CenterButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CenterButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 3,
      shadowColor: Colors.black26,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: const Padding(
          padding: EdgeInsets.all(10),
          child: Icon(
            Icons.my_location_rounded,
            color: AppColors.primary,
            size: 22,
          ),
        ),
      ),
    );
  }
}

// ── Card stazione selezionata ─────────────────────────────────────────────────

class _StationCard extends StatelessWidget {
  final Distributore distributore;
  final Color tierColor;
  final VoidCallback onClose;
  final VoidCallback onDetail;

  const _StationCard({
    required this.distributore,
    required this.tierColor,
    required this.onClose,
    required this.onDetail,
  });

  Future<void> _navigateTo() async {
    final d = distributore;
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=${d.latitudine},${d.longitudine}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = distributore;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d.nome.isNotEmpty ? d.nome : d.bandiera,
                      style: AppTextStyles.nomeDistributore,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      [if (d.bandiera.isNotEmpty) d.bandiera, d.comune]
                          .join(' · '),
                      style: AppTextStyles.bandiera,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.near_me_rounded,
                          size: 12,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          d.distanzaM.toDouble().asDistanza,
                          style: AppTextStyles.distanza,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (d.prezzoBest != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      d.prezzoBest!.toStringAsFixed(3).replaceAll('.', ','),
                      style: AppTextStyles.prezzoHero.copyWith(
                        color: tierColor,
                        fontSize: 26,
                      ),
                    ),
                    Text(
                      '€/L',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: tierColor.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onDetail,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Dettagli',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _navigateTo,
                  icon: const Icon(Icons.navigation_rounded, size: 18),
                  label: const Text(
                    'Naviga',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
