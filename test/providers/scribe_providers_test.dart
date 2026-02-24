// Tests for Scribe providers.
//
// Verifies ScribeTabsNotifier, ScribeSettingsNotifier, and computed providers.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:codeops/models/scribe_diff_models.dart';
import 'package:codeops/models/scribe_models.dart';
import 'package:codeops/providers/scribe_providers.dart';
import 'package:codeops/services/data/scribe_persistence_service.dart';

class MockScribePersistenceService extends Mock
    implements ScribePersistenceService {}

void main() {
  late MockScribePersistenceService mockPersistence;

  setUpAll(() {
    registerFallbackValue(<ScribeTab>[]);
    registerFallbackValue(const ScribeSettings());
  });

  setUp(() {
    mockPersistence = MockScribePersistenceService();
    when(() => mockPersistence.saveTabs(any())).thenAnswer((_) async {});
    when(() => mockPersistence.saveSettings(any())).thenAnswer((_) async {});
    when(() => mockPersistence.loadTabs()).thenAnswer((_) async => []);
    when(() => mockPersistence.loadSettings())
        .thenAnswer((_) async => const ScribeSettings());
    when(() => mockPersistence.saveSessionMetadata(
          activeTabId: any(named: 'activeTabId'),
        )).thenAnswer((_) async {});
  });

  ProviderContainer createContainer() {
    final container = ProviderContainer(
      overrides: [
        scribePersistenceProvider.overrideWithValue(mockPersistence),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('ScribeTabsNotifier', () {
    test('openTab adds a tab', () {
      final container = createContainer();

      container.read(scribeTabsProvider.notifier).openTab(
            title: 'test.dart',
            content: 'void main() {}',
            language: 'dart',
          );

      final tabs = container.read(scribeTabsProvider);
      expect(tabs, hasLength(1));
      expect(tabs.first.title, 'test.dart');
      expect(tabs.first.content, 'void main() {}');
      expect(tabs.first.language, 'dart');
    });

    test('openTab activates duplicate filePath instead of creating new tab',
        () {
      final container = createContainer();

      container.read(scribeTabsProvider.notifier).openTab(
            title: 'file.dart',
            filePath: '/path/to/file.dart',
          );
      final firstId =
          container.read(scribeTabsProvider).first.id;

      container.read(scribeTabsProvider.notifier).openTab(
            title: 'file.dart',
            filePath: '/path/to/file.dart',
          );

      expect(container.read(scribeTabsProvider), hasLength(1));
      expect(container.read(activeScribeTabIdProvider), firstId);
    });

    test('openTab sets new tab as active', () {
      final container = createContainer();

      container.read(scribeTabsProvider.notifier).openTab(title: 'Tab 1');
      container.read(scribeTabsProvider.notifier).openTab(title: 'Tab 2');

      final tabs = container.read(scribeTabsProvider);
      final activeId = container.read(activeScribeTabIdProvider);
      expect(activeId, tabs.last.id);
    });

    test('closeTab removes tab', () {
      final container = createContainer();

      container.read(scribeTabsProvider.notifier).openTab(title: 'Tab 1');
      container.read(scribeTabsProvider.notifier).openTab(title: 'Tab 2');
      final tabToClose = container.read(scribeTabsProvider).first;

      container.read(scribeTabsProvider.notifier).closeTab(tabToClose.id);

      expect(container.read(scribeTabsProvider), hasLength(1));
      expect(container.read(scribeTabsProvider).first.title, 'Tab 2');
    });

    test('closeTab activates adjacent tab when active tab closed', () {
      final container = createContainer();

      container.read(scribeTabsProvider.notifier).openTab(title: 'Tab 1');
      container.read(scribeTabsProvider.notifier).openTab(title: 'Tab 2');
      container.read(scribeTabsProvider.notifier).openTab(title: 'Tab 3');

      final tabs = container.read(scribeTabsProvider);
      // Activate tab 2 (middle).
      container.read(activeScribeTabIdProvider.notifier).state = tabs[1].id;

      // Close tab 2 — should activate tab 3 (next).
      container.read(scribeTabsProvider.notifier).closeTab(tabs[1].id);

      final remaining = container.read(scribeTabsProvider);
      expect(remaining, hasLength(2));
      expect(
        container.read(activeScribeTabIdProvider),
        remaining[1].id,
      );
    });

    test('closeTab sets null when last tab closed', () {
      final container = createContainer();

      container.read(scribeTabsProvider.notifier).openTab(title: 'Only tab');
      final tabId = container.read(scribeTabsProvider).first.id;

      container.read(scribeTabsProvider.notifier).closeTab(tabId);

      expect(container.read(scribeTabsProvider), isEmpty);
      expect(container.read(activeScribeTabIdProvider), isNull);
    });

    test('updateContent marks tab dirty', () {
      final container = createContainer();

      container.read(scribeTabsProvider.notifier).openTab(title: 'Test');
      final tabId = container.read(scribeTabsProvider).first.id;

      container
          .read(scribeTabsProvider.notifier)
          .updateContent(tabId, 'modified content');

      final tab = container.read(scribeTabsProvider).first;
      expect(tab.isDirty, isTrue);
      expect(tab.content, 'modified content');
    });

    test('markClean resets dirty flag', () {
      final container = createContainer();

      container.read(scribeTabsProvider.notifier).openTab(title: 'Test');
      final tabId = container.read(scribeTabsProvider).first.id;

      container
          .read(scribeTabsProvider.notifier)
          .updateContent(tabId, 'changed');
      expect(container.read(scribeTabsProvider).first.isDirty, isTrue);

      container.read(scribeTabsProvider.notifier).markClean(tabId);
      expect(container.read(scribeTabsProvider).first.isDirty, isFalse);
    });

    test('reorderTabs updates order', () {
      final container = createContainer();

      container.read(scribeTabsProvider.notifier).openTab(title: 'A');
      container.read(scribeTabsProvider.notifier).openTab(title: 'B');
      container.read(scribeTabsProvider.notifier).openTab(title: 'C');

      // Move first tab to end.
      container.read(scribeTabsProvider.notifier).reorderTabs(0, 3);

      final tabs = container.read(scribeTabsProvider);
      expect(tabs[0].title, 'B');
      expect(tabs[1].title, 'C');
      expect(tabs[2].title, 'A');
    });

    test('closeAllTabs clears state', () {
      final container = createContainer();

      container.read(scribeTabsProvider.notifier).openTab(title: 'Tab 1');
      container.read(scribeTabsProvider.notifier).openTab(title: 'Tab 2');

      container.read(scribeTabsProvider.notifier).closeAllTabs();

      expect(container.read(scribeTabsProvider), isEmpty);
      expect(container.read(activeScribeTabIdProvider), isNull);
    });

    test('closeOtherTabs keeps only specified tab', () {
      final container = createContainer();

      container.read(scribeTabsProvider.notifier).openTab(title: 'Keep');
      final keepId = container.read(scribeTabsProvider).first.id;
      container.read(scribeTabsProvider.notifier).openTab(title: 'Remove 1');
      container.read(scribeTabsProvider.notifier).openTab(title: 'Remove 2');

      container.read(scribeTabsProvider.notifier).closeOtherTabs(keepId);

      final tabs = container.read(scribeTabsProvider);
      expect(tabs, hasLength(1));
      expect(tabs.first.title, 'Keep');
      expect(container.read(activeScribeTabIdProvider), keepId);
    });

    test('updateLanguage changes language', () {
      final container = createContainer();

      container.read(scribeTabsProvider.notifier).openTab(
            title: 'Test',
            language: 'plaintext',
          );
      final tabId = container.read(scribeTabsProvider).first.id;

      container
          .read(scribeTabsProvider.notifier)
          .updateLanguage(tabId, 'python');

      expect(container.read(scribeTabsProvider).first.language, 'python');
    });

    test('updateEncoding changes encoding', () {
      final container = createContainer();

      container.read(scribeTabsProvider.notifier).openTab(title: 'Test');
      final tabId = container.read(scribeTabsProvider).first.id;

      expect(container.read(scribeTabsProvider).first.encoding, 'utf-8');

      container
          .read(scribeTabsProvider.notifier)
          .updateEncoding(tabId, 'ascii');

      expect(container.read(scribeTabsProvider).first.encoding, 'ascii');
    });

    test('updateLineEnding changes line ending', () {
      final container = createContainer();

      container.read(scribeTabsProvider.notifier).openTab(title: 'Test');
      final tabId = container.read(scribeTabsProvider).first.id;

      expect(container.read(scribeTabsProvider).first.lineEnding, 'lf');

      container
          .read(scribeTabsProvider.notifier)
          .updateLineEnding(tabId, 'crlf');

      expect(container.read(scribeTabsProvider).first.lineEnding, 'crlf');
    });

    test('updateEncoding is no-op for invalid tabId', () {
      final container = createContainer();

      container.read(scribeTabsProvider.notifier).openTab(title: 'Test');

      container
          .read(scribeTabsProvider.notifier)
          .updateEncoding('nonexistent', 'ascii');

      expect(container.read(scribeTabsProvider).first.encoding, 'utf-8');
    });

    test('updateLineEnding is no-op for invalid tabId', () {
      final container = createContainer();

      container.read(scribeTabsProvider.notifier).openTab(title: 'Test');

      container
          .read(scribeTabsProvider.notifier)
          .updateLineEnding('nonexistent', 'crlf');

      expect(container.read(scribeTabsProvider).first.lineEnding, 'lf');
    });

    test('loadFromPersistence loads tabs from database', () async {
      final now = DateTime(2026, 2, 20);
      final testTabs = [
        ScribeTab(
          id: 'persisted-1',
          title: 'saved.dart',
          content: 'saved content',
          language: 'dart',
          createdAt: now,
          lastModifiedAt: now,
        ),
      ];
      when(() => mockPersistence.loadTabs())
          .thenAnswer((_) async => testTabs);

      final container = createContainer();
      await container
          .read(scribeTabsProvider.notifier)
          .loadFromPersistence();

      expect(container.read(scribeTabsProvider), hasLength(1));
      expect(container.read(scribeTabsProvider).first.id, 'persisted-1');
    });
  });

  group('Closed tab history', () {
    test('closeTab pushes tab to closed history', () {
      final container = createContainer();

      container.read(scribeTabsProvider.notifier).openTab(title: 'Tab 1');
      final tabId = container.read(scribeTabsProvider).first.id;

      container.read(scribeTabsProvider.notifier).closeTab(tabId);

      final history = container.read(scribeClosedTabHistoryProvider);
      expect(history, hasLength(1));
      expect(history.first.title, 'Tab 1');
    });

    test('closeAllTabs pushes all tabs to closed history', () {
      final container = createContainer();

      container.read(scribeTabsProvider.notifier).openTab(title: 'Tab 1');
      container.read(scribeTabsProvider.notifier).openTab(title: 'Tab 2');

      container.read(scribeTabsProvider.notifier).closeAllTabs();

      final history = container.read(scribeClosedTabHistoryProvider);
      expect(history, hasLength(2));
      expect(history[0].title, 'Tab 1');
      expect(history[1].title, 'Tab 2');
    });

    test('closeOtherTabs pushes removed tabs to closed history', () {
      final container = createContainer();

      container.read(scribeTabsProvider.notifier).openTab(title: 'Keep');
      final keepId = container.read(scribeTabsProvider).first.id;
      container.read(scribeTabsProvider.notifier).openTab(title: 'Remove 1');
      container.read(scribeTabsProvider.notifier).openTab(title: 'Remove 2');

      container.read(scribeTabsProvider.notifier).closeOtherTabs(keepId);

      final history = container.read(scribeClosedTabHistoryProvider);
      expect(history, hasLength(2));
      expect(history.map((t) => t.title), containsAll(['Remove 1', 'Remove 2']));
    });

    test('closed history capped at 20 entries', () {
      final container = createContainer();

      // Create and close 25 tabs.
      for (var i = 0; i < 25; i++) {
        container.read(scribeTabsProvider.notifier).openTab(title: 'Tab-$i');
      }
      container.read(scribeTabsProvider.notifier).closeAllTabs();

      final history = container.read(scribeClosedTabHistoryProvider);
      expect(history, hasLength(20));
      // Should keep the last 20 (Tab-5 through Tab-24).
      expect(history.first.title, 'Tab-5');
      expect(history.last.title, 'Tab-24');
    });
  });

  group('closeTabsToRight', () {
    test('closes tabs after specified index', () {
      final container = createContainer();

      container.read(scribeTabsProvider.notifier).openTab(title: 'A');
      container.read(scribeTabsProvider.notifier).openTab(title: 'B');
      container.read(scribeTabsProvider.notifier).openTab(title: 'C');
      container.read(scribeTabsProvider.notifier).openTab(title: 'D');

      final tabs = container.read(scribeTabsProvider);
      container.read(scribeTabsProvider.notifier).closeTabsToRight(tabs[1].id);

      final remaining = container.read(scribeTabsProvider);
      expect(remaining, hasLength(2));
      expect(remaining[0].title, 'A');
      expect(remaining[1].title, 'B');

      final history = container.read(scribeClosedTabHistoryProvider);
      expect(history, hasLength(2));
      expect(history[0].title, 'C');
      expect(history[1].title, 'D');
    });

    test('does nothing when tab is last', () {
      final container = createContainer();

      container.read(scribeTabsProvider.notifier).openTab(title: 'A');
      container.read(scribeTabsProvider.notifier).openTab(title: 'B');

      final tabs = container.read(scribeTabsProvider);
      container.read(scribeTabsProvider.notifier).closeTabsToRight(tabs.last.id);

      expect(container.read(scribeTabsProvider), hasLength(2));
      expect(container.read(scribeClosedTabHistoryProvider), isEmpty);
    });

    test('activates kept tab when active tab removed', () {
      final container = createContainer();

      container.read(scribeTabsProvider.notifier).openTab(title: 'A');
      container.read(scribeTabsProvider.notifier).openTab(title: 'B');
      container.read(scribeTabsProvider.notifier).openTab(title: 'C');

      final tabs = container.read(scribeTabsProvider);
      // Active is last tab (C). Close to right of A removes B and C.
      container.read(scribeTabsProvider.notifier).closeTabsToRight(tabs[0].id);

      expect(container.read(scribeTabsProvider), hasLength(1));
      expect(container.read(activeScribeTabIdProvider), tabs[0].id);
    });
  });

  group('closeSavedTabs', () {
    test('closes only clean tabs', () {
      final container = createContainer();

      container.read(scribeTabsProvider.notifier).openTab(title: 'Clean 1');
      container.read(scribeTabsProvider.notifier).openTab(title: 'Dirty 1');
      final dirtyId = container.read(scribeTabsProvider).last.id;
      container.read(scribeTabsProvider.notifier)
          .updateContent(dirtyId, 'changed');
      container.read(scribeTabsProvider.notifier).openTab(title: 'Clean 2');

      container.read(scribeTabsProvider.notifier).closeSavedTabs();

      final remaining = container.read(scribeTabsProvider);
      expect(remaining, hasLength(1));
      expect(remaining.first.title, 'Dirty 1');
    });

    test('preserves dirty tabs and activates first remaining', () {
      final container = createContainer();

      container.read(scribeTabsProvider.notifier).openTab(title: 'Clean');
      container.read(scribeTabsProvider.notifier).openTab(title: 'Dirty');
      final dirtyId = container.read(scribeTabsProvider).last.id;
      container.read(scribeTabsProvider.notifier)
          .updateContent(dirtyId, 'changed');

      // Active is the clean tab.
      container.read(activeScribeTabIdProvider.notifier).state =
          container.read(scribeTabsProvider).first.id;

      container.read(scribeTabsProvider.notifier).closeSavedTabs();

      expect(container.read(activeScribeTabIdProvider), dirtyId);
    });

    test('does nothing when no saved tabs exist', () {
      final container = createContainer();

      container.read(scribeTabsProvider.notifier).openTab(title: 'Dirty');
      final dirtyId = container.read(scribeTabsProvider).first.id;
      container.read(scribeTabsProvider.notifier)
          .updateContent(dirtyId, 'changed');

      container.read(scribeTabsProvider.notifier).closeSavedTabs();

      expect(container.read(scribeTabsProvider), hasLength(1));
      expect(container.read(scribeClosedTabHistoryProvider), isEmpty);
    });
  });

  group('reopenLastClosed', () {
    test('restores tab and activates it', () {
      final container = createContainer();

      container.read(scribeTabsProvider.notifier).openTab(title: 'Tab 1');
      container.read(scribeTabsProvider.notifier).openTab(title: 'Tab 2');
      final tab2Id = container.read(scribeTabsProvider).last.id;

      container.read(scribeTabsProvider.notifier).closeTab(tab2Id);
      expect(container.read(scribeTabsProvider), hasLength(1));

      container.read(scribeTabsProvider.notifier).reopenLastClosed();

      final tabs = container.read(scribeTabsProvider);
      expect(tabs, hasLength(2));
      expect(tabs.last.title, 'Tab 2');
      expect(container.read(activeScribeTabIdProvider), tab2Id);
      expect(container.read(scribeClosedTabHistoryProvider), isEmpty);
    });

    test('does nothing when history is empty', () {
      final container = createContainer();

      container.read(scribeTabsProvider.notifier).openTab(title: 'Tab 1');
      final tabCount = container.read(scribeTabsProvider).length;

      container.read(scribeTabsProvider.notifier).reopenLastClosed();

      expect(container.read(scribeTabsProvider), hasLength(tabCount));
    });
  });

  group('updateTabFilePath', () {
    test('updates file path, title, and marks clean', () {
      final container = createContainer();

      container.read(scribeTabsProvider.notifier).openTab(title: 'Untitled-1');
      final tabId = container.read(scribeTabsProvider).first.id;

      // Make it dirty first.
      container
          .read(scribeTabsProvider.notifier)
          .updateContent(tabId, 'some content');
      expect(container.read(scribeTabsProvider).first.isDirty, isTrue);

      container
          .read(scribeTabsProvider.notifier)
          .updateTabFilePath(tabId, '/path/to/saved.dart');

      final tab = container.read(scribeTabsProvider).first;
      expect(tab.filePath, '/path/to/saved.dart');
      expect(tab.title, 'saved.dart');
      expect(tab.isDirty, isFalse);
    });

    test('extracts file name from path', () {
      final container = createContainer();

      container.read(scribeTabsProvider.notifier).openTab(title: 'Temp');
      final tabId = container.read(scribeTabsProvider).first.id;

      container
          .read(scribeTabsProvider.notifier)
          .updateTabFilePath(tabId, '/deep/nested/folder/config.yaml');

      expect(container.read(scribeTabsProvider).first.title, 'config.yaml');
    });

    test('no-op for nonexistent tab id', () {
      final container = createContainer();

      container.read(scribeTabsProvider.notifier).openTab(title: 'Real');

      container
          .read(scribeTabsProvider.notifier)
          .updateTabFilePath('nonexistent', '/path/to/file.dart');

      // No crash, original tab unchanged.
      expect(container.read(scribeTabsProvider).first.title, 'Real');
    });
  });

  group('scribeRecentFilesProvider', () {
    test('initializes empty', () {
      final container = createContainer();
      expect(container.read(scribeRecentFilesProvider), isEmpty);
    });

    test('can be set', () {
      final container = createContainer();
      container.read(scribeRecentFilesProvider.notifier).state = [
        '/a.dart',
        '/b.dart',
      ];
      expect(container.read(scribeRecentFilesProvider), hasLength(2));
    });
  });

  group('ScribeSettingsNotifier', () {
    test('updateFontSize clamps to valid range', () {
      final container = createContainer();

      container.read(scribeSettingsProvider.notifier).updateFontSize(8.0);
      expect(container.read(scribeSettingsProvider).fontSize, 12.0);

      container.read(scribeSettingsProvider.notifier).updateFontSize(30.0);
      expect(container.read(scribeSettingsProvider).fontSize, 24.0);

      container.read(scribeSettingsProvider.notifier).updateFontSize(16.0);
      expect(container.read(scribeSettingsProvider).fontSize, 16.0);
    });

    test('updateTabSize accepts valid values', () {
      final container = createContainer();

      container.read(scribeSettingsProvider.notifier).updateTabSize(4);
      expect(container.read(scribeSettingsProvider).tabSize, 4);

      container.read(scribeSettingsProvider.notifier).updateTabSize(8);
      expect(container.read(scribeSettingsProvider).tabSize, 8);
    });

    test('updateTabSize rejects invalid values', () {
      final container = createContainer();

      container.read(scribeSettingsProvider.notifier).updateTabSize(3);
      expect(container.read(scribeSettingsProvider).tabSize, 2);
    });

    test('toggleWordWrap toggles', () {
      final container = createContainer();

      expect(container.read(scribeSettingsProvider).wordWrap, isFalse);

      container.read(scribeSettingsProvider.notifier).toggleWordWrap();
      expect(container.read(scribeSettingsProvider).wordWrap, isTrue);

      container.read(scribeSettingsProvider.notifier).toggleWordWrap();
      expect(container.read(scribeSettingsProvider).wordWrap, isFalse);
    });

    test('toggleLineNumbers toggles', () {
      final container = createContainer();

      expect(container.read(scribeSettingsProvider).showLineNumbers, isTrue);

      container.read(scribeSettingsProvider.notifier).toggleLineNumbers();
      expect(container.read(scribeSettingsProvider).showLineNumbers, isFalse);
    });

    test('toggleMinimap toggles', () {
      final container = createContainer();

      expect(container.read(scribeSettingsProvider).showMinimap, isFalse);

      container.read(scribeSettingsProvider.notifier).toggleMinimap();
      expect(container.read(scribeSettingsProvider).showMinimap, isTrue);
    });

    test('setThemeMode changes theme', () {
      final container = createContainer();

      container.read(scribeSettingsProvider.notifier).setThemeMode('light');
      expect(container.read(scribeSettingsProvider).themeMode, 'light');

      container.read(scribeSettingsProvider.notifier).setThemeMode('dark');
      expect(container.read(scribeSettingsProvider).themeMode, 'dark');
    });

    test('setThemeMode rejects invalid mode', () {
      final container = createContainer();

      container.read(scribeSettingsProvider.notifier).setThemeMode('neon');
      expect(container.read(scribeSettingsProvider).themeMode, 'dark');
    });

    test('loadFromPersistence loads settings from database', () async {
      final testSettings = const ScribeSettings(
        fontSize: 18.0,
        tabSize: 4,
        wordWrap: true,
      );
      when(() => mockPersistence.loadSettings())
          .thenAnswer((_) async => testSettings);

      final container = createContainer();
      await container
          .read(scribeSettingsProvider.notifier)
          .loadFromPersistence();

      final settings = container.read(scribeSettingsProvider);
      expect(settings.fontSize, 18.0);
      expect(settings.tabSize, 4);
      expect(settings.wordWrap, isTrue);
    });
  });

  group('Computed providers', () {
    test('activeScribeTabProvider returns correct tab', () {
      final container = createContainer();

      container.read(scribeTabsProvider.notifier).openTab(title: 'Tab 1');
      container.read(scribeTabsProvider.notifier).openTab(title: 'Tab 2');

      final tabs = container.read(scribeTabsProvider);
      container.read(activeScribeTabIdProvider.notifier).state = tabs.first.id;

      final active = container.read(activeScribeTabProvider);
      expect(active, isNotNull);
      expect(active!.title, 'Tab 1');
    });

    test('activeScribeTabProvider returns null when no tabs', () {
      final container = createContainer();
      expect(container.read(activeScribeTabProvider), isNull);
    });

    test('activeScribeTabProvider returns null when id not found', () {
      final container = createContainer();
      container.read(scribeTabsProvider.notifier).openTab(title: 'Tab 1');
      container.read(activeScribeTabIdProvider.notifier).state = 'nonexistent';
      expect(container.read(activeScribeTabProvider), isNull);
    });

    test('hasUnsavedChangesProvider detects dirty tabs', () {
      final container = createContainer();

      container.read(scribeTabsProvider.notifier).openTab(title: 'Tab 1');
      expect(container.read(scribeHasUnsavedChangesProvider), isFalse);

      final tabId = container.read(scribeTabsProvider).first.id;
      container
          .read(scribeTabsProvider.notifier)
          .updateContent(tabId, 'changed');
      expect(container.read(scribeHasUnsavedChangesProvider), isTrue);
    });

    test('hasUnsavedChangesProvider returns false when empty', () {
      final container = createContainer();
      expect(container.read(scribeHasUnsavedChangesProvider), isFalse);
    });

    test('scribeTabCountProvider returns correct count', () {
      final container = createContainer();
      expect(container.read(scribeTabCountProvider), 0);

      container.read(scribeTabsProvider.notifier).openTab(title: 'A');
      container.read(scribeTabsProvider.notifier).openTab(title: 'B');
      expect(container.read(scribeTabCountProvider), 2);
    });
  });

  group('State providers', () {
    test('activeScribeTabIdProvider initializes null', () {
      final container = createContainer();
      expect(container.read(activeScribeTabIdProvider), isNull);
    });

    test('scribeUntitledCounterProvider initializes to 1', () {
      final container = createContainer();
      expect(container.read(scribeUntitledCounterProvider), 1);
    });

    test('scribeSidebarVisibleProvider initializes false', () {
      final container = createContainer();
      expect(container.read(scribeSidebarVisibleProvider), isFalse);
    });

    test('scribeClosedTabHistoryProvider initializes empty', () {
      final container = createContainer();
      expect(container.read(scribeClosedTabHistoryProvider), isEmpty);
    });

    test('scribeSettingsProvider initializes with defaults', () {
      final container = createContainer();
      final settings = container.read(scribeSettingsProvider);
      expect(settings.fontSize, 14.0);
      expect(settings.tabSize, 2);
      expect(settings.insertSpaces, isTrue);
      expect(settings.wordWrap, isFalse);
      expect(settings.showLineNumbers, isTrue);
      expect(settings.showMinimap, isFalse);
      expect(settings.themeMode, 'dark');
      expect(settings.fontFamily, 'JetBrains Mono');
      expect(settings.autoSave, isFalse);
      expect(settings.autoSaveIntervalSeconds, 30);
      expect(settings.showWhitespace, isFalse);
      expect(settings.bracketMatching, isTrue);
      expect(settings.autoCloseBrackets, isTrue);
      expect(settings.highlightActiveLine, isTrue);
      expect(settings.scrollBeyondLastLine, isTrue);
    });

    test('scribeSettingsPanelVisibleProvider initializes false', () {
      final container = createContainer();
      expect(container.read(scribeSettingsPanelVisibleProvider), isFalse);
    });
  });

  group('ScribeSettingsNotifier — new fields (CS-005)', () {
    test('updateFontFamily changes font family', () {
      final container = createContainer();

      container
          .read(scribeSettingsProvider.notifier)
          .updateFontFamily('Fira Code');
      expect(
        container.read(scribeSettingsProvider).fontFamily,
        'Fira Code',
      );
    });

    test('updateFontFamily rejects empty string', () {
      final container = createContainer();

      container.read(scribeSettingsProvider.notifier).updateFontFamily('');
      expect(
        container.read(scribeSettingsProvider).fontFamily,
        'JetBrains Mono',
      );
    });

    test('toggleInsertSpaces toggles', () {
      final container = createContainer();

      expect(container.read(scribeSettingsProvider).insertSpaces, isTrue);

      container.read(scribeSettingsProvider.notifier).toggleInsertSpaces();
      expect(container.read(scribeSettingsProvider).insertSpaces, isFalse);

      container.read(scribeSettingsProvider.notifier).toggleInsertSpaces();
      expect(container.read(scribeSettingsProvider).insertSpaces, isTrue);
    });

    test('toggleHighlightActiveLine toggles', () {
      final container = createContainer();

      expect(
        container.read(scribeSettingsProvider).highlightActiveLine,
        isTrue,
      );

      container
          .read(scribeSettingsProvider.notifier)
          .toggleHighlightActiveLine();
      expect(
        container.read(scribeSettingsProvider).highlightActiveLine,
        isFalse,
      );
    });

    test('toggleBracketMatching toggles', () {
      final container = createContainer();

      expect(
        container.read(scribeSettingsProvider).bracketMatching,
        isTrue,
      );

      container
          .read(scribeSettingsProvider.notifier)
          .toggleBracketMatching();
      expect(
        container.read(scribeSettingsProvider).bracketMatching,
        isFalse,
      );
    });

    test('toggleAutoCloseBrackets toggles', () {
      final container = createContainer();

      expect(
        container.read(scribeSettingsProvider).autoCloseBrackets,
        isTrue,
      );

      container
          .read(scribeSettingsProvider.notifier)
          .toggleAutoCloseBrackets();
      expect(
        container.read(scribeSettingsProvider).autoCloseBrackets,
        isFalse,
      );
    });

    test('toggleShowWhitespace toggles', () {
      final container = createContainer();

      expect(
        container.read(scribeSettingsProvider).showWhitespace,
        isFalse,
      );

      container
          .read(scribeSettingsProvider.notifier)
          .toggleShowWhitespace();
      expect(
        container.read(scribeSettingsProvider).showWhitespace,
        isTrue,
      );
    });

    test('toggleScrollBeyondLastLine toggles', () {
      final container = createContainer();

      expect(
        container.read(scribeSettingsProvider).scrollBeyondLastLine,
        isTrue,
      );

      container
          .read(scribeSettingsProvider.notifier)
          .toggleScrollBeyondLastLine();
      expect(
        container.read(scribeSettingsProvider).scrollBeyondLastLine,
        isFalse,
      );
    });

    test('toggleAutoSave toggles', () {
      final container = createContainer();

      expect(container.read(scribeSettingsProvider).autoSave, isFalse);

      container.read(scribeSettingsProvider.notifier).toggleAutoSave();
      expect(container.read(scribeSettingsProvider).autoSave, isTrue);

      container.read(scribeSettingsProvider.notifier).toggleAutoSave();
      expect(container.read(scribeSettingsProvider).autoSave, isFalse);
    });

    test('updateAutoSaveInterval clamps to valid range', () {
      final container = createContainer();

      container
          .read(scribeSettingsProvider.notifier)
          .updateAutoSaveInterval(2);
      expect(
        container.read(scribeSettingsProvider).autoSaveIntervalSeconds,
        5,
      );

      container
          .read(scribeSettingsProvider.notifier)
          .updateAutoSaveInterval(600);
      expect(
        container.read(scribeSettingsProvider).autoSaveIntervalSeconds,
        300,
      );

      container
          .read(scribeSettingsProvider.notifier)
          .updateAutoSaveInterval(60);
      expect(
        container.read(scribeSettingsProvider).autoSaveIntervalSeconds,
        60,
      );
    });

    test('resetToDefaults restores all settings', () {
      final container = createContainer();

      // Change several settings.
      container.read(scribeSettingsProvider.notifier).updateFontSize(20.0);
      container.read(scribeSettingsProvider.notifier).updateTabSize(4);
      container.read(scribeSettingsProvider.notifier).toggleWordWrap();
      container.read(scribeSettingsProvider.notifier).setThemeMode('light');
      container
          .read(scribeSettingsProvider.notifier)
          .updateFontFamily('Fira Code');
      container.read(scribeSettingsProvider.notifier).toggleAutoSave();
      container
          .read(scribeSettingsProvider.notifier)
          .toggleHighlightActiveLine();

      // Reset.
      container.read(scribeSettingsProvider.notifier).resetToDefaults();

      final settings = container.read(scribeSettingsProvider);
      expect(settings.fontSize, 14.0);
      expect(settings.tabSize, 2);
      expect(settings.wordWrap, isFalse);
      expect(settings.themeMode, 'dark');
      expect(settings.fontFamily, 'JetBrains Mono');
      expect(settings.autoSave, isFalse);
      expect(settings.highlightActiveLine, isTrue);
    });

    test('debounced persistence calls saveSettings after delay', () async {
      final container = createContainer();

      container.read(scribeSettingsProvider.notifier).updateFontSize(20.0);

      // Persistence should not be called immediately.
      verifyNever(() => mockPersistence.saveSettings(any()));

      // Wait for the debounce timer to fire.
      await Future<void>.delayed(const Duration(milliseconds: 600));

      verify(() => mockPersistence.saveSettings(any())).called(1);
    });

    test('rapid changes result in single persistence call', () async {
      final container = createContainer();

      container.read(scribeSettingsProvider.notifier).updateFontSize(16.0);
      container.read(scribeSettingsProvider.notifier).updateFontSize(18.0);
      container.read(scribeSettingsProvider.notifier).updateFontSize(20.0);

      // Wait for debounce.
      await Future<void>.delayed(const Duration(milliseconds: 600));

      // Only the last debounce fires — single call.
      verify(() => mockPersistence.saveSettings(any())).called(1);
    });
  });

  group('ScribeSettings model — JSON round-trip (CS-005)', () {
    test('toJson and fromJson preserve all 15 fields', () {
      const original = ScribeSettings(
        fontSize: 18.0,
        tabSize: 4,
        insertSpaces: false,
        wordWrap: true,
        showLineNumbers: false,
        showMinimap: true,
        themeMode: 'light',
        fontFamily: 'Fira Code',
        autoSave: true,
        autoSaveIntervalSeconds: 60,
        showWhitespace: true,
        bracketMatching: false,
        autoCloseBrackets: false,
        highlightActiveLine: false,
        scrollBeyondLastLine: false,
      );

      final json = original.toJson();
      final restored = ScribeSettings.fromJson(json);

      expect(restored.fontSize, 18.0);
      expect(restored.tabSize, 4);
      expect(restored.insertSpaces, isFalse);
      expect(restored.wordWrap, isTrue);
      expect(restored.showLineNumbers, isFalse);
      expect(restored.showMinimap, isTrue);
      expect(restored.themeMode, 'light');
      expect(restored.fontFamily, 'Fira Code');
      expect(restored.autoSave, isTrue);
      expect(restored.autoSaveIntervalSeconds, 60);
      expect(restored.showWhitespace, isTrue);
      expect(restored.bracketMatching, isFalse);
      expect(restored.autoCloseBrackets, isFalse);
      expect(restored.highlightActiveLine, isFalse);
      expect(restored.scrollBeyondLastLine, isFalse);
    });

    test('fromJson uses defaults for missing new fields', () {
      // Simulate loading old settings that lack the new CS-005 fields.
      final oldJson = <String, dynamic>{
        'fontSize': 16.0,
        'tabSize': 4,
        'insertSpaces': true,
        'wordWrap': false,
        'showLineNumbers': true,
        'showMinimap': false,
        'themeMode': 'dark',
      };

      final settings = ScribeSettings.fromJson(oldJson);

      expect(settings.fontSize, 16.0);
      expect(settings.tabSize, 4);
      // New fields get defaults.
      expect(settings.fontFamily, 'JetBrains Mono');
      expect(settings.autoSave, isFalse);
      expect(settings.autoSaveIntervalSeconds, 30);
      expect(settings.showWhitespace, isFalse);
      expect(settings.bracketMatching, isTrue);
      expect(settings.autoCloseBrackets, isTrue);
      expect(settings.highlightActiveLine, isTrue);
      expect(settings.scrollBeyondLastLine, isTrue);
    });

    test('toJsonString and fromJsonString round-trip', () {
      const original = ScribeSettings(
        fontSize: 20.0,
        fontFamily: 'Monaco',
        autoSave: true,
        autoSaveIntervalSeconds: 45,
      );

      final jsonString = original.toJsonString();
      final restored = ScribeSettings.fromJsonString(jsonString);

      expect(restored.fontSize, 20.0);
      expect(restored.fontFamily, 'Monaco');
      expect(restored.autoSave, isTrue);
      expect(restored.autoSaveIntervalSeconds, 45);
    });

    test('copyWith preserves unmodified new fields', () {
      const original = ScribeSettings(
        fontFamily: 'Menlo',
        autoSave: true,
        highlightActiveLine: false,
      );

      final modified = original.copyWith(fontSize: 20.0);

      expect(modified.fontSize, 20.0);
      expect(modified.fontFamily, 'Menlo');
      expect(modified.autoSave, isTrue);
      expect(modified.highlightActiveLine, isFalse);
    });
  });

  group('Preview state providers (CS-006)', () {
    test('scribePreviewModeProvider initializes empty', () {
      final container = createContainer();
      expect(container.read(scribePreviewModeProvider), isEmpty);
    });

    test('scribePreviewModeProvider can store per-tab modes', () {
      final container = createContainer();

      container.read(scribePreviewModeProvider.notifier).state = {
        'tab-1': 'split',
        'tab-2': 'preview',
      };

      final modes = container.read(scribePreviewModeProvider);
      expect(modes['tab-1'], 'split');
      expect(modes['tab-2'], 'preview');
    });

    test('scribeSplitRatioProvider initializes empty', () {
      final container = createContainer();
      expect(container.read(scribeSplitRatioProvider), isEmpty);
    });

    test('scribeSplitRatioProvider can store per-tab ratios', () {
      final container = createContainer();

      container.read(scribeSplitRatioProvider.notifier).state = {
        'tab-1': 0.6,
        'tab-2': 0.3,
      };

      final ratios = container.read(scribeSplitRatioProvider);
      expect(ratios['tab-1'], 0.6);
      expect(ratios['tab-2'], 0.3);
    });

    test('missing tab ID returns null (default handled by consumer)', () {
      final container = createContainer();

      final modes = container.read(scribePreviewModeProvider);
      expect(modes['nonexistent'], isNull);

      final ratios = container.read(scribeSplitRatioProvider);
      expect(ratios['nonexistent'], isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // Diff Providers (CS-007)
  // ---------------------------------------------------------------------------

  group('Diff Providers', () {
    test('scribeDiffStateProvider defaults to null', () {
      final container = createContainer();
      expect(container.read(scribeDiffStateProvider), isNull);
    });

    test('scribeDiffStateProvider can be set and read', () {
      final container = createContainer();
      const state = DiffState(
        leftTabId: 'tab-1',
        rightTabId: 'tab-2',
        lines: [],
        summary: DiffSummary(),
        changeIndices: [],
      );

      container.read(scribeDiffStateProvider.notifier).state = state;
      final result = container.read(scribeDiffStateProvider);

      expect(result, isNotNull);
      expect(result!.leftTabId, 'tab-1');
      expect(result.rightTabId, 'tab-2');
    });

    test('scribeDiffViewModeProvider defaults to sideBySide', () {
      final container = createContainer();
      expect(
        container.read(scribeDiffViewModeProvider),
        DiffViewMode.sideBySide,
      );
    });

    test('scribeDiffViewModeProvider can be set to inline', () {
      final container = createContainer();
      container.read(scribeDiffViewModeProvider.notifier).state =
          DiffViewMode.inline;
      expect(
        container.read(scribeDiffViewModeProvider),
        DiffViewMode.inline,
      );
    });

    test('scribeCollapseUnchangedProvider defaults to true', () {
      final container = createContainer();
      expect(container.read(scribeCollapseUnchangedProvider), isTrue);
    });

    test('scribeCollapseUnchangedProvider can be toggled', () {
      final container = createContainer();
      container.read(scribeCollapseUnchangedProvider.notifier).state = false;
      expect(container.read(scribeCollapseUnchangedProvider), isFalse);
    });

    test('scribeDiffServiceProvider returns a service instance', () {
      final container = createContainer();
      final service = container.read(scribeDiffServiceProvider);
      expect(service, isNotNull);
    });
  });

  // ---------------------------------------------------------------------------
  // Session Persistence Providers (CS-008)
  // ---------------------------------------------------------------------------

  group('Session Persistence (CS-008)', () {
    test('scribeRecentFilesPanelVisibleProvider defaults to false', () {
      final container = createContainer();
      expect(container.read(scribeRecentFilesPanelVisibleProvider), isFalse);
    });

    test('scribeQuickOpenVisibleProvider defaults to false', () {
      final container = createContainer();
      expect(container.read(scribeQuickOpenVisibleProvider), isFalse);
    });

    test('scribeFileChangedTabsProvider defaults to empty', () {
      final container = createContainer();
      expect(container.read(scribeFileChangedTabsProvider), isEmpty);
    });

    test('scribeFileChangedTabsProvider can track changed tabs', () {
      final container = createContainer();
      container.read(scribeFileChangedTabsProvider.notifier).state = {
        'tab-1': true,
        'tab-3': true,
      };
      final changed = container.read(scribeFileChangedTabsProvider);
      expect(changed, hasLength(2));
      expect(changed['tab-1'], isTrue);
      expect(changed['tab-3'], isTrue);
    });
  });

  group('ScribeTabsNotifier — cursor and scroll (CS-008)', () {
    test('updateCursorPosition updates cursor without marking dirty', () {
      final container = createContainer();

      container.read(scribeTabsProvider.notifier).openTab(title: 'Test');
      final tabId = container.read(scribeTabsProvider).first.id;

      container
          .read(scribeTabsProvider.notifier)
          .updateCursorPosition(tabId, 10, 5);

      final tab = container.read(scribeTabsProvider).first;
      expect(tab.cursorLine, 10);
      expect(tab.cursorColumn, 5);
      expect(tab.isDirty, isFalse);
    });

    test('updateCursorPosition no-op when values unchanged', () {
      final container = createContainer();

      container.read(scribeTabsProvider.notifier).openTab(title: 'Test');
      final tabId = container.read(scribeTabsProvider).first.id;

      // Initial cursor is (0, 0). Setting to same values should be a no-op.
      container
          .read(scribeTabsProvider.notifier)
          .updateCursorPosition(tabId, 0, 0);

      // Still at default values.
      final tab = container.read(scribeTabsProvider).first;
      expect(tab.cursorLine, 0);
      expect(tab.cursorColumn, 0);
    });

    test('updateCursorPosition no-op for nonexistent tab', () {
      final container = createContainer();

      container.read(scribeTabsProvider.notifier).openTab(title: 'Test');

      // Should not throw.
      container
          .read(scribeTabsProvider.notifier)
          .updateCursorPosition('nonexistent', 5, 3);

      expect(container.read(scribeTabsProvider).first.cursorLine, 0);
    });

    test('updateScrollOffset updates offset without marking dirty', () {
      final container = createContainer();

      container.read(scribeTabsProvider.notifier).openTab(title: 'Test');
      final tabId = container.read(scribeTabsProvider).first.id;

      container
          .read(scribeTabsProvider.notifier)
          .updateScrollOffset(tabId, 150.5);

      final tab = container.read(scribeTabsProvider).first;
      expect(tab.scrollOffset, 150.5);
      expect(tab.isDirty, isFalse);
    });

    test('updateScrollOffset no-op when value unchanged', () {
      final container = createContainer();

      container.read(scribeTabsProvider.notifier).openTab(title: 'Test');
      final tabId = container.read(scribeTabsProvider).first.id;

      container
          .read(scribeTabsProvider.notifier)
          .updateScrollOffset(tabId, 0.0);

      final tab = container.read(scribeTabsProvider).first;
      expect(tab.scrollOffset, 0.0);
    });

    test('persistSessionNow saves tabs and session metadata', () async {
      when(() => mockPersistence.saveSessionMetadata(
            activeTabId: any(named: 'activeTabId'),
          )).thenAnswer((_) async {});

      final container = createContainer();
      container.read(scribeTabsProvider.notifier).openTab(title: 'Test');

      // Reset call counts after openTab's _persist call.
      clearInteractions(mockPersistence);

      await container
          .read(scribeTabsProvider.notifier)
          .persistSessionNow();

      verify(() => mockPersistence.saveTabs(any())).called(1);
      verify(() => mockPersistence.saveSessionMetadata(
            activeTabId: any(named: 'activeTabId'),
          )).called(1);
    });
  });

  group('scribeInitProvider — session metadata restore (CS-008)', () {
    test('restores active tab from session metadata', () async {
      final now = DateTime(2026, 2, 20);
      final testTabs = [
        ScribeTab(
          id: 'tab-1',
          title: 'first.dart',
          createdAt: now,
          lastModifiedAt: now,
        ),
        ScribeTab(
          id: 'tab-2',
          title: 'second.dart',
          createdAt: now,
          lastModifiedAt: now,
        ),
      ];

      when(() => mockPersistence.loadTabs())
          .thenAnswer((_) async => testTabs);
      when(() => mockPersistence.loadSessionMetadata())
          .thenAnswer((_) async => (activeTabId: 'tab-2', timestamp: now));
      when(() => mockPersistence.loadSettingsValue(any()))
          .thenAnswer((_) async => null);
      when(() => mockPersistence.saveSessionMetadata(
            activeTabId: any(named: 'activeTabId'),
          )).thenAnswer((_) async {});

      final container = createContainer();
      await container.read(scribeInitProvider.future);

      expect(container.read(activeScribeTabIdProvider), 'tab-2');
    });

    test('falls back to first tab when saved active tab not found', () async {
      final now = DateTime(2026, 2, 20);
      final testTabs = [
        ScribeTab(
          id: 'tab-1',
          title: 'first.dart',
          createdAt: now,
          lastModifiedAt: now,
        ),
      ];

      when(() => mockPersistence.loadTabs())
          .thenAnswer((_) async => testTabs);
      when(() => mockPersistence.loadSessionMetadata())
          .thenAnswer((_) async => (activeTabId: 'nonexistent', timestamp: now));
      when(() => mockPersistence.loadSettingsValue(any()))
          .thenAnswer((_) async => null);
      when(() => mockPersistence.saveSessionMetadata(
            activeTabId: any(named: 'activeTabId'),
          )).thenAnswer((_) async {});

      final container = createContainer();
      await container.read(scribeInitProvider.future);

      expect(container.read(activeScribeTabIdProvider), 'tab-1');
    });
  });
}
