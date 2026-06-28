import '../../../telephone/data/datasources/nearby_telephone_transport.dart';
import 'blitz_transport.dart';

/// App-unique Nearby service id for Balloon Blitz. Distinct from the Telephone
/// id so the two offline games never discover each other, but identical on a
/// Blitz host and every Blitz peer so a family only finds *their* race.
const String kBlitzNearbyServiceId = 'com.sagearbor.taskcaster.balloonblitz';

/// The real offline transport: the exact framed Google Nearby Connections bus
/// the Telephone game uses (Bluetooth + Wi-Fi Direct, no internet), pointed at
/// the Balloon Blitz service id. Subclassing reuses all of the chunking,
/// reassembly, discovery and auto-accept handshake code unchanged.
///
/// DEVICE-ONLY: the underlying radio work runs only on physical Android phones;
/// off-device every method short-circuits (see [NearbyTelephoneTransport]).
class NearbyBlitzTransport extends NearbyTelephoneTransport
    implements BlitzTransport {
  NearbyBlitzTransport() : super(serviceId: kBlitzNearbyServiceId);
}
