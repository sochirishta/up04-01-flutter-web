import 'package:flutter/foundation.dart';

import '../models/page_result.dart';

typedef FindFunction<T, Q> = Future<PageResult<T>> Function(Q query);
typedef DeleteManyFunction = Future<int> Function(List<int> ids);
typedef IdFunction = Future<void> Function(int id);

enum LoadStatus {
  idle,
  loading,
  success,
  error,
}

abstract class EntityListNotifier<T, Q> extends ChangeNotifier {
  EntityListNotifier({
    required this._find,
    required this._deleteMany,
    required this._restore,
    required this._hardDelete,
    required Q initialQuery,
  })  : _query = initialQuery;

  final FindFunction<T, Q> _find;
  final DeleteManyFunction _deleteMany;
  final IdFunction _restore;
  final IdFunction _hardDelete;

  Q _query;
  PageResult<T> _result = PageResult.empty();

  LoadStatus _status = LoadStatus.idle;
  String? _errorMessage;

  final Set<int> _selected = {};

  Q get query => _query;
  PageResult<T> get result => _result;
  LoadStatus get status => _status;
  String? get errorMessage => _errorMessage;
  Set<int> get selected =>
      Set.unmodifiable(_selected);
  bool get hasSelection =>
      _selected.isNotEmpty;

  Future<void> load() async {
    _status = LoadStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _result = await _find(_query);
      _status = LoadStatus.success;
    } catch (error) {
      _status = LoadStatus.error;
      _errorMessage = error.toString();
    }

    notifyListeners();
  }

  Future<void> applyQuery(Q query) async {
    _query = query;
    _selected.clear();
    await load();
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

    await _deleteMany(_selected.toList());
    _selected.clear();
    await load();
  }

  Future<void> restore(int id) async {
    await _restore(id);
    await load();
  }

  Future<void> hardDelete(int id) async {
    await _hardDelete(id);
    await load();
  }
}