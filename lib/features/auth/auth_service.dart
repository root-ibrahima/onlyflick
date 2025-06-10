class AuthService {
  // Simule une base d'utilisateurs avec un compte de démo
  final Map<String, String> _users = {
    'user@test.com': 'password123',
    'demoUser': 'demoPassword', // 💡 utilisateur de démo ajouté
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
    // Simulation d'une déconnexion
  }
}
