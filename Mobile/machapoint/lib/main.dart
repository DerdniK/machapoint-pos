import 'dart:async';
import 'package:MachaPoint/services/auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'Pages/Login_Page.dart';
import 'Pages/product_Page.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await Supabase.initialize(
    url: 'https://rbhdpforntgwfbuqychm.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJiaGRwZm9ybnRnd2ZidXF5Y2htIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODYxNTQyNjAsImV4cCI6MjEwMTczMDI2MH0.HJ2-AYGK0xXQ2z7KE2ZeOE2DAKliGx49Jt1UBIOQ8yQ',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MachaPoint',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFd6a74d)),
        useMaterial3: true,
      ),
      home: const AuthCheckScreen(),
    );
  }
}

class AuthCheckScreen extends StatefulWidget {
  const AuthCheckScreen({super.key});

  @override
  State<AuthCheckScreen> createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends State<AuthCheckScreen> {
  late final StreamSubscription<AuthState> _authSubscription;
  bool _isLoading = true;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkInitialSession();
  }

  Future<void> _checkInitialSession() async {
    // Verificar si ya existe una sesión activa persistida en Supabase
    final session = Supabase.instance.client.auth.currentSession;
    final apiToken = await AuthService.getToken();
    setState(() {
      _isAuthenticated = session != null || (apiToken != null && apiToken.isNotEmpty);
      _isLoading = false;
    });
    
    FlutterNativeSplash.remove();

    // Escuchar activamente logins/logouts
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (mounted) {
        setState(() {
          _isAuthenticated = session != null;
        });
      }
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFd6a74d)),
        ),
      );
    }

    return _isAuthenticated ? const ProductPage() : const LoginPage();
  }
}