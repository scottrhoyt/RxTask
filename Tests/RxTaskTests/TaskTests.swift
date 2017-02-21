import XCTest
@testable import RxTask
import RxSwift
import RxBlocking

class TaskTests: XCTestCase {
    func testStdOut() throws {
        let script = try ScriptFile(commands: [
                "echo hello world",
                "sleep 0.1"
            ])

        let events = try getEvents(for: script)

        XCTAssertEqual(events.count, 3)
        XCTAssertEqual(events[0], .launch(command: script.path))
        XCTAssertEqual(events[1], .stdOut("hello world\n"))
        XCTAssertEqual(events[2], .exit(statusCode: 0))
    }

    func testStdErr() throws {
        let script = try ScriptFile(commands: [
            "echo hello world 1>&2",
            "sleep 0.1"
            ])

        let events = try getEvents(for: script)

        XCTAssertEqual(events.count, 3)
        XCTAssertEqual(events[0], .launch(command: script.path))
        XCTAssertEqual(events[1], .stdErr("hello world\n"))
        XCTAssertEqual(events[2], .exit(statusCode: 0))
    }

    func testExitsWithFailingStatusErrors() throws {
        let script = try ScriptFile(commands: ["exit 100"])

        do {
            _ = try getEvents(for: script)

            // If we get this far it is a failure
            XCTFail()
        } catch {
            if let error = error as? TaskError {
                XCTAssertEqual(error, .exit(statusCode: 100))
            } else {
                XCTFail()
            }
        }
    }

    func testUncaughtSignalErrors() throws {
        let script = try ScriptFile(commands: [
                "kill $$",
                "sleep 10"
            ])

        do {
            _ = try getEvents(for: script)

            // If we get this far it is a failure
            XCTFail()
        } catch {
            if let error = error as? TaskError {
                XCTAssertEqual(error, .uncaughtSignal)
            } else {
                XCTFail()
            }
        }
    }

    func testStdIn() throws {
        let script = try ScriptFile(commands: [
                "read var1",
                "echo $var1",
                "sleep 0.1",
                "read var2",
                "echo $var2",
                "sleep 0.1"
            ])

        let stdIn = Observable.of("hello\n", "world\n")

        let events = try Task(launchPath: script.path, stdIn: stdIn).launch()
            .toBlocking()
            .toArray()

        XCTAssertEqual(events.count, 4)
        XCTAssertEqual(events[0], .launch(command: script.path))
        XCTAssertEqual(events[1], .stdOut("hello\n"))
        XCTAssertEqual(events[2], .stdOut("world\n"))
        XCTAssertEqual(events[3], .exit(statusCode: 0))
    }

    static var allTests: [(String, (TaskTests) -> () throws -> Void)] {
        return [
            ("testStdOut", testStdOut),
            ("testStdErr", testStdErr),
            ("testExitsWithFailingStatusErrors", testExitsWithFailingStatusErrors),
            ("testUncaughtSignalErrors", testUncaughtSignalErrors)
        ]
    }

    // MARK: Helpers

    func getEvents(for script: ScriptFile) throws -> [TaskEvent] {
        return try Task(launchPath: script.path).launch()
            .toBlocking()
            .toArray()
    }
}
