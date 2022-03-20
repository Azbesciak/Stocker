import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stocker/dev_credentials.dart';
import 'package:stocker/symbol/symbol_page.dart';
import 'package:stocker/ui_style.dart';
import 'package:stocker/xtb/model/symbol_data.dart';

import 'utils.dart';
import 'xtb/connector.dart';

class FavouritesPage extends StatefulWidget {
  static const navRoute = "/";

  const FavouritesPage({Key? key}) : super(key: key);

  @override
  State<FavouritesPage> createState() => _FavouritesPageState();
}

@immutable
class SymbolWidget extends StatelessWidget {
  final SymbolData symbol;

  const SymbolWidget({Key? key, required this.symbol}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Text(symbol.symbol),
        onTap: () {
          Navigator.pushNamed(
            context,
            SymbolPage.navRoute,
            arguments: {'symbol': symbol},
          );
        },
        title: Text(symbol.description),
      ),
    );
  }
}

class FilteredData {
  final List<SymbolData> original;
  final String filter;
  final List<String> keys;
  final Map<String, List<SymbolData>> groups;

  const FilteredData({
    required this.original,
    required this.filter,
    required this.keys,
    required this.groups,
  });
}

class _FavouritesPageState extends State<FavouritesPage> {
  final Completer<List<SymbolData>> _symbols = Completer();
  String _filter = '';
  FilteredData? _recentFilterValue;
  final Map<String, bool> _expansions = HashMap();

  @override
  void initState() {
    super.initState();
    checkAPI();
    _filter = '';
  }

  void checkAPI() async {
    final _connector = Provider.of<XTBApiConnector>(context, listen: false);
    await _connector.login(devCredentials);
    _connector
        .getAllSymbols()
        .then(_symbols.complete)
        .onError(_symbols.completeError);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FutureBuilder<List<SymbolData>>(
          future: _symbols.future,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              var data = _filterData(snapshot.data!, _filter);
              Widget _itemBuilder(
                  BuildContext context, int index, List<SymbolData> items) {
                return SymbolWidget(symbol: items[index]);
              }

              Widget _headerBuilder(
                  BuildContext context, bool isExpanded, String key) {
                _expansions[key] = isExpanded;
                return ListTile(title: Text(key));
              }

              return Stack(
                children: [
                  SingleChildScrollView(
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
                          var maxHeight =
                              MediaQuery.of(context).size.height / 3 * 2;
                          return ExpansionPanel(
                              isExpanded: _expansions[e] == true,
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
                                  itemBuilder: (ctx, i) =>
                                      _itemBuilder(ctx, i, group),
                                  itemCount:
                                      _expansions[e] == true ? group.length : 0,
                                ),
                              ));
                        })
                      ],
                    ),
                  ),
                  Align(
                      alignment: Alignment.bottomCenter,
                      child: Card(
                          elevation: 2,
                          child: Padding(
                            padding: EdgeInsets.all(UIStyle.contentMarginSmall),
                            child: TextField(
                              onChanged: (v) {
                                setState(() {
                                  _filter = v;
                                });
                              },
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'Query',
                              ),
                            ),
                          )))
                ],
              );
            } else if (snapshot.hasError) {
              return Text('${snapshot.stackTrace}');
            }

            // By default, show a loading spinner.
            return const CircularProgressIndicator();
          },
        ),
      ),
    );
  }

  List<SymbolData> _filterSymbols(List<SymbolData> symbols, String filter) {
    var searchableFilter = filter.trim().toLowerCase();
    return searchableFilter.isEmpty
        ? symbols
        : List.of(symbols.where((e) =>
            _containsPhrase(e.symbol.toLowerCase(), searchableFilter) ||
            _containsPhrase(e.description.toLowerCase(), searchableFilter)));
  }
}
