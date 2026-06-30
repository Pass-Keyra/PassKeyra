import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'firebase_auth_rest_windows.dart';

/// Document Firestore minimaliste — l'équivalent d'un `DocumentSnapshot` mais
/// purifié en map JSON (sans dépendance au plugin `cloud_firestore`).
@immutable
class FirestoreRestDocument {
  const FirestoreRestDocument({
    required this.id,
    required this.fields,
    required this.updateTime,
  });

  final String id;
  final Map<String, dynamic> fields;
  final DateTime updateTime;
}

/// Client Firestore REST pour PassKeyra Desktop Windows.
///
/// Au 2026-06 il n'y a pas de plugin natif `cloud_firestore_windows` dans
/// FlutterFire. On parle directement à l'API REST :
/// `https://firestore.googleapis.com/v1/projects/{project}/databases/(default)/documents/{path}`.
///
/// **Listener temps réel** : l'API Firestore REST a un endpoint `watch` qui
/// utilise HTTP/2 server-sent events, mais c'est complexe à câbler en Dart
/// pur. Pour V1 desktop, on **remplace par un polling** régulier (toutes les
/// 30s par défaut). C'est moins réactif mais largement suffisant pour un
/// gestionnaire de mots de passe (les changements sont rares).
///
/// **Encodage des types Firestore** : les fields REST utilisent une forme
/// typée explicite : `{stringValue: "x"}`, `{integerValue: "42"}`,
/// `{timestampValue: "2026-...Z"}`, etc. On encapsule la conversion dans
/// [_encodeFields] / [_decodeFields].
class FirestoreRestClient {
  FirestoreRestClient({
    required this.authRest,
    required this.projectId,
    http.Client? httpClient,
  }) : _http = httpClient ?? http.Client();

  final FirebaseAuthRestWindows authRest;
  final String projectId;
  final http.Client _http;

  void _log(String message) {
    if (kDebugMode) debugPrint(message);
  }

  String get _baseUrl =>
      'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents';

  Future<Map<String, String>?> _authHeaders() async {
    final idToken = await authRest.getValidIdToken();
    if (idToken == null) return null;
    return {
      'Authorization': 'Bearer $idToken',
      'Content-Type': 'application/json',
    };
  }

  /// GET un document. Retourne null si pas trouvé (HTTP 404) ou si pas signé.
  Future<FirestoreRestDocument?> getDocument(String path) async {
    final headers = await _authHeaders();
    if (headers == null) return null;
    try {
      final response = await _http.get(
        Uri.parse('$_baseUrl/$path'),
        headers: headers,
      );
      if (response.statusCode == 404) return null;
      if (response.statusCode != 200) {
        _log('FirestoreRest GET $path → HTTP ${response.statusCode}: ${response.body}');
        return null;
      }
      return _parseDocumentResponse(jsonDecode(response.body) as Map<String, dynamic>, path);
    } catch (e) {
      _log('FirestoreRest GET erreur: $e');
      return null;
    }
  }

  /// PATCH (upsert) un document. Crée s'il n'existe pas.
  Future<bool> setDocument(String path, Map<String, dynamic> fields) async {
    final headers = await _authHeaders();
    if (headers == null) return false;
    try {
      // updateMask omis = écrasement complet. Firestore REST accepte ça
      // si updateMask absent (= merge=false).
      final response = await _http.patch(
        Uri.parse('$_baseUrl/$path'),
        headers: headers,
        body: jsonEncode({'fields': _encodeFields(fields)}),
      );
      if (response.statusCode != 200) {
        _log('FirestoreRest PATCH $path → HTTP ${response.statusCode}: ${response.body}');
        return false;
      }
      return true;
    } catch (e) {
      _log('FirestoreRest PATCH erreur: $e');
      return false;
    }
  }

  /// DELETE un document. Idempotent (succès même si déjà absent).
  Future<bool> deleteDocument(String path) async {
    final headers = await _authHeaders();
    if (headers == null) return false;
    try {
      final response = await _http.delete(
        Uri.parse('$_baseUrl/$path'),
        headers: headers,
      );
      // 200 = OK, 404 = déjà absent (idempotent OK).
      if (response.statusCode != 200 && response.statusCode != 404) {
        _log('FirestoreRest DELETE $path → HTTP ${response.statusCode}: ${response.body}');
        return false;
      }
      return true;
    } catch (e) {
      _log('FirestoreRest DELETE erreur: $e');
      return false;
    }
  }

