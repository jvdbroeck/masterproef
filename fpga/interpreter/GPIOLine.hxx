#ifndef __GPIO_LINE_HXX__
#define __GPIO_LINE_HXX__

#include <cassert>
#include <limits>

#include "parser.hxx"

struct GPIOLine
{
	GPIOLine();

	void announceRise(uint64_t timestamp);
	void announceFall(uint64_t timestamp);

	void announceNextLineRise(uint64_t timestamp);
	void announceNextLineFall(uint64_t timestamp);

	void print();

	uint64_t getRiseCount();
	uint64_t getFallCount();

private:
	uint64_t m_nr_rise;
	uint64_t m_nr_fall;

	uint64_t m_total_high;
	uint64_t m_total_low;

	uint64_t m_total_high_nextlow_pre;
	uint64_t m_total_high_nexthigh;
	uint64_t m_total_high_nextlow_post;

	uint64_t m_lastrise;
	uint64_t m_lastfall;

	uint64_t m_nextlastrise;
	uint64_t m_nextlastfall;

	uint64_t m_low_min;
	uint64_t m_low_max;

	uint64_t m_high_min;
	uint64_t m_high_max;
};

GPIOLine::GPIOLine():
	m_nr_rise(0),
	m_nr_fall(0),
	m_total_high(0),
	m_total_low(0),
	m_total_high_nextlow_pre(0),
	m_total_high_nexthigh(0),
	m_total_high_nextlow_post(0),
	m_lastrise(0),
	m_lastfall(0),
	m_nextlastrise(0),
	m_nextlastfall(0),
	m_low_min(std::numeric_limits<uint64_t>::max()),
	m_low_max(0),
	m_high_min(std::numeric_limits<uint64_t>::max()),
	m_high_max(0)
{
}

void
GPIOLine::announceRise(uint64_t timestamp)
{
	if(m_nr_rise > 0)
	{
		uint64_t n = (timestamp - m_lastfall);
		m_total_low += n;
		if(n < m_low_min)
		{
			m_low_min = n;
		}
		if(m_low_max < n)
		{
			m_low_max = n;
		}
	}
	m_lastrise = timestamp;
	m_nr_rise++;
}

void
GPIOLine::announceFall(uint64_t timestamp)
{
	uint64_t n = (timestamp - m_lastrise);
	m_total_high += n;
	if(n < m_high_min)
	{
		m_high_min = n;
	}
	if(m_high_max < n)
	{
		m_high_max = n;
	}

	m_lastfall = timestamp;

	if(m_nextlastfall > 0)
	{
		m_total_high_nextlow_post += (timestamp - m_nextlastfall);
	}
	m_nr_fall++;
}

void
GPIOLine::announceNextLineRise(uint64_t timestamp)
{
	m_total_high_nextlow_pre += (timestamp - m_lastrise);
	m_nextlastrise = timestamp;
}

void
GPIOLine::announceNextLineFall(uint64_t timestamp)
{
	m_total_high_nexthigh += (timestamp - m_nextlastrise);
	m_nextlastfall = timestamp;
}

void
GPIOLine::print()
{
	assert(m_nr_rise == m_nr_fall);

	double factor = 1.0*SAMPLER_PERIOD/m_nr_rise;

	std::cout << "Rising/Falling edge count: "
						<< m_nr_rise << "/" << m_nr_fall << std::endl;
	std::cout << "High[m:M]/Low[m:M] time: "
						<< m_total_high*factor << "[" << m_high_min*SAMPLER_PERIOD << ":" << m_high_max*SAMPLER_PERIOD << "]"
						<< "/" << m_total_low*factor*m_nr_rise/(m_nr_rise-1) << "[" << m_low_min*SAMPLER_PERIOD << ":" << m_low_max*SAMPLER_PERIOD << "]"
						<< std::endl;
	std::cout << "Pre/During/Post next time: "
						<< m_total_high_nextlow_pre*factor << "/" << m_total_high_nexthigh*factor << "/" << m_total_high_nextlow_post*factor << std::endl;
}

uint64_t
GPIOLine::getRiseCount()
{
	return m_nr_rise;
}

uint64_t
GPIOLine::getFallCount()
{
	return m_nr_fall;
}

#endif /* __GPIO_LINE_HXX__ */
