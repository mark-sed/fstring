;; FSTring module.
;; A module for easy and fast work with a string
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
global fstrset                                  ;; Sets text of a fstring
global fstrappend                               ;; Appends string to the end of fstring
global fstr_to_upper                            ;; Converts all letters to uppercase
global fstr_to_lower                            ;; Converts all letters to lowercase
global fstrcapitalize                           ;; Converts first letter (at index) to uppercase
global fstrflip                                 ;; Flips string
global fstrcopy                                 ;; Copies string into fstring at certain location
global fstrinsert                               ;; Inserts string into fstring at certain location

global fstr_find_first                          ;; Finds first appearance of an fstring in an fstring
global fstrsplit                                ;; Splits string into substrings by a separator

;; Included C functions
extern malloc
extern realloc
extern free

;; Constants
FSTR_STRUCT_SIZE        EQU 32                  ;; How many bytes does the fstring_t data type takes
FSTR_LENGTH_OFFSET      EQU 0                   ;; By how many bytes from the start of the fstring is the length offsetted
FSTR_ALLOC_LEN_OFFSET   EQU 8                   ;; By how many bytes from the start of the fstring is the allocated length offsetted
FSTR_TEXT_OFFSET        EQU 16                  ;; By how many bytes from the start of the fstring is the text offsetted
FSTR_ALLOC_START_OFFSET EQU 24                  ;; By how many bytes from the start of the fstring is the alloc_start offsetted

;; Global variables
section .data
__CONST_64_BYTE         dd  0x40_40_40_40, 0x40_40_40_40, 0x40_40_40_40, 0x40_40_40_40       ;; 4*Double filled with 64 on each byte
__CONST_91_BYTE         dd  0x5B_5B_5B_5B, 0x5B_5B_5B_5B, 0x5B_5B_5B_5B, 0x5B_5B_5B_5B       ;; 4*Double filled with 91 on each byte
__CONST_96_BYTE         dd  0x60_60_60_60, 0x60_60_60_60, 0x60_60_60_60, 0x60_60_60_60       ;; 4*Double filled with 96 on each byte
__CONST_123_BYTE        dd  0x7B_7B_7B_7B, 0x7B_7B_7B_7B, 0x7B_7B_7B_7B, 0x7B_7B_7B_7B       ;; 4*Double filled with 123 on each byte
__CONST_32_BYTE         dd  0x20_20_20_20, 0x20_20_20_20, 0x20_20_20_20, 0x20_20_20_20       ;; 4*Double filled with 32 on each byte

__CONST_FLIP            dd  0x0C_0D_0E_0F, 0x08_09_0A_0B, 0x04_05_06_07, 0x00_01_02_03       ;; Flipped indexes (15-0)

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
;;      copy_str(new->text, str);
;;      return new;
;;
;; @note Malloc guarantees memory alignment (length) to be multiple of 16 (thus no need to do it manually)
;;
fstrfromstr:
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
        mov qword[rdx+FSTR_LENGTH_OFFSET], rax  ;; Save the length
        mov qword[rdx+FSTR_ALLOC_LEN_OFFSET], rax ;; Save the allocated length

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
        call fmemuamove                         ;; Move unaligned to aligned

        mov rax, qword[rbp-16]                  ;; Return the object
        
        ;; Leaving function
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
        push rbp
        mov rbp, rsp
        and rsp, -16                            ;; Align stack
        ;; Stack frame end

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
        call fmemaumove                         ;; Copy the string (malloc for cstring was not aligned)
        mov byte[rdi+rdx], 0                    ;; Add terminating 0

        mov rax, rdi                            ;; Return the cstring

        ;; Leave function
        mov rsp, rbp
        pop rbp
        ret
;; end fstrtostr


;; FSTRFREE 
;; Frees fstring from a memory
;;
;; @param
;;      fstring *fstr   - RDI - FSTring
;; @return no return
fstrfree:
        push rbp
        mov rbp, rsp
        and rsp, -16                            ;; Align stack
        ;; Stack frame end

        push rdi
        mov rdi, qword[rdi+FSTR_ALLOC_START_OFFSET] ;; Find the text real address (text is ofsetted for alignment)
        call free                               ;; Free the object
        pop rdi
        call free

        ;; Leave function
        mov rsp, rbp
        pop rbp
        ret
;; end fstrfree


