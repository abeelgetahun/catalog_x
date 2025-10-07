import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stream_transform/stream_transform.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/errors.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import 'catalog_event.dart';
import 'catalog_state.dart';

// Re-export event and state so importing this file exposes related types
export 'catalog_event.dart';
export 'catalog_state.dart';

EventTransformer<E> debounce<E>(Duration duration) {
  return (events, mapper) => events.debounce(duration).switchMap(mapper);
}

class CatalogBloc extends Bloc<CatalogEvent, CatalogState> {
  final ProductRepository repository;

  CatalogBloc({required this.repository}) : super(const CatalogState()) {
    on<CatalogStarted>(_onStarted);
    on<CatalogRefreshed>(_onRefreshed);
    on<CatalogQueryChanged>(
      _onQueryChanged,
      transformer: debounce(ApiConstants.debounceDelay),
    );
    on<CatalogCategoryChanged>(_onCategoryChanged);
    on<CatalogLoadMore>(_onLoadMore);
    on<CatalogRetryRequested>(_onRetryRequested);
    on<CatalogSnackbarCleared>(_onSnackbarCleared);
  }

  Future<void> _onStarted(
    CatalogStarted event,
    Emitter<CatalogState> emit,
  ) async {
    emit(
      state.copyWith(
        status: CatalogStatus.loading,
        error: null,
        snackbarMessage: null,
      ),
    );

    // Load categories
    final categoriesResult = await repository.getCategories();
    categoriesResult.fold((failure) {}, (categories) {
      emit(state.copyWith(categories: categories));
    });

    // Load initial products
    final result = await repository.getProducts(
      page: 1,
      limit: ApiConstants.pageSize,
    );

    result.fold(
      (failure) => _emitFailure(failure, emit),
      (products) => emit(
        state.copyWith(
          status: CatalogStatus.success,
          products: products,
          page: 1,
          hasMore: products.length == ApiConstants.pageSize,
          error: null,
          snackbarMessage: null,
          categories: state.categories.isNotEmpty
              ? state.categories
              : _categoriesFrom(products),
        ),
      ),
    );
  }

  Future<void> _onRefreshed(
    CatalogRefreshed event,
    Emitter<CatalogState> emit,
  ) async {
    final result = await repository.getProducts(
      page: 1,
      limit: ApiConstants.pageSize,
      query: state.query.isEmpty ? null : state.query,
      category: state.selectedCategory,
    );

    result.fold(
      (failure) => _emitFailure(failure, emit),
      (products) => emit(
        state.copyWith(
          status: CatalogStatus.success,
          products: products,
          page: 1,
          hasMore: products.length == ApiConstants.pageSize,
          error: null,
          snackbarMessage: null,
          categories: state.categories.isNotEmpty
              ? state.categories
              : _categoriesFrom(products),
        ),
      ),
    );
  }

  Future<void> _onQueryChanged(
    CatalogQueryChanged event,
    Emitter<CatalogState> emit,
  ) async {
    emit(
      state.copyWith(
        query: event.query,
        status: CatalogStatus.loading,
        error: null,
        snackbarMessage: null,
      ),
    );

    final result = await repository.getProducts(
      page: 1,
      limit: ApiConstants.pageSize,
      query: event.query.isEmpty ? null : event.query,
      category: state.selectedCategory,
    );

    result.fold(
      (failure) => _emitFailure(failure, emit),
      (products) => emit(
        state.copyWith(
          status: CatalogStatus.success,
          products: products,
          page: 1,
          hasMore: products.length == ApiConstants.pageSize,
          error: null,
          snackbarMessage: null,
          categories: state.categories.isNotEmpty
              ? state.categories
              : _categoriesFrom(products),
        ),
      ),
    );
  }

