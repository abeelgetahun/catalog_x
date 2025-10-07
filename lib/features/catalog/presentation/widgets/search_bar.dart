import 'dart:async';

import 'package:flutter/material.dart';

class CatalogSearchBar extends StatefulWidget {
  final String initialValue;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onClear;
  final Duration debounceDuration;
  final List<String> recentSearches;
  final bool showRecentSearches;
  final ValueChanged<bool>? onFocusChanged;
  final ValueChanged<String>? onRecentSelected;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onToggleRecentVisibility;
  final ValueChanged<String>? onDeleteRecent;

  const CatalogSearchBar({
    super.key,
    required this.initialValue,
    required this.onQueryChanged,
    required this.onClear,
    this.recentSearches = const [],
    this.showRecentSearches = true,
    this.onFocusChanged,
    this.onRecentSelected,
    this.onSubmitted,
    this.onToggleRecentVisibility,
    this.onDeleteRecent,
    this.debounceDuration = const Duration(milliseconds: 400),
  });

  @override
  State<CatalogSearchBar> createState() => _CatalogSearchBarState();
}

class _CatalogSearchBarState extends State<CatalogSearchBar>
    with WidgetsBindingObserver {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  Timer? _debounceTimer;
  bool _isFocused = false;
  double _lastViewInset = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lastViewInset = _currentViewInset();
    _controller = TextEditingController(text: widget.initialValue);
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(covariant CatalogSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue &&
        widget.initialValue != _controller.text) {
      _controller.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          decoration: InputDecoration(
            hintText: 'Search products...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: _handleClear,
                  )
                : null,
            filled: true,
            fillColor: _isFocused
                ? theme.colorScheme.surface
                : theme.colorScheme.surfaceContainerHighest,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(
                color: theme.colorScheme.primary,
                width: 1.5,
              ),
            ),
          ),
          onChanged: _handleQueryChanged,
          onSubmitted: _handleSubmit,
          textInputAction: TextInputAction.search,
        ),
        if (_isFocused && widget.recentSearches.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: _RecentSearchesSection(
              searches: widget.recentSearches,
              showList: widget.showRecentSearches,
              onSelected: _handleRecentTap,
              onToggleVisibility: widget.onToggleRecentVisibility,
              onDelete: widget.onDeleteRecent,
            ),
          ),
      ],
    );
  }

  void _handleFocusChange() {
    if (!mounted) return;
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
    widget.onFocusChanged?.call(_isFocused);
  }

  void _handleQueryChanged(String query) {
    if (mounted) {
      setState(() {});
    }
    _emitQuery(query, immediate: false);
  }

  void _handleClear() {
    _debounceTimer?.cancel();
    _controller.clear();
    widget.onClear();
    setState(() {});
  }

  void _handleSubmit(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return;
    }
    _emitQuery(trimmed, immediate: true);
    widget.onSubmitted?.call(trimmed);
  }

  void _handleRecentTap(String value) {
    final trimmed = value.trim();
    _debounceTimer?.cancel();
    _controller
      ..text = trimmed
      ..selection = TextSelection.fromPosition(
        TextPosition(offset: trimmed.length),
      );
    setState(() {});
    widget.onRecentSelected?.call(trimmed);
    _emitQuery(trimmed, immediate: true);
    _focusNode.requestFocus();
  }

  void _emitQuery(String query, {required bool immediate}) {
    _debounceTimer?.cancel();
    if (immediate) {
      widget.onQueryChanged(query);
    } else {
      _debounceTimer = Timer(widget.debounceDuration, () {
        widget.onQueryChanged(query);
      });
    }
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    final inset = _currentViewInset();
    if (_lastViewInset > 0 && inset == 0 && _focusNode.hasFocus) {
      _focusNode.unfocus();
    }
    _lastViewInset = inset;
  }

  double _currentViewInset() {
    final dispatcher = WidgetsBinding.instance.platformDispatcher;
    final view = dispatcher.views.isNotEmpty
        ? dispatcher.views.first
        : dispatcher.implicitView;
    return view?.viewInsets.bottom ?? 0;
  }
}

class _RecentSearchesSection extends StatelessWidget {
  final List<String> searches;
  final bool showList;
  final ValueChanged<String> onSelected;
  final VoidCallback? onToggleVisibility;
  final ValueChanged<String>? onDelete;

  const _RecentSearchesSection({
    required this.searches,
    required this.showList,
    required this.onSelected,
    this.onToggleVisibility,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headlineStyle = theme.textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w600,
      color: theme.colorScheme.onSurface,
    );
    final itemStyle = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurface,
    );

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                height: 40,
                child: Row(
                  children: [
                    Text('Recent searches', style: headlineStyle),
                    const Spacer(),
                    if (onToggleVisibility != null)
                      TextButton(
                        onPressed: onToggleVisibility,
                        child: Text(showList ? 'Hide' : 'Show'),
                      ),
                  ],
                ),
              ),
            ),
            if (showList && searches.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...searches
                  .take(5)
                  .map(
                    (term) => InkWell(
                      onTap: () => onSelected(term),
                      child: SizedBox(
                        height: 40,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            children: [
                              const Icon(Icons.history, size: 18),
                              const SizedBox(width: 12),
                              Expanded(child: Text(term, style: itemStyle)),
                              if (onDelete != null)
                                IconButton(
                                  tooltip: 'Remove',
                                  onPressed: () => onDelete!(term),
                                  icon: const Icon(Icons.close, size: 18),
                                  splashRadius: 18,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }
}
