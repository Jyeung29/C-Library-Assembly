		AREA	|.text|, CODE, READONLY, ALIGN=2
		THUMB

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; System Call Table
HEAP_TOP	EQU		0x20001000
HEAP_BOT	EQU		0x20004FE0
MAX_SIZE	EQU		0x00004000		; 16KB = 2^14
MIN_SIZE	EQU		0x00000020		; 32B  = 2^5
	
MCB_TOP		EQU		0x20006800      	; 2^10B = 1K Space
MCB_BOT		EQU		0x20006BFE
MCB_ENT_SZ	EQU		0x00000002		; 2B per entry
MCB_TOTAL	EQU		512			; 2^9 = 512 entries
	
INVALID		EQU		-1			; an invalid id
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Memory Control Block Initialization
		EXPORT	_heap_init
_heap_init
	;; Implement by yourself
	LDR R0, =MCB_TOP
	LDR R1, =MAX_SIZE
	STR R1, [R0] ;Indicate Available Max Size Space in Heap
	
	LDR R1, =MCB_BOT
	MOV R2, #0
zero_heap 
	STR R2, [R0, #4]! ;Set heap word value to 0 with Pre-index writeback
	CMP R0, R1 ;Compare whether reached bottom of heap
	BLS zero_heap ;Keep going if less than or equal to MCB_BOT
heap_end 
		MOV		pc, lr

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Kernel Memory Allocation
; void* _k_alloc( int size )
		EXPORT	_kalloc
_kalloc
	;; Implement by yourself
	LDR R1, =MCB_TOP ;R1 = Left
	LDR R2, =MCB_BOT ;R2 = Right
	CMP R0, #32 ;R0 = Size
	BHS _ralloc
	MOV R0, #32 ;Set minimum size
	B _ralloc

_ralloc ;Equivalent Helper Function
	PUSH{LR}
	
	SUB R3, R2, R1
	LDR R4, =MCB_ENT_SZ
	ADD R3, R4 ;R3 = entire
	LSR R4, R3, #1 ;R4 = half
	ADD R5, R1, R4 ;R5 = midpoint
	LSL R6, R3, #4 ;R6 = act_entire_size
	LSL R7, R4, #4 ;R7 = act_half_size
	LDR R12, =INVALID ;R12 = heap_addr
	
	CMP R0, R7
	BLS _allocMove ;Skip allocation if size < act_half_size
	
	LDR R8, [R1]
	LSRS R9, R8, #1 ;Check if occupy bit is 1 by dividing 2 and find carry bit
	BCS _allocReturn ;Carry bit present then is occupied
_allocAddress ;Allocate Space
	ADD R6, #1
	STRB R6, [R1]
	LDR R11, =HEAP_TOP
	LDR R10, =MCB_TOP
	MOV R12, R1
	SUB R12, R10 ;Left - MCB_TOP
	LSL R12, #4 ;multiply by 16
	ADD R12, R11 ;Add HEAP_TOP for final heap_addr
	MOV R0, R12 ;Return Heap Address
	
_allocReturn	
	POP {LR}
	BX LR
	
_allocMove
	LDR R8, [R1] ;Value at left
	CMP R8, #0 ;Compare if left value is 0x0000
	BEQ _preAssign ;If so can preAssign
	CMP R8, R7 ;if word value > act_half_size
	BLS _allocBigBudSize ;Check both are true
	LSRS R9, R8, #1 ;Check if not occupied
	BCS _allocBigBudSize
	
_preAssign
	STR R7, [R1] ;Assign left with act_half_size
	
_allocBigBudSize 
	LDR R10, [R5] ;Word value of Midpoint
	CMP R8, R7 ;if midpoint value > act_half_size
	BLS _allocSameBudSize ;If at least 1 is not true try other option
	LSRS R9, R8, #1 ;Check if not occupied
	BCC _allocBuddy
_allocSameBudSize
	CMP R10, #0 ;Check if midpoint is empty
	BNE _leftAlloc
	CMP R8, R7 ;if left wordvalue == act_half_size
	BNE _leftAlloc
	
_allocBuddy
	STR R7, [R5] ;assign buddy act_half_size to midpoint address

_leftAlloc
	PUSH{R1-R7} ;Need to maintain previous recursive information
	MOV R2, R5 ;Assign midpoint as right
	LDR R9, =MCB_ENT_SZ
	SUB R2, R9 ;midpoint-mcb_ent_sz
	BL _ralloc
	;See if Right Is Needed
	POP {R1-R7}
	LDR R11, =INVALID
	CMP R12, R11 ;Check if heap_addr is NULL
	BNE _rallocDone
	LDR R8, [R1]
	CMP R8, R6
	BEQ _rallocDone ;Check if value of left address == act_entire_size
	ADD R9, R6, #1
	CMP R8, R9 
	BEQ _rallocDone ;Check if value of left address == act_entire_size + 1
_rightAlloc	
	MOV R1, R5 ;Assign midpoint as left
	BL _ralloc

_rallocDone
		POP {LR}
		MOV		pc, lr
		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Kernel Memory De-allocation
; void free( void *ptr )
		EXPORT	_kfree
_kfree
	;; Implement by yourself
	;R0 = ptr/addr
	LDR R1, =HEAP_TOP
	LDR R2, =HEAP_BOT
	CMP R0, R1
	BLO _kfreeNull
	CMP R0, R2
	BHI _kfreeNull
	
	SUB R1, R0, R1 ;addr - heap_top
	LSR R1, #4 ;Divide by 16
	LDR R2, =MCB_TOP 
	ADD R1, R2 ;R1 = MCB_ADDR

_rfreeValid
	LDR R2, [R1]
	LSRS R2, #1 ;Check if is occupied and needs to be freed
	MOVCC R0, #0 ;Return 0 value for invalid
	BCC _kfreeDone
_rfree
	PUSH{LR}
	LDR R2, =MCB_TOP
	SUB R2, R1, R2 ;R2 = mcb_offset
	LDR R3, [R1] ;R3 = mcb_contents
	LSR R3, #4 ;Divide by 16
	MOV R4, R3 ;R4 = mcb_chunk
	LSL R3, #4 ;Clear used Bit
	MOV R5, R3 ;R5 = my_size
	STR R3, [R1] ;Assign new cleared value
	
	UDIV R6, R2, R4 ;Divide MCB_OFFSET by MCB_CHUNK
	LSRS R6, #1	;Divide by 2 and check for Carry Bit
	BCS _freeRight
	
_freeLeft
	ADD R6, R1, R4 ;MCB_BUDDY
	LDR R7, =MCB_BOT
	CMP R6, R7
	BHI _freeRecursive
	LDR R7, [R6] ;Value of Buddy
	LDR R8, [R1] ;Value of MCB_ADDR
	CMP R7, R8
	BNE _freeRecursive
	MOV R7, #0 ;Clear Buddy
	STR R7, [R6]
	LSL R5, #1 ;Merge Buddy
	STR R5, [R1]
	BL _rfree ;Recursive Call _rfree(mcb_addr)
	B _freeRecursive
_freeRight
	SUB R6, R1, R4 ;MCB_BUDDY
	LDR R7, =MCB_TOP
	CMP R6, R7
	BLO _freeRecursive
	LDR R7, [R6] ;Value of Buddy
	LDR R8, [R1] ;Value of MCB_ADDR
	CMP R7, R8
	BNE _freeRecursive
	MOV R8, #0 ;Clear Right MCB
	STR R8, [R1]
	LSL R5, #1 ;Left buddy is new MCB
	STR R5, [R6]
	MOV R1, R6
	BL _rfree
	
_freeRecursive
	POP{LR}
	BX LR
	CMP R1, #0
	BNE _kfreeDone
	
_kfreeNull
	LDR R0, =INVALID ;Return Invalid
_kfreeDone
	POP{LR}
		MOV		pc, lr					; return from rfree( )

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;void* _memcpy(void* dest, const void* src, int size)
	EXPORT _kmemcpy
		;R0: dest heap address
		;R1: src heap address
		;R2: size bytes
_kmemcpy
	;Calculate MCB Addresses
	CMP R0, #0
	BLS _memcpyDone
	LDR R3, =MCB_TOP
	LDR R4, =HEAP_TOP
	SUB R5, R0, R4
	ADD R5, R3, R5, LSR #4 ;R5 = mcb_addr of dest
	SUB R6, R1, R4
	ADD R6, R3, R6, LSR #4 ;R6 = mcb_addr of src
	
	;Check for size so no overflow occurs
	LDR R7, [R6] ;Size + Occupy of SRC
	LDR R8, [R5] ;Size + Occupy of DEST
	SUB R7, #1 ;Assume to be occupied
	SUB R8, #1
	MOV R3, R0 ;R3 = Iterating Heap Address of Dest
	MOV R4, R1 ;R4 = Iterating Heap Address of SRC
	CMP R2, R7 ;Compare Size want to copy and actual source size
	BHI _biggerSize
	
_smallerSize ;Size <= SRC Size
	 CMP R2, R8 ;Compare Size and dest size
	 MOVHI R2, R8 ;If size > dest size then use dest size instead
	 ADD R5, R3, R8 ;R5 = Last Finishing Address DEST
	 ADD R6, R4, R2 ;R6 = Last Finishing Address SRC
_cpyAssign
	LDRB R7, [R4] ;Retrieve byte from SRC
	STRB R7, [R3] ;Assign byte from SRC to Dest
	ADD R3, #1
	ADD R4, #1
	CMP R4, R6 ;Compare if src copy is done
	BNE _cpyAssign
	CMP R3, R5 ;Compare if need to zero rest of dest
	BEQ _memcpyDone
	MOV R7, #0
	B _zeroCpy
_biggerSize ;Size > SRC Size
	CMP R2, R8 ;Compare Size and dest size
	BLS _lessBigger
	B _moreBigger
_lessBigger	
	ADD R5, R3, R8 ;R5 = Last Finishing Address DEST
	ADD R6, R4, R7 ;R6 = Last Finishing Address SRC (Max without overflow)
	B _cpyAssign
_moreBigger
	MOV R2, R8 ;Use dest size instead
	ADD R5, R3, R2 ;R5 = Last Finishing Address DEST
	ADD R6, R4, R7 ;R6 = Last Finishing Address SRC (Max without overflow)
	B _cpyAssign
_zeroCpy
	STRB R7, [R3] ;Assign byte of dest to 0
	ADD R3, #1 ;Increment dest address
	CMP R3, R5 ;Compare if dest zero is done
	BNE _zeroCpy
_memcpyDone
	MOV PC,LR
		END
