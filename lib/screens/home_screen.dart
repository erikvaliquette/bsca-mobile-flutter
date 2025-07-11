import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/message_provider.dart';
import 'profile/profile_screen.dart';
import 'messaging/chat_list_screen.dart';
import 'more/more_screen.dart';
import 'network/network_screen.dart';
import 'travel_emissions/travel_emissions_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  
  final List<Widget> _screens = [
    const DashboardScreen(),
    const NetworkScreen(),
    const TravelEmissionsScreen(),
    const ChatListScreen(),
    const MoreScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Network',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.flight),
            label: 'Travel',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.more_horiz),
            label: 'More',
          ),
        ],
      ),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('BSCA Mobile'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Welcome to BSCA Mobile',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Text(
              'You are signed in as:',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              authProvider.user?.email ?? 'Unknown User',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'This is a placeholder dashboard. More features will be added as we migrate from React Native.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PlaceholderScreen extends StatelessWidget {
  final String title;
  
  const PlaceholderScreen({super.key, required this.title});

  IconData _getIconForTitle(String title) {
    switch (title) {
      case 'Network':
        return Icons.people;
      case 'Travel':
        return Icons.flight;
      case 'Messages':
        return Icons.message;
      case 'More':
        return Icons.more_horiz;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getIconForTitle(title),
              size: 80,
              color: Colors.grey.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              '$title Coming Soon',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Text(
              'This feature is currently being migrated from React Native.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
