;; SETUP ----------
use16           ; use 16 bit code when assembing

org 07C00h      ; Set bootsector to be at memory location hex 7C00h
jmp setup_game  ; Jump over Variables section so we don't tryto execute it

;; CONSTANTS ----------
VIDMEM equ 0B800h   ; Color text mode VGA memory location
ROWLEN equ 160      ; 80 Character row * 2 bytes each
PLAYERX equ 4       ; Player X position
CPUX    equ 154     ; CPU X Position
KEY_W   equ 11h     ; Keyboard scancodes...
KEY_S   equ 1Fh
KEY_C   equ 2Eh
KEY_R   equ 13h
SCREENW equ 80
SCREENH equ 24
PADDLEHEIGHT equ 5

;; VARIABLES ----------
drawColor: db 0F0h

playerY:   dw 10    ; Start player Y position 10 rows down
cpuY:      dw 10    ; Start cpu Y position 10 rows down
ballX:     dw 66    ; Starting ball X position
ballY:     dw 7     ; Starting ball Y position
ballVelX:  db -1
ballVelY:  db 1

;; LOGIC ===============
setup_game:
    ;; Set up video mode
    mov ax, 0003h   ; Set video mode BIOS interrupt 10h AH00h; AL = 03h text mode 30x25 chaaracters, 16 color VGA
    int 10h

    ;; Set up video memory
    mov ax, VIDMEM
    mov es, ax      ; ES:DI <- B800:0000

;; Game loop
game_loop:
    ;; Clear Screen to black every cycle
    xor ax, ax
    xor di, di
    mov cx, 80*25
    rep stosw

    ;; Draw middle separating line
    mov ah, [drawColor]    ; White bg, black bg
    mov di, 78              ; Start at middle of 80 character row
    mov cx, 13                  ; 'Dashed' line - only draw every other row
    .draw_middle_loop:
        stosw
        add di, 2*ROWLEN-2       ; Only draw every other row (80 Char * 2 bytes * 2 rows)
        loop .draw_middle_loop   ; Loops CX # of times

    ;; Draw player and CPU paddles
    imul di, [playerY], ROWLEN   ; Y position is Y # rows * length of row
    imul bx, [cpuY], ROWLEN
    mov cl, PADDLEHEIGHT
    .draw_player_loop:
        mov [es:di+PLAYERX], ax
        mov [es:bx+CPUX], ax
        add di, ROWLEN
        add bx, ROWLEN
        loop .draw_player_loop

    ;; Draw ball
    imul di, [ballY], ROWLEN
    add di, [ballX]
    mov word [es:di], 2000h     ; Green bg, black fg

    ;; Get Player input
    mov ah, 1           ; BIOS get keyboard status int 16h AH 01h
    int 16h
    jz move_cpu_up         ; No key entered, don't check, move on

    cbw                 ; Zero out AH in 1 byte
    int 16h             ; BIOS get keystroke, scancode in AH, character in AL

    cmp ah, KEY_W
    je w_pressed
    cmp ah, KEY_S
    je s_pressed
    cmp ah, KEY_C
    je c_pressed
    cmp ah, KEY_R
    je r_pressed

    jmp move_cpu_up        ; Otherwise user entered some other key, move on

    ;; Move player paddle up
    w_pressed:
        dec word [playerY]  ; Move 1 row up
        jge move_cpu_up     ; If player Y is at/above 0 (minimum Y value), then move on
        inc word [playerY]  ; Else increment row # for collision check
        jmp move_cpu_up

    ;; Move player paddle down
    s_pressed:
        cmp word [playerY], SCREENH - PADDLEHEIGHT   ; Is player going to pass bottom of screen?
        jg move_cpu_up                               ; Yes, don'tmove
        inc word [playerY]                           ; No, can move row down
        jmp move_cpu_up

    ;; Change Color of Middle line and paddles
    c_pressed:
        add byte [drawColor], 10h       ; Move to next VGA color
        jmp move_cpu_up

    ;; Reset game to initial state
    r_pressed:
        int 19h     ; Reloads the bootsector(in QEMU)

    ;; Move CPU
    move_cpu_up:
        mov bx, [cpuY]
        cmp bx, [ballY]     ; Is top of CPU paddle at or above the ball?
        jle move_cpu_down   ; Yes, move on
        dec word [cpuY]     ; No, move cpu up
        jnz move_ball
        inc word [cpuY]     ; If CPU hit top of area, move back down to correct
    
    move_cpu_down:
        add bx, PADDLEHEIGHT
        cmp bx, [ballY]         ; Is bottom of CPU paddle at or above the ball?
        jge move_ball           ; Yes, move on
        inc word [cpuY]         ; No, move cpu down
        cmp word [cpuY], 24     ; Did cpu hit bottom of area?
        jl move_ball            ; No, move on
        dec word [cpuY]         ; Yes, move back up to correct

    ;; Move Ball
    move_ball:
        ;; Draw ball at current position
        imul di, [ballY], ROWLEN
        add di, [ballX]
        mov word [es:di], 2000h

        ;; Move ball to next position
        mov bl, [ballVelX]      ; Ball X position change
        add [ballX], bl
        mov bl, [ballVelY]     ; Ball Y position change
        add [ballY], bl

    ;; Check collisions
    check_hit_top:
        cmp word [ballY], 0          ; Did ball hit top of screen? (Y minimum value = 0)
        jg check_hit_bottom
        neg byte [ballVelY]
        jmp end_collision_checks

    check_hit_bottom:
        cmp word [ballY], 24
        jl check_hit_player
        neg byte [ballVelY]
        JMP end_collision_checks

    check_hit_player:
        cmp word [ballX], PLAYERX        ; Is ball at same position as player paddle?
        jne check_hit_cpu           ; No, move on
        mov bx, [playerY]
        cmp bx, [ballY]             ; Is top of player paddle equal or above the ball?
        jg check_hit_cpu            ; No, move on
        add bx, PADDLEHEIGHT        ; Check if hit bottom of player paddle
        cmp bx, [ballY]
        jl check_hit_cpu            ; Bottom of paddle is above ball, move on
        neg byte [ballVelX]         ; Othewise hit ball, reverse X direction
        jmp end_collision_checks


    check_hit_cpu:

    end_collision_checks:
    ;; Delay timer to next cycle
    mov bx, [046Ch]
    inc bx
    inc bx
    .delay:
        cmp [046Ch], bx
        jl .delay

jmp game_loop

;; Win/Lose condition

;; END LOGIC ===============
;; Bootsector padding
times 510-($-$$) db 0
dw 0AA55h ; MAGIC Bootsector number #