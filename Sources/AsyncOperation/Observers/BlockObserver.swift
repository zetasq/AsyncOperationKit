//
//  BlockObserver.swift
//  AsyncOperationKit
//
//  Created by Zhu Shengqi on 08/06/2017.
//  Copyright © 2017 Zhu Shengqi. All rights reserved.
//

import Foundation

public struct BlockObserver: AsyncOperationObserving {
  // MARK: - Properties
  
  private let startHandler: ((AsyncOperation) -> Void)?
  private let produceHandler: ((AsyncOperation, Operation) -> Void)?
  private let finishHandler: ((AsyncOperation, [Error]) -> Void)?
  
  public init(startHandler: ((AsyncOperation) -> Void)? = nil, produceHandler: ((AsyncOperation, Operation) -> Void)? = nil, finishHandler: ((AsyncOperation, [Error]) -> Void)? = nil) {
    self.startHandler = startHandler
    self.produceHandler = produceHandler
    self.finishHandler = finishHandler
  }
  
  // MARK: - AsyncOperationObserver
  public func operationDidStart(_ operation: AsyncOperation) {
    startHandler?(operation)
  }
  
  public func operation(_ operation: AsyncOperation, didProduce newOperation: Operation) {
    produceHandler?(operation, newOperation)
  }
  
  public func operationDidFinish(_ operation: AsyncOperation, errors: [Error]) {
    finishHandler?(operation, errors)
  }
}
