import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:catalog_x/core/constants/api_constants.dart';
import 'package:catalog_x/core/errors/failures.dart';
import 'package:catalog_x/features/catalog/domain/entities/product.dart';
import 'package:catalog_x/features/catalog/domain/repositories/product_repository.dart';
import 'package:catalog_x/features/catalog/presentation/blocs/catalog_bloc.dart';

class MockProductRepository extends Mock implements ProductRepository {}

void main() {
  late CatalogBloc catalogBloc;
  late MockProductRepository mockProductRepository;

  setUp(() {
    mockProductRepository = MockProductRepository();
    catalogBloc = CatalogBloc(repository: mockProductRepository);
  });

  tearDown(() {
    catalogBloc.close();
  });

  const tProduct = Product(
    id: 1,
    title: 'Test Product',
    price: 99.99,
    description: 'Test Description',
    category: 'Test Category',
    image: 'test-image-url',
  );

  const tProducts = [tProduct];
  const tCategories = ['electronics', 'clothing'];
  const tSecondProduct = Product(
    id: 2,
    title: 'Second Product',
    price: 59.99,
    description: 'Another Description',
    category: 'Accessories',
    image: 'second-image-url',
  );
  const tAdditionalProducts = [tSecondProduct];

  group('CatalogBloc', () {
    test('initial state should be CatalogState with initial status', () {
      expect(catalogBloc.state, equals(const CatalogState()));
    });

    blocTest<CatalogBloc, CatalogState>(
      'should emit [loading, success] when CatalogStarted is added and data is fetched successfully',
      build: () {
        when(
          () => mockProductRepository.getCategories(),
        ).thenAnswer((_) async => const Right(tCategories));
        when(
          () => mockProductRepository.getProducts(
            page: any(named: 'page'),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer((_) async => const Right(tProducts));
        return catalogBloc;
      },
      act: (bloc) => bloc.add(CatalogStarted()),
      expect: () => [
        const CatalogState(status: CatalogStatus.loading),
        const CatalogState(
          status: CatalogStatus.loading,
          categories: tCategories,
        ),
        const CatalogState(
          status: CatalogStatus.success,
          categories: tCategories,
          products: tProducts,
          page: 1,
          hasMore: false,
        ),
      ],
    );

    blocTest<CatalogBloc, CatalogState>(
      'should emit [loading, failure] when CatalogStarted is added and fetching data fails',
      build: () {
        when(
          () => mockProductRepository.getCategories(),
        ).thenAnswer((_) async => const Right(tCategories));
        when(
          () => mockProductRepository.getProducts(
            page: any(named: 'page'),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer((_) async => const Left(ServerFailure('Server error')));
        return catalogBloc;
      },
      act: (bloc) => bloc.add(CatalogStarted()),
      expect: () => [
        const CatalogState(status: CatalogStatus.loading),
        const CatalogState(
          status: CatalogStatus.loading,
          categories: tCategories,
        ),
        const CatalogState(
          status: CatalogStatus.failure,
          categories: tCategories,
          error: 'We had trouble contacting the server. Please try again soon.',
        ),
      ],
    );

    blocTest<CatalogBloc, CatalogState>(
      'should emit [loading, success] when CatalogQueryChanged is added with valid query',
      build: () {
        when(
          () => mockProductRepository.getProducts(
            page: any(named: 'page'),
            limit: any(named: 'limit'),
            query: any(named: 'query'),
            category: any(named: 'category'),
          ),
        ).thenAnswer((_) async => const Right(tProducts));
        return catalogBloc;
      },
      act: (bloc) => bloc.add(const CatalogQueryChanged('test')),
      wait: const Duration(milliseconds: 500),
      expect: () => [
        const CatalogState(query: 'test', status: CatalogStatus.loading),
        const CatalogState(
          query: 'test',
          status: CatalogStatus.success,
          products: tProducts,
          categories: ['Test Category'],
          page: 1,
          hasMore: false,
        ),
      ],
    );

    blocTest<CatalogBloc, CatalogState>(
      'should append products when CatalogLoadMore succeeds',
      seed: () => const CatalogState(
        status: CatalogStatus.success,
        products: tProducts,
        page: 1,
        hasMore: true,
      ),
      build: () {
        when(
          () => mockProductRepository.getProducts(
            page: 2,
            limit: ApiConstants.pageSize,
            query: any(named: 'query'),
            category: any(named: 'category'),
          ),
        ).thenAnswer((_) async => const Right(tAdditionalProducts));
        return catalogBloc;
      },
      act: (bloc) => bloc.add(CatalogLoadMore()),
      expect: () => [
        const CatalogState(
          status: CatalogStatus.success,
          products: tProducts,
          page: 1,
          hasMore: true,
          isLoadingMore: true,
        ),
        const CatalogState(
          status: CatalogStatus.success,
          products: [...tProducts, ...tAdditionalProducts],
          categories: ['Accessories', 'Test Category'],
          page: 2,
          hasMore: false,
          isLoadingMore: false,
        ),
      ],
      verify: (_) {
        verify(
          () => mockProductRepository.getProducts(
            page: 2,
            limit: ApiConstants.pageSize,
            query: any(named: 'query'),
            category: any(named: 'category'),
          ),
        ).called(1);
      },
    );

    blocTest<CatalogBloc, CatalogState>(
      'should emit snackbar message when CatalogLoadMore fails with network error but retain data',
      seed: () => const CatalogState(
        status: CatalogStatus.success,
        products: tProducts,
        page: 1,
        hasMore: true,
      ),
      build: () {
        when(
          () => mockProductRepository.getProducts(
            page: 2,
            limit: ApiConstants.pageSize,
            query: any(named: 'query'),
            category: any(named: 'category'),
          ),
        ).thenAnswer(
          (_) async => const Left(
            NetworkFailure(
              'You appear to be offline. Check your internet connection.',
            ),
          ),
        );
        return catalogBloc;
      },
      act: (bloc) => bloc.add(CatalogLoadMore()),
      expect: () => [
        const CatalogState(
          status: CatalogStatus.success,
          products: tProducts,
          page: 1,
          hasMore: true,
          isLoadingMore: true,
        ),
        const CatalogState(
          status: CatalogStatus.success,
          products: tProducts,
          page: 1,
          hasMore: true,
          isLoadingMore: false,
          snackbarMessage:
              'You appear to be offline. Check your internet connection.',
        ),
      ],
    );
  });
}
