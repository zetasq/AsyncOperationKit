//
//  Dictionary.swift
//  AsyncOperationKit
//
//  Created by Zhu Shengqi on 07/06/2017.
//  Copyright © 2017 Zhu Shengqi. All rights reserved.
//

import Foundation

extension Dictionary {
  init<S: Sequence>(sequence: S, keyMapper: (Value) -> Key?)
    where S.Iterator.Element == Value {
      self.init()
      
      for item in sequence {
        if let key = keyMapper(item) {
          self[key] = item
        }
      }
  }
}
