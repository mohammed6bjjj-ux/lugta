import 'dart:convert';

import 'package:flutter_app/data/models.dart';
import 'package:flutter_app/data/repositories/supabase_repositories.dart';
import 'package:flutter_app/data/repositories/repositories.dart';
import 'package:flutter_app/data/session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _Auth extends GoTrueClient {
  _Auth() : super(autoRefreshToken: false);
  @override
  User? get currentUser => const User(
    id: 'owner',
    appMetadata: {},
    userMetadata: {},
    aud: 'authenticated',
    createdAt: '2026-01-01T00:00:00Z',
  );
}

class _Client extends SupabaseClient {
  _Client(http.Client transport)
    : super(
        'https://example.invalid',
        'test-key',
        httpClient: transport,
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      );
  final _testAuth = _Auth();
  @override
  GoTrueClient get auth => _testAuth;
}

Map<String, dynamic> row(String id, int priority, {bool read = false}) => {
  'id': id,
  'recipient_id': 'owner',
  'title_ar': id,
  'body_ar': 'body',
  'notification_type': 'promotion',
  'created_at': id == 'old-first'
      ? '2020-01-01T00:00:00Z'
      : '2026-01-01T00:00:00Z',
  'read_at': read ? '2026-01-02T00:00:00Z' : null,
  'payload': {'show_popup': true, 'popup_priority': priority},
};

void main() {
  tearDown(() => session.notifications = []);

  test(
    'pending priority survives latest-200 boundary and overlap stays read',
    () async {
      final requests = <Uri>[];
      final client = _Client(
        MockClient((request) async {
          requests.add(request.url);
          final query = request.url.queryParameters;
          expect(query['recipient_id'], 'eq.owner');
          expect(query['limit'], '200');
          final pending = query.containsKey('popup_seen_at');
          if (pending) {
            expect(query['read_at'], 'is.null');
            expect(query['popup_seen_at'], 'is.null');
            expect(query['payload->>show_popup'], 'eq.true');
            expect(query['order'], startsWith('payload->popup_priority.desc'));
            expect(request.url.queryParametersAll['or'], hasLength(2));
          }
          return http.Response(
            jsonEncode(
              pending
                  ? [
                      row('old-first', 99999),
                      row('overlap', 99998),
                      row('newer', 2),
                    ]
                  : [
                      for (var i = 0; i < 198; i++)
                        {...row('ordinary-$i', 0), 'payload': {}},
                      row('overlap', 1, read: true),
                      row('newer', 1),
                    ],
            ),
            200,
            request: request,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      addTearDown(client.dispose);
      late List<AppNotification> items;
      try {
        items = await SupabaseNotificationsRepository(
          client,
        ).fetchNotifications();
      } on BackendException catch (error) {
        fail(
          'Notification read failed: ${error.cause}\n${error.cause is Error ? (error.cause as Error).stackTrace : ""}',
        );
      }
      expect(requests, hasLength(2));
      expect(items, hasLength(201));
      expect(items.where((item) => item.id == 'overlap').single.isRead, isTrue);
      expect(items.where((item) => item.id == 'newer').single.popupPriority, 2);
      session.notifications = items;
      expect(session.nextPopupNotification?.id, 'old-first');
    },
  );

  test(
    'priority is deterministic and never revives seen, expired or read cards',
    () {
      AppNotification item(
        String id,
        int priority, {
        bool read = false,
        bool seen = false,
        bool expired = false,
      }) => AppNotification(
        id: id,
        title: id,
        body: '',
        type: NotificationType.promotion,
        at: DateTime.utc(2026),
        showPopup: true,
        popupPriority: priority,
        isRead: read,
        popupSeenAt: seen ? DateTime.utc(2026) : null,
        expiresAt: expired ? DateTime.utc(2020) : null,
      );
      session.notifications = [
        item('z', 5),
        item('a', 5),
        item('read', 99, read: true),
        item('seen', 99, seen: true),
        item('expired', 99, expired: true),
      ];
      expect(session.nextPopupNotification?.id, 'a');
      session.notifications = [item('z', 20), item('a', 5)];
      expect(session.nextPopupNotification?.id, 'z');
    },
  );
}
