import 'dart:io';
import 'package:flutter/material.dart';
import 'device.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:async';
import 'package:path_provider/path_provider.dart';


String ipAddress = "http://192.168.40.159:5000";

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
        '/dashboard': (context) => Dashboard(),
      },
    );
  }
}

/// Login Page
class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

/// Login Page State
class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _ipAddressController = TextEditingController(text: ipAddress);
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
                controller: _ipAddressController,
                decoration: InputDecoration(labelText: 'Server IP Address'),
                onChanged: (value) {
                  setState(() {
                    ipAddress = value;
                  });
                },
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter the IP address';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
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
                  // Navigator.pushNamed(context, '/dashboard',
                  //     arguments: "admin");
                  // return;
                  if (_formKey.currentState!.validate()) {
                    String username = _usernameController.text;
                    String password = _passwordController.text;
                    var url = Uri.parse('$ipAddress/login');
                    try {
                      var response = await http.post(url,
                          body: {'username': username, 'password': password});
                      if (response.statusCode == 302) {
                        setState(() {
                          _errorMessage = '';
                        });
                        Navigator.pushNamed(context, '/dashboard',
                            arguments: username);
                      } else {
                        setState(() {
                          _errorMessage = 'Invalid username or password';
                        });
                      }
                    } on SocketException {
                      setState(() {
                        _errorMessage = 'Network unreachable. Please check the IP address.';
                      });
                    } catch (e) {
                      setState(() {
                        _errorMessage = 'An error occurred';
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
            ],
          ),
        ),
      ),
    );
  }
}


/// Dashboard
class Dashboard extends StatefulWidget {
  @override
  _DashboardState createState() => _DashboardState();
}


/// Dashboard State
class _DashboardState extends State<Dashboard> {
  List<Device> scannedDevices = [];
  List<Device> savedDevices = [];
  List<bool> selectedDevices = [];
  List<Device> capturedDevices = [];
  String didSomething = "";
  Timer? _updateTimer;


