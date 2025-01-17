class Device {
  final String mac;
  final String ipv4;
  final String ipv6;
  final String displayName;
  final String description;
  final String vendor;
  final int progressedPackets;
  final int totalPackets;

  Device({
    required this.mac,
    this.ipv4 = "",
    this.ipv6 = "",
    this.displayName = "",
    this.description = "",
    this.vendor = "",
    this.progressedPackets = 0,
    this.totalPackets = 0
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
      vendor: json['vendor'],
      description: json['description'] ?? ""
    );
  }

  factory Device.capturedFromJson(Map<String, dynamic> json) {
    return Device(
      displayName: json['display_name'] ?? "",
      mac: json['mac_address'],
      progressedPackets: json['progress'],
      totalPackets: json['total_packets'],
    );
  }

}
