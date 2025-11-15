;; SETUP ----------
use16           ; use 16 bit code when assembing

org 07C00h      ; Set bootsector to be at memory location hex 7C00h
jmp setup_game  ; Jump over Variables section so we don't tryto execute it

;; CONSTANTS ----------
VIDMEM equ 0B800h   ; Color text mode VGA memory location
ROWLEN equ 160      ; 80 Character row * 2 bytes each
PLAYERX equ 4       ; Player X position
CPUX    equ 156     ; CPU X Position

;; VARIABLES ----------
drawColor: db 0F0h
playerY:   dw 10    ; Start player Y position 10 rows down
cpuY:      dw 10

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

    ;; Draw mddle separating line
    mov ah, [drawColor]    ; White bg, black bg
    mov di, 78              ; Start at middle of 80 character row
    mov cx, 13                  ; 'Dashed' line - only draw every other row
    .draw_middle_loop:
        stosw
        add di, 2*ROWLEN-2       ; Only draw every other row (80 Char * 2 bytes * 2 rows)
        loop .draw_middle_loop   ; Loops CX # of times

    ;; Draw player paddle
    imul di, [playerY], ROWLEN   ; Y position is Y # rows * length of row
;    add di, PLAYERX
    mov cl, 5
    .draw_player_loop:
        mov [es:di+PLAYERX], ax
;        stosw
        add di, ROWLEN
        loop .draw_player_loop

    ;; Draw CPU paddle
    imul di, [cpuY], ROWLEN
    mov cl, 5
    .draw_cpu_loop:
        mov [es:di+CPUX], ax
        add di, ROWLEN
        loop .draw_cpu_loop

    ;; Draw ball

    ;; Get Player input


;; Player input

;; CPU input
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