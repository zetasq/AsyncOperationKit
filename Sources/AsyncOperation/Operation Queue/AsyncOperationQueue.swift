//
//  AsyncOperationQueue.swift
//  AsyncOperationKit
//
//  Created by Zhu Shengqi on 08/06/2017.
//  Copyright © 2017 Zhu Shengqi. All rights reserved.
//

import Foundation

public protocol AsyncOperationQueueDelegate: class {
  
  func operationQueue(_ operationQueue: AsyncOperationQueue, willAdd operation: Operation)
  
  func operationQueue(_ operationQueue: AsyncOperationQueue, operationDidFinish operation: Operation, with errors: [Error])
  
}

public extension AsyncOperationQueueDelegate {
  
  func operationQueue(_ operationQueue: AsyncOperationQueue, willAdd operation: Operation) {}
  
  func operationQueue(_ operationQueue: AsyncOperationQueue, operationDidFinish operation: Operation, with errors: [Error]) {}
  
}

/**
 `AsyncOperationQueue` is an `OperationQueue` subclass that implements a large
 number of "extra features" related to the `AsyncOperation` class:
 
 - Notifying a delegate of all operation completion
 - Extracting generated dependencies from operation conditions
 - Setting up dependencies to enforce mutual exclusivity
 */
public final class AsyncOperationQueue: OperationQueue {
  
  public weak var delegate: AsyncOperationQueueDelegate?
  
  public override func addOperation(_ op: Operation) {
    if let asyncOperation = op as? AsyncOperation {
      // Set up a `BlockObserver` to invoke the `AsyncOperationQueueDelegate` method.
      let proxyObserver = BlockObserver(
        startHandler: nil,
        produceHandler: { [weak self] in
          self?.addOperation($1)
        }, finishHandler: { [weak self] in
          if let strongSelf = self {
            strongSelf.delegate?.operationQueue(strongSelf, operationDidFinish: $0, with: $1)
          }
        }
      )
      
      asyncOperation.add(proxyObserver)
      
      let dependencies = asyncOperation.conditions.flatMap {
        $0.dependency(for: asyncOperation)
      }
      
      for dependency in dependencies {
        asyncOperation.addDependency(dependency)
        
        addOperation(dependency)
      }
      
      /*
       With condition dependencies added, we can now see if this needs
       dependencies to enforce mutual exclusivity.
       */
      let concurrencyCatogories: [String] = asyncOperation.conditions.flatMap { condition in
        if !type(of: condition).isMutuallyExclusive { return nil }
        
        return "\(type(of: condition))"
      }
      
      if !concurrencyCatogories.isEmpty {
        // Setup the mutual exclusivity dependencies.
        let exclusivityController = ExclusivityController.shared
        
        exclusivityController.add(asyncOperation, categories: concurrencyCatogories)
        
        asyncOperation.add(
          BlockObserver(startHandler: nil, produceHandler: nil, finishHandler: { operation, _ in
            exclusivityController.remove(operation, categories: concurrencyCatogories)
          })
        )
        
        /*
         Indicate to the operation that we've finished our extra work on it
         and it's now it a state where it can proceed with evaluating conditions,
         if appropriate.
         */
        asyncOperation.willEnqueue()
      }
    } else {
      // TODO: Test if the operation is strongly referencing itself after completion, which is memory leak. If so, add [weak self, weak op]
      op.addCompletion {
        self.delegate?.operationQueue(self, operationDidFinish: op, with: [])
      }
    }
    
    delegate?.operationQueue(self, willAdd: op)
    super.addOperation(op)
  }
  
  public override func addOperations(_ ops: [Operation], waitUntilFinished wait: Bool) {
    /*
     The base implementation of this method does not call `addOperation()`,
     so we'll call it ourselves.
     */
    for operation in operations {
      addOperation(operation)
    }
    
    if wait {
      for operation in operations {
        operation.waitUntilFinished()
      }
    }
  }
}
