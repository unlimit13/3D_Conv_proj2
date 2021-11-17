#include <stdlib.h>
#include <stdio.h>
#define KERNEL_SIZE 3
#define TILE_SIZE 30
#define BLOCK_SIZE (TILE_SIZE)+(KERNEL_SIZE)-1

__constant__ float Mc[KERNEL_SIZE][KERNEL_SIZE];

__global__ void 3DConv(float* N,float* P, int height, int width){


}
int main(int argc, const char** argv){
    
    int row_i = atoi(argv[1]);
    int col_i = atoi(argv[2]);
    dim3 dimGrid(ceil(row_i/(TILE_SIZE*1.0)), ceil(col_i/(TILE_SIZE*1.0)),1);
	dim3 dimBlock(BLOCK_SIZE,BLOCK_SIZE,1);



    float *N = (float*)malloc(sizeof(float)*row_i*col_i);
    float M[KERNEL_SIZE][KERNEL_SIZE];
	float* M_ver = (float*)malloc(sizeof(float)*KERNEL_SIZE*KERNEL_SIZE);
    float *result = (float*)malloc(sizeof(float)*row_i*col_i);

	cudaMemcpyToSymbol(Mc,M,sizeof(float)*KERNEL_SIZE*KERNEL_SIZE);
	cudaMemcpy(N_D,N,row_i*col_i*sizeof(float),cudaMemcpyHostToDevice);
    

    Conv<<<dimGrid,dimBlock>>>(N_D,result_D,row_i,col_i);
	cudaMemcpy(result,result_D,row_i*col_i*sizeof(float),cudaMemcpyDeviceToHost);
	verification(N, M_ver, result, row_i, col_i);

	cudaFree(N_D);
	cudaFree(result_D);
	cudaFree(Mc);
	free(N);
	free(M_ver);
	free(result);

	return 0;
}
