#include <stdlib.h>
#include <stdio.h>
#define KERNEL_SIZE 3
#define TILE_SIZE 30
#define BLOCK_SIZE (TILE_SIZE)+(KERNEL_SIZE)-1

__constant__ float Mc[KERNEL_SIZE][KERNEL_SIZE];

void single_3DConv(){

}
void multi_3DConv(){
	
}
__global__ void 3DConv(float* N,float* P, int height, int width){


}
int main(int argc, const char** argv){
  int state, state2, state3;
    if(argc == 4){
        FILE *input_file = fopen(argv[1],"rt");
        FILE *kernel_file = fopen(argv[2],"rt");
        FILE *output_file = fopen(argv[3],"rt");
        if (input_file == NULL || kernel_file == NULL || output_file == NULL){
            printf("스트림 생성시 오류발생");
            return 1;
       }
       char a;
       while(1){
            if (feof(kernel_file) != 0){
                printf("복사가 완료되었습니다.\n");
                break;
            }


            a = fgetc(kernel_file);
            printf("%c ",a);
       }
       state = fclose(input_file);
        state2 = fclose(kernel_file);
        state3 = fclose(output_file);
    }else{
        printf("parameter 부족\n");
    }
    
    if (state != 0 || state2 != 0 || state3 != 0){
        printf("스트림 제거시 오류발생");
        return 1;
    }
    return 0;

}
