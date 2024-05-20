//
//  APU.swift
//  GameBoyEmu
//
//  Created by Thalisson Melo on 18/05/24.
//

import Foundation

class APU {
    private var memory: RAM
    private var cycles: UInt32 = 0

    // Canal 1 (som quadrado)
    private var channel1Frequency: UInt16 = 0
    private var channel1Volume: UInt8 = 0

    // Canal 2 (som quadrado)
    private var channel2Frequency: UInt16 = 0
    private var channel2Volume: UInt8 = 0

    // Canal 3 (gerador de ondas)
    private var channel3Enabled: Bool = false

    // Canal 4 (gerador de ruído)
    private var channel4Frequency: UInt16 = 0
    private var channel4Volume: UInt8 = 0

    init(memory: RAM) {
        self.memory = memory
    }

    func step(cycles: UInt32) {
        self.cycles += cycles
        
        // Process each channel
        updateChannel1()
        updateChannel2()
        updateChannel3()
        updateChannel4()
    }

    private func updateChannel1() {
        // Process the channel 1 logic here
        if cycles >= 1024 {
            // Generate a square wave sound
            channel1Frequency = readFrequency(for: 0xFF13, highRegister: 0xFF14)
            channel1Volume = memory.readByte(at: 0xFF12)
            cycles -= 1024
        }
    }

    private func updateChannel2() {
        // Process the channel 2 logic here
        if cycles >= 1024 {
            // Generate a square wave sound
            channel2Frequency = readFrequency(for: 0xFF18, highRegister: 0xFF19)
            channel2Volume = memory.readByte(at: 0xFF17)
            cycles -= 1024
        }
    }

    private func updateChannel3() {
        // Process the channel 3 logic here
        if channel3Enabled && cycles >= 1024 {
            // Generate wave sound
            cycles -= 1024
        }
    }

    private func updateChannel4() {
        // Process the channel 4 logic here
        if cycles >= 1024 {
            // Generate noise sound
            channel4Frequency = readFrequency(for: 0xFF1D, highRegister: 0xFF1E)
            channel4Volume = memory.readByte(at: 0xFF21)
            cycles -= 1024
        }
    }

    private func readFrequency(for lowRegister: UInt16, highRegister: UInt16) -> UInt16 {
        let low = memory.readByte(at: lowRegister)
        let high = memory.readByte(at: highRegister) & 0x07
        return UInt16(high) << 8 | UInt16(low)
    }
    
    // Placeholder function to generate sound
    func generateSound() {
        
    }
}
