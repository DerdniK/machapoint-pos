import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/user_service.dart';

class CreateUserPage extends StatefulWidget {
  const CreateUserPage({super.key});

  @override
  State<CreateUserPage> createState() => _CreateUserPageState();
}

class _CreateUserPageState extends State<CreateUserPage> {
  final _createFormKey = GlobalKey<FormState>();
  final _updateFormKey = GlobalKey<FormState>();
  String _selectedAction = 'create'; // 'create', 'update', 'delete'

  // Controladores para CREAR
  final _usernameCreateController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstnameController = TextEditingController();
  final _lastnameController = TextEditingController();
  final _roleIdController = TextEditingController(text: '1');
  
  // Controladores para ACTUALIZAR
  final _userIdUpdateController = TextEditingController();
  final _usernameUpdateController = TextEditingController();

  // Controlador para ELIMINAR
  final _userIdDeleteController = TextEditingController();

  bool _isLoading = false;

  Future<void> _submitCreate() async {
    if (!_createFormKey.currentState!.validate()) {
      return;
    }

    final roleId = int.tryParse(_roleIdController.text.trim());
    final password = _passwordController.text.trim();

    if (roleId == null || roleId < 1 || roleId > 2) {
      if (mounted) {
        _showSnackBar('El rol debe ser 1 o 2', Colors.orange);
      }
      return;
    }

    if (password.length < 7) {
      if (mounted) {
        _showSnackBar('La contraseña debe tener al menos 7 caracteres', Colors.orange);
      }
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = UserModel(
        username: _usernameCreateController.text.trim(),
        password: password,
        firstname: _firstnameController.text.trim(),
        lastname: _lastnameController.text.trim(),
        roleid: roleId,
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
    if (!_updateFormKey.currentState!.validate()) {
      return;
    }

    final userId = _userIdUpdateController.text.trim();
    final username = _usernameUpdateController.text.trim();

    setState(() => _isLoading = true);
    try {
      final success = await UserService.updateUser(
        userId: userId,
        username: username,
      );

      if (mounted) {
        if (success) {
          _showSnackBar('¡Usuario actualizado exitosamente!', Colors.green);
        } else {
          _showSnackBar('Usuario no encontrado', Colors.orange);
        }
      }
    } catch (e) {
      final message = e.toString().toLowerCase();
      if (mounted) {
        if (message.contains('not found') || message.contains('usuario no encontrado') || message.contains('404')) {
          _showSnackBar('Usuario no encontrado', Colors.orange);
        } else {
          _showSnackBar('Error: $e', Colors.redAccent);
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitDelete() async {
    final userId = _userIdDeleteController.text.trim();

    if (userId.isEmpty) {
      if (mounted) {
        _showSnackBar('Ingrese el ID del usuario', Colors.orange);
      }
      return;
    }

    setState(() => _isLoading = true);
    try {
      final success = await UserService.deleteUser(
        userId: userId,
      );

      if (mounted) {
        if (success) {
          _showSnackBar('¡Usuario eliminado exitosamente!', Colors.redAccent);
          _userIdDeleteController.clear();
        } else {
          _showSnackBar('Usuario no encontrado', Colors.orange);
        }
      }
    } catch (e) {
      final message = e.toString().toLowerCase();
      if (mounted) {
        if (message.contains('not found') || message.contains('usuario no encontrado') || message.contains('404')) {
          _showSnackBar('Usuario no encontrado', Colors.orange);
        } else {
          _showSnackBar('Error: $e', Colors.redAccent);
        }
      }
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
            if (_selectedAction == 'create') ...[
              Form(
                key: _createFormKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _usernameCreateController,
                      decoration: _inputDec('Nombre de usuario'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Ingrese el nombre de usuario';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      decoration: _inputDec('Contraseña'),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Ingrese la contraseña';
                        }
                        if (value.trim().length < 7) {
                          return 'La contraseña debe tener al menos 7 caracteres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _firstnameController,
                      decoration: _inputDec('Nombre(s)'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Ingrese el nombre';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _lastnameController,
                      decoration: _inputDec('Apellido(s)'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Ingrese el apellido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _roleIdController,
                      decoration: _inputDec('Rol ID'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        final roleId = int.tryParse(value ?? '');
                        if (roleId == null || roleId < 1 || roleId > 2) {
                          return 'El rol debe ser 1 o 2';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
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
              Form(
                key: _updateFormKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _userIdUpdateController,
                      decoration: _inputDec('User ID (UUID)'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Ingrese el ID del usuario';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _usernameUpdateController,
                      decoration: _inputDec('Nuevo Nombre de usuario'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Ingrese el nuevo nombre de usuario';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
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
              Form(
                child: TextFormField(
                  controller: _userIdDeleteController,
                  decoration: _inputDec('User ID (UUID)'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingrese el ID del usuario';
                    }
                    return null;
                  },
                ),
              ),
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