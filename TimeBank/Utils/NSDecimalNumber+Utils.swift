//
//  NSDecimalNumber+Utils.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/9/3.
//  Copyright © 2018年 Tokenmama.io. All rights reserved.
//

import Foundation

// MARK: - Equivalence
extension NSDecimalNumber: Comparable {
}

public func == (left: NSDecimalNumber, right: NSDecimalNumber) -> Bool {
    return left.isEqual(to: right)
}

public func < (left: NSDecimalNumber, right: NSDecimalNumber) -> Bool {
    return left.compare(right) == ComparisonResult.orderedAscending
}


// MARK: - Addition
public prefix func + (value: NSDecimalNumber) -> NSDecimalNumber {
    return value
}

public func + (left: NSDecimalNumber, right: NSDecimalNumber) -> NSDecimalNumber {
    return left.adding(right)
}

public func += ( left: inout NSDecimalNumber, right: NSDecimalNumber) {
    left = left + right
}

public prefix func ++ ( value: inout NSDecimalNumber) -> NSDecimalNumber {
    value += NSDecimalNumber.one
    return value
}

public postfix func ++ ( value: inout NSDecimalNumber) -> NSDecimalNumber {
    let result = value
    ++value
    return result
}

// MARK: Overflow
public func &+ (left: NSDecimalNumber, right: NSDecimalNumber) -> NSDecimalNumber {
    return left.adding(right, withBehavior: LenientDecimalNumberHandler)
}


// MARK: - Subtraction
public prefix func - (value: NSDecimalNumber) -> NSDecimalNumber {
    return value * NSDecimalNumber.minusOne
}

public func - (left: NSDecimalNumber, right: NSDecimalNumber) -> NSDecimalNumber {
    return left.subtracting(right)
}

public func -= ( left: inout NSDecimalNumber, right: NSDecimalNumber) {
    left = left - right
}

public prefix func -- ( value: inout NSDecimalNumber) -> NSDecimalNumber {
    value -= NSDecimalNumber.one
    return value
}

public postfix func -- ( value: inout NSDecimalNumber) -> NSDecimalNumber {
    let result = value
    --value
    return result
}

// MARK: Overflow
public func &- (left: NSDecimalNumber, right: NSDecimalNumber) -> NSDecimalNumber {
    return left.subtracting(right, withBehavior: LenientDecimalNumberHandler)
}


// MARK: - Multiplication
public func * (left: NSDecimalNumber, right: NSDecimalNumber) -> NSDecimalNumber {
    return left.multiplying(by: right)
}

public func *= ( left: inout NSDecimalNumber, right: NSDecimalNumber) {
    left = left * right
}

// MARK: Overflow
public func &* (left: NSDecimalNumber, right: NSDecimalNumber) -> NSDecimalNumber {
    return left.multiplying(by: right, withBehavior: LenientDecimalNumberHandler)
}


// MARK: - Division
public func / (left: NSDecimalNumber, right: NSDecimalNumber) -> NSDecimalNumber {
    return left.dividing(by: right)
}

public func /= ( left: inout NSDecimalNumber, right: NSDecimalNumber) {
    left = left / right
}


// MARK: - Powers
/// Give greater precedence than multiplication
infix operator **: Powers
precedencegroup Powers {
    associativity: left
    higherThan: MultiplicationPrecedence
}

/// Power
public func ** (left: NSDecimalNumber, right: Int) -> NSDecimalNumber {
    return left.raising(toPower: right)
}

/// Match all assignment operators
infix operator **=: PowersMatch
precedencegroup PowersMatch {
    associativity: right
    higherThan: AssignmentPrecedence
}

/// 2 **= 2 will return 4
public func **= ( left: inout NSDecimalNumber, right: Int) {
    left = left ** right
}

// MARK: Overflow
// Match the power operator
infix operator &**: Powers

public func &** (left: NSDecimalNumber, right: Int) -> NSDecimalNumber {
    return left.raising(toPower: right, withBehavior: LenientDecimalNumberHandler)
}


// MARK: - Other
private let LenientDecimalNumberHandler: NSDecimalNumberBehaviors = NSDecimalNumberHandler(roundingMode: NSDecimalNumberHandler.default.roundingMode(), scale: NSDecimalNumberHandler.default.scale(), raiseOnExactness: false, raiseOnOverflow: false, raiseOnUnderflow: false, raiseOnDivideByZero: false)

public extension NSDecimalNumber {
    
    /// -1
    public class var minusOne: NSDecimalNumber {
        struct Lazily {
            static let minusOne = NSDecimalNumber.zero - NSDecimalNumber.one
        }
        return Lazily.minusOne
    }
    
    public func isNaN() -> Bool {
        return self == NSDecimalNumber.notANumber
    }
    
    public func abs() -> NSDecimalNumber {
        
        if (self.isNaN()) {
            return NSDecimalNumber.notANumber
        }
        
        if (self >= NSDecimalNumber.zero) {
            return self
        } else {
            return -self
        }
    }
}

// MARK: - Rounding
private let VaraibleDecimalNumberHandler: (_ roundingMode: NSDecimalNumber.RoundingMode, _ scale: Int16) -> NSDecimalNumberBehaviors = { (roundingMode, scale) -> NSDecimalNumberHandler in
    
    return NSDecimalNumberHandler(roundingMode: roundingMode, scale: scale, raiseOnExactness: false, raiseOnOverflow: true, raiseOnUnderflow: true, raiseOnDivideByZero: true)
}

public extension NSDecimalNumber.RoundingMode {
    
    public func round(value: NSDecimalNumber, scale: Int16) -> NSDecimalNumber {
        return value.rounding(accordingToBehavior: VaraibleDecimalNumberHandler(self, scale))
    }
}


// MARK: - Creation
public extension String {
    
    /// @warning Uses NSDecimalNumber(string:)
    public var decimalNumber: NSDecimalNumber {
        return NSDecimalNumber(string: self)
    }
}
