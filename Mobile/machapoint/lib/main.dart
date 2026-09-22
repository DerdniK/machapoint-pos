import 'dart:async';
import 'package:MachaPoint/providers/auth_provider.dart'; 
import 'package:MachaPoint/providers/cart.dart';
import 'package:MachaPoint/providers/shift_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pages/login_page.dart';
import 'pages/product_page.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await Supabase.initialize(
    url: 'https://rbhdpforntgwfbuqychm.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJiaGRwZm9ybnRnd2ZidXF5Y2htIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODYxNTQyNjAsImV4cCI6MjEwMTczMDI2MH0.HJ2-AYGK0xXQ2z7KE2ZeOE2DAKliGx49Jt1UBIOQ8yQ',
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ShiftProvider()),
      ],
      child: const MyApp(),
    ),
  );
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
  StreamSubscription<AuthState>? _authSubscription;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    // Inicializar sesión una sola vez
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<AuthProvider>().initAuth();
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        FlutterNativeSplash.remove();
      }
    });

    // Escuchar cambios posteriores en Supabase
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (mounted && !_isLoading) {
        context.read<AuthProvider>().initAuth();
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
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

    final authProvider = context.watch<AuthProvider>();
    final supabaseSession = Supabase.instance.client.auth.currentSession;
    final bool isAuthenticated = authProvider.isAuthenticated || supabaseSession != null;

    return isAuthenticated ? const ProductPage() : const LoginPage();
  }
}