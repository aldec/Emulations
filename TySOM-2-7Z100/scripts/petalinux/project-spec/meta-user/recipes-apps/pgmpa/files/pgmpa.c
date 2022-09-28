/***************************** Include Files *******************************/
#include <stdio.h>
#include <stdint.h>
#include <sys/mman.h>
#include <fcntl.h>
#include <string.h>
#include <time.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <errno.h>
#include <sys/ioctl.h>
#include "axis-fifo.h"
/************************** Function Definitions ***************************/
void write_64bit(unsigned int* mem_ptr, unsigned long long int *data) {
    memcpy(mem_ptr, data, 8);
}

void write_single(unsigned int* mem_ptr, unsigned int addr, unsigned long long int data) {
    //printf("[I] data_in = %x\n\r", data);
    mem_ptr[addr/4] = data;
}

unsigned int * init(unsigned long long int addr, unsigned int size_len) {
    unsigned int *dut;
    int _fdmem1;
    size_t pagesize=0;

    //printf("\n[I] Init mem, address=%llu \n\r",addr);
    _fdmem1=open( "/dev/mem", O_RDWR | O_SYNC );

    if (_fdmem1 < 0){
        printf("\n[E] Failed to open the /dev/mem  !\n\r");
        return 0;
    }

    pagesize = sysconf(_SC_PAGE_SIZE);
    dut = (unsigned int*)mmap(NULL, size_len, PROT_READ|PROT_WRITE, MAP_SHARED, _fdmem1, ((addr/pagesize)*pagesize));

    if(dut == (unsigned int *)-1) {
        perror("\n[E] Error mapping\n\r");
        return 0;
    }

    return dut;
}

