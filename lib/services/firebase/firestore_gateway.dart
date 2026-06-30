import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../platform/platform_capabilities.dart';
import 'firebase_auth_service.dart';
import 'rest/firebase_auth_rest_windows.dart';
import 'rest/firestore_rest_client.dart';

/// Gateway Firestore qui abstrait l'implémentation sous-jacente :
/// - **Mobile** (Android/iOS) : utilise le plugin natif `cloud_firestore`
///   (listeners temps réel, batches, offline persistence, etc.)
/// - **Desktop Windows** : utilise [FirestoreRestClient] (API REST Firestore)
///   car FlutterFire n'a pas de plugin Windows pour Cloud Firestore au 2026-06.
///
/// Le contrat exposé est plus simple que `FirebaseFirestore` natif : on expose
/// uniquement les primitives que PassKeyra utilise (get/set/delete/list/listen).
/// Les listeners temps réel sur desktop sont remplacés par un **polling**
/// périodique (cf. [startPolling]).
class FirestoreGateway {
  FirestoreGateway({
    required FirebaseAuthService firebaseAuthService,
    FirebaseFirestore? nativeFirestore,
    FirestoreRestClient? restClient,
    FirebaseAuthRestWindows? authRest,
  })  : _firebaseAuthService = firebaseAuthService,
        _nativeFirestore = isDesktop ? null : (nativeFirestore ?? FirebaseFirestore.instance),
        // Sur desktop, le restClient DOIT etre fourni par le caller (qui
        // reutilise l'instance FirebaseAuthRestWindows partagee). On ne cree
        // plus d'instance orpheline ici.
        _restClient = isDesktop ? restClient : null;

  final FirebaseAuthService _firebaseAuthService;
  final FirebaseFirestore? _nativeFirestore;
  final FirestoreRestClient? _restClient;

  void _log(String message) {
    if (kDebugMode) debugPrint(message);
  }

  // ===========================================================================
  // UID helper
  // ===========================================================================

  String? get _uid {
    final user = _firebaseAuthService.currentCloudUser;
    return user?.uid;
  }

  // ===========================================================================
  // Entries
  // ===========================================================================

  /// Lit une entry Firestore par ID. Retourne `null` si pas trouvée.
  Future<Map<String, dynamic>?> getEntry(String entryId) async {
    final uid = _uid;
    if (uid == null) return null;

    if (isDesktop) {
      final doc = await _restClient?.getDocument(
        'users/$uid/vault/data/entries/$entryId',
      );
      return doc?.fields;
    } else {
      final snapshot = await _nativeFirestore!
          .collection('users')
          .doc(uid)
          .collection('vault')
          .doc('data')
          .collection('entries')
          .doc(entryId)
          .get();
      return snapshot.data();
    }
  }

  /// Set (upsert) une entry.
  Future<bool> setEntry(String entryId, Map<String, dynamic> data) async {
    final uid = _uid;
    if (uid == null) return false;

    if (isDesktop) {
      return await _restClient?.setDocument(
            'users/$uid/vault/data/entries/$entryId',
            data,
          ) ??
          false;
    } else {
      await _nativeFirestore!
          .collection('users')
          .doc(uid)
          .collection('vault')
          .doc('data')
          .collection('entries')
          .doc(entryId)
          .set(data, SetOptions(merge: true));
      return true;
    }
  }

  /// Delete une entry.
  Future<bool> deleteEntry(String entryId) async {
    final uid = _uid;
    if (uid == null) return false;

    if (isDesktop) {
      return await _restClient?.deleteDocument(
            'users/$uid/vault/data/entries/$entryId',
          ) ??
          false;
    } else {
      await _nativeFirestore!
          .collection('users')
          .doc(uid)
          .collection('vault')
          .doc('data')
          .collection('entries')
          .doc(entryId)
          .delete();
      return true;
    }
  }

  /// Liste toutes les entries Firestore.
  Future<List<Map<String, dynamic>>> listEntries() async {
    final uid = _uid;
    if (uid == null) return [];

    if (isDesktop) {
      final docs = await _restClient?.listCollection(
            'users/$uid/vault/data/entries',
          ) ??
          [];
      return docs
          .map((d) => <String, dynamic>{
                'id': d.id,
                ...d.fields,
              })
          .toList();
    } else {
      final snapshot = await _nativeFirestore!
          .collection('users')
          .doc(uid)
          .collection('vault')
          .doc('data')
          .collection('entries')
          .get();
      return snapshot.docs
          .map((d) => <String, dynamic>{'id': d.id, ...d.data()})
          .toList();
    }
  }

