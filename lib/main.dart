import 'package:flutter/material.dart';
import 'package:movil_jmas_reg/registros/list_lecturas_screen.dart';
import 'package:movil_jmas_reg/registros/registro_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lecturas JMAS',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green.shade900),
        useMaterial3: true,
      ),
      initialRoute: '/registro',
      routes: {
        '/registro': (context) => const RegistroScreen(),
        '/lista': (context) => const ListLecturasScreen(),
      },
    );
  }
}
