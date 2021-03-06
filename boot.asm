global start ; this says I will define a start function and I want it to be available outside of this file

section .text ; the code written after a section tag is in the section until the next section tag
bits 32 ; Grub will boot us in protected mode
start:
     ; Point the first entry of the level 4 page table to the first entry in the p3 table
    mov eax, p3_table ; copy the content of the 1st PTE to the eax register
    or eax, 0b11 ; we use the or operation between the eax content and ob11to turn the first bits of the adress into 1. Indeed, the first bits of the address are metadata about the page referenced. The first bit set to 1 is saying, "this page is currently in memory" and the 2nd bit is saying that this page is allowed to be changed/re-written.
    mov dword [p4_table + 0], eax ; now we move the eax content to the 4rth PTE so the first PTE of the 3rd level page table refers to the 4rth level page table


    ; We do the same now but mapping the 2nd level PTE to the 3rd level PTE
    mov eax, p2_table
    or eax, 0b11
    mov dword [p3_table + 0], eax 

    ; point each page table level two entry to a page
    mov ecx, 0 ; counter variable for the loop
    .map_p2_table:
    mov eax, 0x200000  ; 2MiB is the size of a page, so when we define a page (what we do each time of a loop), we actually allocate 2 MiB
    mul ecx ; we multiply the counter by the size of the tables so we know where we are in memory 
    or eax, 0b10000011 ; still use the or operator to set up the first bits which ar elike metadata about this page
    mov [p2_table + ecx * 8], eax ; we are writing the value in eax to the location in square brackets. The location of the p2_tabke is summed with ecx * 8 because each PTE is an address to 8 bytes. We shift by 8 bytes to allocate the address of the page we are looping on

    inc ecx ; increment the counter register by one
    cmp ecx, 512 ; compare the counter variables witht the number of adress in our page tables (512) since the page tables are 4096 bytes large and a PTE is and adress so 8 bytes or a word
    jne .map_p2_table

    ; Now that we have our page tables, we must perform some steps to enable paging 
    ; move page table address to cr3, a control register so it can access our page tables probably. The p4_table is probably the table always in memory that can refer to the other tables
    mov eax, p4_table
    mov cr3, eax

    ; enable PAE : Physical Adress Extension
    mov eax, cr4
    or eax, 1 << 5
    mov cr4, eax

    ; set the long mode bit
    mov ecx, 0xC0000080
    rdmsr
    or eax, 1 << 8
    wrmsr

    ; enable paging
    mov eax, cr0
    or eax, 1 << 31
    or eax, 1 << 16
    mov cr0, eax

    lgdt [gdt64.pointer] ; we tell the hardware where the GDT table is located. Indeed, lgdt stands for load global descriptor table

    ; update segment registers to the gdt64 address it seems so. Apart from ax which is not a segment register
    mov ax, gdt64.data
    mov ss, ax
    mov ds, ax
    mov es, ax

    ; jump to long mode!
    jmp gdt64.code:long_mode_start ; this is what we call a long jump which will assign GDT entry to the code segment register 

    ; We write Hello world afterwards to see if everything worked
    mov word [0xb8000], 0x0248 ; H ; 0248 can be stored on 16 bits because each hexadecimal digit can be stored as 4 bits. So each letter is 2 bytes. And since a memory address can store only 1 byte, there is a letter every 2 bytes in the memory space of the screen 0xb8000 to 0xb8002
    mov word [0xb8002], 0x0265 ; e
    mov word [0xb8004], 0x026c ; l
    mov word [0xb8006], 0x026c ; l
    mov word [0xb8008], 0x026f ; o
    mov word [0xb800a], 0x022c ; ,
    mov word [0xb800c], 0x0220 ;
    mov word [0xb800e], 0x0277 ; w
    mov word [0xb8010], 0x026f ; o
    mov word [0xb8012], 0x0272 ; r
    mov word [0xb8014], 0x026c ; l
    mov word [0xb8016], 0x0264 ; d
    mov word [0xb8018], 0x0221 ; !
    hlt

section .bss

align 4096 ; makes sure we've aligned the tables properly in multiples of 4096 byte chunks

; Define our 3 page table
p4_table:
    resb 4096
p3_table:
    resb 4096
p2_table:
    resb 4096

section .rodata ; define another section standing for "read only data", which is a good idea because we are not going to modify our GDT
gdt64: ; label used later to tell the hardware where the GDT is located
    dq 0 ; set up the zero entry

.code: equ $ - gdt64  ; set up the code segment, $ is the current position, so we substract the current position per the adress of gdt64 so how far is the beginning of the code segment from the beginning of the GDT. The equ keyword is used to set the adress of the label to the difference computed
    dq (1<<44) | (1<<47) | (1<<41) | (1<<43) | (1<<53) ; setting some bits in the code segment that needs to be set. Like the last "or" which sets the 53 bits telling the hardware it is a 64 bits GDT

.data: equ $ - gdt64 ; set up the data segment
    dq (1<<44) | (1<<47) | (1<<41)

.pointer: ; 
    dw .pointer - gdt64 - 1 ; define the size of the GDT table
    dq gdt64 ; address of our table but why we must re-define it ?


section .text
bits 64
long_mode_start:
    mov rax, 0x2f592f412f4b2f4f ; These 2 lines of code (this one and the next one) are just here to prove that we are in 64 bits mode because we can use a 64 bits register
    mov qword [0xb8000], rax
    hlt
