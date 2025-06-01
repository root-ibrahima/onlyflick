class AuthService {
  // Simule une base d'utilisateurs
  final Map<String, String> _users = {
    'user@test.com': 'password123',
  };

  bool login(String email, String password) {
    return _users[email] == password;
  }

  bool register(String email, String password) {
    if (_users.containsKey(email)) return false;
    _users[email] = password;
    return true;
  }

  void logout() {
    // Logique de déconnexion (ex : clear session, token, etc.)
  }
}
