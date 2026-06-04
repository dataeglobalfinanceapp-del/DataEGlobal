import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({super.key, this.currentIndex = 0, this.onTap});

  final int currentIndex;
  final ValueChanged<int>? onTap;

  static const List<BottomNavigationBarItem> _items = [
    BottomNavigationBarItem(
      icon: Icon(Icons.home_outlined),
      activeIcon: Icon(Icons.home),
      label: 'Home',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.add_circle_outline),
      activeIcon: Icon(Icons.add_circle),
      label: 'Add',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.insert_chart_outlined),
      activeIcon: Icon(Icons.insert_chart),
      label: 'Reports',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.person_outline),
      activeIcon: Icon(Icons.person),
      label: 'Account',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color.fromARGB(255, 187, 22, 22),
      unselectedItemColor: Colors.blueGrey,
      showUnselectedLabels: true,
      items: _items,
    );
  }
}
