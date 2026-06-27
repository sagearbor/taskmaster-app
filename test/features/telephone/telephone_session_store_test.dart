import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskcaster_app/features/telephone/data/datasources/telephone_session_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TelephoneSessionStore store;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    store = TelephoneSessionStore();
  });

  test('load returns null when nothing has been saved', () async {
    expect(await store.load(), isNull);
  });

  test('save then load round-trips the host identity (host stays host)',
      () async {
    const saved = SavedTelephoneSession(
      sessionId: 'sess-1',
      playerId: 'host-1',
      isHost: true,
      sessionCode: 'ABC123',
      displayName: 'Sage',
    );
    await store.save(saved);

    final loaded = await store.load();
    expect(loaded, isNotNull);
    expect(loaded!.sessionId, 'sess-1');
    expect(loaded.playerId, 'host-1');
    expect(loaded.isHost, isTrue);
    expect(loaded.sessionCode, 'ABC123');
    expect(loaded.displayName, 'Sage');
  });

  test('save replaces any previous active session', () async {
    await store.save(const SavedTelephoneSession(
      sessionId: 'sess-1',
      playerId: 'p1',
      isHost: true,
      sessionCode: 'AAA111',
      displayName: 'Sage',
    ));
    await store.save(const SavedTelephoneSession(
      sessionId: 'sess-2',
      playerId: 'p2',
      isHost: false,
      sessionCode: 'BBB222',
      displayName: 'Robin',
    ));

    final loaded = await store.load();
    expect(loaded!.sessionId, 'sess-2');
    expect(loaded.isHost, isFalse);
  });

  test('clear forgets the saved session', () async {
    await store.save(const SavedTelephoneSession(
      sessionId: 'sess-1',
      playerId: 'p1',
      isHost: true,
      sessionCode: 'AAA111',
      displayName: 'Sage',
    ));
    await store.clear();
    expect(await store.load(), isNull);
  });

  test('clearIfSession only clears when the id matches', () async {
    await store.save(const SavedTelephoneSession(
      sessionId: 'sess-1',
      playerId: 'p1',
      isHost: true,
      sessionCode: 'AAA111',
      displayName: 'Sage',
    ));

    // Different session: must NOT clear the active one.
    await store.clearIfSession('other-sess');
    expect(await store.load(), isNotNull);

    // Matching session: clears.
    await store.clearIfSession('sess-1');
    expect(await store.load(), isNull);
  });
}
