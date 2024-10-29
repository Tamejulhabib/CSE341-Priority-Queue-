; Interactive Priority Queue System for emu8086
.model small
.stack 100h

.data
    ; Constants
    TASKS_MAX EQU 20

    ; Segment (i): Array to store tasks with priorities
    tasks dw TASKS_MAX dup(0, 0)  ; [id, priority] pairs
    taskCount dw 0

    ; Segment (ii): Stack to manage priority queue
    pqStack dw TASKS_MAX dup(0, 0)  ; [id, priority] pairs
    pqStackTop dw 0

    ; Messages
    promptTask db 'Enter task ID (1-99, 0 to finish): $'
    promptPriority db 'Enter priority (1-9): $'
    msgTaskAdded db 'Task $'
    msgPriority db ' added with priority $'
    msgNewline db 13, 10, '$'
    msgProcessing db 'Processing tasks:$'
    msgProcessingTask db 'Processing task with ID $'
    msgAndPriority db ' and priority $'
    msgNoTasks db 'No tasks in queue$'
    msgInvalidInput db 'Invalid input. Please try again.$'
    msgQueueFull db 'Task queue is full.$'
    msgEnd db 'End of processing. Press any key to exit.$'

    ; Buffers
    inputBuffer db 3, ?, 3 dup(0)

.code
main proc
    mov ax, @data
    mov ds, ax

    call inputTasks
    call processTasks

    ; Wait for key press before exiting
    mov dx, offset msgEnd
    mov ah, 9
    int 21h
    mov ah, 1
    int 21h

    ; Exit program
    mov ah, 4Ch
    int 21h
main endp

; Segment (iii): Macros and procedures for queue management

; Procedure to input tasks from user
inputTasks proc
    push ax
    push bx

input_loop:
    ; Prompt for task ID
    mov dx, offset promptTask
    mov ah, 9
    int 21h

    ; Read task ID
    call readNumber
    cmp ax, 0
    je input_done  ; If ID is 0, end input
    cmp ax, 99
    ja invalid_input

    push ax  ; Save task ID

    ; Prompt for priority
    mov dx, offset promptPriority
    mov ah, 9
    int 21h

    ; Read priority
    call readNumber
    cmp ax, 1
    jb invalid_input
    cmp ax, 9
    ja invalid_input

    mov bx, ax  ; Move priority to bx
    pop ax      ; Restore task ID to ax

    ; Add task
    call addTask
    jmp input_loop

invalid_input:
    mov dx, offset msgInvalidInput
    mov ah, 9
    int 21h
    mov dx, offset msgNewline
    int 21h
    jmp input_loop

input_done:
    pop bx
    pop ax
    ret
inputTasks endp

; Procedure to process all tasks
processTasks proc
    push ax
    push dx

    mov dx, offset msgProcessing
    mov ah, 9
    int 21h
    mov dx, offset msgNewline
    int 21h

process_loop:
    cmp [pqStackTop], 0
    je process_done

    call processHighestPriority
    jmp process_loop

process_done:
    pop dx
    pop ax
    ret
processTasks endp

; Procedure to add a task
addTask proc
    push si

    cmp [taskCount], TASKS_MAX
    jae queue_full

    ; Add to tasks array
    mov si, [taskCount]
    shl si, 2  ; Multiply by 4 (2 words per task)
    mov [tasks + si], ax  ; Store ID
    mov [tasks + si + 2], bx  ; Store priority

    ; Increase task count
    inc [taskCount]

    ; Add to priority pqStack
    call pushToStack

    ; Print confirmation
    push ax
    push bx

    mov dx, offset msgTaskAdded
    mov ah, 9
    int 21h

    mov ax, [tasks + si]  ; ID
    call printNumber

    mov dx, offset msgPriority
    mov ah, 9
    int 21h

    mov ax, [tasks + si + 2]  ; Priority
    call printNumber

    mov dx, offset msgNewline
    mov ah, 9
    int 21h

    pop bx
    pop ax
    jmp addTask_end

