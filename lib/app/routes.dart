import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../features/catalog/presentation/pages/catalog_page.dart';
import '../features/product_detail/presentation/pages/product_detail_page.dart';
import '../features/product_detail/presentation/blocs/product_detail_bloc.dart';
import '../injection_container.dart';

class AppRoutes {
  static const String catalog = '/';
  static const String productDetail = '/product-detail';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case catalog:
        return MaterialPageRoute(builder: (_) => const CatalogPage());
      case productDetail:
        final productId = settings.arguments as int;
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) =>
                sl<ProductDetailBloc>()..add(ProductDetailRequested(productId)),
            child: ProductDetailPage(productId: productId),
          ),
        );
      default:
        return MaterialPageRoute(
          builder: (_) =>
              const Scaffold(body: Center(child: Text('Route not found'))),
        );
    }
  }
}
