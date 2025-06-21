#include "../include/driver_audio_i2s.h"
#include "../include/audio_data.h"
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#define SAMPLE_RATE 44100
#define PLAY_DURATION 8 

// Function to calculate max number of data samples fit in a chunk to send
size_t calculate_max_sample_size() {
    return AXI_DMA_SEND_BUFFER_SIZE / 4; // We are only sending 32-bit samples
}


int main() {
    audio_i2s_t my_config;

    // Initializing I2S interface for speaker output
    if (audio_i2s_init(&my_config) < 0) {
        printf("Error initializing audio I2S for speaker\n");
        return -1;
    }

    // Enable speaker output by setting control register
    audio_i2s_set_reg(&my_config, AUDIO_I2S_CR, 0x2); 

    // Load audio data from wav file
    const char *filename = "output.wav";
    AudioData *audio_data = get_audio_data(filename);
    if (!audio_data) {
        fprintf(stderr, "Failed to load audio data from %s\n", filename);
        audio_i2s_release(&my_config);
        return -1;
    }

    printf("Audio Data Loaded:\n");
    printf("Sample Rate: %u\n", audio_data->sample_rate);
    printf("Channels: %u\n", audio_data->num_channels);
    printf("Bits per Sample: %u\n", audio_data->bits_per_sample);

    // Allocate buffer memory to store 32-bit samples 
    uint32_t *data_ptr = (uint32_t *)malloc(audio_data->data_size * 2); // Buffer for 32-bit samples
    if (!data_ptr) {
        fprintf(stderr, "Failed to allocate buffer\n");
        free_audio_data(audio_data);
        audio_i2s_release(&my_config);
        return -1;
    }

    // Check if it is a 16-bit sample size 
    // if it is then convert to 32-bit sample by padding with zeroes 
    if (audio_data->bits_per_sample == 16) {
        uint16_t *original_data = (uint16_t *)audio_data->audio_data;

        // loops through all 16-bit samples 
        for (size_t i = 0; i < audio_data->data_size / 2; i++) {

            // automatically pads 0s when converting to 32-bit samples 
            data_ptr[i] = (uint32_t)original_data[i]; 
        }
    } else {

        // copies data directly to data_ptr buffer as data was already read in 32-bit samples 
        memcpy(data_ptr, audio_data->audio_data, audio_data->data_size);
    }

    // Calculate number of samples that fit in one chunk to send in AXI DMA SEND BUFFER via mm2s channel
    size_t max_sample_size = calculate_max_sample_size();
    if (max_sample_size == 0) {
        free_audio_data(audio_data);
        audio_i2s_release(&my_config);
        return -1;
    }

    size_t total_samples = audio_data->data_size / (audio_data->bits_per_sample / 8);
    size_t samples_sent = 0;

    // Send audio data to speaker 
    printf("Starting audio playback...\n");

    // Send 32-bit samples in chunks
    while (samples_sent < total_samples) {

        // if samples_to_send exceeds max sample size that can be sent 
        // then samples_to_send is capped at max_sample_size 
        size_t samples_to_send = (total_samples - samples_sent < max_sample_size) ? (total_samples - samples_sent) : max_sample_size;

        if (audio_i2s_send(&my_config, &data_ptr[samples_sent], samples_to_send * sizeof(uint32_t)) < 0) {
            fprintf(stderr, "Error playing audio\n");
            break;
        }

        samples_sent += samples_to_send;
    }
    print_audio_samples(audio_data, total_samples);
    // Free resources 
    free(data_ptr);
    free_audio_data(audio_data);
    audio_i2s_release(&my_config);

    printf("Playback finished.\n");
    return 0;
}