/*** asmMult.s   ***/
    
/* Tell the assembler to allow both 16b and 32b extended Thumb instructions */
.syntax unified

/* Tell the assembler that what follows is in data memory    */
.data
.align
 
/* define and initialize global variables that C can access */

/* create a string */
.global nameStr
.type nameStr,%gnu_unique_object
    
/*** STUDENTS: Change the next line to your name!  **/
nameStr: .asciz "Jesus Hernandez"  

.align   /* realign so that next mem allocations are on word boundaries */
 
/* initialize a global variable that C can access to print the nameStr */
.global nameStrPtr
.type nameStrPtr,%gnu_unique_object
nameStrPtr: .word nameStr   /* Assign the mem loc of nameStr to nameStrPtr */

.global a_Multiplicand,b_Multiplier,a_Sign,b_Sign,a_Abs,b_Abs,init_Product,final_Product
.type a_Multiplicand,%gnu_unique_object
.type b_Multiplier,%gnu_unique_object
.type rng_Error,%gnu_unique_object
.type a_Sign,%gnu_unique_object
.type b_Sign,%gnu_unique_object
.type prod_Is_Neg,%gnu_unique_object
.type a_Abs,%gnu_unique_object
.type b_Abs,%gnu_unique_object
.type init_Product,%gnu_unique_object
.type final_Product,%gnu_unique_object

/* NOTE! These are only initialized ONCE, right before the program runs.
 * If you want these to be 0 every time asmMult gets called, you must set
 * them to 0 at the start of your code!
 */
a_Multiplicand:  .word     0  
b_Multiplier:    .word     0  
rng_Error:       .word     0 
a_Sign:          .word     0  
b_Sign:          .word     0 
prod_Is_Neg:     .word     0 
a_Abs:           .word     0  
b_Abs:           .word     0 
init_Product:    .word     0
final_Product:   .word     0

 /* Tell the assembler that what follows is in instruction memory    */
.text
.align

.global asmUnpack, asmAbs, asmMult, asmFixSign, asmMain
.type asmUnpack,%function
.type asmAbs,%function
.type asmMult,%function
.type asmFixSign,%function
.type asmMain,%function

/* function: asmUnpack
 *    inputs:   r0: contains the packed value. 
 *                  MSB 16bits is signed multiplicand (a)
 *                  LSB 16bits is signed multiplier (b)
 *              r1: address where to store unpacked, 
 *                  sign-extended 32 bit a value
 *              r2: address where to store unpacked, 
 *                  sign-extended 32 bit b value
 *    outputs:  r0: No return value
 *              memory: 
 *                  1) store unpacked A value in location
 *                     specified by r1
 *                  2) store unpacked B value in location
 *                     specified by r2
 */
asmUnpack:   
    
    /*** REMEMBER: You MUST use the ARM calling convention as described in the lectures! ***/

    /*** STUDENTS: Place your asmUnpack code BELOW this line!!! **************/
    
    /* Save the callee-saved registers and the return address so this
     * function follows the ARM calling convention */
    PUSH {r4-r11, LR}

    /* The multiplicand (a) lives in the upper 16 bits of the packed input.
     * An arithmetic shift right by 16 moves it down to the low half and
     * copies its sign bit into the upper 16 bits, giving a sign-extended
     * 32-bit value of a */
    ASR r4, r0, 16
    STR r4, [r1]        /* save sign-extended a at the caller's address */

    /* The multiplier (b) lives in the lower 16 bits. Shift it left so b's
     * sign bit lands in bit 31 (this also discards a), then shift back
     * arithmetically so b is sign-extended to a full 32-bit value */
    LSL r5, r0, 16
    ASR r5, r5, 16
    STR r5, [r2]        /* save sign-extended b at the caller's address */

    /* Restore the caller's registers and return to the caller */
    POP {r4-r11, LR}
    BX LR
    
    /*** STUDENTS: Place your asmUnpack code ABOVE this line!!! **************/


    /***************  END ---- asmUnpack  ************/

 
/* function: asmAbs
 *    inputs:   r0: contains signed value
 *              r1: address where to store absolute value
 *              r2: address where to store sign bit 0 = "+", 1 = "-")
 *    outputs:  r0: Absolute value of r0 input. Same value as stored to location given in r1
 *              memory: store absolute value in location given by r1
 *                      store sign bit in location given by r2
 */    
