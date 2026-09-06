import 'package:flutter_test/flutter_test.dart';
import 'package:savetep/features/auth/data/remote/business_api_models.dart';
import 'package:savetep/features/auth/data/remote/user_api_models.dart';

void main() {
  group('Me API DTOs', () {
    test('parses required and nullable response fields', () {
      final me = MeResponseDto.fromJson(<String, Object?>{
        'id': 'user-1',
        'email': 'owner@example.com',
        'name': null,
        'phone': '+1 555 0100',
        'locale': 'en-US',
        'createdAt': '2026-09-06T02:03:04.000Z',
      });

      expect(me.id, 'user-1');
      expect(me.email, 'owner@example.com');
      expect(me.name, isNull);
      expect(me.phone, '+1 555 0100');
      expect(me.locale, 'en-US');
      expect(me.createdAt.isUtc, isTrue);
    });

    test('update omits fields that are not being changed', () {
      const update = UpdateMeDto(name: 'Ada Owner', locale: 'en-US');

      expect(update.toJson(), <String, Object?>{
        'name': 'Ada Owner',
        'locale': 'en-US',
      });
    });

    test('rejects malformed required response fields', () {
      expect(
        () => MeResponseDto.fromJson(<String, Object?>{
          'id': 'user-1',
          'email': 'owner@example.com',
          'locale': 'en-US',
          'createdAt': 'not-a-date',
        }),
        throwsFormatException,
      );
    });
  });

  group('Business API DTOs', () {
    test('parses documented business fields and enum', () {
      final business = BusinessResponseDto.fromJson(_businessJson());

      expect(business.id, 'business-1');
      expect(business.name, 'Lotus Nails');
      expect(business.type, BusinessType.nailSalon);
      expect(business.rawType, 'NAIL_SALON');
      expect(business.currency, 'USD');
      expect(business.state, 'CA');
      expect(business.referralCode, isNull);
      expect(business.createdAt.isUtc, isTrue);
    });

    test(
      'retains an unknown server business type for forward compatibility',
      () {
        final json = _businessJson()..['type'] = 'MOBILE_SERVICE';

        final business = BusinessResponseDto.fromJson(json);

        expect(business.rawType, 'MOBILE_SERVICE');
        expect(business.type, isNull);
        expect(business.hasKnownType, isFalse);
        expect(business.toJson()['type'], 'MOBILE_SERVICE');
      },
    );

    test('create and update encode only fields supplied by Flutter', () {
      const create = CreateBusinessDto(
        name: 'Lotus Nails',
        type: BusinessType.nailSalon,
        currency: 'USD',
        timezone: 'America/Los_Angeles',
        state: 'CA',
      );
      const update = UpdateBusinessDto(name: 'Lotus Nails & Spa');

      expect(create.toJson(), <String, Object?>{
        'name': 'Lotus Nails',
        'type': 'NAIL_SALON',
        'currency': 'USD',
        'timezone': 'America/Los_Angeles',
        'state': 'CA',
      });
      expect(update.toJson(), <String, Object?>{'name': 'Lotus Nails & Spa'});
    });

    test('active-business response supports no selected business', () {
      final absent = ActiveBusinessResponseDto.fromJson(const <String, Object?>{
        'business': null,
      });
      final selected = ActiveBusinessResponseDto.fromJson(<String, Object?>{
        'business': _businessJson(),
      });

      expect(absent.business, isNull);
      expect(selected.business?.id, 'business-1');
    });

    test('parses deactivation disclosure without changing date semantics', () {
      final disclosure =
          DeactivationDisclosureResponseDto.fromJson(const <String, Object?>{
            'retentionDays': 30,
            'canReactivateUntil': '2026-10-06',
            'warningMessage': 'Data remains recoverable for 30 days.',
          });

      expect(disclosure.retentionDays, 30);
      expect(disclosure.canReactivateUntil, '2026-10-06');
      expect(disclosure.warningMessage, contains('recoverable'));
    });
  });
}

Map<String, Object?> _businessJson() => <String, Object?>{
  'id': 'business-1',
  'name': 'Lotus Nails',
  'type': 'NAIL_SALON',
  'currency': 'USD',
  'timezone': 'America/Los_Angeles',
  'state': 'CA',
  'referralCode': null,
  'createdAt': '2026-09-06T02:03:04.000Z',
  'updatedAt': '2026-09-06T03:04:05.000Z',
};
