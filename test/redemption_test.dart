import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:kraiiv/core/services/data_service.dart';

/// Seeds the KTC balance directly so tests stay focused on redemption
/// (goals/meal logging award tokens through their own paths).
Future<void> seedBalance(int amount) async {
  await Hive.box('tokens').put('balance', amount);
}

void main() {
  setUp(() async {
    final tempDir = await Directory.systemTemp.createTemp('kraiiv_test');
    Hive.init(tempDir.path);
    await DataService.initialize();
    await DataService.resetAll();
  });

  test('redeemKTC deducts the balance and records the redemption', () async {
    await seedBalance(300);

    final record = await DataService.redeemKTC(
      cost: 250,
      title: 'Spa Treatment Voucher',
    );

    expect(record, isNotNull);
    expect(record!['title'], 'Spa Treatment Voucher');
    expect(record['cost'], 250);
    expect(DataService.ktcBalance, 50);
    expect(DataService.redemptions, hasLength(1));
    expect(DataService.redemptions.first['code'], record['code']);
  });

  test('voucher codes follow the KRV-XXXX-XXXX format', () async {
    await seedBalance(2500);
    for (var i = 0; i < 20; i++) {
      final record = await DataService.redeemKTC(
        cost: 100,
        title: 'Local Market Voucher',
      );
      expect(record, isNotNull);
      expect(
        record!['code'],
        matches(RegExp(r'^KRV-[A-Z2-9]{4}-[A-Z2-9]{4}$')),
      );
    }
  });

  test('redeemKTC returns null and changes nothing when balance is short',
      () async {
    await seedBalance(90);

    final record = await DataService.redeemKTC(
      cost: 100,
      title: 'Local Market Voucher',
    );

    expect(record, isNull);
    expect(DataService.ktcBalance, 90);
    expect(DataService.redemptions, isEmpty);
  });

  test('redeemKTC rejects non-positive costs', () async {
    await seedBalance(100);

    final record = await DataService.redeemKTC(cost: 0, title: 'Nothing');

    expect(record, isNull);
    expect(DataService.ktcBalance, 100);
  });

  test('multiple redemptions deduct cumulatively and stay ordered', () async {
    await seedBalance(400);

    final first = await DataService.redeemKTC(
      cost: 100,
      title: 'Local Market Voucher',
    );
    final second = await DataService.redeemKTC(
      cost: 150,
      title: 'Gourmet Dessert Box',
    );

    expect(DataService.ktcBalance, 150);
    expect(DataService.redemptions, hasLength(2));
    // Newest redemption first.
    expect(DataService.redemptions[0]['code'], second!['code']);
    expect(DataService.redemptions[1]['code'], first!['code']);
  });
}
