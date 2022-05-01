import 'package:stocker/preferences/shared_preferences.dart';
import 'package:test/test.dart';

class Temp {}

void main() {
  group('checks save for values and read', () {
    for (var value in [1, 2, 0, 'ala ma kota', 1.1, 10e10, true, false]) {
      test('can save ${value.runtimeType}', () async {
        final instance = SharedPreferences();
        final result = await instance.save('savedValue', value);
        expect(result, true, reason: 'expected successful result of write');
        final fetchResult = await instance.get('savedValue');
        expect(
          fetchResult,
          value,
          reason: 'expected the same value after read from preferences',
        );
      });
    }
  });

  group('nulls and not primitive values are not allowed', () {
    for (var value in [null, {}, [], Temp()]) {
      test('save ${value.runtimeType}', () async {
        final instance = SharedPreferences();
        try {
          await instance.save('savedValue', value);
          fail('should not save value ${value}');
        } catch (e) {
          expect(
            e is NotPrimitiveType,
            true,
            reason: 'exception should be of type NotPrimitiveType',
          );
          expect(
            (e as NotPrimitiveType).type,
            value.runtimeType,
            reason: 'type should be the same as value to save type',
          );
        }
      });
    }
  });
}
