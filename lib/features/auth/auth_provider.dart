import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import './auth_service.dart';
import 'models/auth_models.dart';
import '../../core/services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();

  // État d'authentification
  AuthState _state = AuthState.initial;
  User? _user;
  AuthError? _error;

  // Getters
  AuthState get state => _state;
  User? get user => _user;
  AuthError? get error => _error;
  
  bool get isLoading => _state == AuthState.loading;
  bool get isAuthenticated => _state == AuthState.authenticated && _user != null;
  bool get isUnauthenticated => _state == AuthState.unauthenticated;
  bool get hasError => _state == AuthState.error && _error != null;

  // Getters de rôle
  bool get isCreator => _user?.isCreator ?? false;
  bool get isAdmin => _user?.isAdmin ?? false;
  bool get isSubscriber => _user?.isSubscriber ?? false;

  /// Initialise le provider et vérifie l'état d'authentification
  Future<void> checkAuth() async {
    debugPrint('🔐 Checking authentication state...');
    
    try {
      // Initialiser l'API service
      await _apiService.initialize();
      
      // Vérifier si un token existe et est valide
      if (_authService.hasToken()) {
        _setState(AuthState.loading);
        
        final result = await _authService.getProfile();
        if (result.isSuccess && result.data != null) {
          _user = result.data;
          _setState(AuthState.authenticated);
          debugPrint('🔐 User authenticated: ${_user!.email}');
        } else {
          _setState(AuthState.unauthenticated);
          debugPrint('🔐 Token invalid, user unauthenticated');
        }
      } else {
        _setState(AuthState.unauthenticated);
        debugPrint('🔐 No token found, user unauthenticated');
      }
    } catch (e) {
      debugPrint('❌ Auth check error: $e');
      _setState(AuthState.unauthenticated);
    }
  }

  /// Connexion utilisateur
  Future<bool> login(String email, String password) async {
    debugPrint('🔐 Login attempt for: $email');
    
    _setState(AuthState.loading);
    _clearError();

    try {
      final request = LoginRequest(email: email, password: password);
      final result = await _authService.login(request);

      if (result.isSuccess) {
        // Récupérer le profil utilisateur
        final profileResult = await _authService.getProfile();
        
        if (profileResult.isSuccess && profileResult.data != null) {
          _user = profileResult.data;
          _setState(AuthState.authenticated);
          debugPrint('🔐 Login successful for: ${_user!.email}');
          return true;
        } else {
          _setError(profileResult.error ?? AuthError.server());
          return false;
        }
      } else {
        _setError(result.error ?? AuthError.server());
        return false;
      }
    } catch (e) {
      debugPrint('❌ Login error: $e');
      _setError(AuthError.network());
      return false;
    }
  }

  /// Inscription utilisateur
  Future<bool> register(String firstName, String lastName, String email, String password) async {
    debugPrint('🔐 Registration attempt for: $email');
    
    _setState(AuthState.loading);
    _clearError();

    try {
      final request = RegisterRequest(
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
      );
      
      final result = await _authService.register(request);

      if (result.isSuccess) {
        // Récupérer le profil utilisateur
        final profileResult = await _authService.getProfile();
        
        if (profileResult.isSuccess && profileResult.data != null) {
          _user = profileResult.data;
          _setState(AuthState.authenticated);
          debugPrint('🔐 Registration successful for: ${_user!.email}');
          return true;
        } else {
          _setError(profileResult.error ?? AuthError.server());
          return false;
        }
      } else {
        _setError(result.error ?? AuthError.server());
        return false;
      }
    } catch (e) {
      debugPrint('❌ Registration error: $e');
      _setError(AuthError.network());
      return false;
    }
  }

  /// Mise à jour du profil utilisateur
  Future<bool> updateProfile({
    String? firstName,
    String? lastName,
    String? email,
    String? password,
  }) async {
    if (!isAuthenticated) return false;
    
    debugPrint('🔐 Updating profile for: ${_user!.email}');
    
    _setState(AuthState.loading);
    _clearError();

    try {
      final request = UpdateProfileRequest(
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
      );
      
      final result = await _authService.updateProfile(request);

      if (result.isSuccess && result.data != null) {
        _user = result.data;
        _setState(AuthState.authenticated);
        debugPrint('🔐 Profile updated successfully');
        return true;
      } else {
        _setError(result.error ?? AuthError.server());
        return false;
      }
    } catch (e) {
      debugPrint('❌ Profile update error: $e');
      _setError(AuthError.network());
      return false;
    }
  }

  /// Demande de passage en créateur
  Future<bool> requestCreatorUpgrade() async {
    if (!isAuthenticated) return false;
    
    debugPrint('🔐 Requesting creator upgrade for: ${_user!.email}');
    
    _setState(AuthState.loading);
    _clearError();

    try {
      final result = await _authService.requestCreatorUpgrade();

      if (result.isSuccess) {
        // Recharger le profil pour voir si le statut a changé
        await _refreshProfile();
        debugPrint('🔐 Creator upgrade request sent successfully');
        return true;
      } else {
        _setError(result.error ?? AuthError.server());
        return false;
      }
    } catch (e) {
      debugPrint('❌ Creator upgrade request error: $e');
      _setError(AuthError.network());
      return false;
    }
  }

  /// Suppression du compte
  Future<bool> deleteAccount() async {
    if (!isAuthenticated) return false;
    
    debugPrint('🔐 Deleting account for: ${_user!.email}');
    
    _setState(AuthState.loading);
    _clearError();

    try {
      final result = await _authService.deleteAccount();

      if (result.isSuccess) {
        _user = null;
        _setState(AuthState.unauthenticated);
        debugPrint('🔐 Account deleted successfully');
        return true;
      } else {
        _setError(result.error ?? AuthError.server());
        return false;
      }
    } catch (e) {
      debugPrint('❌ Account deletion error: $e');
      _setError(AuthError.network());
      return false;
    }
  }

  /// Déconnexion utilisateur
  Future<void> logout() async {
    debugPrint('🔐 Logging out user: ${_user?.email}');
    
    await _authService.logout();
    _user = null;
    _setState(AuthState.unauthenticated);
    _clearError();
    
    debugPrint('🔐 User logged out successfully');
  }

  /// Actualise le profil utilisateur
  Future<void> refreshProfile() async {
    await _refreshProfile();
  }

  /// Actualise le profil utilisateur (méthode privée)
  Future<void> _refreshProfile() async {
    if (!isAuthenticated) return;
    
    try {
      final result = await _authService.getProfile();
      
      if (result.isSuccess && result.data != null) {
        _user = result.data;
        _setState(AuthState.authenticated);
      } else if (result.error?.isAuthError ?? false) {
        // Si erreur d'auth, déconnecter
        await logout();
      }
    } catch (e) {
      debugPrint('❌ Profile refresh error: $e');
    }
  }

  /// Change l'état et notifie les listeners
  void _setState(AuthState newState) {
    if (_state != newState) {
      _state = newState;
      notifyListeners();
    }
  }

  /// Définit une erreur et change l'état
  void _setError(AuthError authError) {
    _error = authError;
    _setState(AuthState.error);
  }

  /// Efface l'erreur
  void _clearError() {
    _error = null;
  }

  /// Méthode pour vérifier si l'utilisateur est connecté (legacy)
  Future<bool> isLoggedIn() async {
    return isAuthenticated;
  }

  /// Méthode pour définir l'état connecté (legacy)
  Future<void> setLoggedIn(bool value) async {
    if (value && !isAuthenticated) {
      await checkAuth();
    } else if (!value && isAuthenticated) {
      await logout();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}