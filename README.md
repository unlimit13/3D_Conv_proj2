# 3D_Conv_proj2

1. Makefile
    make GPU : GPU 프로그램 생성 >> GPU
    make Single : single thread프로그램 생성 >> Single
    make Multi : Multitherad 프로그램 생성 >> Multi

    make GPUtest : GPU 프로그램 test 1~5 수행결과 output/GPU에 저장
    make Singletest : Single thread프로그램 수행결과 output/Single에 저장
    make Multitest : Multithread 프로그램 수행결과 output/Multi에 저장

    make clean : 실행파일 모두 삭제

2. output
    첫줄에 수행시간 출력
    이후부터 원소별 비교 결과 출력 [일치할때 ---, 일치하지 않을때 "NON EQUAL"]
    가장 마지막줄 전체 결과 출력 [모두 일치 하는지]