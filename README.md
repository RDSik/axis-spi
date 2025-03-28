[![Simulation and build project](https://github.com/RDSik/axis-spi/actions/workflows/main.yml/badge.svg?branch=master)](https://github.com/RDSik/axis-spi/actions/workflows/main.yml)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](https://github.com/RDSik/axis-spi/blob/master/LICENSE.txt)

# AXI-Stream UART module

This is simple SPI with AXI-Stream interface. 

If you want build project, program board or run simulation use Makefile. 

## Clone repository:
```bash
git clone https://github.com/RDSik/axis-spi.git
cd axis-spi
```

## Build project (need Gowind IDE):
```bash
make project
```

## Program Tang Primer 20K with OpenFPGALoader:
```bash
make program
```

## Simulation with Verilator:
```bash
make
```

## Wave with Gtkwave:
```bash
make wave
```

## Simulation  with QuestaSim:
```bash
make SIM=questa
```
