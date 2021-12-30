import 'package:flutter/material.dart';
import 'package:investor_pro/pages/home/form_10k.dart';
import 'package:investor_pro/pages/home/form_10q.dart';
import 'package:investor_pro/pages/home/form_4.dart';

class Home extends StatelessWidget {
  const Home({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Investor Pro'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(8),
        children: [
          ElevatedButton(
            child: const Text('Form 4'),
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const Form4()));
            },
          ),
          ElevatedButton(
            child: const Text('Form 10K'),
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const Form10K()));
            },
          ),
          ElevatedButton(
            child: const Text('Form 10Q'),
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const Form10Q()));
            },
          ),
        ],
      ),
    );
  }
}
