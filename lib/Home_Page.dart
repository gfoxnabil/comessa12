import 'package:flutter/material.dart';
import 'component_list_page.dart';
import 'import_list_page.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Verifica Componenti'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ImportListPage()),
                );
              },
              child: Text('Importa Lista'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ComponentListPage()),
                );
              },
              child: Text('Lista Componenti'),
            ),
          ],
        ),
      ),
    );
  }
}