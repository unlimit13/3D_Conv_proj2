#include <stdlib.h>
#include <stdio.h>
#define KERNEL_SIZE 3

__constant__ float Mc[KERNEL_SIZE][KERNEL_SIZE];

void single_3DConv(){

}
void multi_3DConv(){

}
__global__ void _3DConv(){
	__syncthreads();

}
int main(int argc, const char** argv){
    int state, state2, state3;
    float ***input, ***kernel, ***output; 
    if(argc == 4){
        FILE *input_file = fopen(argv[1],"rt");
        FILE *kernel_file = fopen(argv[2],"rt");
        FILE *output_file = fopen(argv[3],"rt");
        if (input_file == NULL || kernel_file == NULL || output_file == NULL){
            printf("스트림 생성시 오류발생");
            return 1;
       }
       char buffer[20],row_temp[20],col_temp[20],height_temp[20];
       int row,col,height;
       fscanf(input_file,"%s",height_temp);
       fscanf(input_file,"%s",col_temp);
       fscanf(input_file,"%s",row_temp);
       height = atoi(height_temp);
       row = atoi(row_temp);
       col = atoi(col_temp);
       
       input = (float***)malloc(sizeof(float**) * height);
       for(int i=0; i<height; i++){
           input[i] = (float**)malloc(sizeof(float*) * col);
           for(int j=0; j<col; j++){
                input[i][j] = (float*)malloc(sizeof(float) * row);
           }
       }

       float num;
       for(int i=0;i<height;i++){
           for(int j=0;j<col;j++){
               for(int k=0;k<row;k++){
                    if (feof(input_file) != 0){
                        break;
                    }
                    fscanf(input_file,"%s",buffer);
                    num = atof(buffer);
                    input[i][j][k] = num;
               }
           }
       }
       //input

       //kernel
       fscanf(kernel_file,"%s",height_temp);
       height = atoi(height_temp);
       kernel = (float***)malloc(sizeof(float**) * height);
       for(int i=0; i<height; i++){
            kernel[i] = (float**)malloc(sizeof(float*) * height);
           for(int j=0; j<height; j++){
                kernel[i][j] = (float*)malloc(sizeof(float) * height);
           }
       }
        for(int i=0;i<height;i++){
            for(int j=0;j<height;j++){
                for(int k=0;k<height;k++){
                    if (feof(kernel_file) != 0){
                        break;
                    }
                    fscanf(kernel_file,"%s",buffer);
                    num = atof(buffer);
                    kernel[i][j][k] = num;
                }
            }
        }
        //kernel

        //output
        fscanf(output_file,"%s",height_temp);
        fscanf(output_file,"%s",col_temp);
        fscanf(output_file,"%s",row_temp);
        height = atoi(height_temp);
        row = atoi(row_temp);
        col = atoi(col_temp);

        output = (float***)malloc(sizeof(float**) * height);
       for(int i=0; i<height; i++){
        output[i] = (float**)malloc(sizeof(float*) * col);
           for(int j=0; j<col; j++){
                output[i][j] = (float*)malloc(sizeof(float) * row);
           }
       }

       for(int i=0;i<height;i++){
           for(int j=0;j<col;j++){
               for(int k=0;k<row;k++){
                    if (feof(output_file) != 0){
                        break;
                    }
                    fscanf(output_file,"%s",buffer);
                    num = atof(buffer);
                    output[i][j][k] = num;
               }
           }
       }
       printf("%f \n",output[0][0][0]);
       printf("%f \n",output[0][0][1]);
       printf("%f \n",output[0][0][2]);
       
       state = fclose(input_file);
       state2 = fclose(kernel_file);
       state3 = fclose(output_file);
    }
	else{
        printf("parameter 부족\n");
    }
    
    if (state != 0 || state2 != 0 || state3 != 0){
        printf("스트림 제거시 오류발생");
        return 1;
    }

	dim3 dimGrid(1,1,1);
	dim3 dimBlock(1,1,1);

	cudaEvent_t start, end;
	float time_ms_single=0, time_ms_multi=0, time_ms_GPU=0;
	cudaEventCreate(&start);
	cudaEventCreate(&end);

	cudaEventRecord(start,0);
	single_3DConv();
	cudaEventRecord(end,0);
	cudaEventSynchronize(end);
	cudaEventElapsedTime(&time_ms_single,start,end);

	cudaEventRecord(start,0);
	multi_3DConv();
	cudaEventRecord(end,0);
	cudaEventSynchronize(end);
	cudaEventElapsedTime(&time_ms_multi,start,end);

	cudaEventRecord(start,0);
	_3DConv<<<dimGrid,dimBlock>>>();
	cudaEventRecord(end,0);
	cudaEventSynchronize(end);
	cudaEventElapsedTime(&time_ms_GPU,start,end);

    return 0;

}
