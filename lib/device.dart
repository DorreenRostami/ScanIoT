class Device {
  final String mac;
  final String ipv4;
  final String ipv6;
  final String displayName;
  final String description;

  Device({
    required this.mac,
    this.ipv4 = "",
    this.ipv6 = "",
    this.displayName = "",
    this.description = "",
  });

  factory Device.savedFromJson(List<dynamic> json) {
    return Device(
      ipv4: json[1],
      mac: json[2],
      displayName: json[3],
      description: json[4],
    );
  }

  factory Device.scanFromJson(Map<String, dynamic> json) {
    return Device(
      mac: json['mac'],
      ipv4: (json['ips']['IPv4'] as List<dynamic>).isNotEmpty
          ? json['ips']['IPv4'][0] as String
          : "",
      ipv6: (json['ips']['IPv6'] as List<dynamic>).isNotEmpty
          ? json['ips']['IPv6'][0] as String
          : "",
      displayName: json['display_name'] ?? "",
      description: "",
    );
  }
}
