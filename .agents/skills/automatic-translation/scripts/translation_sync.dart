import 'dart:convert';
import 'dart:io';
import 'package:translator/translator.dart';

void main() async {
  final translator = GoogleTranslator();
  final dir = Directory('/Users/ferhatnas/App/EXFINOPS/assets/translations');
  
  // Read TR
  final trFile = File('${dir.path}/tr.json');
  final trContent = json.decode(await trFile.readAsString()) as Map<String, dynamic>;

  // Target files
  final targetFiles = dir.listSync().whereType<File>().where((f) => f.path.endsWith('.json') && !f.path.endsWith('tr.json')).toList();

  for (final file in targetFiles) {
    print('Processing ${file.path}...');
    final langCode = file.uri.pathSegments.last.split('.').first.split('-').first; // 'ar-iq' -> 'ar'
    final content = json.decode(await file.readAsString()) as Map<String, dynamic>;
    
    bool updated = false;

    Future<void> syncMap(Map<String, dynamic> source, Map<String, dynamic> target, String path) async {
      for (final key in source.keys) {
        if (!target.containsKey(key)) {
          if (source[key] is String) {
            String value = source[key];
            // Translate
            try {
              if (value.trim().isEmpty) {
                  target[key] = value;
              } else {
                  // Some basic replacements to prevent breaking params like {username}
                  final placeholderPattern = RegExp(r'\{.*?\}');
                  final placeholders = <String>[];
                  String textToTranslate = value.replaceAllMapped(placeholderPattern, (match) {
                      placeholders.add(match.group(0)!);
                      return ' [[[PLACEHOLDER_${placeholders.length - 1}]]] ';
                  });

                  var translation = await translator.translate(textToTranslate, from: 'tr', to: langCode);
                  String translatedText = translation.text;

                  for (int i = 0; i < placeholders.length; i++) {
                      translatedText = translatedText.replaceAll('[[[PLACEHOLDER_$i]]]', placeholders[i]);
                      // Handle possible casing/spacing issues caused by translator
                      translatedText = translatedText.replaceAll(' [[[ PLACEHOLDER_$i ]]] ', placeholders[i]);
                      translatedText = translatedText.replaceAll('[[[ PLACEHOLDER_$i ]]]', placeholders[i]);
                      translatedText = translatedText.replaceAll(RegExp(r'\[\s*\[\s*\[\s*PLACEHOLDER_' + i.toString() + r'\s*\]\s*\]\s*\]', caseSensitive: false), placeholders[i]);
                  }

                  target[key] = translatedText.trim();
              }
              print('Translated ${path != '' ? "$path." : ""}$key -> ${target[key]} ($langCode)');
              updated = true;
            } catch (e) {
              print('Error translating $value to $langCode: $e');
              target[key] = source[key]; // fallback to TR
              updated = true;
            }
          } else if (source[key] is Map) {
            target[key] = <String, dynamic>{};
            await syncMap(source[key] as Map<String, dynamic>, target[key] as Map<String, dynamic>, '$path$key.');
            updated = true;
          }
        } else if (source[key] is Map && target[key] is Map) {
          await syncMap(source[key] as Map<String, dynamic>, target[key] as Map<String, dynamic>, '$path$key.');
        }
      }
    }

    await syncMap(trContent, content, '');

    if (updated) {
      const encoder = JsonEncoder.withIndent('    ');
      final newJson = encoder.convert(content);
      await file.writeAsString(newJson);
      print('Saved ${file.path}');
    } else {
      print('No changes for ${file.path}');
    }
  }
}
