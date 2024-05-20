//
//  Timer.swift
//  GameBoyEmu
//
//  Created by Thalisson Melo on 20/05/24.
//

import Foundation

class Timer {
    private let ram: RAM
    private var cycles: UInt32 = 0
    private var divCounter: UInt16 = 0
    private var timerCounter: UInt16 = 0
    
    // Constants for timer control
    private struct TimerControl {
        static let EnableMask: UInt8 = 0x04
        static let InputClockSelectMask: UInt8 = 0x03
        
        static let InputClockCycles: [UInt16] = [1024, 16, 64, 256]
    }
    
    init(ram: RAM) {
        self.ram = ram
    }
    
    func step(cycles: UInt32) {
        self.cycles += cycles
        
        // Update DIV register (increments every 256 cycles)
        divCounter += UInt16(cycles)
        if divCounter >= 256 {
            divCounter -= 256
            ram.ioRegisters[Int(RAM.DIV - 0xFF00)] &+= 1
        }
        
        // Check if timer is enabled
        let tac = ram.ioRegisters[Int(RAM.TAC - 0xFF00)]
        if tac & TimerControl.EnableMask != 0 {
            // Timer is enabled, update TIMA register based on selected frequency
            let inputClockSelect = tac & TimerControl.InputClockSelectMask
            let inputClockCycles = TimerControl.InputClockCycles[Int(inputClockSelect)]
            
            timerCounter += UInt16(cycles)
            if timerCounter >= inputClockCycles {
                timerCounter -= inputClockCycles
                
                var tima = ram.ioRegisters[Int(RAM.TIMA - 0xFF00)]
                tima &+= 1
                if tima == 0 {
                    // Timer overflow, set TIMA to TMA and request interrupt
                    tima = ram.ioRegisters[Int(RAM.TMA - 0xFF00)]
                    ram.ioRegisters[Int(RAM.IF - 0xFF00)] |= RAM.I_TIMER
                }
                ram.ioRegisters[Int(RAM.TIMA - 0xFF00)] = tima
            }
        }
    }
    
    func reset() {
        cycles = 0
        divCounter = 0
        timerCounter = 0
    }
}
