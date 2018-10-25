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

;; Constants
FSTR_STRUCT_SIZE EQU 24                 ;; How many bytes does the fstring_t data type takes

;; Global variables
section .data

;; Code section
section .text

;; Converts C string to FSTring
;;
;; @param 1 pointer to a string
;; @return pointer to a fstring object
;; 
fstrfromstr:
        push rbp
        mov rbp, rsp                    
        ;; Stack frame 
        
        ; uint64_t len = fstr_cstr_len(str);
        ; fstring_t *new = malloc(FSTR_STRUCT_SIZE);
        ; new->length = new->alloc_len = len;
        ; new->text = str;
        ; return new;

        

        ;; Leave function
        mov rsp, rbp
        pop rbp
        ret
;; end fstrfromstr              
