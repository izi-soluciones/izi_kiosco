import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:izi_kiosco/domain/utils/print_utils.dart';
import 'package:izi_kiosco/domain/utils/print/print_template.dart';

void main() {
  group('IziPrintItem.fromJson', () {
    test('returns null for non-map input', () {
      expect(IziPrintItem.fromJson('nope'), isNull);
      expect(IziPrintItem.fromJson(null), isNull);
    });
    test('returns null for an unknown type', () {
      expect(IziPrintItem.fromJson({'type': 'banana'}), isNull);
    });

    test('parses a text item with size, bold and align', () {
      final item = IziPrintItem.fromJson({
        'type': 'text',
        'text': 'Hello',
        'size': 'lg',
        'bold': true,
        'align': 'center',
      });
      expect(item, isA<IziPrintText>());
      final text = item as IziPrintText;
      expect(text.text, 'Hello');
      expect(text.size, IziPrintSize.lg);
      expect(text.bold, isTrue);
      expect(text.align, IziPrintAlign.center);
    });

    test('text defaults: unknown size -> sm, missing align -> left', () {
      final text = IziPrintItem.fromJson({'type': 'text'}) as IziPrintText;
      expect(text.text, '');
      expect(text.size, IziPrintSize.sm);
      expect(text.bold, isFalse);
      expect(text.align, IziPrintAlign.left);
    });

    test('parses a row with columns', () {
      final row = IziPrintItem.fromJson({
        'type': 'row',
        'size': 'md',
        'bold': true,
        'cols': [
          {'text': 'A', 'width': 2, 'align': 'right'},
          {'text': 'B', 'width': 4},
          'not-a-map',
        ],
      }) as IziPrintRow;
      expect(row.size, IziPrintSize.md);
      expect(row.bold, isTrue);
      expect(row.values.length, 2); // the non-map entry is skipped
      expect(row.values.first.text, 'A');
      expect(row.values.first.width, 2);
      expect(row.values.first.align, IziPrintAlign.right);
      expect(row.values[1].align, IziPrintAlign.left); // default
    });

    test('parses a separator', () {
      final sep =
          IziPrintItem.fromJson({'type': 'separator', 'dotted': true})
              as IziPrintSeparator;
      expect(sep.dotted, isTrue);
    });

    test('lineWrap defaults to 1 line when missing', () {
      final lw =
          IziPrintItem.fromJson({'type': 'lineWrap'}) as IziPrintLineWrap;
      expect(lw.lines, 1);
      final lw3 = IziPrintItem.fromJson({'type': 'lineWrap', 'lines': 3})
          as IziPrintLineWrap;
      expect(lw3.lines, 3);
    });

    test('parses a qr with content and default size', () {
      final qr =
          IziPrintItem.fromJson({'type': 'qr', 'content': 'x'}) as IziPrintQR;
      expect(qr.qrContent, 'x');
      expect(qr.size, 2);
    });

    test('parses an image from base64', () {
      final b64 = base64Encode([1, 2, 3, 4]);
      final img =
          IziPrintItem.fromJson({'type': 'image', 'data': b64}) as IziPrintImage;
      expect(img.image, [1, 2, 3, 4]);
      expect(img.size, 70);
    });

    test('returns null for an image with invalid base64', () {
      expect(
          IziPrintItem.fromJson({'type': 'image', 'data': '!!!notb64!!!'}),
          isNull);
    });

    test('parses a cut item', () {
      expect(IziPrintItem.fromJson({'type': 'cut'}), isA<IziPrintCut>());
    });
  });

  group('IziPrintItem.listFromJson', () {
    test('maps valid items and drops null (invalid) entries', () {
      final list = IziPrintItem.listFromJson([
        {'type': 'text', 'text': 'a'},
        {'type': 'unknown'},
        {'type': 'cut'},
      ]);
      expect(list.length, 2);
      expect(list[0], isA<IziPrintText>());
      expect(list[1], isA<IziPrintCut>());
    });
  });

  group('StringExtension.capitalize', () {
    test('capitalizes first letter and lowercases the rest', () {
      expect('hELLO'.capitalize(), 'Hello');
      expect('a'.capitalize(), 'A');
      expect('WORLD'.capitalize(), 'World');
    });
  });
}
