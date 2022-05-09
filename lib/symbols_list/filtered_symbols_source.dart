import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/streams.dart';
import 'package:rxdart/subjects.dart';
import 'package:stocker/symbols_list/filter_data.dart';
import 'package:stocker/symbols_list/symbols_source.dart';
import 'package:stocker/utils.dart';
import 'package:stocker/xtb/model/symbol_data.dart';

class FilteredSymbolsSource {
  late final _filter$ = BehaviorSubject<String>.seeded('');
  FilteredData? _recentFilterValue;
  late final Stream<FilteredData?> filtered$;

  set filterValue(String value) {
    _filter$.add(value);
  }

  FilteredSymbolsSource(BuildContext ctx) {
    filtered$ = CombineLatestStream<dynamic, FilteredData?>(
      [
        Provider.of<SymbolsSource>(ctx, listen: false).symbols,
        _filter$,
      ],
      (v) => _filterData(v[0], v[1]),
    ).distinct();
  }

  FilteredData _filterData(List<SymbolData> originalData, String filter) {
    if (_recentFilterValue?.filter == filter &&
        _recentFilterValue?.original == originalData) {
      return _recentFilterValue!;
    }
    var data = _filterSymbols(originalData, filter);
    var grouped = groupBy<SymbolData, String>(data, (v) => v.categoryName);
    var keys = grouped.keys.toList()..sort((a, b) => a.compareTo(b));
    _recentFilterValue = FilteredData(
      original: originalData,
      filter: filter,
      keys: keys,
      groups: grouped,
    );
    return _recentFilterValue!;
  }

  List<SymbolData> _filterSymbols(List<SymbolData> symbols, String filter) {
    var searchableFilter = filter.trim().toLowerCase();
    return searchableFilter.isEmpty
        ? symbols
        : List.of(
            symbols.where(
              (e) =>
                  _containsPhrase(
                    e.symbol.toLowerCase(),
                    searchableFilter,
                  ) ||
                  _containsPhrase(
                    e.description.toLowerCase(),
                    searchableFilter,
                  ),
            ),
          );
  }

  bool _containsPhrase(String word, String query) {
    var lastIndex = -1;
    for (var i = 0; i < query.length; i++) {
      lastIndex = word.indexOf(query[i], lastIndex + 1);
      if (lastIndex == -1) {
        return false;
      }
    }
    return true;
  }
}
