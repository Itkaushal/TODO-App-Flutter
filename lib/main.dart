import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

void main() async {
  await Hive.openBox('shopping_box');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home:  MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final String title='Crud Using Hive Db';
  List<Map<String, dynamic>> _items = [];

  final _shoppingBox = Hive.box('shopping_box');

  int _nextItemId = 0;

  @override
  void initState() {
    super.initState();
    _refreshItems(); // get all data to when app starts
  }

  void _refreshItems(){
    final data = _shoppingBox.keys.map((key){
      final value = _shoppingBox.get(key);
      return
       {"key": key, "name": value["name"], "quantity": value['quantity']};
    }).toList();

    setState(() {
      _items = data.reversed.toList(); // sort items in order to oldest to latest
    });
  }

  // Create Item
  Future<void> _createItem(Map<String, dynamic> newItem) async{
    await _shoppingBox.put(_nextItemId,newItem);
    _nextItemId++;
    _refreshItems(); // update ui
  }

  // Retrieve single item by its key
  Future<void> _readItem(int key){
    final item = _shoppingBox.get(key);
    return item;
  }

  // Update A Single Item
  Future<void> _updateItem(int itemKey, Map<String, dynamic> item) async{
    await  _shoppingBox.put(itemKey, item);
    _refreshItems();
  }

  // Delete a single Item
  Future<void> _deleteItem(int itemKey) async{
    await _shoppingBox.delete(itemKey);
    _refreshItems();
    
    if( !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('item has been deleted')));
  }

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();

  void _showForm(BuildContext ctx, int? itemKey) async{
    if(itemKey != null){
      final existingItem = _items.firstWhere((element) => element['key'] == itemKey);

      _nameController.text = existingItem['name'] as String;
      _quantityController.text = existingItem['quantity'] as String;
    }
    
    showModalBottomSheet(context: context,
        isScrollControlled: true,
        elevation: 5,
        builder: (_) => Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom,top: 15,left: 15, right: 15),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(hintText: 'Name'),
              ),

              const SizedBox(height: 10,),

              TextField(
                controller: _quantityController,
                decoration: const InputDecoration(hintText: 'Quantity',),
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 10,),

              ElevatedButton(onPressed: ()async{
                // save newItem
                if(itemKey == null){
                  _createItem({
                    "name": _nameController.text,
                    "quantity": _quantityController.text
                  });
                  }else {
                    // Update existing item (Corrected logic)
                    _updateItem(itemKey, {
                      "name": _nameController.text.trim(),
                      "quantity": _quantityController.text.trim(),});
                  }

                  _nameController.text ='';
                  _quantityController.text ='';
                  Navigator.of(context).pop(); //close to bottom sheet
                  
                },
               child: Text(itemKey == null ? 'Create New' : 'Update'),),
              const SizedBox(height: 10,)


            ],
          ),
        )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(title),
      ),
      body: _items.isEmpty ? const Center(
        child: Text('No Data',style: TextStyle(fontSize: 30),),
      ) :  ListView.builder(itemCount: _items.length,
          itemBuilder: (_, index){
        final currentItem = _items[index];
        return Card(
    color: Colors.red.shade100,
    margin: const EdgeInsets.all(10),
    elevation: 3,
    child: ListTile(
    title: Text(currentItem['name'].toString()),
    subtitle: Text(currentItem['quantity'].toString()),
    trailing: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      // Edit Button
      IconButton(onPressed: ()=> _showForm(context,currentItem['key']), icon: const Icon(Icons.edit)),

      // Delete Button
      IconButton(onPressed: ()=> _deleteItem(currentItem['key']), icon: const Icon(Icons.delete))
    ],
    ),
    ),
    );
    }),
    floatingActionButton: FloatingActionButton(onPressed: () => _showForm(context,null),
    child: const Icon(Icons.add),),
    );
  }
}

