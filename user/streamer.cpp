#include <algorithm>
#include <chrono>
#include <cstring>
#include <fstream>
#include <iostream>
#include <memory>
#include <thread>

#include <errno.h>
#include <fcntl.h>

#include <sys/mman.h>
#include <sys/time.h>
#include <sys/ioctl.h>

#include "../driver/xpcie.h"

#include "narrow.hxx"
#include "CFileDeleter.hxx"
#include "CircularBufferMonitor.hxx"
#include "MemoryMapping.hxx"



// Kijk eens naar https://github.com/bombela/backward-cpp




struct Application
{
	Application(const char *const output_file_name);

	int
	run();


private:

	static constexpr const char *const DEVICE_NAME = "/dev/xpcie";

	enum: size_t
	{
		FILE_BUFFER_SIZE = 1 << 30,
		FILE_BUFFER_CHUNKS_LOG2 = 3,
		FILE_BUFFER_CHUNKS = 1 << FILE_BUFFER_CHUNKS_LOG2,
		FILE_BUFFER_CHUNK_SIZE = FILE_BUFFER_SIZE >> FILE_BUFFER_CHUNKS_LOG2
	};


	const char *const m_output_file_name;
	uint8_t m_dma_buffer_count;
	MemoryMapping m_dma_buffers[MAX_DMA_BUF_COUNT];
	std::unique_ptr<FILE, CFileDeleter> m_output_file;
	MemoryMapping m_file_buffer;
	CircularBufferMonitor m_file_buffer_monitor;

	template <typename T>
	T *
	getFileBufferPointer(CircularBufferMonitor::slot_t slot);

	void
	writerThread();
};


Application::Application(const char *const output_file_name):
	m_output_file_name(output_file_name),
	m_dma_buffer_count(0),
	m_dma_buffers(),
	m_output_file(),
	m_file_buffer(),
	m_file_buffer_monitor(FILE_BUFFER_CHUNKS)
{}

template <typename T>
T *
Application::getFileBufferPointer(CircularBufferMonitor::slot_t slot)
{
	assert(slot >= 0);
  return reinterpret_cast<T *>(m_file_buffer.get<int8_t>() + (static_cast<uint8_t>(slot) * FILE_BUFFER_CHUNK_SIZE));
}