queue_full:
    mov dx, offset msgQueueFull
    mov ah, 9
    int 21h
    mov dx, offset msgNewline
    int 21h

addTask_end:
    pop si
    ret
addTask endp

; Procedure to push task to pqStack and reorder
pushToStack proc
    push si
    mov si, [pqStackTop]
    shl si, 2  ; Multiply by 4 (2 words per task)
    mov [pqStack + si], ax  ; Store ID
    mov [pqStack + si + 2], bx  ; Store priority
    inc [pqStackTop]

    ; Reorder pqStack
    call reorderStack

    pop si
    ret
pushToStack endp

; Procedure to reorder the pqStack based on priority
reorderStack proc
    push ax
    push bx
    push cx
    push dx
    push si

    mov cx, [pqStackTop]
    dec cx  ; Number of comparisons
    jcxz done_reorder  ; If only one or no elements, no need to sort

    outer_loop:
        push cx
        mov si, 0  ; Start index

        inner_loop:
            mov ax, [pqStack + si + 2]  ; Current priority
            mov bx, [pqStack + si + 6]  ; Next priority
            cmp ax, bx
            jae next_pair  ; If in correct order, move to next pair

            ; Swap pairs if out of order
            mov dx, [pqStack + si]
            xchg dx, [pqStack + si + 4]
            mov [pqStack + si], dx

            mov dx, [pqStack + si + 2]
            xchg dx, [pqStack + si + 6]
            mov [pqStack + si + 2], dx

        next_pair:
            add si, 4
            loop inner_loop

        pop cx
        loop outer_loop

    done_reorder:
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
reorderStack endp

; Procedure to process highest priority task
processHighestPriority proc
    cmp [pqStackTop], 0
    je no_tasks

    ; Get top task
    mov si, [pqStackTop]
    dec si
    shl si, 2  ; Multiply by 4 (2 words per task)
    mov ax, [pqStack + si]  ; ID
    mov bx, [pqStack + si + 2]  ; Priority

    ; Decrease pqStack top
    dec [pqStackTop]

    ; Print processing message
    push ax
    push bx

    mov dx, offset msgProcessingTask
    mov ah, 9
    int 21h

    pop bx  ; Priority
    pop ax  ; ID
    push ax ; Save ID for later use

    call printNumber  ; Print ID

    mov dx, offset msgAndPriority
    mov ah, 9
    int 21h

    mov ax, bx
    call printNumber  ; Print Priority

    mov dx, offset msgNewline
    mov ah, 9
    int 21h

    pop ax  ; Restore ID

    ret

no_tasks:
    mov dx, offset msgNoTasks
    mov ah, 9
    int 21h
    mov dx, offset msgNewline
    int 21h
    ret
processHighestPriority endp

; Utility procedure to read a number from input
readNumber proc
    push bx
    push cx
    push dx

    mov ah, 0Ah
    mov dx, offset inputBuffer
    int 21h

    ; Convert string to number
    mov ax, 0
    mov bx, 0
    mov bl, [inputBuffer + 1]  ; Get length of input
    mov cl, bl
    mov ch, 0
    mov si, 2  ; Start of actual input

convert_loop:
    mov bl, [inputBuffer + si]
    sub bl, '0'
    mul cx  ; AX = AX * 10
    add al, bl
    ;adc ah, 0
    inc si
    loop convert_loop

    pop dx
    pop cx
    pop bx
    ret
readNumber endp

; Utility procedure to print a number
printNumber proc
    push ax
    push bx
    push cx
    push dx

    mov bx, 10
    mov cx, 0  ; Digit counter

    ; Handle zero separately
    test ax, ax
    jnz extract_digits
    mov dl, '0'
    mov ah, 2
    int 21h
    jmp print_done

    ; Extract digits
    extract_digits:
        mov dx, 0
        div bx
        push dx
        inc cx
        cmp ax, 0
        jnz extract_digits

    ; Print digits
    print_loop:
        pop dx
        add dl, '0'
        mov ah, 2
        int 21h
        loop print_loop

    print_done:
    pop dx
    pop cx
    pop bx
    pop ax
    ret
printNumber endp

end main