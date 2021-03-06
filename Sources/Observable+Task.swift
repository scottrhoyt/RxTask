//
//  Observable+Task.swift
//  RxRunner
//
//  Created by Scott Hoyt on 2/20/17.
//
//

import Foundation
import RxSwift

/// A protocol encapsulated `TaskEvent`. Necessary to create `Observable` operators and not intended for public use.
public protocol TaskEventType {

    /// The exit status code if available, `nil` otherwise.
    var exitStatus: Int? { get }

    /// The output of the event if available, `nil` otherwise.
    var output: String? { get }
}

extension TaskEvent: TaskEventType {

    /// The exit status code if available, `nil` otherwise.
    public var exitStatus: Int? {
        switch self {
        case .exit(let statusCode):
            return statusCode
        default:
            return nil
        }
    }

    /// The output of the event if available, `nil` otherwise.
    public var output: String? {
        switch self {
        case .stdErr(let output), .stdOut(let output):
            return output
        default:
            return nil
        }
    }
}

public extension Observable where Element: TaskEventType {

    /// Filters out the output and launch events to produce just an `Observable` of the exit status.
    func justExitStatus() -> Observable<Int> {
        return flatMap { event -> Observable<Int> in
            guard let exitStatus = event.exitStatus else {
                return Observable<Int>.empty()
            }

            return Observable<Int>.just(exitStatus)
        }
    }

    /// Filters out the launch and exit events to just produce and `Observable` of the output (`stdout` and `stderr`).
    func justOutput() -> Observable<String> {
        return flatMap { event -> Observable<String> in
            guard let output = event.output else {
                return Observable<String>.empty()
            }

            return Observable<String>.just(output)
        }
    }
}
