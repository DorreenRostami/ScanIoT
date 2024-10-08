class Device {
  final String mac;
  final List<String> ipv4;
  final List<String> ipv6;
  final String displayName;
  final String description;

  Device({
    required this.mac,
    this.ipv4 = const [],
    this.ipv6 = const [],
    this.displayName = "",
    this.description = "",
  });

  factory Device.refreshFromJson(List<dynamic> json) {
    return Device(
      ipv4: [json[1]], // The second item is the IP address
      mac: json[2], // The third item is the MAC address
      displayName: json[3], // The fourth item is the display name
      description: json[4], // The fifth item is the type (e.g., Home, Personal)
    );
  }

  // factory Device.scanFromJson(List<dynamic> json) {
  //   return Device(
  //     mac: json[2], // The third item is the MAC address
  //     ipv4: json[1] != null ? [json[1]] : [], // The second item is the IPv4 address, if available
  //     ipv6: json.length > 3 ? json[3] : [], // Extract the IPv6 addresses if they exist
  //     displayName: json.length > 4 ? json[4] : "", // The fifth item is the display name (if present)
  //     description: json.length > 5 ? json[5] : "", // Assuming description is in the 6th position
  //   );
  // }

  factory Device.scanFromJson(Map<String, dynamic> json) {
    return Device(
      mac: json['mac'], // The MAC address is always present
      ipv4: List<String>.from(json['ips']['IPv4']), // Extract the list of IPv4 addresses
      ipv6: List<String>.from(json['ips']['IPv6']), // Extract the list of IPv6 addresses
      displayName: json['display_name'] ?? "", // Handle null display name, default to empty string
      description: "", // Assuming no description in the JSON
    );
  }
}