  Future<void> _onCategoryChanged(
    CatalogCategoryChanged event,
    Emitter<CatalogState> emit,
  ) async {
    emit(
      state.copyWith(
        selectedCategory: event.category,
        status: CatalogStatus.loading,
        error: null,
        snackbarMessage: null,
      ),
    );

    final result = await repository.getProducts(
      page: 1,
      limit: ApiConstants.pageSize,
      query: state.query.isEmpty ? null : state.query,
      category: event.category,
    );

    result.fold(
      (failure) => _emitFailure(failure, emit),
      (products) => emit(
        state.copyWith(
          status: CatalogStatus.success,
          products: products,
          page: 1,
          hasMore: products.length == ApiConstants.pageSize,
          error: null,
          snackbarMessage: null,
          categories: state.categories.isNotEmpty
              ? state.categories
              : _categoriesFrom(products),
        ),
      ),
    );
  }

  Future<void> _onLoadMore(
    CatalogLoadMore event,
    Emitter<CatalogState> emit,
  ) async {
    if (state.isLoadingMore || !state.hasMore) return;

    emit(state.copyWith(isLoadingMore: true, snackbarMessage: null));

    final nextPage = state.page + 1;
    final result = await repository.getProducts(
      page: nextPage,
      limit: ApiConstants.pageSize,
      query: state.query.isEmpty ? null : state.query,
      category: state.selectedCategory,
    );

    result.fold(
      (failure) => _emitFailure(failure, emit, resetLoadingMore: true),
      (newProducts) {
        final updatedProducts = [...state.products, ...newProducts];
        emit(
          state.copyWith(
            products: updatedProducts,
            page: nextPage,
            hasMore: newProducts.length == ApiConstants.pageSize,
            isLoadingMore: false,
            error: null,
            snackbarMessage: null,
            categories: state.categories.isNotEmpty
                ? state.categories
                : _categoriesFrom(updatedProducts),
          ),
        );
      },
    );
  }

  Future<void> _onRetryRequested(
    CatalogRetryRequested event,
    Emitter<CatalogState> emit,
  ) async {
    emit(
      state.copyWith(
        status: CatalogStatus.loading,
        error: null,
        snackbarMessage: null,
      ),
    );

    final result = await repository.getProducts(
      page: state.page,
      limit: ApiConstants.pageSize,
      query: state.query.isEmpty ? null : state.query,
      category: state.selectedCategory,
    );

    result.fold((failure) => _emitFailure(failure, emit), (products) {
      final combined = state.page == 1
          ? products
          : [...state.products, ...products];
      emit(
        state.copyWith(
          status: CatalogStatus.success,
          products: combined,
          error: null,
          snackbarMessage: null,
          categories: state.categories.isNotEmpty
              ? state.categories
              : _categoriesFrom(combined),
        ),
      );
    });
  }

  void _onSnackbarCleared(
    CatalogSnackbarCleared event,
    Emitter<CatalogState> emit,
  ) {
    if (state.snackbarMessage != null) {
      emit(state.copyWith(snackbarMessage: null));
    }
  }

  List<String> _categoriesFrom(List<Product> products) {
    final unique = <String>{};
    for (final product in products) {
      final category = product.category.trim();
      if (category.isEmpty) continue;
      unique.add(category);
    }
    final result = unique.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return result;
  }

  void _emitFailure(
    Failure failure,
    Emitter<CatalogState> emit, {
    bool resetLoadingMore = false,
  }) {
    final message = mapFailureToMessage(failure);

    if (failure is NetworkFailure && state.products.isNotEmpty) {
      emit(
        state.copyWith(
          status: CatalogStatus.success,
          snackbarMessage: message,
          error: null,
          isLoadingMore: resetLoadingMore ? false : state.isLoadingMore,
        ),
      );
    } else {
      emit(
        state.copyWith(
          status: CatalogStatus.failure,
          error: message,
          snackbarMessage: null,
          isLoadingMore: resetLoadingMore ? false : state.isLoadingMore,
        ),
      );
    }
  }
}
