import 'package:flutter_test/flutter_test.dart';
import 'package:taskcaster_app/core/services/notification_service.dart';

void main() {
  group('MockNotificationService', () {
    late NotificationService service;

    setUp(() => service = MockNotificationService());
    tearDown(() => service.dispose());

    test('initialize completes without throwing', () async {
      await expectLater(service.initialize(), completes);
    });

    test('requestPermission returns true', () async {
      expect(await service.requestPermission(), isTrue);
    });

    test('getToken returns a non-null token', () async {
      expect(await service.getToken(), isNotNull);
    });
  });
}
