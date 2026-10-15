import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/user_service.dart';
import 'update_user.dart';

class CreateUserPage extends StatefulWidget {
  const CreateUserPage({super.key});

  @override
  State<CreateUserPage> createState() => _CreateUserPageState();
}

class _CreateUserPageState extends State<CreateUserPage> {
  final _createFormKey = GlobalKey<FormState>();

  String _selectedAction = 'create';
  final _usernameCreateController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstnameController = TextEditingController();
  final _lastnameController = TextEditingController();
  final _roleIdController = TextEditingController(text: '1');
  final _userSearchController = TextEditingController();

  bool _isLoading = false;
  Future<List<UserRecord>>? _usersFuture;

  Future<void> _submitCreate() async {
    if (!_createFormKey.currentState!.validate()) return;

    final roleId = int.tryParse(_roleIdController.text.trim());
    final password = _passwordController.text.trim();

    if (roleId == null || roleId < 1 || roleId > 2) {
      if (mounted) _showSnackBar('El rol debe ser 1 o 2', Colors.orange);
      return;
    }

    if (password.length < 7) {
      if (mounted) {
        _showSnackBar(
          'La contraseña debe tener al menos 7 caracteres',
          Colors.orange,
        );
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
        _showSnackBar('Usuario registrado exitosamente', Colors.green);
        _usernameCreateController.clear();
        _passwordController.clear();
        _firstnameController.clear();
        _lastnameController.clear();
      }
    } catch (e) {
      final rawMsg = e.toString().replaceAll('Exception: ', '').toLowerCase();
      if (mounted) {
        if (rawMsg.contains('409') ||
            rawMsg.contains('already exist') ||
            rawMsg.contains('ya existe') ||
            rawMsg.contains('ocupado') ||
            rawMsg.contains('duplicate')) {
          _showSnackBar('El nombre de usuario ya esta ocupado', Colors.orange);
        } else {
          _showSnackBar(
            'Error: ${e.toString().replaceAll('Exception: ', '')}',
            Colors.redAccent,
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _loadUsers() {
    setState(() {
      _usersFuture = UserService.getUsers();
    });
  }

  List<UserRecord> _filterUsers(List<UserRecord> users, String query) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) return users;

    return users.where((user) {
      final searchableText = [
        user.firstname,
        user.lastname,
        user.username,
        user.userId,
        user.roleName,
        user.roleId?.toString() ?? '',
      ].join(' ').toLowerCase();
      return searchableText.contains(normalizedQuery);
    }).toList();
  }

  Future<void> _openUserUpdate(UserRecord user) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => UpdateUserPage(user: user)),
    );
    if (updated == true && mounted) _loadUsers();
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  @override
  void dispose() {
    _usernameCreateController.dispose();
    _passwordController.dispose();
    _firstnameController.dispose();
    _lastnameController.dispose();
    _roleIdController.dispose();
    _userSearchController.dispose();
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
            DropdownButtonFormField<String>(
              initialValue: _selectedAction,
              decoration: InputDecoration(
                labelText: 'Acción de Usuarios',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.black26),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.black26),
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'create', child: Text('Crear Usuario')),
                DropdownMenuItem(value: 'view', child: Text('Ver/Editar Usuarios')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedAction = value);
                  if (value == 'view') _loadUsers();
                }
              },
            ),
            const SizedBox(height: 24),
            if (_selectedAction == 'create') ...[
              Form(
                key: _createFormKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _usernameCreateController,
                      maxLength: 20,
                      decoration: _inputDec('Nombre de usuario'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Ingrese el nombre de usuario';
                        }
                        if (value.trim().length > 20) {
                          return 'Máximo 20 caracteres';
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
                      maxLength: 20,
                      decoration: _inputDec('Nombre(s)'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Ingrese el nombre';
                        }
                        if (value.trim().length > 20) {
                          return 'Máximo 20 caracteres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _lastnameController,
                      maxLength: 20,
                      decoration: _inputDec('Apellido(s)'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Ingrese el apellido';
                        }
                        if (value.trim().length > 20) {
                          return 'Máximo 20 caracteres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      initialValue: int.tryParse(_roleIdController.text) ?? 1,
                      decoration: _inputDec('Rol'),
                      items: const [
                        DropdownMenuItem(
                          value: 1,
                          child: Text('Rol 1 (Administrador)'),
                        ),
                        DropdownMenuItem(
                          value: 2,
                          child: Text('Rol 2 (Cajero)'),
                        ),
                      ],
                      validator: (value) =>
                          value == null ? 'Seleccione un rol' : null,
                      onChanged: (value) {
                        if (value != null) {
                          _roleIdController.text = value.toString();
                        }
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: orangeColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isLoading ? null : _submitCreate,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Crear Usuario',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ] else if (_selectedAction == 'view') ...[
              if (_usersFuture == null)
                ElevatedButton.icon(
                  onPressed: _loadUsers,
                  icon: const Icon(Icons.people),
                  label: const Text('Cargar usuarios'),
                )
              else
                FutureBuilder<List<UserRecord>>(
                  future: _usersFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (snapshot.hasError) {
                      return Column(
                        children: [
                          Text(
                            'No se pudieron cargar los usuarios, comprueba tu conexion.',
                          ),
                          TextButton.icon(
                            onPressed: _loadUsers,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reintentar'),
                          ),
                        ],
                      );
                    }
                    final users = snapshot.data ?? [];
                    if (users.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(20),
                        child: Text('No hay usuarios para mostrar'),
                      );
                    }
                    final filteredUsers = _filterUsers(
                      users,
                      _userSearchController.text,
                    );
                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredUsers.isEmpty
                          ? 2
                          : filteredUsers.length + 1,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return TextField(
                            controller: _userSearchController,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              labelText: 'Buscar usuario',
                              hintText: 'Nombre, username o ID',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: _userSearchController.text.isEmpty
                                  ? null
                                  : IconButton(
                                      tooltip: 'Limpiar búsqueda',
                                      onPressed: () {
                                        _userSearchController.clear();
                                        setState(() {});
                                      },
                                      icon: const Icon(Icons.clear),
                                    ),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        }
                        if (filteredUsers.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(12),
                            child: Text('No se encontraron usuarios'),
                          );
                        }
                        final user = filteredUsers[index - 1];
                        return Card(
                          child: ListTile(
                            title: Text(
                              '${user.firstname} ${user.lastname}'
                                      .trim()
                                      .isEmpty
                                  ? user.username
                                  : '${user.firstname} ${user.lastname}',
                            ),
                            subtitle: Text(
                              '@${user.username}\n'
                              '${user.roleName.isNotEmpty ? user.roleName : 'Rol ${user.roleId ?? 'N/D'}'}'
                              ' · ID: ${user.userId}',
                            ),
                            isThreeLine: true,
                            trailing: IconButton(
                              tooltip: 'Editar usuario',
                              icon: const Icon(Icons.edit),
                              onPressed: () => _openUserUpdate(user),
                            ),
                          ),
                        );
                      },
                    );
                  },
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
