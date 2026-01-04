# FactoryOS

## What is this?

An automation system for Minecraft's Create mod using ComputerCraft: Tweaked. Manages distributed crafting across multiple nodes with centralized storage and intelligent scheduling.

## Status

Currently under a refactor, not avaiable unless I revert main branch


## Installation

### Warning

System is very sensitive to the way you place node modules and which local networks parts of the system are connected to.
After a refactor I will place a demo/screenshots as to how to set up the system properly.

### Prerequisites

- CC:Tweaked  
- Create 
- UnlimitedPeripheralWorks

### Setup

1. Clone the repository on your main computer and node computer:
```bash
pastebin run qL6NF5xJ
```

2. Run the setup script:
```bash
factory/setup.lua
```

3. Configure each computer:
   - **Main PC**: Select "main" type, specify modem location
   - **Worker Nodes**: Select "node" type, choose station type, specify buffer name

4. The system auto-updates on startup from the GitHub repository

## About

Personal project inspired by system displayed in this [video](https://www.youtube.com/watch?v=40RwGATZYwI&t=282s).
I was not able to get my hands on source code of system in that video, so I decided to make my own with quite a few extensions and making it way more complicated then it really needs to be.

## License

This project is licensed under the MIT License - see the [LICENSE](./LICENSE) file for details.

## Acknowledgments

Thanks to [SquidDev](https://github.com/SquidDev) for creating a git clone inside CC:Tweaked!
