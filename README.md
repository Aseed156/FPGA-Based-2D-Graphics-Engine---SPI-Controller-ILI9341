# FPGA-Based 2D Graphics Engine

A complete 2D graphics pipeline built entirely in VHDL for an ILI9341 TFT LCD (320×240) — no software, no soft-core processor, no CPU involved anywhere. Every pixel decision, physics update, and protocol handshake happens in hardware.

## What it does

- Drives an ILI9341 TFT LCD over SPI from scratch — custom bit-bang SPI controller + LCD init/streaming FSM
- Runs 9 independent graphics entities in parallel: 4 bouncing balls, 4 animated rectangles, and a 2-player Pong game
- Each shape entity does its own fixed-point physics (gravity, elastic bouncing) and combinational hit-testing
- Renders scaled bitmap text (ROM-based font) entirely in hardware
- Pong includes an AI-controlled paddle and a user-controlled paddle (board switch input)
- Switch-selectable display modes (text-only, full physics scene, mixed, Pong)

## Architecture
50 MHz OSC → ALTPLL → 100 MHz (SPI/LCD) + 10 kHz (game clock)  

│  

LCD Controller (init FSM + pixel streaming)  

│  

SPI Controller (bit-bang, MSB-first)  

│  

ILI9341 LCD  
Pixel Counter (x,y) ──┬─► Ball ×4  

├─► Rectangle ×4  

├─► Text Overlay  

└─► Pong  

│  

Priority Mux (combinational)  

│  

currentPixel → framebuffer  

## Modules

| File | Purpose |
|---|---|
| `Graphics_Accelerator.vhd` | Top-level: PLL, clocking, entity instantiation, pixel compositing |
| `spi_controller.vhd` | Bit-bang SPI master FSM (9-bit word: DC flag + 8-bit payload) |
| `LCD_Controller.vhd` | ILI9341 init sequence ROM + continuous pixel streaming |
| `ball.vhd` | Generic bouncing ball — Q10.6 fixed-point physics, squared-distance hit test |
| `rectangle.vhd` | Generic bouncing rectangle — AABB hit test |
| `text_overlay.vhd` | 8×8 bitmap font ROM, scaled 3×, fully combinational |
| `pong.vhd` | 2-player Pong — AI left paddle, user-controlled right paddle |
| `clk_div.vhd` | Parameterizable clock divider for the game/physics clock |

## Clocking

| Domain | Frequency | Used by |
|---|---|---|
| Board oscillator | 50 MHz | ALTPLL input |
| `lcd_clk` | 100 MHz | SPI controller, LCD controller |
| `clk_10khz` → `gameClk` | 10 kHz → divided down | Physics tick for all entities |
| Pixel hit-testing | Combinational | Evaluated every pixel, no dedicated clock |

## Target Hardware

- Intel Cyclone V SE 5CSEBA6U23I7
- ILI9341 320×240 SPI TFT LCD
- Synthesized resource usage: ~5.7% logic, ~13.8% DSP blocks, Fmax ~89 MHz

## Status

Functional on physical hardware across all display modes. See report for full verification details, synthesis results, and known pitfalls (MADCTL orientation, SPI handshake timing).

