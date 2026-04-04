import 'package:flutter/material.dart';

import '../../../models/app_models.dart';

class CommissionWorkViewScreen extends StatefulWidget {
  final Project commission;

  const CommissionWorkViewScreen({
    super.key,
    required this.commission,
  });

  @override
  State<CommissionWorkViewScreen> createState() => _CommissionWorkViewScreenState();
}

class _CommissionWorkViewScreenState extends State<CommissionWorkViewScreen> {
  int _selectedImageIndex = 0;

  List<String> get _imageGallery {
    // For now, return reference images. In a real app, this would be submitted artwork
    return widget.commission.referenceImages;
  }

  @override
  Widget build(BuildContext context) {
    final images = _imageGallery;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(color: Colors.black),
        title: const Text(
          'Commission Work',
          style: TextStyle(color: Color(0xFFD32F2F)),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      backgroundColor: const Color(0xFFF2F2F4),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Commission info header
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.commission.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF111111),
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Client: ${widget.commission.clientName}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF6E6E6E),
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Budget: ₱${widget.commission.budget.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFFD32F2F),
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),

            // Image gallery
            if (images.isNotEmpty) ...[
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Artwork Gallery',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    // Main image display
                    Container(
                      height: 300,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: _getImageProvider(images[_selectedImageIndex]),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Stage label
                    _buildSubmissionStageLabel(_selectedImageIndex),
                    const SizedBox(height: 16),
                    // Thumbnail gallery
                    if (images.length > 1)
                      SizedBox(
                        height: 80,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: images.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final isSelected = index == _selectedImageIndex;
                            return GestureDetector(
                              onTap: () => setState(() => _selectedImageIndex = index),
                              child: Container(
                                width: 80,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFFD32F2F)
                                        : Colors.grey.shade300,
                                    width: isSelected ? 2 : 1,
                                  ),
                                  image: DecorationImage(
                                    image: _getImageProvider(images[index]),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'No artwork has been submitted yet.',
                      style: TextStyle(
                        color: Color(0xFF6E6E6E),
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSubmissionStageLabel(int imageIndex) {
    String stageLabel;
    Color stageColor;

    if (imageIndex == 0) {
      stageLabel = 'First work';
      stageColor = const Color(0xFF1976D2);
    } else if (imageIndex == _imageGallery.length - 1) {
      stageLabel = 'Latest work';
      stageColor = const Color(0xFF2E7D32);
    } else {
      stageLabel = 'Work in progress';
      stageColor = const Color(0xFFFFA000);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: stageColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: stageColor.withOpacity(0.3)),
      ),
      child: Text(
        stageLabel,
        style: TextStyle(
          color: stageColor,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }

  ImageProvider _getImageProvider(String imagePath) {
    if (imagePath.startsWith('http')) {
      return NetworkImage(imagePath);
    }
    return AssetImage(imagePath);
  }
}