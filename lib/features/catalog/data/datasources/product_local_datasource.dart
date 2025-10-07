import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/errors/failures.dart';
import '../models/product_model.dart';

abstract class ProductLocalDataSource {
  Future<List<ProductModel>> getCachedProducts();
  Future<void> cacheProducts(List<ProductModel> products);
  Future<List<String>> getCachedCategories();
  Future<void> cacheCategories(List<String> categories);
  Future<ProductModel> getCachedProduct(int id);
  Future<void> cacheProduct(ProductModel product);
}

class ProductLocalDataSourceImpl implements ProductLocalDataSource {
  final SharedPreferences sharedPreferences;
  static const String cachedProductsKey = 'CACHED_PRODUCTS';
  static const String cachedCategoriesKey = 'CACHED_CATEGORIES';
  static const String cachedProductPrefix = 'CACHED_PRODUCT_';

  ProductLocalDataSourceImpl(this.sharedPreferences);

  @override
  Future<List<ProductModel>> getCachedProducts() async {
    final jsonString = sharedPreferences.getString(cachedProductsKey);
    if (jsonString != null) {
      final List<dynamic> jsonList = json.decode(jsonString);
      if (jsonList.isEmpty) {
        throw const CacheFailure();
      }
      return jsonList
          .map((item) => ProductModel.fromJson(item))
          .toList(growable: false);
    }
    throw const CacheFailure();
  }

  @override
  Future<void> cacheProducts(List<ProductModel> products) async {
    final jsonString = json.encode(
      products.map((product) => product.toJson()).toList(),
    );
    await sharedPreferences.setString(cachedProductsKey, jsonString);
  }

  @override
  Future<List<String>> getCachedCategories() async {
    final jsonString = sharedPreferences.getString(cachedCategoriesKey);
    if (jsonString != null) {
      return List<String>.from(json.decode(jsonString));
    } else {
      throw const CacheFailure();
    }
  }

  @override
  Future<void> cacheCategories(List<String> categories) async {
    final jsonString = json.encode(categories);
    await sharedPreferences.setString(cachedCategoriesKey, jsonString);
  }

  @override
  Future<ProductModel> getCachedProduct(int id) async {
    final jsonString = sharedPreferences.getString('$cachedProductPrefix$id');
    if (jsonString != null) {
      return ProductModel.fromJson(json.decode(jsonString));
    } else {
      throw const CacheFailure();
    }
  }

  @override
  Future<void> cacheProduct(ProductModel product) async {
    final jsonString = json.encode(product.toJson());
    await sharedPreferences.setString(
      '$cachedProductPrefix${product.id}',
      jsonString,
    );
  }
}
