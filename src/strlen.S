#define ALIGN_TEXT      .p2align 4,0x90 /* 16-byte alignment, nop filled */

#define original_ptr		x0
#define	result_reg		x0
#define new_ptr			x11
#define ref_ptr			x14
#define shift			x12
#define mask_reg		x13
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
	bic 	new_ptr, 	original_ptr, #0xF 	// align to 16B boundary
	ld1 	{data_vec.16b}, [new_ptr]  		// load 16 bytes into v0
	cmeq	comp_vec.16b, 	data_vec.16b, #0 	// equivalent to pcmpeqb
	lsl	shift, 		original_ptr, #2
	shrn	mask_vec.8b, 	comp_vec.8h, #4		// get then nibble mask
	fmov	mask_reg,	low_64_of_mask_vec	// move mask vec to reg
	lsr	mask_reg, 	mask_reg, shift
	cbnz	mask_reg,	exit

	ALIGN_TEXT
body_loop:
	add	new_ptr,	new_ptr, #16		// move new_ptr up 16 bytes
	ld1 	{data_vec.16b}, [new_ptr]		// load the vector up at this new address
	cmeq	comp_vec.16b, 	data_vec.16b, #0 	// find any null bytes
	shrn	mask_vec.8b, 	comp_vec.8h, 4 		// get then nibble mask
	fmov	mask_reg,	low_64_of_mask_vec	// move mask vec to reg
	cbz	mask_reg,	body_loop		// if all zeros then no null terminator

	//null terminator found in body
	sub	result_reg,	new_ptr, original_ptr	// subtract the new_ptr from original
	rbit	mask_reg,	mask_reg		// reverse for counting
	clz	lead_zero_reg,	mask_reg		// result should be result_reg plus the leading zeros from this
	lsr 	lead_zero_reg, 	lead_zero_reg, #2
	add	result_reg,	result_reg, lead_zero_reg
	ret

exit:
	/* need to think how this part will be affected by leading junk */
	rbit	mask_reg,	mask_reg		// reverse the bits
	clz	result_reg,	mask_reg		// cnt leading zeros
	lsr 	result_reg, 	result_reg, #2
	ret

.section .text.end
