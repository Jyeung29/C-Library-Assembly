		AREA	|.text|, CODE, READONLY, ALIGN=2
		THUMB

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; void _bzero( void *s, int n )
; Parameters
;	s 		- pointer to the memory location to zero-initialize
;	n		- a number of bytes to zero-initialize
; Return value
;   none
		EXPORT	_bzero
_bzero
		; implement your complete logic, including stack operations
		;R0 = *s
		;R1 = n
		LDR R4, =0x0 ;Register to Load
		
bzeroLoop	SUBS R1, #1 ;decrement counter by 1 for number of bytes left to initalize
			BMI end_bzero ;If negative then end
			STRB R4, [R0], #1  ;Store by Byte. Post-index offset by 1 byte
			B bzeroLoop
			
end_bzero	LDR R0, =0x0 ;makes sure return value is null
			LDR R1, =0x0
			MOV		pc, lr	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; char* _strncpy( char* dest, char* src, int size )
; Parameters
;   	dest 	- pointer to the buffer to copy to
;	src	- pointer to the zero-terminated string to copy from
;	size	- a total of n bytes
; Return value
;   dest
		EXPORT	_strncpy
_strncpy
		; implement your complete logic, including stack operations
		;R0 = *dest
		;R1 = *src
		;R2 = size
		;R4 = store src byte
		MOV R5, R0 ;Copy address of dest so R0 can be dest can be returned
		
strncpyLoop		SUBS R2, #1 ;decrement counter by 1 for number of bytes left to copy
				BMI end_strncpy
				LDRB R4, [R1], #1 ;Load by byte from src. Post-index offset by 1 byte
				STRB R4, [R5], #1 ;Store copied byte to dest. Post-index offset by 1 byte
				B strncpyLoop

end_strncpy		LDR R1, =0x0 ;Make sure return value for R1 is null from not double
				MOV		pc, lr
		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; void* _malloc( int size )
; Parameters
;	size	- #bytes to allocate
; Return value
;   	void*	a pointer to the allocated space
		EXPORT	_malloc
_malloc
		; save registers
		PUSH {LR, R4-R12}
		; set the system call # to R7
		MOV R7, #3
	        SVC     #0x0
		; resume registers
		POP {LR, R4-R12}
		MOV		pc, lr

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; void _free( void* addr )
; Parameters
;	size	- the address of a space to deallocate
; Return value
;   	none
		EXPORT	_free
_free
		; save registers
		PUSH {LR, R4-R12}
		; set the system call # to R7
		MOV R7, #4
        	SVC     #0x0
		; resume registers
		POP {LR, R4-R12}
		MOV		pc, lr

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; unsigned int _alarm( unsigned int seconds )
; Parameters
;   seconds - seconds when a SIGALRM signal should be delivered to the calling program	
; Return value
;   unsigned int - the number of seconds remaining until any previously scheduled alarm
;                  was due to be delivered, or zero if there was no previously schedul-
;                  ed alarm. 
		EXPORT	_alarm
_alarm
		; save registers
		PUSH {LR, R4-R12}
		; set the system call # to R7
		MOV R7, #1
        	SVC     #0x0
		; resume registers
		POP {LR, R4-R12}
		MOV		pc, lr		
			
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; void* _signal( int signum, void *handler )
; Parameters
;   signum - a signal number (assumed to be 14 = SIGALRM)
;   handler - a pointer to a user-level signal handling function
; Return value
;   void*   - a pointer to the user-level signal handling function previously handled
;             (the same as the 2nd parameter in this project)
		EXPORT	_signal
_signal
		; save registers
		PUSH {LR, R4-R12}
		; set the system call # to R7
		MOV R7, #2
        	SVC     #0x0
		; resume registers
		POP {LR, R4-R12}
		MOV		pc, lr	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; void* _memcpy(void* dest, void* src, unsigned int bytes)
; Parameters
;	dest - a pointer to a heap address to copy to
;	src - a pointer to a heap address to copy from
;	bytes - number of bytes to copy from src to dest
	EXPORT _memcpy
_memcpy
	PUSH {LR, R4-R12}
	MOV R7, #5
		SVC #0x0
	POP {LR, R4-R12}
	MOV PC, LR
		END			
