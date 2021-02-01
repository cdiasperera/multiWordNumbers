; === TODO ===
; If you see this, something has gone horribly wrong!
; 1) Put binary addition for a single cell into its own subroutine
; 2) Figure out how to put position data addresses arbitrarily
; === END-TODO ===

; MVN.asm - Channa Dias Perera - c.dias.perera@student.rug.nl
; Program to add two large positive numbers.
; Room for improvement:
;   Technically, we are very memory inefficient:
;       We are using 16 bits to store a word that only requires 4 bits. If we were clever we could try to squeeze in 4 digits per memory cell
;       We probably could store the result in binary, which would reduce the number size from ~100 bits to log_2(10^100)=~332 bits = 20 memory cells
; Inputs: Two numbers, in decimal, 0 <= n,m <= 10^{100}, separated by a newline
; Output: The output of these numbers, on a newline

.ORIG x3000
; GOTO MAIN
                BRnzp   MAIN
; GET_NUM
; Input:    R1 - The starting address of the space allocated for the input
;           R2 - The address for the number of digits of the input
; Algorithm: Grab characters from the keyboard, and while the character is not a newline, convert it to binary and store in a memory cell.
; Output:   None
GET_NUM
                ST      R0, SAVE_R0         ; Save registers. R0 will be used for IO
                ST      R1, SAVE_R1         ; R1 wil be used for keeping track of which cell we will store the current digit into.
                ST      R2, SAVE_R2         ; R2 wil be used to store address of where to store number of digits in input
                ST      R3, SAVE_R3         ; Stores newline value / neg-ASCII-0
                ST      R4, SAVE_R4         ; Stores number of digits in input
                
                AND     R4, R4, #0          ; Initialize number of digits to 0
                
GET_CHAR        GETC                        ; Get input from keyboard
                OUT                         ; Echo
                LD      R3, NEG_NEWLINE     ; Initialize newline     
                ADD     R3, R0, R3          ; Check if character is a newline
                BRz     LEAVE_GET_NUM       ; Branches if newline
                
                ADD     R4, R4, #1
                
                LD      R3, ASCII_NEG_0     ; Convert to binary and store value in appropriate memory cell
                ADD     R0, R0, R3
                STR     R0, R1, #0
                
                ADD     R1, R1, #1          ; Point to next free space for digit
                BRnzp   GET_CHAR                

LEAVE_GET_NUM   STR     R4, R2, #0          ; Store number of digits
                LD      R0, SAVE_R0         ; Load registers
                LD      R1, SAVE_R1
                LD      R2, SAVE_R2
                LD      R3, SAVE_R3
                LD      R4, SAVE_R4
                RET

; ADD_MWN
; Add two MWNs.
; Inputs:   R0 - The starting address of the first MWN
;           R1 - The number of digits in the first MWN
;           R2 - The starting address of the second MWN
;           R3 - The number of digits in the second MWN
;           R4 - The desired starting address of the ouput MWN
;           R5 - The address for the number of digits in the output
; Output:   Result of addition, stored backwards, in the desired memory location.
; Algorithm: For each cell:
;               Add binary numbers + carry. Substract by 10. If result is not negative, set carry to 1 and store result. Otherwise, add 10 and store result.
ADD_MWN
                ST      R0, SAVE_R0         ; Save registers. We will use R0 as a pointer for the current memory cell of input 1.
                ST      R1, SAVE_R1         ; We will use R1 as the number of digits in input 1 to process.
                ST      R2, SAVE_R2         ; We will use R2 as a pointer for the current memory cell of input 2.
                ST      R3, SAVE_R3         ; We will use R3 as the number of digits in input 1 to process.
                ST      R4, SAVE_R4         ; We will use R4 as a pointer for the current memory cell of the output.
                ST      R5, SAVE_R5         ; We will use R5 to store the number of digits of the output.
                ST      R6, SAVE_R6         ; We will use R6 as the carry value.
                ST      R7, SAVE_R7         ; The current value that will be pushed to the current output cell

                ADD     R0, R0, R1          ; Initiallize values. Go to end of input 1
                ADD     R0, R0, #-1
                ADD     R2, R2, R3          ; Go to end of input 2
                ADD     R2, R2, #-1
                AND     R5, R5, #0
                AND     R6, R6, #0
                
