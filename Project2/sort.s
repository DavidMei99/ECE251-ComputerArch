.data
//Message 1 ask for input name
msg_1:  .asciz "Enter the input filename: "
//Message 2 ask for output name
msg_2:  .asciz "Enter the output filename: "
//Error message if input not found
err_msg: .asciz "Input file not found\n"
//Error message if input >100
err_msg_1:.asciz "Too many numbers\n"


//Allocate 4 bytes for each integer
number: .skip 4
//Allocate 400 bytes for 100 integers
array:  .skip 404
//Return value
return: .word 0

//Format 1 for scanf
scanFMT_1: .asciz "%s"
//Format 2 for scanf
scanFMT_2: .asciz "%d"
//Format for printf
printFMT: .asciz "%d\n"
//Allocate 20 bytes for input file name
in_file_name: .skip 20
//Read mode for fopen
read_mode: .asciz "r"
//Allocate 20 bytes for output file name
out_file_name: .skip 20
//Write mode for write mode
write_mode: .asciz "w"


.global fopen
.global fclose
.global printf
.global scanf
.global fputs
.global fscanf
.global fprintf


.text

.global main
main:

        ldr r1, =return         //r1 = &return
        str lr, [r1]            // *r1 = lr
        ldr r0, =msg_1          //r0 = &msg_1
        bl printf               //call printf

        ldr r0, =scanFMT_1      //r0 = &scan format1
        ldr r1, =in_file_name   //r1 = &input file name
        bl scanf                //call scanf

        ldr r0, =in_file_name   //r0 = &input file name
        ldr r1, =read_mode      //r1 = &read mode
        bl fopen                //call fopen
        cmp r0, #0x00           //compare fopen output to null
        beq error               //If no file is opened, branch to error
        mov r7, r0              //r7 = fp

        ldr r0, =msg_2          //r0 = &msg2
        bl printf               //call printf

        ldr r0, =scanFMT_1      //r0 = &scan format1
        ldr r1, =out_file_name  //r1 = &output file name
        bl scanf                //call scanf

        ldr r0, =out_file_name  //r0 = &output file name
        ldr r1, =write_mode     //r1 = write mode
        bl fopen                //call fopen
        mov r5, r0              //r5 = fp2
        mov r6, #0              //i = 0, line counter
        ldr r4, =array          //r4 = &array

read:
        mov r0, r7              //r0 = fp
        ldr r1, =scanFMT_2      //r1 = &scan format 2
        ldr r2, =number         //r2 = &number
        bl fscanf               //call fscanf
        cmp r0, #1
        bne isort               //if reaching EOF, branch to isort

        ldr r0, =number
        ldr r1, [r0]            //r1 = number
        lsl r6, r6, #2          //i *= 4
        str r1, [r4, r6]        //array[i] = r1
        lsr r6, r6, #2          //i/=4
        add r6, r6, #1          //i +=1
        cmp r6, #101
        beq error_1             //if i==101, goto error1
        b read                  //loop read

/*INSERTION SORT*/
isort:
        mov r0, r4              //r0 = &array
        mov r1, r6              //r1 = length n

        mov r2, #1              //i=1

iloop:
        cmp r2, r1              //if i>=n, branch to loopend
        bge iloopend
        add r10, r0, r2, LSL #2 //temp = &array[i*4]
        ldr r10, [r10]          //temp = array[i]
        sub r3, r2, #1          //j = i-1

jloop:
        cmp r3, #0              //if j<=0, end j loop
        blt jloopend
        add r9, r0, r3, LSL #2
        ldr r9, [r9]            //r9 = array[j]
        cmp r10, r9
        bge jloopend            //if temp >= array[j], end jloop
        add r8, r0, r3, LSL #2
        add r8, r8, #4          //r8 = &array[j+1]
        str r9, [r8]            //a[j+1] = a[j]
        sub r3, r3, #1          //j-=1
        b jloop                 //loop jloop

jloopend:
        add r3, r3, #1          //j+=1
        add r8, r0, r3, LSL #2
        str r10, [r8]           //a[j+1] = temp
        add r2, r2, #1          //i++
        b iloop                 //loop iloop

iloopend:
/*END ISORT*/


/*WRITE TO OUTPUT FILE*/
write:
        mov r8, #0              //i=0
write_loop:
        cmp r8, r6              //if i>=n, branch to close file
        bge close_file
        lsl r8, r8, #2          //i *=4

        mov r0, r5              //r0 = fp1
        ldr r1, =printFMT       //r1 = &print format
        ldr r2, [r4, r8]        //r2 = array[i]
        bl fprintf              //call fprintf

        lsr r8, r8, #2          //i/=4
        add r8, r8, #1          //i +=1
        b write_loop            //loop write loop

close_file:
        mov r0, r7              //r0 = fp
        bl fclose               //call fclose
        mov r0, r5              //r0 = fp1
        bl fclose               //call fclose
        ldr lr, =return         //lr = &return
        ldr lr, [lr]
        bx lr

error:
        ldr r0, =err_msg        //r0 = &errormessaage
        bl printf               //call printf
        ldr lr, =return
        ldr lr, [lr]
        bx lr

error_1:
        ldr r0, =err_msg_1      //r0 = &errormessage1
        bl printf               //call printf
        ldr lr, =return
        ldr lr, [lr]
        bx lr