#ifndef WAV_H
#define WAV_H
#include <stdint.h>
#include <stdio.h>

#define SAMPLE_RATE 44100
#define NUM_CHANNELS 1
#define BITS_PER_SAMPLE 32

typedef struct
{
    char chunk_id[4];   // Positions 1-4: "RIFF"
    uint32_t file_size; // Positions 5-8: File size (integer)
    char format[4];     // Positions 9-12: "WAVE"

    char fmt_chunk_marker[4]; // Positions 13-16: "fmt "
    uint32_t format_length;   // Positions 17-20: Length of format data
    uint16_t format_type;     // Positions 21-22: Type of format
    uint16_t num_channels;    // Positions 23-24: Number of channels (2)
    uint32_t sample_rate;     // Positions 25-28: Sample rate (44100)
    uint32_t byte_rate;       // Positions 29-32: (Sample Rate * BitsPerSample * Channels) / 8
    uint16_t block_align;     // Positions 33-34: (BitsPerSample * Channels) / 8
    uint16_t bits_per_sample; // Positions 35-36: Bits per sample (16)

    char data_chunk_header[4]; // Positions 37-40: "data"
    uint32_t data_size;        // Positions 41-44: Size of the data section
} WAV_Header;

/**
 * @brief Write an unsigned integer to a file in little-endian format.
 *
 * @param value The unsigned integer to write.
 * @param num_bytes The number of bytes to write.
 * @param wav_file The file pointer to write to.
 */
void write_little_endian_value(uint32_t value, int num_bytes, FILE *wav_file);

/**
 * @brief Initialize and write the WAV header to the file.
 *
 * @param wav_file The file pointer to write to.
 * @param sample_rate The audio sample rate.
 * @param num_channels The number of audio channels.
 * @param bits_per_sample The bit depth (bits per sample).
 * @param num_samples The total number of samples in the audio.
 */
void initialize_wav_header(FILE *wav_file, uint32_t sample_rate, uint16_t num_channels, uint16_t bits_per_sample, uint32_t num_samples);

/**
 * @brief Create and save a WAV file with the given audio data.
 *
 * @param filename The name of the WAV file.
 * @param num_samples The number of samples in the audio data.
 * @param data The array containing the audio data.
 * @param sample_rate The audio sample rate.
 * @param num_channels The number of audio channels.
 * @param bits_per_sample The bit depth (bits per sample).
 */
void save_wav_file(const char *filename, uint32_t num_samples, uint32_t *data, uint32_t sample_rate, uint16_t num_channels, uint16_t bits_per_sample);

#endif // WAV_H
