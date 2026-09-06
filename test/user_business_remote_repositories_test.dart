import 'dart:collection';

import 'package:flutter_test/flutter_test.dart';
import 'package:savetep/features/auth/data/remote/business_api_models.dart';
import 'package:savetep/features/auth/data/remote/user_api_models.dart';
import 'package:savetep/features/auth/data/remote/user_business_api_client.dart';
import 'package:savetep/features/auth/data/remote/user_business_remote_repositories.dart';

void main() {
  group('ApiMeRepository', () {
    test('GET /me sends the exact accepted terms version', () async {
      final client = _FakeUserBusinessApiClient(<UserBusinessApiResponse>[
        UserBusinessApiResponse(statusCode: 200, data: _meJson()),
      ]);
      final repository = ApiMeRepository(client);

      final me = await repository.fetchMe(acceptedTermsVersion: '2026-09-01');

      expect(me.id, 'user-1');
      expect(client.requests, hasLength(1));
      expect(client.requests.single.method, UserBusinessApiMethod.get);
      expect(client.requests.single.path, '/me');
      expect(client.requests.single.query, isEmpty);
      expect(client.requests.single.jsonBody, isNull);
      expect(client.requests.single.headers, <String, String>{
        'X-Terms-Version': '2026-09-01',
      });
    });

    test('GET /me omits terms header when no acceptance is pending', () async {
      final client = _FakeUserBusinessApiClient(<UserBusinessApiResponse>[
        UserBusinessApiResponse(statusCode: 200, data: _meJson()),
      ]);

      await ApiMeRepository(client).fetchMe();

      expect(client.requests.single.headers, isEmpty);
    });

    test('rejects an invalid terms header before making a request', () async {
      final client = _FakeUserBusinessApiClient(const []);

      await expectLater(
        ApiMeRepository(client).fetchMe(acceptedTermsVersion: ' '),
        throwsArgumentError,
      );
      expect(client.requests, isEmpty);
    });

    test('PATCH /me sends only fields selected for update', () async {
      final client = _FakeUserBusinessApiClient(<UserBusinessApiResponse>[
        UserBusinessApiResponse(statusCode: 200, data: _meJson()),
      ]);

      await ApiMeRepository(
        client,
      ).updateMe(const UpdateMeDto(name: 'Ada', locale: 'en-US'));

      final request = client.requests.single;
      expect(request.method, UserBusinessApiMethod.patch);
      expect(request.path, '/me');
      expect(request.headers, isEmpty);
      expect(request.jsonBody, <String, Object?>{
        'name': 'Ada',
        'locale': 'en-US',
      });
    });
  });

  group('ApiBusinessRepository', () {
    test('lists and creates businesses using documented contracts', () async {
      final client = _FakeUserBusinessApiClient(<UserBusinessApiResponse>[
        UserBusinessApiResponse(
          statusCode: 200,
          data: <Object?>[_businessJson()],
        ),
        UserBusinessApiResponse(statusCode: 201, data: _businessJson()),
      ]);
      final repository = ApiBusinessRepository(client);

      final businesses = await repository.listBusinesses();
      final created = await repository.createBusiness(
        const CreateBusinessDto(
          name: 'Lotus Nails',
          type: BusinessType.nailSalon,
          currency: 'USD',
        ),
      );

      expect(businesses.single.id, 'business-1');
      expect(created.id, 'business-1');
      expect(client.requests[0].method, UserBusinessApiMethod.get);
      expect(client.requests[0].path, '/businesses');
      expect(client.requests[1].method, UserBusinessApiMethod.post);
      expect(client.requests[1].path, '/businesses');
      expect(client.requests[1].jsonBody, <String, Object?>{
        'name': 'Lotus Nails',
        'type': 'NAIL_SALON',
        'currency': 'USD',
      });
    });

    test('gets and patches an encoded business path', () async {
      final client = _FakeUserBusinessApiClient(<UserBusinessApiResponse>[
        UserBusinessApiResponse(statusCode: 200, data: _businessJson()),
        UserBusinessApiResponse(statusCode: 200, data: _businessJson()),
      ]);
      final repository = ApiBusinessRepository(client);

      await repository.getBusiness('business/id');
      await repository.updateBusiness(
        'business/id',
        const UpdateBusinessDto(timezone: 'America/Los_Angeles'),
      );

      expect(client.requests[0].path, '/businesses/business%2Fid');
      expect(client.requests[0].method, UserBusinessApiMethod.get);
      expect(client.requests[1].path, '/businesses/business%2Fid');
      expect(client.requests[1].method, UserBusinessApiMethod.patch);
      expect(client.requests[1].jsonBody, <String, Object?>{
        'timezone': 'America/Los_Angeles',
      });
    });

    test('fetches disclosure and explicitly confirms deactivation', () async {
      final client = _FakeUserBusinessApiClient(const <UserBusinessApiResponse>[
        UserBusinessApiResponse(
          statusCode: 200,
          data: <String, Object?>{
            'retentionDays': 30,
            'canReactivateUntil': '2026-10-06',
            'warningMessage': 'This deactivates the business.',
          },
        ),
        UserBusinessApiResponse(statusCode: 204),
      ]);
      final repository = ApiBusinessRepository(client);

      final disclosure = await repository.getDeactivationDisclosure(
        'business-1',
      );
      await repository.deactivateBusiness(
        'business-1',
        const DeactivateBusinessDto(confirm: true),
      );

      expect(disclosure.retentionDays, 30);
      expect(
        client.requests[0].path,
        '/businesses/business-1/deactivation-disclosure',
      );
      expect(client.requests[1].method, UserBusinessApiMethod.delete);
      expect(client.requests[1].path, '/businesses/business-1');
      expect(client.requests[1].jsonBody, <String, Object?>{'confirm': true});
    });

    test('rejects an undocumented status instead of parsing it as success', () {
      final client = _FakeUserBusinessApiClient(const <UserBusinessApiResponse>[
        UserBusinessApiResponse(statusCode: 202, data: <Object?>[]),
      ]);

      expect(
        ApiBusinessRepository(client).listBusinesses(),
        throwsA(
          isA<UserBusinessApiProtocolException>()
              .having((error) => error.statusCode, 'statusCode', 202)
              .having(
                (error) => error.operation,
                'operation',
                'GET /businesses',
              ),
        ),
      );
    });
  });

  group('ApiActiveBusinessRepository', () {
    test('gets an explicitly empty active-business context', () async {
      final client = _FakeUserBusinessApiClient(const <UserBusinessApiResponse>[
        UserBusinessApiResponse(
          statusCode: 200,
          data: <String, Object?>{'business': null},
        ),
      ]);

      final active = await ApiActiveBusinessRepository(
        client,
      ).getActiveBusiness();

      expect(active.business, isNull);
      expect(client.requests.single.method, UserBusinessApiMethod.get);
      expect(client.requests.single.path, '/me/active-business');
    });

    test(
      'sets an active business with PUT and the server business ID',
      () async {
        final client = _FakeUserBusinessApiClient(<UserBusinessApiResponse>[
          UserBusinessApiResponse(
            statusCode: 200,
            data: <String, Object?>{'business': _businessJson()},
          ),
        ]);

        final active = await ApiActiveBusinessRepository(
          client,
        ).setActiveBusiness('business-1');

        expect(active.business?.id, 'business-1');
        expect(client.requests.single.method, UserBusinessApiMethod.put);
        expect(client.requests.single.path, '/me/active-business');
        expect(client.requests.single.jsonBody, <String, Object?>{
          'businessId': 'business-1',
        });
      },
    );
  });
}

class _FakeUserBusinessApiClient implements UserBusinessApiClient {
  final Queue<UserBusinessApiResponse> _responses;
  final List<UserBusinessApiRequest> requests = <UserBusinessApiRequest>[];

  _FakeUserBusinessApiClient(Iterable<UserBusinessApiResponse> responses)
    : _responses = Queue<UserBusinessApiResponse>.from(responses);

  @override
  Future<UserBusinessApiResponse> send(UserBusinessApiRequest request) async {
    requests.add(request);
    if (_responses.isEmpty) {
      throw StateError('No fake response was queued.');
    }
    return _responses.removeFirst();
  }
}

Map<String, Object?> _meJson() => <String, Object?>{
  'id': 'user-1',
  'email': 'owner@example.com',
  'name': 'Ada Owner',
  'phone': null,
  'locale': 'en-US',
  'createdAt': '2026-09-06T02:03:04.000Z',
};

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
