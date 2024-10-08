class User {
  final String username;
  final String password;

  User(this.username, this.password);
}

class Database {
  static List<User> users = [
    User('admin', 'admin!'),
  ];

  static void addUser(String username, String password) {
    users.add(User(username, password));
  }

  static bool isValidUser(String username, String password) {
    return users
        .any((user) => user.username == username && user.password == password);
  }

  static bool isExistingUser(String username) {
    return users.any((user) => user.username == username);
  }
}
