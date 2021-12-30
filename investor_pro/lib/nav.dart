import 'package:flutter/material.dart';
import 'package:investor_pro/pages/home/home_page.dart';
import 'package:investor_pro/pages/settings/settings_page.dart';

class Nav extends StatefulWidget {
  const Nav({Key? key}) : super(key: key);

  @override
  State<Nav> createState() => _NavState();
}

class _NavState extends State<Nav> {
  int _selectedPageIndex = 0;

  final List<Widget> _pages = const [Home(), Settings()];

  void _onTap(int index) {
    setState(() {
      _selectedPageIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _pages.elementAt(_selectedPageIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
          showSelectedLabels: false,
          showUnselectedLabels: false,
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.grey,
          currentIndex: _selectedPageIndex,
          type: BottomNavigationBarType.fixed,
          onTap: _onTap,
          backgroundColor: Colors.white,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(
                Icons.home,
              ),
              label: "Home",
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.settings,
              ),
              label: "Settings",
            ),
          ]),
    );
  }
}