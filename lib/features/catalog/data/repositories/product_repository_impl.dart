import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/product_local_datasource.dart';
import '../datasources/product_remote_datasource.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductRemoteDataSource remoteDataSource;
  final ProductLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  ProductRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<Product>>> getProducts({
    int page = 1,
    int limit = 20,
    String? query,
    String? category,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final remoteProducts = await remoteDataSource.getProducts(
          page: page,
          limit: limit,
          query: query,
          category: category,
        );

        final paged = _paginateProducts(
          remoteProducts,
          page: page,
          limit: limit,
        );

        final isFirstPage = page == 1;
        final hasQuery = query != null && query.isNotEmpty;
        final hasCategory = category != null && category.isNotEmpty;

        if (isFirstPage && !hasQuery && !hasCategory) {
          await localDataSource.cacheProducts(remoteProducts);
        }

        return Right(paged);
      } on Failure catch (failure) {
        return Left(failure);
      } catch (_) {
        return const Left(ServerFailure());
      }
    } else {
      try {
        final cachedProducts = await localDataSource.getCachedProducts();
        final filtered = _filterProducts(
          cachedProducts,
          query: query,
          category: category,
        );

        final paged = _paginateProducts(filtered, page: page, limit: limit);
        return Right(paged);
      } on Failure catch (failure) {
        return Left(failure);
      } catch (_) {
        return const Left(CacheFailure());
      }
    }
  }

  @override
  Future<Either<Failure, List<String>>> getCategories() async {
    if (await networkInfo.isConnected) {
      try {
        final categories = await remoteDataSource.getCategories();
        final sanitized = _sanitizeCategories(categories);
        await localDataSource.cacheCategories(sanitized);
        return Right(sanitized);
      } on Failure catch (failure) {
        return Left(failure);
      } catch (_) {
        return const Left(ServerFailure());
      }
    } else {
      try {
        final cached = await localDataSource.getCachedCategories();
        if (cached.isNotEmpty) {
          return Right(cached);
        }
        final derived = await _deriveCategoriesFromCache();
        return Right(derived);
      } on CacheFailure {
        try {
          final derived = await _deriveCategoriesFromCache();
          return Right(derived);
        } on Failure catch (failure) {
          return Left(failure);
        } catch (_) {
          return const Left(CacheFailure());
        }
      } on Failure catch (failure) {
        return Left(failure);
      } catch (_) {
        return const Left(CacheFailure());
      }
    }
  }

  @override
  Future<Either<Failure, Product>> getProduct(int id) async {
    if (await networkInfo.isConnected) {
      try {
        final product = await remoteDataSource.getProduct(id);
        await localDataSource.cacheProduct(product);
        return Right(product);
      } on Failure catch (failure) {
        return Left(failure);
      } catch (_) {
        return const Left(ServerFailure());
      }
    } else {
      try {
        final product = await localDataSource.getCachedProduct(id);
        return Right(product);
      } on Failure catch (failure) {
        return Left(failure);
      } catch (_) {
        return const Left(CacheFailure());
      }
    }
  }

  List<Product> _filterProducts(
    List<Product> products, {
    String? query,
    String? category,
  }) {
    Iterable<Product> filtered = products;

    if (category != null && category.isNotEmpty) {
      final normalizedCategory = category.toLowerCase().trim();
      filtered = filtered.where(
        (product) =>
            product.category.toLowerCase().trim() == normalizedCategory,
      );
    }

    if (query == null || query.trim().isEmpty) {
      return filtered.toList(growable: false);
    }

    final trimmedQuery = query.trim().toLowerCase();
    final wordPattern = RegExp(r'\b' + RegExp.escape(trimmedQuery) + r'\b');

    final scored = <_ScoredProduct>[];

    for (final product in filtered) {
      final titleLower = product.title.toLowerCase();
      final descriptionLower = product.description.toLowerCase();
      final categoryLower = product.category.toLowerCase();

      final titleContains = titleLower.contains(trimmedQuery);
      final categoryContains = categoryLower.contains(trimmedQuery);
      final descriptionContains = descriptionLower.contains(trimmedQuery);

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
      return const [];
    }

    scored.sort((a, b) {
      final cmp = a.score.compareTo(b.score);
      if (cmp != 0) return cmp;
      return a.product.title.compareTo(b.product.title);
    });

    final bestScore = scored.first.score;
    return scored
        .where((entry) => entry.score <= bestScore + 1)
        .map((entry) => entry.product)
        .toList(growable: false);
  }

  List<Product> _paginateProducts(
    List<Product> products, {
    required int page,
    required int limit,
  }) {
    if (products.isEmpty) {
      return const [];
    }

    final startIndex = (page - 1) * limit;
    if (startIndex >= products.length || startIndex < 0) {
      return const [];
    }

    final endIndex = (startIndex + limit).clamp(0, products.length);
    return products.sublist(startIndex, endIndex);
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

  List<String> _sanitizeCategories(List<String> categories) {
    final seen = <String>{};
    final sanitized = <String>[];

    for (final category in categories) {
      final trimmed = category.trim();
      if (trimmed.isEmpty) continue;
      if (seen.add(trimmed.toLowerCase())) {
        sanitized.add(trimmed);
      }
    }

    sanitized.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return sanitized;
  }

  Future<List<String>> _deriveCategoriesFromCache() async {
    final cachedProducts = await localDataSource.getCachedProducts();
    final categories = cachedProducts
        .map((product) => product.category)
        .toList();
    final sanitized = _sanitizeCategories(categories);
    if (sanitized.isEmpty) {
      throw const CacheFailure();
    }
    await localDataSource.cacheCategories(sanitized);
    return sanitized;
  }
}

class _ScoredProduct {
  const _ScoredProduct({required this.product, required this.score});

  final Product product;
  final int score;
}
