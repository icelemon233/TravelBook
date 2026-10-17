import 'dart:async';
import 'dart:convert';

import '../../../core/json_values.dart';
import '../../books/domain/travel_book.dart';
import '../domain/legacy_migration.dart';
import '../domain/preferences_repository.dart';
import '../domain/user_preferences.dart';

class LocalPreferencesRepository implements PreferencesRepository {
  LocalPreferencesRepository(this.store, this.legacyReader);
  final PreferencesStore store;
  final LegacyPreferencesReader legacyReader;
  final _controller = StreamController<PreferencesSnapshot>.broadcast(
    sync: true,
  );
  UserPreferences _value = UserPreferences();
  Future<void> _tail = Future.value();
  Future<void>? _importBarrier;
  int _revision = 0;
  int _replacementRevision = 0;
  bool _saving = false, _closed = false, _readFailed = false;
  String? _error, _recoveryRaw;
  @override
  PreferencesSnapshot get snapshot => PreferencesSnapshot(
    value: _value,
    saving: _saving,
    error: _error,
    recoveryRaw: _recoveryRaw,
    replacementRevision: _replacementRevision,
  );
  @override
  Stream<PreferencesSnapshot> get changes => _controller.stream;
  void _emit() {
    if (!_closed) _controller.add(snapshot);
  }

  @override
  Future<void> initialize(List<TravelBook> books) async {
    String? stored;
    var migrated = false;
    try {
      stored = await store.read();
      if (stored != null) {
        _value = UserPreferences.fromJson(jsonObject(jsonDecode(stored)));
      } else {
        _value = const LegacyMigration().migrate(legacyReader.read(), books);
        migrated = _value.books.isNotEmpty;
      }
    } catch (_) {
      _readFailed = true;
      _recoveryRaw = stored;
      _error = stored == null
          ? '未能读取本地资料，已暂停自动保存。本次修改可导出备份；重新打开应用重试读取，或导入有效备份。'
          : '本地资料格式无法读取，原始内容已保留。请导出恢复副本，或导入有效备份；本次修改可另行导出。';
      _emit();
      return;
    }
    _readFailed = false;
    _error = null;
    _recoveryRaw = null;
    if (migrated) {
      await _persist();
      return;
    }
    _emit();
  }

  @override
  Future<void> updateBook(
    String id,
    BookPreferences Function(BookPreferences) edit,
  ) {
    final barrier = _importBarrier;
    if (barrier != null) {
      return barrier.then(
        (_) => updateBook(id, edit),
        onError: (Object _, StackTrace _) => updateBook(id, edit),
      );
    }
    _value = _value.update(id, edit(_value.forBook(id)));
    if (_readFailed) {
      _emit();
      return Future.value();
    }
    return _persist();
  }

  Future<void> _persist() {
    final revision = ++_revision, encoded = jsonEncode(_value.toJson());
    _saving = true;
    _emit();
    _tail = _tail.then((_) async {
      try {
        await store.write(encoded);
        if (revision == _revision) _error = null;
      } catch (_) {
        _error = '保存失败。内容仍保留在本次会话，请导出备份后检查设备存储。';
      }
      if (revision == _revision) _saving = false;
      _emit();
    });
    return _tail;
  }

  @override
  Future<void> importBackup(String source) async {
    final imported = UserPreferences.import(source);
    if (_importBarrier != null) {
      await _importBarrier!.then((_) {}, onError: (Object _, StackTrace _) {});
    }
    _saving = true;
    _emit();
    final work = _tail.then((_) async {
      try {
        // New edits wait and apply to the committed imported state.
        await store.write(jsonEncode(imported.toJson()));
        _value = imported;
        _readFailed = false;
        _recoveryRaw = null;
        _error = null;
        _revision++;
        _replacementRevision++;
      } catch (_) {
        _error = '导入未完成，原有资料未被替换。';
        rethrow;
      }
    });
    late final Future<void> barrier;
    barrier = work.whenComplete(() {
      if (identical(_importBarrier, barrier)) _importBarrier = null;
      _saving = false;
      _emit();
    });
    _importBarrier = barrier;
    _tail = barrier.then((_) {}, onError: (Object _, StackTrace _) {});
    return barrier;
  }

  @override
  Future<void> flush() => _tail;
  @override
  Future<void> dispose() async {
    await _tail;
    _closed = true;
    await _controller.close();
  }
}