asmAbs:  

    /*** REMEMBER: You MUST use the ARM calling convention as described in the lectures! ***/

    /*** STUDENTS: Place your asmAbs code BELOW this line!!! **************/
    
    /* Save the callee-saved registers and the return address so this
     * function follows the ARM calling convention */
    PUSH {r4-r11, LR}

    /* Bit 31 of a two's complement number is its sign bit. A logical
     * shift right by 31 isolates it: 0 means positive, 1 means negative.
     * Record it so the final product's sign can be fixed later */
    LSR r4, r0, 31
    STR r4, [r2]

    /* Positive values (and zero) are already their own absolute value,
     * so skip the negation step for them */
    CMP r0, 0
    BGE abs_store

    /* The value is negative: subtract it from 0 to get its magnitude */
    RSB r0, r0, 0

abs_store:
    /* Save the absolute value at the caller's address. It also stays in
     * r0 because the caller expects it as the return value */
    STR r0, [r1]

    /* Restore the caller's registers and return to the caller */
    POP {r4-r11, LR}
    BX LR

    /*** STUDENTS: Place your asmAbs code ABOVE this line!!! **************/


    /***************  END ---- asmAbs  ************/

 
/* function: asmMult
 *    inputs:   r0: contains abs value of multiplicand (a)
 *              r1: contains abs value of multiplier (b)
 *    outputs:  r0: initial product: r0 * r1
 */ 
asmMult:   

    /*** REMEMBER: You MUST use the ARM calling convention as described in the lectures! ***/

    /*** STUDENTS: Place your asmMult code BELOW this line!!! **************/

    /* Save the callee-saved registers and the return address so this
     * function follows the ARM calling convention */
    PUSH {r4-r11, LR}

    /* Shift-and-add multiplication: r4 accumulates the running product,
     * so it must start at 0 before any partial products are added */
    MOV r4, 0

mult_loop:
    /* Once every 1 bit of the multiplier has been processed, the
     * multiplier becomes 0 and the product is complete */
    CMP r1, 0
    BEQ mult_done

    /* Check the multiplier's lowest bit. If it is 0, this partial
     * product is 0, so nothing needs to be added this round */
    TST r1, 1
    BEQ mult_shift

    /* The multiplier's lowest bit is 1, so add the current (shifted)
     * multiplicand into the running product */
    ADD r4, r4, r0

mult_shift:
    /* Move to the next bit position: doubling the multiplicand lines it up
     * with the next multiplier bit, and shifting the multiplier right
     * brings that next bit into bit 0 for the next test */
    LSL r0, r0, 1
    LSR r1, r1, 1
    B mult_loop

mult_done:
    /* The calling convention returns values in r0, so hand back the
     * finished (positive) product there */
    MOV r0, r4

    /* Restore the caller's registers and return to the caller */
    POP {r4-r11, LR}
    BX LR

    /*** STUDENTS: Place your asmMult code ABOVE this line!!! **************/

   
    /***************  END ---- asmMult  ************/


    
/* function: asmFixSign
 *    inputs:   r0: initial product from previous step: 
 *              (abs value of A) * (abs value of B)
 *              r1: sign bit of originally unpacked value
 *                  of A
 *              r2: sign bit of originally unpacked value
 *                  of B
 *    outputs:  r0: final product:
 *                  sign-corrected version of initial product
 */ 
asmFixSign:   
    
    /*** REMEMBER: You MUST use the ARM calling convention as described in the lectures! ***/

    /*** STUDENTS: Place your asmFixSign code BELOW this line!!! **************/

    /* Save the callee-saved registers and the return address so this
     * function follows the ARM calling convention */
    PUSH {r4-r11, LR}

    /* The product is negative only when exactly one input was negative.
     * XOR of the two sign bits is 1 in exactly that case */
    EOR r4, r1, r2
    CMP r4, 0
    BEQ fix_done        /* signs matched, so the positive product is correct */

    /* Signs differed: negate the positive product so it has the correct
     * negative sign (a product of 0 stays 0) */
    RSB r0, r0, 0