PROCESS_CELL    AND     R7, R7, #0
                ADD     R1, R1, #0
                BRnz    ADD_INP2_DIG        ; If input 1 has no digits to process, we go to process input 2
                ST      R1, SAVE_NUM_DIGS   ; We temporarily save the number of digits to make space for the value in input 1
                LDR     R1, R0, #0
                ADD     R7, R1, R7
                LD      R1, SAVE_NUM_DIGS
                ADD     R0, R0, #-1         ; Prep for next loop
                ADD     R1, R1, #-1
                
ADD_INP2_DIG    ADD     R3, R3, #0          ; If input 2 has no digits to process, we skip to adding the carry
                BRnz    ADD_CARRY
                ST      R1, SAVE_NUM_DIGS
                LDR     R1, R2, #0
                ADD     R7, R1, R7
                LD      R1, SAVE_NUM_DIGS
                ADD     R2, R2, #-1
                ADD     R3, R3, #-1

ADD_CARRY       ADD     R7, R7, R6
                ADD     R7, R7, #-10        ; Check if we need to set carry for next iteration
                BRn     NO_CARRY            ; If the result is negative after substracting, this means that no carry is present
                
                AND     R6, R6, #0          ; Set carry to 1
                ADD     R6, R6, #1
                BRnzp   STORE_RESULT
                
NO_CARRY        AND     R6, R6, #0          ; Set carry to 0
                ADD     R7, R7, #10         ; Re-set R7 to value before division check
                
STORE_RESULT    STR     R7, R4, #0
                ADD     R4, R4, #1          ; Set output to point to next free cell
                ADD     R5, R5, #1
                
                ADD     R1, R1, #0          ; Check if there are any more digits to process
                BRp     PROCESS_CELL
                ADD     R3, R3, #0
                BRp     PROCESS_CELL
                ADD     R6, R6, #0          ; Check if there's a carry to process
                BRp     PROCESS_CELL
                
LEAVE_ADD_MWN   LEA     R0, OUTP_ADDR       ; Flip output MWN
                ADD     R1, R5, #0
                JSR     FLIP_MWN
                
                ADD     R0, R5, #0          ; Store number of digits in output. We will make use of R0 to store the address, since we don't need it for its original purpose
                LD      R5, SAVE_R5
                STR     R0, R5, #0
                
                LD      R0, SAVE_R0         ; Load registers
                LD      R1, SAVE_R1
                LD      R2, SAVE_R2
                LD      R3, SAVE_R3
                LD      R4, SAVE_R4
                LD      R6, SAVE_R6
                LD      R7, SAVE_R7
                RET

RIGHT_SHIFT     
; RIGHT_SHIFT
; Right shifts R1 in place
; Inputs:   R1 - The value to be right shifted
; Outputs:  R1 - The right-shifted value
; Algorithm: Right shifting is just division by 2, so we will just do that
                LEA     R6, SAVE_SHIFT
                STR     R0, R6, #0      ; We will use R0 to store the amount of subtractions by 2
                
                AND     R0, R0, #0
                
SUB_2           ADD     R1, R1, #-2
                BRn     FINISH_SHIFT
                
                ADD     R0, R0, #1
                BRnzp   SUB_2

FINISH_SHIFT    ADD     R1, R0, #0
                LEA     R6, SAVE_SHIFT
                LDR     R0, R6, #0
                RET

FLIP_MWN
; FLIP_MWN
; Flips the digits of a MWN.
; Inputs:   R0 - Location of MWN
;           R1 - Number of digits of MWN
; Outputs:  The flipped MWN, in its place
; Algorithm: We swap mirrored cells, till we have swapped floor(R1/2) digits.
                LEA     R6, SAVE_FLIP  ; The save stack for the registers
                STR     R0, R6, #0      ; Save registers. We will use R0 point to the front cell of the MWN we are swapping
                STR     R1, R6, #1      ; We will use R1 for the number of digits to swap
                STR     R2, R6, #2      ; We will use R2 to point to the back cell of the MWN we are swapping
                STR     R3, R6, #3      ; We will use R3 as temporary storage
                STR     R4, R6, #4      ; We will use R4 to temporary storage
                STR     R7, R6, #7
                
                ADD     R2, R0, R1      ; Initialize back pointer
                ADD     R2, R2, #-1
                
                JSR     RIGHT_SHIFT     ; We right shift R1 to get floor(R1/2)
                
