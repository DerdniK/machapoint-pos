import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/user_service.dart';

class UpdateUserPage extends StatefulWidget {
  final UserRecord user;

  const UpdateUserPage({super.key, required this.user});

  @override
  State<UpdateUserPage> createState() => _UpdateUserPageState();
}

class _UpdateUserPageState extends State<UpdateUserPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _firstnameController = TextEditingController();
  final _lastnameController = TextEditingController();

  bool _isLoading = false;
  int? _selectedRoleId;

  Future<void> _update() async {
    if (!_formKey.currentState!.validate()) return;

    final username = _usernameController.text.trim();
    final firstname = _firstnameController.text.trim();
    final lastname = _lastnameController.text.trim();
    if (username.isEmpty &&
        firstname.isEmpty &&
        lastname.isEmpty &&
        _selectedRoleId == null) {
      _showMessage(
        'Ingresa al menos un dato que quieras actualizar.',
        Colors.orange,
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final success = await UserService.updateUser(
        userId: widget.user.userId,
        username: username.isEmpty ? null : username,
        firstname: firstname.isEmpty ? null : firstname,
        lastname: lastname.isEmpty ? null : lastname,
        roleId: _selectedRoleId,
      );

      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Usuario actualizado exitosamente!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      } else {
        _showMessage('Usuario no encontrado.', Colors.orange);
      }
    } catch (error) {
      final message = error.toString().replaceAll('Exception: ', '');
      final normalized = message.toLowerCase();
      if (normalized.contains('409') ||
          normalized.contains('already exist') ||
          normalized.contains('ya existe') ||
          normalized.contains('ocupado') ||
          normalized.contains('duplicate')) {
        _showMessage(
          'El nuevo nombre de usuario ya está ocupado.',
          Colors.orange,
        );
      } else if (normalized.contains('not found') ||
          normalized.contains('usuario no encontrado') ||
          normalized.contains('404')) {
        _showMessage('Usuario no encontrado.', Colors.orange);
      } else {
        _showMessage('Error: $message', Colors.redAccent);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _firstnameController.dispose();
    _lastnameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const orangeColor = Color(0xFFF2B04E);
    final displayName = '${widget.user.firstname} ${widget.user.lastname}'
        .trim();

    return Scaffold(
      backgroundColor: const Color(0xFFF3E7DF),
      appBar: AppBar(
        title: const Text('Actualizar Usuario'),
        backgroundColor: orangeColor,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              displayName.isEmpty ? widget.user.username : displayName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text('@${widget.user.username} · ID: ${widget.user.userId}'),
            const SizedBox(height: 20),
            TextFormField(
              controller: _usernameController,
              maxLength: 20,
              decoration: _inputDecoration(
                'Nuevo nombre de usuario (opcional)',
              ),
              validator: _validateOptionalMaxLength,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _firstnameController,
              maxLength: 20,
              decoration: _inputDecoration('Nombre(s) (opcional)'),
              validator: _validateOptionalMaxLength,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _lastnameController,
              maxLength: 20,
              decoration: _inputDecoration('Apellido(s) (opcional)'),
              validator: _validateOptionalMaxLength,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int?>(
              initialValue: _selectedRoleId,
              decoration: _inputDecoration('Rol (opcional)'),
              items: const [
                DropdownMenuItem<int?>(value: null, child: Text('Sin cambios')),
                DropdownMenuItem<int?>(
                  value: 1,
                  child: Text('Rol 1 (Administrador)'),
                ),
                DropdownMenuItem<int?>(value: 2, child: Text('Rol 2 (Cajero)')),
              ],
              onChanged: _isLoading
                  ? null
                  : (value) => setState(() => _selectedRoleId = value),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: orangeColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isLoading ? null : _update,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Actualizar Usuario',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) => InputDecoration(
    labelText: label,
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
  );

  String? _validateOptionalMaxLength(String? value) {
    if ((value?.trim().length ?? 0) > 20) {
      return 'Máximo 20 caracteres';
    }
    return null;
  }
}
