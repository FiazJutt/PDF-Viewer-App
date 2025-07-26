import 'dart:io';
import 'package:flutter/material.dart';
import '../controllers/home_controller.dart';
import '../models/pdf_document.dart';
import '../widgets/document_card.dart';
import '../widgets/empty_state.dart';
import 'pdf_viewer_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late HomeController _homeController;
  late TabController _tabController;
  String _searchQuery = '';
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    _homeController = HomeController();
    _tabController = TabController(length: 1, vsync: this); // Single tab now
    _initializeController();
  }

  Future<void> _initializeController() async {
    await _homeController.init();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _homeController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Clean Header
            _buildCleanHeader(),

            // Search Bar (only show when needed)
            if (_searchQuery.isNotEmpty || _showSearch)
              _buildMinimalSearchBar(),

            // Content
            Expanded(
              child: _buildRecentTab(), // Single view now
            ),
          ],
        ),
      ),
      floatingActionButton: _buildCleanFAB(),
    );
  }

  Widget _buildRecentTab() {
    return AnimatedBuilder(
      animation: _homeController,
      builder: (context, child) {
        if (_homeController.isLoading &&
            _homeController.recentDocuments.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (_homeController.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  _homeController.error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red[600]),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    _homeController.clearError();
                    _refreshDocuments();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final filteredDocs = _homeController.searchRecentDocuments(
          _searchQuery,
        );

        if (filteredDocs.isEmpty) {
          return EmptyState(
            icon: Icons.description,
            message: _searchQuery.isEmpty
                ? 'No recent documents\nOpen a PDF to get started!'
                : 'No documents match your search',
            actionText: _searchQuery.isEmpty ? 'Open PDF' : null,
            onAction: _searchQuery.isEmpty ? _pickPDFFile : null,
          );
        }

        return RefreshIndicator(
          onRefresh: _refreshDocuments,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: filteredDocs.length,
            itemBuilder: (context, index) {
              final document = filteredDocs[index];
              return DocumentCard(
                document: document,
                onTap: () => _openDocument(document),
                onRemove: () => _removeDocument(document.path),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _openDocument(PDFDocument document) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PDFViewerScreen(document: document),
      ),
    ).then((_) => _refreshDocuments());
  }

  Future<void> _openFileFromDevice(File file) async {
    try {
      final document = await _homeController.convertFileToPDFDocument(file);
      await _openDocument(document);
    } catch (e) {
      _showErrorDialog('Failed to open PDF: $e');
    }
  }

  Future<void> _pickPDFFile() async {
    try {
      final document = await _homeController.pickPDFFile();
      if (document != null) {
        await _openDocument(document);
      } else if (_homeController.error != null) {
        // Show permission dialog if permission-related error
        if (_homeController.error!.toLowerCase().contains('permission')) {
          _showPermissionDialog();
        } else {
          _showErrorDialog(_homeController.error!);
        }
      }
    } catch (e) {
      _showErrorDialog('Failed to pick PDF file: $e');
    }
  }

  Future<void> _removeDocument(String path) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Document'),
        content: const Text('Remove this document from recent list?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _homeController.removeRecentDocument(path);
    }
  }

  Future<void> _refreshDocuments() async {
    await _homeController.refresh();
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'sort_name':
        _homeController.sortRecentDocumentsByName();
        break;
      case 'sort_date':
        _homeController.sortRecentDocumentsByDate();
        break;
      case 'sort_size':
        _homeController.sortRecentDocumentsBySize();
        break;
      case 'clear_recent':
        _clearRecentDocuments();
        break;
    }
  }

  Future<void> _clearRecentDocuments() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Recent Documents'),
        content: const Text(
          'This will remove all documents from the recent list.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _homeController.clearRecentDocuments();
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.security, color: Colors.orange, size: 24),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Text(
                'Storage Permission',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PDF Reader needs storage access to open PDF files from your device.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[600], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You can grant permission in device Settings > Apps > PDF Reader > Permissions',
                      style: TextStyle(fontSize: 12, color: Colors.blue[600]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _pickPDFFile(); // Try again
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  // Clean UI Components
  Widget _buildCleanHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and Search Icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'PDF Reader',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _showSearch = !_showSearch;
                        if (!_showSearch) {
                          _searchQuery = '';
                        }
                      });
                    },
                    icon: Icon(
                      _showSearch ? Icons.close : Icons.search,
                      color: Colors.grey[700],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: _handleMenuAction,
                    icon: Icon(Icons.more_vert, color: Colors.grey[700]),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'sort_name',
                        child: ListTile(
                          leading: Icon(Icons.sort_by_alpha),
                          title: Text('Sort by Name'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'sort_date',
                        child: ListTile(
                          leading: Icon(Icons.access_time),
                          title: Text('Sort by Date'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'clear_recent',
                        child: ListTile(
                          leading: Icon(Icons.clear_all, color: Colors.red),
                          title: Text('Clear Recent'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Subtitle
          Text(
            'Your recently opened PDF documents',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildMinimalSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: TextField(
        onChanged: (query) {
          setState(() {
            _searchQuery = query;
          });
        },
        decoration: InputDecoration(
          hintText: 'Search PDFs...',
          hintStyle: TextStyle(color: Colors.grey[500]),
          prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey[500]),
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildCleanFAB() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20, right: 4),
      child: FloatingActionButton.extended(
        onPressed: _pickPDFFile,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add),
        label: const Text(
          'Open PDF',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
