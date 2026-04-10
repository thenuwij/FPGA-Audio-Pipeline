# FPGA Audio Pipeline

A real-time audio capture and processing system built on the Kria KV260 FPGA, developed as the final assessment for COMP3601 (Design Project) at UNSW Sydney, in collaboration with [@ZhongtaiZzhang](https://github.com/ZhongtaiZzhang) and [@YuanxuSun](https://github.com/YuanxuSun).

## Overview

The system captures audio from an I2S MEMS microphone, streams samples over AXI DMA into memory on a PetaLinux-based Kria KV260 environment, and packages the output as a `.wav` file for export and playback. An extension adds bidirectional audio support, enabling `.wav` file playback through an I2S amplifier and speaker.

## System Architecture

The pipeline is split into a hardware layer implemented in VHDL and a software layer written in C/C++ running on the embedded ARM core under PetaLinux.

**Hardware (VHDL)**
- `i2s_master.vhd` — clocks and serialises the I2S interface to the MEMS microphone, generating `bclk` and `lrclk` and shifting in PDM audio data
- `axi_dma_controller.vhd` — bridges the I2S data stream into AXI DMA transfers for memory-mapped access from the software layer
- `FIFO` — decouples the I2S clock domain from the AXI bus, buffering samples between the two
- `audio_pipeline.vhd` — top-level integration of the above components
- `params.vhd` — shared parameters across the pipeline

**Software (C/C++, cross-compiled for AArch64)**
- `audio_i2s.c` — configures and reads the I2S peripheral
- `axi_dma.c` — manages DMA transfers between the FPGA fabric and ARM memory via the S2MM channel
- `wave.c` — packages raw PCM samples into a valid `.wav` file with correct headers

## Speaker Extension

The extension adds a parallel transmit path for audio playback:

- `i2s_master_speaker.vhd` — drives an I2S amplifier using a separate FIFO instance, independent of the microphone receive path
- `driver_audio_i2s.c / driver_axi_dma.c` — software counterparts for the MM2S transmit channel
- `convert_audio.c` — strips `.wav` headers and prepares raw PCM for DMA transmission
- `main_s.c` — reads a `.wav` file from storage and streams it to the speaker via DMA

Module-level simulation confirmed correct VHDL data path behaviour. End-to-end speaker playback was functional with minor timing refinements in progress at submission.

## Hardware

- Kria KV260 Vision AI Starter Kit
- Adafruit I2S MEMS Microphone (SPH0645)
- UNSW CSE Design Project PMOD breakout board
- I2S amplifier and speaker (extension)

## Tools

- Vitis Vivado 2021.1
- PetaLinux (pre-configured image)
- AArch64 cross-compiler (`aarch64-xilinx-linux-g++`)
