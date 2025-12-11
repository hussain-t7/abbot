import 'package:abbot/screen/form_screen/stock_form.dart';
import 'package:abbot/screen/form_screen/user_form.dart';
import 'package:abbot/screen/invoice.dart';
import 'package:abbot/screen/list_user.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MainNav extends StatefulWidget {
  const MainNav({super.key});

  @override
  State<MainNav> createState() => _MainNavState();
}

class _MainNavState extends State<MainNav> {
  int _index = 0;

  void _onTabTapped(int index) {
    if (index != _index && mounted) {
      setState(() => _index = index);
    }
  }

  List<Widget> get _pages => [
    KeyedSubtree(key: const ValueKey(0), child: AddUserScreen()),
    KeyedSubtree(key: const ValueKey(1), child: TradeExitForm()),
    KeyedSubtree(key: const ValueKey(2), child: CustomerListScreen()),
    KeyedSubtree(key: const ValueKey(3), child: InvoicePage()),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
              child: ScaleTransition(
                scale: Tween(begin: 0.92, end: 1.0).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
                ),
                child: child,
              ),
            );
          },
          child: _pages[_index],
        ),
      ),

      // 🔥 IMPROVED BOTTOM NAVIGATION BAR
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 14,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Theme(
            data: Theme.of(context).copyWith(
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              splashFactory: NoSplash.splashFactory,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Responsive font sizes based on screen width
                final isSmallScreen = constraints.maxWidth < 360;
                final selectedFontSize = isSmallScreen ? 11.0 : 13.0;
                final unselectedFontSize = isSmallScreen ? 9.0 : 11.0;
                
                return BottomNavigationBar(
                  currentIndex: _index,
                  backgroundColor: Colors.white,
                  type: BottomNavigationBarType.fixed,
                  selectedItemColor: const Color(0xff1A57E8),
                  unselectedItemColor: Colors.grey.shade500,
                  showUnselectedLabels: true,
                  elevation: 0,
                  selectedLabelStyle: GoogleFonts.poppins(
                    fontSize: selectedFontSize,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: GoogleFonts.poppins(
                    fontSize: unselectedFontSize,
                    color: Colors.grey,
                  ),
                  onTap: _onTabTapped,
                  items: [
                    _navItem(Icons.person_add_alt_1, "Add User", 0),
                    _navItem(Icons.swap_vert_circle, "Buy/Sell", 1),
                    _navItem(Icons.people_alt, "Customers", 2),
                    _navItem(Icons.receipt_long, "Invoice", 3),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  /// ⭐ Custom animated icon widget for navigation
  BottomNavigationBarItem _navItem(IconData icon, String label, int index) {
    bool selected = _index == index;

    return BottomNavigationBarItem(
      label: label,
      icon: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeInOut,
        padding: EdgeInsets.all(selected ? 4 : 0),
        child: AnimatedScale(
          duration: const Duration(milliseconds: 240),
          scale: selected ? 1.2 : 1.0,
          child: Icon(
            icon,
            size: selected ? 26 : 24,
            shadows: selected
                ? [
                    Shadow(
                      blurRadius: 8,
                      color: const Color(0xff1A57E8).withOpacity(0.3),
                    ),
                  ]
                : [],
          ),
        ),
      ),
    );
  }
}
