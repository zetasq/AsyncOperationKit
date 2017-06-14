//
//  AsyncOperation+State.swift
//  AsyncOperationKit
//
//  Created by Zhu Shengqi on 07/06/2017.
//  Copyright © 2017 Zhu Shengqi. All rights reserved.
//

import Foundation

extension AsyncOperation {
  enum State: Int, Comparable {
    /// The initial state of an `Operation`.
    case initialized
    
    /// The `AsyncOperation` is ready to begin evaluating conditions.
    case pending
    
    /// The `AsyncOperation` is evaluating conditions.
    case evaluatingConditions
    
    /**
     The `AsyncOperation`'s conditions have all been satisfied, and it is ready
     to execute.
     */
    case ready
    
    /// The `AsyncOperation` is executing.
    case executing
    
    /**
     Execution of the `AsyncOperation` has finished, but it has not yet notified
     the queue of this.
     */
    case finishing
    
    /// The `Operation` has finished executing.
    case finished
    
    func canTransition(to targetState: State) -> Bool {
      switch (self, targetState) {
      case (.initialized, .pending):
        return true
      case (.pending, .evaluatingConditions):
        return true
      case (.evaluatingConditions, .ready):
        return true
      case (.ready, .executing):
        return true
      case (.ready, .finishing):
        return true
      case (.executing, .finishing):
        return true
      case (.finishing, .finished):
        return true
      default:
        return false
      }
    }
  }
}

// Simple operator functions to simplify the assertions used above.
func <(lhs: AsyncOperation.State, rhs: AsyncOperation.State) -> Bool {
  return lhs.rawValue < rhs.rawValue
}

func ==(lhs: AsyncOperation.State, rhs: AsyncOperation.State) -> Bool {
  return lhs.rawValue == rhs.rawValue
}
