import 'package:flutter_test/flutter_test.dart';
import 'package:izi_kiosco/domain/utils/input_obj.dart';

// A simple validator: non-empty required, else null.
InputError? requiredValidator(String v) =>
    v.isEmpty ? InputError.required : null;

void main() {
  group('InputObj.changeValue', () {
    test('updates value and preserves validator', () {
      const input = InputObj(value: 'a', validator: requiredValidator);
      final next = input.changeValue('hello');
      expect(next.value, 'hello');
    });
    test('resets loading to its default (false)', () {
      const input = InputObj(
          value: 'a', validator: requiredValidator, loading: true);
      expect(input.changeValue('b').loading, isFalse);
    });
  });

  group('InputObj.changeLoading', () {
    test('sets loading and keeps the value', () {
      const input = InputObj(value: 'x', validator: requiredValidator);
      final next = input.changeLoading(true);
      expect(next.loading, isTrue);
      expect(next.value, 'x');
    });
    test('falls back to current loading when null passed', () {
      const input = InputObj(
          value: 'x', validator: requiredValidator, loading: true);
      expect(input.changeLoading(null).loading, isTrue);
    });
  });

  group('InputObj.validateError', () {
    test('sets the error returned by the validator', () {
      const input = InputObj(value: '', validator: requiredValidator);
      expect(input.validateError().inputError, InputError.required);
    });
    test('clears error for valid input', () {
      const input = InputObj(value: 'ok', validator: requiredValidator);
      expect(input.validateError().inputError, isNull);
    });
    test('skips validation (no error) when valueRequired is empty', () {
      const input = InputObj(value: '', validator: requiredValidator);
      expect(input.validateError(valueRequired: '').inputError, isNull);
    });
    test('runs validation when valueRequired is non-empty', () {
      const input = InputObj(value: '', validator: requiredValidator);
      expect(input.validateError(valueRequired: 'x').inputError,
          InputError.required);
    });
  });

  group('InputObj.copyWith', () {
    test('overrides value only', () {
      const input = InputObj(value: 'a', validator: requiredValidator);
      expect(input.copyWith(value: 'b').value, 'b');
    });
    test('sets inputError via the callback form', () {
      const input = InputObj(value: 'a', validator: requiredValidator);
      final next = input.copyWith(inputError: () => InputError.invalid);
      expect(next.inputError, InputError.invalid);
    });
  });

  group('InputObj equality', () {
    test('equal when value, inputError and loading match', () {
      const a = InputObj(value: 'x', validator: requiredValidator);
      const b = InputObj(value: 'x', validator: requiredValidator);
      expect(a, equals(b));
    });
    test('not equal when value differs', () {
      const a = InputObj(value: 'x', validator: requiredValidator);
      const b = InputObj(value: 'y', validator: requiredValidator);
      expect(a, isNot(equals(b)));
    });
  });
}
