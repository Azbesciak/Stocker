import 'package:flutter/material.dart';
import 'package:loggy/loggy.dart';
import 'package:provider/provider.dart';
import 'package:stocker/dev_credentials.dart';
import 'package:stocker/preferences/preferences.dart';
import 'package:stocker/preferences/shared_preferences.dart';
import 'package:stocker/symbol/symbol_page.dart';
import 'package:stocker/symbols_list/symbols_list_page.dart';
import 'package:stocker/symbols_list/symbols_source.dart';
import 'package:stocker/xtb/connector.dart';
import 'package:stocker/xtb/json_helper.dart';

void main() {
  Loggy.initLoggy(logPrinter: PrettyPrinter(showColors: true));
  runApp(const StockerApp());
}

class StockerApp extends StatelessWidget {
  const StockerApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<Preferences>(
          create: (context) => SharedPreferences(),
        ),
        Provider<XTBApiConnector>(
          create: (context) => XTBApiConnector(
            url: 'wss://ws.xtb.com/demo',
            streamUrl: 'wss://ws.xtb.com/demoStream',
            appName: 'test',
          )
            ..init()
            ..login(devCredentials),
          dispose: (ctx, value) => value.dispose(),
        ),
        Provider<SymbolsSource>(
          create: (context) => SymbolsSource(context)..fetch(),
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
        initialRoute: SymbolsListPage.navRoute,
        onGenerateRoute: (RouteSettings settings) {
          Map<String, WidgetBuilder> routes = {
            // LandingPage.navRoute: (BuildContext context) => LandingPage(),
            SymbolsListPage.navRoute: (BuildContext context) =>
                SymbolsListPage(),
            SymbolPage.navRoute: (BuildContext context) {
              JsonObj arguments = settings.arguments as JsonObj;
              assert(arguments.containsKey('symbol'));
              return SymbolPage(
                symbol: arguments['symbol'],
              );
            },
          };
          logInfo('NAV: ${settings.name}, PARAMS: ${settings.arguments}');
          WidgetBuilder builder = routes[settings.name]!;
          return MaterialPageRoute(
            builder: (ctx) => builder(ctx),
            settings: settings,
          );
        },
      ),
    );
  }
}
