class ApolloStringUtils {
  /// Sanitizes a string for sorting by removing special characters like ' and ( ).
  /// It skips leading symbols and ensures the string starts with a letter or number.
  static String toSortable(String text) {
    if (text.isEmpty) return text;
    
    // Remove non-alphanumeric characters using Unicode-aware regex.
    // This skips characters like ", ', (, ., !, etc.
    return text
        .replaceAll(RegExp(r'[^\p{L}\p{N}\s]', unicode: true), '')
        .toLowerCase()
        .trim();
  }
}