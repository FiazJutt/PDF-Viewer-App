import 'dart:io';
import 'package:flutter/material.dart';
import '../models/pdf_document.dart';
import '../services/file_service.dart';
import '../services/storage_service.dart';

class HomeController extends ChangeNotifier {
  List<PDFDocument> _recentDocuments = [];
  List<File> _devicePDFs = [];
  bool _isLoading = false;
  String? _error;
  bool _showDevicePDFs = false;

  // Getters
  List<PDFDocument> get recentDocuments => _recentDocuments;
  List<File> get devicePDFs => _devicePDFs;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get showDevicePDFs => _showDevicePDFs;

  // Initialize controller
  Future<void> init() async {
    await loadRecentDocuments();
  }

  // Loading state management
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  // Load recent documents
  Future<void> loadRecentDocuments() async {
    try {
      _setLoading(true);
      _setError(null);
      
      _recentDocuments = await StorageService.getRecentDocuments();
      
      // Filter out documents that no longer exist
      List<PDFDocument> validDocuments = [];
      for (PDFDocument doc in _recentDocuments) {
        if (await FileService.fileExists(doc.path)) {
          validDocuments.add(doc);
        }
      }
      
      // Update storage if some files were removed
      if (validDocuments.length != _recentDocuments.length) {
        await StorageService.clearRecentDocuments();
        for (PDFDocument doc in validDocuments) {
          await StorageService.saveRecentDocument(doc);
        }
        _recentDocuments = validDocuments;
      }
      
    } catch (e) {
      _setError('Failed to load recent documents: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Load device PDFs
  Future<void> loadDevicePDFs() async {
    try {
      _setLoading(true);
      _setError(null);
      
      _devicePDFs = await FileService.getRecentPDFFiles();
      _showDevicePDFs = true;
      
    } catch (e) {
      _setError('Failed to load device PDFs: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Pick PDF file
  Future<PDFDocument?> pickPDFFile() async {
    try {
      _setLoading(true);
      _setError(null);
      
      PDFDocument? document = await FileService.pickPDFFile();
      
      if (document != null) {
        await refresh();
        return document;
      }
      
    } catch (e) {
      String errorMessage = e.toString().replaceAll('Exception: ', '');
      _setError(errorMessage);
      print('Error in pickPDFFile: $e');
    } finally {
      _setLoading(false);
    }
    return null;
  }

  // Remove document from recent list
  Future<void> removeRecentDocument(String path) async {
    try {
      await StorageService.removeRecentDocument(path);
      _recentDocuments.removeWhere((doc) => doc.path == path);
      notifyListeners();
    } catch (e) {
      _setError('Failed to remove document: $e');
    }
  }

  // Clear all recent documents
  Future<void> clearRecentDocuments() async {
    try {
      await StorageService.clearRecentDocuments();
      _recentDocuments.clear();
      notifyListeners();
    } catch (e) {
      _setError('Failed to clear recent documents: $e');
    }
  }

  // Convert File to PDFDocument
  Future<PDFDocument> convertFileToPDFDocument(File file) async {
    return await FileService.fileToPDFDocument(file);
  }

  // Toggle device PDFs view
  void toggleDevicePDFsView() {
    _showDevicePDFs = !_showDevicePDFs;
    if (_showDevicePDFs && _devicePDFs.isEmpty) {
      loadDevicePDFs();
    } else {
      notifyListeners();
    }
  }

  // Refresh data
  Future<void> refresh() async {
    await loadRecentDocuments();
    if (_showDevicePDFs) {
      await loadDevicePDFs();
    }
  }

  // Search functionality
  List<PDFDocument> searchRecentDocuments(String query) {
    if (query.isEmpty) return _recentDocuments;
    
    return _recentDocuments.where((doc) {
      return doc.name.toLowerCase().contains(query.toLowerCase()) ||
             doc.path.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  List<File> searchDevicePDFs(String query) {
    if (query.isEmpty) return _devicePDFs;
    
    return _devicePDFs.where((file) {
      final fileName = file.path.split('/').last;
      return fileName.toLowerCase().contains(query.toLowerCase()) ||
             file.path.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  // Sort methods
  void sortRecentDocumentsByName() {
    _recentDocuments.sort((a, b) => a.name.compareTo(b.name));
    notifyListeners();
  }

  void sortRecentDocumentsByDate() {
    _recentDocuments.sort((a, b) => b.lastOpened.compareTo(a.lastOpened));
    notifyListeners();
  }

  void sortRecentDocumentsBySize() {
    _recentDocuments.sort((a, b) => b.fileSize.compareTo(a.fileSize));
    notifyListeners();
  }

  // Get document statistics
  Map<String, dynamic> getDocumentStats() {
    int totalDocs = _recentDocuments.length;
    int totalSize = _recentDocuments.fold(0, (sum, doc) => sum + doc.fileSize);
    
    return {
      'totalDocuments': totalDocs,
      'totalSize': totalSize,
      'averageSize': totalDocs > 0 ? totalSize / totalDocs : 0,
    };
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
