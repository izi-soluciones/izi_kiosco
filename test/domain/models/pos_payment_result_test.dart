import 'package:flutter_test/flutter_test.dart';
import 'package:izi_kiosco/domain/models/pos_payment_result.dart';

void main() {
  group('PosPaymentResult.statusFromString', () {
    test('maps known statuses', () {
      expect(PosPaymentResult.statusFromString('SUCCESS'),
          PosPaymentStatus.success);
      expect(
          PosPaymentResult.statusFromString('ERROR'), PosPaymentStatus.error);
      expect(PosPaymentResult.statusFromString('CANCELLED'),
          PosPaymentStatus.cancelled);
      expect(PosPaymentResult.statusFromString('PENDING'),
          PosPaymentStatus.pending);
    });
    test('unknown or null -> unknown', () {
      expect(PosPaymentResult.statusFromString('whatever'),
          PosPaymentStatus.unknown);
      expect(PosPaymentResult.statusFromString(null), PosPaymentStatus.unknown);
    });
  });

  group('PosPaymentResult.fromJson', () {
    test('parses status and stringifies other fields', () {
      final r = PosPaymentResult.fromJson({
        'status': 'SUCCESS',
        'transactionId': 123,
        'errorMessage': null,
        'reference': 'ref-9',
      });
      expect(r.status, PosPaymentStatus.success);
      expect(r.transactionId, '123');
      expect(r.errorMessage, isNull);
      expect(r.reference, 'ref-9');
    });
  });

  group('PosPaymentResult.isTerminal', () {
    PosPaymentResult of(PosPaymentStatus s) => PosPaymentResult(status: s);
    test('success/error/cancelled/pending are terminal', () {
      expect(of(PosPaymentStatus.success).isTerminal, isTrue);
      expect(of(PosPaymentStatus.error).isTerminal, isTrue);
      expect(of(PosPaymentStatus.cancelled).isTerminal, isTrue);
      expect(of(PosPaymentStatus.pending).isTerminal, isTrue);
    });
    test('unknown is not terminal', () {
      expect(of(PosPaymentStatus.unknown).isTerminal, isFalse);
    });
  });
}
