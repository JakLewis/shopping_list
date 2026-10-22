import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shopping_list/data/categories.dart';
import 'package:http/http.dart' as http;
import 'package:shopping_list/models/category.dart';
import 'package:shopping_list/models/grocery_item.dart';

class NewItem extends StatefulWidget {
  const NewItem({super.key});

  @override
  State<NewItem> createState() => _NewItemState();
}

class _NewItemState extends State<NewItem> {
  final _formKey = GlobalKey<FormState>();
  var _enteredName = '';
  var _enteredQuanity = 1;
  var _selectedCategory = categories[Categories.carbs]!;
  var _isSending = false;

  void _savedItem() async{
   if (_formKey.currentState!.validate()){
      _formKey.currentState!.save();
      setState(() {
        _isSending = true;
      });
      final url = Uri.https(
        'udemy-proj-d7265-default-rtdb.firebaseio.com',
        'shopping-list.json'
        );
      final response = await http.post(
        url, 
        headers: {
          'Content-Type': 'application/json'
        }, body: json.encode({
              'name': _enteredName, 
              'quantity': _enteredQuanity, 
              'category': _selectedCategory.name
        })
      );

      final Map<String, dynamic> resData = json.decode(response.body);

      if (!context.mounted) {
        return;
      }

      Navigator.of(context).pop(GroceryItem(
        id: resData['name'],
        name: _enteredName,
        quantity: _enteredQuanity, 
        category: _selectedCategory));

        
    //  Navigator.of(context).pop(GroceryItem(
    //   id: DateTime.now().toString(), 
    //   name: _enteredName, 
    //   quantity: _enteredQuanity, 
    //   category: _selectedCategory));
   }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add a new Item'),
      ),
      body: Padding(
        padding: const EdgeInsetsGeometry.all(12),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                maxLength: 50,
                decoration: const InputDecoration(
                  label: Text('Name'),
                ),
                validator: (value) {
                  if(value == null || value.isEmpty || 
                  value.trim().length <= 1
                  || value.trim().length > 50){
                    return 'Must be between 1 and 50 character';
                  }
                  return null;
                },
                onSaved: (value) {
                  _enteredName = value!;
                },
              ), 
              Row(
                // crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: _enteredQuanity.toString(),
                      maxLength: 2,
                      decoration: InputDecoration(
                        label: Text('Quantity'),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                  if(value == null || value.isEmpty || 
                  int.tryParse(value) == null
                  || int.tryParse(value)! <= 0){
                    return 'Must be a positive number';
                  }
                  return null;
                    },
                    onSaved: (value) {
                      _enteredQuanity = int.parse(value!);
                    },
                  ),
                  ),
                  const SizedBox(width: 8,),
                  Expanded(
                    child: DropdownButtonFormField(
                      initialValue: _selectedCategory,
                      items: [
                        for(final category in categories.entries)
                        DropdownMenuItem(
                          value: category.value,
                          child: Row(
                            children: [
                              Container(
                              width: 16,
                              height: 16,
                              color: category.value.color,
                            ),
                            const SizedBox(width: 6,),
                            Text(category.value.name),
                          ]
                        ),
                      ),
                      ], 
                      onChanged: (value){
                        setState(() {
                          _selectedCategory = value!;
                        });
                      }),
                  )
                ],
              ),// instead of Textfield
              const SizedBox(height: 12,),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                TextButton(
                  onPressed: _isSending ? null : (){
                    _formKey.currentState!.reset();
                  }, 
                  child: const Text('Reset')
                ),
                ElevatedButton(
                  onPressed: _isSending ? null :
                   _savedItem, 
                  child: _isSending ? SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(),
                  ) : const Text('Add Item')
                )
              ],)
            ],
          )
        ),
      ),
    );
  }
}