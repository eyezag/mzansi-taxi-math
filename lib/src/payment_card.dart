import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'format.dart';
import 'models.dart';
import 'theme.dart';
import 'trip_controller.dart';

const _notes = [10, 20, 50, 100, 200];

/// One cash handover. Expanded while being filled in; compact once done.
class PaymentCard extends StatefulWidget {
  const PaymentCard({
    super.key,
    required this.controller,
    required this.entry,
    required this.number,
    required this.expanded,
    required this.onDelete,
  });

  final TripController controller;
  final PaymentEntry entry;
  final int number;
  final bool expanded;
  final VoidCallback onDelete;

  @override
  State<PaymentCard> createState() => _PaymentCardState();
}

class _PaymentCardState extends State<PaymentCard> {
  late final TextEditingController _cash =
      TextEditingController(text: widget.entry.cashGiven?.toString() ?? '');

  @override
  void didUpdateWidget(PaymentCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Note buttons change cash from outside the text field.
    final want = widget.entry.cashGiven?.toString() ?? '';
    if (_cash.text != want) {
      _cash.value = TextEditingValue(
        text: want,
        selection: TextSelection.collapsed(offset: want.length),
      );
    }
  }

  @override
  void dispose() {
    _cash.dispose();
    super.dispose();
  }

  TripController get c => widget.controller;
  PaymentEntry get e => widget.entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: cardDecoration(),
      clipBehavior: Clip.antiAlias,
      child: AnimatedSize(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: widget.expanded ? _expanded() : _collapsed(),
      ),
    );
  }

  Widget _collapsed() {
    final tiers = c.tiers;
    final resolved = e.isResolved(tiers);
    final seats = e.seats;
    return InkWell(
      onTap: () => c.toggleExpanded(e.id),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PAYMENT ${widget.number}  ·  ${clock(e.timestamp)}', style: AppText.label),
                  const SizedBox(height: 6),
                  Text(
                    '$seats seat${seats == 1 ? '' : 's'}  ·  ${rand(e.expectedTotal(tiers))} due',
                    style: AppText.body,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    e.cashGiven == null ? 'No cash entered' : 'Paid ${rand(e.cashGiven!)}',
                    style: const TextStyle(fontSize: 14, color: AppColors.muted),
                  ),
                ],
              ),
            ),
            if (resolved)
              _Outcome(change: e.change(tiers), compact: true)
            else
              const Row(
                children: [
                  Text('Finish', style: TextStyle(color: AppColors.muted, fontSize: 14)),
                  Icon(Icons.chevron_right_rounded, color: AppColors.muted),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _expanded() {
    final tiers = c.tiers;
    final single = tiers.length == 1;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 8, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: e.isResolved(tiers) ? () => c.toggleExpanded(e.id) : null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Text(
                      'PAYMENT ${widget.number}  ·  ${clock(e.timestamp)}',
                      style: AppText.label,
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Delete payment',
                onPressed: widget.onDelete,
                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.muted),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final t in tiers)
                  _SeatRow(
                    label: single ? 'Seats' : t.label,
                    fare: t.amount,
                    count: e.seatCounts[t.id] ?? 0,
                    onChanged: (n) => c.setSeats(e.id, t.id, n),
                  ),
                const SizedBox(height: 16),
                const Row(
                  children: [
                    Text('CASH GIVEN', style: AppText.label),
                    Spacer(),
                    Text('notes add up', style: TextStyle(fontSize: 12, color: AppColors.muted)),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _cash,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(5),
                  ],
                  style: AppText.money(34),
                  onChanged: (v) => c.setCash(e.id, int.tryParse(v)),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.field,
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(left: 16, right: 4),
                      child: Text('R', style: AppText.money(34, color: AppColors.muted)),
                    ),
                    prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                    hintText: '0',
                    hintStyle: AppText.money(34, color: AppColors.line),
                    suffixIcon: e.cashGiven == null
                        ? null
                        : IconButton(
                            tooltip: 'Clear cash',
                            onPressed: () => c.setCash(e.id, null),
                            icon: const Icon(Icons.close_rounded, color: AppColors.muted),
                          ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    for (final (i, n) in _notes.indexed) ...[
                      if (i > 0) const SizedBox(width: 6),
                      Expanded(child: _NoteButton(value: n, onTap: () => c.addNote(e.id, n))),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: e.isResolved(tiers)
                      ? _ResultPanel(key: const ValueKey('result'), entry: e, tiers: tiers)
                      : Padding(
                          key: const ValueKey('hint'),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(_hint(tiers), style: const TextStyle(color: AppColors.muted)),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _hint(List<FareTier> tiers) {
    if (tiers.every((t) => t.amount == 0)) return 'Set the fare above to see change.';
    if (e.seats == 0) return 'Add seats for this payment.';
    if (e.expectedTotal(tiers) == 0) return 'Set a fare for the selected seats.';
    return 'Enter the cash handed over.';
  }
}

class _SeatRow extends StatelessWidget {
  const _SeatRow({
    required this.label,
    required this.fare,
    required this.count,
    required this.onChanged,
  });

  final String label;
  final int fare;
  final int count;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppText.body),
                Text('${rand(fare)} each', style: const TextStyle(fontSize: 13, color: AppColors.muted)),
              ],
            ),
          ),
          _RoundButton(icon: Icons.remove_rounded, onTap: count > 0 ? () => onChanged(count - 1) : null),
          SizedBox(
            width: 52,
            child: Text('$count', textAlign: TextAlign.center, style: AppText.money(28)),
          ),
          _RoundButton(icon: Icons.add_rounded, onTap: () => onChanged(count + 1)),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.field,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(icon, color: onTap == null ? AppColors.line : AppColors.ink),
        ),
      ),
    );
  }
}

class _NoteButton extends StatelessWidget {
  const _NoteButton({required this.value, required this.onTap});

  final int value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.line, width: 1.5),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: SizedBox(
          height: 48,
          child: Center(
            child: FittedBox(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text('R$value', style: AppText.body.copyWith(fontSize: 15)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultPanel extends StatelessWidget {
  const _ResultPanel({super.key, required this.entry, required this.tiers});

  final PaymentEntry entry;
  final List<FareTier> tiers;

  @override
  Widget build(BuildContext context) {
    final change = entry.change(tiers);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: change < 0 ? AppColors.shortSoft : AppColors.moneySoft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(child: _Outcome(change: change)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('DUE', style: AppText.label),
              Text(rand(entry.expectedTotal(tiers)), style: AppText.money(18, color: AppColors.muted)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Change back in green, a shortfall in amber — never a misleading payout.
class _Outcome extends StatelessWidget {
  const _Outcome({required this.change, this.compact = false});

  final int change;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final (label, text, color) = switch (change) {
      > 0 => ('CHANGE BACK', rand(change), AppColors.money),
      < 0 => ('SHORT', '${rand(change)} owed', AppColors.short),
      _ => ('EXACT', 'No change', AppColors.money),
    };
    return Column(
      crossAxisAlignment: compact ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: AppText.label.copyWith(color: color)),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            text,
            style: AppText.money(
              compact ? (change == 0 ? 20 : 30) : (change == 0 ? 30 : 48),
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
