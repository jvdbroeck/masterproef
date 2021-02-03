#ifndef __GPIO_MONITOR_HXX__
#define __GPIO_MONITOR_HXX__

#include "GPIOLine.hxx"
#include "parser.hxx"

struct GPIOMonitor
{
	GPIOMonitor();

	void add(uint64_t timestamp, uint32_t data, uint32_t prevdata);
	void print();
	uint64_t getIterationCount();

private:
	GPIOLine gpio[DATA_WIDTH];
};

GPIOMonitor::GPIOMonitor()
{
}

void
GPIOMonitor::add(uint64_t timestamp, uint32_t data, uint32_t prevdata)
{
	// Loop over all databits
	for(uint32_t i=0; i<DATA_WIDTH; i++)
	{
		if(((data >> (DATA_WIDTH-i-1)) & 1u) != ((prevdata >> (DATA_WIDTH-i-1)) & 1u))
		{
			// bit 'i' has changed
			if(((data >> (DATA_WIDTH-i-1)) & 1u) == 1)
			{
				gpio[i].announceRise(timestamp);
				if(i > 0)
				{
					gpio[i-1].announceNextLineRise(timestamp);
				}
			}
			else
			{
				gpio[i].announceFall(timestamp);
				if(i > 0)
				{
					gpio[i-1].announceNextLineFall(timestamp);
				}
			}
		}
	}
}

void
GPIOMonitor::print()
{
	std::cout << "STATISTIC MEASUREMENTS" << std::endl;
	std::cout << "Results are averaged over " << gpio[0].getRiseCount() << " iterations" << std::endl;

	for(uint32_t i=0; i<DATA_WIDTH; i++)
	{
		std::cout << "------------------------" << std::endl;
		std::cout << "GPIO " << i << std::endl;
		gpio[i].print();
	}
}

uint64_t
GPIOMonitor::getIterationCount()
{
	return gpio[0].getFallCount();
}

#endif /* __GPIO_MONITOR_HXX__ */
