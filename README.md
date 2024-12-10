# MIPS 2048

A faithful implementation of the popular 2048 puzzle game written in MIPS assembly language, designed to run on the MARS MIPS simulator.

## Features

- Complete 2048 gameplay mechanics
- Bitmap display visualization
- Color-coded tiles
- Score tracking
- Responsive controls using WASD keys
- Win/loss detection

## Game Controls

- **W**: Move tiles up
- **A**: Move tiles left
- **S**: Move tiles down
- **D**: Move tiles right

## Technical Details

**Display Configuration**
- 64x64 pixel bitmap display
- 1x1 pixel size
- Base address: 0x10040000

**Memory Organization**
- Board state stored in 4x4 array
- Temporary matrices for move calculations
- Color lookup tables for tile visualization
- Special digit tables for number rendering

## Implementation Highlights

- Efficient tile merging algorithms
- Matrix transposition for up/down movements
- Dynamic tile color management
- Custom number rendering system
- Random tile generation with 2/4 probability distribution

## Data Structures

- Main game board (4x4)
- Available spaces tracking
- Temporary board for move calculations
- Transposition matrix for vertical moves
- Color lookup tables
- Digit rendering tables

## Game Logic

- Tile merging follows standard 2048 rules
- Score increases by merged tile value
- Game ends when:
  - Player reaches 2048 (win)
  - No valid moves remain (loss)
  - Board is full with no possible merges (loss)

## Display System

- Custom character rendering
- Dynamic color management
- Efficient tile drawing routines
- Automatic board refresh after moves
  
![Screenshot 2024-10-01 155135](https://github.com/user-attachments/assets/2c58062b-d372-4a18-a00f-9a93112e1f3c)
