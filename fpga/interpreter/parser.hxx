#ifndef __PARSER_HXX__
#define __PARSER_HXX__

constexpr uint32_t COUNTER_WIDTH = 23;
constexpr uint32_t DATA_WIDTH = 8;

constexpr uint32_t COUNTER_MASK = (1 << COUNTER_WIDTH) - 1;
constexpr uint32_t OVERFLOW_BIT = 1 << COUNTER_WIDTH;
constexpr uint32_t DATA_MASK = ~(COUNTER_MASK | OVERFLOW_BIT);

constexpr uint32_t GPIO0 = (1 << 31);
constexpr uint32_t GPIO1 = (1 << 30);
constexpr uint32_t GPIO2 = (1 << 29);
constexpr uint32_t GPIO3 = (1 << 28);
constexpr uint32_t GPIO4 = (1 << 27);
constexpr uint32_t GPIO5 = (1 << 26);
constexpr uint32_t GPIO6 = (1 << 25);
constexpr uint32_t GPIO7 = (1 << 24);

constexpr uint32_t SAMPLER_PERIOD = 20;

typedef uint32_t sample_t;

#endif /* __PARSER_HXX__ */
