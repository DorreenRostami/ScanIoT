import 'dart:io';

import 'package:flutter/material.dart';
import 'device.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

const String ipAddress = "http://192.168.196.159:5000";

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
  List<Device> savedDevices = [];
  List<bool> selectedDevices = [];
  String didSomething = "";

  Future<void> showSavedDevices() async {
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
            savedDevices = (data["records"] as List)
                .map((deviceJson) => Device.savedFromJson(deviceJson))
                .toList();
          });
        } else {
          print(
              'Failed to show saved devices. Status code: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('Error showing saved devices: $e');
    }
  }

  Future<void> scanDevices() async {
    didSomething = "";
    savedDevices = [];
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
          print('Failed to scan devices. Status code: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('Error scanning devices: $e');
    }
  }

  File? selectedImage; // Holds the selected image file
  String selectedFileName = "No file chosen"; // Default file text

  Future<void> showUpdateAndSaveDialogue(
      BuildContext context, String ip, String mac) async {
    TextEditingController nameController = TextEditingController();
    TextEditingController descriptionController = TextEditingController();

    File? dialogSelectedImage;
    String dialogSelectedFileName = "No file chosen";

    // Method to open the camera and capture an image
    Future<void> openCamera(StateSetter dialogSetState) async {
      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(source: ImageSource.camera);

      if (photo != null) {
        dialogSetState(() {
          dialogSelectedImage = File(photo.path); // Update dialog state
          dialogSelectedFileName = photo.name; // Update file name
        });
      }
    }

    // Method to show the file upload dialog
    void showImageUploadDialog(StateSetter dialogSetState) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Upload Image'),
            content: const Text('Choose an option:'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context); // Close the dialog
                  await openCamera(dialogSetState); // Open the camera
                },
                child: const Text('Take Picture'),
              ),
            ],
          );
        },
      );
    }

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter dialogSetState) {
            return AlertDialog(
              title: const Text('Update Device'),
              content: SingleChildScrollView(
                child: Column(
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
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            dialogSelectedFileName,
                            style: const TextStyle(
                                fontSize: 14, color: Colors.grey),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () =>
                              showImageUploadDialog(dialogSetState),
                          child: const Text('Choose File'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    dialogSelectedImage != null
                        ? Image.file(
                            dialogSelectedImage!,
                            height: 150,
                            width: 150,
                            fit: BoxFit.cover,
                          )
                        : const Text('No image selected.'),
                  ],
                ),
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
                        // Create a request with an optional image file
                        final request =
                            http.MultipartRequest('POST', Uri.parse(url))
                              ..headers["Content-Type"] = "application/json"
                              ..fields['ip'] = ip
                              ..fields['mac'] = mac
                              ..fields['device_name'] = nameController.text
                              ..fields['device_description'] =
                                  descriptionController.text;

                        if (dialogSelectedImage != null) {
                          request.files.add(await http.MultipartFile.fromPath(
                            'device_image',
                            dialogSelectedImage!.path,
                          ));
                        }

                        final response = await request.send();
                        if (response.statusCode == 302) {
                          setState(() {
                            scannedDevices = [];
                            savedDevices = [];
                            didSomething = "Device Updated Successfully";
                          });
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
                    Navigator.of(context).pop(); // Close the dialog
                  },
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      // Reset state after dialog is closed
      setState(() {
        selectedImage = null;
        selectedFileName = "No file chosen";
      });
    });
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
                      savedDevices = [];
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
                      onPressed: showSavedDevices,
                      child: const Text('Saved Devices')),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: savedDevices.isNotEmpty
                    ? ListView.builder(
                        itemCount: savedDevices.length,
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
                                        selectedDevices[index] = value ?? false;
                                      });
                                    },
                                  ),
                                  Expanded(
                                    child: Text(
                                      "Device Name: ${savedDevices[index].displayName.isEmpty ? 'Unknown' : savedDevices[index].displayName}",
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text("MAC: ${savedDevices[index].mac}"),
                                        Text(
                                            "IPv4: ${savedDevices[index].ipv4}"),
                                        Text(
                                            "IPv6: ${savedDevices[index].ipv6}"),
                                        Text(
                                          "Description: ${savedDevices[index].description.isEmpty ? 'No description' : savedDevices[index].description}",
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
                                            'mac': savedDevices[index].mac,
                                          }),
                                        );

                                        if (response.statusCode == 200) {
                                          setState(() {
                                            savedDevices = [];
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
                                  ElevatedButton(
                                    onPressed: () async {
                                      await showCaptureDialogue(
                                        context,
                                        [savedDevices[index].mac],
                                      );
                                    },
                                    child: const Text('Capture'),
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
                                  title: Text(
                                    "Device Name: ${scannedDevices[index].displayName.isEmpty ? 'Unknown' : scannedDevices[index].displayName}",
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
                                              await showUpdateAndSaveDialogue(
                                                context,
                                                scannedDevices[index].ipv4,
                                                scannedDevices[index].mac,
                                              );
                                            },
                                            child: const Text('Update'),
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
              if (savedDevices.isNotEmpty)
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
