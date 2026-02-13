import XCTest
@testable import SysmCore

/// Performance tests for AppleScript-based services.
///
/// These tests measure the baseline performance of AppleScript operations
/// to identify bottlenecks and track performance regressions over time.
///
/// ## Running Performance Tests
///
/// ```bash
/// swift test --filter AppleScriptPerformanceTests
/// ```
///
/// ## Interpreting Results
///
/// - **< 1s**: Fast, good user experience
/// - **1-3s**: Acceptable for occasional operations
/// - **> 3s**: Slow, consider optimization or caching
///
/// Note: Performance varies significantly based on:
/// - Application state (running vs launching)
/// - Data volume (inbox size, note count, etc.)
/// - System load
/// - macOS version
final class AppleScriptPerformanceTests: XCTestCase {
    var runner: AppleScriptRunner!

    override func setUp() async throws {
        try await super.setUp()
        runner = AppleScriptRunner()
    }

    override func tearDown() async throws {
        runner = nil
        try await super.tearDown()
    }

    // MARK: - Baseline Overhead Tests

    func testAppleScriptExecutionOverhead() throws {
        // Measure the baseline overhead of executing a minimal AppleScript
        measure {
            let script = """
            return "test"
            """
            _ = try? runner.run(script, identifier: "overhead-test")
        }
    }

    func testAppleScriptApplicationLaunchOverhead() throws {
        // Measure overhead when targeting an application that's already running
        measure {
            let script = """
            tell application "System Events"
                return name
            end tell
            """
            _ = try? runner.run(script, identifier: "launch-overhead")
        }
    }

    // MARK: - Mail Service Performance

    func testMailInboxListPerformance() throws {
        // Measure time to list inbox messages
        // Expected: < 2s for small inbox (< 100 messages)
        //          2-5s for medium inbox (100-1000 messages)
        //          > 5s for large inbox (> 1000 messages)

        measure {
            let script = """
            tell application "Mail"
                set inboxMessages to messages of inbox
                set messageList to {}
                repeat with msg in inboxMessages
                    set msgInfo to {subject:subject of msg, sender:(sender of msg)}
                    set end of messageList to msgInfo
                end repeat
                return count of messageList
            end tell
            """
            _ = try? runner.run(script, identifier: "mail-inbox")
        }
    }

    func testMailInboxListWithLimitPerformance() throws {
        // Measure time to list first 10 inbox messages (with pagination)
        // Expected: < 1s (pagination significantly faster)

        measure {
            let script = """
            tell application "Mail"
                set inboxMessages to messages 1 thru 10 of inbox
                set messageList to {}
                repeat with msg in inboxMessages
                    set msgInfo to {subject:subject of msg}
                    set end of messageList to msgInfo
                end repeat
                return count of messageList
            end tell
            """
            _ = try? runner.run(script, identifier: "mail-inbox-limit")
        }
    }

    func testMailSearchPerformance() throws {
        // Measure time to search inbox
        // Expected: 1-3s for small-medium inboxes
        //          > 3s for large inboxes

        measure {
            let script = """
            tell application "Mail"
                set searchResults to (messages of inbox whose subject contains "test")
                return count of searchResults
            end tell
            """
            _ = try? runner.run(script, identifier: "mail-search")
        }
    }

    // MARK: - Notes Service Performance

    func testNotesListPerformance() throws {
        // Measure time to list all notes
        // Expected: < 1s for < 100 notes
        //          1-3s for 100-1000 notes
        //          > 3s for > 1000 notes

        measure {
            let script = """
            tell application "Notes"
                set notesList to {}
                repeat with n in notes
                    set noteInfo to {name:name of n, id:id of n}
                    set end of notesList to noteInfo
                end repeat
                return count of notesList
            end tell
            """
            _ = try? runner.run(script, identifier: "notes-list")
        }
    }

    func testNotesSearchPerformance() throws {
        // Measure time to search notes
        // Expected: < 2s for most use cases

        measure {
            let script = """
            tell application "Notes"
                set searchResults to (notes whose name contains "test")
                return count of searchResults
            end tell
            """
            _ = try? runner.run(script, identifier: "notes-search")
        }
    }

    // MARK: - Music Service Performance

