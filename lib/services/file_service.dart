import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../models/pdf_document.dart';
import 'storage_service.dart';

class FileService {

  // Pick a PDF file using file picker
  static Future<PDFDocument?> pickPDFFile() async {
    try {
      // Use file picker without strict permission requirements
      // The file picker handles permissions internally
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
        allowCompression: false,
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        final fileName = result.files.single.name;
        final fileSize = result.files.single.size;
        
        // Verify the file exists and is accessible
        final file = File(filePath);
        if (!await file.exists()) {
          throw Exception('Selected file is not accessible');
        }

        // Create PDF document from picked file
        PDFDocument document = PDFDocument(
          path: filePath,
          name: fileName,
          totalPages: 0, // Will be updated when PDF is loaded
          currentPage: 1,
          lastOpened: DateTime.now(),
          fileSize: fileSize,
        );

        return document;
      }
    } catch (e) {
      print('Error picking PDF file: $e');
      // Re-throw with more user-friendly message
      if (e.toString().contains('permission')) {
        throw Exception('Permission denied. Please grant storage access in device settings.');
      } else {
        throw Exception('Failed to select PDF file. Please try again.');
      }
    }
    return null;
  }

  // Check if file exists
  static Future<bool> fileExists(String path) async {
    try {
      final file = File(path);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  // Get file info
  static Future<Map<String, dynamic>?> getFileInfo(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        final stat = await file.stat();
        return {
          'size': stat.size,
          'modified': stat.modified,
          'accessed': stat.accessed,
        };
      }
    } catch (e) {
      print('Error getting file info: $e');
    }
    return null;
  }

  // Get recent PDF files from device storage (simplified - disabled for now)
  static Future<List<File>> getRecentPDFFiles() async {
    // For now, return empty list to avoid permission issues
    // Users can use the file picker instead
    return [];
  }

  // Convert File to PDFDocument
  static Future<PDFDocument> fileToPDFDocument(File file) async {
    final stat = await file.stat();
    final fileName = file.path.split('/').last;

    return PDFDocument(
      path: file.path,
      name: fileName,
      totalPages: 0, // Will be updated when PDF is loaded
      currentPage: 1,
      lastOpened: DateTime.now(),
      fileSize: stat.size,
    );
  }

  // Save document to recent files
  static Future<void> saveToRecentFiles(PDFDocument document) async {
    await StorageService.saveRecentDocument(document);
  }

  // Update document page count after loading
  static Future<void> updateDocumentPageCount(String path, int totalPages) async {
    try {
      List<PDFDocument> recentDocs = await StorageService.getRecentDocuments();
      final index = recentDocs.indexWhere((doc) => doc.path == path);
      
      if (index != -1) {
        final updatedDoc = recentDocs[index].copyWith(totalPages: totalPages);
        await StorageService.saveRecentDocument(updatedDoc);
      }
    } catch (e) {
      print('Error updating document page count: $e');
    }
  }
}
