import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter_data_table/flutter_data_table.dart';
import 'package:pagination_view/pagination_view.dart';
import 'edit_component_form.dart';

class ReportPage extends StatefulWidget {
  @override
  _ReportPageState createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  int _sortColumnIndex = 0;
  bool _sortAscending = true;
  final _filterController = TextEditingController();

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  Future<void> _generateCsv() async {
    List<Map<String, dynamic>> components =
    await DatabaseHelper.instance.getComponents();
    List<List<dynamic>> csvData = [
      ['Codice', 'Quantità Prevista', 'Quantità Ricevuta', 'Verificato'],
    ];
    for (var component in components) {
      csvData.add([
        component['codice'],
        component['quantita_prevista'],
        component['quantita_ricevuta'],
        component['verificato'] == 1 ? 'Sì' : 'No',
      ]);
    }
    String csv = const ListToCsvConverter().convert(csvData);

    // Salva il file CSV
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/report_verifica.csv';
    final file = File(path);
    await file.writeAsString(csv);

    // Mostra un messaggio di successo
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Report esportato in $path'),
    ));
  }

  void _sortColumn(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
    });
  }

  List<Map<String, dynamic>> _filterComponents(
      List<Map<String, dynamic>> components) {
    final filterText = _filterController.text.toLowerCase();
    return components.where((component) {
      return component['codice'].toLowerCase().contains(filterText);
    }).toList();
  }

  Future<void> _editComponent(Map<String, dynamic> component) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return EditComponentForm(component: component);
      },
    );
    setState(() {});
  }

  Future<void> _deleteComponent(String codice) async {
    await DatabaseHelper.instance.deleteComponent(codice);
    setState(() {});
  }

  Future<void> _toggleVerified(String codice, bool isVerified) async {
    await DatabaseHelper.instance.updateComponentVerified(codice, !isVerified);
    setState(() {});
  }

  Future<Map<String, int>> _getSummary() async {
    final components = await DatabaseHelper.instance.getComponents();
    int totalComponents = components.length;
    int verifiedComponents =
        components.where((c) => c['verificato'] == 1).length;
    int discrepancies = components
        .where((c) => c['quantita_prevista'] != c['quantita_ricevuta'])
        .length;
    return {
      'total': totalComponents,
      'verified': verifiedComponents,
      'discrepancies': discrepancies,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Report Verifica'),
        actions: [
          IconButton(
            icon: Icon(Icons.download),
            onPressed: _generateCsv,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _filterController,
              decoration: InputDecoration(
                hintText: 'Filtra per codice...',
                suffixIcon: IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () {
                    _filterController.clear();
                    setState(() {});
                  },
                ),
              ),
              onChanged: (text) {
                setState(() {});
              },
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: DatabaseHelper.instance.getComponents(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final filteredComponents = _filterComponents(snapshot.data!);
                  return Column(
                    children: [
                      FutureBuilder<Map<String, int>>(
                        future: _getSummary(),
                        builder: (context, summarySnapshot) {
                          if (summarySnapshot.hasData) {
                            return Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    children: [
                                      Text(
                                        'Riepilogo',
                                        style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                          'Componenti totali: ${summarySnapshot.data!['total']}'),
                                      Text(
                                          'Componenti verificati: ${summarySnapshot.data!['verified']}'),
                                      Text(
                                          'Discrepanze: ${summarySnapshot.data!['discrepancies']}'),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          } else {
                            return SizedBox.shrink();
                          }
                        },
                      ),
                      Expanded(
                        child: PaginationView<Map<String, dynamic>>(
                          preloadedItems: [],
                          paginationViewType: PaginationViewType.table,
                          itemBuilder:
                              (BuildContext context, component, int index) {
                            bool hasDiscrepancy =
                                component['quantita_prevista'] !=
                                    component['quantita_ricevuta'];
                            return DataRow(
                              color: MaterialStateProperty.resolveWith<Color>(
                                      (Set<MaterialState> states) {
                                    if (hasDiscrepancy) {
                                      return Colors.yellow.withOpacity(0.3);
                                    }
                                    return Colors
                                        .transparent; // Use default color
                                  }),
                              cells: [
                                DataCell(Text(component['codice'])),
                                DataCell(Text(
                                    component['quantita_prevista'].toString())),
                                DataCell(Text(
                                    component['quantita_ricevuta'].toString())),
                                DataCell(IconButton(
                                  icon: Icon(Icons.edit),
                                  onPressed: () => _editComponent(component),
                                )),
                                DataCell(IconButton(
                                  icon: Icon(Icons.delete),
                                  onPressed: () =>
                                      _deleteComponent(component['codice']),
                                )),
                                DataCell(Checkbox(
                                  value: component['verificato'] == 1,
                                  onChanged: (value) => _toggleVerified(
                                      component['codice'], value!),
                                )),
                              ],
                            );
                          },
                          pageFetch: (int offset) async {
                            return filteredComponents
                                .skip(offset)
                                .take(10)
                                .toList();
                          },
                          onError: (dynamic error) => Center(
                            child: Text('Errore: $error'),
                          ),
                          onEmpty: Center(
                            child: Text('Nessun dato disponibile'),
                          ),
                          bottomLoader: Center(
                            child: CircularProgressIndicator(),
                          ),
                          initialLoader: Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      ),
                    ],
                  );
                } else if (snapshot.hasError) {
                  return Center(child: Text('Errore: ${snapshot.error}'));
                } else {
                  return Center(child: CircularProgressIndicator());
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}