import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/premium_service.dart';
import '../services/purchase_service.dart';
import '../theme/app_theme.dart';
import 'teoria_screen.dart';
import 'tuner_screen.dart';
import 'scores_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tabIndex = 0;
  final _auth = AuthService();

  final _screens = const [
    TeoriaScreen(),
    TunerScreen(),
    ScoresScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _auth.addListener(_onAuthChanged);
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() => setState(() {});

  void _showAccountSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const _AccountSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_tabIndex],
      floatingActionButton: GestureDetector(
            onTap: _auth.isSignedIn
                ? _showAccountSheet
                : () => _auth.signInWithGoogle(),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surface,
                border: Border.all(color: AppColors.accent, width: 2),
                image: _auth.photoUrl != null
                    ? DecorationImage(
                        image: NetworkImage(_auth.photoUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: _auth.photoUrl == null
                  ? const Icon(Icons.person, color: AppColors.text)
                  : null,
            ),
          ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.accent,
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.music_note_outlined),
            selectedIcon: Icon(Icons.music_note, color: AppColors.black),
            label: 'Teoria',
          ),
          NavigationDestination(
            icon: Icon(Icons.graphic_eq),
            selectedIcon: Icon(Icons.graphic_eq, color: AppColors.black),
            label: 'Afinador',
          ),
          NavigationDestination(
            icon: Icon(Icons.queue_music_outlined),
            selectedIcon: Icon(Icons.queue_music, color: AppColors.black),
            label: 'Cifras',
          ),
        ],
      ),
    );
  }
}

class _AccountSheet extends StatelessWidget {
  const _AccountSheet();

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    final premium = PremiumService();
    final purchases = PurchaseService();
    final purchasedIds = purchases.purchasedProductIds;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 32,
            backgroundImage: auth.photoUrl != null
                ? NetworkImage(auth.photoUrl!)
                : null,
            backgroundColor: AppColors.accent,
            child: auth.photoUrl == null
                ? const Icon(Icons.person, size: 32, color: AppColors.black)
                : null,
          ),
          const SizedBox(height: 12),
          Text(
            auth.displayName ?? '',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          Text(
            auth.email ?? '',
            style: const TextStyle(fontSize: 14, color: AppColors.textDim),
          ),
          const SizedBox(height: 20),
          _statusRow(
            'Premium',
            premium.isPremium ? 'Ativo' : 'Inativo',
            premium.isPremium ? const Color(0xFF4CAF50) : AppColors.textDim,
          ),
          _statusRow(
            'Cifras',
            '${purchasedIds.length} na biblioteca',
            AppColors.textDim,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () async {
                Navigator.pop(context);
                await auth.signOut();
                PremiumService().setPremium(false);
                await PurchaseService().reloadPurchases();
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.border),
              ),
              child: const Text('Sair da conta'),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _statusRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: AppColors.text)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: valueColor.withAlpha(30),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }
}
