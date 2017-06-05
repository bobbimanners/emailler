.include "atari.inc"

.export get_key
.export check_for_abort_key
.export get_key_if_available
.export get_key_ip65
.export abort_key
.exportzp abort_key_default = 0
.exportzp abort_key_disable = 0

.import ip65_process


.data

abort_key: .byte 0              ; ???
iocb:      .byte 0
kname:     .byte "K:",155


.code

; inputs: none
; outputs: A contains ASCII value of key just pressed
get_key:
  jsr get_key_if_available
  beq get_key
  rts

; inputs: none
; outputs: A contains ASCII value of key just pressed (0 if no key pressed)
get_key_if_available:
  lda CH                        ; GLOBAL VARIABLE FOR KEYBOARD
  cmp #255
  beq @nokey
  ldx iocb                      ; K: already open?
  bne @read
  ldx #$40                      ; IOCB to use for keyboard input
  stx iocb                      ; mark K: as open
  lda #<kname
  sta ICBAL,x                   ; 1-byte low buffer address
  lda #>kname
  sta ICBAH,x                   ; 1-byte high buffer address
  lda #OPEN                     ; open
  sta ICCOM,x                   ; COMMAND CODE
  lda #OPNIN                    ; open for input (all devices)
  sta ICAX1,x                   ; 1-byte first auxiliary information
  jsr CIOV                      ; vector to CIO
@read:
  lda #0
  sta ICBLL,x                   ; 1-byte low buffer length
  sta ICBLH,x                   ; 1-byte high buffer length
  lda #GETCHR                   ; get character(s)
  sta ICCOM,x                   ; COMMAND CODE
  jsr CIOV                      ; vector to CIO
  ldx #255
  stx CH                        ; GLOBAL VARIABLE FOR KEYBOARD
  rts
@nokey:
  lda #0
  rts

; process inbound ip packets while waiting for a keypress
get_key_ip65:
  jsr ip65_process
  jsr get_key_if_available
  beq get_key_ip65
  rts

;check whether the abort key is being pressed
;inputs: none
;outputs: sec if abort key pressed, clear otherwise
check_for_abort_key:
  ; TODO: implement actual check
  clc
  rts



;-- LICENSE FOR atrinputs.s --
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
