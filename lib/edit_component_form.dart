import 'package:flutter/material.dart';
import 'database_helper.dart';

class EditComponentForm extends StatefulWidget {
  final Map<String, dynamic> component;

  const EditComponentForm({Key? key, required this.component})
      : super(key: key);

  @override
  _EditComponentFormState createState() => _EditComponentFormState();
}

class _EditComponentFormState extends State<EditComponentForm> {
  final _codiceController = TextEditingController();
  final _quantitaPrevistaController = TextEditingController();
  final _quantitaRicevutaController = TextEditingController();
  String _feedbackMessage = '';

  @override
  void initState() {
    super.initState();
    _codiceController.text = widget.component['codice'].toString();
    _quantitaPrevistaController.text =
        widget.component['quantita_prevista'].toString();
    _quantitaRicevutaController.text =
        widget.component['quantita_ricevuta'].toString();
  }

  @override
  void dispose() {
    _codiceController.dispose();
    _quantitaPrevistaController.dispose();
    _quantitaRicevutaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Modifica Componente'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _codiceController,
            decoration: InputDecoration(labelText: 'Codice'),
            enabled: false,
          ),
          TextField(
            controller: _quantitaPrevistaController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: 'Quantità Prevista'),
          ),
          TextField(
            controller: _quantitaRicevutaController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: 'Quantità Ricevuta'),
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
            int? quantitaPrevista = int.tryParse(_quantitaPrevistaController.text);
            int? quantitaRicevuta = int.tryParse(_quantitaRicevutaController.text);
            if (codice.isNotEmpty && quantitaPrevista != null && quantitaRicevuta != null &&
                quantitaPrevista >= 0 && quantitaRicevuta >= 0) {
              try {
                DatabaseHelper.instance.updateComponent(
                    codice, quantitaPrevista, quantitaRicevuta);
                Navigator.of(context).pop();
              } catch (e) {
                setState(() {
                  _feedbackMessage =
                  'Errore durante l\'aggiornamento del componente: $e';
                });
              }
            } else {
              setState(() {
                _feedbackMessage = 'Inserisci valori validi.';
              });
            }
          },
          child: Text('Salva'),
        ),
      ],
    );
  }
}