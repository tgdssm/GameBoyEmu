//
//  Input.swift
//  GameBoyEmu
//
//  Created by Thalisson Melo on 18/05/24.
//

import Foundation

class Input {
    private var memory: RAM

    // Botões do Game Boy
    enum Button: UInt8 {
        case right = 0x01
        case left = 0x02
        case up = 0x04
        case down = 0x08
        case a = 0x10
        case b = 0x20
        case select = 0x40
        case start = 0x80
    }

    init(memory: RAM) {
        self.memory = memory
    }

    func pressButton(_ button: Button) {
        let p1 = memory.ioRegisters[Int(RAM.P1 - 0xFF00)]
        memory.ioRegisters[Int(RAM.P1 - 0xFF00)] = p1 & ~button.rawValue
        requestInterrupt()
    }

    func releaseButton(_ button: Button) {
        let p1 = memory.ioRegisters[Int(RAM.P1 - 0xFF00)]
        memory.ioRegisters[Int(RAM.P1 - 0xFF00)] = p1 | button.rawValue
    }

    private func requestInterrupt() {
        memory.ioRegisters[Int(RAM.IF - 0xFF00)] |= RAM.I_P1
    }
}
