import 'package:bilisail/app/workspace_tabs.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  WorkspaceTabs singlePageWorkspace() =>
      WorkspaceTabs()..setSingleMode(true);

  test('retained playback pages never exceed the cap', () {
    final tabs = singlePageWorkspace();
    for (var index = 0; index < 9; index++) {
      tabs.acceptRoute(Uri(path: '/video/BV$index'));
      tabs.enforcePlaybackLimit();
    }
    final playback = tabs.tabs.where((tab) => tab.isPlayback).toList();
    expect(
      playback.length,
      lessThanOrEqualTo(WorkspaceTabs.maximumPlaybackPages),
    );
    // The page the user is looking at is never evicted.
    expect(playback.any((tab) => tab.id == tabs.activeId), isTrue);
  });

  test('the least recently visited playback page is evicted first', () {
    final tabs = singlePageWorkspace();
    for (var index = 0; index < 7; index++) {
      tabs.acceptRoute(Uri(path: '/video/BV$index'));
      tabs.enforcePlaybackLimit();
    }
    final paths = tabs.tabs.map((tab) => tab.location.path).toList();
    expect(paths, isNot(contains('/video/BV0')));
    expect(paths, contains('/video/BV6'));
  });

  test('browsing pages are not touched by the playback cap', () {
    final tabs = singlePageWorkspace();
    tabs.acceptRoute(Uri(path: '/popular'));
    for (var index = 0; index < 8; index++) {
      tabs.acceptRoute(Uri(path: '/video/BV$index'));
      tabs.enforcePlaybackLimit();
    }
    expect(
      tabs.tabs.where((tab) => !tab.isPlayback).map((tab) => tab.location.path),
      contains('/popular'),
    );
  });

  test('nothing is closed while the count is within the cap', () {
    final tabs = singlePageWorkspace();
    for (var index = 0; index < 3; index++) {
      tabs.acceptRoute(Uri(path: '/video/BV$index'));
    }
    expect(tabs.enforcePlaybackLimit(), isFalse);
    expect(
      tabs.tabs.where((tab) => tab.isPlayback).length,
      3,
    );
  });
}
