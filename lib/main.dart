import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:inventory_management/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(InventoryApp());
}

class InventoryApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inventory Management App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: InventoryHomePage(title: 'Inventory Home Page'),
    );
  }
}

class InventoryHomePage extends StatefulWidget {
  InventoryHomePage({Key? key, required this.title}) : super(key: key);
  final String title;
  @override
  _InventoryHomePageState createState() => _InventoryHomePageState();
}

class _InventoryHomePageState extends State<InventoryHomePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _showItemDialog({String? id, String? name, int? quantity}) {
    TextEditingController nameController = TextEditingController(text: name);
    TextEditingController quantityController =
        TextEditingController(text: quantity?.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(id == null ? 'Add Item' : 'Edit Item'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Item Name'),
              ),
              TextField(
                controller: quantityController,
                decoration: InputDecoration(labelText: 'Quantity'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty && quantityController.text.isNotEmpty) {
                  int? quantity = int.tryParse(quantityController.text);
                  if (quantity != null) {
                    if (id == null) {
                      _addItem(nameController.text, quantity);
                    } else {
                      _updateItem(id, nameController.text, quantity);
                    }
                    Navigator.pop(context);
                  }
                }
              },
              child: Text(id == null ? 'Add' : 'Update'),
            ),
          ],
        );
      },
    );
  }

  void _addItem(String name, int quantity) async {
    await _firestore.collection('items').add({
      'name': name,
      'quantity': quantity,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  void _updateItem(String id, String name, int quantity) async {
    await _firestore.collection('items').doc(id).update({
      'name': name,
      'quantity': quantity,
    });
  }

  void _deleteItem(String id) async {
    await _firestore.collection('items').doc(id).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: StreamBuilder(
        stream: _firestore.collection('items').orderBy('timestamp').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          var items = snapshot.data!.docs;

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              var item = items[index];
              return ListTile(
                title: Text(item['name']),
                subtitle: Text('Quantity: ${item['quantity']}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _showItemDialog(
                        id: item.id,
                        name: item['name'],
                        quantity: item['quantity'],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteItem(item.id),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showItemDialog(),
        tooltip: 'Add Item',
        child: Icon(Icons.add),
      ),
    );
  }
}
