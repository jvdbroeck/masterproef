#include <cstdint>
#include <fstream>
#include <iostream>
#include <sstream>
#include <string>

int main(int argc, char* argv[]) {
	if (argc < 2) {
		std::cout << "ERROR: wrong number of arguments" << std::endl;
		return 1;
	}

	std::ifstream infile(argv[1]);
	if(!infile.is_open()) {
		std::cout << "ERROR: could not open input file" << std::endl;
		return 1;
	}

	uint64_t lineNumber = 0;
	uint64_t prevtime = 0;
	uint64_t maxdiff = 0;
	uint64_t maxdiffLine = 0;
	bool started = false;

	while(infile.good()) {
		std::string line;
		getline(infile, line);
		++lineNumber;

		if(line.empty()) {
			std::cout << lineNumber << ": empty line" << std::endl;
			continue;
		}

		// timestamp van huidige lijn extraheren
		uint64_t timestamp = 0;
		std::stringstream ss;
		ss << line.substr(0, line.find_first_of(","));
		ss >> timestamp;
		ss.clear();

		if(started) {
			if(timestamp-prevtime > maxdiff) {
				maxdiff = timestamp-prevtime;
				maxdiffLine = lineNumber;
			}
		} else {
			started = true;
		}

		prevtime = timestamp;
	}

	std::cout << "max difference on line "<< maxdiffLine <<": " << maxdiff << std::endl;

	infile.close();

	return 0;
}
