import 'package:equatable/equatable.dart';
import '../../../catalog/domain/entities/product.dart';

enum ProductDetailStatus { initial, loading, success, failure }

class ProductDetailState extends Equatable {
  final ProductDetailStatus status;
  final Product? product;
  final String? error;

  const ProductDetailState({
    this.status = ProductDetailStatus.initial,
    this.product,
    this.error,
  });

  ProductDetailState copyWith({
    ProductDetailStatus? status,
    Product? product,
    String? error,
  }) {
    return ProductDetailState(
      status: status ?? this.status,
      product: product ?? this.product,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [status, product, error];
}