;; FSTRSET
;; Rewrites text in fstring (If text is longer than allocated length, it is reallocated, if smaller then it is not)
;;
;; @param
;;      fstring *fstr   - RDI - FSTring
;;      char *str       - RSI - Cstring text to set the string
;; @return no return
;; @code
;;      uint64_t len = fstr_cstr_len(str);
;;      if(len > fstr->alloc_len){
;;              fstr->alloc_start = realloc(fstr->alloc_start, len+15);
;;              fstr->text = (fstr->alloc_start+15) & -16;
;;              fstr->alloc_length = len;
;;      }        
;;      copy_str(new->text);
;;      fstr->length = len;
fstrset:
        push rbp
        mov rbp, rsp
        push rdi                                ;; Save rdi (fstr) on stack for later use [rbp-8]
        push rsi                                ;; Save rsi (str) [rbp-16]
        and rsp, -16                            ;; Align stack
        ;; Stack frame end

        xchg rdi, rsi                           ;; Move str as a parameter for cstrlen
        call cstrlen                            ;; Find out how long is cstring (RAX)
        mov qword[rsi+FSTR_LENGTH_OFFSET], rax  ;; Save length
        cmp rax, qword[rsi+FSTR_ALLOC_LEN_OFFSET] ;; Check if new string would fit into the allocated space
        jbe .fstrset_fits                       ;; Skip realloc if fits
        
        mov qword[rsi+FSTR_ALLOC_LEN_OFFSET], rax ;; Save new length as new allocation length
        mov rdi, qword[rsi+FSTR_ALLOC_START_OFFSET] ;; Set the text as an argument for realloc
        mov rsi, rax                            ;; Set length as an argument for realloc
        add rsi, 15                             ;; Add 15 for alignment
        call realloc                            ;; Reallocate the memory
        
        mov rsi, qword[rbp-8]                   ;; Load fstring object
        mov qword[rsi+FSTR_ALLOC_START_OFFSET], rax ;; Set the alloc start to the new one returned by realloc
        add rax, 15                             ;; Creating aligned memory
        and rax, -16                            ;; Aligning
        mov qword[rsi+FSTR_TEXT_OFFSET], rax    ;; Text start (aligned 16B)
.fstrset_fits:                                  ;; If jumped here then the string fits to the allocated space
        mov rax, qword[rbp-8]                   ;; Get the fstr
        mov rdi, qword[rax+FSTR_TEXT_OFFSET]    ;; Set the text pointer as a 1st argument
        mov rsi, qword[rbp-16]                  ;; Set the cstring as a 2nd argument
        mov rdx, qword[rax+FSTR_LENGTH_OFFSET]  ;; Set the length as a 3rd argument 
        add rdx, 1                              ;; Get also the +1 for \0      
        call fmemuamove                         ;; Move test from unaligned memory to aligned memory
        ;; Leaving function
        mov rsp, rbp
        pop rbp
        ret
;; end fstrset


;; FSTRAPPEND
;; Appends cstring to the end of the fstring
;;
;; @param
;;      fstr    - RDI - FSTring
;;      str     - RSI - CString 
;; @return no return
;; @code 
;;      len = cstrlen(str);
;;      if(fstr->len+len >= fstr->alloc_len)
;;              fstrrealloc(fstr, ((fstr->len+len)*2+15)&-16);   
;;      fmemuumove(&(fstr->text[fstr->len]), str);
;;      fstr->length = fstr->len+len;
fstrappend:
        push rbp
        mov rbp, rsp
        and rsp, -16                            ;; Align stack
        push r12
        push r13
        push r14
        push r15
        ;; Stack frame end

        mov r14, rdi                            ;; Save fstring
        mov r13, rsi                            ;; Save cstring
        xchg rdi, rsi                           ;; Switch registers so that cstring is an argument for cstrlen
        call cstrlen                            ;; Calculate length of appending string (RAX)
        mov r12, rax                            ;; Save length of cstring

.fstrappend_realloc_loop:
        mov r15, qword[r14+FSTR_LENGTH_OFFSET]  ;; Get fstring length
        add r15, rax                            ;; fstr->length+length(str)
        mov rdx, qword[r14+FSTR_ALLOC_LEN_OFFSET] ;; Get alloc length

        cmp r15, rdx                            ;; Find out if new string fits
        jb .fstrappend_fits                     ;; Fits, skip realloc
        
        mov rdi, r14                            ;; Set fstring as an argument for fstrrealloc
        mov rsi, r15                            ;; Set length of fstr+str as an argument for fstrrealloc
        shl rsi, 1                              ;; Multiply length by 2
        add rsi, 15                             ;; Add 15 for alignment of length
        and rsi, -16                            ;; Align length
        call fstrrealloc                        ;; Reallocate fstring
        
        jmp short .fstrappend_realloc_loop      ;; Check if it fits now

.fstrappend_fits:                               ;; String fits now
        
        mov rax, qword[r14+FSTR_LENGTH_OFFSET]  ;; Get fstr length
        mov rdi, qword[r14+FSTR_TEXT_OFFSET]    ;; Get text pointer
        add rdi, rax                            ;; Skip to the end and set as argument
        mov rsi, r13                            ;; Set str ad second argument
        mov rdx, r12                            ;; Set length to length of str
        call fmemuumove                         ;; Both addresses are unaligned, append

        add r12, r15                            ;; Add previous length to appended str length
        mov qword[r14+FSTR_LENGTH_OFFSET], r12  ;; Set length to a new length

        ;; Leaving function
        pop r15
        pop r14
        pop r13
        pop r12
        mov rsp, rbp
        pop rbp
        ret
;; end fstrappend


