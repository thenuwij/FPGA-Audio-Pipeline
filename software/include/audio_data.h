#ifndef AUDIO_DATA_H
#define AUDIO_DATA_H

#include <stdint.h>
#include <stdio.h>

typedef struct {
    uint32_t sample_rate;
    uint16_t num_channels;
    uint16_t bits_per_sample;
    uint32_t data_size;      
    void *audio_data;       // Pointer to audio data
} AudioData;

/**
 * @brief get the audio data from wav file
 * 
 * @param filename The name of the WAV file.
 * @return return a AudioData structure pointer for success or NULL for fail
 */
AudioData* get_audio_data(const char *filename);

/**
 * @brief free AudioData structure memory.
 * 
 * @param audio_data the pointer we need free
 */
void free_audio_data(AudioData *audio_data);

/**
 * @brief print the audio sample
 * 
 * @param audio_data pointer to the structure containing the audio data.
 * @param num_samples the number of samples to display
 */
void print_audio_samples(const AudioData *audio_data, size_t num_samples);

#endif // AUDIO_DATA_H