ENTRY(start)

SECTIONS {
    . = 1M;

    .boot : /* we create a section named boot inside we put every section named multiboot_header */
    {
        /* ensure that the multiboot header is at the beginning */
        *(.multiboot_header)
    }

    .text :
    {
        *(.text)
    }
}

