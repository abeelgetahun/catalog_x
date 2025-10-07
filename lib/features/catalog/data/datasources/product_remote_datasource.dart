import 'dart:io';

import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/failures.dart';
import '../models/product_model.dart';

abstract class ProductRemoteDataSource {
  Future<List<ProductModel>> getProducts({
    int page = 1,
    int limit = 20,
    String? query,
    String? category,
  });

  Future<List<String>> getCategories();
  Future<ProductModel> getProduct(int id);
}

class ProductRemoteDataSourceImpl implements ProductRemoteDataSource {
  final Dio dio;

  ProductRemoteDataSourceImpl(this.dio);

  @override
  Future<List<ProductModel>> getProducts({
    int page = 1,
    int limit = 20,
    String? query,
    String? category,
  }) async {
    try {
      String url = '${ApiConstants.baseUrl}${ApiConstants.products}';

      if (category != null && category.isNotEmpty) {
        url =
            '${ApiConstants.baseUrl}${ApiConstants.products}/category/$category';
      }

      final response = await dio.get(url);

      List<ProductModel> products = (response.data as List<dynamic>)
          .map((json) => ProductModel.fromJson(json))
          .toList();

      if (query != null && query.isNotEmpty) {
        final trimmedQuery = query.trim().toLowerCase();
        final wordPattern = RegExp(r'\b' + RegExp.escape(trimmedQuery) + r'\b');

        final List<_ScoredProduct> scored = [];

        for (final product in products) {
          final titleLower = product.title.toLowerCase();
          final descriptionLower = product.description.toLowerCase();
          final categoryLower = product.category.toLowerCase();

          final bool titleContains = titleLower.contains(trimmedQuery);
          final bool categoryContains = categoryLower.contains(trimmedQuery);
          final bool descriptionContains = descriptionLower.contains(
            trimmedQuery,
          );

          if (!titleContains && !categoryContains && !descriptionContains) {
            continue;
          }

          final score = _scoreProduct(
            query: trimmedQuery,
            wordPattern: wordPattern,
            titleLower: titleLower,
            descriptionLower: descriptionLower,
            categoryLower: categoryLower,
          );

          scored.add(_ScoredProduct(product: product, score: score));
        }

        if (scored.isEmpty) {
          return [];
        }

        scored.sort((a, b) {
          final cmp = a.score.compareTo(b.score);
          if (cmp != 0) return cmp;
          return a.product.title.compareTo(b.product.title);
        });

        final bestScore = scored.first.score;
        products = scored
            .where((entry) => entry.score <= bestScore + 1)
            .map((entry) => entry.product)
            .toList();
      }

      return products;
    } on DioException catch (error) {
      throw _mapDioErrorToFailure(error);
    }
  }

  @override
  Future<List<String>> getCategories() async {
    try {
      final response = await dio.get(
        '${ApiConstants.baseUrl}${ApiConstants.categories}',
      );
      return List<String>.from(response.data);
    } on DioException catch (error) {
      throw _mapDioErrorToFailure(error);
    }
  }

  @override
  Future<ProductModel> getProduct(int id) async {
    try {
      final response = await dio.get(
        '${ApiConstants.baseUrl}${ApiConstants.products}/$id',
      );
      return ProductModel.fromJson(response.data);
    } on DioException catch (error) {
      throw _mapDioErrorToFailure(error);
    }
  }
}

int _scoreProduct({
  required String query,
  required RegExp wordPattern,
  required String titleLower,
  required String descriptionLower,
  required String categoryLower,
}) {
  if (titleLower == query) return 0;
  if (titleLower.startsWith(query)) return 1;
  if (wordPattern.hasMatch(titleLower)) return 2;
  if (titleLower.contains(query)) return 3;
  if (categoryLower == query) return 4;
  if (categoryLower.contains(query)) return 5;
  if (wordPattern.hasMatch(descriptionLower)) return 6;
  if (descriptionLower.contains(query)) return 7;
  return 8;
}

class _ScoredProduct {
  const _ScoredProduct({required this.product, required this.score});

  final ProductModel product;
  final int score;
}

Failure _mapDioErrorToFailure(DioException error) {
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.connectionError:
      return const NetworkFailure();
    case DioExceptionType.badCertificate:
    case DioExceptionType.badResponse:
      return const ServerFailure();
    case DioExceptionType.cancel:
      return const ServerFailure();
    case DioExceptionType.unknown:
      if (error.error is SocketException) {
        return const NetworkFailure();
      }
      return const ServerFailure();
  }
}
