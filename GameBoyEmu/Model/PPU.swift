//
//  PPU.swift
//  GameBoyEmu
//
//  Created by Thalisson Melo on 20/05/24.
//

import Foundation

class PPU {
    private var memory: RAM
    private var cycles: UInt32 = 0
    private var screenBuffer: [UInt8]

    init(memory: RAM) {
        self.memory = memory
        self.screenBuffer = [UInt8](repeating: 0, count: 160 * 144)
    }

    func step(cycles: UInt32) {
        self.cycles += cycles

        // The PPU has a frequency of 1 PPU cycle every 4 CPU cycles
        while self.cycles >= 4 {
            self.cycles -= 4
            updatePPU()
        }
    }

    private func updatePPU() {
        // Update LY (Y coordinate) every 456 PPU cycles (or 114 CPU cycles)
        if self.cycles % 456 == 0 {
            let ly = (memory.readByte(at: RAM.LY) + 1) % 154
            memory.writeByte(ly, at: RAM.LY)

            if ly == 144 {
                // Trigger V-Blank interrupt
                memory.writeByte(memory.readByte(at: RAM.IF) | RAM.I_VBLANK, at: RAM.IF)
            }

            updateSTAT()
        }

        renderScanline()
    }

    private func updateSTAT() {
        let ly = memory.readByte(at: RAM.LY)
        let lyc = memory.readByte(at: RAM.LYC)
        let stat = memory.readByte(at: RAM.STAT)

        if ly == lyc {
            memory.writeByte(stat | 0x04, at: RAM.STAT)  // Coincidence flag
        } else {
            memory.writeByte(stat & ~0x04, at: RAM.STAT)  // Clear coincidence flag
        }

        // Generate STAT interrupt if enabled
        if (stat & 0x40) != 0 && ly == lyc {
            memory.writeByte(memory.readByte(at: RAM.IF) | RAM.I_LCDC, at: RAM.IF)
        }
    }

    private func renderScanline() {
        let lcdc = memory.readByte(at: RAM.LCDC)
        let ly = memory.readByte(at: RAM.LY)

        if (lcdc & 0x80) == 0 {
            return  // LCD off
        }

        if (lcdc & 0x01) != 0 {
            renderBackgroundLine(ly: ly)
        }

        if (lcdc & 0x20) != 0 {
            renderWindowLine(ly: ly)
        }

        if (lcdc & 0x02) != 0 {
            renderSprites(ly: ly)
        }
    }

    private func renderBackgroundLine(ly: UInt8) {
        let scy = memory.readByte(at: RAM.SCY)
        let scx = memory.readByte(at: RAM.SCX)
        let backgroundMapAddress: UInt16 = (memory.readByte(at: RAM.LCDC) & 0x08) != 0 ? 0x9C00 : 0x9800

        for x in 0..<160 {
            let bgX = (UInt16(x) + UInt16(scx)) & 0xFF
            let bgY = (UInt16(ly) + UInt16(scy)) & 0xFF
            let tileIndex = (bgY / 8) * 32 + (bgX / 8)
            let tileAddress = backgroundMapAddress + tileIndex
            let tileId = memory.readByte(at: tileAddress)
            renderTile(tileId: tileId, x: x, y: Int(ly), bgX: Int(bgX), bgY: Int(bgY))
        }
    }

    private func renderWindowLine(ly: UInt8) {
        let wy = memory.readByte(at: RAM.WY)
        let wx = memory.readByte(at: RAM.WX) - 7
        if ly < wy || wx >= 160 { return }

        let windowMapAddress: UInt16 = (memory.readByte(at: RAM.LCDC) & 0x40) != 0 ? 0x9C00 : 0x9800

        for x in 0..<160 {
            if x < wx { continue }

            let windowX = UInt16(x) - UInt16(wx)
            let windowY = UInt16(ly) - UInt16(wy)
            let tileIndex = (windowY / 8) * 32 + (windowX / 8)
            let tileAddress = windowMapAddress + tileIndex
            let tileId = memory.readByte(at: tileAddress)
            renderTile(tileId: tileId, x: x, y: Int(ly), bgX: Int(windowX), bgY: Int(windowY))
        }
    }

    private func renderSprites(ly: UInt8) {
        for i in stride(from: 0, to: 40, by: 4) {
            let spriteY = memory.oam[i] - 16
            let spriteX = memory.oam[i + 1] - 8
            let tileId = memory.oam[i + 2]
            let attributes = memory.oam[i + 3]

            if ly >= spriteY && ly < spriteY + 8 {
                renderSprite(tileId: tileId, x: Int(spriteX), y: Int(spriteY), ly: Int(ly), attributes: attributes)
            }
        }
    }

    private func renderTile(tileId: UInt8, x: Int, y: Int, bgX: Int, bgY: Int) {
        let tileDataAddress: UInt16 = (memory.readByte(at: RAM.LCDC) & 0x10) != 0 ? 0x8000 : 0x8800
        let tileAddress = tileDataAddress + UInt16(tileId) * 16
        let line = memory.readByte(at: tileAddress + UInt16(bgY % 8) * 2)

        for pixelX in 0..<8 {
            let colorBit = (line >> (7 - pixelX)) & 0x01
            let color = colorBit != 0 ? 1 : 0  // Placeholder for the color
            setPixel(x: x + pixelX, y: y, color: color)
        }
    }

    private func renderSprite(tileId: UInt8, x: Int, y: Int, ly: Int, attributes: UInt8) {
        let tileAddress = 0x8000 + UInt16(tileId) * 16
        let line = memory.readByte(at: tileAddress + UInt16(ly - y) * 2)

        for pixelX in 0..<8 {
            let colorBit = (line >> (7 - pixelX)) & 0x01
            let color = colorBit != 0 ? 1 : 0  // Placeholder for the color
            setPixel(x: x + pixelX, y: ly, color: color)
        }
    }

    private func setPixel(x: Int, y: Int, color: Int) {
        if x < 0 || x >= 160 || y < 0 || y >= 144 { return }
        screenBuffer[y * 160 + x] = UInt8(color)
    }

    func getFrameBuffer() -> [UInt8] {
        return screenBuffer
    }
}
