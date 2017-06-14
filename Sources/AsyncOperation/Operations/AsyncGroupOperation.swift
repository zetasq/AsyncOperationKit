//
//  AsyncGroupOperation.swift
//  AsyncOperationKit
//
//  Created by Zhu Shengqi on 13/06/2017.
//  Copyright © 2017 Zhu Shengqi. All rights reserved.
//

import Foundation

/**
 A subclass of `AsyncOperation` that executes zero or more operations as part of its
 own execution. This class of operation is very useful for abstracting several
 smaller operations into a larger operation.
 
 Additionally, `AsyncGroupOperation`s are useful if you establish a chain of dependencies,
 but part of the chain may "loop". For example, if you have an operation that
 requires the user to be authenticated, you may consider putting the "login"
 operation inside a group operation. That way, the "login" operation may produce
 subsequent operations (still within the outer `GroupOperation`) that will all
 be executed before the rest of the operations in the initial chain of operations.
 */
public final class AsyncGroupOperation: AsyncOperation {
  fileprivate let internalQueue = AsyncOperationQueue()
  fileprivate let startingOperation = BlockOperation(block: {})
  fileprivate let finishingOperation = BlockOperation(block: {})
  
  fileprivate var aggregatedErrors: [Error] = []
  
  public init(operations: [Operation]) {
    super.init()
    
    internalQueue.isSuspended = true
    //internalQueue.delegate = self
    internalQueue.addOperation(startingOperation)
    
    for operation in operations {
      internalQueue.addOperation(operation)
    }
  }
  
  public override func cancel() {
    internalQueue.cancelAllOperations()
    super.cancel()
  }
  
  public override func execute() {
    internalQueue.isSuspended = false
    internalQueue.addOperation(finishingOperation)
  }
  
  public func add(_ operation: Operation) {
    internalQueue.addOperation(operation)
  }
  
  /**
   Note that some part of execution has produced an error.
   Errors aggregated through this method will be included in the final array
   of errors reported to observers and to the `finished(_:)` method.
   */
  public func aggregate(_ error: Error) {
    aggregatedErrors.append(error)
  }
  
  
}