;; FSTRREALLOC 
;; Reallocates fstring to new size, allignes the memory and saves new size to the object
;; Realloc does not guarantee aligned memory, thus this process is done by calling malloc and copying data and freeing old memory
;;
;; @param
;;      - RDI - *fstring
;;      - RSI - new size
;; @return no return
;; @code
;;      void *newmem = malloc(RSI);
;;      void *alignstart = (newmem+15) & -16;
;;      fmemaamove(alignstart, RDI->text, RDI->length);
;;      void *delmem = RDI->alloc_start;
;;      free(delmem);
;;      RDI->alloc_start = newmem;
;;      RDI->text = alignstart;
;;      RDI->alloc_len = RSI;
fstrrealloc:
        push rbp
        mov rbp, rsp
        and rsp, -16
        push r12
        push r13
        push r14
        push r15
        ;; Stack frame end

        mov r14, rdi                            ;; Saving fstring because of malloc call
        mov r15, rsi                            ;; Saving new_size because of malloc call

        mov rdi, rsi                            ;; Set argument for malloc
        call malloc                             ;; Get new memory (RAX)
        mov r13, rax                            ;; Save the memory for alloc_start
        add rax, 15                             ;; Add 15 for alignement
        and rax, -16                            ;; Align

        mov rdi, rax                            ;; Set destionation
        mov rsi, qword[r14+FSTR_TEXT_OFFSET]    ;; Set source (text)
        mov rdx, qword[r14+FSTR_LENGTH_OFFSET]  ;; Set length
        call fmemaamove                         ;; Copy text

        mov r12, rdi                            ;; Save new text pointer
        mov rdi, qword[r14+FSTR_ALLOC_START_OFFSET] ;; Find previous memory start
        call free                               ;; Free previous memory

        mov qword[r14+FSTR_ALLOC_START_OFFSET], r13 ;; Save new memory start
        mov qword[r14+FSTR_TEXT_OFFSET], r12    ;; Save text
        mov qword[r14+FSTR_ALLOC_LEN_OFFSET], r15 ;; Save new allocated length

        ;; Leaving function
        pop r15
        pop r14
        pop r13
        pop r12
        mov rsp, rbp
        pop rbp
        ret
;; end fstrrealloc


;; fstr_to_upper
;; Converts all letters to uppercase (in range). If range if incorrect, adjust bottom to 0 and top to length.
;; 
;; @param
;;      fstring *fstr   - RDI - FSTring to convert
;;      ulong start     - RSI - Starting index
;;      ulong end       - RDX - Ending index
;; @return No return
;; 
fstr_to_upper:
        cmp rdx, qword[rdi+FSTR_LENGTH_OFFSET]  ;; Check if the end is bigger than the string length
        cmova rdx, qword[rdi+FSTR_LENGTH_OFFSET] ;; If end is bigger than length change end to length
        cmp rsi, rdx                            ;; Check if starting index is bigger than the ending
        jbe .fstr_to_upper_nabove               ;; Start is not above end
        xor rsi, rsi                            ;; If starting index is bigger than ending index, change it to 0
.fstr_to_upper_nabove:

        mov r8, qword[rdi+FSTR_TEXT_OFFSET]     ;; Get the text
        add r8, rsi                             ;; Move to the starting index

        mov rcx, rdx                            ;; Load end index
        sub rcx, rsi                            ;; Calculate length
        shr rcx, 4                              ;; Divide by 16, to find out the amount of possible SSE cycles
        shl rcx, 4                              ;; Multiply by 16 (in adress cannot be *16)
        
.fstr_to_upper_sseloop:                         ;; SSE regs loop
        test rcx, rcx                           ;; Check if RCX is 0
        jz .fstr_to_upper_ssedone               ;; No more cycles can be done, abort
        sub rcx, 16                             ;; Decrese counter
        
        movdqu xmm2, [__CONST_123_BYTE]         ;; Load 123 to all bytes
        movdqu xmm1, [__CONST_96_BYTE]          ;; Load 96 into all bytes
        movdqa xmm3, [r8+rcx]                   ;; Load from aligned memory 16 characters
        movdqa xmm0, [r8+rcx]                   ;; Values are in cache, this should be faster than copying register
        
        pcmpgtb xmm3, xmm1                      ;; Check if characters are bigger than 96 (chars > 96). Mask saved in xmm0, because LT is not available
        pcmpgtb xmm2, xmm0                      ;; Check if characters are less than 123 (123 > chars). Mask saved in xmm2
        
        andps xmm3, xmm2                        ;; Get mask where ones are there where both conditions meet
        movdqu xmm2, [__CONST_32_BYTE]          ;; Load 32 to all bytes
        andps xmm3, xmm2                        ;; Get 32 to all positive matches
        xorps xmm0, xmm3                        ;; Xor lowercase letters with 32, changing them to uppercase
        movdqa [r8+rcx], xmm0                   ;; Save back to the text      

        jmp short .fstr_to_upper_sseloop        ;; While style loop
.fstr_to_upper_ssedone:
        mov rcx, rdx                            ;; Load end index
        sub rcx, rsi                            ;; Calculate length
        mov rax, rcx                            ;; Copy difference
        shr rax, 4                              ;; Divide by 4
        shl rax, 4                              ;; Multiply
        sub rcx, rax                            ;; Get how many letters are left to be converted
        
        add r8, rax                             ;; Move text to the not yet converted part
.fstr_to_upper_loop:
        test rcx, rcx                           ;; Check if rcx is 0
        jz .fstr_to_upper_loop_done             ;; If so, no more converting has to be done
        sub rcx, 1                              ;; sub is better than dec

        mov dl, byte[r8+rcx]                    ;; Get the current char
        cmp dl, 96                              ;; Compare if bigger than 96
        jbe .fstr_to_upper_loop                 ;; Get next char
        cmp dl, 123                             ;; Compare if less than 123
        jae .fstr_to_upper_loop                 ;; Get next char
        xor dl, 32                              ;; Convert
        mov byte[r8+rcx], dl                    ;; Save

        jmp short .fstr_to_upper_loop           ;; While style loop
