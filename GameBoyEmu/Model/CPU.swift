//  CPU.swift
//  GameBoyEmu
//
//  Created by Thalisson Melo on 14/05/24.
//

import Foundation

class CPU {
    var registers: CPURegisters = CPURegisters()
    var memory: RAM
    var timer: Timer
    var apu: APU
    var ppu: PPU
    var input: Input
    var halted: Bool = false
    var ime: Bool = true // Interrupt Master Enable

    private var opcodeTable: [UInt8: (CPU) -> UInt32] = [:]  // The function now returns the consumed cycles

    init(memory: RAM) {
        self.memory = memory
        self.timer = Timer(ram: memory)
        self.apu = APU(memory: memory)
        self.ppu = PPU(memory: memory)
        self.input = Input(memory: memory)
        initializeOpcodeTable()
    }

    private func initializeOpcodeTable() {
        opcodeTable = [
            0x00: { cpu in return 4 }, // NOP
            0x01: { cpu in let value = cpu.read16Bits(); cpu.registers.BC = value; return 12 }, // LD BC, nn
            0x02: { cpu in let address = cpu.registers.BC; cpu.memory.writeByte(cpu.registers.A, at: address); return 8 }, // LD (BC), A
            0x03: { cpu in cpu.registers.BC &+= 1; return 8 }, // INC BC
            0x06: { cpu in let value = cpu.readByte(); cpu.registers.B = value; return 8 }, // LD B, n
            0x0E: { cpu in let value = cpu.readByte(); cpu.registers.C = value; return 8 }, // LD C, n
            0x11: { cpu in let value = cpu.read16Bits(); cpu.registers.DE = value; return 12 }, // LD DE, nn
            0x12: { cpu in let address = cpu.registers.DE; cpu.memory.writeByte(cpu.registers.A, at: address); return 8 }, // LD (DE), A
            0x16: { cpu in let value = cpu.readByte(); cpu.registers.D = value; return 8 }, // LD D, n
            0x1A: { cpu in let address = cpu.registers.DE; cpu.registers.A = cpu.memory.readByte(at: address); return 8 }, // LD A, (DE)
            0x1E: { cpu in let value = cpu.readByte(); cpu.registers.E = value; return 8 }, // LD E, n
            0x20: { cpu in let offset = Int8(bitPattern: cpu.readByte()); if !cpu.registers.zeroFlag { cpu.registers.PC = UInt16(Int(cpu.registers.PC) + Int(offset)); return 12 } else { return 8 } }, // JR NZ, e
            0x21: { cpu in let value = cpu.read16Bits(); cpu.registers.HL = value; return 12 }, // LD HL, nn
            0x22: { cpu in let address = cpu.registers.HL; cpu.memory.writeByte(cpu.registers.A, at: address); cpu.registers.HL &+= 1; return 8 }, // LDI (HL), A
            0x23: { cpu in cpu.registers.HL &+= 1; return 8 }, // INC HL
            0x26: { cpu in let value = cpu.readByte(); cpu.registers.H = value; return 8 }, // LD H, n
            0x2E: { cpu in let value = cpu.readByte(); cpu.registers.L = value; return 8 }, // LD L, n
            0x31: { cpu in let value = cpu.read16Bits(); cpu.registers.SP = value; return 12 }, // LD SP, nn
            0x32: { cpu in let address = cpu.registers.HL; cpu.memory.writeByte(cpu.registers.A, at: address); cpu.registers.HL &-= 1; return 8 }, // LDD (HL), A
            0x36: { cpu in let address = cpu.registers.HL; let value = cpu.readByte(); cpu.memory.writeByte(value, at: address); return 12 }, // LD (HL), n
            0x3A: { cpu in let address = cpu.registers.HL; cpu.registers.A = cpu.memory.readByte(at: address); cpu.registers.HL &-= 1; return 8 }, // LDD A, (HL)
            0x3E: { cpu in let value = cpu.readByte(); cpu.registers.A = value; return 8 }, // LD A, n
            0x77: { cpu in let address = cpu.registers.HL; cpu.memory.writeByte(cpu.registers.A, at: address); return 8 }, // LD (HL), A
            0x7E: { cpu in let address = cpu.registers.HL; cpu.registers.A = cpu.memory.readByte(at: address); return 8 }, // LD A, (HL)
            0xAF: { cpu in cpu.registers.A ^= cpu.registers.A; cpu.registers.zeroFlag = true; cpu.registers.negativeFlag = false; cpu.registers.halfCarryFlag = false; cpu.registers.carryFlag = false; return 4 }, // XOR A
            0xC1: { cpu in cpu.registers.BC = cpu.pop16Bits(); return 12 }, // POP BC
            0xC5: { cpu in cpu.push16Bits(value: cpu.registers.BC); return 16 }, // PUSH BC
            0xC9: { cpu in cpu.registers.PC = cpu.pop16Bits(); return 16 }, // RET
            0xCD: { cpu in let address = cpu.read16Bits(); cpu.push16Bits(value: cpu.registers.PC); cpu.registers.PC = address; return 24 }, // CALL nn
            0xE0: { cpu in let address = 0xFF00 + UInt16(cpu.readByte()); cpu.memory.writeByte(cpu.registers.A, at: address); return 12 }, // LDH (n), A
            0xE1: { cpu in cpu.registers.HL = cpu.pop16Bits(); return 12 }, // POP HL
            0xE2: { cpu in let address = 0xFF00 + UInt16(cpu.registers.C); cpu.memory.writeByte(cpu.registers.A, at: address); return 8 }, // LD (C), A
            0xE5: { cpu in cpu.push16Bits(value: cpu.registers.HL); return 16 }, // PUSH HL
            0xEA: { cpu in let address = cpu.read16Bits(); cpu.memory.writeByte(cpu.registers.A, at: address); return 16 }, // LD (nn), A
            0xF0: { cpu in let address = 0xFF00 + UInt16(cpu.readByte()); cpu.registers.A = cpu.memory.readByte(at: address); return 12 }, // LDH A, (n)
            0xF1: { cpu in cpu.registers.AF = cpu.pop16Bits(); return 12 }, // POP AF
            0xF3: { cpu in cpu.ime = false; return 4 }, // DI
            0xF5: { cpu in cpu.push16Bits(value: cpu.registers.AF); return 16 }, // PUSH AF
            0xF9: { cpu in cpu.registers.SP = cpu.registers.HL; return 8 }, // LD SP, HL
            0xFA: { cpu in let address = cpu.read16Bits(); cpu.registers.A = cpu.memory.readByte(at: address); return 16 }, // LD A, (nn)
            0xFB: { cpu in cpu.ime = true; return 4 }, // EI
        ]
    }

