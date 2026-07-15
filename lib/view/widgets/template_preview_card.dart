import 'package:flutter/material.dart';

class TemplatePreviewCard extends StatelessWidget {
  final String title;
  final String templateId;
  final bool isSelected;
  final VoidCallback onTap;

  const TemplatePreviewCard({
    Key? key,
    required this.title,
    required this.templateId,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF00A8E8) : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                ),
                child: _buildPreview(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? const Color(0xFF00A8E8) : Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    switch (templateId) {
      case 'standard':
        return _buildSlipPreview(detailed: false);
      case 'detailed':
        return _buildSlipPreview(detailed: true);
      case 'minimal':
        return _buildMinimalSlipPreview();
      case 'product_small':
        return _buildLabelPreview(isShelf: false);
      case 'shelf_large':
        return _buildLabelPreview(isShelf: true);
      default:
        return const Center(child: Icon(Icons.print));
    }
  }

  Widget _buildSlipPreview({required bool detailed}) {
    return Column(
      children: [
        Container(height: 4, width: 40, color: Colors.grey.shade300),
        const SizedBox(height: 4),
        Container(height: 2, width: 60, color: Colors.grey.shade200),
        const SizedBox(height: 8),
        ...List.generate(detailed ? 5 : 3, (index) => Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(height: 2, width: 30, color: Colors.grey.shade300),
              Container(height: 2, width: 20, color: Colors.grey.shade300),
            ],
          ),
        )),
        const Spacer(),
        const Divider(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(height: 3, width: 25, color: Colors.grey.shade400),
            Container(height: 3, width: 25, color: Colors.grey.shade400),
          ],
        ),
        const SizedBox(height: 4),
        Center(child: Container(height: 15, width: 15, color: Colors.grey.shade300)), // QR placeholder
      ],
    );
  }

  Widget _buildMinimalSlipPreview() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(height: 4, width: 30, color: Colors.grey.shade400),
        const SizedBox(height: 10),
        Container(height: 2, width: 50, color: Colors.grey.shade200),
        Container(height: 2, width: 50, color: Colors.grey.shade200),
        const SizedBox(height: 10),
        Container(height: 5, width: 40, color: Colors.grey.shade500),
      ],
    );
  }

  Widget _buildLabelPreview({required bool isShelf}) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.all(4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(height: 3, width: 60, color: Colors.black45),
          const SizedBox(height: 4),
          if (isShelf) ...[
             const Spacer(),
             Row(
               mainAxisAlignment: MainAxisAlignment.center,
               children: [
                 Container(height: 15, width: 40, color: Colors.black12),
                 const SizedBox(width: 4),
                 Container(height: 10, width: 10, color: Colors.black87),
               ],
             ),
             const Spacer(),
          ] else ...[
             const SizedBox(height: 8),
             Container(height: 12, width: 12, color: Colors.black12),
             const Spacer(),
             Container(height: 8, width: 50, color: Colors.black87),
          ],
          Container(height: 2, width: 50, color: Colors.grey.shade300),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(10, (i) => Container(width: 2, height: 8, color: Colors.black54, margin: const EdgeInsets.symmetric(horizontal: 1))),
          ), // Barcode
        ],
      ),
    );
  }
}
