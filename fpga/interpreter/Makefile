all:
	clang -std=c++11 -Weverything -Wno-c++98-compat interpreter.cpp -o interpreter -lstdc++
	clang -std=c++11 -Weverything -Wno-c++98-compat checktiming.cpp -o checktiming -lstdc++
	clang -std=c++11 -Weverything -Wno-c++98-compat checkmaxdiff.cpp -o checkmaxdiff -lstdc++
	clang -std=c++11 -Weverything -Wno-c++98-compat parser.cpp -o parser -lstdc++

clean:
	rm -f interpreter checktiming checkmaxdiff parser
