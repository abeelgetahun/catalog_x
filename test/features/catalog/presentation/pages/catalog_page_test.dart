import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:catalog_x/core/utils/search_history_storage.dart';
import 'package:catalog_x/core/widgets/loading_widget.dart';
import 'package:catalog_x/features/catalog/domain/entities/product.dart';
import 'package:catalog_x/features/catalog/presentation/blocs/catalog_bloc.dart';
import 'package:catalog_x/features/catalog/presentation/pages/catalog_page.dart';
import 'package:catalog_x/injection_container.dart';

class MockCatalogBloc extends MockBloc<CatalogEvent, CatalogState>
    implements CatalogBloc {}

class FakeCatalogEvent extends Fake implements CatalogEvent {
  @override
  List<Object?> get props => const [];
}

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockCatalogBloc mockCatalogBloc;
  late StreamController<CatalogState> controller;

  setUpAll(() {
    registerFallbackValue(FakeCatalogEvent());
  });

  setUp(() async {
    controller = StreamController<CatalogState>.broadcast();
    mockCatalogBloc = MockCatalogBloc();
    when(() => mockCatalogBloc.close()).thenAnswer((_) async {});
    when(() => mockCatalogBloc.add(any())).thenReturn(null);
    when(() => mockCatalogBloc.stream).thenAnswer((_) => controller.stream);
    await sl.reset();
    sl.registerSingleton<SearchHistoryStorage>(FakeSearchHistoryStorage());
  });

  tearDown(() async {
    await controller.close();
    await mockCatalogBloc.close();
    await sl.reset();
  });

  const tProduct = Product(
    id: 1,
    title: 'Test Product',
    price: 99.99,
    description: 'Test Description',
    category: 'Test Category',
    image: 'test-image-url',
  );

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: BlocProvider<CatalogBloc>.value(
        value: mockCatalogBloc,
        child: const CatalogPage(),
      ),
    );
  }

  group('CatalogPage', () {
    testWidgets('renders loading, success, and failure states as expected', (
      WidgetTester tester,
    ) async {
      const loadingState = CatalogState(status: CatalogStatus.loading);
      when(() => mockCatalogBloc.state).thenReturn(loadingState);

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(LoadingWidget), findsOneWidget);

      const successState = CatalogState(
        status: CatalogStatus.success,
        products: [tProduct],
        categories: ['Test Category'],
      );
      when(() => mockCatalogBloc.state).thenReturn(successState);
      controller.add(successState);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Test Product'), findsOneWidget);
      expect(find.text('\$99.99'), findsOneWidget);

      const failureState = CatalogState(
        status: CatalogStatus.failure,
        error: 'Test error message',
      );
      when(() => mockCatalogBloc.state).thenReturn(failureState);
      controller.add(failureState);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Test error message'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
    });

    testWidgets('renders empty state when no products found', (
      WidgetTester tester,
    ) async {
      const emptyState = CatalogState(
        status: CatalogStatus.success,
        products: [],
      );
      when(() => mockCatalogBloc.state).thenReturn(emptyState);
      controller.add(emptyState);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('No products found'), findsOneWidget);
    });
  });
}
