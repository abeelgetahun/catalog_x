import 'package:equatable/equatable.dart';

abstract class CatalogEvent extends Equatable {
  const CatalogEvent();

  @override
  List<Object?> get props => [];
}

class CatalogStarted extends CatalogEvent {}

class CatalogRefreshed extends CatalogEvent {}

class CatalogQueryChanged extends CatalogEvent {
  final String query;

  const CatalogQueryChanged(this.query);

  @override
  List<Object> get props => [query];
}

class CatalogCategoryChanged extends CatalogEvent {
  final String? category;

  const CatalogCategoryChanged(this.category);

  @override
  List<Object?> get props => [category];
}

class CatalogLoadMore extends CatalogEvent {}

class CatalogRetryRequested extends CatalogEvent {}

class CatalogSnackbarCleared extends CatalogEvent {}
