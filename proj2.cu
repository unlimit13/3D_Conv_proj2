#include <stdlib.h>
#include <stdio.h>

#define TILE_SIZE 4
#define KERNEL_SIZE 5
#define BLOCK_SIZE (TILE_SIZE)-1
void verification(float* GPU, float* output, int height, int col, int row){
    for(int i=0;i<height;i++){
        for(int j=0;j<col;j++){
            for(int k=0;k<row;k++){
                printf("GPU : %f vs output : %f \n",GPU[i*(row*col)+j*row+k],output[i*(row*col)+j*row+k]);
                if(abs(GPU[i*(row*col)+j*row+k]-output[i*(row*col)+j*row+k]) < 0.001f){
                    printf("---\n");
                }
                else{
                    printf("NON EQUAL\n");
                }
            }
        }
    }

}

__constant__ float Kernel_const[KERNEL_SIZE*KERNEL_SIZE*KERNEL_SIZE];
__global__ void __3DConv(float* input_D,float* output_D,int height,int col,int row,int size){
	int tx=threadIdx.x;
    int ty=threadIdx.y;
    int tz=threadIdx.z;

    int row_o = blockIdx.x*TILE_SIZE+tx;
    int col_o = blockIdx.y*TILE_SIZE+ty;
    int hei_o = blockIdx.z*TILE_SIZE+tz;

    int row_i = row_o-((size-1)/2);
	int col_i = col_o-((size-1)/2);
    int hei_i = hei_o-((size-1)/2);


    float output=0.0f;
    __shared__ float input_slice[TILE_SIZE+KERNEL_SIZE-1][TILE_SIZE+KERNEL_SIZE-1][TILE_SIZE+KERNEL_SIZE-1];
	if((row_i>=0)&&(row_i<row)&&(col_i>=0)&&(col_i<col)&&(hei_i>=0)&&(hei_i<height)){
		input_slice[tz][ty][tx]=input_D[hei_i*(row*col)+col_i*row+row_i];
                      

	}
	else{
		input_slice[tz][ty][tx] = 0.0f;
	}
    __syncthreads();
    if(tz < TILE_SIZE && ty < TILE_SIZE && tx < TILE_SIZE){
		for(int i = 0; i < size; i++){
			for(int j = 0; j < size; j++){
				for(int k = 0; k < size; k++){
                    output += Kernel_const[i*(KERNEL_SIZE*KERNEL_SIZE)+j*(KERNEL_SIZE)+k] * input_slice[i+tz][j+ty][k+tx];
                }
			}
		}

        //__syncthreads();
		// some threads do not write output
		if (hei_o < height && col_o < col && row_o < row){
			output_D[hei_o*(row*col)+col_o*row+row_o] = output;
		}
	}
}
int main(int argc, const char** argv){
    int state, state2, state3,size,row,col,height;
    float *input, *kernel, *output; 
    if(argc == 4){
        FILE *input_file = fopen(argv[1],"rt");
        FILE *kernel_file = fopen(argv[2],"rt");
        FILE *output_file = fopen(argv[3],"rt");
        if (input_file == NULL || kernel_file == NULL || output_file == NULL){
            printf("스트림 생성시 오류발생");
            return 1;
       }
       char buffer[20],row_temp[20],col_temp[20],height_temp[20];
       fscanf(input_file,"%s",height_temp);
       fscanf(input_file,"%s",col_temp);
       fscanf(input_file,"%s",row_temp);
       height = atoi(height_temp);
       col = atoi(col_temp);
       row = atoi(row_temp);
       
       input = (float*)malloc(sizeof(float) * height*col*row);
       float num;
       for(int i=0;i<height;i++){
           for(int j=0;j<col;j++){
               for(int k=0;k<row;k++){
                    if (feof(input_file) != 0){
                        break;
                    }
                    fscanf(input_file,"%s",buffer);
                    num = atof(buffer);
                    input[i*(row*col)+j*row+k] = num;
                    
               }
           }
       }
       //input

       //kernel
       fscanf(kernel_file,"%s",height_temp);
       size = atoi(height_temp);
       kernel = (float*)malloc(sizeof(float)*KERNEL_SIZE*KERNEL_SIZE*KERNEL_SIZE);
  
        for(int i=0;i<size;i++){
            for(int j=0;j<size;j++){
                for(int k=0;k<size;k++){
                    if (feof(kernel_file) != 0){
                        break;
                    }
                    fscanf(kernel_file,"%s",buffer);
                    num = atof(buffer);
                    kernel[i*(KERNEL_SIZE*KERNEL_SIZE)+j*(KERNEL_SIZE)+k] = num;
                }
            }
        }
        //kernel

        //output
        fscanf(output_file,"%s",height_temp);
        fscanf(output_file,"%s",col_temp);
        fscanf(output_file,"%s",row_temp);
        height = atoi(height_temp);
        col = atoi(col_temp);
        row = atoi(row_temp);

        output = (float*)malloc(sizeof(float) * height*col*row);


       for(int i=0;i<height;i++){
           for(int j=0;j<col;j++){
               for(int k=0;k<row;k++){
                    if (feof(output_file) != 0){
                        break;
                    }
                    fscanf(output_file,"%s",buffer);
                    num = atof(buffer);
                    output[i*(row*col)+j*row+k] = num;
               }
           }
       }
    //output
       
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

	dim3 dimGrid(ceil(row/(TILE_SIZE*1.0)),ceil(col/(TILE_SIZE*1.0)),ceil(height/(TILE_SIZE*1.0)));
	dim3 dimBlock(BLOCK_SIZE+size,BLOCK_SIZE+size,BLOCK_SIZE+size);


	cudaEvent_t start, end;
	float time_ms_GPU=0;
	cudaEventCreate(&start);
	cudaEventCreate(&end);


    float *input_D,*output_D,*output_result;
    output_result = (float*)malloc(sizeof(float)*height*col*row);
    memset(output_result, 0, height*col*row*sizeof(float));

    cudaMalloc((void**)&input_D,sizeof(float)*height*col*row);
    cudaMemcpy(input_D,input,sizeof(float)*height*col*row,cudaMemcpyHostToDevice);
    cudaMalloc((void**)&output_D,sizeof(float)*height*col*row);
    cudaMemcpy(output_D,output_result,sizeof(float)*height*col*row,cudaMemcpyHostToDevice);
    cudaMemcpyToSymbol(Kernel_const,kernel,sizeof(float)*KERNEL_SIZE*KERNEL_SIZE*KERNEL_SIZE);


	cudaEventRecord(start,0);
	__3DConv<<<dimGrid,dimBlock>>>(input_D,output_D,height, col, row, size);
    cudaDeviceSynchronize();
	cudaMemcpy(output_result,output_D,row*col*height*sizeof(float),cudaMemcpyDeviceToHost);
    cudaEventRecord(end,0);
	cudaEventSynchronize(end);
	cudaEventElapsedTime(&time_ms_GPU,start,end);
    printf("\nExecution time for kernel: %.2f ms\n",time_ms_GPU);

    verification(output_result,output,height,col,row);


    return 0;

}
