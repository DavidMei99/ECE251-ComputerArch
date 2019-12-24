.equ    nul, 0

.data

.balign 4
msg1: .asciz "Hey, type a string:"

.balign 4
msg2: .asciz "The concatenated string is %s\n"

.balign 4
msg3: .asciz "The size of string is %d\n"

.balign 4
msg4: .asciz "Type the second string:"

.balign 4
scan_pattern: .asciz "%s"

.balign 4
string_read: .skip 100

.balign 4
string_len: .word 0

.balign 4
concat_string_len: .word 0

.balign 4
string_len2: .word 0

.balign 4
return: .word 0

.balign 4
return2: .word 0

.text
str_length:
        ldr r1, address_of_return2
        str lr, [r1]

        mov r1, #0
loop:
        ldrb r2, [r0], #1
        add r1, r1, #1
        cmp r2, #nul
        bne loop
        sub r1, r1, #1
        ldr lr, address_of_return2
        ldr lr, [lr]
        bx lr
address_of_return2: .word return2


.global main
main:
        ldr r1, return_addr
        str lr, [r1]

        /*type string 1*/
        ldr r0, msg1_addr
        bl printf

        /*scan string1*/
        ldr r0, scan_pattern_addr
        ldr r1, string_read_addr
        bl scanf

        /*strlen stirng1*/
        ldr r0, string_read_addr
        bl str_length

        ldr r0, string_len_addr
        str r1, [r0]
        /*print strlen str1*/
        ldr r0, msg3_addr
        ldr r1, string_len_addr
        ldr r1, [r1]
        bl printf

        ldr r0, string_len_addr
        ldr r0, [r0]
        cmp r0, #10
        bgt error1


        /*type str2*/
        ldr r0, msg4_addr
        bl printf

        /*scan string2*/
        ldr r0, scan_pattern_addr
        ldr r1, string_read_addr
        ldr r2, string_len_addr
        ldr r2, [r2]
        add r1, r1, r2
        bl scanf

        ldr r0, string_read_addr
        bl str_length

        ldr r0, concat_string_len_addr
        str r1, [r0]


        /*find strlen2*/
        ldr r0, string_len_addr
        ldr r0, [r0]
        sub r1, r1, r0

        ldr r0, string_len2_addr
        str r1, [r0]

        ldr r0, msg3_addr
        ldr r1, string_len2_addr
        ldr r1, [r1]
        bl printf

        ldr r0, string_len2_addr
        ldr r0, [r0]
        cmp r0, #10
        bgt error2

        ldr r0, msg2_addr
        ldr r1, string_read_addr
        bl printf

        /*return strlen*/
        ldr r0, concat_string_len_addr
        ldr r0, [r0]
        b end

error1:
        mov r0, #21
        b end

error2:
        mov r0, #22
        b end



end:
        ldr lr, return_addr
        ldr lr, [lr]
        bx lr

return_addr:    .word return
msg1_addr:      .word msg1
scan_pattern_addr:      .word scan_pattern
string_read_addr:       .word string_read
string_len_addr:        .word string_len
msg2_addr:      .word msg2
msg3_addr:      .word msg3
msg4_addr:      .word msg4
string_len2_addr:       .word string_len2
concat_string_len_addr: .word concat_string_len
.global printf
.global scanf
