import 'package:flutter/material.dart';
import 'device.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';

const String ipAddress = "http://192.168.8.159:5000";

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
                    var url = Uri.parse('$ipAddress/login');
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

class Dashboard extends StatefulWidget {
  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  List<Device> scannedDevices = [];
  List<Device> refreshedDevices = [];
  List<bool> selectedDevices = [];
  String didSomething = "";

  Future<void> refreshDevices() async {
    didSomething = "";
    scannedDevices = [];
    var url = '$ipAddress/refresh';
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
    didSomething = "";
    refreshedDevices = [];
    var url = '$ipAddress/dashboard';
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
            scannedDevices = (data["connected_devices"] as List)
                .map((deviceJson) => Device.scanFromJson(deviceJson))
                .toList();
            selectedDevices = List<bool>.filled(scannedDevices.length, false);
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

  Future<void> showUpdateDialogue(
      BuildContext context, String ip, String mac) async {
    TextEditingController nameController = TextEditingController();
    TextEditingController descriptionController = TextEditingController();

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Update Device'),
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
              onPressed: () async {
                if (nameController.text.isEmpty ||
                    descriptionController.text.isEmpty) {
                  showDialog<void>(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Error'),
                        content: const Text('Both fields are required!'),
                        actions: [
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text('OK'),
                          ),
                        ],
                      );
                    },
                  );
                } else {
                  String url = '$ipAddress/update_device';
                  try {
                    final response = await http.post(
                      Uri.parse(url),
                      headers: {
                        "Content-Type": "application/json",
                      },
                      body: jsonEncode({
                        'ip': ip,
                        'mac': mac,
                        'device_name': nameController.text,
                        'device_description': descriptionController.text,
                      }),
                    );

                    if (response.statusCode == 200) {
                      scannedDevices = [];
                      refreshedDevices = [];
                      didSomething = "Device Updated Successfully";
                    } else {
                      print(
                          'Failed to update device. Status code: ${response.statusCode}');
                    }

                    Navigator.of(context).pop();
                  } catch (e) {
                    print('Error occurred while updating device: $e');
                    Navigator.of(context).pop();
                  }
                }
              },
              child: const Text('Save'),
            ),
            ElevatedButton(
              onPressed: () {
                // Simply close the dialog
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> showCaptureDialogue(
      BuildContext context, List<String> macAddresses) async {
    TextEditingController fileNameController = TextEditingController();
    TextEditingController numberController = TextEditingController();

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Capture PCAP'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: fileNameController,
                decoration: const InputDecoration(
                  labelText: 'File Name',
                ),
              ),
              TextField(
                controller: numberController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly, // Allows only digits
                  FilteringTextInputFormatter.allow(
                      RegExp(r'[1-9][0-9]*')), // Ensures numbers > 0
                ],
                decoration: const InputDecoration(
                  labelText: 'Number of Packets',
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                if (fileNameController.text.isEmpty ||
                    numberController.text.isEmpty) {
                  showDialog<void>(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Error'),
                        content: const Text('Both fields are required!'),
                        actions: [
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text('OK'),
                          ),
                        ],
                      );
                    },
                  );
                } else {
                  String url = '$ipAddress/capture_pcap';
                  try {
                    Map<String, dynamic> requestBody;

                    // Create the JSON body based on the number of MAC addresses
                    if (macAddresses.length == 1) {
                      requestBody = {
                        'mac': macAddresses.first,
                      };
                    } else {
                      requestBody = {
                        'selected_devices': macAddresses,
                      };
                    }

                    // Add additional fields
                    requestBody['filename'] = fileNameController.text;
                    requestBody['packets'] = numberController.text;

                    final response = await http.post(
                      Uri.parse(url),
                      headers: {
                        "Content-Type": "application/json",
                      },
                      body: jsonEncode(requestBody), // Encode the entire map
                    );

                    if (response.statusCode == 200) {
                      scannedDevices = [];
                      refreshedDevices = [];
                      didSomething = "Packets captured succesfully";
                    } else {
                      print('Response: ${response.body}');
                    }

                    Navigator.of(context).pop();
                  } catch (e) {
                    print('Error occurred: $e');
                    Navigator.of(context).pop();
                  }
                }
              },
              child: const Text('Capture'),
            ),
            ElevatedButton(
              onPressed: () {
                // Simply close the dialog
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

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
                style: const TextStyle(fontSize: 20),
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
                              subtitle: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                            "MAC: ${refreshedDevices[index].mac}"),
                                        Text(
                                            "IPv4: ${refreshedDevices[index].ipv4}"),
                                        Text(
                                            "IPv6: ${refreshedDevices[index].ipv6}"),
                                        Text(
                                          "Description: ${refreshedDevices[index].description.isEmpty ? 'No description' : refreshedDevices[index].description}",
                                        ),
                                      ],
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: () async {
                                      String url = '$ipAddress/delete_device';
                                      try {
                                        final response = await http.post(
                                          Uri.parse(url),
                                          headers: {
                                            "Content-Type": "application/json",
                                          },
                                          body: jsonEncode({
                                            'mac': refreshedDevices[index].mac,
                                          }),
                                        );

                                        if (response.statusCode == 200) {
                                          setState(() {
                                            refreshedDevices = [];
                                            didSomething =
                                                "Device deleted successfully";
                                          });
                                        } else {
                                          print('Failed. ${response.body}');
                                        }
                                      } catch (e) {
                                        print('Error: $e');
                                      }
                                    },
                                    child: const Text('Delete'),
                                  ),
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
                                  title: Row(
                                    children: [
                                      Checkbox(
                                        value: selectedDevices[index],
                                        onChanged: (bool? value) {
                                          setState(() {
                                            selectedDevices[index] =
                                                value ?? false;
                                          });
                                        },
                                      ),
                                      Expanded(
                                        child: Text(
                                          "Device Name: ${scannedDevices[index].displayName.isEmpty ? 'Unknown' : scannedDevices[index].displayName}",
                                        ),
                                      ),
                                    ],
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text("MAC: ${scannedDevices[index].mac}"),
                                      const Text("IP Addresses:"),
                                      Text(
                                          " • IPv4: ${scannedDevices[index].ipv4}"),
                                      Text(
                                          " • IPv6: ${scannedDevices[index].ipv6}"),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          ElevatedButton(
                                            onPressed: () async {
                                              // Show the dialog but don't return anything
                                              await showUpdateDialogue(
                                                  context,
                                                  scannedDevices[index].ipv4,
                                                  scannedDevices[index].mac);
                                            },
                                            child: const Text('Update'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () async {
                                              // Show the dialog but don't return anything
                                              await showCaptureDialogue(context,
                                                  [scannedDevices[index].mac]);
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
                        : didSomething != ""
                            ? Center(
                                child: Text(
                                  didSomething,
                                  style: const TextStyle(color: Colors.green),
                                ),
                              )
                            : const Center(
                                child: Text(
                                    'No devices to show')), // both lists are empty
              ),
              const SizedBox(height: 10),
              if (scannedDevices.isNotEmpty)
                ElevatedButton(
                  onPressed: () async {
                    List<String> selectedMacAddresses = [];
                    for (int i = 0; i < scannedDevices.length; i++) {
                      if (selectedDevices[i]) {
                        selectedMacAddresses.add(scannedDevices[i].mac);
                      }
                    }
                    if (selectedMacAddresses.isNotEmpty) {
                      await showCaptureDialogue(context,
                          selectedMacAddresses); // Assuming all devices have the same IP
                    } else {
                      // Handle case where no devices are selected
                      showDialog<void>(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('No devices selected'),
                            content: const Text(
                                'Please select at least one device to capture.'),
                            actions: [
                              ElevatedButton(
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
                  },
                  child: const Text('Capture All'),
                ),
              const SizedBox(height: 10),
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