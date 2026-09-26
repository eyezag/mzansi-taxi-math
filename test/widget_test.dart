import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mzansi_taxi_math/main.dart';
import 'package:mzansi_taxi_math/src/format.dart';
import 'package:mzansi_taxi_math/src/trip_controller.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('TripController', () {
    test('change, shortfall and totals', () {
      final c = TripController();
      final fare = c.tiers.first;
      c.updateTier(fare.id, amount: 18);

      final first = c.entries.first; // defaults to 1 seat
      c.setSeats(first.id, fare.id, 2);
      c.addNote(first.id, 50);
      expect(first.change(c.tiers), 14);

      c.addEntry();
      final second = c.entries.last;
      c.setCash(second.id, 13);
      expect(second.change(c.tiers), -5);

      final t = c.totals;
      expect(t.collected, 63);
      expect(t.changeGiven, 14);
      expect(t.shortfall, 5);
      expect(t.owedToDriver, 49);
      expect(t.seats, 3);

      final (index, removed) = c.removeEntry(first.id);
      expect(c.totals.collected, 13);
      c.restoreEntry(index, removed);
      expect(c.totals.collected, 63);
    });

    test('tiers split fares and new trip keeps them', () {
      final c = TripController();
      c.addTier();
      final [local, town] = c.tiers;
      expect(local.label, 'Local');
      expect(town.label, 'Town');
      c.updateTier(local.id, amount: 15);
      c.updateTier(town.id, amount: 22);

      final e = c.entries.first;
      c.setSeats(e.id, local.id, 1);
      c.setSeats(e.id, town.id, 2);
      c.setCash(e.id, 100);
      expect(e.expectedTotal(c.tiers), 59);
      expect(e.change(c.tiers), 41);

      c.newTrip();
      expect(c.entries.length, 1);
      expect(c.totals.collected, 0);
      expect(c.tiers.length, 2);
    });
  });

  test('rand formatting', () {
    expect(rand(1250), 'R1 250');
    expect(rand(-5), '−R5');
  });

  testWidgets('entering cash shows change', (tester) async {
    final c = TripController();
    await tester.pumpWidget(TaxiMathApp(controller: c));
    c.updateTier(c.tiers.first.id, amount: 18);
    await tester.pump();

    await tester.tap(find.text('R20'));
    await tester.pumpAndSettle();
    expect(find.text('CHANGE BACK'), findsOneWidget);
    expect(find.text('R2'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add_rounded).last); // seat +
    await tester.pumpAndSettle();
    expect(find.text('SHORT'), findsOneWidget);
    expect(find.text('−R16 owed'), findsOneWidget);
  });

  testWidgets('add row collapses previous card; delete can be undone', (tester) async {
    tester.view
      ..physicalSize = const Size(1080, 2400)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final c = TripController();
    await tester.pumpWidget(TaxiMathApp(controller: c));
    c.updateTier(c.tiers.first.id, amount: 18);
    await tester.pump();
    await tester.tap(find.text('R50'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Add row'));
    await tester.tap(find.text('Add row'));
    await tester.pumpAndSettle();
    expect(c.entries.length, 2);
    expect(find.text('Paid R50'), findsOneWidget); // compact summary of card 1
    expect(find.text('R32'), findsOneWidget);

    await tester.tap(find.byTooltip('Delete payment'));
    await tester.pumpAndSettle();
    expect(c.entries.length, 1);
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(c.entries.length, 2);
    expect(c.totals.owedToDriver, 18);
  });
}
