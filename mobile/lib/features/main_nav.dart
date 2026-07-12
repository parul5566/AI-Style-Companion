/// Main navigation shell — bottom nav bar with 6 tabs.
import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../dashboard/dashboard_screen.dart';
import '../wardrobe/wardrobe_screen.dart';
import '../stylist/stylist_screen.dart';
import '../stylist/tryon_screen.dart';
import '../stylist/shopping_screen.dart';
import '../chat/chat_screen.dart';
import '../profile/profile_screen.dart';

class MainNav extends StatefulWidget {
  const MainNav({super.key});

  @override
  State<MainNav> createState() => _MainNavState();
}

class _MainNavState extends State<MainNav> {
  int _currentIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      DashboardScreen(
        onNavigateWardrobe: () => setState(() => _currentIndex = 1),
        onNavigateStylist: () => setState(() => _currentIndex = 2),
        onNavigateChat: () => _navigateTo(4),
        onNavigateShopping: () => setState(() => _currentIndex = 5),
        onNavigateTryOn: () => setState(() => _currentIndex = 3),
        onNavigateSubscription: () {
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => const SubscriptionScreen(),
          ));
        },
      ),
      const WardrobeScreen(),
      const StylistScreen(),
      const TryOnScreen(),
      const ChatScreen(),
      const ShoppingScreen(),
    ];
  }

  void _navigateTo(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex > 5 ? 0 : _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.checkroom_outlined), activeIcon: Icon(Icons.checkroom), label: 'Wardrobe'),
            BottomNavigationBarItem(icon: Icon(Icons.auto_awesome_outlined), activeIcon: Icon(Icons.auto_awesome), label: 'Stylist'),
            BottomNavigationBarItem(icon: Icon(Icons.face_retouching_natural_outlined), activeIcon: Icon(Icons.face_retouching_natural), label: 'Try-On'),
            BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), activeIcon: Icon(Icons.chat_bubble), label: 'Chat'),
            BottomNavigationBarItem(icon: Icon(Icons.shopping_bag_outlined), activeIcon: Icon(Icons.shopping_bag), label: 'Shop'),
          ],
        ),
      ),
    );
  }
}
