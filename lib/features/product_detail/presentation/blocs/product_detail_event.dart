import 'package:equatable/equatable.dart';

abstract class ProductDetailEvent extends Equatable {
  const ProductDetailEvent();

  @override
  List<Object> get props => [];
}

class ProductDetailRequested extends ProductDetailEvent {
  final int productId;

  const ProductDetailRequested(this.productId);

  @override
  List<Object> get props => [productId];
}

class ProductDetailRetryRequested extends ProductDetailEvent {
  final int productId;

  const ProductDetailRetryRequested(this.productId);

  @override
  List<Object> get props => [productId];
}
