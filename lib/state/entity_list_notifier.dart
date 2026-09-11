import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

import '../models/page_result.dart';

typedef FindFunction<T, Q> =
    Future<PageResult<T>> Function(Q query, {CancelToken? cancelToken});

typedef DeleteManyFunction = Future<int> Function(List<int> ids);
typedef IdFunction = Future<void> Function(int id);

enum LoadStatus { idle, loading, success, error }

abstract class EntityListNotifier<T, Q> extends ChangeNotifier {
  EntityListNotifier({
    required this.find,
    required this.deleteMany,
    required this.restore,
    required this.hardDelete,
    required Q initialQuery,
  }) : _query = initialQuery;

  final FindFunction<T, Q> find;
  final DeleteManyFunction deleteMany;
  final IdFunction restore;
  final IdFunction hardDelete;

  Q _query;
  PageResult<T> _result = PageResult.empty();

  LoadStatus _status = LoadStatus.idle;
  String? _errorMessage;

  final Set<int> _selected = {};

  CancelToken? _queryCancelToken;

  Q get query => _query;
  PageResult<T> get result => _result;
  LoadStatus get status => _status;
  String? get errorMessage => _errorMessage;

  Set<int> get selected => Set.unmodifiable(_selected);

  bool get hasSelection => _selected.isNotEmpty;

  CancelToken _newQueryCancelToken() {
    _queryCancelToken?.cancel();

    final token = CancelToken();
    _queryCancelToken = token;

    return token;
  }

  Future<void> load({CancelToken? cancelToken}) async {
    _status = LoadStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _result = await find(_query, cancelToken: cancelToken);
      _status = LoadStatus.success;
    } catch (error) {
      if (error is DioException && error.type == DioExceptionType.cancel) {
        return;
      }

      _status = LoadStatus.error;
      _errorMessage = error.toString();
    }

    notifyListeners();
  }

  Future<void> applyQuery(Q query) async {
    _query = query;
    _selected.clear();

    final cancelToken = _newQueryCancelToken();

    await load(cancelToken: cancelToken);
  }

  void toggleSelection(int id) {
    if (_selected.contains(id)) {
      _selected.remove(id);
    } else {
      _selected.add(id);
    }

    notifyListeners();
  }

  Future<void> deleteSelected() async {
    if (_selected.isEmpty) return;

    await deleteMany(_selected.toList());
    _selected.clear();
    await load();
  }

  Future<void> restoreItem(int id) async {
    await restore(id);
    await load();
  }

  Future<void> hardDeleteItem(int id) async {
    await hardDelete(id);
    await load();
  }

  @override
  void dispose() {
    _queryCancelToken?.cancel();
    super.dispose();
  }
}
