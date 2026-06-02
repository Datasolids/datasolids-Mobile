// State for one category list screen.
//
// Holds the current filter/sort, accumulates pages as the user scrolls,
// and exposes `loadMore()` + `refresh()` + `setFilter()` / `setSort()`.
//
// Keyed by (categoryKey) — `categoryResourcesControllerProvider` is
// `.family<…, String>` so each category gets its own state and the user
// can flip between Labs and Medications without the lists colliding.

import 'dart:async';

import 'package:datasolids_mobile/features/pod/data/category_resources_api.dart';
import 'package:datasolids_mobile/features/pod/data/dtos/category_resource.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CategoryResourcesState {
  const CategoryResourcesState({
    this.items = const [],
    this.total = 0,
    this.hasMore = false,
    this.filter = 'all',
    this.sort = 'date_desc',
    this.isLoadingFirstPage = false,
    this.isLoadingMore = false,
    this.errorMessage,
  });

  final List<CategoryResourceListItem> items;
  final int total;
  final bool hasMore;
  final String filter; // all | abnormal | recent | active
  final String sort;   // date_desc | date_asc | title_asc
  final bool isLoadingFirstPage;
  final bool isLoadingMore;
  final String? errorMessage;

  CategoryResourcesState copyWith({
    List<CategoryResourceListItem>? items,
    int? total,
    bool? hasMore,
    String? filter,
    String? sort,
    bool? isLoadingFirstPage,
    bool? isLoadingMore,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CategoryResourcesState(
      items: items ?? this.items,
      total: total ?? this.total,
      hasMore: hasMore ?? this.hasMore,
      filter: filter ?? this.filter,
      sort: sort ?? this.sort,
      isLoadingFirstPage: isLoadingFirstPage ?? this.isLoadingFirstPage,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class CategoryResourcesController extends StateNotifier<CategoryResourcesState> {
  CategoryResourcesController(this._ref, this._key)
      : super(const CategoryResourcesState()) {
    // First load on construction.
    unawaited(refresh());
  }

  final Ref _ref;
  final String _key;
  static const int _pageSize = 20;

  Future<void> refresh() async {
    state = state.copyWith(isLoadingFirstPage: true, clearError: true);
    try {
      final page = await _ref.read(categoryResourcesApiProvider).getList(
            categoryKey: _key,
            filter: state.filter,
            sort: state.sort,
            offset: 0,
            limit: _pageSize,
          );
      state = state.copyWith(
        items: page.results,
        total: page.total,
        hasMore: page.hasMore,
        isLoadingFirstPage: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingFirstPage: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true, clearError: true);
    try {
      final page = await _ref.read(categoryResourcesApiProvider).getList(
            categoryKey: _key,
            filter: state.filter,
            sort: state.sort,
            offset: state.items.length,
            limit: _pageSize,
          );
      state = state.copyWith(
        items: [...state.items, ...page.results],
        total: page.total,
        hasMore: page.hasMore,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> setFilter(String filter) async {
    if (filter == state.filter) return;
    state = state.copyWith(filter: filter, items: const [], total: 0);
    await refresh();
  }

  Future<void> setSort(String sort) async {
    if (sort == state.sort) return;
    state = state.copyWith(sort: sort, items: const [], total: 0);
    await refresh();
  }
}

final categoryResourcesControllerProvider = StateNotifierProvider.family<
    CategoryResourcesController, CategoryResourcesState, String>((ref, key) {
  return CategoryResourcesController(ref, key);
});

// ---------------------------------------------------------------------------
// Resource detail — one-shot fetch, AsyncValue is plenty here.
// ---------------------------------------------------------------------------

final resourceDetailProvider =
    FutureProvider.family<ResourceDetail, String>((ref, resourceId) {
  return ref.read(categoryResourcesApiProvider).getDetail(resourceId);
});