fix_done:
    /* The sign-corrected product is already in r0 as the return value.
     * Restore the caller's registers and return to the caller */
    POP {r4-r11, LR}
    BX LR
    
    /*** STUDENTS: Place your asmFixSign code ABOVE this line!!! **************/


    /***************  END ---- asmFixSign  ************/



    
/* function: asmMain
 *    inputs:   r0: contains packed value to be multiplied
 *                  using shift-and-add algorithm
 *           where: MSB 16bits is signed multiplicand (a)
 *                  LSB 16bits is signed multiplier (b)
 *    outputs:  r0: final product: sign-corrected product
 *                  of the two unpacked A and B input values
 *    NOTE TO STUDENTS: 
 *           To implement asmMain, follow the steps outlined
 *           in the comments in the body of the function
 *           definition below.
 */  
asmMain:   
    
    /*** REMEMBER: You MUST use the ARM calling convention as described in the lectures! ***/

    /*** STUDENTS: Place your asmMain code BELOW this line!!! **************/

    /* Save the callee-saved registers and the return address. LR must be
     * saved here because every BL below overwrites it, and asmMain still
     * needs it to return to the C code that called it */
    PUSH {r4-r11, LR}
    
    /* Step 1:
     * call asmUnpack. Have it store the output values in a_Multiplicand
     * and b_Multiplier.
     */
    /* The packed input is already in r0, so only the two destination
     * addresses need to be passed in r1 and r2 */
    LDR r1, =a_Multiplicand
    LDR r2, =b_Multiplier
    BL asmUnpack


     /* Step 2a:
      * call asmAbs for the multiplicand (a). Have it store the absolute value
      * in a_Abs, and the sign in a_Sign.
      */
    /* Pass the unpacked multiplicand as the value to take the absolute
     * value of, plus the addresses for its magnitude and sign bit */
    LDR r0, =a_Multiplicand
    LDR r0, [r0]
    LDR r1, =a_Abs
    LDR r2, =a_Sign
    BL asmAbs


     /* Step 2b:
      * call asmAbs for the multiplier (b). Have it store the absolute value
      * in b_Abs, and the sign in b_Sign.
      */
    /* Same as step 2a, but for the unpacked multiplier */
    LDR r0, =b_Multiplier
    LDR r0, [r0]
    LDR r1, =b_Abs
    LDR r2, =b_Sign
    BL asmAbs


    /* Step 3:
     * call asmMult. Pass a_Abs as the multiplicand, 
     * and b_Abs as the multiplier.
     * asmMult returns the initial (positive) product in r0.
     * In this function (asmMain), store the output value  
     * returned asmMult in r0 to mem location init_Product.
     */
    /* Load both magnitudes into the argument registers so the
     * shift-and-add routine multiplies only positive numbers */
    LDR r0, =a_Abs
    LDR r0, [r0]
    LDR r1, =b_Abs
    LDR r1, [r1]
    BL asmMult

    /* Record the unsigned product (returned in r0) in init_Product */
    LDR r1, =init_Product
    STR r0, [r1]


    /* Step 4:
     * call asmFixSign. Pass in the initial product, and the
     * sign bits for the original a and b inputs. 
     * asmFixSign returns the final product with the correct
     * sign. Store the value returned in r0 to mem location 
     * final_Product.
     */
    /* The initial product is still in r0 from step 3. Load the two sign
     * bits saved in step 2 so asmFixSign knows whether to negate it */
    LDR r1, =a_Sign
    LDR r1, [r1]
    LDR r2, =b_Sign
    LDR r2, [r2]
    BL asmFixSign

    /* Record the sign-corrected product (returned in r0) in final_Product */
    LDR r1, =final_Product
    STR r0, [r1]


     /* Step 5:
      * END! Return to caller. Make sure of the following:
      * 1) Stack has been correctly managed.
      * 2) the final answer is stored in r0, so that the C call 
      *    can access it.
      */
    /* The final product is already in r0 for the C caller. Restore the
     * registers saved on entry (balancing the stack) and return to C */
    POP {r4-r11, LR}
    BX LR

    
    /*** STUDENTS: Place your asmMain code ABOVE this line!!! **************/


    /***************  END ---- asmMain  ************/

 
    
    
.end   /* the assembler will ignore anything after this line. */