  // ===========================================================================
  // Categories
  // ===========================================================================

  /// Lit le document catégories.
  Future<Map<String, dynamic>?> getCategories() async {
    final uid = _uid;
    if (uid == null) return null;

    if (isDesktop) {
      final doc = await _restClient?.getDocument('users/$uid/vault/categories');
      return doc?.fields;
    } else {
      final snapshot = await _nativeFirestore!
          .collection('users')
          .doc(uid)
          .collection('vault')
          .doc('categories')
          .get();
      return snapshot.data();
    }
  }

  /// Set le document catégories.
  Future<bool> setCategories(Map<String, dynamic> data) async {
    final uid = _uid;
    if (uid == null) return false;

    if (isDesktop) {
      return await _restClient?.setDocument(
            'users/$uid/vault/categories',
            data,
          ) ??
          false;
    } else {
      await _nativeFirestore!
          .collection('users')
          .doc(uid)
          .collection('vault')
          .doc('categories')
          .set(data, SetOptions(merge: true));
      return true;
    }
  }

  // ===========================================================================
  // Key fingerprint
  // ===========================================================================

  Future<Map<String, dynamic>?> getKeyFingerprint() async {
    final uid = _uid;
    if (uid == null) return null;

    if (isDesktop) {
      final doc =
          await _restClient?.getDocument('users/$uid/vault/key_fingerprint');
      return doc?.fields;
    } else {
      final snapshot = await _nativeFirestore!
          .collection('users')
          .doc(uid)
          .collection('vault')
          .doc('key_fingerprint')
          .get();
      return snapshot.data();
    }
  }

  Future<bool> setKeyFingerprint(Map<String, dynamic> data) async {
    final uid = _uid;
    if (uid == null) return false;

    if (isDesktop) {
      return await _restClient?.setDocument(
            'users/$uid/vault/key_fingerprint',
            data,
          ) ??
          false;
    } else {
      await _nativeFirestore!
          .collection('users')
          .doc(uid)
          .collection('vault')
          .doc('key_fingerprint')
          .set(data);
      return true;
    }
  }

  // ===========================================================================
  // Native-only : listeners temps réel (mobile)
  // ===========================================================================

  /// Snapshot listener sur les entries (mobile uniquement). Sur desktop,
  /// retourne null — utiliser [startPolling] à la place.
  Stream<QuerySnapshot<Map<String, dynamic>>>? entriesSnapshots() {
    if (isDesktop) return null;
    final uid = _uid;
    if (uid == null) return null;
    return _nativeFirestore!
        .collection('users')
        .doc(uid)
        .collection('vault')
        .doc('data')
        .collection('entries')
        .snapshots();
  }

  /// Snapshot listener sur le document catégories (mobile uniquement).
  Stream<DocumentSnapshot<Map<String, dynamic>>>? categoriesSnapshots() {
    if (isDesktop) return null;
    final uid = _uid;
    if (uid == null) return null;
    return _nativeFirestore!
        .collection('users')
        .doc(uid)
        .collection('vault')
        .doc('categories')
        .snapshots();
  }

  // ===========================================================================
  // Batch write (mobile natif). Desktop les fait en série via REST.
  // ===========================================================================

  /// Écrit plusieurs entries en une seule opération.
  /// Mobile = batch Firestore. Desktop = séquentiel REST (pas de batch REST).
  Future<void> batchSetEntries(Map<String, Map<String, dynamic>> entries) async {
    final uid = _uid;
    if (uid == null) return;

    if (isDesktop) {
      for (final entry in entries.entries) {
        await _restClient?.setDocument(
          'users/$uid/vault/data/entries/${entry.key}',
          entry.value,
        );
      }
    } else {
      final batch = _nativeFirestore!.batch();
      final collection = _nativeFirestore!
          .collection('users')
          .doc(uid)
          .collection('vault')
          .doc('data')
          .collection('entries');
      for (final entry in entries.entries) {
        batch.set(collection.doc(entry.key), entry.value, SetOptions(merge: true));
      }
      await batch.commit();
    }
  }
}
