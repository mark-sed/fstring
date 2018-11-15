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
global fstrset                                  ;; Sets text of a fstring
global fstrappend                               ;; Appends string to the end of fstring
global fstr_to_upper                            ;; Converts all letters to uppercase
global fstr_to_lower                            ;; Converts all letters to lowercase
global fstrcapitalize                           ;; Converts first letter (at index) to uppercase
global fstr_find_first                          ;; Finds first appearance of an fstring in an fstring

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

.fstrappend_fits:                               ;; String fits now
        
        mov rax, qword[r14+FSTR_LENGTH_OFFSET]  ;; Get fstr length
        mov rdi, qword[r14+FSTR_TEXT_OFFSET]    ;; Get text pointer
        add rdi, rax                            ;; Skip to the end and set as argument
        mov rsi, r13                            ;; Set str ad second argument
        mov rdx, r12                            ;; Set length to length of str
        call fmemuumove                         ;; Both addresses are unaligned, append

        mov qword[r14+FSTR_LENGTH_OFFSET], r15  ;; Set length to a new length

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
        ;; Stack frame end

        ;; Check bounds on 1st fstring
        cmp rdx, qword[rdi+FSTR_LENGTH_OFFSET]  ;; Check if the end is bigger than the string length
        cmova rdx, qword[rdi+FSTR_LENGTH_OFFSET] ;; If end is bigger than length change end to length (dont care for the ending \0)
        cmp rsi, rdx                            ;; Check if starting index is bigger than the ending
        jbe .fstr_find_first_nabove1            ;; Start is not above end
        xor rsi, rsi                            ;; If starting index is bigger than ending index, change it to 0
.fstr_find_first_nabove1:   

        ;; Check bounds on 2nd fstring
        cmp r8, qword[rcx+FSTR_LENGTH_OFFSET]   ;; Check if the end is bigger or same as the string length
        jb .fstr_find_first_bellow2             ;; Skip change
        mov r8, qword[rcx+FSTR_LENGTH_OFFSET]   ;; Set end1 to length
        sub r8, 1                               ;; Subtract 1 (dont want the ending 0)
.fstr_find_first_bellow2:                       ;; Is bellow length
        cmp r9, r8                              ;; Check if starting index is bigger than the ending
        jbe .fstr_find_first_nabove2            ;; Start is not above end
        xor r9, r9                              ;; If starting index is bigger than ending index, change it to 0
.fstr_find_first_nabove2:
        
        ;; Searching
        

        ;; NOTE: rax a rdx se musi menit za nacitani (je mozne mit tam length a odecitat 16 - melo by podle dokumentace)

.fstr_find_first_loop:                          ;; Loop for searching
        ;mov rax, rdx                            ;; Set the end of xmm0 as the end of the 1st fstring
        ;mov rdx, r8                             ;; Set the end of xmm1 as the end of the 2nd fstring 

.fstr_find_first_done:
        ;; Leaving function
        mov rsp, rbp
        pop rbp
        ret
;; end fstr_find_first


;; CSTRLEN                            ;; TODO: Are string literals aligned in length as well?
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