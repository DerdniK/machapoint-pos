import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'product_Page.dart';

const _loadingMessages = [
  'Preparando tu espacio de trabajo',
  '¿Listo para chambear?',
  'La maquina de chambeo entro',
  'Listo para vender',
];

class BienvenudaPage extends StatefulWidget {
  const BienvenudaPage({super.key});

  @override
  State<BienvenudaPage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<BienvenudaPage> {
  Timer? _navigationTimer;
  late final String _loadingMessage;

  @override
  void initState() {
    super.initState();
    _loadingMessage =
        _loadingMessages[Random().nextInt(_loadingMessages.length)];
    _navigationTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const ProductPage()),
      );
    });
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const brandColor = Color(0xFFF2B04E);
    final authProvider = context.watch<AuthProvider>();
    final userName = authProvider.userName?.trim();
    final displayedName = userName == null || userName.isEmpty
        ? 'Usuario'
        : userName;
    final role = switch (authProvider.roleId) {
      1 => 'Administrador',
      2 => 'Cajero',
      _ => '',
    };

    return Scaffold(
      backgroundColor: const Color(0xFFF3E7DF),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/Icon.png',
                  height: 150,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 32),
                Text(
                  '¡Bienvenido, $displayedName!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                if (role.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: brandColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      role,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 40),
                const CircularProgressIndicator(color: brandColor),
                const SizedBox(height: 12),
                Text(
                  _loadingMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
