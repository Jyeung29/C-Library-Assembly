		AREA	|.text|, CODE, READONLY, ALIGN=2
		THUMB

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; System Timer Definition
STCTRL		EQU		0xE000E010		; SysTick Control and Status Register
STRELOAD	EQU		0xE000E014		; SysTick Reload Value Register
STCURRENT	EQU		0xE000E018		; SysTick Current Value Register
	
STCTRL_STOP	EQU		0x00000004		; Bit 2 (CLK_SRC) = 1, Bit 1 (INT_EN) = 0, Bit 0 (ENABLE) = 0
STCTRL_GO	EQU		0x00000007		; Bit 2 (CLK_SRC) = 1, Bit 1 (INT_EN) = 1, Bit 0 (ENABLE) = 1
STRELOAD_MX	EQU		0x00FFFFFF		; MAX Value = 1/16MHz * 16M = 1 second
STCURR_CLR	EQU		0x00000000		; Clear STCURRENT and STCTRL.COUNT	
SIGALRM		EQU		14			; sig alarm

; System Variables
SECOND_LEFT	EQU		0x20007B80		; Secounds left for alarm( )
USR_HANDLER     EQU		0x20007B84		; Address of a user-given signal handler function	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Timer initialization
; void timer_init( )
		EXPORT		_timer_init
_timer_init
	;; Implement by yourself
	;Stop SysTick
	LDR R0, =STCTRL_STOP
	LDR R1, =STCTRL
	STR R0, [R1]
	;Load Max to SYST_RVR
	LDR R0, =STRELOAD_MX
	LDR R1, =STRELOAD
	STR R0, [R1]
		MOV		pc, lr		; return to Reset_Handler

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Timer start
; int timer_start( int seconds )
		EXPORT		_timer_start
_timer_start
	;; Implement by yourself
	LDR R1, =SECOND_LEFT
	LDR R2, [R1] ;Get previous value at 0x20007B80 
	STR R0, [R1] ;Set new seconds value at 0x20007B80
	LDR R3, =STCTRL
	LDR R4, =STCTRL_GO
	STR R4, [R3] ;Enable SysTick with STCTRL to bits 111
	LDR R3, =STCURRENT
	LDR R4, =STCURR_CLR
	STR R4, [R3] ;Clear SYST_CVR with 0x00000000
	MOV R0, R2 ;Return previous value at USR_HANDLER
		MOV		pc, lr		; return to SVC_Handler

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Timer update
; void timer_update( )
		EXPORT		_timer_update
_timer_update
	;; Implement by yourself
	LDR R8, =SECOND_LEFT
	LDR R4, [R8]
	SUBS R4, #1
	STR R4, [R8] ;Save back decrement value to seconds remain
	BNE _timer_update_done
	LDR R5, =STCTRL_STOP
	LDR R6, [R5] ;Load value of STRCTRL_STOP into R6
	LDR R5, =STCTRL
	STR R6, [R5] ;Load value of STRCTRL_STOP into address STRCTRL
	
	LDR R4, =USR_HANDLER
	LDR R5, [R4]
	MOVS R4, #3
	MSR CONTROL, R4
	PUSH{LR}
	BLX R5
	POP{LR}
_timer_update_done
		MOV		pc, lr		; return to SysTick_Handler

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Timer update
; void* signal_handler( int signum, void* handler )
	    EXPORT	_signal_handler
_signal_handler
	;; Implement by yourself
	LDR R3, =SIGALRM
	LDR R4, =USR_HANDLER
	LDR R5, [R4] ;Previous Value of 0x2007B84 USR_HANDLER
	CMP R0, R3
	STREQ R1, [R4]
	MOV R0, R5 ;Assign previous value to R0 to return to main
		MOV		pc, lr		; return to Reset_Handler
		END		