  /// Liste tous les documents d'une collection (paginé si > 100). Retourne
  /// la liste complète. Utilisé par le polling pour détecter ajouts/maj.
  Future<List<FirestoreRestDocument>> listCollection(String collectionPath) async {
    final headers = await _authHeaders();
    if (headers == null) return [];
    final result = <FirestoreRestDocument>[];
    String? nextPageToken;
    try {
      do {
        final uri = Uri.parse(
                '$_baseUrl/$collectionPath?pageSize=100${nextPageToken != null ? '&pageToken=$nextPageToken' : ''}');
        final response = await _http.get(uri, headers: headers);
        if (response.statusCode != 200) {
          _log('FirestoreRest LIST $collectionPath → HTTP ${response.statusCode}: ${response.body}');
          break;
        }
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final docs = (body['documents'] as List<dynamic>?) ?? const [];
        for (final raw in docs) {
          final doc = _parseDocumentResponse(raw as Map<String, dynamic>, null);
          if (doc != null) result.add(doc);
        }
        nextPageToken = body['nextPageToken'] as String?;
      } while (nextPageToken != null);
    } catch (e) {
      _log('FirestoreRest LIST erreur: $e');
    }
    return result;
  }

  // ===========================================================================
  // Encodage typage Firestore REST
  // ===========================================================================

  /// Convertit un map Dart {key: value} en {key: {<type>Value: ...}} attendu
  /// par l'API REST. Supporte les types qu'on utilise dans PassKeyra :
  /// String, int, bool, DateTime (→ timestampValue), null, Map (→ mapValue).
  Map<String, dynamic> _encodeFields(Map<String, dynamic> fields) {
    final encoded = <String, dynamic>{};
    fields.forEach((key, value) {
      encoded[key] = _encodeValue(value);
    });
    return encoded;
  }

  Map<String, dynamic> _encodeValue(Object? value) {
    if (value == null) return {'nullValue': null};
    if (value is bool) return {'booleanValue': value};
    if (value is int) return {'integerValue': value.toString()};
    if (value is double) return {'doubleValue': value};
    if (value is String) return {'stringValue': value};
    if (value is DateTime) {
      return {'timestampValue': value.toUtc().toIso8601String()};
    }
    if (value is Map) {
      return {
        'mapValue': {
          'fields': _encodeFields(value.cast<String, dynamic>()),
        }
      };
    }
    if (value is List) {
      return {
        'arrayValue': {
          'values': value.map((v) => _encodeValue(v)).toList(),
        }
      };
    }
    // Fallback : sérialiser en string JSON.
    return {'stringValue': jsonEncode(value)};
  }

  /// Convertit un map {key: {<type>Value: ...}} venu de Firestore en
  /// {key: value} Dart natif.
  Map<String, dynamic> _decodeFields(Map<String, dynamic> raw) {
    final decoded = <String, dynamic>{};
    raw.forEach((key, typedValue) {
      decoded[key] = _decodeValue(typedValue as Map<String, dynamic>);
    });
    return decoded;
  }

  Object? _decodeValue(Map<String, dynamic> typed) {
    if (typed.containsKey('nullValue')) return null;
    if (typed.containsKey('booleanValue')) return typed['booleanValue'] as bool;
    if (typed.containsKey('integerValue')) {
      return int.tryParse(typed['integerValue'] as String) ?? 0;
    }
    if (typed.containsKey('doubleValue')) return typed['doubleValue'] as double;
    if (typed.containsKey('stringValue')) return typed['stringValue'] as String;
    if (typed.containsKey('timestampValue')) {
      return DateTime.parse(typed['timestampValue'] as String);
    }
    if (typed.containsKey('mapValue')) {
      final mapFields = ((typed['mapValue'] as Map<String, dynamic>?)?['fields'] as Map<String, dynamic>?) ?? {};
      return _decodeFields(mapFields);
    }
    if (typed.containsKey('arrayValue')) {
      final values = ((typed['arrayValue'] as Map<String, dynamic>?)?['values'] as List<dynamic>?) ?? const [];
      return values.map((v) => _decodeValue(v as Map<String, dynamic>)).toList();
    }
    return null;
  }

  FirestoreRestDocument? _parseDocumentResponse(
    Map<String, dynamic> raw,
    String? overridePath,
  ) {
    final name = (raw['name'] as String?) ?? overridePath ?? '';
    final id = name.split('/').last;
    final fields = (raw['fields'] as Map<String, dynamic>?) ?? const {};
    final updateTimeRaw = raw['updateTime'] as String?;
    final updateTime = updateTimeRaw != null ? DateTime.parse(updateTimeRaw) : DateTime.now();
    return FirestoreRestDocument(
      id: id,
      fields: _decodeFields(fields),
      updateTime: updateTime,
    );
  }
}
