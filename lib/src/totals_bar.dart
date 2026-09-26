import 'package:flutter/material.dart';

import 'format.dart';
import 'theme.dart';
import 'trip_controller.dart';

/// Slim running-totals bar at the bottom; tap to expand the breakdown.
class TotalsBar extends StatefulWidget {
  const TotalsBar({super.key, required this.controller});

  final TripController controller;

  @override
  State<TotalsBar> createState() => _TotalsBarState();
}

class _TotalsBarState extends State<TotalsBar> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final t = c.totals;
    final capacity = c.trip.totalSeats;
    final seatsText = capacity == null ? '${t.seats}' : '${t.seats} / $capacity';

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        boxShadow: [BoxShadow(color: Color(0x12000000), blurRadius: 24, offset: Offset(0, -4))],
      ),
      child: SafeArea(
        top: false,
        child: InkWell(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          onTap: () => setState(() => _open = !_open),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 14, 16, 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('OWED TO DRIVER', style: AppText.label),
                            Text(rand(t.owedToDriver), style: AppText.money(28)),
                          ],
                        ),
                      ),
                      Text(
                        '$seatsText seat${t.seats == 1 && capacity == null ? '' : 's'}',
                        style: const TextStyle(color: AppColors.muted, fontSize: 14),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        _open ? Icons.expand_more_rounded : Icons.expand_less_rounded,
                        color: AppColors.muted,
                      ),
                    ],
                  ),
                  if (_open) ...[
                    const SizedBox(height: 12),
                    const Divider(height: 1, color: AppColors.line),
                    const SizedBox(height: 8),
                    _Line('Collected', rand(t.collected)),
                    _Line('Change given', rand(t.changeGiven), color: AppColors.money),
                    if (t.shortfall > 0) _Line('Short (unpaid)', rand(t.shortfall), color: AppColors.short),
                    _Line('Payments', '${t.payments}'),
                    Row(
                      children: [
                        const Expanded(child: Text('Seats paid', style: _lineLabel)),
                        Text(seatsText, style: AppText.money(18)),
                        const SizedBox(width: 8),
                        _Small(
                          icon: Icons.remove_rounded,
                          tooltip: 'Fewer seats in taxi',
                          onTap: capacity == null ? null : () => c.setTotalSeats(capacity - 1),
                        ),
                        _Small(
                          icon: Icons.add_rounded,
                          tooltip: 'Seats in taxi',
                          onTap: () => c.setTotalSeats(
                            capacity == null ? TripController.defaultCapacity : capacity + 1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

const _lineLabel = TextStyle(fontSize: 15, color: AppColors.muted);

class _Line extends StatelessWidget {
  const _Line(this.label, this.value, {this.color = AppColors.ink});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 6, right: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: _lineLabel)),
          Text(value, style: AppText.money(18, color: color)),
        ],
      ),
    );
  }
}

class _Small extends StatelessWidget {
  const _Small({required this.icon, required this.tooltip, required this.onTap});

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      icon: Icon(icon, size: 20),
      color: AppColors.ink,
      disabledColor: AppColors.line,
    );
  }
}