.fstr_to_upper_loop_done:                       ;; Conversion is done
        ret
;; end fstr_to_upper


;; FSTR_TO_LOWER 
;; Converts letters to lowercase
;;
;; @param
;;      fstring *fstr   - RDI - FSTring to convert
;;      ulong start     - RSI - Starting index
;;      ulong end       - RDX - Ending index
;; @return No return
;; 
fstr_to_lower:
        cmp rdx, qword[rdi+FSTR_LENGTH_OFFSET]  ;; Check if the end is bigger than the string length
        cmova rdx, qword[rdi+FSTR_LENGTH_OFFSET] ;; If end is bigger than length change end to length
        cmp rsi, rdx                            ;; Check if starting index is bigger than the ending
        jbe .fstr_to_lower_nabove               ;; Start is not above end
        xor rsi, rsi                            ;; If starting index is bigger than ending index, change it to 0
.fstr_to_lower_nabove:

        mov r8, qword[rdi+FSTR_TEXT_OFFSET]     ;; Get the text
        add r8, rsi                             ;; Move to the starting index

        mov rcx, rdx                            ;; Load end index
        sub rcx, rsi                            ;; Calculate length
        shr rcx, 4                              ;; Divide by 16, to find out the amount of possible SSE cycles
        shl rcx, 4                              ;; Multiply by 16 (in adress cannot be *16)
        
.fstr_to_lower_sseloop:                         ;; SSE regs loop
        test rcx, rcx                           ;; Check if RCX is 0
        jz .fstr_to_lower_ssedone               ;; No more cycles can be done, abort
        sub rcx, 16                             ;; Decrese counter
        
        movdqu xmm2, [__CONST_91_BYTE]          ;; Load 91 to all bytes
        movdqu xmm1, [__CONST_64_BYTE]          ;; Load 64 into all bytes
        movdqa xmm3, [r8+rcx]                   ;; Load from aligned memory 16 characters
        movdqa xmm0, [r8+rcx]                   ;; Values are in cache, this should be faster than copying register
        
        pcmpgtb xmm3, xmm1                      ;; Check if characters are bigger than 64 (chars > 64). Mask saved in xmm0, because LT is not available
        pcmpgtb xmm2, xmm0                      ;; Check if characters are less than 91 (91 > chars). Mask saved in xmm2
        
        andps xmm3, xmm2                        ;; Get mask where ones are there where both conditions meet
        movdqu xmm2, [__CONST_32_BYTE]          ;; Load 32 to all bytes
        andps xmm3, xmm2                        ;; Get 32 to all positive matches
        xorps xmm0, xmm3                        ;; Xor lowercase letters with 32, changing them to uppercase
        movdqa [r8+rcx], xmm0                   ;; Save back to the text      

        jmp short .fstr_to_lower_sseloop        ;; While style loop
.fstr_to_lower_ssedone:
        mov rcx, rdx                            ;; Load end index
        sub rcx, rsi                            ;; Calculate length
        mov rax, rcx                            ;; Copy difference
        shr rax, 4                              ;; Divide by 4
        shl rax, 4                              ;; Multiply
        sub rcx, rax                            ;; Get how many letters are left to be converted
        
        add r8, rax                             ;; Move text to the not yet converted part
.fstr_to_lower_loop:
        test rcx, rcx                           ;; Check if rcx is 0
        jz .fstr_to_lower_loop_done             ;; If so, no more converting has to be done
        sub rcx, 1                              ;; sub is better than dec

        mov dl, byte[r8+rcx]                    ;; Get the current char
        cmp dl, 64                              ;; Compare if bigger than 64
        jbe .fstr_to_lower_loop                 ;; Get next char
        cmp dl, 91                              ;; Compare if less than 91
        jae .fstr_to_lower_loop                 ;; Get next char
        xor dl, 32                              ;; Convert
        mov byte[r8+rcx], dl                    ;; Save

        jmp short .fstr_to_lower_loop           ;; While style loop
.fstr_to_lower_loop_done:                       ;; Conversion is done
        ret
;; end fstr_to_lower


;; FSTRCAPITALIZE
;; Conversion specified letter to uppercase
;; If start is out of bounds, it is set to max
;;
;; @param
;;      fstring *fstr   - RDI - FSTring
;;      ulong start     - RSI - Starting index
;; @return No return
;;
fstrcapitalize:
        cmp rsi, qword[rdi+FSTR_LENGTH_OFFSET]  ;; Compare index to max index
        jb .fstrcapitalize_bellow               ;; Bellow length
        mov rsi, qword[rdi+FSTR_LENGTH_OFFSET]  ;; If end is bigger than length change end to length
        sub rsi, 1                              ;; Index = length-1 (at length is \0)
.fstrcapitalize_bellow:
        mov rdx, qword[rdi+FSTR_TEXT_OFFSET]    ;; Get the text
        mov al, byte[rdx+rsi]                   ;; Move to the correct index and get byte
                                                
        cmp al, 96                              ;; Compare if bigger than 96
        jbe .fstrcapitalize_done                ;; Skip
        cmp al, 123                             ;; Compare if less than 123
        jae .fstrcapitalize_done                ;; Skip
        xor al, 32                              ;; Convert
        mov byte[rdx+rsi], al                   ;; Save
