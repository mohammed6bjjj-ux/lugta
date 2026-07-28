import 'dart:async';

import 'package:flutter_app/data/models.dart';
import 'package:flutter_app/data/repositories/demo_repositories.dart';
import 'package:flutter_app/data/repositories/repositories.dart';
import 'package:flutter_app/data/services/device_token_registrar.dart';
import 'package:flutter_app/data/session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _ControllableAuthRepository auth;

  tearDown(() async {
    await session.configure(createDemoRepositories(), loadInitialData: false);
    await auth.dispose();
  });

  test('failed remote sign-out still clears all local account data', () async {
    auth = _ControllableAuthRepository('user-a')..failSignOut = true;
    final profile = _ControllableProfileRepository(auth);
    await session.configure(
      _repositories(auth: auth, profile: profile),
      loadInitialData: false,
    );
    await session.refreshAuthenticatedData();

    expect(session.seller.id, 'user-a');
    expect(session.orders, isNotEmpty);

    await expectLater(session.signOut(), throwsStateError);

    expect(session.seller.id, isEmpty);
    expect(session.orders, isEmpty);
    expect(session.products, isEmpty);
    expect(session.notifications, isEmpty);
    expect(session.availableBalance, 0);
  });

  test('external auth loss invalidates this device push token', () async {
    auth = _ControllableAuthRepository('user-a');
    final deviceTokens = _TrackingDeviceTokens();
    await session.configure(
      _repositories(auth: auth, profile: _ControllableProfileRepository(auth)),
      deviceTokens: deviceTokens,
      loadInitialData: false,
    );

    auth.switchUser(null);
    await pumpEventQueue();

    expect(deviceTokens.unregisterCalls, 1);
    expect(session.isAuthenticated, isFalse);
  });

  test('an old account refresh cannot overwrite the new account', () async {
    auth = _ControllableAuthRepository('user-a');
    final profile = _ControllableProfileRepository(auth, pauseUserA: true);
    addTearDown(profile.releaseUserA);
    await session.configure(
      _repositories(auth: auth, profile: profile),
      loadInitialData: false,
    );

    final userARefresh = session.refreshAuthenticatedData();
    await profile.userARequestStarted.future;

    auth.switchUser('user-b');
    final userBRefresh = session.refreshAuthenticatedData();
    await userBRefresh.timeout(const Duration(seconds: 2));

    expect(session.seller.id, 'user-b');
    expect(session.seller.name, 'Seller user-b');
    expect(profile.requestedUsers, ['user-a', 'user-b']);

    profile.releaseUserA();
    await userARefresh;

    expect(session.seller.id, 'user-b');
    expect(session.seller.name, 'Seller user-b');
    expect(profile.requestedUsers, ['user-a', 'user-b']);
  });
}

AppRepositories _repositories({
  required AuthRepository auth,
  required ProfileRepository profile,
}) {
  final demo = createDemoRepositories();
  return AppRepositories(
    auth: auth,
    profile: profile,
    catalog: demo.catalog,
    orders: demo.orders,
    wallet: demo.wallet,
    notifications: demo.notifications,
    isDemo: false,
  );
}

class _ControllableAuthRepository implements AuthRepository {
  _ControllableAuthRepository(this._userId);

  final StreamController<String?> _changes =
      StreamController<String?>.broadcast(sync: true);
  String? _userId;
  bool failSignOut = false;

  @override
  bool get hasSession => _userId != null;

  @override
  String? get currentUserId => _userId;

  @override
  Stream<String?> get userIdChanges => _changes.stream;

  void switchUser(String? userId) {
    _userId = userId;
    _changes.add(userId);
  }

  @override
  Future<void> signOut() async {
    switchUser(null);
    if (failSignOut) throw StateError('remote sign-out failed');
  }

  Future<void> dispose() => _changes.close();

  @override
  Future<bool> completePendingRegistration() async => false;

  @override
  Future<void> resendOtp({
    required String phone,
    required OtpPurpose purpose,
  }) async {}

  @override
  Future<void> sendPasswordRecoveryOtp(String phone) async {}

  @override
  Future<void> signIn({
    required String phone,
    required String password,
  }) async {}

  @override
  Future<void> signUp(RegistrationRequest request) async {}

  @override
  Future<void> updatePassword(String newPassword) async {}

  @override
  Future<void> abandonPasswordRecovery() async {}

  @override
  Future<void> verifyOtp({
    required String phone,
    required String token,
    required OtpPurpose purpose,
  }) async {}
}

class _ControllableProfileRepository implements ProfileRepository {
  _ControllableProfileRepository(this.auth, {this.pauseUserA = false});

  final _ControllableAuthRepository auth;
  final bool pauseUserA;
  final Completer<void> userARequestStarted = Completer<void>();
  final Completer<void> _userARelease = Completer<void>();
  final List<String> requestedUsers = [];

  void releaseUserA() {
    if (!_userARelease.isCompleted) _userARelease.complete();
  }

  @override
  Future<Seller> fetchCurrentProfile() async {
    final requestedUser = auth.currentUserId!;
    requestedUsers.add(requestedUser);
    if (requestedUser == 'user-a' && pauseUserA) {
      if (!userARequestStarted.isCompleted) userARequestStarted.complete();
      await _userARelease.future;
    }
    return _seller(requestedUser);
  }

  @override
  Future<AccountDeletionRequest?> fetchLatestAccountDeletionRequest() async =>
      null;

  @override
  Future<Seller> updateCurrentProfile({
    required String name,
    required String storeName,
    required String instagramUrl,
  }) async => _seller(
    auth.currentUserId!,
  ).copyWith(name: name, storeName: storeName, instagramUrl: instagramUrl);

  @override
  Future<Seller> updateSettings({
    required String locale,
    required Map<String, bool> notificationPreferences,
  }) async => _seller(
    auth.currentUserId!,
  ).copyWith(locale: locale, notificationPreferences: notificationPreferences);

  @override
  Future<AccountDeletionRequest> requestAccountDeletion({
    required String reason,
    required String clientRequestId,
  }) => throw UnimplementedError();

  @override
  Future<AccountDeletionRequest> cancelAccountDeletion({
    required String requestId,
    required String clientRequestId,
  }) => throw UnimplementedError();

  @override
  Future<void> touchLastActive() async {}

  Seller _seller(String userId) => Seller(
    id: userId,
    name: 'Seller $userId',
    phone: userId == 'user-a' ? '+9647700000001' : '+9647700000002',
    storeName: 'Store $userId',
    instagramUrl: '',
    governorateId: 'baghdad',
    status: AccountStatus.approved,
    joinedAt: DateTime.utc(2026),
  );
}

class _TrackingDeviceTokens extends NoopDeviceTokenRegistrar {
  int unregisterCalls = 0;

  @override
  Future<void> unregisterCurrentDevice() async {
    unregisterCalls += 1;
  }
}
