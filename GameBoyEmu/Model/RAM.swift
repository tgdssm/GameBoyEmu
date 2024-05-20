//
//  RAM.swift
//  GameBoyEmu
//
//  Created by Thalisson Melo on 14/05/24.
//

import Foundation

class RAM {
    // Video registers
    static let LCDC: UInt16 = 0xFF40 // LCD control
    static let STAT: UInt16 = 0xFF41 // LCD status
    static let SCY: UInt16 = 0xFF42 // Scroll vertical
    static let SCX: UInt16 = 0xFF43 // Scroll horizontal
    static let WY: UInt16 = 0xFF4A // Window Y position
    static let WX: UInt16 = 0xFF4B // Window X position
    static let LY: UInt16 = 0xFF44 // LCD Y coordinate
    static let LYC: UInt16 = 0xFF45 // LY compare
    static let DMA: UInt16 = 0xFF46 // DMA transfer
    static let BGP: UInt16 = 0xFF47 // BG palette data
    static let OBP0: UInt16 = 0xFF48 // OBJ palette 0
    static let OBP1: UInt16 = 0xFF49 // OBJ palette 1
    
    // I/O registers
    static let P1: UInt16 = 0xFF00 // Joypad input
    static let SB: UInt16 = 0xFF01 // Serial transfer data
    static let SC: UInt16 = 0xFF02 // Serial transfer control
    
    // Timing registers
    static let DIV: UInt16 = 0xFF04 // Divider register
    static let TIMA: UInt16 = 0xFF05 // Timer counter
    static let TMA: UInt16 = 0xFF06 // Timer modulo
    static let TAC: UInt16 = 0xFF07 // Timer control
    
    // Interrupts
    static let IE: UInt16 = 0xFFFF // Interrupt enable
    static let IF: UInt16 = 0xFF0F // Interrupt flag
    static let I_VBLANK: UInt8 = 0x01 // V-Blank interrupt
    static let I_LCDC: UInt8 = 0x02 // LCDC interrupt
    static let I_TIMER: UInt8 = 0x04 // Timer interrupt
    static let I_SERIAL: UInt8 = 0x08 // Serial interrupt
    static let I_P1: UInt8 = 0x10 // Joypad interrupt
    
    // Memory areas
    var wram = [UInt8](repeating: 0, count: 0x2000) // 8 KB Work RAM
    var vram = [UInt8](repeating: 0, count: 0x2000) // 8 KB Video RAM
    var oam = [UInt8](repeating: 0, count: 0xA0)   // 160 bytes OAM
    var hram = [UInt8](repeating: 0, count: 0x7F)  // 127 bytes High RAM
    var ioRegisters = [UInt8](repeating: 0, count: 0x80) // 128 bytes I/O registers
    
    // Cartridge data placeholders
    var rom = [UInt8](repeating: 0, count: 0x8000) // Placeholder for ROM data
    var externalRam = [UInt8](repeating: 0, count: 0x2000) // Placeholder for external RAM

    // Jumps (exemplos)
    static let JUMP_RESET: UInt16 = 0x0100 // Reset jump
    static let JUMP_VBLANK: UInt16 = 0x0040 // V-Blank interrupt vector
    static let JUMP_LCDC: UInt16 = 0x0048 // LCDC interrupt vector
    static let JUMP_TIMER: UInt16 = 0x0050 // Timer interrupt vector
    static let JUMP_SERIAL: UInt16 = 0x0058 // Serial interrupt vector
    static let JUMP_P1: UInt16 = 0x0060 // Joypad interrupt vector
    
    func readByte(at address: UInt16) -> UInt8 {
        switch address {
        case 0x0000...0x7FFF:
            // ROM (handled by the cartridge)
            return rom[Int(address)]
        case 0x8000...0x9FFF:
            // VRAM
            return vram[Int(address - 0x8000)]
        case 0xA000...0xBFFF:
            // External RAM (handled by the cartridge)
            return externalRam[Int(address - 0xA000)]
        case 0xC000...0xDFFF:
            // Work RAM
            return wram[Int(address - 0xC000)]
        case 0xFE00...0xFE9F:
            // OAM
            return oam[Int(address - 0xFE00)]
        case 0xFF00...0xFF7F:
            // I/O registers
            return ioRegisters[Int(address - 0xFF00)]
        case 0xFF80...0xFFFE:
            // High RAM
            return hram[Int(address - 0xFF80)]
        case 0xFFFF:
            // Interrupt Enable Register
            return ioRegisters[0x7F]
        default:
            return 0xFF // Unused memory returns 0xFF
        }
    }
    
    func writeByte(_ value: UInt8, at address: UInt16) {
        switch address {
        case 0x0000...0x7FFF:
            // ROM (handled by the cartridge)
            break // Placeholder
        case 0x8000...0x9FFF:
            // VRAM
            vram[Int(address - 0x8000)] = value
        case 0xA000...0xBFFF:
            // External RAM (handled by the cartridge)
            externalRam[Int(address - 0xA000)] = value
        case 0xC000...0xDFFF:
            // Work RAM
            wram[Int(address - 0xC000)] = value
        case 0xFE00...0xFE9F:
            // OAM
            oam[Int(address - 0xFE00)] = value
        case 0xFF00...0xFF7F:
            // I/O registers
            ioRegisters[Int(address - 0xFF00)] = value
        case 0xFF80...0xFFFE:
            // High RAM
            hram[Int(address - 0xFF80)] = value
        case 0xFFFF:
            // Interrupt Enable Register
            ioRegisters[0x7F] = value
        default:
            break // Unused memory
        }
    }
    
    func readBytes(at address: UInt16, length: UInt16) -> [UInt8] {
        var bytes = [UInt8]()
        for i in 0..<length {
            bytes.append(readByte(at: address + i))
        }
        return bytes
    }
    
    func writeBytes(_ values: [UInt8], at address: UInt16) {
        for (offset, value) in values.enumerated() {
            writeByte(value, at: address + UInt16(offset))
        }
    }

    // DMA Transfer (Direct Memory Access)
    func dmaTransfer(from source: UInt8) {
        let sourceAddress = UInt16(source) << 8
        for i in 0..<0xA0 {
            let data = readByte(at: sourceAddress + UInt16(i))
            writeByte(data, at: 0xFE00 + UInt16(i))
        }
    }
}
