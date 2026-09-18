import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../core/formatters.dart';
import '../../core/widgets/app_network_image.dart';
import '../../core/widgets/primary_button.dart';
import '../../data/models.dart';
import '../../data/session.dart';
import 'assistant_service.dart';
import 'assistant_strings.dart';

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({
    super.key,
    this.send = sendAssistantMessage,
    this.loadProduct = loadAssistantProduct,
  });
  final AssistantSend send;
  final Future<Product> Function(String) loadProduct;
  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _Turn {
  const _Turn(
    this.text, {
    this.mine = false,
    this.products = const [],
    this.handoff = false,
  });
  final String text;
  final bool mine;
  final List<Product> products;
  final bool handoff;
}

class _AssistantScreenState extends State<AssistantScreen> {
  final _draft = TextEditingController(), _scroll = ScrollController();
  final List<_Turn> _turns = [];
  bool _consented = false, _sending = false, _opening = false;
  String? _error;
  late final String _owner;
  bool _sessionInvalidated = false;
  @override
  void initState() {
    super.initState();
    _owner = session.seller.id;
    session.addListener(_sessionChanged);
  }

  void _sessionChanged() {
    if (session.seller.id != _owner && mounted) {
      setState(() {
        _sessionInvalidated = true;
        _turns.clear();
        _draft.clear();
        _consented = false;
        _sending = false;
        _error = null;
      });
    }
  }

  @override
  void dispose() {
    session.removeListener(_sessionChanged);
    _draft.dispose();
    _scroll.dispose();
    super.dispose();
  }

  bool get _current =>
      mounted && !_sessionInvalidated && session.seller.id == _owner;
  void _bottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  Future<void> _send() async {
    final message = _draft.text.trim();
    if (!_current || !_consented || _sending || message.isEmpty) return;
    final history = _turns
        .map((t) => {'role': t.mine ? 'user' : 'assistant', 'content': t.text})
        .toList();
    final pending = _Turn(message, mine: true);
    setState(() {
      _sending = true;
      _error = null;
      _turns.add(pending);
    });
    _bottom();
    try {
      final answer = await widget.send(
        message,
        history.length > 8 ? history.sublist(history.length - 8) : history,
      );
      if (!_current) return;
      setState(() {
        _draft.clear();
        _turns.add(
          _Turn(
            answer.text,
            products: answer.products,
            handoff: answer.handoff,
          ),
        );
        if (_turns.length > 60) _turns.removeRange(0, _turns.length - 60);
      });
      _bottom();
    } catch (e) {
      if (_current) {
        setState(() {
          _turns.remove(pending);
          _error = e is FunctionException && e.status == 429
              ? AssistantStrings.limited
              : AssistantStrings.error;
        });
      }
    } finally {
      if (_current) setState(() => _sending = false);
    }
  }

