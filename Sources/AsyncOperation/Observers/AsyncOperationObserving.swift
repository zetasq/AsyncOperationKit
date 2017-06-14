//
//  AsyncOperationObserving.swift
//  AsyncOperationKit
//
//  Created by Zhu Shengqi on 08/06/2017.
//  Copyright © 2017 Zhu Shengqi. All rights reserved.
//

import Foundation

/**
 The protocol that types may implement if they wish to be notified of significant
 operation lifecycle events.
 */
public protocol AsyncOperationObserving {
  /// Invoked immediately prior to the `AsyncOperation`'s `execute()` method.
  func operationDidStart(_ operation: AsyncOperation)
  
  /// Invoked when `AsyncOperation.produceOperation(_:)` is executed.
  func operation(_ operation: AsyncOperation, didProduce newOperation: Operation)
  
  /**
   Invoked as an `AsyncOperation` finishes, along with any errors produced during
   execution (or readiness evaluation).
   */
  func operationDidFinish(_ operation: AsyncOperation, errors: [Error])
}

public extension AsyncOperationObserving {
  
  func operationDidStart(_ operation: AsyncOperation) {}
  
  func operation(_ operation: AsyncOperation, didProduce newOperation: Operation) {}
  
  func operationDidFinish(_ operation: AsyncOperation, errors: [Error]) {}

}
