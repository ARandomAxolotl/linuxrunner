#include "app/LinuxRunner/RFBProtocol.h"
#include <assert.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
int main(void){
    size_t bytes=0;assert(lr_rfb_dimensions(640,480,&bytes)&&bytes==1228800);
    assert(!lr_rfb_dimensions(0,1,&bytes));assert(!lr_rfb_dimensions(2561,1,&bytes));assert(!lr_rfb_dimensions(1,1601,&bytes));
    assert(lr_rfb_dimensions(2560,1600,&bytes)&&bytes==16384000);assert(lr_rfb_dimensions(824,1200,&bytes));  // Fit Screen / external displays
    uint8_t storage[4*4*4+32];memset(storage,0xa5,sizeof storage);uint8_t source[16];memset(source,0x42,sizeof source);
    assert(lr_rfb_apply_raw(storage+16,4,4,1,1,2,2,source,16));
    assert(storage[16+(1*4+1)*4]==0x42&&storage[16+(2*4+2)*4]==0x42&&storage[16]==0xa5);
    assert(!lr_rfb_apply_raw(storage+16,4,4,3,3,2,2,source,16));
    assert(!lr_rfb_apply_raw(storage+16,4,4,1,1,2,2,source,15));
    assert(!lr_rfb_rectangle(4,4,65535,0,1,1,&bytes));
    assert(!lr_rfb_rectangle(4,4,4,0,1,1,&bytes));
    assert(lr_rfb_reverse_bits(0x12)==0x48);
    for(size_t i=0;i<16;i++)assert(storage[i]==0xa5&&storage[sizeof(storage)-i-1]==0xa5);
    uint8_t color[4]={1,2,3,4};assert(lr_rfb_fill(storage+16,4,4,3,3,1,1,color));
    assert(storage[16+60]==1&&storage[16+63]==4);
    assert(!lr_rfb_fill(storage+16,4,4,3,3,2,1,color));
    for(size_t i=0;i<16;i++)assert(storage[i]==0xa5&&storage[sizeof(storage)-i-1]==0xa5);
    srand(47);for(unsigned i=0;i<50000;i++){
        uint16_t x=rand(),y=rand(),w=rand(),h=rand();
        if(lr_rfb_rectangle(640,480,x,y,w,h,&bytes))assert((size_t)x+w<=640&&(size_t)y+h<=480&&bytes<=1228800);
    }
    puts("RFB bounded rectangle, guard bytes, malformed dimensions and randomized bounds passed");
}
