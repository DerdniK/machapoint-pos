class UserModel {
  final String username;
  final String password;
  final String firstname;
  final String lastname;
  final int roleid;

  UserModel({
    required this.username,
    required this.password,
    required this.firstname,
    required this.lastname,
    required this.roleid,
  });

  Map<String, dynamic> toJson() {
    return {
      "username": username,
      "password": password,
      "firstname": firstname,
      "lastname": lastname,
      "roleid": roleid,
    };
  }
}

class UserRecord {
  final String userId;
  final String username;
  final String firstname;
  final String lastname;
  final int? roleId;
  final String roleName;
  final String? createdAt;

  const UserRecord({
    required this.userId,
    required this.username,
    required this.firstname,
    required this.lastname,
    required this.roleId,
    required this.roleName,
    required this.createdAt,
  });

  factory UserRecord.fromJson(Map<String, dynamic> json) {
    final normalized = {
      for (final entry in json.entries)
        entry.key.toLowerCase().replaceAll('_', ''): entry.value,
    };
    final role = normalized['roleid'];
    return UserRecord(
      userId: (normalized['userid'] ?? normalized['id'])?.toString() ?? '',
      username: normalized['username']?.toString() ?? '',
      firstname: normalized['firstname']?.toString() ?? '',
      lastname: normalized['lastname']?.toString() ?? '',
      roleId: role is num ? role.toInt() : int.tryParse(role?.toString() ?? ''),
      roleName: normalized['rolename']?.toString() ?? '',
      createdAt: normalized['createdat']?.toString(),
    );
  }
}
