import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/user_service.dart';

class CreateUserPage extends StatefulWidget {
  const CreateUserPage({super.key});

  @override
  State<CreateUserPage> createState() => _CreateUserPageState();
}

class _CreateUserPageState extends State<CreateUserPage> {
  String _selectedAction = 'create'; // 'create', 'update', 'delete'

  // Controladores independientes para CREAR
  final _usernameCreateController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstnameController = TextEditingController();
  final _lastnameController = TextEditingController();
  final _roleIdController = TextEditingController(text: '1');
  
  // Controladores independientes para ACTUALIZAR
  final _userIdUpdateController = TextEditingController();
  final _usernameUpdateController = TextEditingController();

  // Controlador independiente para ELIMINAR
  final _userIdDeleteController = TextEditingController();

  bool _isLoading = false;

  Future<void> _submitCreate() async {
    setState(() => _isLoading = true);
    try {
      final user = UserModel(
        username: _usernameCreateController.text.trim(),
        password: _passwordController.text.trim(),
        firstname: _firstnameController.text.trim(),
        lastname: _lastnameController.text.trim(),
        roleid: int.tryParse(_roleIdController.text.trim()) ?? 1,
      );
      await UserService.registerUser(user);
      if (mounted) {
        _showSnackBar('¡Usuario registrado exitosamente!', Colors.green);
        _usernameCreateController.clear();
        _passwordController.clear();
        _firstnameController.clear();
        _lastnameController.clear();
      }
    } catch (e) {
      if (mounted) _showSnackBar('Error: $e', Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitUpdate() async {
    setState(() => _isLoading = true);
    try {
      await UserService.updateUser(
        userId: _userIdUpdateController.text.trim(),
        username: _usernameUpdateController.text.trim(),
      );
      if (mounted) {
        _showSnackBar('¡Usuario actualizado exitosamente!', Colors.green);
      }
    } catch (e) {
      if (mounted) _showSnackBar('Error: $e', Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitDelete() async {
    setState(() => _isLoading = true);
    try {
      await UserService.deleteUser(
        userId: _userIdDeleteController.text.trim(),
      );
      if (mounted) {
        _showSnackBar('¡Usuario eliminado exitosamente!', Colors.redAccent);
        _userIdDeleteController.clear();
      }
    } catch (e) {
      if (mounted) _showSnackBar('Error: $e', Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  void dispose() {
    _usernameCreateController.dispose();
    _passwordController.dispose();
    _firstnameController.dispose();
    _lastnameController.dispose();
    _roleIdController.dispose();
    _userIdUpdateController.dispose();
    _usernameUpdateController.dispose();
    _userIdDeleteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const orangeColor = Color(0xFFF2B04E);

    return Scaffold(
      backgroundColor: const Color(0xFFF3E7DF),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Selector desplegable superior
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black26),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedAction,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 'create', child: Text('Crear Usuario')),
                    DropdownMenuItem(value: 'update', child: Text('Actualizar Usuario')),
                    DropdownMenuItem(value: 'delete', child: Text('Eliminar Usuario')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedAction = value!;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Formulario condicional según la opción seleccionada
            if (_selectedAction == 'create') ...[
              TextField(
                controller: _usernameCreateController,
                decoration: _inputDec('Nombre de usuario'),
              ),
              const SizedBox(height: 16),
              TextField(controller: _passwordController, decoration: _inputDec('Contraseña'), obscureText: true),
              const SizedBox(height: 16),
              TextField(controller: _firstnameController, decoration: _inputDec('Nombre(s)')),
              const SizedBox(height: 16),
              TextField(controller: _lastnameController, decoration: _inputDec('Apellido(s)')),
              const SizedBox(height: 16),
              TextField(controller: _roleIdController, decoration: _inputDec('Rol ID'), keyboardType: TextInputType.number),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: orangeColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: _isLoading ? null : _submitCreate,
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Crear Usuario', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ),
            ] else if (_selectedAction == 'update') ...[
              TextField(controller: _userIdUpdateController, decoration: _inputDec('User ID (UUID)')),
              const SizedBox(height: 16),
              TextField(controller: _usernameUpdateController, decoration: _inputDec('Nuevo Nombre de usuario')),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: orangeColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: _isLoading ? null : _submitUpdate,
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Actualizar Usuario', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ),
            ] else if (_selectedAction == 'delete') ...[
              TextField(controller: _userIdDeleteController, decoration: _inputDec('User ID (UUID)')),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: _isLoading ? null : _submitDelete,
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Eliminar Usuario', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDec(String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      );
}