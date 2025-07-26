import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import '../controllers/pdf_controller.dart';
import '../models/pdf_document.dart';
import '../widgets/pdf_controls.dart';

class PDFViewerScreen extends StatefulWidget {
  final PDFDocument document;

  const PDFViewerScreen({
    super.key,
    required this.document,
  });

  @override
  State<PDFViewerScreen> createState() => _PDFViewerScreenState();
}

class _PDFViewerScreenState extends State<PDFViewerScreen> {
  late PDFController _pdfController;
  bool _isFullScreen = false;

  @override
  void initState() {
    super.initState();
    _pdfController = PDFController();
    _initializePDF();
  }

  Future<void> _initializePDF() async {
    await _pdfController.loadDocument(widget.document);
  }

  @override
  void dispose() {
    _pdfController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _isFullScreen ? null : _buildAppBar(),
      body: AnimatedBuilder(
        animation: _pdfController,
        builder: (context, child) {
          if (_pdfController.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    'Loading PDF...',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            );
          }

          if (_pdfController.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _pdfController.error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }

          return Stack(
            children: [
              // PDF View
              GestureDetector(
                onTap: _toggleFullScreen,
                child: PDFView(
                  filePath: _pdfController.currentDocument!.path,
                  enableSwipe: true,
                  swipeHorizontal: false,
                  autoSpacing: true,
                  pageFling: true,
                  pageSnap: true,
                  defaultPage: _pdfController.currentPage - 1,
                  fitPolicy: FitPolicy.WIDTH,
                  preventLinkNavigation: false,
                  onRender: (pages) {
                    _pdfController.onDocumentReady(pages ?? 0);
                  },
                  onError: (error) {
                    _pdfController.onDocumentError(error);
                  },
                  onPageError: (page, error) {
                    _pdfController.onDocumentError(error);
                  },
                  onViewCreated: (controller) {
                    _pdfController.onPDFViewCreated(controller);
                  },
                  onLinkHandler: (uri) {
                    // Handle link navigation if needed
                  },
                  onPageChanged: (page, total) {
                    _pdfController.onPageChanged((page ?? 0) + 1);
                  },
                ),
              ),


// Navigation Controls only
              if (_pdfController.showControls && !_isFullScreen)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: PDFControls(
                    controller: _pdfController,
                    onPageJump: _showPageJumpDialog,
                  ),
                ),

              // Loading overlay for page changes
              if (_pdfController.isLoading)
                Container(
                  color: Colors.black54,
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      title: AnimatedBuilder(
        animation: _pdfController,
        builder: (context, child) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.document.name,
                style: const TextStyle(fontSize: 16),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (_pdfController.totalPages > 0)
                Text(
                  _pdfController.pageInfo,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
            ],
          );
        },
      ),
    );
  }

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
    });
    
    if (_isFullScreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      _pdfController.hideControlsPanel();
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      _pdfController.showControlsPanel();
    }
  }

  void _showPageJumpDialog() {
    final TextEditingController pageController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Go to Page'),
        content: TextField(
          controller: pageController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Page number (1-${_pdfController.totalPages})',
            border: const OutlineInputBorder(),
          ),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final pageNum = int.tryParse(pageController.text);
              if (pageNum != null && pageNum > 0 && pageNum <= _pdfController.totalPages) {
                _pdfController.goToPage(pageNum);
                Navigator.pop(context);
              }
            },
            child: const Text('Go'),
          ),
        ],
      ),
    );
  }


}
