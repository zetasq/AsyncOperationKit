//
//  Lock.swift
//  AsyncOperationKit
//
//  Created by Zhu Shengqi on 07/06/2017.
//  Copyright © 2017 Zhu Shengqi. All rights reserved.
//

import Foundation

extension NSLock {
  public func withCriticalScope<T>(_ block: () -> T) -> T {
    lock()
    let value = block()
    unlock()
    return value
  }
}

extension NSRecursiveLock {
  public func withCriticalScope<T>(_ block: () -> T) -> T {
    lock()
    let value = block()
    unlock()
    return value
  }
}
