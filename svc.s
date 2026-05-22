		AREA	|.text|, CODE, READONLY, ALIGN=2
		THUMB

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; System Call Table
SYSTEMCALLTBL	EQU		0x20007B00 ; originally 0x20007500
SYS_EXIT		EQU		0x0		; address 20007B00
SYS_ALARM		EQU		0x1		; address 20007B04
SYS_SIGNAL		EQU		0x2		; address 20007B08
SYS_MALLOC		EQU		0x3		; address 20007B0C
SYS_FREE		EQU		0x4		; address 20007B10
SYS_MEMCPY		EQU		0x5		; address 20007B14

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; System Call Table Initialization
		EXPORT	_syscall_table_init
_syscall_table_init
	;; Implement by yourself
	IMPORT _kfree
	IMPORT _kalloc
	IMPORT _signal_handler
	IMPORT _timer_start
	IMPORT _kmemcpy
		
	LDR R1, =SYSTEMCALLTBL
	LDR R2, =_timer_start ;Assign _timer_start to alarm
	STR R2, [R1, #4]!
	LDR R2, =_signal_handler ;Assign _signal_handler to signal
	STR R2, [R1, #4]!
	LDR R2, =_kalloc
	STR R2, [R1, #4]! ;Assign _kalloc to malloc
	LDR R2, =_kfree
	STR R2, [R1, #4]! ;Assign _kfree to free
	LDR R2, =_kmemcpy
	STR R2, [R1, #4]! ;Assign _kmemcpy to _memcpy
		MOV		pc, lr

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; System Call Table Jump Routine
        EXPORT	_syscall_table_jump
_syscall_table_jump
	PUSH{LR}
	LDR R4, =SYSTEMCALLTBL
	LDR R5, [R4, R7, LSL #2] ;Pre-index address SYSTEMCALLTBL with offset of R7 * 4 bits
	BLX R5
_syscall_jump_done
	POP{LR}
		MOV		pc, lr			
		END


		
