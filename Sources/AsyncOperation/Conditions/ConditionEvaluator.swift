//
//  ConditionEvaluator.swift
//  AsyncOperationKit
//
//  Created by Zhu Shengqi on 07/06/2017.
//  Copyright © 2017 Zhu Shengqi. All rights reserved.
//

import Foundation

extension AsyncOperation {
  struct ConditionEvaluator {
    func evaluate(_ conditions: [AsyncOperationConditional], operation: AsyncOperation, completion: @escaping ([Error]) -> Void) {
      // Check conditions
      let conditionGroup = DispatchGroup()
      
      var results: [AsyncOperation.ConditionResult?] = Array(repeating: nil, count: conditions.count)
      
      // Ask each condition to evaluate and store its result in the "results" array.
      for (index, condition) in conditions.enumerated() {
        conditionGroup.enter()
        condition.evaluate(for: operation) { result in
          // TODO: will results be acccessed from multiple thread?
          results[index] = result
          conditionGroup.leave()
        }
      }
      
      // After all the conditions have evaluated, this block will execute.
      conditionGroup.notify(queue: .global()) { 
        // Aggregate the errors that occurred, in order
        var failures = results.flatMap { $0?.error }
        
        // if any of the conditions caused this operation to be cancelled, check for that
        if operation.isCancelled {
          failures.append(NSError(code: .conditionFailed))
        }
        
        completion(failures)
      }
    }
  }
}
