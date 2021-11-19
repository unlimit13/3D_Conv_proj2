GPU : proj2.cu
	nvcc proj2.cu -o GPU -g
Single : projAVX.c
	gcc -pg -mavx2 -o Single projAVX.c 
Multi : projAVX_M.c
	gcc -pg -mavx2 -o Multi projAVX_M.c -lpthread -Wall

GPUtest:
	\rm -f output/GPU/test1 output/GPU/test2 output/GPU/test3 output/GPU/test4 output/GPU/test5
	./GPU sample/test1/input.txt sample/test1/kernel.txt sample/test1/output.txt >> output/GPU/test1
	./GPU sample/test2/input.txt sample/test2/kernel.txt sample/test2/output.txt >> output/GPU/test2
	./GPU sample/test3/input.txt sample/test3/kernel.txt sample/test3/output.txt >> output/GPU/test3
	./GPU sample/test4/input.txt sample/test4/kernel.txt sample/test4/output.txt >> output/GPU/test4
	./GPU sample/test5/input.txt sample/test5/kernel.txt sample/test5/output.txt >> output/GPU/test5
Singletest:
	\rm -f output/Single/test1 output/Single/test2 output/Single/test3 output/Single/test4 output/Single/test5
	./Single sample/test1/input.txt sample/test1/kernel.txt sample/test1/output.txt >> output/Single/test1
	./Single sample/test2/input.txt sample/test2/kernel.txt sample/test2/output.txt >> output/Single/test2
	./Single sample/test3/input.txt sample/test3/kernel.txt sample/test3/output.txt >> output/Single/test3
	./Single sample/test4/input.txt sample/test4/kernel.txt sample/test4/output.txt >> output/Single/test4
	./Single sample/test5/input.txt sample/test5/kernel.txt sample/test5/output.txt >> output/Single/test5
Multitest:
	\rm -f output/Multi/test1 output/Multi/test2 output/Multi/test3 output/Multi/test4 output/Multi/test5
	./Multi sample/test1/input.txt sample/test1/kernel.txt sample/test1/output.txt >> output/Multi/test1
	./Multi sample/test2/input.txt sample/test2/kernel.txt sample/test2/output.txt >> output/Multi/test2
	./Multi sample/test3/input.txt sample/test3/kernel.txt sample/test3/output.txt >> output/Multi/test3
	./Multi sample/test4/input.txt sample/test4/kernel.txt sample/test4/output.txt >> output/Multi/test4
	./Multi sample/test5/input.txt sample/test5/kernel.txt sample/test5/output.txt >> output/Multi/test5
	

clean : 
	\rm -f GPU Single Multi 
