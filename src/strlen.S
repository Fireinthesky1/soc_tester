#define ALIGN_TEXT      .p2align 4,0x90 /* 16-byte alignment, nop filled */

#define original_ptr		x0
#define	result_reg		x0
#define new_ptr			x11
#define ref_ptr			x14
#define shift			x12
#define mask_reg		x13
#define partial_len_reg		x14
#define lead_zero_reg		x15
#define data_vec		v0
#define comp_vec		v1
#define mask_vec		v2
#define low_64_of_mask_vec	d2

.text
.global strlen

strlen:
	// program starts here
	// initial scrub
	mov 	new_ptr, 	original_ptr		// move string pointer
	and 	original_ptr, 	original_ptr, #~0xF 	// align to 16B boundary
	ld1 	{data_vec.16b}, [original_ptr]  	// load 16 bytes into v0
	cmeq	comp_vec.16b, 	data_vec.16b, #0 	// equivalent to pcmpeqb
	mov	new_ptr,	ref_ptr			// ref ptr for later
	and 	shift,		new_ptr, #0xF		// num bytes past align
	shrn	mask_vec.8b, 	comp_vec.8h, 4 		// get then nibble mask
	add	original_ptr,	original_ptr, #32	// move up 32 bytes
	fmov	mask_reg,	low_64_of_mask_vec	// move mask vec to reg
	lsr	mask_reg, 	mask_reg, shift

	/*
	 * there may be junk bytes before the start of the string
	 * that are 0. So we shift the mask right by the number of
	 * bytes we were past alignment to get erroneous matches
	 * out of the mask
	 */

	/*
	 * the mask will be zero if there are no null bytes
	 * if the mask IS NOT zero we should get the string length
	 * and return. Otherwise keep tying
	 */
	cbnz	mask_reg,	exit

	ALIGN_TEXT
loop:
	eor	data_vec.16b,	data_vec.16b, data_vec.16b
	sub	x7,		original_ptr, #16	// go back 16
	ld1 	{data_vec.16b}, [x7] 		 	// load 16 more bytes
	cmeq	comp_vec.16b, 	data_vec.16b, #0 	// equivalent to pcmpeqb
	shrn	mask_vec.8b, 	comp_vec.8h, 4 		// get then nibble mask
	fmov	mask_reg,	low_64_of_mask_vec	// move mask vec to reg
	cbnz	mask_reg,	.body_exit

	// the same unrolled once more
	eor	data_vec.16b,	data_vec.16b, data_vec.16b
	ld1 	{data_vec.16b}, [original_ptr]  	// load 16 more bytes
	cmeq	comp_vec.16b, 	data_vec.16b, #0 	// equivalent to pcmpeqb
	shrn	mask_vec.8b, 	comp_vec.8h, 4 		// get then nibble mask
	fmov	mask_reg,	low_64_of_mask_vec	// move mask vec to reg
	add	original_ptr,	original_ptr, #32	// move up 32 bytes
	cbz	mask_reg,	loop

	//match found in loop body
	sub	original_ptr,	original_ptr, #16	// move pointer back
body_exit:
	rbit	mask_reg,	mask_reg		// reverse for counting
	clz	lead_zero_reg,	mask_reg		// cnt leading 0's
	sub	partial_len_reg,ref_ptr, original_ptr	// length w/o lead zeros
	add	result_reg,	partial_len_reg, lead_zero_reg
	ret

exit:
	/* need to think how this part will be affected by leading junk */
	rbit	mask_reg,	mask_reg		// reverse the bits
	clz	result_reg,	mask_reg		// cnt leading zeros
	ret

.section .text.end