/************************** MAIN *******************************************/
int main(int argc, char *argv[])
{
    unsigned long long int GP_AXI_CTRL = 0x40000000;
    unsigned long long int GP_AXI_A = 0x41000000;
    unsigned long long int GP_AXI_B = 0x42000000;

    // device file locations
    char *fifo_out_dev =  "/dev/axis_fifo_0x43c00000";

    /* init fifo devices */
    int f_out = open(fifo_out_dev, O_RDONLY);
    int rc;

    // test error conditions
    if (f_out < 0) {
        printf("Open read out failed with error: %s\n", strerror(errno));
        return -1;
    }


    /* initialize the fifo core  */
    rc = ioctl(f_out, AXIS_FIFO_RESET_IP);
    if (rc) {
        perror("ioctl");
        return -1;
    }

    /* init memory map */
    unsigned int *gp_ctrl = init(GP_AXI_CTRL,32);
    unsigned int *gp_a = init(GP_AXI_A,32);
    unsigned int *gp_b = init(GP_AXI_B,32);

    unsigned long long int ull[256];
    unsigned long long int data_ll;

    FILE* f_prog;
    FILE* f_a;
    FILE* f_b;
    char path[1024];
    char* line = NULL;
    size_t line_size;
    char byte[8];
    char pathToFileA[1024] = "";
    char pathToFileB[1024] = "";
    char pathToFileProg[1024] = "";

    int a_data_ctr = 0;
    int b_data_ctr = 0;

    if (argc == 2) {//print help
        strcpy(path,argv[1]);
        printf("Starting from directory: %s\n",path);
    } else if (argc == 1) {
        strcpy(path,"./");
        printf("Starting from directory: %s\n",path);
    } else {//print help
        printf("    usage: ./pgcpu_prog <optional directory (default ./)> \n");
        exit(1);
    }

    strcat(pathToFileA,path);
    strcat(pathToFileA,"/busA.sim");
    f_a = fopen(pathToFileA, "r");
    if (f_a == NULL){
        printf("busA.sim file handle NULL\n");
        exit(2);
    }
    strcat(pathToFileB,path);
    strcat(pathToFileB,"/busB.sim");
    f_b = fopen(pathToFileB, "r");
    if (f_b == NULL){
        printf("busB.sim file handle NULL\n");
        exit(2);
    }
    strcat(pathToFileProg,path);
    strcat(pathToFileProg,"/prog.sim");
    f_prog = fopen(pathToFileProg, "r");
    if (f_prog == NULL){
        printf("prog.sim file handle NULL\n");
        exit(2);
    }

    //clear MPA registers
    printf("\n\nClear MPA registers\n");
    for(unsigned int t=0;t<16;t++){
        data_ll = 0x1bdULL;
        write_64bit(gp_a, &data_ll);
        data_ll = 0ULL;
        for(int k=0;k<44;k++) {
            write_64bit(gp_a, &data_ll);
        }
        data_ll = 0x101ULL | (unsigned long long)(t<<4);
        printf("%llx\n", data_ll);
        write_64bit(gp_ctrl, &data_ll);
    }

    printf("PROG\n");
    while ( !feof(f_prog) || !feof(f_a) || !feof(f_b) ) {
        //A
        if( !feof(f_a) && !(a_data_ctr > 128) ){
            int len = getline(&line, &line_size, f_a);
            data_ll = 0ULL;
            if(len > 23){
                for(int y=0;y<8;y++){
                    strncpy(byte, (line + 3*y), sizeof(byte));
                    byte[2] = '\0';
                    data_ll = data_ll | strtoull(byte,NULL,16) << 8*y;
                }
                //printf("\nA[%d]: %llx ", a_data_ctr,data_ll);
                write_64bit(gp_a, &data_ll);
                a_data_ctr++;
                for(int x=1;x<=64;x++){
                    data_ll = 0ULL;
                    if(len > 23 + x*24){
                        for(int y=0;y<8;y++){
                            strncpy(byte, (line + x*24+3*y), sizeof(byte));
                            byte[2] = '\0';
                            data_ll = data_ll | strtoull(byte,NULL,16) << 8*y;
                        }
                        //printf("%llx ", data_ll);
                        write_64bit(gp_a, &data_ll);
                    }
                }
            }
        }
        //B

        if( !feof(f_b) && !(b_data_ctr > 128) ){
            int len = getline(&line, &line_size, f_b);
            data_ll = 0ULL;
            if(len > 23){
                for(int y=0;y<8;y++){
                    strncpy(byte, (line + 3*y), sizeof(byte));
                    byte[2] = '\0';
                    data_ll = data_ll | strtoull(byte,NULL,16) << 8*y;
                }
//              printf("\nB[%d]: %llx ", b_data_ctr, data_ll);
                write_64bit(gp_b, &data_ll);
                b_data_ctr++;
                for(int x=1;x<=64;x++){
                    data_ll = 0ULL;
                    if(strlen(line) > 23 + x*24){
                        for(int y=0;y<8;y++){
                            strncpy(byte, (line + x*24+3*y), sizeof(byte));
                            byte[2] = '\0';
                            data_ll = data_ll | strtoull(byte,NULL,16) << 8*y;
                        }
//                      printf("%llx ", data_ll);
                        write_64bit(gp_b, &data_ll);
                    }
                }
            }
        }

        //CTRL

        if( !feof(f_prog) ){
            //printf("\nC\n");
            int len = getline(&line, &line_size, f_prog);
            data_ll = 0ULL;
            if(len > 5) {
                strncpy(byte, line, sizeof(byte));
                byte[2] = '\0';
                data_ll = strtoull(byte,NULL,16);
                strncpy(byte, (line + 3), sizeof(byte));
                byte[2] = '\0';
                data_ll = data_ll | (strtoull(byte,NULL,16) << 8);
                //printf("\nC: %llx ", data_ll);
                write_64bit(gp_ctrl, &data_ll);
                if( (data_ll >> 8) == 0x01ULL){
                    if( ( (data_ll & 0x0FULL ) == 0x01ULL ) ){
                        a_data_ctr--;
                    }
                    else if( ( (data_ll & 0x0FULL ) == 0x02ULL ) ){
                        b_data_ctr--;
                    }
                }
            }
            if(len > 10) {
                strncpy(byte, (line + 6), sizeof(byte));
                byte[2] = '\0';
                data_ll = strtoull(byte,NULL,16);
                strncpy(byte, (line + 9), sizeof(byte));
                byte[2] = '\0';
                data_ll = data_ll | (strtoull(byte,NULL,16) << 8);
                //printf("%llx ", data_ll);
                write_64bit(gp_ctrl, &data_ll);
                if( ( (data_ll & 0x0FULL ) == 0x03ULL ) ){
                    a_data_ctr--;
                    b_data_ctr--;
                }
            }
        }
    }


    printf("\nFinish PROG\n");

    getchar();

    //Y
    unsigned int read_buff[512];
    printf("\n\nRESULT\n");
    ssize_t bytes_read = read(f_out, &read_buff, 512);
    close(f_out);

    for (int i = 0; i < bytes_read/8; ++i) {
        ull[i] =  (unsigned long long)read_buff[(i*2)+1];
        ull[i] =  (ull[i]<<32) | (unsigned long long) read_buff[(i*2)];
        printf("%16llx \n",ull[i]);
    }

    /* close memory map */
    munmap(gp_a,32);
    munmap(gp_b,32);
    munmap(gp_ctrl,32);

    fclose(f_prog);
    fclose(f_a);
    fclose(f_b);

    return 0;
}
