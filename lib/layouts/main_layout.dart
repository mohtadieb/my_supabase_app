import 'package:flutter/material.dart';
import '../pages/home_page.dart';
import '../pages/profile_page.dart';
import '../pages/search_page.dart';
import '../pages/settings_page.dart';
import '../services/auth/auth_service.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;
  final _auth = AuthService();

  // Pages will be initialized in initState to get the current UID from Supabase
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _auth.getCurrentUserId();
    _pages = [
      const HomePage(),
      ProfilePage(userId: _auth.getCurrentUserId()), // dynamic current user
      const SearchPage(),
      SettingsPage(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentPage = _selectedIndex; // however you track it
    final showAppBar = currentPage != 1; // e.g., hide on Profile tab

    return Scaffold(

      // AppBar with reduced height
      appBar: showAppBar
          ? AppBar(
        centerTitle: true,
        foregroundColor: Theme.of(context).colorScheme.primary,
        toolbarHeight: kToolbarHeight / 2,
      )
          : null,

      // Use IndexedStack to preserve page state
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),

      // Bottom navigation bar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}