import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../../../core/utils/errors.dart';
import '../../../../core/utils/search_history_storage.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../blocs/catalog_bloc.dart';
import '../widgets/category_chips.dart';
import '../widgets/search_bar.dart';
import '../widgets/product_card.dart';
import '../../../../injection_container.dart';

class CatalogPage extends StatefulWidget {
  const CatalogPage({super.key});

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  final ScrollController _scrollController = ScrollController();
  final List<String> _recentSearches = [];
  bool _isSearchFocused = false;
  bool _showRecentSearches = true;
  late final SearchHistoryStorage _searchHistoryStorage;

  @override
  void initState() {
    super.initState();
    _searchHistoryStorage = sl<SearchHistoryStorage>();
    _loadRecentSearches();
    context.read<CatalogBloc>().add(CatalogStarted());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<CatalogBloc>().add(CatalogLoadMore());
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  Future<void> _loadRecentSearches() async {
    final storedHistory = await _searchHistoryStorage.loadHistory();
    if (!mounted) return;
    setState(() {
      _recentSearches
        ..clear()
        ..addAll(storedHistory);
    });
  }

  @override
  Widget build(BuildContext context) {
    const searchFieldHeight = 56.0;
    const paddingVertical = 16.0; // TextField padding in PreferredSize
    const spacerAboveSuggestions = 12.0;
    const suggestionsCardVerticalPadding = 24.0; // top+bottom padding 12
    const suggestionsHeaderHeight = 40.0;
    const suggestionsGap = 8.0;
    const suggestionItemHeight = 40.0;

    final hasRecentSuggestions = _isSearchFocused && _recentSearches.isNotEmpty;

    double bottomHeight = searchFieldHeight + paddingVertical;
    if (hasRecentSuggestions) {
      bottomHeight += spacerAboveSuggestions;
      bottomHeight += suggestionsCardVerticalPadding;
      bottomHeight += suggestionsHeaderHeight;
      if (_showRecentSearches) {
        bottomHeight += suggestionsGap;
        bottomHeight +=
            math.min(_recentSearches.length, 5) * suggestionItemHeight;
      }
    }

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 0,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(bottomHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 8),
            child: CatalogSearchBar(
              initialValue: context.read<CatalogBloc>().state.query,
              onQueryChanged: (query) {
                context.read<CatalogBloc>().add(CatalogQueryChanged(query));
              },
              onClear: () {
                context.read<CatalogBloc>().add(const CatalogQueryChanged(''));
              },
              recentSearches: _recentSearches,
              showRecentSearches: _showRecentSearches,
              onFocusChanged: (isFocused) {
                if (!mounted) return;
                setState(() {
                  _isSearchFocused = isFocused;
                });
              },
              onRecentSelected: _recordRecentSearch,
              onSubmitted: _recordRecentSearch,
              onToggleRecentVisibility: _toggleRecentVisibility,
              onDeleteRecent: _removeRecentSearch,
            ),
          ),
        ),
      ),
      body: BlocListener<CatalogBloc, CatalogState>(
        listenWhen: (previous, current) =>
            previous.snackbarMessage != current.snackbarMessage &&
            current.snackbarMessage != null,
        listener: (context, state) {
          final messenger = ScaffoldMessenger.of(context);
          messenger.hideCurrentSnackBar();

          final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
          final theme = Theme.of(context);
          messenger.showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    Icons.wifi_off,
                    color: theme.colorScheme.onInverseSurface,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      state.snackbarMessage!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onInverseSurface,
                      ),
                    ),
                  ),
                ],
              ),
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottomInset),
              backgroundColor: theme.colorScheme.inverseSurface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              action: SnackBarAction(
                label: 'Retry',
                textColor: theme.colorScheme.primary,
                onPressed: () =>
                    context.read<CatalogBloc>().add(CatalogRetryRequested()),
              ),
            ),
          );

          context.read<CatalogBloc>().add(CatalogSnackbarCleared());
        },
        child: BlocBuilder<CatalogBloc, CatalogState>(
          builder: (context, state) {
            return Column(
              children: [
                if (state.categories.isNotEmpty)
                  CategoryChips(
                    categories: state.categories,
                    selectedCategory: state.selectedCategory,
                    onCategorySelected: (category) {
                      final bloc = context.read<CatalogBloc>();
                      final currentCategory = state.selectedCategory;

                      if (currentCategory == category) {
                        bloc.add(CatalogRefreshed());
                      } else {
                        bloc.add(CatalogCategoryChanged(category));
                      }
                    },
                  ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      final bloc = context.read<CatalogBloc>();
                      final previousState = bloc.state;
                      final dataFuture = bloc.stream
                          .firstWhere((state) => state != previousState)
                          .timeout(
                            const Duration(seconds: 1),
                            onTimeout: () => previousState,
                          );
                      bloc.add(CatalogRefreshed());
                      await Future.wait([
                        Future.delayed(const Duration(seconds: 2)),
                        dataFuture,
                      ]);
                    },
                    child: _buildContent(state),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(CatalogState state) {
    switch (state.status) {
      case CatalogStatus.loading:
        return const LoadingWidget();
      case CatalogStatus.failure:
        return ErrorDisplayWidget(
          message: state.error ?? ErrorMessage.generic,
          onRetry: () =>
              context.read<CatalogBloc>().add(CatalogRetryRequested()),
        );
      case CatalogStatus.success:
        if (state.products.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No products found',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }
        final products = state.products;

        return AnimationLimiter(
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    return AnimationConfiguration.staggeredGrid(
                      position: index,
                      duration: const Duration(milliseconds: 375),
                      columnCount: 2,
                      child: ScaleAnimation(
                        child: FadeInAnimation(
                          child: ProductCard(product: products[index]),
                        ),
                      ),
                    );
                  }, childCount: products.length),
                ),
              ),
              if (state.isLoadingMore)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2.5,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      case CatalogStatus.initial:
        return const SizedBox.shrink();
    }
  }

  void _recordRecentSearch(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    setState(() {
      _recentSearches.removeWhere(
        (item) => item.toLowerCase() == trimmed.toLowerCase(),
      );
      _recentSearches.insert(0, trimmed);
      if (_recentSearches.length > 5) {
        _recentSearches.removeRange(5, _recentSearches.length);
      }
      _showRecentSearches = true;
    });
    _searchHistoryStorage.saveHistory(List<String>.from(_recentSearches));
  }

  void _toggleRecentVisibility() {
    setState(() {
      _showRecentSearches = !_showRecentSearches;
    });
  }

  void _removeRecentSearch(String term) {
    setState(() {
      _recentSearches.removeWhere(
        (item) => item.toLowerCase() == term.toLowerCase(),
      );
    });
    _searchHistoryStorage.saveHistory(List<String>.from(_recentSearches));
  }
}
