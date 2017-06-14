//
//  OperationError.swift
//  AsyncOperationKit
//
//  Created by Zhu Shengqi on 08/06/2017.
//  Copyright © 2017 Zhu Shengqi. All rights reserved.
//

import Foundation

extension AsyncOperation {
  enum ErrorCode: Int {
    case conditionFailed = 1
    case executionFailed = 2
  }
  
  static let errorDomain = "\(AsyncOperation.self)Errors"
}

extension NSError {
  convenience init(code: AsyncOperation.ErrorCode, userInfo: [AnyHashable: Any]? = nil) {
    self.init(domain: AsyncOperation.errorDomain, code: code.rawValue, userInfo: userInfo)
  }
}

func ==(lhs: Int, rhs: AsyncOperation.ErrorCode) -> Bool {
  return lhs == rhs.rawValue
}

func ==(lhs: AsyncOperation.ErrorCode, rhs: Int) -> Bool {
  return lhs.rawValue == rhs
}
