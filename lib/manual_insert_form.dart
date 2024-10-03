import 'package:flutter/material.dart';
import 'database_helper.dart';

class ManualInsertForm extends StatefulWidget {
  @override
  _ManualInsertFormState createState() => _ManualInsertFormState();
}

class _ManualInsertFormState extends State<ManualInsertForm> {
  final _codiceController = TextEditingController();
  final _quantitaController = TextEditingController();
  String _feedbackMessage = '';

  @override
  void dispose() {
    _codiceController.dispose();
    _quantitaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Inserisci Componente Manualmente'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _codiceController,
            decoration: InputDecoration(labelText: 'Codice'),
          ),
          TextField(
            controller: _quantitaController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: 'Quantità Prevista'),
          ),
          SizedBox(height: 10),
          Text(
            _feedbackMessage,
            style: TextStyle(color: Colors.red),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('Annulla'),
        ),
        TextButton(
          onPressed: () {
            String codice = _codiceController.text;
            int? quantita = int.tryParse(_quantitaController.text);

            if (codice.isNotEmpty && quantita != null && quantita > 0) {
              try {
                DatabaseHelper.instance
                    .insertComponent(codice, quantita, 0, 0);
                Navigator.of(context).pop();
              } catch (e) {
                setState(() {
                  _feedbackMessage =
                  'Errore durante l\'inserimento del componente: $e';
                });
              }
            } else {
              setState(() {
                _feedbackMessage = 'Inserisci un codice e una quantità validi.';
              });
            }
          },
          child: Text('Inserisci'),
        ),
      ],
    );
  }
}