;; SETUP ----------
use16           ; use 16 bit code when assembing

org 07C00h      ; Set bootsector to be at memory location hex 7C00h
jmp setup_game  ; Jump over Variables section so we don't tryto execute it

;; CONSTANTS ----------
VIDMEM equ 0B800h
ROWLEN equ 160      ; 80 Character row * 2 bytes each

;; VARIABLES ----------
drawColor: db 0F0h


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
    mov ah, [drawlColor]    ; White bg, black bg
    mov di, 78              ; Start at middle of 80 character row
mov cl, 13                  ; 'Dashed' line - only draw every other row
    .draw_middle_loop:
        stosw
        add di, 2*ROWLEN-2       ; Only draw every other row (80 Char * 2 bytes * 2 rows)
        loop .draw_middle_loop   ; Loops CX # of times

    ;; Draw player paddle

    ;; Draw CPU paddle

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