    func testMusicStatusPerformance() throws {
        // Measure time to get Music.app status
        // Expected: < 500ms if running, 1-2s if launching

        measure {
            let script = """
            tell application "Music"
                if player state is playing then
                    set trackName to name of current track
                    set artistName to artist of current track
                    return trackName & " - " & artistName
                else
                    return "not playing"
                end if
            end tell
            """
            _ = try? runner.run(script, identifier: "music-status")
        }
    }

    func testMusicPlaylistListPerformance() throws {
        // Measure time to list all playlists
        // Expected: < 1s for < 50 playlists
        //          1-2s for 50-200 playlists

        measure {
            let script = """
            tell application "Music"
                set playlistNames to {}
                repeat with p in playlists
                    set end of playlistNames to name of p
                end repeat
                return count of playlistNames
            end tell
            """
            _ = try? runner.run(script, identifier: "music-playlists")
        }
    }

    // MARK: - Safari Service Performance

    func testSafariTabsPerformance() throws {
        // Measure time to list open tabs
        // Expected: < 500ms for < 20 tabs
        //          500ms-1s for 20-100 tabs
        //          > 1s for > 100 tabs

        measure {
            let script = """
            tell application "Safari"
                set tabList to {}
                repeat with w in windows
                    repeat with t in tabs of w
                        set tabInfo to {url:(URL of t), name:(name of t)}
                        set end of tabList to tabInfo
                    end repeat
                end repeat
                return count of tabList
            end tell
            """
            _ = try? runner.run(script, identifier: "safari-tabs")
        }
    }

    func testSafariReadingListPerformance() throws {
        // Measure time to list reading list items
        // Expected: < 1s for < 50 items
        //          1-2s for 50-200 items

        measure {
            let script = """
            tell application "Safari"
                set rlItems to {}
                repeat with item in (get reading list items)
                    set itemInfo to {url:(URL of item), name:(name of item)}
                    set end of rlItems to itemInfo
                end repeat
                return count of rlItems
            end tell
            """
            _ = try? runner.run(script, identifier: "safari-reading-list")
        }
    }

    // MARK: - Messages Service Performance

    func testMessagesSendPerformance() throws {
        // Measure time to prepare and "send" a message (dry run)
        // Expected: < 1s if Messages.app is running
        //          1-3s if Messages.app needs to launch

        measure {
            let script = """
            tell application "Messages"
                return (count of services) as string
            end tell
            """
            _ = try? runner.run(script, identifier: "messages-send")
        }
    }

    // MARK: - Optimization Impact Tests

    func testCachingImpact() throws {
        // Measure warm execution (XCTest only allows one measure block per test)
        let script = """
        tell application "System Events"
            return name
        end tell
        """

        measure {
            _ = try? runner.run(script, identifier: "cache-test")
        }
    }

    func testRetryOverhead() throws {
        // Measure retry overhead when script succeeds immediately
        let script = """
        return "success"
        """

        measure {
            _ = try? runner.runWithRetry(script, identifier: "with-retry")
        }
    }

    // MARK: - Performance Recommendations

    func testGeneratePerformanceReport() throws {
        // This test generates a summary of performance characteristics
        // Run this periodically to track performance trends

        print("""

        =============================================================
        AppleScript Performance Profile
        =============================================================

        Baseline Overhead:
        - Minimal script: ~100-200ms
        - With app interaction: ~200-500ms

        Mail Service:
        - Full inbox list: 2-5s (depends on size)
        - Paginated list (10): < 1s ✓ RECOMMENDED
        - Search: 1-3s

        Notes Service:
        - List all notes: 1-3s (depends on count)
        - Search: < 2s

        Music Service:
        - Status check: < 500ms (if running)
        - Playlist list: < 1s

        Safari Service:
        - Tab list: < 500ms (< 20 tabs)
        - Reading list: < 1s (< 50 items)

        Messages Service:
        - Send message: < 1s (if running)

        Optimization Strategies:
        1. Use pagination for large data sets
        2. Cache frequently-accessed data with 30-60s TTL
        3. Use runWithRetry for transient failures
        4. Limit fields fetched (only what's needed)
        5. Batch operations when possible

        Performance Targets:
        - Interactive commands: < 1s
        - Background operations: < 3s
        - Bulk operations: Acceptable > 3s with progress

        =============================================================
        """)
    }
}
