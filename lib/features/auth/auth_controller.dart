import 'auth_service.dart';

class AuthController {
  final AuthService _service;

  AuthController(this._service);

  String? login(String email, String password) {
    final isValid = _service.login(email, password);
    return isValid ? null : 'Identifiants incorrects';
  }

  String? register(String email, String password) {
    final success = _service.register(email, password);
    return success ? null : 'Email déjà utilisé';
  }
}
