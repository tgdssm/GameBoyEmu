//
//  RAM.swift
//  GameBoyEmu
//
//  Created by Thalisson Melo on 14/05/24.
//

import Foundation

class RAM {
    static let P1: UInt16 = 0xFF00 // Joypad input
    static let SB: UInt16 = 0xFF01 // Serial transfer data
    static let SC: UInt16 = 0xFF02 // Serial transfer control
    static let DIV: UInt16 = 0xFF04 // Divider register
    static let TIMA: UInt16 = 0xFF05 // Timer counter
    static let TMA: UInt16 = 0xFF06 // Timer modulo
    static let TAC: UInt16 = 0xFF07 // Timer control
    
    
}
