import '../../../telephone/data/datasources/nearby_telephone_transport.dart'
    show NearbyDevice;

export '../../../telephone/data/datasources/nearby_telephone_transport.dart'
    show NearbyDevice;

/// The offline message bus Balloon Blitz needs, expressed as an interface so the
/// host-authoritative logic can be unit-tested against a fake. The real
/// implementation ([NearbyBlitzTransport]) is the same framed Google Nearby
/// Connections transport the Telephone game uses; tests swap in an in-memory
/// fake that records broadcasts and lets them inject inbound messages.
abstract class BlitzTransport {
  /// A fully-reassembled JSON message arrived from [endpointId].
  set onMessage(
      void Function(String endpointId, Map<String, dynamic> message)? cb);

  /// An endpoint finished its connection handshake.
  set onEndpointConnected(void Function(String endpointId)? cb);

  /// An endpoint dropped.
  set onEndpointDisconnected(void Function(String endpointId)? cb);

  /// Live list of advertisers found while discovering (peer side).
  Stream<List<NearbyDevice>> get discoveredDevices;

  /// Endpoints we currently have an open channel to.
  Set<String> get connectedEndpoints;

  /// HOST: start advertising so peers can find this race.
  Future<bool> startAdvertising(String advertisedName);

  /// PEER: start scanning for hosts.
  Future<bool> startDiscovery(String selfName);

  /// PEER: request a connection to a discovered host.
  Future<bool> connect(String endpointId);

  /// Send one JSON message to a single endpoint.
  Future<void> sendToEndpoint(String endpointId, Map<String, dynamic> message);

  /// Send one JSON message to every connected endpoint (host → all peers).
  Future<void> broadcast(Map<String, dynamic> message);

  /// Tear down advertising/discovery/connections.
  Future<void> dispose();
}
