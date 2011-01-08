; timer routines
;
; the timer should be a 16-bit counter that's incremented by about
; 1000 units per second. it doesn't have to be particularly accurate.
; this VIC20 implementation requires the routine timer_vbl_handler be called 60 times per second

	.include "../inc/common.i"


	.export timer_init
	.export timer_read
  
  IRQ_VECTOR=$314

  .bss
  current_time_value: .res 2
  
  .data 
  jmp_old_handler:
    .byte $4c ;JMP    
old_handler:    
    .word $00
  
	.code

;reset timer to 0
;inputs: none
;outputs: none
timer_init:
  lda old_handler
  bne @handler_installed
  ldax  IRQ_VECTOR
  stax old_handler  
  ldax #timer_vbl_handler
  stax  IRQ_VECTOR
@handler_installed:  
  ldax  #0
  stax current_time_value
	rts

;read the current timer value 
; inputs: none
; outputs: AX = current timer value (roughly equal to number of milliseconds since the last call to 'timer_init')
timer_read:
  ldax  current_time_value
  rts

; tick over the current timer value - should be called 60 times per second
; inputs: none
; outputs: none (all registers preserved, by carry flag can be modified)
timer_vbl_handler:
  pha
  lda #$11  ; 60 HZ =~ 17 ms per 'tick' 
: 
  adc current_time_value
  sta current_time_value
  bcc :+
  inc current_time_value+1
:
  pla
  jmp jmp_old_handler


;-- LICENSE FOR c64timer_nb65.s --
; The contents of this file are subject to the Mozilla Public License
; Version 1.1 (the "License"); you may not use this file except in
; compliance with the License. You may obtain a copy of the License at
; http://www.mozilla.org/MPL/
; 
; Software distributed under the License is distributed on an "AS IS"
; basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
; License for the specific language governing rights and limitations
; under the License.
; 
; The Original Code is ip65.
; 
; The Initial Developer of the Original Code is Jonno Downes,
; jonno@jamtronix.com.
; Portions created by the Initial Developer are Copyright (C) 2009
; Jonno Downes. All Rights Reserved.  
; -- LICENSE END --