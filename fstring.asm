;; FSTring module.
;; A module for easy and fast working with a string
;;
;; @author Marek Sedlacek, (xsedla1b)
;; @date October 2018
;; @email xsedla1b@fit.vutbr.cz 
;;        mr.mareksedlacek@gmail.com
;;

;; Exported functions 
global fstrfromstr                              ;; Converts cstring to fstring
global fstrtostr                                ;; Converts fstring (or part of it) to a cstring
global fstrfree                                 ;; Free the text and the object

;; Included C functions
extern malloc
extern free

;; Constants
FSTR_STRUCT_SIZE        EQU 32                  ;; How many bytes does the fstring_t data type takes
FSTR_LENGTH_OFFSET      EQU 0                   ;; By how many bytes from the start of the fstring is the length offsetted
FSTR_ALLOC_LEN_OFFSET   EQU 8                   ;; By how many bytes from the start of the fstring is the allocated length offsetted
FSTR_TEXT_OFFSET        EQU 16                  ;; By how many bytes from the start of the fstring is the text offsetted
FSTR_ALLOC_START_OFFSET EQU 24                  ;; By how many bytes from the start of the fstring is the alloc_start offsetted

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
;; @code
;;      fstring_t *new = malloc(FSTR_STRUCT_SIZE); //15 for alignment
;;      uint64_t len = fstr_cstr_len(str);
;;      new->alloc_start = malloc(len+15)
;;      new->text = (new->alloc_start+15) & -16 // Shift address to be aligned
;;      new->length = len;
;;      new->aloc_len = len+alignment;
;;      copy_str(new->text);
;;      return new;
;;
;; @note Malloc guarantees memory alignment (length) to be multiple of 16 (thus no need to do it manually)
;;
fstrfromstr:                                                                                            ;; TODO: Add the after padding to the alloc_length
        push rbp
        mov rbp, rsp
        push rdi                                ;; Save rdi (str) on stack for later use [rbp-8]
        sub rsp, 8                              ;; Space for local variables - start [rbp-16]
        and rsp, -16                            ;; Align stack
        
        push rbx
        push rsi
        ;; Stack frame end

        mov rdi, FSTR_STRUCT_SIZE               ;; Size of the fstring object (parameter for malloc)
        call malloc                             ;; Allocate the struct (RAX)
        mov qword[rbp-16], rax                  ;; fstring object pointer saved to stack (because of malloc call later on)
        
        mov rdi, qword[rbp-8]                   ;; Get str from stack
        call cstrlen                            ;; Get the string length (RAX)
        mov rdx, qword[rbp-16]                  ;; Load fstring object pointer
        mov qword[rdx+FSTR_LENGTH_OFFSET], rax  ;; Save the allocated start in the alloc_start
        
        mov rdi, rax                            ;; Set length as a parameter for malloc
        add rdi, 15                             ;; Add padding for moving pointer for alignment
        call malloc                             ;; Allocate memory for a fstring (with padding)
        mov rbx, qword[rbp-16]                  ;; Load fstring object pointer
        mov qword[rbx+FSTR_ALLOC_START_OFFSET], rax    ;; Save the allocated start in the alloc_start
        add rax, 15                             ;; Creating aligned memory
        and rax, -16                            ;; Aligning
        mov qword[rbx+FSTR_TEXT_OFFSET], rax    ;; Text start (aligned 16B)

        mov rdi, rax                            ;; Set destination as the text start
        mov rsi, qword[rbp-8]                   ;; Set the source
        mov rdx, qword[rbx+FSTR_LENGTH_OFFSET]  ;; Load the length
        call fmemmove

        mov rax, qword[rbp-16]                  ;; Return the object
        
        ;; Leave function
        pop rsi
        pop rbx

        mov rsp, rbp
        pop rbp
        ret
;; end fstrfromstr


