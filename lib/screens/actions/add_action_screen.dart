import 'package:flutter/material.dart';

class AddActionScreen extends StatelessWidget {
  final int sdgId;

  const AddActionScreen({
    Key? key,
    required this.sdgId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) => Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Add New Action'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 200,
                height: 100,
                color: Colors.red,
                child: const Center(
                  child: Text(
                    'ULTRA BASIC TEST',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('SDG ID: $sdgId'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Save Test Action'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
