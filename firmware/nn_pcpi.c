#include "firmware.h"
#define K						5
#define MAX_INT                 2147483647
#define DATA_LENGTH             3073
#define NUM_CLASS				10
#define NUM_TEST_IMAGE			50
#define NUM_TRAIN_IMAGE			950
#define IMAGE_OFFSET 			0x00010000
void nn_pcpi(void){
	int ans;
	print_str("Now Testing the nn coprocessor");
	int begin = tick();
	ans = hard_nn_pcpi(0,0);
	int end = tick();
	print_str("The image is: ");
	print_dec(ans);
	print_str("\n");
	print_str("Time elapsed: ");
	print_dec(end - begin);
	print_str("\n");
	begin = tick();
	ans = hard_nn_pcpi(1,0);
	end = tick();
	print_str("The image is: ");
	print_dec(ans);
	print_str("\n");
	print_str("Time elapsed: ");
	print_dec(end - begin);
	print_str("\n");
	begin = tick();
	ans = hard_nn_pcpi(2,0);
	end = tick();
	print_str("The image is: ");
	print_dec(ans);
	print_str("\n");
	print_str("Time elapsed: ");
	print_dec(end - begin);
	print_str("\n");


}
