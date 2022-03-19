import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stocker/xtb/connector.dart';
import 'package:stocker/xtb/json_helper.dart';
import 'package:stocker/symbol/symbol_page.dart';

import 'favourites_page.dart';

void main() {
  runApp(const StockerApp());
}

class StockerApp extends StatelessWidget {
  const StockerApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<XTBApiConnector>(
          create: (context) => XTBApiConnector(
            url: 'wss://ws.xtb.com/demo',
            appName: 'test',
          )..init(),
          dispose: (ctx, value) => value.dispose(),
        )
      ],
      child: MaterialApp(
          title: 'Stocker',
          themeMode: ThemeMode.dark,
          darkTheme: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.red,
              brightness: Brightness.dark,
            ),
          ),
          theme: ThemeData.light().copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.red,
              brightness: Brightness.light,
            ),
          ),
          initialRoute: FavouritesPage.navRoute,
          onGenerateRoute: (RouteSettings settings) {
            Map<String, WidgetBuilder> routes = {
              // LandingPage.navRoute: (BuildContext context) => LandingPage(),
              FavouritesPage.navRoute: (BuildContext context) =>
                  FavouritesPage(),
              SymbolPage.navRoute: (BuildContext context) {
                JsonObj arguments = settings.arguments as JsonObj;
                assert(arguments.containsKey('symbol'));
                return SymbolPage(
                  symbol: arguments['symbol'],
                );
              },
            };
            log('NAVIGATION: ${settings.name}, PARAMS: ${settings.arguments}');
            WidgetBuilder builder = routes[settings.name]!;
            return MaterialPageRoute(
              builder: (ctx) => builder(ctx),
              settings: settings,
            );
          }),
    );
  }
}
