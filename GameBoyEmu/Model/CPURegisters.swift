//
//  CPURegisters.swift
//  GameBoyEmu
//
//  Created by Thalisson Melo on 13/05/24.
//

import Foundation

class CPURegisters {
    var A: UInt8 = 0
    var F: UInt8 = 0
    var B: UInt8 = 0
    var C: UInt8 = 0
    var D: UInt8 = 0
    var E: UInt8 = 0
    var H: UInt8 = 0
    var L: UInt8 = 0
    
    var PC: UInt16 = 0
    var SP: UInt16 = 0
    
    var AF : UInt16 {
        get { return UInt16(A) << 8 | UInt16(F) }
        set {
            A = UInt8(newValue >> 8)
            F = UInt8(newValue & 0xFF)
        }
    }
    
    var BC : UInt16 {
        get { return UInt16(B) << 8 | UInt16(C) }
        set {
            B = UInt8(newValue >> 8)
            C = UInt8(newValue & 0xFF)
        }
    }
    
    var DE : UInt16 {
        get { return UInt16(D) << 8 | UInt16(E) }
        set {
            D = UInt8(newValue >> 8)
            E = UInt8(newValue & 0xFF)
        }
    }
    
    var HL : UInt16 {
        get { return UInt16(H) << 8 | UInt16(L) }
        set {
            H = UInt8(newValue >> 8)
            L = UInt8(newValue & 0xFF)
        }
    }
    
    var zeroFlag: Bool {
        get { return F & 0b10000000 != 0 }
        set {
            if newValue {
                F |= 0b10000000
            } else {
                F &= ~0b10000000
            }
        }
    }
    
    var negativeFlag: Bool {
        get { return F & 0b01000000 != 0 }
        set {
            if newValue {
                F |= 0b01000000
            } else {
                F &= ~0b01000000
            }
        }
    }
    
    var halfCarryFlag: Bool {
        get { return F & 0b00100000 != 0 }
        set {
            if newValue {
                F |= 0b00100000
            } else {
                F &= ~0b00100000
            }
        }
    }
    
    var carryFlag: Bool {
        get { return F & 0b00010000 != 0 }
        set {
            if newValue {
                F |= 0b00010000
            } else {
                F &= ~0b00010000
            }
        }
    }
    
    func reset() {
        A = UInt8(0)
        F = UInt8(0)
        B = UInt8(0)
        C = UInt8(0)
        D = UInt8(0)
        E = UInt8(0)
        H = UInt8(0)
        L = UInt8(0)
        SP = UInt16(0)
        PC = UInt16(0)
    }
}
