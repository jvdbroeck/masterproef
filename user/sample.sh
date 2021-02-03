#!/bin/bash
while true
do
	read -p "Press a key to enable the sampler..." -n1 -s
	./control enable

	read -p "Press a key to stop sampling..." -n1 -s
	./control disable
	./control flush
	./control reset
	./control disable
done
