import 'package:flutter/material.dart';
import 'device.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(HomeGuardApp());
}

class HomeGuardApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HomeGuard',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => LoginPage(),
        // '/signup': (context) => SignUpPage(),
        '/dashboard': (context) => Dashboard(),
      },
    );
  }
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController _usernameController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  String _errorMessage = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(84, 30, 30, 176),
        title: const Text('Login'),
      ),
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(labelText: 'Username'),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter your username';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter your password';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    String username = _usernameController.text;
                    String password = _passwordController.text;
                    var url = Uri.parse('http://192.168.209.159:5000/login');
                    var response = await http.post(url,
                        body: {'username': username, 'password': password});
                    if (response.statusCode != 401) {
                      Navigator.pushNamed(context, '/dashboard',
                          arguments: username);
                    } else {
                      setState(() {
                        _errorMessage = 'Invalid username or password';
                      });
                    }
                  }
                },
                child: const Text('Login'),
              ),
              SizedBox(height: 10),
              Text(
                _errorMessage,
                style: TextStyle(color: Colors.red),
              ),
              SizedBox(height: 10),
              // Row(
              //   mainAxisAlignment: MainAxisAlignment.center,
              //   children: [
              //     const Text("Don't have an account? "),
              //     GestureDetector(
              //       onTap: () {
              //         Navigator.pushNamed(context, '/signup');
              //       },
              //       child: const Text(
              //         'Sign Up',
              //         style: TextStyle(
              //             fontWeight: FontWeight.bold, color: Colors.blue),
              //       ),
              //     ),
              //   ],
              // ),
            ],
          ),
        ),
      ),
    );
  }
}

// class SignUpPage extends StatefulWidget {
//   @override
//   _SignUpPageState createState() => _SignUpPageState();
// }
//
// class _SignUpPageState extends State<SignUpPage> {
//   final _formKey = GlobalKey<FormState>();
//   TextEditingController _usernameController = TextEditingController();
//   TextEditingController _passwordController = TextEditingController();
//   String _errorMessage = '';
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: const Color.fromARGB(84, 30, 30, 176),
//         title: const Text('Sign Up'),
//       ),
//       body: Padding(
//         padding: EdgeInsets.all(20.0),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: <Widget>[
//               TextFormField(
//                 controller: _usernameController,
//                 decoration: InputDecoration(labelText: 'Username'),
//                 validator: (value) {
//                   if (value!.isEmpty) {
//                     return 'Please enter your username';
//                   } else if (Database.isExistingUser(value)) {
//                     return 'Username already exists';
//                   }
//                   return null;
//                 },
//               ),
//               SizedBox(height: 20),
//               TextFormField(
//                 controller: _passwordController,
//                 decoration: InputDecoration(labelText: 'Password'),
//                 obscureText: true,
//                 validator: (value) {
//                   if (value!.isEmpty) {
//                     return 'Please enter your password';
//                   }
//                   return null;
//                 },
//               ),
//               SizedBox(height: 20),
//               ElevatedButton(
//                 onPressed: () {
//                   if (_formKey.currentState!.validate()) {
//                     String username = _usernameController.text;
//                     String password = _passwordController.text;
//                     Database.addUser(username, password);
//                     Navigator.pop(context);
//                   }
//                 },
//                 child: Text('Sign Up'),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

class Dashboard extends StatefulWidget {
  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  List<Device> scannedDevices = [];
  List<Device> refreshedDevices = [];

