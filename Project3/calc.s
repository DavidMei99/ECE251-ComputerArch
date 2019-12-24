@ Define my Raspberry Pi
        .cpu    cortex-a53
        .fpu    neon-fp-armv8
        .syntax unified         @ modern syntax

.data
output:     .asciz "%f\n"
error_msg1: .asciz "Invalid expression!\n"
error_msg2: .asciz "Input buffer exceeded!\n"
error_msg3: .asciz "Input operations exceeded!\n"


SCAN_FMT:       .asciz "%s"

dbl_zero: .double 0.0
dbl_one:  .double 1.0
dbl_ten:  .double 10.0

.equ    BUFFLEN, 20     @ Maximum length for input string
.equ    DELIMIT, 10     @ Charater that delimits the string
.equ    EXIT_NORMAL, 0
.equ    EXIT_ERROR, 1

buffer: .skip BUFFLEN   @ Allocate space for input string
addr_char: .word 0      @ Points to a character in the string
addr_op_count: .word 0


.text
.global main

main:

        str             lr, [sp, #-8]!


        ldr             r2, [r1, #4]    @load from command line input
        ldr             r0, =buffer     @r0 = &buffer

        mov             r4, #0          @r4 = 0 counter
store:
        ldrb            r3, [r2], #1    @load bits
        cmp             r3,  #0x00
        beq             expression      @if r3= '0', goto expression
        strb            r3, [r0], #1
        add             r4, r4, #1      @i+=1
        b               store           @loop through store


expression:

        ldr             r0, =buffer     @ insert Delimit character
        mov             r1, #DELIMIT    @ at the end of the buffer
        add             r0, r0, r4
        strb            r1, [r0]


        ldr             r0, =buffer
        ldr             r1, =addr_char  @ save start of buffer in addr_char
        str             r0, [r1]

        ldrb            r0, [r0]        @ if empty line, exits
        teq             r0, #DELIMIT
        beq             end

        bl              expr

        bl              check


        vmov.f64        r2, r3, d0      @ print the expression value
        ldr             r0, =output
        bl              printf
        b               end


end:
        mov             r0, #EXIT_NORMAL
        ldr             lr, [sp], #+8
        bx              lr

check:
        ldr             r1, =addr_op_count
        ldr             r1, [r1]
        cmp             r1, #4          @if operation>4, exit
        bgt             op_over
        bx              lr

op_over:
        ldr             r0, =error_msg3
        bl              printf
        mov             r0, #EXIT_ERROR
        mov             r7, #1
        swi             0



/*function to evaluate expression*/
expr:
        str             lr, [sp, #-8]!
        bl              term            @ get first term in d0

expr_loop:
        ldr             r0, =addr_char
        ldr             r0, [r0]        @ String pointer in r0
        ldrb            r1, [r0]
        teq             r1, #DELIMIT    @ If we've reached end of expression
        beq             expr_done       @ return our final value in d0
        teq             r1, #41         @ ')' detected
        beq             expr_done       @ return sub expression () in d0
expr_add:
        teq             r1, #43         @ '+' detected ?
        bne             expr_sub        @if not got to expr_sub


        ldr             r4, =addr_op_count      @i+=1, operation counter
        ldr             r4, [r4]
        add             r4, r4, #1
        ldr             r5, =addr_op_count
        str             r4, [r5]

        add             r0, r0, #1      @ Advance pointer to next character
        ldr             r1, =addr_char
        str             r0, [r1]
        vmov.f64        r0, r1, d0      @ Save the first term
        stmdb           sp!, {r0, r1}
        bl              term            @ Get the next term
        ldmia           sp!, {r0, r1}
        vmov.f64        d1, r0, r1
        vadd.f64        d0, d0, d1      @ Add the next term to d0
        b               expr_loop
expr_sub:
        teq             r1, #45         @ '-' detected
        bne             expr_invalid    @if not go to invaid expression


        ldr             r4, =addr_op_count
        ldr             r4, [r4]
        add             r4, r4, #1
        ldr             r5, =addr_op_count
        str             r4, [r5]


        add             r0, r0, #1      @ advance pointer to next character
        ldr             r1, =addr_char
        str             r0, [r1]
        vmov.f64        r0, r1, d0      @ save the first term
        stmdb           sp!, {r0, r1}
        bl              term            @ get the next term
        ldmia           sp!, {r0, r1}
        vmov.f64        d1, r0, r1
        vsub.f64        d0, d1, d0      @ subtract the second term from the first
        b               expr_loop
expr_invalid:                           @ branch here if the string is invald
        ldr             r0, =error_msg1
        bl              printf
        mov             r0, #EXIT_ERROR
        mov             r7, #1
        swi             0
expr_done:
        add             r0, r0, #1
        ldr             r1, =addr_char
        str             r0, [r1]
        ldr             lr, [sp], #+8
        bx              lr


/*functio to get the value of a term*/
term:
        str             lr, [sp, #-8]!
        bl              number          @ get the first number in the term, in d0


term_mul:
        ldr             r0, =addr_char
        ldr             r0, [r0]        @ string pointer in r0
        ldrb            r1, [r0]
        teq             r1, #42         @ '*' detected ?
        bne             term_div        @if not go to term_div


        ldr             r4, =addr_op_count
        ldr             r4, [r4]
        add             r4, r4, #1
        ldr             r5, =addr_op_count
        str             r4, [r5]


        add             r0, r0, #1      @ Advance pointer to next character
        ldr             r1, =addr_char
        str             r0, [r1]
        vmov.f64        r0, r1, d0      @ Save the first number
        stmdb           sp!, {r0, r1}
        bl              number          @ Get the next number
        ldmia           sp!, {r0, r1}
        vmov.f64        d1, r0, r1
        vmul.f64        d0, d0, d1      @ Multiply the next number in the term
        b               term_mul

term_div:
        teq             r1, #47         @ '/' detected  ?
        bne             term_done       @if not term is evaluated


        ldr             r4, =addr_op_count
        ldr             r4, [r4]
        add             r4, r4, #1
        ldr             r5, =addr_op_count
        str             r4, [r5]




        add             r0, r0, #1      @ advance pointer to next character
        ldr             r1, =addr_char
        str             r0, [r1]
        vmov.f64        r0, r1, d0      @ save the first number
        stmdb           sp!, {r0, r1}
        bl              number          @ get the second number
        ldmia           sp!, {r0, r1}
        vmov.f64        d1, r0, r1
        vdiv.f64        d0, d1, d0      @ divide the first by the second number
        b               term_mul

term_done:
        ldr             lr, [sp], #+8
        bx              lr


/*function to recoginize number or expression*/
number:
        str             lr, [sp, #-8]!

        ldr             r0, =addr_char
        ldr             r0, [r0]
        ldrb            r1, [r0]
        teq             r1, #40         @ '(' found
        bne             number_start
        add             r0, r0, #1      @ increment pointer to start of sub expression
        ldr             r1, =addr_char
        strb            r0, [r1]
        bl              expr            @ evaluate number within parentheses
        b               number_done
number_start:
        ldr             r1, =dbl_zero
        vldr            d0, [r1]        @ d0 to store final value of number
number_intpart:
        ldrb            r1, [r0]
        cmp             r1, #48         @ when non-digit detected
        blt             number_int_done @ done evaluating integer part of number
        cmp             r1, #57
        bgt             number_int_done
        sub             r1, r1, #48     @ evaluate integer part
        vmov.u32        s2, r1
        vcvt.f64.u32    d1, s2
        ldr             r1, =dbl_ten
        vldr            d2, [r1]
        vmul.f64        d0, d0, d2
        vadd.f64        d0, d0, d1
        add             r0, r0, #1
        b               number_intpart
number_int_done:
        teq             r1, #46         @ '.' found ?
        bne             number_done     @ if not, number is only an integer

        ldr             r1, =dbl_one
        vldr            d1, [r1]        @ if reach here factor for decimal places
number_fracpart:
        add             r0, r0, #1
        ldrb            r1, [r0]
        cmp             r1, #48         @ when non-digit detected
        blt             number_done     @ done evaluating fractional part of number
        cmp             r1, #57
        bgt             number_done
        ldr             r2, =dbl_ten
        vldr            d2, [r2]
        vdiv.f64        d1, d1, d2
        sub             r1, r1, #48
        vmov.u32        s4, r1
        vcvt.f64.u32    d2, s4
        vmul.f64        d2, d2, d1
        vadd.f64        d0, d0, d2
        b               number_fracpart
number_done:
        ldr             r1, =addr_char  @ save current string pointer
        str             r0, [r1]
        ldr             lr, [sp], #+8
        bx              lr
