import 'package:stocker/preferences/watchable_preferences.dart';

class FavouritesStore {
  final WatchablePreferences preferences;
  static const _FAVOURITES_SYMBOLS_ROOT = 'favourites.symbols';
  static const _SYMBOLS_SEPARATOR = ',';

  FavouritesStore({required this.preferences});

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
      (c, s, g) => _addSymbolToGroup(c, s, g, position),
    );
  }

  Future<bool> removeFromFavourites(String symbol, String group) {
    return _updateGroup(symbol, group, _removeSymbolFromGroup);
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

  Future<bool> _addSymbolToGroup(
    List<String> currentValue,
    String symbol,
    String keyForGroup, [
    int position = 0,
  ]) {
    final currentIndex = currentValue.indexOf(symbol);
    if (currentIndex == position) {
      return Future.value(false);
    }
    if (currentIndex != -1) {
      currentValue.remove(symbol);
    }
    currentValue.insert(position, symbol);
    return preferences.save(keyForGroup, currentValue.join(_SYMBOLS_SEPARATOR));
  }

  Future<bool> _removeSymbolFromGroup(
    List<String> currentValue,
    String symbol,
    String keyForGroup,
  ) {
    if (currentValue.isEmpty || !currentValue.contains(symbol)) {
      return Future.value(false);
    }
    final newValue = (currentValue..remove(symbol)).join(_SYMBOLS_SEPARATOR);
    return preferences.save(keyForGroup, newValue);
  }

  String _keyForGroup(String group) => _FAVOURITES_SYMBOLS_ROOT + '.' + group;
}
