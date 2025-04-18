import 'package:flutter/material.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.green,
            ),
            child: Text(
              'Menú JMAS',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.edit_document),
            title: const Text('Registro de Lecturas'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/registro');
            },
          ),
          ListTile(
            leading: const Icon(Icons.list),
            title: const Text('Lista de Lecturas'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/lista');
            },
          ),
        ],
      ),
    );
  }
}