  /// Scan for devices connected to the network
  Future<void> scanDevices() async {
    _stopUpdateTimer();
    didSomething = "";
    savedDevices = [];
    capturedDevices = [];
    var url = '$ipAddress/dashboard';
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
        },
      );

      print("-----------------");
      print(response.statusCode);
      print(response.body);
      print("------------------");

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data["connected_devices"] != null &&
            data["connected_devices"] is List) {
          setState(() {
            scannedDevices = (data["connected_devices"] as List)
                .map((deviceJson) => Device.scanFromJson(deviceJson))
                .toList();
          });
        } else {
          print('Failed to scan devices. Status code: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('Error scanning devices: $e');
    }
  }

  /// Get list of saved devices
  Future<void> getSavedDevices() async {
    _stopUpdateTimer();
    didSomething = "";
    scannedDevices = [];
    capturedDevices = [];
    var url = '$ipAddress/refresh';
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data["records"] != null && data["records"] is List) {
          setState(() {
            savedDevices = (data["records"] as List)
                .map((deviceJson) => Device.savedFromJson(deviceJson))
                .toList();
            selectedDevices = List<bool>.filled(savedDevices.length, false);
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

  /// Get list of devices that packets are being/have been captured for
  Future<void> getCapturedDevices() async {
    didSomething = "";
    savedDevices = [];
    scannedDevices = [];

    // setState(() {
    // capturedDevices = [
    //   Device(
    //     mac: '00:14:22:01:23:45',
    //     displayName: 'Pixel 4a',
    //     progressedPackets: 105,
    //     totalPackets: 900,
    //   ),
    //   Device(
    //     mac: '00:14:22:01:23:46',
    //     displayName: 'MacBook Pro',
    //     progressedPackets: 1200,
    //     totalPackets: 2000,
    //   ),
    //   Device(
    //     mac: '00:14:22:01:23:47',
    //     displayName: 'Dor\'s Samsung',
    //     progressedPackets: 2700,
    //     totalPackets: 2700,
    //   ),
    // ];
    // });
    // return;

    var url = '$ipAddress/get_progress';
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data["progress"] != null && data["progress"] is List) {
          setState(() {
            capturedDevices = (data["progress"] as List)
                .map((deviceJson) => Device.capturedFromJson(deviceJson))
                .toList();
          });
        } else {
          print('Invalid progress data format.');
        }
      } else {
        print('Failed to fetch captured devices. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching captured devices: $e');
    }
  }

  /// Start timer which will update the captured devices list every 15 sec
  void startCapturedDevicesUpdate() {
    _stopUpdateTimer();
    _updateTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      getCapturedDevices();
    });
    getCapturedDevices();
  }

  /// Method to stop the timer
  void _stopUpdateTimer() {
    if (_updateTimer != null) {
      _updateTimer!.cancel();
      _updateTimer = null;
    }
  }

  /// Ensure timer is canceled when the widget is disposed
  @override
  void dispose() {
    _stopUpdateTimer();
    super.dispose();
  }


  File? selectedImage; // Holds the selected image file
  String selectedFileName = "No file chosen"; // Default file name text

  /// Dialog for updating device name, description, and image
  Future<void> showUpdateAndSaveDialog(
      BuildContext context, Device device) async {
    String ip = device.ipv4;
    String mac = device.mac;
    TextEditingController nameController = TextEditingController(text: device.displayName);
    TextEditingController descriptionController = TextEditingController(text: device.description);

    File? dialogSelectedImage;
    String dialogSelectedFileName = "No file chosen";
    bool newImage = false;

    // Check if the image file exists in the application documents directory
    final directory = await getApplicationDocumentsDirectory();
    final String imagePath = '${directory.path}/device_photo_$mac.jpg';
    if (File(imagePath).existsSync()) {
      dialogSelectedImage = File(imagePath);
      dialogSelectedFileName = 'device_photo_$mac.jpg';
    }

    //open the camera and capture an image
    Future<void> openCamera(StateSetter dialogSetState) async {
      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(source: ImageSource.camera);

      if (photo != null) {
        dialogSetState(() {
          dialogSelectedImage = File(photo.path);
          dialogSelectedFileName = "device_photo_$mac";
          newImage = true;
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
                          child: const Text('Add Picture'),
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
                    if (nameController.text.isEmpty) {
                      showDialog<void>(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Error'),
                            content: const Text('The name field is required!'),
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

                        if (newImage == true) {
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

                          if (newImage == true) {
                            final directory = await getApplicationDocumentsDirectory();
                            final String filePath = '${directory.path}/device_photo_$mac.jpg';
                            await dialogSelectedImage!.copy(filePath);
                            print('Image saved successfully at $filePath');
                          }
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

  /// Dialog for capturing packets (enter file name and number of packets)
  Future<void> showCaptureDialog(
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
                    requestBody['filename'] = fileNameController.text;
                    requestBody['packets'] = numberController.text;

                    http.post(
                      Uri.parse(url),
                      headers: {
                        "Content-Type": "application/json",
                      },
                      body: jsonEncode(requestBody),
                    );

                    Navigator.of(context).pop();
                    Future.delayed(const Duration(seconds: 1), () {
                      startCapturedDevicesUpdate();
                    });
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

  /// Stop packet capture when stop button is pressed
  void stopCaptureForDevice(Device device) async {
    String url = '$ipAddress/stop_capture';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"mac": device.mac}),
      );

      if (response.statusCode == 200) {
        print('Capture stopped successfully for device: ${device.mac}');
        startCapturedDevicesUpdate();
      } else {
        print('Failed to stop capture. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error while stopping capture: $e');
    }
  }


  /// Build the dashboard widgets
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
                      onPressed: scanDevices,
                      child: const Text('Scan')),
                  ElevatedButton(
                      onPressed: getSavedDevices,
                      child: const Text('Saved Devices')),
                  ElevatedButton(
                      onPressed: startCapturedDevicesUpdate,
                      child: const Text('Captured Packets')),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(child: _buildDeviceList()), //selects what list to show
              const SizedBox(height: 10),
              if (savedDevices.isNotEmpty)
                ElevatedButton(
                  onPressed: () async {
                    List<String> selectedMacAddresses = [];
                    for (int i = 0; i < savedDevices.length; i++) {
                      if (selectedDevices[i]) {
                        selectedMacAddresses.add(savedDevices[i].mac);
                      }
                    }
                    if (selectedMacAddresses.isNotEmpty) {
                      await showCaptureDialog(context, selectedMacAddresses);
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

  // select which list to show in the dashboard
  Widget _buildDeviceList() {
    if (savedDevices.isNotEmpty) {
      return _buildSavedDevicesList();
    } else if (scannedDevices.isNotEmpty) {
      return _buildScannedDevicesList();
    } else if (capturedDevices.isNotEmpty) {
      return _buildCapturedDevicesList();
    } else if (didSomething.isNotEmpty) {
      return Center(child: Text(didSomething, style: const TextStyle(color: Colors.green)));
    } else {
      return const Center(child: Text('No devices to show'));
    }
  }

  Widget _buildScannedDevicesList() {
    return ListView.builder(
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
                Text("MAC Address: ${scannedDevices[index].mac}"),
                Text("Vendor: ${scannedDevices[index].vendor}"),
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
                        await showUpdateAndSaveDialog(
                          context,
                          scannedDevices[index]
                        );
                      },
                      child: const Text('Update & Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSavedDevicesList() {
    return ListView.builder(
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
                    await showCaptureDialog(
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
    );
  }

  Widget _buildCapturedDevicesList() {
    return ListView.builder(
      itemCount: capturedDevices.length,
      itemBuilder: (context, index) {
        final device = capturedDevices[index];

        final int captured = device.progressedPackets;
        final int total = device.totalPackets > 0 ? device.totalPackets : 1;
        final double progress = (captured / total).clamp(0.0, 1.0);
        final int percentage = (progress * 100).toInt();

        return Card(
          margin: const EdgeInsets.all(8),
          child: ListTile(
            title: Text(
              "Device Name: ${device.displayName.isEmpty ? 'Unknown' : device.displayName}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Captured Packets: $captured / ${device.totalPackets}",
                          ),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: progress,
                            minHeight: 8,
                            backgroundColor: Colors.grey[300],
                            color: Colors.blue,
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 16.0),
                      child: Text(
                        "$percentage%",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: progress >= 1.0
                        ? null // Disable the button if progress is 100%
                        : () {
                      stopCaptureForDevice(device);
                    },
                    child: const Text("Stop"),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
