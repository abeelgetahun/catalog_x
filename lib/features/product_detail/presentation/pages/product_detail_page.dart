import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/widgets/error_widget.dart';
import '../blocs/product_detail_bloc.dart';

class ProductDetailPage extends StatelessWidget {
  final int productId;

  const ProductDetailPage({super.key, required this.productId});

  @override
  Widget build(BuildContext context) {
    final double topImageSpacing = MediaQuery.of(context).padding.top + 12;

    return Scaffold(
      body: BlocBuilder<ProductDetailBloc, ProductDetailState>(
        builder: (context, state) {
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // SizedBox(height: topImageSpacing),
                      Positioned.fill(
                        child: Column(
                          children: [
                            Container(
                              height: topImageSpacing,
                              color: Colors.grey[200],
                            ),
                            Expanded(
                              child: Container(
                                color: Colors.grey[200],
                                alignment: Alignment.center,
                                child: state.product?.image != null
                                    ? CachedNetworkImage(
                                        imageUrl: state.product!.image,
                                        fit: BoxFit.contain,
                                        alignment: Alignment.center,
                                        placeholder: (context, url) =>
                                            const Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            ),
                                        errorWidget: (context, url, error) =>
                                            const Icon(Icons.error, size: 64),
                                      )
                                    : const Icon(Icons.image, size: 64),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Align(
                        alignment: Alignment.topCenter,
                        child: Container(
                          height: 120,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(0.25),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Fullscreen icon at bottom right
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(24),
                            onTap: () {
                              showDialog(
                                context: context,
                                barrierDismissible: true,
                                barrierColor: Colors.black.withOpacity(0.9),
                                builder: (context) => Stack(
                                  children: [
                                    GestureDetector(
                                      onTap: () => Navigator.of(context).pop(),
                                      child: Container(
                                        color: Colors.transparent,
                                      ),
                                    ),
                                    Center(
                                      child: state.product?.image != null
                                          ? CachedNetworkImage(
                                              imageUrl: state.product!.image,
                                              fit: BoxFit.contain,
                                              errorWidget:
                                                  (context, url, error) =>
                                                      const Icon(
                                                        Icons.error,
                                                        size: 128,
                                                      ),
                                              placeholder: (context, url) =>
                                                  const Center(
                                                    child:
                                                        CircularProgressIndicator(),
                                                  ),
                                            )
                                          : const Icon(Icons.image, size: 128),
                                    ),
                                    Positioned(
                                      top: 32,
                                      right: 32,
                                      child: GestureDetector(
                                        onTap: () =>
                                            Navigator.of(context).pop(),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(
                                              0.4,
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                          padding: const EdgeInsets.all(8),
                                          child: const Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 28,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: const Icon(
                                Icons.fullscreen,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                leading: Padding(
                  padding: const EdgeInsets.only(left: 12, top: 8),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.black.withOpacity(0.08),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      color: Colors.white,
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(child: _buildContent(context, state)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, ProductDetailState state) {
    switch (state.status) {
      case ProductDetailStatus.initial:
        return const SizedBox.shrink();
      case ProductDetailStatus.loading:
        return const SizedBox(
          height: 400,
          child: Center(child: CircularProgressIndicator()),
        );
      case ProductDetailStatus.failure:
        return SizedBox(
          height: 400,
          child: ErrorDisplayWidget(
            message: state.error ?? 'Failed to load product details',
            onRetry: () => context.read<ProductDetailBloc>().add(
              ProductDetailRetryRequested(productId),
            ),
          ),
        );
      case ProductDetailStatus.success:
        final product = state.product!;
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product title
              Text(
                product.title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 15),
              // Row with rating and category
              Row(
                children: [
                  // Rating with 5 stars and count
                  if (product.rating != null) ...[
                    Row(
                      children: [
                        ...List.generate(5, (index) {
                          double ratingValue = product.rating ?? 0;
                          return Icon(
                            index < ratingValue.round()
                                ? Icons.star
                                : Icons.star_border,
                            size: 18,
                            color: Colors.amber[600],
                          );
                        }),
                        const SizedBox(width: 8),
                        Text(
                          '${product.rating!.toStringAsFixed(1)}',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        if (product.ratingCount != null) ...[
                          const SizedBox(width: 4),
                          Text(
                            '(${product.ratingCount} ratings)',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ],
                  const Spacer(),
                  // Category at row end
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      product.category.toUpperCase(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Price
              Text(
                '\$${product.price.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: 24,
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              // Description
              Text(
                'Description',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                product.description,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(height: 1.5, fontSize: 14),
              ),
            ],
          ),
        );
    }
  }
}
