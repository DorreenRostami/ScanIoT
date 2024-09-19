import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(84, 30, 30, 176),
          title: const Text('HomeGuard'),
        ),
        body: Center(
            child: ElevatedButton(onPressed: () {}, child: Text('Login'))),
        bottomNavigationBar: BottomNavigationBar(items: const [
          BottomNavigationBarItem(label: 'Login', icon: Icon(Icons.login)),
          BottomNavigationBarItem(
              label: 'Signup', icon: Icon(Icons.app_registration))
        ]),
      ),
    );
  }
}