;; FSTRTOSTR 
;; Converts part of the fstring to a newly allocated cstring
;;
;; @param
;;      fstring *fstr   - RDI - FSTring
;;      uint start      - RSI - Starting index
;;      uint end        - RDX - End index
;; @return Dynamically created cstring containing text from fstr passed in
;; @code 
;;      if(end > fstr->length)
;;              end = fstr->length;
;;      if(start > end)
;;              start = 0;
;;      char *str = malloc(end-start+1);
;;      str = copy_str(&fstr->text[start], end-start);
;;      str[end-start] = '\0'
;;      return str;
;; 
fstrtostr:
        cmp rdx, qword[rdi+FSTR_LENGTH_OFFSET]  ;; Check if the end is bigger than the string length
        cmova rdx, qword[rdi+FSTR_LENGTH_OFFSET] ;; If end is bigger than length change end to length
        cmp rsi, rdx                            ;; Check if starting index is bigger than the ending
        jbe .fstrtostr_nabove                   ;; Start is not above end
        xor rsi, rsi                            ;; If starting index is bigger than ending index, change it to 0
.fstrtostr_nabove:
        push rdi                                ;; Saving register because of malloc call
        push rsi
        push rdx

        mov rdi, rdx                            ;; Calculate the needed length
        sub rdi, rsi                            ;; Indexes are unsigned and rsi <= rdi
        add rdi, 1                              ;; Size will be at least 1 for the \0 (note: add is better than inc)
        call malloc                             ;; Allocate the space for the new cstring (RAX)
        
        pop rdx                                 ;; Recover register values before call
        pop rsi
        pop rdi

        xchg rdi, rax                           ;; Move destination to RDI (RAX->fstr)
        mov rcx, qword[rax+FSTR_TEXT_OFFSET]    ;; Move text pointer to the rcx
        add rcx, rsi                            ;; Move starting index
        mov rax, rdx                            ;; End index
        sub rax, rsi                            ;; Get length
        mov rsi, rcx                            ;; Set the source
        mov rdx, rax                            ;; Set the length
        call fmemumove                          ;; Copy the string (malloc for cstring was not aligned)
        mov byte[rdi+rdx], 0                    ;; Add terminating 0

        mov rax, rdi                            ;; Return the cstring
        ;; Leave function
        ret
;; end fstrtostr


;; FSTRFREE 
;; Frees fstring from a memory
;;
;; @param
;;      fstr    - RDI - FSTring
;; @return no return
fstrfree:
        push rdi
        mov rdi, qword[rdi+FSTR_TEXT_OFFSET]    ;; Find the text address
        call free                               ;; Free the text
        pop rdi
        mov rdi, qword[rdi+FSTR_ALLOC_START_OFFSET] ;; Find the actuall object allocation start (unaligned)
        call free
        ;; Leave function
        ret
;; end fstrfree

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
        pcmpistri xmm0, xmm0, 0x60              ;; Compare with itself, ending on \0, thus finding the end and setting the index
        jnz .cstrlen_loop                       ;; If end was found the ZF is set
        
        cmp rcx, 16                             ;; Check if rcx is bigger than max index (15), then the string is empty
        je .cstrlen_end                         ;; Return
        
        add rax, rcx                            ;; Add indexes from the last cycle   
        add rax, 1                              ;; Add aditional 1 because of indexing starting from 0
.cstrlen_end:
        ret
;; end cstrlen 


;; FMEMMOVE
;; Copies memory block with aligned length to another aligned destination
;;
;; @param
;;      dest    - RDI - Destination
;;      src     - RSI - Source
;;      len     - RDX - Length of the block
;; @return no return (rax will be how many blocks were moved)
fmemmove:
        xor rax, rax
.fmemmove_loop:
        movdqu xmm0, [rsi+rax]                  ;; Load the memory (unaligned)
        movdqa [rdi+rax], xmm0                  ;; Save the memory (aligned)
        add rax, 16                             ;; Add to the index     
        cmp rax, rdx                            ;; Compare
        jb .fmemmove_loop

        ret
;; end fmemmove

;; FMEMUMOVE
;; Copies unaligned memory block with aligned length to another unaligned destination
;;
;; @param
;;      dest    - RDI - Destination
;;      src     - RSI - Source
;;      len     - RDX - Length of the block
;; @return no return (rax will be how many blocks were moved)
fmemumove:
        xor rax, rax
.fmemumove_loop:
        movdqu xmm0, [rsi+rax]                  ;; Load the memory (unaligned)
        movdqu [rdi+rax], xmm0                  ;; Save the memory (unaligned)
        add rax, 16                             ;; Add to the index     
        cmp rax, rdx                            ;; Compare
        jb .fmemumove_loop

        ret
;; end fmemmove