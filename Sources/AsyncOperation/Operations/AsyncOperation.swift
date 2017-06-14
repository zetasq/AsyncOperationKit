//
//  AsyncOperation.swift
//  AsyncOperationKit
//
//  Created by Zhu Shengqi on 07/06/2017.
//  Copyright © 2017 Zhu Shengqi. All rights reserved.
//

import Foundation

public class AsyncOperation: Operation {
  // MARK: - KVO Dependencies
  @objc
  static func keyPathsForValuesAffectingIsReady() -> Set<String> {
    return ["state"]
  }
  
  @objc
  static func keyPathsForValuesAffectingIsExecuting() -> Set<String> {
    return ["state"]
  }
  
  @objc
  static func keyPathsForValuesAffectingIsFinished() -> Set<String> {
    return ["state"]
  }
  
  // MARK: - State Management
  private var _state: State = .initialized
  private let stateLock = NSLock()
  
  private var state: State {
    get {
      return stateLock.withCriticalScope {
        _state
      }
    }
    
    set {
      /*
       It's important to note that the KVO notifications are NOT called from inside
       the lock. If they were, the app would deadlock, because in the middle of
       calling the `didChangeValueForKey()` method, the observers try to access
       properties like "isReady" or "isFinished". Since those methods also
       acquire the lock, then we'd be stuck waiting on our own lock. It's the
       classic definition of deadlock.
       */
      willChangeValue(forKey: "state")
      
      stateLock.withCriticalScope {
        guard _state != .finished else {
          return
        }
        
        assert(_state.canTransition(to: newValue), "Performing invalid state transition from \(_state) to \(newValue).")
        
        _state = newValue
      }
      
      didChangeValue(forKey: "state")
    }
  }
  
  /**
   Indicates that the Operation can now begin to evaluate readiness conditions,
   if appropriate.
   */
  func willEnqueue() {
    state = .pending
  }
  
  public override var isReady: Bool {
    switch state {
      
    case .initialized:
      // If the operation has been cancelled, "isReady" should return true
      return isCancelled
      
    case .pending:
      // If the operation has been cancelled, "isReady" should return true
      guard !isCancelled else {
        return true
      }
      
      // If super isReady, conditions can be evaluated
      if super.isReady {
        evaluateConditions()
      }
      
      // Until conditions have been evaluated, "isReady" returns false
      return false
      
    case .ready:
      return super.isReady || isCancelled
      
    default:
      return false
    }
  }
  
  var userInitiated: Bool {
    get {
      return qualityOfService == .userInitiated
    }
    
    set {
      assert(state < .executing, "Cannot modify userInitiated after execution has begun.")
      
      qualityOfService = newValue ? .userInitiated : .default
    }
  }
  
  public override var isExecuting: Bool {
    return state == .executing
  }
  
  public override var isFinished: Bool {
    return state == .finished
  }
  
  // MARK: - Observers and Conditions
  private(set) var conditions: [AsyncOperationConditional] = []
  private var _internalErrors: [Error] = []

  private func evaluateConditions() {
    assert(state == .pending && !isCancelled, "\(#function) was called out-of-order")
    
    state = .evaluatingConditions
    
    ConditionEvaluator().evaluate(conditions, operation: self) { failures in
      self._internalErrors.append(contentsOf: failures)
      self.state = .ready
    }
  }
  
  func add(_ condition: AsyncOperationConditional) {
    assert(state < .evaluatingConditions, "Cannot modify conditions after execution has begun. (state = \(state)")
    
    conditions.append(condition)
  }
  
  private(set) var observers: [AsyncOperationObserving] = []
  
  func add(_ observer: AsyncOperationObserving) {
    assert(state < .executing, "Cannot modify observers after execution has begun. (state = \(state)")
    
    observers.append(observer)
  }
  
  public override func addDependency(_ op: Operation) {
    assert(state < .executing, "Dependencies cannot be modified after execution has begun. (state = \(state)")
    
    super.addDependency(op)
  }
  
  // MARK: - Execution and Cancellation
  public override final func start() {
    // Operation.start() contains important logic that shouldn't be bypassed.
    super.start()
    
    if isCancelled {
      finish()
    }
  }
  
  public override final func main() {
    assert(state == .ready, "This operation must be performed on an operation queue.")
    
    if _internalErrors.isEmpty && !isCancelled {
      state = .executing
      
      for observer in observers {
        observer.operationDidStart(self)
      }
      
      execute()
    } else {
      finish()
    }
  }
  
  /**
   `execute()` is the entry point of execution for all `AsyncOperation` subclasses.
   If you subclass `AsyncOperation` and wish to customize its execution, you would
   do so by overriding the `execute()` method.
   
   At some point, your `AsyncOperation` subclass must call one of the "finish"
   methods defined below; this is how you indicate that your operation has
   finished its execution, and that operations dependent on yours can re-evaluate
   their readiness state.
   */
  public func execute() {
    assert(false, "\(type(of: self)) must override `execute()`.")
    
    finish()
  }
  
  func cancel(with error: Error? = nil) {
    if let error = error {
      _internalErrors.append(error)
    }
    
    cancel()
  }
  
  final func produce(_ op: Operation) {
    for observer in observers {
      observer.operation(self, didProduce: op)
    }
  }
  
  // MARK: - Finishing
  /**
   Most operations may finish with a single error, if they have one at all.
   This is a convenience method to simplify calling the actual `finish()`
   method. This is also useful if you wish to finish with an error provided
   by the system frameworks.
  */
  @nonobjc
  public final func finish(with error: Error?) {
    if let error = error {
      finish(with: [error])
    } else {
      finish()
    }
  }
  
  /**
   A private property to ensure we only notify the observers once that the
   operation has finished.
   */
  private var hasFinishedAlready = false
  
  @nonobjc
  public final func finish(with errors: [Error] = []) {
    guard !hasFinishedAlready else {
      return
    }
    
    hasFinishedAlready = true
    state = .finishing
    
    let combinedErrors = _internalErrors + errors
    finished(with: combinedErrors)
    
    for observer in observers {
      observer.operationDidFinish(self, errors: combinedErrors)
    }
    
    state = .finished
  }
  
  /**
   Subclasses may override `finished(with:)` if they wish to react to the operation
   finishing with errors.
   */
  func finished(with errors: [Error]) {
    // No op.
  }
  
  
  public override final func waitUntilFinished() {
    /*
     Waiting on operations is almost NEVER the right thing to do. It is
     usually superior to use proper locking constructs, such as `dispatch_semaphore_t`
     or `dispatch_group_notify`, or even `NSLocking` objects. Many developers
     use waiting when they should instead be chaining discrete operations
     together using dependencies.
     
     To reinforce this idea, invoking `waitUntilFinished()` will crash your
     app, as incentive for you to find a more appropriate way to express
     the behavior you're wishing to create.
     */
    fatalError("Waiting on operations is an anti-pattern. Remove this ONLY if you're absolutely sure there is No Other Way™.")
  }
  
}
