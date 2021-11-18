proj2 : proj2.cu
	nvcc proj2.cu -o proj2 -g

test1:
	\rm -f test1
	./proj2 sample/test1/input.txt sample/test1/kernel.txt sample/test1/output.txt >> test1
test2:
	\rm -f test2	
	./proj2 sample/test2/input.txt sample/test2/kernel.txt sample/test2/output.txt >> test2
test3:
	\rm -f test3
	./proj2 sample/test3/input.txt sample/test3/kernel.txt sample/test3/output.txt >> test3
test4:
	\rm -f test4
	./proj2 sample/test4/input.txt sample/test4/kernel.txt sample/test4/output.txt >> test4
test5:
	\rm -f test5
	./proj2 sample/test5/input.txt sample/test5/kernel.txt sample/test5/output.txt >> test5

clean : 
	\rm -f proj2 test1 test2 test3 test4 test5
