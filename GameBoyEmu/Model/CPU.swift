//
//  CPU.swift
//  GameBoyEmu
//
//  Created by Thalisson Melo on 14/05/24.
//

struct opcode {
    var code : String
    var instruction: (_ cpu : CPU) -> Void
    
}

import Foundation

class CPU {
    var registers : CPURegisters = CPURegisters()
    var memory : RAM = RAM()
}
