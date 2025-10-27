import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() => runApp(MaterialApp(home: FileStorageDemo()));

class FileStorageDemo extends StatefulWidget {
  @override
  State<FileStorageDemo> createState() => _FileStorageDemoState();
}

class _FileStorageDemoState extends State<FileStorageDemo> {
  String content = '';

  Future<String> get _filePath async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/user_data.txt';
  }

  Future<void> writeData(String text) async {
    final path = await _filePath;
    final file = File(path);
    await file.writeAsString(text);
  }

  Future<void> readData() async {
    final path = await _filePath;
    final file = File(path);
    if (await file.exists()) {
      final data = await file.readAsString();
      setState(() => content = data);
    } else {
      setState(() => content = 'No file found.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController();
    return Scaffold(
      appBar: AppBar(title: Text('File Storage Demo')),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(controller: controller, decoration: InputDecoration(labelText: 'Enter text')),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                    onPressed: () async {
                      await writeData(controller.text);
                      controller.clear();
                    },
                    child: Text('Write')),
                ElevatedButton(onPressed: readData, child: Text('Read')),
              ],
            ),
            SizedBox(height: 20),
            Text(content, style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
