#include <cstdint>
#include <cstdlib>
#include <iostream>
#include <fstream>
#include <regex>
#include <string>
#include <sstream>


constexpr uint32_t COUNTER_WIDTH = 24;
constexpr uint32_t DATA_WIDTH = 7;

constexpr uint32_t COUNTER_MASK = (1 << COUNTER_WIDTH) - 1;
constexpr uint32_t OVERFLOW_BIT = 1 << COUNTER_WIDTH;
constexpr uint32_t DATA_MASK = static_cast<uint32_t>(-1) & ~(1u << (1 + COUNTER_WIDTH));


int main(int argc, char* argv[])
{
    if (argc < 3)
    {
        std::cout << "ERROR: wrong number of arguments" << std::endl;
        return 1;
    }

    std::ifstream infile(argv[1]);
    if (!infile.is_open())
    {
        std::cout << "ERROR: could not open input file" << std::endl;
        return 1;
    }

    std::ofstream outfile(argv[2]);
    if (!outfile.is_open())
    {
        std::cout << "ERROR: could not open output file" << std::endl;
        return 1;
    }

    outfile << "timestamp [ns],bit0,bit1,bit2,bit3,bit4,bit5,bit6,bit7" << std::endl;

    std::cout << "processing file contents" << std::endl;

    uint64_t offset = 0;
    uint64_t lastTimestamp = 0;
    uint64_t lineNumber = 0;
    bool started = false;

    while (infile.good())
    {
        std::string line;
        getline(infile, line);
        ++lineNumber;

        if (line.empty())
        {
            std::cout << lineNumber << ": empty line found" << std::endl;
            continue;
        }

        std::string data = line.substr(12, 8);

        uint32_t sample = 0;
        std::stringstream ss;
        ss << std::hex << data;
        ss >> sample;
        if (ss.bad())
        {
            std::cout << lineNumber << ": invalid line found: [" << line << "]" << std::endl;
            abort();
        }

        uint64_t timestamp = sample & COUNTER_MASK;

        bool is_add_offset = true;
        if (!started)
        {
            // OPGELET
            // Eerste sample kan starten op een tijdstip verschillend van 0!
            // Dit komt omdat de sampler de INITIELE toestand van de ingang niet opslaat.
            // Als de toestand dus maar later verandert, is de eerste geobserveerde sample
            // op een tijdstip verschillend van 0...
            /*if (timestamp != 0)
            {
                std::cout << lineNumber << ": invalid sample: start at non-zero counter value: " << std::hex << sample
                          << std::dec << std::endl;
                abort();
            }*/
            sample |= OVERFLOW_BIT;
            is_add_offset = false;
            started = true;
        }

        if ((timestamp == 0) ^ static_cast<bool>(sample & OVERFLOW_BIT))
        {
            std::cout << lineNumber << ": invalid sample: overflow at non-zero counter value: " << std::hex << timestamp
                      << std::dec << std::endl;
            abort();
        }

        // Overflow / offset correction
        if (is_add_offset) {
            if (sample & OVERFLOW_BIT)
            {
                offset += 1 << COUNTER_WIDTH;
            }
        }
        timestamp += offset;

        if (!(timestamp==lastTimestamp && timestamp==0)) {
            if (timestamp <= lastTimestamp)
            {
                std::cout << lineNumber << ": invalid sample: going back in time" << std::endl;
                abort();
            }
        }
        lastTimestamp = timestamp;

        outfile << timestamp << ",";
        for (unsigned i = 31; i >= 31 - DATA_WIDTH; i--)
        {
            outfile << ((sample >> i) & 1u) << ",";
        }
        outfile << std::endl;
    }
    std::cout << "done" << std::endl;

    infile.close();
    outfile.close();

    return 0;
}
