import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stocker/dev_credentials.dart';
import 'package:stocker/symbols_list/filter_data.dart';
import 'package:stocker/symbols_list/symbol_filter.dart';
import 'package:stocker/symbols_list/symbol_list_item.dart';
import 'package:stocker/utils.dart';
import 'package:stocker/xtb/connector.dart';
import 'package:stocker/xtb/model/symbol_data.dart';

class SymbolsListPage extends StatefulWidget {
  static const navRoute = '/';

  const SymbolsListPage({Key? key}) : super(key: key);

  @override
  State<SymbolsListPage> createState() => _SymbolsListPageState();
}

class _SymbolsListPageState extends State<SymbolsListPage> {
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
                BuildContext context,
                int index,
                List<SymbolData> items,
              ) {
                return SymbolListItemWidget(symbol: items[index]);
              }

              Widget _headerBuilder(
                BuildContext context,
                bool isExpanded,
                String key,
              ) {
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
                                itemBuilder: (ctx, i) =>
                                    _itemBuilder(ctx, i, group),
                                itemCount: groupExpanded ? group.length : 0,
                              ),
                            ),
                          );
                        })
                      ],
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: SymbolFilter(onInputChange: _updateFilterValue),
                  )
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

  void _updateFilterValue(String v) {
    setState(() {
      _filter = v;
    });
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
}
