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
    await Future.delayed(_SYNC_DURATION);
    expect(
      watched.length,
      element.length + 1,
      reason: 'expect history long as changes + 1 (initial empty state)',
    );
  });

  test('can add on the end with -1', () async {
    final group = 'aaqwe';
    final store = await _initializeStoreWithItems(['1', '2', '3'], group);
    await store.addToFavourites('10', group, -1);
    final actual = await store.getFavourites(group);
    await Future.delayed(_SYNC_DURATION);
    expect(
      actual,
      ['3', '2', '1', '10'],
      reason: 'when last expected, it should be added on the end',
    );
  });

  test('should move already stored item to the end if required', () async {
    final group = 'aaqwe';
    final store = await _initializeStoreWithItems(['1', '2', '3'], group);
    await store.addToFavourites('3', group, -1);
    final actual = await store.getFavourites(group);
    await Future.delayed(_SYNC_DURATION);
    expect(
      actual,
      ['2', '1', '3'],
      reason: 'when last expected, it should be added on the end',
    );
  });

  test('should clean group after removing', () async {
    final group = 'aaqwe';
    final store = await _initializeStoreWithItems(['1', '2', '3'], group);
    final groupsBeforeGroupAdd = await store.getGroups();
    expect(
      groupsBeforeGroupAdd,
      [],
      reason: 'group need to be added manually',
    );
    await store.addGroup(group);
    final groupsAfterGroupAdd = await store.getGroups();
    expect(
      groupsAfterGroupAdd,
      [group],
      reason: 'group should be added',
    );
    final storedInGroup = await store.getFavourites(group);
    expect(storedInGroup, ['3', '2', '1'],
        reason: 'items should be added to group');
    await store.removeGroup(group);
    final afterRemove = await store.getFavourites(group);
    expect(
      afterRemove,
      [],
      reason: 'group after remove should be empty',
    );
    final groupsAfterRemove = await store.getGroups();
    expect(
      groupsAfterRemove,
      [],
      reason: 'there should be no groups after remove',
    );
  });
}

final _SYNC_DURATION = Duration(milliseconds: 100);

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
