import 'package:flutter/material.dart';
import '../controllers/pdf_controller.dart';

class PDFControls extends StatelessWidget {
  final PDFController controller;
  final VoidCallback onPageJump;

  const PDFControls({
    super.key,
    required this.controller,
    required this.onPageJump,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black54,
            Colors.black87,
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top row - Navigation controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildControlButton(
                    icon: Icons.first_page,
                    onPressed: controller.currentPage > 1
                        ? controller.goToFirstPage
                        : null,
                    tooltip: 'First page',
                  ),
                  _buildControlButton(
                    icon: Icons.navigate_before,
                    onPressed: controller.currentPage > 1
                        ? controller.previousPage
                        : null,
                    tooltip: 'Previous page',
                  ),
                  _buildControlButton(
                    icon: Icons.list,
                    onPressed: onPageJump,
                    tooltip: 'Go to page',
                  ),
                  _buildControlButton(
                    icon: Icons.navigate_next,
                    onPressed: controller.currentPage < controller.totalPages
                        ? controller.nextPage
                        : null,
                    tooltip: 'Next page',
                  ),
                  _buildControlButton(
                    icon: Icons.last_page,
                    onPressed: controller.currentPage < controller.totalPages
                        ? controller.goToLastPage
                        : null,
                    tooltip: 'Last page',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: onPressed != null
                  ? Colors.white.withOpacity(0.2)
                  : Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
              ),
            ),
            child: Icon(
              icon,
              color: onPressed != null
                  ? Colors.white
                  : Colors.white.withOpacity(0.5),
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}
