import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

// Create a global RouteObserver
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  print('🚀 App starting...');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) {
          print('🟣 Creating AuthProvider...');
          return AuthProvider();
        }),
      ],
      child: MaterialApp(
        title: 'SunVibee',
        theme: ThemeData(
          primarySwatch: Colors.orange,
          useMaterial3: true,
        ),
        navigatorObservers: [routeObserver],
        home: const AuthWrapper(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    print('🟣 AuthWrapper build - isLoggedIn: ${authProvider.isLoggedIn}, isLoading: ${authProvider.isLoading}');
    
    if (authProvider.isLoading) {
      // Show loading screen while session is being checked
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    if (authProvider.isLoggedIn) {
      print('🟢 User is logged in - Showing HomeScreen');
      return const HomeScreen();
    } else {
      print('🔴 User is NOT logged in - Showing LoginScreen');
      return const LoginScreen();
    }
  }
} 