.fstrcapitalize_done:
        ret
;; end fstrcapitalize


;; FSTR_FLIP
;; Flips the fstring
;; Vectorized only for strings longer than 31 letters
;;
;; @param
;;      fstring *fstr   - RDI - FSTring
;;      ulong start     - RSI - Starting index of fstr
;;      ulong end1      - RDX - Endind index of fstr
;; @return No return
fstrflip:
        mov rax, qword[rdi+FSTR_LENGTH_OFFSET]  ;; Load length of the string
        cmp rdx, rax                            ;; Check if the end is bigger than the string length
        jnae .fstrflip_nabove1                  ;; If in bounds skip change
        mov rdx, rax                            ;; Set the length to max possible
        sub rdx, 1                              ;; Delete \0
.fstrflip_nabove1:
        cmp rsi, rdx                            ;; Check if starting index is bigger than the ending
        jbe .fstrflip_nabove2                   ;; Start is not above end
        xor rsi, rsi                            ;; If starting index is bigger than ending index, change it to 0
.fstrflip_nabove2: 

        mov r8, qword[rdi+FSTR_TEXT_OFFSET]     ;; Load the text
        mov rax, rdx                            ;; Get the end
        sub rax, rsi                            ;; Find the length that is going to be changed
        mov rcx, rax                            ;; Copy the length
        xor r9, r9                              ;; Used as a counter
        add r9, rsi                             ;; Move the starting index
        movdqu xmm2, [__CONST_FLIP]             ;; Load the indexes for shufb
        add rcx, 1                              ;; Move the index by one
        mov r10, r8
        add r10, rsi
        shr rax, 5                              ;; Divide by 32 (xmm0+xmm1 sizes) to calculate how many cycles will be needed (sets ZF)
.fstrflip_sse_loop:                             ;; Loop for sse instructions
        jz .fstrflip_sse_loop_done
        
        sub rcx, 16                             ;; Move the address backwards 

        movdqu xmm0, [r8+r9]                    ;; Load the starting not converted 16 letters
        movdqu xmm1, [r10+rcx]                  ;; Load the last not converted 16 letters
        pshufb xmm0, xmm2                       ;; Rearrange bytes
        pshufb xmm1, xmm2                       ;; Rearrange bytes
        movdqu [r8+r9], xmm1                    ;; Save the last as the first
        movdqu [r10+rcx], xmm0                  ;; Save the first as the last
                              
        add r9, 16                              ;; Move the address
        sub rax, 1                              ;; Sets the flags for jz later one
        jmp short .fstrflip_sse_loop            ;; Repeat vectorized while we can

.fstrflip_sse_loop_done:                        ;; End of vectorized flip
        ;; rcx contains the last not converted index
        ;; r9 contains the first not converted index
        mov rax, rcx                            ;; Get the last index
        add rax, rsi                            ;; Add starting index
        mov r10, rcx                            ;; Get first starting
        sub r10, r9                             ;; Subtract length
        jz .fstrflip_done                       ;; No more needed to be flipped (length was multiple of 32)
.fstrflip_loop:                                 ;; Loop for non vectorized flip
        sub rax, 1                              ;; Decrement by one
        
        mov dl, byte[r8+r9]                     ;; Get the first not converted letter                    
        mov cl, byte[r8+rax]                    ;; Get the last not converted letter
        mov byte[r8+r9], cl                     ;; Save letter
        mov byte[r8+rax], dl                    ;; Save letter

        add r9, 1                               ;; Increas address
        cmp r9, rax                             ;; Compare if the indexes have met
        sub r10, 1
        jnz .fstrflip_loop                      ;; No more letters need converting
.fstrflip_done:                                 ;; All converted
        ret
;; end fstrflip


;; FSTRCOPY 
;; Copies a string into fstring at certain location
;;
;; @param
;;      fstring *fstr   - RDI - Fstring into which will be text copyed
;;      uint start      - RSI - Starting index of copying (in fstring)
;;      char *str       - RDX - String to copy
;; @return No return
fstrcopy:
        mov r8, [rdi+FSTR_LENGTH_OFFSET]        ;; Get fstr length
        cmp rsi, r8                             ;; Check if starting index is bigger than the length
        jbe .fstrcopy_nabove                    ;; Start is not above end
        xor rsi, rsi                            ;; If starting index is bigger than ending index, change it to 0
.fstrcopy_nabove:                               ;; Index is correct
        
        xchg rdi, rdx                           ;; Set string as argument strlen
        call cstrlen                            ;; Get length of the string (RAX)
        mov r10, rax                            ;; Save the length
        sub r8, rsi                             ;; Get the changing length
        cmp r8, r10                             ;; Compare lenghts
        cmovb r10, r8                           ;; Store the lower length for later
        shr rax, 4                              ;; Divide by 16 to get the amount of vectorized cycles
        shr r8, 4                               ;; Also get the amount of possible vectorized cycles based on fstr length
        cmp r8, rax                             ;; Compare
        cmovb rax, r8                           ;; Set the max cycles to the lowest value 
        xor rcx, rcx                            ;; Index
        mov r9, [rdx+FSTR_TEXT_OFFSET]          ;; Load the fstring test
        add r9, rsi                             ;; Offset the text
