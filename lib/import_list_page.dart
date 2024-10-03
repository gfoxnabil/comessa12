import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';
import 'database_helper.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:file_picker/file_picker.dart';
import 'manual_insert_form.dart';
import 'dart:io';

class ImportListPage extends StatefulWidget {
  @override
  _ImportListPageState createState() => _ImportListPageState();
}

class _ImportListPageState extends State<ImportListPage> {
  String _feedbackMessage = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Importa Lista Componenti'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                _scanCode();
              },
              child: Text('Scansiona Codice'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _uploadFile();
              },
              child: Text('Carica File'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _insertManually();
              },
              child: Text('Inserisci Manualmente'),
            ),
            SizedBox(height: 20),
            Text(_feedbackMessage),
          ],
        ),
      ),
    );
  }

  Future<void> _scanCode() async {
    try {
      String barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
          '#ff6666', 'Cancella', true, ScanMode.BARCODE);
      if (barcodeScanRes != '-1') {
        setState(() {
          _feedbackMessage = 'Ricerca componente in corso...';
        });
        try {
          // Carica il file CSV
          final input =
          await rootBundle.loadString('assets/lista_componenti.csv');
          List<List<dynamic>> csvTable = CsvToListConverter().convert(input);

          // Trova il componente corrispondente
          bool found = false;
          for (var row in csvTable) {
            if (row[0] == barcodeScanRes) {
              int quantitaPrevista = int.parse(row[1]);
              // Aggiorna il database
              await DatabaseHelper.instance.insertComponent(
                  barcodeScanRes, quantitaPrevista, 1, 0);
              found = true;
              break;
            }
          }

          setState(() {
            _feedbackMessage = found
                ? 'Componente trovato e aggiunto al database'
                : 'Componente non trovato nella lista';
          });
        } catch (e) {
          setState(() {
            _feedbackMessage = 'Errore durante la ricerca del componente: $e';
          });
        }
      } else {
        setState(() {
          _feedbackMessage = 'Scansione annullata';
        });
      }
    } catch (e) {
      setState(() {
        _feedbackMessage = 'Errore durante la scansione: $e';
      });
    }
  }

  Future<void> _uploadFile() async {
    setState(() {
      _feedbackMessage = 'Caricamento file in corso...';
    });
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null) {
        PlatformFile file = result.files.first;
        final input = await File(file.path!).readAsString();
        List<List<dynamic>> csvTable = const CsvToListConverter().convert(input);

        // Elimina l'intestazione del CSV
        if (csvTable.isNotEmpty) {
          csvTable.removeAt(0);
        }

        for (var row in csvTable) {
          try {
            String codice = row[0].toString();
            int quantitaPrevista = int.parse(row[1].toString());
            // Aggiorna il database
            await DatabaseHelper.instance
                .insertComponent(codice, quantitaPrevista, 0, 0);
          } catch (e) {
            // Gestisci l'errore durante l'elaborazione di una riga del CSV
            setState(() {
              _feedbackMessage =
              'Errore durante l\'elaborazione di una riga del file: $e';
            });
            return; // Interrompi l'elaborazione del file
          }
        }

        setState(() {
          _feedbackMessage = 'File caricato e database aggiornato con successo!';
        });
      } else {
        setState(() {
          _feedbackMessage = 'Caricamento file annullato';
        });
      }
    } catch (e) {
      // Gestisci l'errore generale durante il caricamento del file
      setState(() {
        _feedbackMessage = 'Errore durante il caricamento del file: $e';
      });
    }
  }

  void _insertManually() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ManualInsertForm();
      },
    );
  }
}