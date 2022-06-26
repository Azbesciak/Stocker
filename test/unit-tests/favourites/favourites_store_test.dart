import 'package:stocker/favourites/favourites_store.dart';
import 'package:stocker/preferences/watchable_preferences.dart';
import 'package:test/test.dart';

import '../mock-preferences.dart';

void main() {
  group('check if adding symbol works', () {
    final group = 'group';
    [
      ['A', 'B', 'C', 'D'],
      ['A'],
      ['G', 'B' 'D']
    ].forEach((element) {
      test('saving ${element} should result in ${element.reversed.toList()}',
          () async {
        final store = await _initializeStoreWithItems(element, group);
        final stored = await store.getFavourites(group);
        expect(
          stored,
          element.reversed,
          reason: 'expected same list like added, but reversed',
        );
      });
    });
  });

  group('Should not add duplicates', () {
    final group = 'group';
    [
      [
        ['A', 'B', 'C', 'D', 'A', 'C'],
        ['C', 'A', 'D', 'B']
      ],
      [
        ['B', 'G', 'B'],
        ['B', 'G'],
      ]
    ].forEach((element) {
      test('saving ${element[0]} should result in ${element[1]}', () async {
        final store = await _initializeStoreWithItems(element[0], group);
        final stored = await store.getFavourites(group);
        expect(
          stored,
          element[1],
          reason: 'expected list without duplicates in correct order',
        );
      });
    });
  });

  group('Should add on given position', () {
    test('saving on given position', () async {
      final initial = ['A', 'B', 'C', 'D'];
      final group = 'aaaa';
      final store = await _initializeStoreWithItems(initial, group);
      final inserted = 'X';
      await store.addToFavourites(inserted, group, 3);
      final expected = initial.reversed.toList()..insert(3, inserted);
      final stored = await store.getFavourites(group);
      expect(
        stored,
        expected,
        reason: 'should insert on given position',
      );
    });
  });

  group('Should remove given item', () {
    final group = 'group';
    [
      [
        ['A', 'B', 'C', 'D'],
        ['C'],
        ['A', 'B', 'D'].reversed.toList()
      ],
      [
        ['B'],
        ['B'],
        <String>[],
      ],
      [
        ['B', 'C', 'D'],
        ['B', 'C'],
        ['D'],
      ]
    ].forEach((element) {
      test(
          'saving ${element[0]} should result in ${element[2]} (removed ${element[1]})',
          () async {
        final store = await _initializeStoreWithItems(element[0], group);
        for (var e in element[1]) {
          await store.removeFromFavourites(e, group);
        }
        final stored = await store.getFavourites(group);
        expect(
          stored,
          element[2],
          reason: 'expected list without removed elements',
        );
      });
    });
  });

  test('updates are watchable', () async {
    final store = _getStore();
    final group = 'aaqwe';
    final stream = store.watchGroup$(group);
    final element = ['A', 'B', 'C', 'D'];
    final watched = <List<String>>[];
    stream.listen(watched.add);
    for (var e in element) {
      await store.addToFavourites(e, group);
    }
    await Future.delayed(Duration(seconds: 1));
    expect(
      watched.length,
      element.length + 1,
      reason: 'expect history long as changes + 1 (initial empty state)',
    );
  });
}

Future<FavouritesStore> _initializeStoreWithItems(
  List<String> element,
  String group,
) async {
  final store = _getStore();
  for (var e in element) {
    await store.addToFavourites(e, group);
  }
  return store;
}

FavouritesStore _getStore() =>
    FavouritesStore(preferences: WatchablePreferences(MockPreferences()));
