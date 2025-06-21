#include "../include/audio_data.h"
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

AudioData* get_audio_data(const char *filename) {
    FILE *file = fopen(filename, "rb");
    if (!file) {
        fprintf(stderr, "Can't open %s\n", filename);
        return NULL;
    }

    AudioData *audio_data = (AudioData *)malloc(sizeof(AudioData));
    if (!audio_data) {
        fprintf(stderr, "Can't allocate the memory\n");
        fclose(file);
        return NULL;
    }

    // begining of the file
    fseek(file, 0, SEEK_SET);

    // jump to 22 to get num channels
    fseek(file, 22, SEEK_SET);
    fread(&audio_data->num_channels, sizeof(uint16_t), 1, file);

    // then read the sample rate
    fread(&audio_data->sample_rate, sizeof(uint32_t), 1, file);

    // jump to 34 to get bps
    fseek(file, 34, SEEK_SET);
    fread(&audio_data->bits_per_sample, sizeof(uint16_t), 1, file);

    // jump to 40 to get the size of data
    fseek(file, 40, SEEK_SET);
    fread(&audio_data->data_size, sizeof(uint32_t), 1, file);

    // allocate memory for audio data
    audio_data->audio_data = malloc(audio_data->data_size);
    if (!audio_data->audio_data) {
        fprintf(stderr, "Memory for audio data is allocate fail.\n");
        free(audio_data);
        fclose(file);
        return NULL;
    }

    fread(audio_data->audio_data, 1, audio_data->data_size, file);
    fclose(file);

    return audio_data;
}

void free_audio_data(AudioData *audio_data) {
    if (audio_data) {
        free(audio_data->audio_data);
        free(audio_data);
    }
}

void print_audio_samples(const AudioData *audio_data, size_t num_samples) {
    if (!audio_data || !audio_data->audio_data) {
        fprintf(stderr, "There is no audio data\n");
        return;
    }

    printf("Sample Rate is %u\n", audio_data->sample_rate);
    printf("Channels is %u\n", audio_data->num_channels);
    printf("Bits per Sample is %u\n", audio_data->bits_per_sample);

    if (audio_data->bits_per_sample == 16) {
        uint16_t *samples = (uint16_t *)audio_data->audio_data;
        for (size_t i = 0; i < num_samples && i < audio_data->data_size / 2; i++) {
            printf("%d\n", samples[i]);
        }
    } else if (audio_data->bits_per_sample == 32) {
        uint32_t *samples = (uint32_t *)audio_data->audio_data;
        for (size_t i = 0; i < num_samples && i < audio_data->data_size / 4; i++) {
            printf("%d\n", samples[i]);
        }
    } else {
        printf("Error for bps maybe not supported\n");
    }
}
// main


