//
//  ConditionResult.swift
//  AsyncOperationKit
//
//  Created by Zhu Shengqi on 07/06/2017.
//  Copyright © 2017 Zhu Shengqi. All rights reserved.
//

import Foundation

extension AsyncOperation {

  enum ConditionResult: Equatable {
    case satisfied
    case failed(Error)
    
    var error: Error? {
      switch self {
      case .satisfied:
        return nil
      case .failed(let error):
        return error
      }
    }
    
    static let OperationConditionKey = "OperationCondition"
  }
}


func ==(lhs: AsyncOperation.ConditionResult, rhs: AsyncOperation.ConditionResult) -> Bool {
  switch (lhs, rhs) {
  case (.satisfied, .satisfied):
    return true
  case (.failed(let lError as NSError), .failed(let rError as NSError)) where lError == rError:
    return true
  default:
    return false
  }
}