.fstrcopy_sse_loop:                             ;; Vectorized loop
        test rax, rax                           ;; Test if
        jz .fstrcopy_sse_loop_end               ;; No more cycles
        
        movdqu xmm0, [rdi+rcx]                  ;; Load 16B pro string
        movdqu [r9+rcx], xmm0                   ;; Save to the string 

        add rcx, 16
        sub rax, 1                              ;; Decrement counter
        jmp short .fstrcopy_sse_loop            ;; While style loop
.fstrcopy_sse_loop_end:
        
        add rdi, rcx                            ;; Shift string
        add r9, rcx                             ;; Shift fstring
        and r10, 0xF                            ;; Get the modulo after division by 16 of lower length
        xor rcx, rcx                            ;; Zero out index
.fstrcopy_loop:                                 ;; Non vectorized cycle
        cmp rcx, r10                            ;; Compare if index == end
        jz .fstrcopy_loop_end                   ;; All done

        mov al, byte[rdi+rcx]                   ;; Load the character
        mov byte[r9+rcx], al                    ;; Save the character
        
        add rcx, 1                              ;; Increase counter (add is better than inc on most processors)
        jmp short .fstrcopy_loop                ;; While style loop
.fstrcopy_loop_end:                             ;; All letter copied or end of fstr found
        ret
;; fstrcopy


;; FSTRINSERT 
;; Inserts a string into fstring at certain location
;;
;; @param
;;      fstring *fstr   - RDI - Fstring into which will be text inserted
;;      uint start      - RSI - Starting index of insert (in fstring)
;;      char *str       - RDX - String to insert
;; @return No return
fstrinsert:
        push rbp                                ;; Stack frame because of possible call to realloc
        mov rbp, rsp
        and rsp, -16
        push r11
        push r12
        push rbx
        ;; Stack frame end

        mov r8, [rdi+FSTR_LENGTH_OFFSET]        ;; Get fstr length
        cmp rsi, r8                             ;; Check if starting index is bigger than the length
        jbe .fstrinsert_nabove                  ;; Start is not above end
        xor rsi, rsi                            ;; If starting index is bigger than length, change it to 0
.fstrinsert_nabove:                             ;; Index is correct 
        
        xchg rdi, rdx                           ;; Set string as parameter to cstrlen
        call cstrlen                            ;; Get the length of str (RAX)
        mov r10, rax                            ;; Copy length of str
        mov r9, [rdx+FSTR_ALLOC_LEN_OFFSET]     ;; Get the whole allocated length
        add rax, r8                             ;; Add the length of fstring
        add rax, 1                              ;; Add one for \0
        cmp rax, r9                             ;; Check if the string fits or reallocation is needed
        jna .fstrinsert_fits                    ;; Skip realloc
        
        push rdi                                ;; Save later needed registers
        push rsi
        push rdx
        push r8
        push r10

        mov rdi, rdx                            ;; Set fstring as parameter
        mov rsi, r9                             ;; Set the current alloc length as new length
        shl rsi, 1                              ;; Multiply length by 2
        add rsi, 15                             ;; Add 15 for alignment of length
        and rsi, -16                            ;; Align length

        add rax, 15
        and rax, -16                            ;; Align precise length as well
        cmp rax, rsi                            ;; Compare lengths to use the bigger one
        cmova rsi, rax                          ;; If precise aligned length is bigger then multiple of 2, then set it as argument

        call fstrrealloc

        pop r10
        pop r8
        pop rdx
        pop rsi
        pop rdi                                 ;; Restore registers after call
.fstrinsert_fits:                               ;; String now can be inserted

        mov rax, qword[rdx+FSTR_TEXT_OFFSET]    ;; Load the text
        mov rcx, qword[rdx+FSTR_LENGTH_OFFSET]  ;; Get the length
        mov r12, rcx                            ;; Copy length
        add r12, r10                            ;; Add inserted string length
        add r10, rcx                            ;; Set the index
        mov r11, rcx                            ;; Copy length of fstring
        sub r11, rsi                            ;; Subtract starting index
        mov r9, r11                             ;; Copy length that is going to be moved
        and r9, 0xF                             ;; Get modulo after division by 16
        shr r11, 4                              ;; Divide by 16

.fstrinsert_move_sse_loop:                      ;; Vectorized cycles
        test r11, r11                           ;; Test is cycle counter is 0
        jz .fstrinsert_move_sse_loop_done       ;; No more cycles
        sub r11, 1                              ;; Decrement cycle counter
        sub rcx, 16                             ;; Decrease counter
        sub r10, 16                             ;; Decrease second counter
        movdqu xmm0, [rax+rcx]                  ;; Load last bytes
        movdqu [rax+r10], xmm0                  ;; Save bytes into the last bytes
        jmp short .fstrinsert_move_sse_loop     ;; While style loop
.fstrinsert_move_sse_loop_done:                 ;; SSE loop is done

