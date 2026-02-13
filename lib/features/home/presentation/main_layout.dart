import 'package:flutter/material.dart';

import '../../auth/presentation/account_screen.dart';
import '../../home/presentation/home_screen.dart';
import '../../trip/presentation/reservation_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  static const List<Widget> _screens = [
    HomeScreen(),
    ReservationScreen(),
    AccountScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.drive_eta), label: '配車を依頼'),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: '配車を予約',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'アカウント'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.deepOrange,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
