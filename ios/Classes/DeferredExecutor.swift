//
//  SerialExecutor.swift
//  fluetooth
//
//  Created by Iandi Santulus on 27/12/21.
//

//
//  SerialExecutor.swift
//  fluetooth
//
//  Created by Iandi Santulus on 27/12/21.
//

import Foundation

class DeferredExecutor {

    private let _dispatcher: DispatchQueue = DispatchQueue(
        label: "fluetooth-executor",
        qos: .background
    )
    private var _tasks: [() throws -> Void] = []
    private var _activeTask: (() throws -> Void)?

    func now(_ callback: @escaping () throws -> Void) {
        _dispatcher.sync {
            try? callback()
        }
    }

    func add(
        onCompleteNext: Bool = false,
        _ callback: @escaping () throws -> Void
    ) {
        _tasks.append { [weak self] in
            try? callback()
            if onCompleteNext {
                self?.next()
            }
        }
        if _activeTask == nil {
            next()
        }
    }

    func delayed(
        onCompleteNext: Bool = true,
        deadline: DispatchTime,
        _ callback: @escaping () throws -> Void
    ) {
        _dispatcher.asyncAfter(deadline: deadline) { [weak self] in
            try? callback()
            if onCompleteNext {
                self?.next()
            }
        }
    }

    func next() {
        guard let task = _tasks.first else {
            _activeTask = nil
            return
        }

        _activeTask = task
        _tasks.removeFirst()

        do {
            try _activeTask?()
        } catch {
            print("Error executing task: \(error)")
        }
    }

    func clear() {
        _tasks = []
        _activeTask = nil
    }
}

