//
//  AsyncBlockOperation.swift
//  AsyncOperationKit
//
//  Created by Zhu Shengqi on 08/06/2017.
//  Copyright © 2017 Zhu Shengqi. All rights reserved.
//

import Foundation

/// A sublcass of `AsyncOperation` to execute a closure.
public final class AsyncBlockOperation: AsyncOperation {
  public typealias OperationBlock = (@escaping () -> Void) -> Void
  
  private let block: OperationBlock?
  
  /**
   The designated initializer.
   
   - parameter block: The closure to run when the operation executes. This
   closure will be run on an arbitrary queue. The parameter passed to the
   block **MUST** be invoked by your code, or else the `AsyncBlockOperation`
   will never finish executing. If this parameter is `nil`, the operation
   will immediately finish.
   */
  public init(block: OperationBlock? = nil) {
    self.block = block
    super.init()
  }
  
  /**
   A convenience initializer to execute a block on the main queue.
   
   - parameter mainQueueBlock: The block to execute on the main queue. Note
   that this block does not have a "continuation" block to execute (unlike
   the designated initializer). The operation will be automatically ended
   after the `mainQueueBlock` is executed.
   */
  public convenience init(mainQueueBlock: @escaping () -> Void) {
    self.init(block: { continuation in
      DispatchQueue.main.async {
        mainQueueBlock()
        continuation()
      }
    })
  }
  
  public override func execute() {
    guard let block = block else {
      finish()
      return
    }
    
    block {
      self.finish()
    }
  }
}
