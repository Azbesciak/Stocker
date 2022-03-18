import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stocker/dev_credentials.dart';
import 'package:stocker/symbol_page.dart';
import 'package:stocker/xtb/model/symbol_data.dart';

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

class _FavouritesPageState extends State<FavouritesPage> {
  final Completer<List<SymbolData>> _symbols = Completer();

  @override
  void initState() {
    super.initState();
    checkAPI();
  }

  void checkAPI() async {
    final _connector = Provider.of<XTBApiConnector>(context, listen: false);
    await _connector.login(devCredentials);
    _connector
        .getAllSymbols()
        .then(_symbols.complete)
        .onError(_symbols.completeError);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FutureBuilder<List<SymbolData>>(
          future: _symbols.future,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              Widget _itemBuilder(BuildContext context, int index) {
                return SymbolWidget(symbol: snapshot.data![index]);
              }

              return ListView.builder(
                  itemBuilder: _itemBuilder, itemCount: snapshot.data!.length);
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
}
