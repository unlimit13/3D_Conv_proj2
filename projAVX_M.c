#include <stdio.h>
#include <stdlib.h>
#include <immintrin.h>
#include <pthread.h>

typedef struct params
{
  float*** input;
  float*** kernel;
  float*** output;
  int i,j,k,m;
  int kernel_size;
}Params;

void *woker(void *arg){
    Params *data = (Params *)arg;
    float **input_temp = aligned_alloc(32,sizeof(float*) * (data->kernel_size));
    float **kernel_temp = aligned_alloc(32,sizeof(float*) * (data->kernel_size));
    for(int l = 0; l<(data->kernel_size);l++){
        input_temp[l] = aligned_alloc(32,sizeof(float) * (data->kernel_size));
        kernel_temp[l] = aligned_alloc(32,sizeof(float) * (data->kernel_size));
    }
                     
    for(int o=0;o<(data->kernel_size);o++){
        for(int p=0;p<(data->kernel_size);p++){
            input_temp[o][p] = data->input[data->i+data->m][data->j+o][data->k+p];
            kernel_temp[o][p] = data->kernel[data->m][o][p];
                             
                            //output[i][j][k] += input[i+m][j+o][k+p] * kernel[m][o][p];
        }
    }
    __m256 A[data->kernel_size],B[data->kernel_size],result[data->kernel_size];
    for(int o=0;o<data->kernel_size;o++){
        A[o] = _mm256_load_ps(input_temp[o]);
        B[o] = _mm256_load_ps(kernel_temp[o]);
    }
    float *values[data->kernel_size];
    for(int o=0;o<data->kernel_size;o++){
        result[o] = _mm256_mul_ps(A[o],B[o]);
        values[o] = (float *)&result[o]; 
    }
    for(int o=0;o<data->kernel_size;o++){
        for(int v=0;v<data->kernel_size;v++){
            data->output[data->i][data->j][data->k] += values[o][v];
        }
    }
    pthread_exit(NULL);
}

void Multi_3DConv(float ***input,float ***kernel,float ***output,int row, int col, int height, int kernel_height){
    int height_length = height+((kernel_height-1))-(kernel_height-1); //여기도 지금 kernel 3기준임
    int col_length = col+((kernel_height-1))-(kernel_height-1);
    int row_length = row+((kernel_height-1))-(kernel_height-1);
    for(int i=0;i<height_length;i++){
        for(int j=0;j<col_length;j++){
            for(int k=0;k<row_length;k++){
                pthread_t *threads;
                threads = (pthread_t *)malloc(sizeof(pthread_t)*kernel_height);
                //printf("here1!\n");
                for(int m=0;m<kernel_height;m++){
                    Params* thread_params;
                    thread_params = (Params*)malloc(sizeof(Params));
                    //printf("here2!\n");
                    thread_params->input = input;
                    thread_params->kernel = kernel;
                    thread_params->output = output;
                    thread_params->i = i;
                    thread_params->j = j;
                    thread_params->k = k;
                    thread_params->m = m;
                    thread_params->kernel_size = kernel_height;
                    //printf("here3!\n");
                    //printf("m : %d\n",m);
                    pthread_create(&threads[m],NULL,woker,(void*)thread_params);
                    //pthread_detach(threads[m]);
                    //printf("here4\n");
                }
                for(int m=0;m<kernel_height;m++){
                    pthread_join(threads[m],NULL);
                }
                //printf("here5\n");
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
    int check = 0;
    Multi_3DConv(input,kernel,avx_output,row,col,height,kernel_height);
    for(int i=0;i<height;i++){
           for(int j=0;j<col;j++){
               for(int k=0;k<row;k++){
                   if(abs(output[i][j][k] - avx_output[i][j][k]) < 0.001f){
                       printf("equal!\n");
                   }
                   else{
                       //printf("not equal!\n");
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