import 'package:flutter/material.dart';
import 'data/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repo = AuthRepository();
  bool? _isLoggedIn;

  bool? get isLoggedIn => _isLoggedIn;

  Future<void> checkAuth() async {
    _isLoggedIn = await _repo.isLoggedIn();
    notifyListeners();
  }

  Future<void> login() async {
    await _repo.setLoggedIn(true);
    _isLoggedIn = true;
    notifyListeners();
  }

  Future<void> logout() async {
    await _repo.logout();
    _isLoggedIn = false;
    notifyListeners();
  }
}