  Future<void> _open(Product product) async {
    if (_opening || !_current) return;
    setState(() => _opening = true);
    try {
      final fresh = await widget
          .loadProduct(product.id)
          .timeout(const Duration(seconds: 10));
      if (fresh.id != product.id) throw StateError('product_mismatch');
      if (mounted && _current) {
        await Navigator.pushNamed(
          context,
          Routes.productDetail,
          arguments: fresh,
        );
      }
    } catch (_) {
      if (mounted && _current) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AssistantStrings.unavailable)));
      }
    } finally {
      if (_current) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(AssistantStrings.title)),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: !_consented
                ? ListView(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    children: [
                      const Icon(Icons.chat_bubble_outline_rounded, size: 44),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        AssistantStrings.subtitle,
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        AssistantStrings.disclosure,
                        style: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      PrimaryButton(
                        label: AssistantStrings.start,
                        onPressed: () => setState(() => _consented = true),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          controller: _scroll,
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: const EdgeInsets.all(AppSpacing.md),
                          itemCount: _turns.isEmpty
                              ? 1
                              : _turns.length + (_sending ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (_turns.isEmpty) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AssistantStrings.welcome,
                                    style: theme.textTheme.bodyLarge,
                                  ),
                                  const SizedBox(height: AppSpacing.lg),
                                  for (final prompt in [
                                    AssistantStrings.discover,
                                    AssistantStrings.profit,
                                  ])
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: OutlinedButton(
                                        style: OutlinedButton.styleFrom(
                                          minimumSize: const Size(48, 48),
                                        ),
                                        onPressed: () {
                                          _draft.text = prompt;
                                          _send();
                                        },
                                        child: Text(prompt),
                                      ),
                                    ),
                                ],
                              );
                            }
                            if (index == _turns.length) {
                              return Semantics(
                                liveRegion: true,
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Text(AssistantStrings.thinking),
                                ),
                              );
                            }
                            final turn = _turns[index];
                            return Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.md,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Align(
                                    alignment: turn.mine
                                        ? AlignmentDirectional.centerEnd
                                        : AlignmentDirectional.centerStart,
                                    child: FractionallySizedBox(
                                      widthFactor: .9,
                                      child: Container(
                                        padding: const EdgeInsets.all(
                                          AppSpacing.md,
                                        ),
                                        decoration: BoxDecoration(
                                          color: turn.mine
                                              ? theme
                                                    .colorScheme
                                                    .primaryContainer
                                              : theme
                                                    .colorScheme
                                                    .surfaceContainerHighest,
                                          borderRadius: BorderRadius.circular(
                                            AppRadius.md,
                                          ),
                                        ),
                                        child: Text(
                                          turn.text,
                                          style: theme.textTheme.bodyLarge
                                              ?.copyWith(
                                                color: turn.mine
                                                    ? theme
                                                          .colorScheme
                                                          .onPrimaryContainer
                                                    : theme
                                                          .colorScheme
                                                          .onSurface,
                                              ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  for (final product in turn.products)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: AssistantProductRow(
                                        product: product,
                                        onOpen: _opening
                                            ? null
                                            : () => _open(product),
                                      ),
                                    ),
                                  if (turn.handoff)
                                    TextButton(
                                      onPressed: () => Navigator.pushNamed(
                                        context,
                                        Routes.support,
                                      ),
                                      style: TextButton.styleFrom(
                                        minimumSize: const Size(48, 48),
                                      ),
                                      child: Text(AssistantStrings.support),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Semantics(
                            liveRegion: true,
                            child: Text(
                              _error!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.error,
                              ),
                            ),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _draft,
                                enabled: !_sending,
                                maxLength: 1200,
                                minLines: 1,
                                maxLines: 4,
                                decoration: InputDecoration(
                                  labelText: AssistantStrings.hint,
                                  counterText: '',
                                ),
                                onSubmitted: (_) => _send(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton.filled(
                              tooltip: AssistantStrings.send,
                              style: IconButton.styleFrom(
                                foregroundColor: theme.colorScheme.onPrimary,
                                backgroundColor: theme.colorScheme.primary,
                                disabledForegroundColor: theme
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: .38),
                                disabledBackgroundColor: theme
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: .12),
                              ),
                              constraints: const BoxConstraints(
                                minHeight: 48,
                                minWidth: 48,
                              ),
                              onPressed: _sending ? null : _send,
                              icon: const Icon(Icons.send_rounded),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class AssistantProductRow extends StatelessWidget {
  const AssistantProductRow({
    super.key,
    required this.product,
    required this.onOpen,
  });
  final Product product;
  final VoidCallback? onOpen;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppNetworkImage(
                product.coverImage,
                width: 64,
                height: 64,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.localizedName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '${AssistantStrings.wholesale}: ${formatIqd(product.wholesalePrice)}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          TextButton(
            onPressed: onOpen,
            style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
            child: Text(AssistantStrings.openProduct),
          ),
        ],
      ),
    ),
  );
}