int
Application::run()
{
	// Try to open the associated character device
	FileDescriptor char_device(open(DEVICE_NAME, O_RDWR));
	if (char_device < 0)
	{
		auto error = errno;
		std::cout << "ERROR *** File " << DEVICE_NAME << " could not be opened (" << error << ")" << std::endl;
		return error;
	}

	uint32_t answer = static_cast<uint32_t>(ioctl(char_device, XPCIE_IOC_CHECK));
	if(answer != XPCIE_MAGIC) {
		std::cout << "Character device " << DEVICE_NAME << " did not respond correctly!" << std::endl;
		std::cout << "  (expected answer: 0x" << std::hex << XPCIE_MAGIC << ", actual answer: 0x" << answer << ")" << std::endl;
		return 1;
	}
	std::cout << "Character device " << DEVICE_NAME << " successfully opened." << std::endl;

	// Try to open the output file
  	m_output_file = std::unique_ptr<FILE, CFileDeleter>(fopen(m_output_file_name, "a"));
	if (m_output_file == nullptr)
	{
		auto error = errno;
		std::cout << "ERROR *** File " << m_output_file_name << " could not be opened (" << error << ")" << std::endl;
		return 1;
	}
	std::cout << "Output file " << m_output_file_name << " successfully opened." << std::endl;

	// Try to map the DMA buffers in user space
	m_dma_buffer_count = narrow<uint8_t>(ioctl(char_device, XPCIE_IOC_GETBUFCOUNT));
	std::cout << "Mapping " << static_cast<uint32_t>(m_dma_buffer_count) << " DMA buffers in user space." << std::endl;
	if (m_dma_buffer_count == 0)
	{
		std::cout << "ERROR *** No DMA buffers were allocated." << std::endl;
		return 1;
	}
	for (int i = 0; i < m_dma_buffer_count; i++)
	{
		m_dma_buffers[i] = MemoryMapping(BUF_SIZE, PROT_READ, MAP_SHARED, char_device);
	}

	// Get upper memory buffer (reserved at boot time)
	std::cout << "Mapping high memory in userspace." << std::endl;
	m_file_buffer = MemoryMapping(FILE_BUFFER_SIZE, PROT_READ | PROT_WRITE, MAP_SHARED, char_device);

	// Create 'consumer' thread
	std::cout << "Starting writer thread." << std::endl;
	std::thread writer_thread(&Application::writerThread, this);

	std::cout << "Ready." << std::endl;

	#if defined(MEASURE_TIME_COPYHI) || defined(MEASURE_TIME_PROCESS)
	struct timeval tv_begin,tv_end;
	uint64_t totaldummy_usec=0, totaltime_usec=0;
	uint64_t blocknr=0;
	#endif

	bool running = true;
	while (running)
	{
		auto slot = m_file_buffer_monitor.getNextFreeSlot();
		if (slot < 0)
		{
			std::cout << "Error: buffer overrun" << std::endl;
			break;
		}

		uint32_t *const buffer = getFileBufferPointer<uint32_t>(slot);
		uint32_t *const buffer_end = buffer + (FILE_BUFFER_CHUNK_SIZE / sizeof(uint32_t));
		uint32_t *p = buffer;
		uint32_t written_count = 0;
		while (p < buffer_end)
		{
			// Doe een blocking read op ons char device om een DMA block te krijgen
			uint8_t current_dma_buffer = 0;
			assert(::read(char_device, static_cast<void *>(&current_dma_buffer), 1) == 1);

			#if defined(MEASURE_TIME_COPYHI) || defined(MEASURE_TIME_PROCESS)
			blocknr++;
			gettimeofday(&tv_begin, NULL);
			#endif

			// Kopieer de gecapteerde data zo snel mogelijk naar onze eigen buffer
			p = std::copy_n(m_dma_buffers[current_dma_buffer].template get<uint32_t>(), BUF_SIZE_WORDS, p);

			#if defined(MEASURE_TIME_COPYHI)
			gettimeofday(&tv_end, NULL);
			totaltime_usec += (uint64_t)((tv_end.tv_sec-tv_begin.tv_sec)*1000000+(tv_end.tv_usec-tv_begin.tv_usec));

			gettimeofday(&tv_begin, NULL);
			gettimeofday(&tv_end, NULL);
			totaldummy_usec += (uint64_t)((tv_end.tv_sec-tv_begin.tv_sec)*1000000+(tv_end.tv_usec-tv_begin.tv_usec));
			#endif

			// Transfer voltooid, laat het weten aan de kernel
			if(static_cast<bool>(::ioctl(char_device, XPCIE_IOC_DONE)))
			{
				// dit was de laatste te lezen buffer
				running = false;
				written_count = narrow<uint32_t>(reinterpret_cast<uintptr_t>(p)-reinterpret_cast<uintptr_t>(buffer));
				break;
			}

			#if defined(MEASURE_TIME_PROCESS)
			gettimeofday(&tv_end, NULL);
			totaltime_usec += (uint64_t)((tv_end.tv_sec-tv_begin.tv_sec)*1000000+(tv_end.tv_usec-tv_begin.tv_usec));
			#endif
		}

		std::cout << "^" << std::flush;
		m_file_buffer_monitor.confirmProduced(slot, written_count);
	}

	std::cout << std::endl << "Waiting for remaining data to be written to disk..." << std::endl << std::flush;

	// Wait for 'consumer' to finish
	writer_thread.join();

	#if defined(MEASURE_TIME_COPYHI) || defined(MEASURE_TIME_PROCESS)
	std::cout << "Total time copying: " << totaltime_usec << std::endl;
	std::cout << "Total time gettimeofday: " << totaldummy_usec << std::endl;
	std::cout << "Number of blocks: " << blocknr << std::endl;
	#endif

	return 0;
}

void
Application::writerThread()
{
	bool thread_running = true;
	while (thread_running)
	{
		uint32_t nbytes = 0;
		auto slot = m_file_buffer_monitor.getNextFullSlot(nbytes);

		if(nbytes != 0) {
			thread_running = false;
		} else {
			nbytes = FILE_BUFFER_CHUNK_SIZE;
		}

		std::fwrite(getFileBufferPointer<void>(slot), nbytes, 1, m_output_file.get());

		m_file_buffer_monitor.confirmConsumed(slot);
	}
}

int
main(int argc, char *argv[])
{
	if (argc != 2)
	{
		std::cout << "Usage: " << argv[0] << " output-file" << std::endl;
		return 1;
	}

	return Application(argv[1]).run();
}
