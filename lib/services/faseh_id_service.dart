import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class FasehIdService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final Random _random = Random.secure();

  // Removed confusing characters:
  // 0, O, 1, I, L
  static const String _allowedCharacters =
      'ABCDEFGHJKMNPQRSTUVWXYZ23456789';

  /// Creates a readable ID such as:
  /// FSH-7K2M-9Q8D
  String _generateCandidate() {
    String generatePart(int length) {
      return List.generate(
        length,
        (_) => _allowedCharacters[
            _random.nextInt(_allowedCharacters.length)],
      ).join();
    }

    return 'FSH-${generatePart(4)}-${generatePart(4)}';
  }

  /// Generates an ID that does not currently exist
  /// in the faseh_ids collection.
  Future<String> generateUniqueFasehId() async {
    const int maxAttempts = 10;

    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      final String candidate = _generateCandidate();

      final DocumentSnapshot snapshot =
          await _db.collection('faseh_ids').doc(candidate).get();

      if (!snapshot.exists) {
        return candidate;
      }
    }

    throw Exception('Unable to generate a unique Faseh ID.');
  }

  /// Normalizes manually entered Faseh IDs.
  ///
  /// Example:
  /// " fsh-7k2m-9q8d "
  /// becomes:
  /// "FSH-7K2M-9Q8D"
  String normalizeFasehId(String value) {
    return value.trim().toUpperCase();
  }
}