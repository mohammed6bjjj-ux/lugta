import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../data/session.dart';

void openAuthenticatedDestination(BuildContext context) {
  final (route, arguments) = switch (session.destination) {
    SessionDestination.shell => (Routes.shell, null),
    SessionDestination.pendingApproval => (Routes.pendingApproval, null),
    SessionDestination.rejected => (
      Routes.accountBlocked,
      {
        'isRejected': true,
        'reason': session.seller.statusReason ?? 'تم رفض طلب التسجيل.',
      },
    ),
    SessionDestination.blocked => (
      Routes.accountBlocked,
      {
        'isRejected': false,
        'reason': session.seller.statusReason ?? 'تم إيقاف الحساب مؤقتاً.',
      },
    ),
    SessionDestination.deleted => (Routes.accountDeleted, null),
    SessionDestination.onboarding => (Routes.onboarding, null),
  };
  Navigator.pushNamedAndRemoveUntil(
    context,
    route,
    (route) => false,
    arguments: arguments,
  );
}
