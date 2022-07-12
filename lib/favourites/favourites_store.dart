import 'package:loggy/loggy.dart';
import 'package:stocker/preferences/watchable_preferences.dart';

class FavouritesStore {
  final WatchablePreferences preferences;
  static const DEFAULT_GROUP = 'Default';
  static const _FAVOURITES_SYMBOLS_ROOT = 'favourites.symbols';
  static const _FAVOURITES_GROUPS = 'favourites.groups';
  static const _SYMBOLS_SEPARATOR = ',';

  FavouritesStore({required this.preferences});

  Future<List<String>> getGroups() {
    return preferences
        .get<String>(_FAVOURITES_GROUPS)
        .then(_extractValuesToList);
  }

  Stream<List<String>> watchGroups$() {
    return preferences
        .watch$<String>(_FAVOURITES_GROUPS)
        .map(_extractValuesToList);
  }

  Future<bool> addGroup(String groupName, [int position = -1]) {
    return getGroups().then((g) => _addValue(g, groupName, _FAVOURITES_GROUPS));
  }

  Future<bool> removeGroup(String groupName) {
    return getGroups()
        .then((g) => _removeValue(g, groupName, _FAVOURITES_GROUPS))
        .then(
          (removed) => preferences
              .save(_keyForGroup(groupName), null)
              .then((value) => removed),
        );
  }

  Stream<List<String>> watchGroup$(String group) {
    return preferences
        .watch$<String>(_keyForGroup(group))
        .map(_extractValuesToList);
  }

  Future<List<String>> getFavourites(String group) {
    return preferences
        .get<String>(_keyForGroup(group))
        .then(_extractValuesToList);
  }

  List<String> _extractValuesToList(String? value) {
    final asStr = value ?? '';
    return asStr.isEmpty ? [] : asStr.split(_SYMBOLS_SEPARATOR);
  }

  Future<bool> addToFavourites(
    String symbol,
    String group, [
    int position = 0,
  ]) {
    return _updateGroup(
      symbol,
      group,
      (c, s, g) => _addValue(c, s, g, position),
    );
  }

  Future<bool> removeFromFavourites(String symbol, String group) {
    return _updateGroup(symbol, group, _removeValue);
  }

  Future<bool> _updateGroup(
    String symbol,
    String group,
    Future<bool> update(
      List<String> currentValue,
      String symbol,
      String groupKey,
    ),
  ) {
    return getFavourites(group)
        .then((value) => update(value, symbol, _keyForGroup(group)));
  }

  Future<bool> _addValue(
    List<String> currentValue,
    String value,
    String key, [
    int position = 0,
  ]) {
    final currentIndex = currentValue.indexOf(value);
    if (position == -1) {
      if (currentIndex == -1) {
        position = currentValue.length;
      } else {
        position = currentValue.length - 1;
      }
    }
    if (currentIndex == position) {
      return Future.value(false);
    }
    if (currentIndex != -1) {
      currentValue.remove(value);
    }
    currentValue.insert(position, value);
    return preferences.save(key, currentValue.join(_SYMBOLS_SEPARATOR));
  }

  Future<bool> _removeValue(
    List<String> currentValue,
    String value,
    String key,
  ) {
    if (currentValue.isEmpty || !currentValue.contains(value)) {
      return Future.value(false);
    }
    final newValue = (currentValue..remove(value)).join(_SYMBOLS_SEPARATOR);
    logInfo('removed $value $newValue');
    return preferences.save(key, newValue);
  }

  String _keyForGroup(String group) => _FAVOURITES_SYMBOLS_ROOT + '.' + group;
}
