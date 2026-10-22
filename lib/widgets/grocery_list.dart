import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shopping_list/data/categories.dart';
import 'package:shopping_list/models/grocery_item.dart';
import 'package:shopping_list/widgets/new_item.dart';

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});


  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> _groceryItems = [];
  var _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  void _loadItems() async {
    final url = Uri.https(
        'udemy-proj-d7265-default-rtdb.firebaseio.com',
        'shopping-list.json'
        );
    

    try {
      final response = await http.get(url);
        print(response.statusCode); //if statusCode > 400 or 500 then there is an error

    if (response.statusCode >= 400) {
      setState(() {
        _error = 'Failed to load data. Please try again later';
      });
    }
    
    final Map<String, dynamic>listData
     = json.decode(response.body);

     final List<GroceryItem> loadedItems = [];
    for (final item in listData.entries) {
      final category = categories.entries.firstWhere(
        (catItem) => catItem.value.name == item.value['category']
        ).value;

      loadedItems.add(GroceryItem(
        id: item.key, 
        name: item.value['name'], 
        quantity: item.value['quantity'], 
        category: category,
        ),
      );
    }
    setState(() {
      _groceryItems = loadedItems;
      _isLoading = false;
    });
    } catch (error){
      setState(() {
        _error = 'Something went wrong!. Please try again later';
      });
    }
  }

  void _addItem() async{
    final newItem = await Navigator.of(context).push<GroceryItem>(
      MaterialPageRoute(builder: (ctx) => 
      const NewItem(),
      )
    );

    _loadItems();

    if (newItem == null) {
      return;
    }
    setState(() {
      _groceryItems.add(newItem);
    });
  }

  void _onRemoveItem (GroceryItem groceryItem) async{
    final groceryItemIndex = _groceryItems.indexOf(groceryItem);
    
    setState(() {
      _groceryItems.remove(groceryItem);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Item has been removed')
      )
    );

    final url = Uri.https(
        'udemy-proj-d7265-default-rtdb.firebaseio.com',
        'shopping-list/${groceryItem.id}.json'
        );
    final response = await http.delete(url);

    if (response.statusCode >= 400) {
      ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('An occurred when removing an item')
        )
       );
      setState(() {
        _groceryItems.insert(groceryItemIndex, groceryItem);
      });
    }

    if (response.body == 'null'){
      setState(() {
        _isLoading = false;
      });
      return;
    }
    
  }

  @override
  Widget build(BuildContext context) {
    Widget fallBackContent = const Center(
      child: Text('No Items has been added as yet'),
    );

    if (_isLoading){
      fallBackContent = const Center(
        child: CircularProgressIndicator(
          strokeWidth: 8,
          constraints: BoxConstraints.expand(
            width: 90,
            height: 90
          ),
        ),
      );
    }

    if (_groceryItems.isNotEmpty){
      fallBackContent = ListView.builder(
        itemCount: _groceryItems.length,
        itemBuilder: (ctx, index) =>
        Dismissible(
          key: ValueKey(_groceryItems[index].id),
          onDismissed: (direction) {
            _onRemoveItem(_groceryItems[index]);
          },
          child: ListTile(
            title: Text(_groceryItems[index].name),
            leading: Container(
              width: 24,
              height: 24,
              color: _groceryItems[index].category.color,
            ),
            trailing: Text(
              _groceryItems[index].quantity.toString()
            )
          ),
        )
      );
    }

    if (_error != null){
      fallBackContent = Center(
      child: Text(_error!),
    );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Your Groceries By J.L'),
        actions: [
          IconButton(
            onPressed: _addItem, 
            icon: const Icon(Icons.add))
        ],
      ),
      body: fallBackContent
    );
  }
}