import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'ui/home_page.dart';

void main() {
  if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(const ProviderScope(child: BrewCoffeeApp()));
}

class BrewCoffeeApp extends StatelessWidget {
  const BrewCoffeeApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
      title: 'Brew Coffee',
      theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xff5e5ce6), brightness: Brightness.light),
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xfff5f5f7),
          appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              centerTitle: false),
          cardTheme: const CardThemeData(
              color: Colors.white,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              margin: EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(18)))),
          dialogTheme: const DialogThemeData(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(24)))),
          inputDecorationTheme: InputDecorationTheme(
              filled: false,
              fillColor: Colors.transparent,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: Color(0xff5e5ce6), width: 1.5)))),
      home: const HomePage());
}
