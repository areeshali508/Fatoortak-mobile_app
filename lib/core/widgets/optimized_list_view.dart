import 'package:flutter/material.dart';

/// Optimized ListView with automatic pagination and loading indicators
/// 
/// This widget provides:
/// - Automatic load more when scrolling near bottom
/// - Loading indicators for initial load and pagination
/// - Pull to refresh support
/// - Optimized rendering with keys
class OptimizedListView<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final Future<void> Function()? onLoadMore;
  final Future<void> Function()? onRefresh;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final Widget? emptyWidget;
  final Widget? loadingWidget;
  final EdgeInsetsGeometry? padding;
  final double loadMoreThreshold;
  final String Function(T item)? keyBuilder;

  const OptimizedListView({
    required this.items,
    required this.itemBuilder,
    this.onLoadMore,
    this.onRefresh,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.emptyWidget,
    this.loadingWidget,
    this.padding,
    this.loadMoreThreshold = 200.0,
    this.keyBuilder,
    super.key,
  });

  @override
  State<OptimizedListView<T>> createState() => _OptimizedListViewState<T>();
}

class _OptimizedListViewState<T> extends State<OptimizedListView<T>> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isLoadingMore || !widget.hasMore || widget.onLoadMore == null) {
      return;
    }

    final double maxScroll = _scrollController.position.maxScrollExtent;
    final double currentScroll = _scrollController.position.pixels;
    final double threshold = widget.loadMoreThreshold;

    if (maxScroll - currentScroll <= threshold) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || widget.onLoadMore == null) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      await widget.onLoadMore!();
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading widget for initial load
    if (widget.isLoading && widget.items.isEmpty) {
      return widget.loadingWidget ??
          const Center(
            child: CircularProgressIndicator(),
          );
    }

    // Show empty widget if no items
    if (widget.items.isEmpty) {
      return widget.emptyWidget ??
          const Center(
            child: Text('No items'),
          );
    }

    // Build list with optional refresh
    Widget listView = ListView.builder(
      controller: _scrollController,
      padding: widget.padding,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: widget.items.length + (widget.hasMore ? 1 : 0),
      itemBuilder: (BuildContext context, int index) {
        // Show loading indicator at bottom if loading more
        if (index >= widget.items.length) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            alignment: Alignment.center,
            child: widget.isLoadingMore || _isLoadingMore
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const SizedBox.shrink(),
          );
        }

        final T item = widget.items[index];
        final Widget child = widget.itemBuilder(context, item, index);

        // Add key for better performance
        if (widget.keyBuilder != null) {
          return KeyedSubtree(
            key: ValueKey(widget.keyBuilder!(item)),
            child: child,
          );
        }

        return child;
      },
    );

    // Wrap with RefreshIndicator if onRefresh is provided
    if (widget.onRefresh != null) {
      listView = RefreshIndicator(
        onRefresh: widget.onRefresh!,
        child: listView,
      );
    }

    return listView;
  }
}

/// Skeleton loading widget for list items
class ListItemSkeleton extends StatelessWidget {
  final double height;
  final EdgeInsetsGeometry? margin;

  const ListItemSkeleton({
    this.height = 80,
    this.margin,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE9EEF5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 16,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 12,
                    width: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
