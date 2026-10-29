import 'package:flutter/material.dart';
import '../pages/home_page.dart';
import '../pages/game_pages.dart';
import '../pages/profile_page.dart';
import '../pages/dictionary_page.dart';
import '../pages/community_page_simple.dart';
import '../pages/ai_recognition_page.dart';

const Color primaryRed = Color(0xFFE60012);

class NavigationWrapper extends StatefulWidget {
  final Widget child;
  final int selectedIndex;
  final bool showBottomNav;

  const NavigationWrapper({
    super.key,
    required this.child,
    this.selectedIndex = 0,
    this.showBottomNav = true,
  });

  @override
  State<NavigationWrapper> createState() => _NavigationWrapperState();
}

class _NavigationWrapperState extends State<NavigationWrapper> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.selectedIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: widget.showBottomNav
          ? BottomNavigationBar(
              currentIndex: _currentIndex,
              selectedItemColor: primaryRed,
              unselectedItemColor: Colors.grey,
              backgroundColor: Colors.white,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
                _navigateToPage(index);
              },
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: "Accueil",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.folder),
                  label: "Catégories",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.sports_esports),
                  label: "Jeux",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.camera_alt),
                  label: "IA",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.people),
                  label: "Communauté",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  label: "Profil",
                ),
              ],
            )
          : null,
    );
  }

  void _navigateToPage(int index) {
    switch (index) {
      case 0:
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
          (route) => false,
        );
        break;
      case 1:
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => DictionaryPage()),
          (route) => false,
        );
        break;
      case 2:
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => GamesPage()),
          (route) => false,
        );
        break;
      case 3:
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => AIRecognitionPage()),
          (route) => false,
        );
        break;
      case 4:
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => CommunityPageSimple()),
          (route) => false,
        );
        break;
      case 5:
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => ProfilePage()),
          (route) => false,
        );
        break;
    }
  }
}

// Extension method for easier navigation
extension NavigationExtension on BuildContext {
  void navigateWithBottomNav(Widget page, int selectedIndex) {
    Navigator.push(
      this,
      MaterialPageRoute(
        builder: (context) => NavigationWrapper(
          selectedIndex: selectedIndex,
          child: page,
        ),
      ),
    );
  }
}
