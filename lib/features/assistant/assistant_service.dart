import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models.dart';
import '../../data/session.dart';

class AssistantAnswer {
  const AssistantAnswer(
    this.text, {
    this.products = const [],
    this.handoff = false,
  });
  final String text;
  final List<Product> products;
  final bool handoff;
}

typedef AssistantSend =
    Future<AssistantAnswer> Function(
      String message,
      List<Map<String, String>> history,
    );
Future<Product> loadAssistantProduct(String id) =>
    session.refreshProductById(id);
Future<AssistantAnswer> sendAssistantMessage(
  String message,
  List<Map<String, String>> history,
) async {
  final client = Supabase.instance.client;
  final owner = client.auth.currentUser?.id;
  if (owner == null || session.isGuest) {
    throw StateError('authentication_required');
  }
  final response = await client.functions
      .invoke(
        'lugta-assistant',
        body: {'message': message, 'history': history, 'consent': true},
      )
      .timeout(const Duration(seconds: 70));
  if (client.auth.currentUser?.id != owner || session.seller.id != owner) {
    throw StateError('session_changed');
  }
  final data = response.data;
  if (data is! Map || data['reply'] is! String) {
    throw StateError('invalid_response');
  }
  final ids =
      (data['product_ids'] is List ? data['product_ids'] as List : const [])
          .whereType<String>()
          .toSet()
          .take(4);
  final products = await Future.wait(
    ids.map((id) async {
      try {
        return await session
            .refreshProductById(id)
            .timeout(const Duration(seconds: 8));
      } catch (_) {
        return null;
      }
    }),
  );
  if (client.auth.currentUser?.id != owner || session.seller.id != owner) {
    throw StateError('session_changed');
  }
  return AssistantAnswer(
    data['reply'] as String,
    products: products.whereType<Product>().toList(),
    handoff: data['handoff'] == true,
  );
}
