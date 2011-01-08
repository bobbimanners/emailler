.ifndef SCREEN_WIDTH
  SCREEN_WIDTH = 22
.endif


 .include "../inc/common.i"
  .include "../inc/commonprint.i"
  .include "../inc/net.i"
  
.import timer_init
.import timer_read


	.segment "STARTUP"    ;this is what gets put at the start of the file on the C64

	.word basicstub		; load address

basicstub:
	.word @nextline
	.word 20
	.byte $9e ;SYS
	.byte <(((init / 1000) .mod 10) + $30)
	.byte <(((init / 100 ) .mod 10) + $30)
	.byte <(((init / 10  ) .mod 10) + $30)
	.byte <(((init       ) .mod 10) + $30)
	.byte 0
@nextline:
	.word 0
  .word 0
  
.code

init:
  lda #14
  jsr print_a ;switch to lower case 

  jsr timer_init
  init_ip_via_dhcp
  jsr print
  jsr print_ip_config
  
  rts
  

print_ax:
  pha
  txa
  jsr print_hex
  pla
  jmp print_hex
 


;-- LICENSE FOR test_tcp.s --
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
