#include "firmware.h"
#define K						5
#define MAX_INT                 2147483647
#define DATA_LENGTH             3073
#define NUM_CLASS				10
#define NUM_TEST_IMAGE			50
#define NUM_TRAIN_IMAGE			950
#define IMAGE_OFFSET 			0x00010000
void knn_pcpi(void){
	int ans;
	print_str("enter");
	ans = hard_knn_pcpi(1, 1);
}
