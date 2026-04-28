import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/score_service.dart';
import '../services/purchase_service.dart';
import '../models/score.dart';
import 'score_detail_screen.dart';

class ScoresScreen extends StatefulWidget {
  const ScoresScreen({super.key});

  @override
  State<ScoresScreen> createState() => _ScoresScreenState();
}

class _ScoresScreenState extends State<ScoresScreen> {
  final _service = ScoreService();
  final _purchases = PurchaseService();

  @override
  void initState() {
    super.initState();
    _purchases.addListener(_onPurchaseChange);
  }

  @override
  void dispose() {
    _purchases.removeListener(_onPurchaseChange);
    super.dispose();
  }

  void _onPurchaseChange() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: StreamBuilder<List<Score>>(
        stream: _service.getScores(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Erro: ${snapshot.error}',
                style: const TextStyle(color: Colors.red, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            );
          }

          final scores = snapshot.data ?? [];

          if (scores.isEmpty) {
            return Center(
              child: Text(
                'Nenhuma cifra cadastrada.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.textDim, fontStyle: FontStyle.italic),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: scores.length,
            itemBuilder: (context, index) {
              final score = scores[index];
              final hasAccess = _purchases.hasAccess(score);
              return _scoreCard(score, hasAccess);
            },
          );
        },
      ),
    );
  }

  Widget _scoreCard(Score score, bool hasAccess) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: AppColors.border),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            if (hasAccess) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ScoreDetailScreen(score: score),
                ),
              );
            } else {
              _showBuyDialog(score);
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(score.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: hasAccess ? AppColors.text : const Color(0xFF555555),
                          )),
                      const SizedBox(height: 4),
                      Text(score.artist,
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                if (!hasAccess) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'R\$ ${score.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.lock, size: 16, color: Color(0xFF555555)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLoginSuccess({VoidCallback? then}) {
    final auth = AuthService();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Login realizado com sucesso',
            style: TextStyle(color: AppColors.text, fontSize: 18)),
        content: Text(
          auth.displayName ?? auth.email ?? '',
          style: const TextStyle(color: AppColors.textDim),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {});
              then?.call();
            },
            child: const Text('OK', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showBuyDialog(Score score) {
    final auth = AuthService();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(score.title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(score.artist,
                style: const TextStyle(fontSize: 14, color: AppColors.textDim)),
            const SizedBox(height: 16),
            Text(
              'R\$ ${score.price.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w300,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(height: 24),
            if (!auth.isSignedIn) ...[
              const Text(
                'Entre com sua conta Google para\nsalvar a compra de forma segura.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.textDim),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () async {
                    final success = await auth.signInWithGoogle();
                    if (success) {
                      await _purchases.reloadPurchases();
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        _showLoginSuccess(then: () {
                          if (!_purchases.hasAccess(score)) {
                            _showBuyDialog(score);
                          }
                        });
                      }
                    }
                  },
                  icon: const Icon(Icons.login),
                  label: const Text('Entrar com Google'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.black,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () async {
                  final success = await auth.signInWithGoogle();
                  if (success) {
                    await _purchases.reloadPurchases();
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      _showLoginSuccess();
                    }
                  }
                },
                child: const Text(
                  'Já comprou? Restaurar compras',
                  style: TextStyle(fontSize: 13, color: AppColors.textDim),
                ),
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _purchases.buyScore(score);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.black,
                  ),
                  child: const Text('Comprar'),
                ),
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
