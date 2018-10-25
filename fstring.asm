;; FSTring module.
;; A module for easy and fast working with a string
;;
;; @author Marek Sedlacek, (xsedla1b)
;; @date October 2018
;; @email xsedla1b@fit.vutbr.cz 
;;        mr.mareksedlacek@gmail.com
;;

;; Exported functions 
global fstrfromstr

;; Included C functions
extern malloc
extern puts

;; Constants
FSTR_STRUCT_SIZE EQU 24                         ;; How many bytes does the fstring_t data type takes

;; Global variables
section .data

;; Code section
section .text

;; FSTRFROMSTR
;; Converts C string to FSTring
;;
;; @param
;;      char *str       - RDI - CString
;; @return pointer to a fstring object
;; 
fstrfromstr:
        ; uint64_t len = fstr_cstr_len(str);
        ; fstring_t *new = malloc(FSTR_STRUCT_SIZE+len+alignment);
        ; new->length = len;
        ; new->aloc_len = len+alignment;
        ; new->text = str;
        ; return new;
        mov r10, rdi                            ;; Save pointer to string (RDI will be rewritten to call malloc
        call cstrlen
               

        ;; Leave function
        ret
;; end fstrfromstr

;; CSTRLEN
;; Returns length of a CString
;; 
;; @param
;;      - RDI - CString
;; @return length of a cstring
;;
cstrlen:
        xor rax, rax                            ;; Clear rax
        jmp short .cstrlen_frst
.cstrlen_loop:                                  ;; Loop (until zero end is found)
        add rax, rcx                            ;; Add from previous cycle placed here so the flags are not affected (no need to clear RCX, because of it being rewritten)
        add rax, 1                              ;; Add 1 because of indexing from 0
.cstrlen_frst:
        movups xmm0, [rdi+rax]                  ;; Load string with offset to xmm0 (memory is unaligned)
        ;; Malloc guarantees the allocated memory to be a multiple of 16 thus PCMPISTRI can be used for whole string of unknown length
        pcmpistri xmm0, xmm0, 0x60              ;; Compate for end of string 
        jnz .cstrlen_loop                       ;; If end was found the ZF is set
        
        cmp rcx, 16                             ;; Check if rcx is bigger than max index (15), then the string is empty
        je .cstrlen_end                         ;; Return
        
        add rax, rcx                            ;; Add indexes from the last cycle   
        add rax, 1                              ;; Add aditional 1 because of indexing starting from 0
.cstrlen_end:
        ret
;; end cstrlen       
