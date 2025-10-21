import 'package:flutter/material.dart';

class TextUtils {
  /// Extraer hashtags del texto
  static List<String> extractHashtags(String text) {
    final RegExp hashtagRegex = RegExp(r'#(\w+)', unicode: true);
    final matches = hashtagRegex.allMatches(text);
    
    return matches
        .map((match) => match.group(1)!.toLowerCase())
        .toSet() // Eliminar duplicados
        .toList();
  }

  /// Extraer menciones del texto
  static List<String> extractMentions(String text) {
    final RegExp mentionRegex = RegExp(r'@(\w+)', unicode: true);
    final matches = mentionRegex.allMatches(text);
    
    return matches
        .map((match) => match.group(1)!.toLowerCase())
        .toSet() // Eliminar duplicados
        .toList();
  }

  /// Formatear texto con hashtags y menciones clickeables
  static List<TextSpan> formatTextWithLinks(
    String text, {
    TextStyle? defaultStyle,
    TextStyle? hashtagStyle,
    TextStyle? mentionStyle,
    Function(String)? onHashtagTap,
    Function(String)? onMentionTap,
  }) {
    final List<TextSpan> spans = [];
    final RegExp pattern = RegExp(r'(#\w+|@\w+)', unicode: true);
    int lastIndex = 0;

    for (final match in pattern.allMatches(text)) {
      // Agregar texto normal antes del match
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: text.substring(lastIndex, match.start),
          style: defaultStyle,
        ));
      }

      // Agregar hashtag o mención
      final matchText = match.group(0)!;
      if (matchText.startsWith('#')) {
        spans.add(TextSpan(
          text: matchText,
          style: hashtagStyle,
          // recognizer: onHashtagTap != null ? (TapGestureRecognizer()..onTap = () => onHashtagTap(matchText)) : null,
        ));
      } else if (matchText.startsWith('@')) {
        spans.add(TextSpan(
          text: matchText,
          style: mentionStyle,
          // recognizer: onMentionTap != null ? (TapGestureRecognizer()..onTap = () => onMentionTap(matchText)) : null,
        ));
      }

      lastIndex = match.end;
    }

    // Agregar texto restante
    if (lastIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastIndex),
        style: defaultStyle,
      ));
    }

    return spans;
  }
}

