#include <cstdint>
#include <cstdlib>
#include <iostream>
#include <fstream>
#include <string>
#include <sstream>

int main(int argc, char* argv[]) {
	if(argc < 3) {
		std::cout << "ERROR: wrong number of arguments" << std::endl;
		return 1;
	}

    std::ifstream infile(argv[1]);
    if (!infile.is_open())
    {
        std::cout << "ERROR: could not open input file" << std::endl;
        return 1;
    }

    uint64_t interval = 0;
    std::stringstream convarg;
    convarg << argv[2];
    convarg >> interval;

    uint64_t linenumber = 0;
    uint64_t prevTimestamp = 0;
    int prevOverflowbit = 0;
    while(infile.good()) {
    	std::string line;
    	getline(infile, line);
    	++linenumber;

    	if(line.empty()) {
    		std::cout << "Line " << linenumber << ": empty line" << std::endl;
    		continue;
    	}

    	size_t first_separator = line.find_first_of(",");

    	uint64_t timestamp = 0;
    	std::stringstream ss;
    	ss << line.substr(0, first_separator);
    	ss >> timestamp;
    	ss.clear();

    	int overflowbit = -1;
    	ss << line.substr(line.size()-2, 1);
    	ss >> overflowbit;
    	ss.clear();

    	if(linenumber>1) {
	    	if(prevTimestamp+interval !=timestamp) {
	    		if(prevOverflowbit == 1) {
	    			//std::cout << "Line " << linenumber << ": time warp, but recovering from overflow. No problemo." << std::endl;

	    		} else if(overflowbit == 0) {
		    		std::cout << "Line " << linenumber << ": time warping is not allowed (prev="
		    		 			<< prevTimestamp << ", now=" << timestamp << ", interval=" << interval << ")" << std::endl;

					//abort();
				} else {
					//std::cout << "Line " << linenumber << ": time warp, but overflow bit is set. No problemo." << std::endl;
				}
	    	}
	    }

    	prevOverflowbit = overflowbit;
    	prevTimestamp = timestamp;
    }

    std::cout << "done" << std::endl;

    infile.close();
}
