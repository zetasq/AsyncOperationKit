//
//  Operation.swift
//  AsyncOperationKit
//
//  Created by Zhu Shengqi on 07/06/2017.
//  Copyright © 2017 Zhu Shengqi. All rights reserved.
//

import Foundation

extension Operation {
  
  public func addCompletion(_ block: @escaping () -> Void) {
    if let currentCompletionBlock = completionBlock {
      completionBlock = {
        currentCompletionBlock()
        block()
      }
    } else {
      completionBlock = block
    }
  }
  
  public func addDependencies(_ ops: [Operation]) {
    for op in ops {
      addDependency(op)
    }
  }
}
