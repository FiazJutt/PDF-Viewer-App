import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import '../models/pdf_document.dart';
import '../services/file_service.dart';
import '../services/storage_service.dart';

class PDFController extends ChangeNotifier {
  PDFViewController? _pdfViewController;
  PDFDocument? _currentDocument;
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  int _totalPages = 0;
  double _zoomLevel = 1.0;
  bool _showControls = true;

  // Getters
  PDFViewController? get pdfViewController => _pdfViewController;
  PDFDocument? get currentDocument => _currentDocument;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  double get zoomLevel => _zoomLevel;
  bool get showControls => _showControls;

  // Loading state management
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  // Load PDF document
  Future<void> loadDocument(PDFDocument document) async {
    try {
      _setLoading(true);
      _setError(null);

      // Check if file exists
      if (!await FileService.fileExists(document.path)) {
        throw Exception('PDF file not found');
      }

      _currentDocument = document;
      _currentPage = document.currentPage;
      
      // Save to recent documents
      await FileService.saveToRecentFiles(document);
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to load PDF: $e');
    } finally {
      _setLoading(false);
    }
  }

  // PDF view controller ready callback
  void onPDFViewCreated(PDFViewController controller) {
    _pdfViewController = controller;
    notifyListeners();
  }

  // PDF document ready callback
  void onDocumentReady(int totalPages) {
    _totalPages = totalPages;
    
    // Update document with correct page count
    if (_currentDocument != null) {
      FileService.updateDocumentPageCount(_currentDocument!.path, totalPages);
      _currentDocument = _currentDocument!.copyWith(totalPages: totalPages);
    }
    
    // Go to last read page
    if (_currentPage > 1 && _currentPage <= totalPages) {
      goToPage(_currentPage);
    }
    
    notifyListeners();
  }

  // Page changed callback
  void onPageChanged(int page) {
    _currentPage = page;
    
    // Update progress in storage
    if (_currentDocument != null) {
      StorageService.updateDocumentProgress(_currentDocument!.path, page);
      _currentDocument = _currentDocument!.copyWith(currentPage: page);
    }
    
    notifyListeners();
  }

  // Navigation methods
  Future<void> goToPage(int page) async {
    if (_pdfViewController != null && page > 0 && page <= _totalPages) {
      await _pdfViewController!.setPage(page - 1); // PDF view uses 0-based indexing
    }
  }

  Future<void> nextPage() async {
    if (_currentPage < _totalPages) {
      await goToPage(_currentPage + 1);
    }
  }

  Future<void> previousPage() async {
    if (_currentPage > 1) {
      await goToPage(_currentPage - 1);
    }
  }

  Future<void> goToFirstPage() async {
    await goToPage(1);
  }

  Future<void> goToLastPage() async {
    await goToPage(_totalPages);
  }

  // Zoom methods
  Future<void> zoomIn() async {
    if (_pdfViewController != null && _zoomLevel < 3.0) {
      _zoomLevel = (_zoomLevel + 0.25).clamp(0.5, 3.0);
      notifyListeners();
    }
  }

  Future<void> zoomOut() async {
    if (_pdfViewController != null && _zoomLevel > 0.5) {
      _zoomLevel = (_zoomLevel - 0.25).clamp(0.5, 3.0);
      notifyListeners();
    }
  }

  Future<void> resetZoom() async {
    _zoomLevel = 1.0;
    notifyListeners();
  }

  Future<void> setZoom(double zoom) async {
    _zoomLevel = zoom.clamp(0.5, 3.0);
    notifyListeners();
  }

  // Control visibility
  void toggleControls() {
    _showControls = !_showControls;
    notifyListeners();
  }

  void showControlsPanel() {
    _showControls = true;
    notifyListeners();
  }

  void hideControlsPanel() {
    _showControls = false;
    notifyListeners();
  }

  // Document info
  String get documentProgress {
    if (_totalPages == 0) return '0%';
    return '${((_currentPage / _totalPages) * 100).toInt()}%';
  }

  String get pageInfo {
    return '$_currentPage of $_totalPages';
  }

  // Reset controller
  void reset() {
    _pdfViewController = null;
    _currentDocument = null;
    _isLoading = false;
    _error = null;
    _currentPage = 1;
    _totalPages = 0;
    _zoomLevel = 1.0;
    _showControls = true;
    notifyListeners();
  }

  // Error handling
  void onDocumentError(dynamic error) {
    _setError('Error loading PDF: $error');
  }

  @override
  void dispose() {
    _pdfViewController = null;
    super.dispose();
  }
}
