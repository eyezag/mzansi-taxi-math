import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models.dart';
import 'theme.dart';
import 'trip_controller.dart';

/// Compact, pinned fare strip. One fare by default; "+" splits into named tiers.
class FareBar extends StatelessWidget {
  const FareBar({super.key, required this.controller});

  final TripController controller;

  @override
  Widget build(BuildContext context) {
    final tiers = controller.tiers;
    final single = tiers.length == 1;
    final pills = [
      for (final t in tiers)
        _TierPill(key: ValueKey(t.id), tier: t, controller: controller, fill: single),
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.all(8),
      decoration: cardDecoration(radius: 22),
      child: Row(
        children: [
          Expanded(
            child: single
                ? pills.first
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final p in pills)
                          Padding(padding: const EdgeInsets.only(right: 8), child: p),
                      ],
                    ),
                  ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 52,
            height: 64,
            child: Material(
              color: AppColors.field,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: controller.addTier,
                child: const Tooltip(
                  message: 'Add fare tier',
                  child: Icon(Icons.add_rounded, color: AppColors.ink, size: 26),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TierPill extends StatefulWidget {
  const _TierPill({
    super.key,
    required this.tier,
    required this.controller,
    required this.fill,
  });

  final FareTier tier;
  final TripController controller;
  final bool fill;

  @override
  State<_TierPill> createState() => _TierPillState();
}

class _TierPillState extends State<_TierPill> {
  late final TextEditingController _amount = TextEditingController(
    text: widget.tier.amount == 0 ? '' : '${widget.tier.amount}',
  );

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _edit() async {
    final canRemove = widget.controller.tiers.length > 1;
    final name = TextEditingController(text: widget.tier.label);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Fare tier'),
        content: TextField(
          controller: name,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Name'),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          if (canRemove)
            TextButton(
              onPressed: () => Navigator.pop(ctx, '\u0000remove'),
              child: const Text('Remove', style: TextStyle(color: AppColors.short)),
            ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, name.text), child: const Text('Save')),
        ],
      ),
    );
    name.dispose();
    if (result == null) return;
    if (result == '\u0000remove') {
      widget.controller.removeTier(widget.tier.id);
    } else {
      widget.controller.updateTier(widget.tier.id, label: result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final amountField = SizedBox(
      width: widget.fill ? null : 64,
      child: TextField(
        controller: _amount,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(4),
        ],
        style: AppText.money(26),
        decoration: InputDecoration.collapsed(
          hintText: '0',
          hintStyle: AppText.money(26, color: AppColors.line),
        ),
        onChanged: (v) =>
            widget.controller.updateTier(widget.tier.id, amount: int.tryParse(v) ?? 0),
      ),
    );

    return Container(
      height: 64,
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
      decoration: BoxDecoration(
        color: AppColors.field,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _edit,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(widget.tier.label.toUpperCase(), style: AppText.label),
                const SizedBox(width: 4),
                const Icon(Icons.edit_outlined, size: 12, color: AppColors.muted),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: widget.fill ? MainAxisSize.max : MainAxisSize.min,
            children: [
              Text('R', style: AppText.money(26, color: AppColors.muted)),
              const SizedBox(width: 2),
              widget.fill ? Expanded(child: amountField) : amountField,
            ],
          ),
        ],
      ),
    );
  }
}
