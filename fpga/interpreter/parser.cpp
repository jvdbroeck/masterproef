#include <cstdint>
#include <fstream>
#include <iostream>
#include <cstring>
#include <sstream>

#include "GPIOMonitor.hxx"
#include "parser.hxx"
#include "VCDFile.hxx"

#define REVERSE(x) ((((x) & 0xFF000000)>>24) | (((x) & 0x00FF0000) >> 8) | (((x) & 0x0000FF00) << 8) | (((x) & 0x000000FF) << 24))
#define print_sample_offset(x) (x) << " [0x" << std::hex << (x) << std::dec << "] "

int main(int argc, char* argv[])
{

	if(argc < 4)
	{
		std::cout << "ERROR wrong number of arguments" << std::endl;
		std::cout << "      Usage: ./parser [input] [wlf-output] [skip_samples]" << std::endl;
		return 1;
	}

	// Parse number of samples to skip
	std::istringstream ss(argv[3]);
	uint64_t skip_count;
	if(!(ss >> skip_count))
	{
		std::cout << "ERROR Third argument not a number!" << std::endl;
		return 1;
	}
	std::cout << "Skipping the first " << skip_count << " samples" << std::endl;

	// Open input file as binary
	std::ifstream input(argv[1], std::ios::in | std::ios::binary | std::ios::ate);
	if(!input.is_open())
	{
		std::cout << "ERROR opening input file \"" << argv[1] << "\"!" << std::endl;
		return 1;
	}
	std::cout << "Input file: " << argv[1] << std::endl;

	// grootte van de inputfile opvragen
	uint64_t input_size = (uint64_t)input.tellg();
	input.seekg(0, std::ios::beg);
	uint64_t nr_samples = input_size/4;
	std::cout << "Input file contains " << nr_samples << " samples" << std::endl;

	// create VCD file instance
	char tmpname_buffer[L_tmpnam];
	tmpnam(tmpname_buffer);
	std::cout << "Intemediate VCD file: " << tmpname_buffer << std::endl;
	VCDFile vcd(tmpname_buffer);

	// Monitor the GPIO lines to measure statistics
	GPIOMonitor gpio_monitor;

	// variables
	uint64_t processed_count = 0;
	uint64_t percent = 0;
	uint32_t lastData = 0;
	uint64_t lastTimestamp = 0;
	uint64_t offset = 0;
	bool started = false;

	while(input.good())
	{
		sample_t sample = 0xFFFFFFFF;
		uint64_t sample_offset = (uint64_t)input.tellg();
		input.read((char *)&sample, sizeof(sample_t));
		sample = REVERSE(sample);

		if(sample == 0xFFFFFFFF)
		{
			// Sample comes from empty buffer.
			continue;
		}

		// extract the timestamp
		uint64_t timestamp = sample & COUNTER_MASK;

		// counter value should be zero when overflow bit set
		if(((timestamp == 0) ^ static_cast<bool>(sample & OVERFLOW_BIT)) && started)
		{
			std::cout << "Sample at offset " << print_sample_offset(sample_offset) << ": invalid sample - overflow at non-zero counter value (0x"
						<< std::hex << sample << std::dec << ")" << std::endl;
			abort();
		}

		// overflow/offset correction
		if((sample & OVERFLOW_BIT) && started)
		{
			offset += 1 << COUNTER_WIDTH;
		}
		timestamp += offset;

		// current timestamp should always be greater than previous
		if(timestamp <= lastTimestamp && started)
		{
			std::cout << "Sample at offset " << print_sample_offset(sample_offset) << ": invalid sample - going back in time (0x"
						<< std::hex << sample << std::dec << ")" << std::endl;
			abort();
		}

		// extract the sample value
		uint32_t data = (sample & DATA_MASK) >> (COUNTER_WIDTH+1);

		if((data != lastData) && (skip_count != 0)) {
			skip_count--;
		}

		if(skip_count == 0)
		{
			// add data to VCD file
			vcd.add(timestamp, data);
			// record changes for statistic measurements
			gpio_monitor.add(timestamp, data, lastData);
		}

		// display progress
		processed_count++;
		uint64_t new_percent = (uint64_t)(processed_count*100/nr_samples);
		if(new_percent != percent)
		{
			std::cout << "\r" << percent << "%" << std::flush;
		}
		percent = new_percent;

		// update loop variables
		lastTimestamp = timestamp;
		lastData = data;
		started = true;
	}
	std::cout << std::endl;

	std::cout << vcd.getSampleCount() << " samples recorded in the VCD-file" << std::endl;

	// convert VCD -> WLF
	std::cout << "Output WLF file: " << argv[2] << std::endl;
	std::string command = std::string("vcd2wlf \"") + tmpname_buffer + "\" \"" + argv[2] + "\"";
	std::cout << "Conversion VCD->WLF: " << command << std::endl;
	system(command.c_str());

	// print statistics
	gpio_monitor.print();

	return 0;
}
