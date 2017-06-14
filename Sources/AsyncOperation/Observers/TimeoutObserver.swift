//
//  TimeoutObserver.swift
//  AsyncOperationKit
//
//  Created by Zhu Shengqi on 08/06/2017.
//  Copyright © 2017 Zhu Shengqi. All rights reserved.
//

import Foundation

public struct TimeoutObserver: AsyncOperationObserving {
  // MARK: - Properties
  public static let timeoutKey = "Timeout"
  
  let timeout: TimeInterval
  
  // MARK: - AsyncOperationObserver
  public func operationDidStart(_ operation: AsyncOperation) {
    let when = DispatchTime.now() + timeout
    
    DispatchQueue.global().asyncAfter(deadline: when) {
      if !operation.isFinished && !operation.isCancelled {
        let error = NSError(code: .executionFailed, userInfo: [TimeoutObserver.timeoutKey: self.timeout])
        
        operation.cancel(with: error)
      }
    }
  }
}
