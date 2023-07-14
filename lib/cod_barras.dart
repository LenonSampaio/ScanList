import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share/share.dart';

class BarcodeScanner extends StatefulWidget {
  const BarcodeScanner({Key? key}) : super(key: key);

  @override
  _BarcodeScannerState createState() => _BarcodeScannerState();
}

class _BarcodeScannerState extends State<BarcodeScanner> {
  final List<String> _barcodes = [];
  String _currentBarcode = '';
  List<String> _fileList = [];
  String _selectedFile = '';

  @override
  void initState() {
    super.initState();
    _loadFileList();
  }

  Future<void> _loadFileList() async {
    final directory = await getApplicationDocumentsDirectory();
    final files = await directory.list().toList();

    setState(() {
      _fileList = files
          .map((file) => file.path.split('/').last.replaceAll('.txt', ''))
          .toList();
      if (_fileList.isNotEmpty) {
        _selectedFile = _fileList[0];
      }
    });
  }

  Future<void> _scanBarcode() async {
    String barcodeResult = await FlutterBarcodeScanner.scanBarcode(
      '#ff6666', // Cor do botão de escaneamento
      'Cancelar', // Texto do botão de cancelamento
      true, // Mostrar flash na câmera
      ScanMode.BARCODE, // Modo de escaneamento (código de barras)
    );

    if (!mounted) return;

    if (barcodeResult != '-1') {
      setState(() {
        _currentBarcode = barcodeResult;
      });
    }
  }

  Future<void> _saveToFile() async {
    if (_currentBarcode.isEmpty) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Erro'),
            content: const Text('Nenhum código de barras lido.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
      return;
    }

    if (_selectedFile.isEmpty) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Erro'),
            content: const Text('Nenhum arquivo selecionado.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
      return;
    }

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$_selectedFile.txt');

    await file.writeAsString('$_currentBarcode\n', mode: FileMode.append);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Arquivo Salvo'),
          content: Text(
              'O código de barras $_currentBarcode foi salvo em $_selectedFile.txt'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );

    setState(() {
      _currentBarcode = ''; // Limpa o código atual
    });
  }

  Future<void> _createNewFile(String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName.txt');

    if (await file.exists()) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Erro'),
            content: const Text('Essa lista já existe.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
      return;
    }

    await file.create();
    _loadFileList(); // Atualiza a lista de arquivos após criar um novo arquivo

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Arquivo Criado'),
          content:
              Text('O arquivo $fileName.txt foi criado em ${directory.path}'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _viewFile(String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName.txt');

    if (await file.exists()) {
      final contents = await file.readAsString();

      showDialog(
        context: context,
        builder: (BuildContext context) {
          String editedContents = contents;

          return AlertDialog(
            title: const Text('Lista de Códigos de Barras'),
            content: SingleChildScrollView(
              child: TextFormField(
                initialValue: contents,
                onChanged: (value) {
                  editedContents = value;
                },
                maxLines: null,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  await file.writeAsString(editedContents);
                  Navigator.of(context).pop();
                },
                child: const Text('Salvar'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Fechar'),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> _deleteFile(String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName.txt');

    if (await file.exists()) {
      await file.delete();
      _loadFileList();

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Arquivo Excluído'),
            content: Text('O arquivo $fileName.txt foi excluído.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> _shareFile(String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName.txt');

    if (await file.exists()) {
      final contents = await file.readAsString();
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/$fileName.txt');
      await tempFile.writeAsString(contents);

      Share.shareFiles([tempFile.path]);
    }
  }

  Future<void> _renameFile(String fileName) async {
    String newFileName = fileName;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Renomear Arquivo'),
          content: TextField(
            onChanged: (value) {
              newFileName = value;
            },
            decoration: const InputDecoration(
              labelText: 'Novo nome do arquivo',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                final directory = await getApplicationDocumentsDirectory();
                final file = File('${directory.path}/$fileName.txt');
                final newFile = File('${directory.path}/$newFileName.txt');

                if (await newFile.exists()) {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Erro'),
                        content: const Text('Esse nome de arquivo já existe.'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text('OK'),
                          ),
                        ],
                      );
                    },
                  );
                  return;
                }

                await file.rename(newFile.path);
                _loadFileList();

                Navigator.of(context).pop();
              },
              child: const Text('Renomear'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Leitor de Código de Barras',
          style: TextStyle(color: Colors.black),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _fileList.length,
              itemBuilder: (BuildContext context, int index) {
                final fileName = _fileList[index];
                return ListTile(
                  leading: const Icon(Icons.file_present),
                  title: Text(
                    fileName,
                    style: const TextStyle(fontSize: 16),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () => _viewFile(fileName),
                        icon: const Icon(Icons.remove_red_eye),
                      ),
                      IconButton(
                        onPressed: () => _deleteFile(fileName),
                        icon: const Icon(Icons.delete),
                      ),
                      IconButton(
                        onPressed: () => _shareFile(fileName),
                        icon: const Icon(Icons.share),
                      ),
                      IconButton(
                        onPressed: () => _renameFile(fileName),
                        icon: const Icon(Icons.edit),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _scanBarcode,
            child: const Text('Escanear'),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _saveToFile,
            child: const Text('   Salvar   '),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  String fileName = '';

                  return AlertDialog(
                    title: const Text('Criar Novo Arquivo'),
                    content: TextField(
                      onChanged: (value) {
                        fileName = value;
                      },
                      decoration: const InputDecoration(
                        labelText: 'Nome do arquivo',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () {
                          _createNewFile(fileName);
                          Navigator.of(context).pop();
                        },
                        child: const Text('Criar'),
                      ),
                    ],
                  );
                },
              );
            },
            child: const Text('Nova lista'),
          ),
          const SizedBox(height: 10),
          DropdownButton<String>(
            value: _selectedFile,
            onChanged: (String? newValue) {
              setState(() {
                _selectedFile = newValue!;
              });
            },
            items: _fileList.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
