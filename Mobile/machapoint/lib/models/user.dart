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