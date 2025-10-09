import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:catalog_x/app/app.dart';
import 'package:catalog_x/core/errors/failures.dart';
import 'package:catalog_x/core/utils/search_history_storage.dart';
import 'package:catalog_x/features/catalog/domain/entities/product.dart';
import 'package:catalog_x/features/catalog/domain/repositories/product_repository.dart';
import 'package:catalog_x/features/catalog/presentation/blocs/catalog_bloc.dart';
import 'package:catalog_x/features/product_detail/presentation/blocs/product_detail_bloc.dart';
import 'package:catalog_x/injection_container.dart';

class FakeSearchHistoryStorage implements SearchHistoryStorage {
  List<String> _history = const [];

  @override
  Future<void> clearHistory() async {
    _history = const [];
  }

  @override
  Future<List<String>> loadHistory() async => List.unmodifiable(_history);

  @override
  Future<void> saveHistory(List<String> history) async {
    _history = List<String>.from(history);
  }
}

class FakeProductRepository implements ProductRepository {
  static final List<Product> _products = [
    const Product(
      id: 1,
      title: 'Test Product',
      price: 99.99,
      description: 'Test Description',
      category: 'featured',
      image: 'test-image-url',
    ),
    const Product(
      id: 2,
      title: 'Second Product',
      price: 59.50,
      description: 'Another Description',
      category: 'sale',
      image: 'second-image-url',
    ),
  ];

  @override
  Future<Either<Failure, List<String>>> getCategories() async {
    final categories =
        _products.map((product) => product.category).toSet().toList()..sort();
    return Right(categories);
  }

  @override
  Future<Either<Failure, Product>> getProduct(int id) async {
    try {
      final product = _products.firstWhere((product) => product.id == id);
      return Right(product);
    } catch (_) {
      return const Left(ServerFailure('Product not found'));
    }
  }

  @override
  Future<Either<Failure, List<Product>>> getProducts({
    int page = 1,
    int limit = 20,
    String? query,
    String? category,
  }) async {
    Iterable<Product> filtered = _products;

    if (query != null && query.isNotEmpty) {
      final lowerQuery = query.toLowerCase();
      filtered = filtered.where(
        (product) => product.title.toLowerCase().contains(lowerQuery),
      );
    }

    if (category != null && category.isNotEmpty) {
      filtered = filtered.where((product) => product.category == category);
    }

    final items = filtered.toList();
    final startIndex = (page - 1) * limit;
    if (startIndex >= items.length) {
      return const Right([]);
    }

    final endIndex = (startIndex + limit).clamp(0, items.length);
    return Right(items.sublist(startIndex, endIndex));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await sl.reset();
    sl.registerSingleton<SearchHistoryStorage>(FakeSearchHistoryStorage());
    sl.registerLazySingleton<ProductRepository>(() => FakeProductRepository());
    sl.registerFactory(() => CatalogBloc(repository: sl()));
    sl.registerFactory(() => ProductDetailBloc(repository: sl()));
  });

  tearDown(() async {
    await sl.reset();
  });

  testWidgets('renders catalog grid with fake data', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MiniCatalogApp());

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Test Product'), findsOneWidget);
    expect(find.text('\$99.99'), findsOneWidget);
  });
}
