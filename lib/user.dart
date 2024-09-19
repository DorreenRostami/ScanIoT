class User {
  final String username;
  final String password;

  User(this.username, this.password);
}

class Database {
  static List<User> users = [
    User('user1', 'password1'),
    User('user2', 'password2'),
    User('user3', 'password3'),
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
