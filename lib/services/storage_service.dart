import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pdf_document.dart';

class StorageService {
  static SharedPreferences? _prefs;
  static const String _recentDocsKey = 'recent_documents';
  static const String _settingsKey = 'app_settings';

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static SharedPreferences get prefs {
    if (_prefs == null) {
      throw Exception('StorageService not initialized. Call init() first.');
    }
    return _prefs!;
  }

  // Recent Documents Management
  static Future<List<PDFDocument>> getRecentDocuments() async {
    try {
      final String? docsJson = prefs.getString(_recentDocsKey);
      if (docsJson == null) return [];

      final List<dynamic> docsList = json.decode(docsJson);
      return docsList
          .map((doc) => PDFDocument.fromJson(doc as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error loading recent documents: $e');
      return [];
    }
  }

  static Future<void> saveRecentDocument(PDFDocument document) async {
    try {
      List<PDFDocument> recentDocs = await getRecentDocuments();
      
      // Remove if already exists (to update position)
      recentDocs.removeWhere((doc) => doc.path == document.path);
      
      // Add to beginning
      recentDocs.insert(0, document);
      
      // Keep only last 10 documents
      if (recentDocs.length > 10) {
        recentDocs = recentDocs.take(10).toList();
      }

      final String docsJson = json.encode(
        recentDocs.map((doc) => doc.toJson()).toList(),
      );
      
      await prefs.setString(_recentDocsKey, docsJson);
    } catch (e) {
      print('Error saving recent document: $e');
    }
  }

  static Future<void> updateDocumentProgress(String path, int currentPage) async {
    try {
      List<PDFDocument> recentDocs = await getRecentDocuments();
      
      final int index = recentDocs.indexWhere((doc) => doc.path == path);
      if (index != -1) {
        recentDocs[index] = recentDocs[index].copyWith(
          currentPage: currentPage,
          lastOpened: DateTime.now(),
        );

        final String docsJson = json.encode(
          recentDocs.map((doc) => doc.toJson()).toList(),
        );
        
        await prefs.setString(_recentDocsKey, docsJson);
      }
    } catch (e) {
      print('Error updating document progress: $e');
    }
  }

  static Future<void> removeRecentDocument(String path) async {
    try {
      List<PDFDocument> recentDocs = await getRecentDocuments();
      recentDocs.removeWhere((doc) => doc.path == path);

      final String docsJson = json.encode(
        recentDocs.map((doc) => doc.toJson()).toList(),
      );
      
      await prefs.setString(_recentDocsKey, docsJson);
    } catch (e) {
      print('Error removing recent document: $e');
    }
  }

  static Future<void> clearRecentDocuments() async {
    try {
      await prefs.remove(_recentDocsKey);
    } catch (e) {
      print('Error clearing recent documents: $e');
    }
  }

  // App Settings
  static Future<Map<String, dynamic>> getAppSettings() async {
    try {
      final String? settingsJson = prefs.getString(_settingsKey);
      if (settingsJson == null) {
        return _getDefaultSettings();
      }
      return json.decode(settingsJson) as Map<String, dynamic>;
    } catch (e) {
      print('Error loading app settings: $e');
      return _getDefaultSettings();
    }
  }

  static Future<void> saveAppSettings(Map<String, dynamic> settings) async {
    try {
      final String settingsJson = json.encode(settings);
      await prefs.setString(_settingsKey, settingsJson);
    } catch (e) {
      print('Error saving app settings: $e');
    }
  }

  static Map<String, dynamic> _getDefaultSettings() {
    return {
      'theme_mode': 'light',
      'auto_night_mode': false,
      'remember_zoom_level': true,
      'default_zoom_level': 1.0,
      'show_page_numbers': true,
      'continuous_scroll': false,
    };
  }
}