  Future<void> refreshDevices() async {
    scannedDevices = [];
    var url = 'http://192.168.209.159:5000/refresh';
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        print(response.body);
        var data = jsonDecode(response.body);
        if (data["records"] != null && data["records"] is List) {
          setState(() {
            refreshedDevices = (data["records"] as List)
                .map((deviceJson) => Device.refreshFromJson(deviceJson))
                .toList();
          });
        } else {
          print(
              'Failed to refresh devices. Status code: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('Error refreshing devices: $e');
    }
  }

  Future<void> scanDevices() async {
    refreshedDevices = [];
    var url = 'http://192.168.209.159:5000/dashboard';
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        print(response.body);
        var data = jsonDecode(response.body);
        if (data["connected_devices"] != null &&
            data["connected_devices"] is List) {
          setState(() {
            // Parsing the records into a list of Device objects
            scannedDevices = (data["connected_devices"] as List)
                .map((deviceJson) => Device.scanFromJson(deviceJson))
                .toList();
          });
        } else {
          print(
              'Failed to refresh devices. Status code: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('Error refreshing devices: $e');
    }
  }

  Future<void> showEditDialogue(BuildContext context) async {
    TextEditingController nameController = TextEditingController();
    TextEditingController descriptionController = TextEditingController();

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Device'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Device Display Name',
                ),
              ),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Device Description',
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                // Close the dialog and print the entered values
                Navigator.of(context).pop();
                // Print the values after a short delay
                Future.delayed(Duration(milliseconds: 500), () {
                  print("Device Name: ${nameController.text}");
                  print("Device Description: ${descriptionController.text}");
                });
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // var url = 'http://192.168.209.159:5000/refresh';
  // try {
  //   final response = await http.post(
  //     Uri.parse(url),
  //     headers: {
  //       "Content-Type": "application/json",
  //     },
  //     body: {'display_name': displayName, 'description': description}
  //   );

  //   if (response.statusCode == 200) {
  //     print(response.body);
  //     var data = jsonDecode(response.body);
  //     if (data["records"] != null && data["records"] is List) {
  //       setState(() {
  //         // Parsing the records into a list of Device objects
  //         refreshedDevices = (data["records"] as List)
  //             .map((deviceJson) => Device.refreshFromJson(deviceJson))
  //             .toList();
  //       });
  //     } else {
  //       print(
  //           'Failed to refresh devices. Status code: ${response.statusCode}');
  //     }
  //   }
  // } catch (e) {
  //   print('Error refreshing devices: $e');
  // }

  @override
  Widget build(BuildContext context) {
    final String username =
        ModalRoute.of(context)!.settings.arguments as String;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color.fromARGB(84, 30, 30, 176),
        title: const Text('Dashboard'),
      ),
      body: Center(
        child: Container(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              const SizedBox(height: 20),
              Text(
                'Welcome, $username!',
                style: TextStyle(fontSize: 20),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                      onPressed: scanDevices, child: const Text('Scan')),
                  ElevatedButton(
                      onPressed: refreshDevices, child: const Text('Refresh')),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: refreshedDevices.isNotEmpty
                    ? ListView.builder(
                        itemCount: refreshedDevices.length,
                        itemBuilder: (context, index) {
                          return Card(
                            margin: EdgeInsets.all(8),
                            child: ListTile(
                              title: Text(
                                  "Device Name: ${refreshedDevices[index].displayName.isEmpty ? 'Unknown' : refreshedDevices[index].displayName}"),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("MAC: ${refreshedDevices[index].mac}"),
                                  Text(
                                      "IPv4: ${refreshedDevices[index].ipv4.join(', ')}"),
                                  Text(
                                      "IPv6: ${refreshedDevices[index].ipv6.join(', ')}"),
                                  Text(
                                      "Description: ${refreshedDevices[index].description.isEmpty ? 'No description' : refreshedDevices[index].description}"),
                                ],
                              ),
                            ),
                          );
                        },
                      )
                    : scannedDevices.isNotEmpty
                        ? ListView.builder(
                            itemCount: scannedDevices.length,
                            itemBuilder: (context, index) {
                              return Card(
                                margin: EdgeInsets.all(8),
                                child: ListTile(
                                  title: Text(
                                      "Device Name: ${scannedDevices[index].displayName.isEmpty ? 'Unknown' : scannedDevices[index].displayName}"),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text("MAC: ${scannedDevices[index].mac}"),
                                      const Text("IP Addresses:"),
                                      Text(
                                          " • IPv4: ${scannedDevices[index].ipv4.join(', ')}"),
                                      Text(
                                          " • IPv6: ${scannedDevices[index].ipv6.join(', ')}"),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          ElevatedButton(
                                            onPressed: () async {
                                              // Show the dialog but don't return anything
                                              await showEditDialogue(context);
                                            },
                                            child: const Text('Edit'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () {
                                              // Action for "Capture" button
                                            },
                                            child: const Text('Capture'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          )
                        : const Center(
                            child: Text(
                                'No devices to show')), //both lists are empty
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.popUntil(context, ModalRoute.withName('/login'));
                },
                child: const Text('Logout'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}



// class MyApp extends StatefulWidget {
//   MyApp({Key? key}) : super(key: key);

//   @override
//   State<MyApp> createState() => _MyAppState();
// }

// class _MyAppState extends State<MyApp> {
//   String buttonName = 'Login';
//   int currentIndex = 0;
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
      
//       home: Scaffold(
//         appBar: AppBar(
//           backgroundColor: const Color.fromARGB(84, 30, 30, 176),
//           title: const Text('HomeGuard'),
//         ),
//         body: Center(
//             child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             TextField(
              
//             )
//             ElevatedButton(
//                 onPressed: () {
//                   setState(() {
//                     buttonName = 'clicked';
//                   });
//                 },
//                 child: Text(buttonName))
//           ],
//         )),
//         bottomNavigationBar: BottomNavigationBar(
//           items: const [
//             BottomNavigationBarItem(label: 'Login', icon: Icon(Icons.login)),
//             BottomNavigationBarItem(
//                 label: 'Signup', icon: Icon(Icons.app_registration))
//           ],
//           currentIndex: currentIndex,
//           onTap: (int index) {
//             setState(() {
//               currentIndex = index;
//               if (index == 0) {
//                 buttonName = 'Login';
//               } else {
//                 buttonName = 'Signup';
//               }
//             });
//           },
//         ),
//       ),
//     );
//   }
// }
