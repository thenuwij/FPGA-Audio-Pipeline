/** 22T3 COMP3601 Design Project A
 * File name: main.c
 * Description: Example main file for using the audio_i2s driver for your Zynq audio driver.
 *
 * Distributed under the MIT license.
 * Copyright (c) 2022 Elton Shih
 * Permission is hereby granted, free of charge, to any person obtaining a copy of
 * this software and associated documentation files (the "Software"), to deal in
 * the Software without restriction, including without limitation the rights to
 * use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
 * of the Software, and to permit persons to whom the Software is furnished to do
 * so, subject to the following conditions:
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include "audio_i2s.h"
#include "../include/wave.h"

#define RECORD_DURATION 8     
#define TOTAL_SAMPLES (SAMPLE_RATE * RECORD_DURATION  * NUM_CHANNELS)

uint32_t reverseBits(uint32_t num) {
    uint32_t reversed = 0;
    int i;

    for (i = 0; i < 32; i++) {
        reversed <<= 1;  // Shift left by 1
        reversed |= (num & 1);  // Set the least significant bit of the reversed number
        num >>= 1;  // Shift the original number right by 1
    }

    return reversed;
}

int main() {

    uint32_t audio_buffer[TOTAL_SAMPLES] = {0};
    uint32_t index = 0;
    uint32_t temp_buffer[TOTAL_SAMPLES] = {0};
    
    audio_i2s_t my_config;
    if (audio_i2s_init(&my_config) < 0) {
        printf("Error initializing audio I2S\n");
        return -1;
    }

    printf("mmapped address: %p\n", my_config.v_baseaddr);
    printf("Before writing to CR: %08x\n", audio_i2s_get_reg(&my_config, AUDIO_I2S_CR));
    audio_i2s_set_reg(&my_config, AUDIO_I2S_CR, 0x1);
    printf("After writing to CR: %08x\n", audio_i2s_get_reg(&my_config, AUDIO_I2S_CR));
    printf("SR: %08x\n", audio_i2s_get_reg(&my_config, AUDIO_I2S_SR));
    printf("Key: %08x\n", audio_i2s_get_reg(&my_config, AUDIO_I2S_KEY));
    printf("Before writing to gain: %08x\n", audio_i2s_get_reg(&my_config, AUDIO_I2S_GAIN));
    audio_i2s_set_reg(&my_config, AUDIO_I2S_GAIN, 0x1);
    printf("After writing to gain: %08x\n", audio_i2s_get_reg(&my_config, AUDIO_I2S_GAIN));

    printf("Starting audio recording for %d seconds...\n", RECORD_DURATION );


    while (index < TOTAL_SAMPLES) {
        int32_t *samples = audio_i2s_recv(&my_config);
        
        for (int i = 0; i < TRANSFER_LEN && index < TOTAL_SAMPLES; i++) {
            audio_buffer[index++] = samples[i];
        }
    }

    for (int i = 0; i < TOTAL_SAMPLES; i++) {
        audio_buffer[i] = reverseBits(audio_buffer[i]);
    }

    //  for (int i = 0; i < 200; i++) {
    //     printf("Sample %d: %d\n", i, audio_buffer[i]);  
    // }
    //comment it out with 2 channel
    int filtered_index = 0;
     for (int i = 0; i < TOTAL_SAMPLES; i++) {
         if (audio_buffer[i] != 0) {  // Only keep non-zero samples
            temp_buffer[filtered_index++] = audio_buffer[i];
         }
     }

    // Copy filtered non-zero samples back to audio_buffer
    memcpy(audio_buffer, temp_buffer, filtered_index * sizeof(uint32_t));


    printf("Recording complete. Saving to WAV file...\n");
    
    //save_wav_file("output.wav", TOTAL_SAMPLES, audio_buffer, SAMPLE_RATE, NUM_CHANNELS, BITS_PER_SAMPLE);

    save_wav_file("output.wav", filtered_index, audio_buffer, SAMPLE_RATE, NUM_CHANNELS, BITS_PER_SAMPLE);

    printf("WAV file saved as output.wav\n");

    audio_i2s_release(&my_config);

    return 0;
}
