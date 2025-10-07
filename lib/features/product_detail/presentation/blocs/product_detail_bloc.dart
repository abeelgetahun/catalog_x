import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../catalog/domain/repositories/product_repository.dart';
import 'product_detail_event.dart';
import 'product_detail_state.dart';

// Re-export event and state for convenient imports
export 'product_detail_event.dart';
export 'product_detail_state.dart';

class ProductDetailBloc extends Bloc<ProductDetailEvent, ProductDetailState> {
  final ProductRepository repository;

  ProductDetailBloc({required this.repository})
    : super(const ProductDetailState()) {
    on<ProductDetailRequested>(_onProductDetailRequested);
    on<ProductDetailRetryRequested>(_onProductDetailRetryRequested);
  }

  Future<void> _onProductDetailRequested(
    ProductDetailRequested event,
    Emitter<ProductDetailState> emit,
  ) async {
    emit(state.copyWith(status: ProductDetailStatus.loading));

    final result = await repository.getProduct(event.productId);

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: ProductDetailStatus.failure,
          error: failure.toString(),
        ),
      ),
      (product) => emit(
        state.copyWith(status: ProductDetailStatus.success, product: product),
      ),
    );
  }

  Future<void> _onProductDetailRetryRequested(
    ProductDetailRetryRequested event,
    Emitter<ProductDetailState> emit,
  ) async {
    emit(state.copyWith(status: ProductDetailStatus.loading));

    final result = await repository.getProduct(event.productId);

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: ProductDetailStatus.failure,
          error: failure.toString(),
        ),
      ),
      (product) => emit(
        state.copyWith(status: ProductDetailStatus.success, product: product),
      ),
    );
  }
}
