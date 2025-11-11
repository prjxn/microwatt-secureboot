#include <stdint.h>
#include <stddef.h>

#define RAM_START 0x20000000UL
#define RAM_WORDS 1024
#define NOP_WORD  0x60000000UL

#define SHA_BASE    0x40000000UL
#define SHA_CMD     0x00
#define SHA_STATUS  0x04
#define SHA_DATA    0x10
#define SHA_RESULT  0x40

volatile uint32_t * const ram     = (volatile uint32_t *)RAM_START;
volatile uint32_t * const sha_reg = (volatile uint32_t *)SHA_BASE;

void __attribute__((noreturn, section(".startup"))) _start(void) {
    extern int main(void);
    int r = main();
    (void)r;
    for (;;) { __asm__ volatile ("trap"); }
}

static inline void init_ram(void) {
    for (uint32_t i = 0; i < RAM_WORDS; ++i) ram[i] = (uint32_t)NOP_WORD;
}

static inline void write_sha(uint32_t off, uint32_t val) {
    sha_reg[off / 4] = val;
}

static inline uint32_t read_sha(uint32_t off) {
    return sha_reg[off / 4];
}

int main(void) {
    init_ram();
    const char payload[64] = "Secure boot demo";
    const int payload_len = 64;
    const int words = 16;
    for (int i = 0; i < words; ++i) {
        uint32_t w = 0;
        for (int b = 0; b < 4; ++b) {
            int idx = i * 4 + b;
            uint8_t ch = (idx < payload_len) ? (uint8_t)payload[idx] : 0u;
            w = (w << 8) | (uint32_t)ch;
        }
        write_sha(SHA_DATA + i * 4u, w);
    }
    write_sha(SHA_CMD, 1u);
    while ((read_sha(SHA_STATUS) & 1u) == 0u) __asm__ volatile ("nop");
    uint32_t digest[8];
    for (int i = 0; i < 8; ++i) digest[i] = read_sha(SHA_RESULT + i * 4u);
    const uint32_t expected[8] = {
        0x8bfb0f9d, 0x8f9a1e5e, 0x9d08790a, 0xf789ee1c,
        0x7bbef592, 0x93de2453, 0x16b08b2d, 0xd60dfeb5
    };
    int ok = 1;
    for (int i = 0; i < 8; ++i) if (digest[i] != expected[i]) { ok = 0; break; }
    if (ok) for (;;) __asm__ volatile ("nop");
    else for (;;) __asm__ volatile ("trap");
    return 0;
}