.fstrinsert_move_loop:                          ;; Non vectorized loop
        test r9, r9                             ;; Check if cycle counter is 0
        jz .fstrinsert_move_loop_done           ;; No more cycles needed
        sub r9, 1                               ;; Decrement counter
        sub rcx, 1                              ;; Decrement pointer index
        sub r10, 1                              ;; Decrement the other pointer index
        mov bl, byte[rax+rcx]                   ;; Load character
        mov byte[rax+r10], bl                   ;; Save the character
        jmp short .fstrinsert_move_loop         ;; While style loop
.fstrinsert_move_loop_done:                     ;; All letters moved
        mov [rdx+FSTR_LENGTH_OFFSET], r12       ;; Save the new length
        xchg rdi, rdx                           ;; Set the fstr as 1st argument for fstrcopy
        call fstrcopy                           ;; Copy the string

        ;; Leaving function
        pop rbx
        pop r12
        pop r11
        mov rsp, rbp
        pop rbp
        ret
;; fstrinsert


;; FSTR_FIND_FIRST
;; Finds first appearance of an fstring in another fstring
;; Indexes will be adjusted if they are of bounds
;;
;; @param
;;      fstring *fstr   - RDI - Source where will be the string searched for
;;      ulong start1    - RSI - Starting index of fstr
;;      ulong end1      - RDX - Endind index of fstr
;;      fstring *fstrsub- RCX - String which will be searched for
;;      ulong start2    - R8  - Starting index of fstrsub
;;      ulong end2      - R9  - Endind index of fstrsub
;; @return ulong index where the first appearence starts (RAX) or length of 1st fstring if not substring was not found
fstr_find_first:
        push rbp
        mov rbp, rsp
        and rsp, -16
        push r11
        push r12
        push r13
        push r14
        push r15
        ;; Stack frame end

        ;; Check bounds on 1st fstring
        cmp rdx, qword[rdi+FSTR_LENGTH_OFFSET]  ;; Check if the end is bigger than the string length
        cmova rdx, qword[rdi+FSTR_LENGTH_OFFSET] ;; If end is bigger than length change end to length (dont care for the ending \0)
        cmp rsi, rdx                            ;; Check if starting index is bigger than the ending
        jbe .fstr_find_first_nabove1            ;; Start is not above end
        xor rsi, rsi                            ;; If starting index is bigger than ending index, change it to 0
.fstr_find_first_nabove1:   

        ;; Check bounds on 2nd fstring
        cmp r9, qword[rcx+FSTR_LENGTH_OFFSET]   ;; Check if the end is bigger or same as the string length
        jb .fstr_find_first_bellow2             ;; Skip change
        mov r9, qword[rcx+FSTR_LENGTH_OFFSET]   ;; Set end1 to length
        ;sub r9, 1                               ;; Subtract 1 (dont want the ending 0)
.fstr_find_first_bellow2:                       ;; Is bellow length
        cmp r8, r9                              ;; Check if starting index is bigger than the ending
        jbe .fstr_find_first_nabove2            ;; Start is not above end
        xor r8, r8                              ;; If starting index is bigger than ending index, change it to 0
.fstr_find_first_nabove2:
        
        ;; Searching
        ;; NOTE: rax a rdx se musi menit za nacitani (je mozne mit tam length a odecitat 16 - melo by podle dokumentace)
        xor r10, r10                            ;; Zero out first index
        xor r11, r11                            ;; Zero out seconf index

        mov r12, rdx                            ;; Get ending index
        sub r12, rsi                            ;; Subtract starting = Length

        mov r13, r9                             ;; Get ending index
        sub r13, r8                             ;; Subtract starting = Length

        mov r14, [rdi+FSTR_TEXT_OFFSET]         ;; Get the text of str
        mov r15, [rcx+FSTR_TEXT_OFFSET]         ;; Get the text of substr
.fstr_find_first_loop:                          ;; Loop for searching
        mov rax, 15                             ;; Set the end of xmm0 as the end of the 1st fstring
        mov rdx, r13                            ;; Set the end of xmm1 as the end of the 2nd fstring 

        movdqu xmm0, [r14+r10]                  ;; Load 16 characters with offset (str)
        movdqu xmm1, [r15+r11]                  ;; Load 16 characters (substr)
        pcmpestri xmm0, xmm1, 0x2c              ;; Find starting match
        ;mov rax, rcx

        ;; DOESNT WORK 
        ;; TODO: finish
        
        ;; CHECK: append

        ;;;;

.fstr_find_first_done:
        ;; Leaving function
        pop r15
        pop r14
        pop r13
        pop r12
        pop r11
        mov rsp, rbp
        pop rbp
        ret
;; end fstr_find_first


