import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Configuration selon votre backend Go et la plateforme
  static String get _baseUrl {
    if (kDebugMode) {
      // En développement, adapter selon la plateforme
      if (defaultTargetPlatform == TargetPlatform.android) {
        return 'http://10.0.2.2:8080';  // Android emulator
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        return 'http://localhost:8080';  // iOS simulator
      } else {
        return 'http://localhost:8080';  // Desktop/Web
      }
    } else {
      return 'https://api.onlyflick.io';  // Production
    }
  }

  final http.Client _client = http.Client();
  String? _token;

  // Headers par défaut
  Map<String, String> get _defaultHeaders => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  /// Initialise le service avec le token stocké
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    debugPrint('🔐 ApiService initialized with token: ${_token != null}');
    debugPrint('🌍 Base URL: $_baseUrl');
  }

  /// Met à jour le token d'authentification
  Future<void> setToken(String? token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    if (token != null) {
      await prefs.setString('auth_token', token);
      debugPrint('🔐 Token saved: ${token.substring(0, 10)}...');
    } else {
      await prefs.remove('auth_token');
      debugPrint('🔐 Token cleared');
    }
  }

  /// Récupère le token actuel
  String? get token => _token;

  /// GET Request
  Future<ApiResponse<T>> get<T>(
    String endpoint, {
    Map<String, String>? queryParams,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    return _makeRequest<T>('GET', endpoint, queryParams: queryParams, fromJson: fromJson);
  }

  /// POST Request
  Future<ApiResponse<T>> post<T>(
    String endpoint, {
    Object? body,
    Map<String, String>? queryParams,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    return _makeRequest<T>('POST', endpoint, body: body, queryParams: queryParams, fromJson: fromJson);
  }

  /// PATCH Request
  Future<ApiResponse<T>> patch<T>(
    String endpoint, {
    Object? body,
    Map<String, String>? queryParams,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    return _makeRequest<T>('PATCH', endpoint, body: body, queryParams: queryParams, fromJson: fromJson);
  }

  /// DELETE Request
  Future<ApiResponse<T>> delete<T>(
    String endpoint, {
    Map<String, String>? queryParams,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    return _makeRequest<T>('DELETE', endpoint, queryParams: queryParams, fromJson: fromJson);
  }

  /// Méthode privée pour effectuer les requêtes HTTP
  Future<ApiResponse<T>> _makeRequest<T>(
    String method,
    String endpoint, {
    Object? body,
    Map<String, String>? queryParams,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final uri = _buildUri(endpoint, queryParams);
      
      debugPrint('🌐 $method ${uri.toString()}');
      if (body != null) debugPrint('📤 Body: ${jsonEncode(body)}');

      final headers = _defaultHeaders;
      late http.Response response;

      switch (method.toUpperCase()) {
        case 'GET':
          response = await _client.get(uri, headers: headers).timeout(
            const Duration(seconds: 10),
          );
          break;
        case 'POST':
          response = await _client.post(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          ).timeout(
            const Duration(seconds: 10),
          );
          break;
        case 'PATCH':
          response = await _client.patch(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          ).timeout(
            const Duration(seconds: 10),
          );
          break;
        case 'DELETE':
          response = await _client.delete(uri, headers: headers).timeout(
            const Duration(seconds: 10),
          );
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }

      debugPrint('📥 Response ${response.statusCode}: ${response.body}');
      return _handleResponse<T>(response, fromJson);

    } on SocketException {
      debugPrint('❌ No internet connection');
      return ApiResponse.error('Pas de connexion internet');
    } on HttpException {
      debugPrint('❌ HTTP error occurred');
      return ApiResponse.error('Erreur de communication avec le serveur');
    } on FormatException {
      debugPrint('❌ Bad response format');
      return ApiResponse.error('Format de réponse invalide');
    } catch (e) {
      debugPrint('❌ Unexpected error: $e');
      return ApiResponse.error('Serveur inaccessible. Vérifiez que votre backend Go est démarré.');
    }
  }

  /// Construit l'URI avec les paramètres de requête
  Uri _buildUri(String endpoint, Map<String, String>? queryParams) {
    final url = endpoint.startsWith('/') ? '$_baseUrl$endpoint' : '$_baseUrl/$endpoint';
    
    if (queryParams != null && queryParams.isNotEmpty) {
      return Uri.parse(url).replace(queryParameters: queryParams);
    }
    
    return Uri.parse(url);
  }

  /// Traite la réponse HTTP et la convertit en ApiResponse
  ApiResponse<T> _handleResponse<T>(
    http.Response response,
    T Function(Map<String, dynamic>)? fromJson,
  ) {
    final statusCode = response.statusCode;
    
    try {
      final jsonData = jsonDecode(response.body);

      // Gestion des réponses de succès (2xx)
      if (statusCode >= 200 && statusCode < 300) {
        if (fromJson != null && jsonData is Map<String, dynamic>) {
          final data = fromJson(jsonData);
          return ApiResponse.success(data, statusCode);
        } else {
          return ApiResponse.success(jsonData, statusCode);
        }
      }

      // Gestion des erreurs avec format du backend Go
      if (jsonData is Map<String, dynamic>) {
        final message = jsonData['message'] ?? jsonData['error'] ?? 'Erreur inconnue';
        
        // Gestion spécifique des erreurs d'authentification
        if (statusCode == 401) {
          _handleUnauthorized();
          return ApiResponse.error('Session expirée, veuillez vous reconnecter', statusCode);
        }
        
        return ApiResponse.error(message, statusCode);
      }

      return ApiResponse.error('Erreur de format de réponse', statusCode);

    } catch (e) {
      debugPrint('❌ Error parsing response: $e');
      return ApiResponse.error('Erreur de traitement de la réponse', statusCode);
    }
  }

  /// Gère les erreurs d'authentification (401)
  void _handleUnauthorized() {
    debugPrint('⚠️ Unauthorized access - clearing token');
    setToken(null);
  }

  /// Nettoyage des ressources
  void dispose() {
    _client.close();
  }
}

/// Classe générique pour wrapper les réponses de l'API
class ApiResponse<T> {
  final bool isSuccess;
  final T? data;
  final String? error;
  final int? statusCode;

  const ApiResponse._({
    required this.isSuccess,
    this.data,
    this.error,
    this.statusCode,
  });

  /// Constructeur pour les réponses de succès
  factory ApiResponse.success(T? data, [int? statusCode]) {
    return ApiResponse._(
      isSuccess: true,
      data: data,
      statusCode: statusCode,
    );
  }

  /// Constructeur pour les réponses d'erreur
  factory ApiResponse.error(String error, [int? statusCode]) {
    return ApiResponse._(
      isSuccess: false,
      error: error,
      statusCode: statusCode,
    );
  }

  /// Vérifie si la réponse est un succès
  bool get isError => !isSuccess;

  /// Vérifie si c'est une erreur d'authentification
  bool get isAuthError => statusCode == 401;

  /// Vérifie si c'est une erreur de validation
  bool get isValidationError => statusCode == 400;

  @override
  String toString() {
    if (isSuccess) {
      return 'ApiResponse.success(data: $data, statusCode: $statusCode)';
    } else {
      return 'ApiResponse.error(error: $error, statusCode: $statusCode)';
    }
  }
}