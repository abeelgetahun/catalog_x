import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/product.dart';

abstract class ProductRepository {
  Future<Either<Failure, List<Product>>> getProducts({
    int page = 1,
    int limit = 20,
    String? query,
    String? category,
  });

  Future<Either<Failure, List<String>>> getCategories();
  Future<Either<Failure, Product>> getProduct(int id);
}
