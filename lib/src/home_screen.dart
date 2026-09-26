import 'package:flutter/material.dart';

import 'fare_bar.dart';
import 'payment_card.dart';
import 'theme.dart';
import 'totals_bar.dart';
import 'trip_controller.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.controller});

  final TripController controller;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _scroll = ScrollController();

  TripController get c => widget.controller;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _addRow() {
    FocusScope.of(context).unfocus();
    c.addEntry();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _delete(String id) {
    FocusScope.of(context).unfocus();
    final (index, entry) = c.removeEntry(id);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: const Text('Payment removed'),
        action: SnackBarAction(label: 'Undo', onPressed: () => c.restoreEntry(index, entry)),
      ));
  }

  Future<void> _confirmNewTrip() async {
    var keepFares = true;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Start a new trip?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('All payments and totals will be cleared.'),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Keep fares'),
                value: keepFares,
                onChanged: (v) => setLocal(() => keepFares = v),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('New trip')),
          ],
        ),
      ),
    );
    if (ok == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      c.newTrip(keepFares: keepFares);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) {
        final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 6, 10, 2),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Mzansi Taxi Math',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                            letterSpacing: -0.4,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'New trip',
                        iconSize: 26,
                        onPressed: _confirmNewTrip,
                        icon: const Icon(Icons.restart_alt_rounded, color: AppColors.ink),
                      ),
                    ],
                  ),
                ),
                FareBar(controller: c),
                Expanded(
                  child: ListView(
                    controller: _scroll,
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    children: [
                      for (final (i, e) in c.entries.indexed)
                        Padding(
                          key: ValueKey(e.id),
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Dismissible(
                            key: ValueKey('d-${e.id}'),
                            direction: DismissDirection.endToStart,
                            onDismissed: (_) => _delete(e.id),
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 28),
                              decoration: BoxDecoration(
                                color: AppColors.shortSoft,
                                borderRadius: BorderRadius.circular(22),
                              ),
                              child: const Icon(Icons.delete_outline_rounded, color: AppColors.short),
                            ),
                            child: PaymentCard(
                              controller: c,
                              entry: e,
                              number: i + 1,
                              expanded: c.expandedId == e.id,
                              onDelete: () => _delete(e.id),
                            ),
                          ),
                        ),
                      _AddRowButton(onTap: _addRow),
                    ],
                  ),
                ),
                if (!keyboardOpen) TotalsBar(controller: c),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AddRowButton extends StatelessWidget {
  const _AddRowButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: AppColors.line, width: 1.5),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: const SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_rounded, color: AppColors.ink),
              SizedBox(width: 6),
              Text('Add row', style: AppText.body),
            ],
          ),
        ),
      ),
    );
  }
}