    // Function to fetch the next opcode
    private func fetch() -> UInt8 {
        let opcode = memory.readByte(at: registers.PC)
        registers.PC &+= 1
        return opcode
    }

    // Function to execute a CPU cycle
    func step() {
        if !halted {
            let opcode = fetch()
            if let instruction = opcodeTable[opcode] {
                let cycles = instruction(self)
                // Update the timer, APU, and PPU after each instruction
                timer.step(cycles: cycles)
                apu.step(cycles: cycles)
                ppu.step(cycles: cycles)
            } else {
                fatalError("Opcode not implemented: \(opcode)")
            }
            checkInterrupts()
        }
    }

    // Check and handle interrupts
    private func checkInterrupts() {
        if !ime { return }

        let ie = memory.readByte(at: RAM.IE)
        let `if` = memory.readByte(at: RAM.IF)
        let pendingInterrupts = ie & `if`

        if pendingInterrupts != 0 {
            ime = false
            halted = false

            // Check interrupt priority
            if (pendingInterrupts & RAM.I_VBLANK) != 0 {
                handleInterrupt(vector: RAM.JUMP_VBLANK, interrupt: RAM.I_VBLANK)
            } else if (pendingInterrupts & RAM.I_LCDC) != 0 {
                handleInterrupt(vector: RAM.JUMP_LCDC, interrupt: RAM.I_LCDC)
            } else if (pendingInterrupts & RAM.I_TIMER) != 0 {
                handleInterrupt(vector: RAM.JUMP_TIMER, interrupt: RAM.I_TIMER)
            } else if (pendingInterrupts & RAM.I_SERIAL) != 0 {
                handleInterrupt(vector: RAM.JUMP_SERIAL, interrupt: RAM.I_SERIAL)
            } else if (pendingInterrupts & RAM.I_P1) != 0 {
                handleInterrupt(vector: RAM.JUMP_P1, interrupt: RAM.I_P1)
            }
        }
    }

    private func handleInterrupt(vector: UInt16, interrupt: UInt8) {
        // Save current state on the stack
        push16Bits(value: registers.PC)
        // Adjust PC to the interrupt vector
        registers.PC = vector
        // Clear the corresponding interrupt flag
        var `if` = memory.readByte(at: RAM.IF)
        `if` &= ~interrupt
        memory.writeByte(`if`, at: RAM.IF)
    }

    private func push16Bits(value: UInt16) {
        registers.SP &-= 1
        memory.writeByte(UInt8((value >> 8) & 0xFF), at: registers.SP)
        registers.SP &-= 1
        memory.writeByte(UInt8(value & 0xFF), at: registers.SP)
    }

    private func pop16Bits() -> UInt16 {
        let lower = memory.readByte(at: registers.SP)
        registers.SP &+= 1
        let upper = memory.readByte(at: registers.SP)
        registers.SP &+= 1
        return UInt16(upper) << 8 | UInt16(lower)
    }

    // Helper functions
    private func read16Bits() -> UInt16 {
        let lower = memory.readByte(at: registers.PC)
        registers.PC &+= 1
        let upper = memory.readByte(at: registers.PC)
        registers.PC &+= 1
        return UInt16(upper) << 8 | UInt16(lower)
    }

    private func write16Bits(value: UInt16, to address: UInt16) {
        memory.writeByte(UInt8(value & 0xFF), at: address)
        memory.writeByte(UInt8(value >> 8), at: address &+ 1)
    }

    private func readByte() -> UInt8 {
        let value = memory.readByte(at: registers.PC)
        registers.PC &+= 1
        return value
    }
}
