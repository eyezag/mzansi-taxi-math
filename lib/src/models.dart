class FareTier {
  FareTier({required this.id, required this.label, this.amount = 0});

  final String id;
  String label;
  int amount;

  Map<String, dynamic> toJson() => {'id': id, 'label': label, 'amount': amount};

  factory FareTier.fromJson(Map<String, dynamic> json) => FareTier(
        id: json['id'] as String,
        label: json['label'] as String,
        amount: (json['amount'] as num).toInt(),
      );
}

class PaymentEntry {
  PaymentEntry({
    required this.id,
    Map<String, int>? seatCounts,
    this.cashGiven,
    DateTime? timestamp,
  })  : seatCounts = seatCounts ?? {},
        timestamp = timestamp ?? DateTime.now();

  final String id;
  final Map<String, int> seatCounts;
  int? cashGiven;
  final DateTime timestamp;

  int get seats => seatCounts.values.fold(0, (a, b) => a + b);

  /// Derived: what these seats cost at the current fares.
  int expectedTotal(List<FareTier> tiers) =>
      tiers.fold(0, (sum, t) => sum + t.amount * (seatCounts[t.id] ?? 0));

  /// Derived: positive = change owed back, negative = shortfall.
  int change(List<FareTier> tiers) => (cashGiven ?? 0) - expectedTotal(tiers);

  bool isResolved(List<FareTier> tiers) =>
      cashGiven != null && seats > 0 && expectedTotal(tiers) > 0;
}

class Trip {
  Trip({required this.fareTiers, required this.entries, this.totalSeats});

  List<FareTier> fareTiers;
  List<PaymentEntry> entries;
  int? totalSeats;
}

class TripTotals {
  const TripTotals({
    required this.collected,
    required this.changeGiven,
    required this.shortfall,
    required this.seats,
    required this.payments,
  });

  final int collected;
  final int changeGiven;
  final int shortfall;
  final int seats;
  final int payments;

  int get owedToDriver => collected - changeGiven;

  static TripTotals of(Trip trip) {
    var collected = 0, changeGiven = 0, shortfall = 0, seats = 0, payments = 0;
    for (final e in trip.entries) {
      if (!e.isResolved(trip.fareTiers)) continue;
      final change = e.change(trip.fareTiers);
      collected += e.cashGiven!;
      if (change > 0) changeGiven += change;
      if (change < 0) shortfall += -change;
      seats += e.seats;
      payments++;
    }
    return TripTotals(
      collected: collected,
      changeGiven: changeGiven,
      shortfall: shortfall,
      seats: seats,
      payments: payments,
    );
  }
}
