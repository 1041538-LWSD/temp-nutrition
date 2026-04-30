import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'scanner_screen.dart';
import 'history_screen.dart';
import 'compare_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  _MainLayoutState createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 1;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(), 
        children: const [
          HomeScreen(),
          ScannerScreen(),
          HistoryScreen(),
          CompareScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: _onTabTapped,
            type: BottomNavigationBarType.fixed,
            iconSize: 28, 
            selectedFontSize: 14,
            unselectedFontSize: 13,
            selectedItemColor: Theme.of(context).colorScheme.primary,
            unselectedItemColor: Colors.grey[400],
            elevation: 0, 
            backgroundColor: Colors.transparent,
            items: const [
              BottomNavigationBarItem(
                icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.home_outlined)),
                activeIcon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.home)),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.document_scanner_outlined)),
                activeIcon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.document_scanner)),
                label: 'Scan',
              ),
              BottomNavigationBarItem(
                icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.history_outlined)),
                activeIcon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.history)),
                label: 'History',
              ),
              BottomNavigationBarItem(
                icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.compare_arrows_outlined)),
                activeIcon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.compare_arrows)),
                label: 'Compare',
              ),
            ],
          ),
        ),
      ),
    );
  }
}