SWAP_NUMS       ADD     R1, R1, #0
                BRnz    LEAVE_FLIP      ; Leave if we have no numbers left to swap
                
                LDR     R3, R0, #0      ; Swap numbers
                LDR     R4, R2, #0
                STR     R4, R0, #0
                STR     R3, R2, #0
                
                ADD     R0, R0, #1      ; Move pointers and decrement counter
                ADD     R2, R2, #-1
                ADD     R1, R1, #-1
                
                BRnzp   SWAP_NUMS
                
LEAVE_FLIP      LEA     R6, SAVE_FLIP
                LDR     R0, R6, #0      ; Load registers
                LDR     R1, R6, #1
                LDR     R2, R6, #2
                LDR     R3, R6, #3
                LDR     R4, R6, #4
                LDR     R7, R6, #7
                RET
; READ_MWN
; Read a MWN out.
; Inputs:   R0 - The desired starting address of the ouput MWN
;           R1 - The address for the number of digits in the output
; Outputs:  The result of the addition, on a new line
; Algorithm: We go to the start of the MWN and set a counter to the number of digits.
;            Then, while the counter is positive, we output the ASCII value of the pointed cell, decrement the counter and increment the pointer
;            Finally, we output a newline
READ_MWN
                ST      R0, SAVE_R0     ; Save registers. We will use R0 for IO
                ST      R1, SAVE_R1     ; We will use R1 as a pointer to the cell to print
                ST      R2, SAVE_R2     ; We will use R0 as the number of digits still to process
                ST      R3, SAVE_R3     ; We will use R3 to store ASCII_0 / newline
                
                LD      R3, ASCII_0
                
OUTPUT_CHAR     ADD     R2, R2, #0
                BRnz    NUM_PRINTED     ; No more characters to process
                LDR     R0, R1, #0      ; Convert to ASCII
                ADD     R0, R0, R3
                OUT
                
                ADD     R1, R1, #1     ; Prep next cell for processing
                ADD     R2, R2, #-1
                BRnzp   OUTPUT_CHAR
        
NUM_PRINTED     LD      R0, NEWLINE     ; Add newline
                OUT

                LD      R0, SAVE_R0     ; Load registers
                LD      R1, SAVE_R1
                LD      R2, SAVE_R2
                RET

; MAIN
; Main program execution
MAIN
                LEA     R1, INP1_ADDR       ; Get input 1
                LEA     R2, INP1_NUM_DIGS   
                JSR     GET_NUM
                
                LEA     R1, INP2_ADDR       ; Get input 2
                LEA     R2, INP2_NUM_DIGS   ;
                JSR     GET_NUM

                LEA     R0, INP1_ADDR       ; Add numbers
                LD      R1, INP1_NUM_DIGS
                LEA     R2, INP2_ADDR
                LD      R3, INP2_NUM_DIGS
                LEA     R4, OUTP_ADDR
                LEA     R5, OUTP_NUM_DIGS
                JSR     ADD_MWN
                
                LEA     R1, OUTP_ADDR       ; Initialize registers for reading output
                LD      R2, OUTP_NUM_DIGS
                JSR     READ_MWN
                HALT

; DATA ---------------------------

; ASCII
NEG_NEWLINE     .FILL       xFFF6
NEWLINE         .FILL       x0a
ASCII_0         .FILL       x30
ASCII_NEG_0     .FILL       xFFD0

; Cells for saving registers
SAVE_R0         .FILL       #0
SAVE_R1         .FILL       #0
SAVE_R2         .FILL       #0
SAVE_R3         .FILL       #0
SAVE_R4         .FILL       #0
SAVE_R5         .FILL       #0
SAVE_R6         .FILL       #0
SAVE_R7         .FILL       #0

SAVE_FLIP       .BLKW       #8
SAVE_SHIFT      .BLKW       #8

SAVE_NUM_DIGS   .FILL       #0

; Number of digits in input, output.
INP1_NUM_DIGS   .FILL       #0
INP2_NUM_DIGS   .FILL       #0
OUTP_NUM_DIGS   .FILL       #0

; Allocate space for output: 101 cells for each digit.
OUTP_ADDR       .BLKW       #101

; Allocate space for inputs 1,2: 100 cells for each digit + 1 cell for number of digits.
INP1_ADDR       .BLKW       #100
INP2_ADDR       .BLKW       #100

.END
