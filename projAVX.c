#include <immintrin.h>
#include <x86intrin.h>
#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <ctype.h>
#include <time.h>
#include <unistd.h>

void single_3DConv(float ***input,float ***kernel,float ***output,int row, int col, int height, int kernel_height){
    for(int i=0;i<height;i++){
        for(int j=0;j<col;j++){
            for(int k=0;k<row;k++){
                 for(int m=0;m<kernel_height;m++){
                     float **input_temp = aligned_alloc(32,sizeof(float*) * kernel_height);
                     float **kernel_temp = aligned_alloc(32,sizeof(float*) * kernel_height);
                     for(int l = 0; l<kernel_height;l++){
                         input_temp[l] = aligned_alloc(32,sizeof(float) * kernel_height);
                         kernel_temp[l] = aligned_alloc(32,sizeof(float) * kernel_height);
                     }
                     
                     for(int o=0;o<kernel_height;o++){
                         for(int p=0;p<kernel_height;p++){
                             input_temp[o][p] = input[i+m][j+o][k+p];
                             kernel_temp[o][p] = kernel[m][o][p];
                             
                            //output[i][j][k] += input[i+m][j+o][k+p] * kernel[m][o][p];
                         }
                     }
                      __m256 A[kernel_height],B[kernel_height],result[kernel_height];
                    for(int o=0;o<kernel_height;o++){
                        A[o] = _mm256_load_ps(input_temp[o]);
                        B[o] = _mm256_load_ps(kernel_temp[o]);
                    }
                    float *values[kernel_height];
                    for(int o=0;o<kernel_height;o++){
                        result[o] = _mm256_mul_ps(A[o],B[o]);
                        values[o] = (float *)&result[o]; 
                    }
                    for(int o=0;o<kernel_height;o++){
                        for(int v=0;v<kernel_height;v++){
                            output[i][j][k] += values[o][v];
                        }
                    }

                 }
            }
            
        }
    
    }
   
}

int main(int argc, char **argv)
{
    int state, state2, state3;
    float ***input, ***kernel, ***output, ***avx_output; 
    int row,col,height,kernel_height;

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
       row = atoi(row_temp);
       col = atoi(col_temp);
       char kernel_temp[20];
       fscanf(kernel_file,"%s",kernel_temp);
       kernel_height = atoi(kernel_temp);

       input = aligned_alloc(32, sizeof(float**) * (height+(kernel_height-1)));

       for(int i=0; i<(height+(kernel_height-1)); i++){
           input[i] = aligned_alloc(32, sizeof(float*) * (col+(kernel_height-1)));
           for(int j=0; j<(col+(kernel_height-1)); j++){
                input[i][j] = aligned_alloc(32, sizeof(float) * (row+(kernel_height-1)));
           }
       }

       avx_output = aligned_alloc(32, sizeof(float**) * (height));

       for(int i=0; i<(height); i++){
           avx_output[i] = aligned_alloc(32, sizeof(float*) * (col));
           for(int j=0; j<(col); j++){
                avx_output[i][j] = aligned_alloc(32, sizeof(float) * (row));
           }
       }


       for(int i=0;i<height;i++){
           for(int j=0;j<col;j++){
               for(int k=0;k<row;k++){
                   avx_output[i][j][k] = 0;
               }
           }
       } 
       float num;
       int boundary = (kernel_height - 1) / 2;
       for(int i=0;i<height+((kernel_height-1));i++){
           for(int j=0;j<col+((kernel_height-1));j++){
               for(int k=0;k<row+((kernel_height-1));k++){
                    if (feof(input_file) != 0){
                            break;
                    }
                    if(i < (kernel_height-1)/2 || j < (kernel_height-1)/2 || k < (kernel_height-1)/2){ //이거 지금 kernel size 3일때만 되니까, 나중에 5일때도 되도록 바꿔주렴.
                        input[i][j][k] = 0;
                    }
                    else if(i >= height+((kernel_height-1))-(kernel_height-1)/2 || j >= col+((kernel_height-1))-(kernel_height-1)/2 || k >= row+((kernel_height-1))-(kernel_height-1)/2){
                        input[i][j][k] = 0;
                    }
                    else{
                        fscanf(input_file,"%s",buffer);
                        num = atof(buffer);
                        input[i][j][k] = num;
                    }
               }
           }
       }
       //input

       //kernel
       
       kernel = aligned_alloc(32, sizeof(float**) * kernel_height);
       for(int i=0; i<kernel_height; i++){
            kernel[i] = aligned_alloc(32, sizeof(float*) * kernel_height);
           for(int j=0; j<kernel_height; j++){
                kernel[i][j] = aligned_alloc(32, sizeof(float) * kernel_height);
           }
       }
        for(int i=0;i<kernel_height;i++){
            for(int j=0;j<kernel_height;j++){
                for(int k=0;k<kernel_height;k++){
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

        output = aligned_alloc(32, sizeof(float**) * height);
       for(int i=0; i<height; i++){
        output[i] = aligned_alloc(32, sizeof(float*) * col);
           for(int j=0; j<col; j++){
                output[i][j] = aligned_alloc(32, sizeof(float) * row);
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
    clock_t start, end;
    int check = 0;
    start = clock();
    single_3DConv(input,kernel,avx_output,row,col,height,kernel_height);
    end = clock();;
    printf("\nExecution time for kernel: %f s\n",(float)(end-start)/CLOCKS_PER_SEC);
    for(int i=0;i<height;i++){
           for(int j=0;j<col;j++){
               for(int k=0;k<row;k++){
                   printf("Single : %f vs output : %f \n",avx_output[i][j][k],output[i][j][k]);
                   if(abs(output[i][j][k] - avx_output[i][j][k]) < 0.001f){
                       printf("---\n");
                   }
                   else{
                       printf("NON EQUAL\n");
                       check = 1;
                   }
               }
           }
       } 
    if(check){
        printf("Results are not eqaul!\n");
    }else{
        printf("Results are equal\n");
    }

    return 0;
}