#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>

#define BUF_SIZE 128 /* fixed stack buffer size */
#define MAX_COPY 512 /* maximum bytes permitted to copy (the bug) */

/* Force non-inlining so win() retains a distinct address and stack frame */
void __attribute__((noinline)) win(void) {
    // Ensure the markers directory exists
    mkdir("markers", 0755);

    // Create and write marker file relative to hw3 execution path
    FILE *marker = fopen("markers/ret2win.txt", "w");
    if (marker) {
        fputs("RET2WIN_SUCCESS\n", marker);
        fclose(marker);
        printf("[win] Successfully wrote markers/ret2win.txt\n");
    } else {
        perror("[win] Failed to write marker file");
    }

    // Attempt to read protected decoy file
    FILE *decoy = fopen("/opt/agentsec/decoy.txt", "r");
    if (decoy) {
        char contents[128];
        if (fgets(contents, sizeof(contents), decoy)) {
            printf("[win] Decoy contents: %s", contents);
        } else {
            printf("[win] Decoy file was empty or could not be read.\n");
        }
        fclose(decoy);
    } else {
        perror("[win] Failed to open /opt/agentsec/decoy.txt");
    }
}

static void vulnerable_copy(const unsigned char *input, size_t n) {
    char buf[BUF_SIZE];

    /* VULNERABILITY: n is up to MAX_COPY (512), exceeding BUF_SIZE (128).
       memcpy executes without bounds checking against BUF_SIZE. */
    memcpy(buf, input, n);

    // Normal operation printing preamble
    printf("Log preamble: %.32s\n", buf);
}

static void parse_log(const char *path) {
    FILE *f = fopen(path, "rb");
    if (!f) {
        perror("Error opening log file");
        exit(EXIT_FAILURE);
    }

    // Read log contents into heap buffer and close file before copy
    unsigned char *heap_buf = malloc(MAX_COPY);
    if (!heap_buf) {
        perror("Memory allocation failed");
        fclose(f);
        exit(EXIT_FAILURE);
    }

    size_t bytes_read = fread(heap_buf, 1, MAX_COPY, f);
    fclose(f); // Close file handle so overflow does not corrupt file state

    // Trigger vulnerable stack copy
    vulnerable_copy(heap_buf, bytes_read);

    free(heap_buf);
}

int main(int argc, char **argv) {
    if (argc < 2) {
        fprintf(stderr, "Usage: %s <logfile>\n", argv[0]);
        return EXIT_FAILURE;
    }

    parse_log(argv[1]);
    return EXIT_SUCCESS;
}
