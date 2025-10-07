import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../domain/entities/product.dart';
import '../../../../app/routes.dart';

class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.pushNamed(
          context,
          AppRoutes.productDetail,
          arguments: product.id,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: Container(
                  color: Colors.grey[200],
                  alignment: Alignment.center,
                  child: CachedNetworkImage(
                    imageUrl: product.image,
                    fit: BoxFit.contain,
                    alignment: Alignment.center,
                    placeholder: (context, url) =>
                        const Center(child: CircularProgressIndicator()),
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.error),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 2,
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    if (product.rating != null) ...[
                      Row(
                        children: [
                          ...List.generate(5, (index) {
                            final ratingValue = product.rating!;
                            IconData icon;
                            if (ratingValue >= index + 1) {
                              icon = Icons.star;
                            } else if (ratingValue > index &&
                                ratingValue < index + 1) {
                              icon = Icons.star_half;
                            } else {
                              icon = Icons.star_border;
                            }
                            return Padding(
                              padding: const EdgeInsets.only(right: 2),
                              child: Icon(
                                icon,
                                size: 14,
                                color: Colors.amber[600],
                              ),
                            );
                          }),
                          const SizedBox(width: 6),
                          Text(
                            product.rating!.toStringAsFixed(1),
                            style: theme.textTheme.bodySmall,
                          ),
                          if (product.ratingCount != null) ...[
                            const SizedBox(width: 4),
                            Text(
                              '(${product.ratingCount})',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                    ],
                    Text(
                      '\$${product.price.toStringAsFixed(2)}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w700,
                        fontSize:
                            (theme.textTheme.titleMedium?.fontSize ?? 16) + 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
