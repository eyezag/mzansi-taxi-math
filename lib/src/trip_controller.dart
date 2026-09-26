import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

/// Holds the whole trip in memory. Only fare tiers are persisted.
class TripController extends ChangeNotifier {
  TripController() {
    _addFreshEntry();
  }

  static const _prefsKey = 'fare_tiers_v1';
  static const defaultCapacity = 15;

  int _seq = 0;
  String _newId() => '${DateTime.now().microsecondsSinceEpoch}-${_seq++}';

  late final Trip trip = Trip(
    fareTiers: [FareTier(id: _newId(), label: 'Fare')],
    entries: [],
  );

  /// The card currently open for editing (others show a compact summary).
  String? expandedId;

  List<FareTier> get tiers => trip.fareTiers;
  List<PaymentEntry> get entries => trip.entries;
  TripTotals get totals => TripTotals.of(trip);

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null) return;
      final saved = (jsonDecode(raw) as List)
          .map((e) => FareTier.fromJson(e as Map<String, dynamic>))
          .toList();
      if (saved.isEmpty) return;
      trip.fareTiers = saved;
      // Rebuild the untouched starter card so its seat defaults match the saved tiers.
      if (entries.length == 1 && entries.first.cashGiven == null) {
        entries.clear();
        _addFreshEntry();
      }
      notifyListeners();
    } catch (_) {
      // Presets are a convenience; fall back to defaults.
    }
  }

  Future<void> _saveTiers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, jsonEncode(tiers.map((t) => t.toJson()).toList()));
    } catch (_) {}
  }

  // Fare tiers

  void addTier() {
    if (tiers.length == 1 && tiers.first.label == 'Fare') tiers.first.label = 'Local';
    tiers.add(FareTier(
      id: _newId(),
      label: tiers.length == 1 ? 'Town' : 'Tier ${tiers.length + 1}',
    ));
    _saveTiers();
    notifyListeners();
  }

  void updateTier(String id, {String? label, int? amount}) {
    final tier = tiers.firstWhere((t) => t.id == id);
    if (label != null && label.trim().isNotEmpty) tier.label = label.trim();
    if (amount != null) tier.amount = amount;
    _saveTiers();
    notifyListeners();
  }

  void removeTier(String id) {
    if (tiers.length <= 1) return;
    tiers.removeWhere((t) => t.id == id);
    for (final e in entries) {
      e.seatCounts.remove(id);
    }
    _saveTiers();
    notifyListeners();
  }

  // Payment entries

  void _addFreshEntry() {
    final entry = PaymentEntry(
      id: _newId(),
      // One fare: assume a single seat, the most common handover.
      seatCounts: {if (tiers.length == 1) tiers.first.id: 1},
    );
    entries.add(entry);
    expandedId = entry.id;
  }

  void addEntry() {
    _addFreshEntry();
    notifyListeners();
  }

  void toggleExpanded(String id) {
    expandedId = expandedId == id ? null : id;
    notifyListeners();
  }

  PaymentEntry _entry(String id) => entries.firstWhere((e) => e.id == id);

  void setSeats(String entryId, String tierId, int count) {
    _entry(entryId).seatCounts[tierId] = max(0, count);
    notifyListeners();
  }

  void setCash(String entryId, int? cash) {
    _entry(entryId).cashGiven = cash;
    notifyListeners();
  }

  void addNote(String entryId, int note) {
    final e = _entry(entryId);
    e.cashGiven = (e.cashGiven ?? 0) + note;
    notifyListeners();
  }

  /// Removes an entry; totals are derived so its effect reverses automatically.
  (int, PaymentEntry) removeEntry(String id) {
    final index = entries.indexWhere((e) => e.id == id);
    final entry = entries.removeAt(index);
    if (expandedId == id) expandedId = null;
    notifyListeners();
    return (index, entry);
  }

  void restoreEntry(int index, PaymentEntry entry) {
    entries.insert(min(index, entries.length), entry);
    notifyListeners();
  }

  void setTotalSeats(int? seats) {
    trip.totalSeats = (seats == null || seats <= 0) ? null : seats;
    notifyListeners();
  }

  void newTrip({bool keepFares = true}) {
    if (!keepFares) {
      trip.fareTiers = [FareTier(id: _newId(), label: 'Fare')];
      _saveTiers();
    }
    entries.clear();
    _addFreshEntry();
    notifyListeners();
  }
}
