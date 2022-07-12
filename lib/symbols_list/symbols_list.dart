import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:stocker/favourites/favourites_store.dart';
import 'package:stocker/symbols_list/filter_data.dart';
import 'package:stocker/symbols_list/filtered_symbols_source.dart';
import 'package:stocker/symbols_list/symbol_list_item.dart';
import 'package:stocker/xtb/model/symbol_data.dart';

class SymbolsList extends StatefulWidget {
  const SymbolsList({super.key});

  @override
  State<SymbolsList> createState() => _SymbolsListState();
}

class _SymbolsListState extends State<SymbolsList> {
  final Map<String, bool> _expansions = HashMap();
  late final Stream<Set<String>> _allFavourites$;
  late final StreamSubscription<Set<String>> _behaviorSub;

  @override
  void initState() {
    super.initState();
    final favourites = Provider.of<FavouritesStore>(context, listen: false);
    _allFavourites$ = favourites
        .watchGroups$()
        .switchMap(
          (groups) => CombineLatestStream(
            groups.map((e) => favourites.watchGroup$(e).share()),
            (values) => values.expand((v) => v as List<String>).toSet(),
          ),
        )
        .debounceTime(
          Duration(milliseconds: 10),
        )
        .shareValue();
    _behaviorSub = _allFavourites$.listen((event) {});
  }

  @override
  Widget build(BuildContext context) {
    final favourites = Provider.of<FavouritesStore>(context, listen: false);

    return StreamBuilder<FilteredData?>(
      stream:
          Provider.of<FilteredSymbolsSource>(context, listen: false).filtered$,
      initialData: null,
      builder: (ctx, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          var data = snapshot.data!;
          Widget _itemBuilder(
            BuildContext context,
            int index,
            List<SymbolData> items,
          ) =>
              _buildSymbolListItem(items, index, favourites);

          Widget _headerBuilder(
            BuildContext context,
            bool isExpanded,
            String key,
          ) {
            _expansions[key] = isExpanded;
            return ListTile(title: Text(key));
          }

          return SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: ExpansionPanelList(
              expandedHeaderPadding: EdgeInsets.zero,
              elevation: 4,
              expansionCallback: (i, expanded) {
                setState(() {
                  _expansions[data.keys[i]] = !expanded;
                });
              },
              children: [
                ...data.keys.map((e) {
                  var group = data.groups[e]!;
                  var maxHeight = MediaQuery.of(context).size.height / 3 * 2;
                  var groupExpanded = _expansions[e] == true;
                  return ExpansionPanel(
                    isExpanded: groupExpanded,
                    canTapOnHeader: true,
                    headerBuilder: (ctx, expanded) =>
                        _headerBuilder(context, expanded, e),
                    body: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: maxHeight,
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const ClampingScrollPhysics(),
                        itemBuilder: (ctx, i) => _itemBuilder(ctx, i, group),
                        itemCount: groupExpanded ? group.length : 0,
                      ),
                    ),
                  );
                })
              ],
            ),
          );
        } else if (snapshot.hasError) {
          return Align(
            child: Text('${snapshot.stackTrace}'),
            alignment: Alignment.center,
          );
        }

        // By default, show a loading spinner.
        return Align(
          child: const CircularProgressIndicator(),
          alignment: Alignment.center,
        );
      },
    );
  }

  StreamBuilder<bool> _buildSymbolListItem(
      List<SymbolData> items, int index, FavouritesStore favourites) {
    final symbol = items[index];
    return StreamBuilder<bool>(
      builder: (ctx, snap) {
        final isFavourite = snap.hasData && snap.data!;
        return SymbolListItemWidget(
          symbol: symbol,
          isFavourite: isFavourite,
          toggleFavourite: () =>
              _toggleFavouriteState(isFavourite, favourites, symbol),
        );
      },
      stream: _allFavourites$
          .map((event) => event.contains(symbol.symbol))
          .distinct(),
    );
  }

  void _toggleFavouriteState(
      bool isFavourite, FavouritesStore favourites, SymbolData symbol) {
    if (isFavourite) {
      favourites.removeFromFavourites(
        symbol.symbol,
        FavouritesStore.DEFAULT_GROUP,
      );
    } else {
      favourites.addToFavourites(
        symbol.symbol,
        FavouritesStore.DEFAULT_GROUP,
      );
    }
  }

  @override
  void dispose() {
    super.dispose();
    _behaviorSub.cancel();
  }
}
