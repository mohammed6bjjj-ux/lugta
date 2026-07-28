import 'package:flutter_app/data/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('video without a thumbnail never exposes its MP4 as an image', () {
    const video = MediaItem(
      id: 'video-1',
      type: MediaType.video,
      url: 'https://example.test/demo.mp4',
    );
    final product = Product(
      id: 'product-1',
      nameAr: 'منتج',
      categoryId: 'category-1',
      description: '',
      specs: const {},
      media: const [video],
      variants: const [],
      wholesalePrice: 1000,
      suggestedPrice: 1500,
      createdAt: DateTime(2026),
    );

    expect(video.thumbnailUrl, isEmpty);
    expect(product.coverImage, isEmpty);
  });

  test('cover skips an empty image URL and uses the next valid image', () {
    final product = Product(
      id: 'product-1',
      nameAr: 'منتج',
      categoryId: 'category-1',
      description: '',
      specs: const {},
      media: const [
        MediaItem(id: 'missing', type: MediaType.image, url: ''),
        MediaItem(
          id: 'ready',
          type: MediaType.image,
          url: 'https://example.test/ready.webp',
        ),
      ],
      variants: const [],
      wholesalePrice: 1000,
      suggestedPrice: 1500,
      createdAt: DateTime(2026),
    );

    expect(product.coverImage, 'https://example.test/ready.webp');
  });
}
