// lib/validators/matricule_validator.dart

// lib/validators/matricule_validator.dart

class MatriculeValidator {
  static String? validate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le matricule est requis';
    }

    // Expect format: NN|L|NNNNN (e.g. 15|ب|3005)
    final RegExp pattern = RegExp(r'^\d{1,2}\|[\u0600-\u06FF]\|\d{1,5}$');

    if (!pattern.hasMatch(value)) {
      return 'Format invalide. Exemple : 1|ب|10000';
    }

    return null; // valid
  }
}




