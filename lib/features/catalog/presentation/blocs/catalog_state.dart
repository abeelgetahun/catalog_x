import 'package:equatable/equatable.dart';
import '../../domain/entities/product.dart';

enum CatalogStatus { initial, loading, success, failure }

class CatalogState extends Equatable {
  final CatalogStatus status;
  final List<Product> products;
  final List<String> categories;
  final int page;
  final bool hasMore;
  final String query;
  final String? selectedCategory;
  final String? error;
  final bool isLoadingMore;
  final String? snackbarMessage;

  const CatalogState({
    this.status = CatalogStatus.initial,
    this.products = const [],
    this.categories = const [],
    this.page = 1,
    this.hasMore = true,
    this.query = '',
    this.selectedCategory,
    this.error,
    this.isLoadingMore = false,
    this.snackbarMessage,
  });

  static const Object _noValue = Object();

  CatalogState copyWith({
    CatalogStatus? status,
    List<Product>? products,
    List<String>? categories,
    int? page,
    bool? hasMore,
    String? query,
    Object? selectedCategory = _noValue,
    Object? error = _noValue,
    bool? isLoadingMore,
    Object? snackbarMessage = _noValue,
  }) {
    return CatalogState(
      status: status ?? this.status,
      products: products ?? this.products,
      categories: categories ?? this.categories,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      query: query ?? this.query,
      selectedCategory: identical(selectedCategory, _noValue)
          ? this.selectedCategory
          : selectedCategory as String?,
      error: identical(error, _noValue) ? this.error : error as String?,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      snackbarMessage: identical(snackbarMessage, _noValue)
          ? this.snackbarMessage
          : snackbarMessage as String?,
    );
  }

  @override
  List<Object?> get props => [
    status,
    products,
    categories,
    page,
    hasMore,
    query,
    selectedCategory,
    error,
    isLoadingMore,
    snackbarMessage,
  ];
}
