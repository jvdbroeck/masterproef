#ifndef __VCDFILE_HXX__
#define __VCDFILE_HXX__

#include <ctime>
#include <fstream>

#include "parser.hxx"

struct VCDFile
{
	VCDFile(const char *const file_name);

	void add(uint64_t time, uint32_t data);
	uint64_t getSampleCount();

private:
	const char *const m_file_name;
	uint32_t m_last_data;
	uint64_t m_sample_count;
	std::ofstream m_file;
	static constexpr char VCDCHAR = '!';
	static constexpr uint32_t TIMESCALE = 10;
};

VCDFile::VCDFile(const char *const file_name):
	m_file_name(file_name),
	m_last_data(0),
	m_sample_count(0),
	m_file(file_name)
{
	if(!m_file.is_open())
	{
		std::cout << "Error opening VCD file \"" << m_file_name << "\"!" << std::endl;
		return;
	}

	// header information
	time_t now = time(0);
	m_file << "$date " << ctime(&now) << " $end" << std::endl;
	m_file << "$version FPGA Sampler, Jens Van den Broeck 2013, v0.1 $end" << std::endl;
	m_file << "$timescale " << TIMESCALE << "ns $end" << std::endl;

	// variable declarations
	m_file << "$scope module logic $end" << std::endl;
	for(uint32_t i=0; i<DATA_WIDTH; i++) {
		m_file << "$var wire 1 " << (char)(VCDCHAR+i) << " GPIO" << i << " $end" << std::endl;
	}
	m_file << "$upscope $end" << std::endl;
	m_file << "$enddefinitions $end" << std::endl;

	// initial values of signal lines
	m_file << "$dumpvars" << std::endl;
	for(uint32_t i=0; i<DATA_WIDTH; i++) {
		m_file << "0" << (char)(VCDCHAR+i) << std::endl;
	}
}

void
VCDFile::add(uint64_t timestamp, uint32_t data)
{
	// Error check.
	if(!m_file.is_open())
	{
		std::cout << "Error: VCD file not open!" << std::endl;
		return;
	}

	// By default, no record is made.
	bool is_added = false;

	// Loop over all databits, only recording value changes.
	for(uint32_t i=0; i<DATA_WIDTH; i++)
	{
		if(((data >> i) & 1u) != ((m_last_data >> i) & 1u))
		{
			if(!is_added)
			{
				// Record timestamp if not yet added.
				// Compensate for limited timescale values of VCD specification.
				m_file << "#" << timestamp*(SAMPLER_PERIOD/TIMESCALE) << std::endl;
			}

			// Record changed GPIO line.
			m_file << ((data >> i) & 1u) << (char)(VCDCHAR+(DATA_WIDTH-1)-i) << std::endl;
			is_added = true;
		}
	}

	// Increment recorded sample count.
	if(is_added)
	{
		m_sample_count++;
		m_last_data = data;
	}
}

uint64_t
VCDFile::getSampleCount()
{
	return m_sample_count;
}

#endif /* __VCDFILE_HXX__ */
