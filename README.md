# FPGA Audio Pipeline

This project was developed in collaboration with [@ZhongtaiZzhang](https://github.com/ZhongtaiZzhang) and [@YuanxuSun](https://github.com/YuanxuSun), using the Kria KV260 FPGA to capture and process audio signals in real time. It was built as the final assessment for the course COMP3601.

## Project Description 

This project captures audio input from a microphone connected to the Kria KV260 FPGA board, converts it into a .wav file, and exports it to a computer for playback. An extension is also in place to enable direct audio output through a connected speaker, supporting playback from .wav files stored on the device.

## Hardware Components Used 

1. Pre-flashed Petalinux image with configured software and example bitstreams on SD card
2. Kria KV260 with power supply, ethernet cable, USB cable
3. UNSWCSEDesignProject A/B PMODboard 
4. Adafruit I2S MEMS microphone
5. Output Speaker (Will be connected later for Hardware Audio Output project extension)

## Software Pre-requisites 

1. Vitis Vivado 2021.1
   - During installation, you need to choose to install the full Vitis package as it will be needed later in this course.
2. IfUbuntu: minicom, if Windows: Putty

## Startup Instructions (Hardware Code)

1. Open Vivado. Click on Create Project and click Next.

   <img width="696" alt="Screenshot 2024-10-23 at 3 19 51 pm" src="https://github.com/user-attachments/assets/f0441d73-b2fb-4bd6-9864-2ec730e9fdaa">

2. Set Project name and Project location and click Next.

<img width="529" alt="Screenshot 2024-10-23 at 3 20 06 pm" src="https://github.com/user-attachments/assets/75a75adc-89c9-48b2-9380-7c6902aab32b">

3. Select RTL Project. We will add the sources later so tick Do not specify sources at this time. Click Next.

<img width="532" alt="Screenshot 2024-10-23 at 3 20 20 pm" src="https://github.com/user-attachments/assets/3a1e4737-e914-409e-bd80-ff2fd1a2477e">

4. In the Default Part section, click on the Boards tab and type "kv" in the search bar. Select Kria KV260 Vision AI Starter Kit and click Next.

<img width="516" alt="Screenshot 2024-10-23 at 3 20 35 pm" src="https://github.com/user-attachments/assets/50e6c13a-4168-4647-b6f2-f5bd19764e5f">

5. Click Finish to create your project.

6. Once the project has been created click on 'Add Sources' + and import all our hardware code files and design one by one including the KRIA contraints.
   
## Startup Instructions (Software Code)

1. Use VScode or any other compatible code editor and copy our code files from the repository to the computer.
   
2. Copy all files in the software section including the 'include' folder and 'src' folder.
   
3. Once everything is read use a USB drive an copy the .c files from the computer to the USB drive.

## Startup Instructions (KRIA KV260 BOARD)

Windows instructions:
Open PuTTY and go to the terminal settings.
Enable Implicit CR in every LF
Implicit LF in every CR

<img width="503" alt="Screenshot 2024-10-23 at 4 29 57 pm" src="https://github.com/user-attachments/assets/c6e69b4a-ea05-41f8-ae9c-f5a40ee586a1">

Now click on Serial, and set it up as follows:

<img width="512" alt="Screenshot 2024-10-23 at 4 30 41 pm" src="https://github.com/user-attachments/assets/5529734e-0e95-452b-8ab4-9bdd86d2ddbe">

Now click on Session, and choose Serial

<img width="511" alt="Screenshot 2024-10-23 at 4 30 53 pm" src="https://github.com/user-attachments/assets/79fe3779-86d9-4d91-96b5-2411bc0ac661">

Now press “Open”, you should get a serial window. Click 'Reset' on the Kria board. Note there is often a long delay between the last OF message and the “Starting tcf-agent:” OK.

## Connecting the USB drive to KRIA KV260 BOARD 

A normal USB drive would not be compatible with our KRIA KV260 board, so please watch this youtube tutorial linked below to help convert the USB drive to FAT32 format, which will be accepted by the KRIA KV260 board.

[Click here to watch the USB drive format conversion video](https://www.youtube.com/watch?v=s4EX5DMEZH0&t=223s)

Next connect the USB drive to a USB port on the KRIA board after you have followed the KRIA KV260 startup instructions mentioned earlier in this file.

After connecting and once Putty (if on Windows) is setup, enter the following command line instructions :

### Mount the USB DRIVE to KRIA 

mkdir /comp3601/usb    -- make directory (Only use the first time)

lsblk                  -- Run this command to view all the connected devices including USB drive 

mount /dev/sda1 /comp3601/usb    -- Mount the usb drive to the created directory 


cd /comp3601/usb                 -- Go to directory created where USB is mounted 
ls                               -- lists the contents inside the USB drive (you will see the files copied from the computer)

### Test if i2smaster and AXI functions correctly using the following commands 

1. “activate” the built-in AXI image using xmutil unloadapp && xmutil loadapp comp3601-i2s-axi via the serial port.

xmutil unloadapp && xmutil loadapp comp3601-i2s-axi

The LED should start blinking to indicate the app is loaded.

2. Navigate to the directory /comp3601/resources/sample_bin and run #ls
   You should see two files  'ctrl_bus_test  sample256'

3. Run 'chmod +x sample256' (Only first time to make program executable)
   
4. Run ./sample256
   
5. It will print a long series of numbers which reflect the values captured from the data input
of the microphone. You can do a simple test using a wire.

Connect SD to 3V3 and run sample256 - all captures should be 1s

<img width="832" alt="Screenshot 2024-10-23 at 4 12 24 pm" src="https://github.com/user-attachments/assets/0fde221c-9595-40d6-a1ce-35a72427a7a8">

Now repeat, but connect SD to GND - all captures should now be 0s

<img width="786" alt="Screenshot 2024-10-23 at 4 13 04 pm" src="https://github.com/user-attachments/assets/9a4391e9-94a8-4069-a449-72e00a6fc232">

Now repeat, but plug the microphone in - all captures should be “random” values

<img width="784" alt="Screenshot 2024-10-23 at 4 13 16 pm" src="https://github.com/user-attachments/assets/d76f61b4-b6ea-4e4b-b143-4e49bc28c65f">


## Compile and run your code files to produce .wav output file 

Navigate to the directory created eariler ''/comp3601/usb''.

1. Run the following commands on PUTTY terminal to compile the .c files and create M4_output file.

aarch64-xilinx-linux-g++ -g -Wall -O2 -std=c++11 -I include/ -c src/main.c -o build/main.o

aarch64-xilinx-linux-g++ -g -Wall -O2 -std=c++11 -I include/ -c src/audio_i2s.c -o build/audio_i2s.o

aarch64-xilinx-linux-g++ -g -Wall -O2 -std=c++11 -I include/ -c src/axi_dma.c -o build/axi_dma.o

aarch64-xilinx-linux-g++ -g -Wall -O2 -std=c++11 -I include/ -c src/wave.c -o build/wave.o
 
aarch64-xilinx-linux-g++ -o M4_output build/main.o build/audio_i2s.o build/axi_dma.o build/wave.o -lpthread -lz -rdynamic 
on putty terminal

 2. Once compiled, now run './M4_output' to start recording the sound. Once the sound has been recorded you will see a message saying a .wav output file has been created.

## Unmount the USB drive from KRIA play .wav file on computer 

To unmount the drive run the command :
umount /comp3601/usb

Once unmounted successfully from the KRIA board, connect to your computer and play the .wav file output.
Currently we have an issue where the audio is not playing properly but will be working on fixing it as soon as possible.

## Extension for Speaker

### Additional Components Used
- I2S amp soldered to speaker  
- All other components remain the same as the main pipeline

### Additional VHDL Files Added
- **i2s_master_speaker.vhd**: Manages I2S data transmission to the speaker using `bclk` and `lrcl` clocks. Handles data transfer from FIFO to the I2S amp.
- **FIFO**: Same component as the microphone input, instantiated separately in the audio pipeline for independent operation.
- **audio_pipeline.vhd**: Extended to support speaker output.
- **params.vhd**: Updated with parameters to support speaker integration in the pipeline.

### Additional Software Files Added

- **axi_dma.c/h**: Handles DMA operations for audio data transfer between memory and FPGA. A modified version (`driver_axi_dma.c/h`) is used for speaker output.
- **audio_i2s.c/h**: Manages the I2S protocol. Two versions are used: one for the microphone (`audio_i2s`) and another (`driver_audio_i2s`) for the speaker.
- **wav.c/h**: Converts raw audio into `.wav` format.
- **convert_audio.c/h**: Strips headers and prepares audio data for further processing (`audio_data.c` is also involved).
- **main.c**: Reads microphone input via S2MM data channel in AXI DMA and stores it as a `.wav` file.
- **main_s.c**: Reads audio from a `.wav` file and transmits it to the speaker using the MM2S data channel and `driver_audio_i2s`.

### Running the Extended System

To run the extended system, follow the same steps outlined earlier, but use `main_s.c` to initiate speaker playback. Module-level testing has confirmed that the VHDL data path operates as expected, and the software successfully processes audio samples from `.wav` files for output. Minor refinements are in progress to further improve the reliability of speaker playback.