;; FSTRSPLIT 
;; Splits string into substring by separator
;;
;; @params
;;      fstring *fstr   - RDI - FSTring
;;      char separator  - RSI - Separator
;; @return char** (Dyn allocated array of string litrals)
;; @code
;;      int subst_am = 0;
;;      int help_susbt_am = 0;
;;      for(int i = 0; i < fstrlen(fstr); i++){      
;;              if(fstr->text[i] == ' '){
;;                      if(help_susbt_am == i){ // Skip trailing separators
;;                              help_susbt_am = i+1;
;;                              continue;
;;                      } 
;;                      help_susbt_am = i+1;
;;                      subst_am++;
;;              }
;;      }
;;      if(help_susbt_am < fstrlen(fstr))
;;              subst_am++;
;;
;;      ret_arr = malloc(subst_am);
;;      int free_i = 0;
;;      int start_i = 0;
;;      for(int i = 0; i < fstrlen(fstr); i++){
;;              if(fstr[i] == separator){
;;                      fstr[i] = '\0';
;;                      if(start_i == i){ // Skip trailing separators
;;                              start_i = i+1;
;;                              continue;
;;                      }
;;                      ret_arr[free_i] = start_i; 
;;                      free_i++;
;;                      start_i = i+1;
;;              }
;;      }
fstrsplit:
        push rbp
        mov rbp, rsp
        and rsp, -16
        push rbx
        ;; Stack frame end

        mov rdx, [rdi+FSTR_LENGTH_OFFSET]       ;; Load the length of the string
        xor rcx, rcx                            ;; Zero out the counter
        mov rbx, [rdi+FSTR_TEXT_OFFSET]         ;; Load the text
       
%assign i 0
%rep 16
        pinsrb xmm1, esi, i                     ;; Load the seperator to each byte
%assign i i+1
%endrep

.fstrsplit_loop1:
        cmp rcx, rdx                            ;; Compare counter and length
        jae .fstrsplit_loop1_end                ;; Exit cycle if counter is bigger or equal to the length of the string
        
        movdqa xmm2, [rbx+rcx]                  ;; Load 16 letters
        pcmpeqb xmm2, xmm1                      ;; Compare each byte if there is separator (mask is in xmm2)

        ;; Problem: kdyz je vic separatoru vedle sebe, nelze lehce spocitat vektorizovane   

        add rcx, 16                             ;; Increase counter (add i better than inc on most processors)        
        jmp short .fstrsplit_loop1              ;; While style loop (compare is at the start)
.fstrsplit_loop1_end:
        
        ;; Leaving function
        pop rbx
        mov rsp, rbp
        pop rbp
        ret
;; fstrsplit


;; CSTRLEN
;; Returns length of a CString
;; 
;; @param
;;      - RDI - CString
;; @return length of a cstring
cstrlen:
        xor rax, rax                            ;; Clear rax
        jmp short .cstrlen_frst
.cstrlen_loop:                                  ;; Loop (until zero end is found)
        add rax, rcx                            ;; Add from previous cycle placed here so the flags are not affected (no need to clear RCX, because of it being rewritten)
        add rax, 1                              ;; Add 1 because of indexing from 0
.cstrlen_frst:
        movdqu xmm0, [rdi+rax]                  ;; Load string with offset to xmm0 (memory is unaligned)
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


;; FMEMUAMOVE
;; Copies memory block with aligned length and unaligned memory to another aligned destination
;;
;; @param
;;      dest    - RDI - Destination
;;      src     - RSI - Source
;;      len     - RDX - Length of the block
;; @return no return (rax will be how many blocks were moved)
fmemuamove:
        xor rax, rax
.fmemuamove_loop:
        movdqu xmm0, [rsi+rax]                  ;; Load the memory (unaligned)
        movdqa [rdi+rax], xmm0                  ;; Save the memory (aligned)
        add rax, 16                             ;; Add to the index     
        cmp rax, rdx                            ;; Compare
        jb .fmemuamove_loop
        ret
;; end fmemuamove

;; FMEMAUMOVE
;; Copies unaligned memory block with aligned length and memory to another unaligned destination
;;
;; @param
;;      dest    - RDI - Destination
;;      src     - RSI - Source
;;      len     - RDX - Length of the block
;; @return no return (rax will be how many blocks were moved)
fmemaumove:
        xor rax, rax
.fmemaumove_loop:
        movdqa xmm0, [rsi+rax]                  ;; Load the memory (aligned)
        movdqu [rdi+rax], xmm0                  ;; Save the memory (unaligned)
        add rax, 16                             ;; Add to the index     
        cmp rax, rdx                            ;; Compare
        jb .fmemaumove_loop
        ret
;; end fmemaumove

;; FMEMAAMOVE
;; Copies aligned memory block with aligned length and memory to another aligned destination
;;
;; @param
;;      dest    - RDI - Destination
;;      src     - RSI - Source
;;      len     - RDX - Length of the block
;; @return no return (rax will be how many blocks were moved)
fmemaamove:
        xor rax, rax
.fmemaamove_loop:
        movdqa xmm0, [rsi+rax]                  ;; Load the memory (aligned)
        movdqa [rdi+rax], xmm0                  ;; Save the memory (aligned)
        add rax, 16                             ;; Add to the index     
        cmp rax, rdx                            ;; Compare
        jb .fmemaamove_loop
        ret
;; end fmemaamove


;; FMEMUUMOVE
;; Copies unaligned memory block with aligned length to another unaligned destination
;;
;; @param
;;      dest    - RDI - Destination
;;      src     - RSI - Source
;;      len     - RDX - Length of the block
;; @return no return (rax will be how many blocks were moved)
fmemuumove:
        xor rax, rax
.fmemuumove_loop:
        movdqu xmm0, [rsi+rax]                  ;; Load the memory (unaligned)
        movdqu [rdi+rax], xmm0                  ;; Save the memory (unaligned)
        add rax, 16                             ;; Add to the index     
        cmp rax, rdx                            ;; Compare
        jb .fmemuumove_loop
        ret
;; end fmemuumove