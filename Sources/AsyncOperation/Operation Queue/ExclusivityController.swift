//
//  ExclusivityController.swift
//  AsyncOperationKit
//
//  Created by Zhu Shengqi on 08/06/2017.
//  Copyright © 2017 Zhu Shengqi. All rights reserved.
//

import Foundation

/**
 `ExclusivityController` is a singleton to keep track of all the in-flight
 `AsyncOperation` instances that have declared themselves as requiring mutual exclusivity.
 We use a singleton because mutual exclusivity must be enforced across the entire
 app, regardless of the `AsyncOperationQueue` on which an `AsyncOperation` was executed.
 */

public final class ExclusivityController {
  public static let shared = ExclusivityController()
  
  private let serialQueue = DispatchQueue(label: "AsyncOperationKit.ExclusivityController")
  
  private var operations: [String: [AsyncOperation]] = [:]
  
  private init() {}
  
  /// Register an operation as being mutually exclusive
  public func add(_ operation: AsyncOperation, categories: [String]) {
    /*
     This needs to be a synchronous operation.
     If this were async, then we might not get around to adding dependencies
     until after the operation had already begun, which would be incorrect.
     */
    serialQueue.sync {
      for category in categories {
        self.noqueue_add(operation, category: category)
      }
    }
  }
  
  /// Unregister an operation from being mutually exclusive.
  public func remove(_ operation: AsyncOperation, categories: [String]) {
    serialQueue.async {
      for category in categories {
        self.noqueue_remove(operation, category: category)
      }
    }
  }
  
  // MARK: - Operation Management
  private func noqueue_add(_ operation: AsyncOperation, category: String) {
    var operationsWithThisCategory = operations[category] ?? []
    
    if let last = operationsWithThisCategory.last {
      operation.addDependency(last)
    }
    
    operationsWithThisCategory.append(operation)
    
    operations[category] = operationsWithThisCategory
  }
  
  private func noqueue_remove(_ operation: AsyncOperation, category: String) {
    let matchingOperations = operations[category]
    
    if var operationsWithThisCategory = matchingOperations, let index = operationsWithThisCategory.index(of: operation) {
      
      operationsWithThisCategory.remove(at: index)
      operations[category] = operationsWithThisCategory
    }
  }
}
