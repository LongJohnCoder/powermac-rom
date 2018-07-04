;	AUTO-GENERATED SYMBOL LIST
;	IMPORTS:
;	  NKScreenConsole
;	    ScreenConsole_putchar
;	    ScreenConsole_redraw
;	EXPORTS:
;	  getchar (=> NKThud, NKTimers)
;	  print_unknown (=> NKThud)
;	  printb (=> NKInit, NKMPCalls, NKTimers)
;	  printc (=> NKInit, NKPoolAllocator, NKThud)
;	  printd (=> NKInit, NKMPCalls, NKPoolAllocator, NKTimers)
;	  printh (=> NKBuiltinInit, NKMPCalls, NKReplacementInit, NKScheduler, NKThud, NKTimers)
;	  prints (=> NKMPCalls, NKThud)
;	  printw (=> NKAddressSpaces, NKExceptions, NKInit, NKIntHandlers, NKIntMisc, NKMPCalls, NKPaging, NKPoolAllocator, NKReplacementInit, NKScheduler, NKThud, NKTimers)



;	                         prints

;	_log null-terminated string with a few special escapes.
;	Not done figuring this out, with the serial and stuff.

prints	;	OUTSIDE REFERER
	mfsprg	r1, 0
	stmw	r24, -0x0108(r1)
	mflr	r24
	mfcr	r25
	stw		r24, -0x0110(r1)
	stw		r25, -0x010c(r1)
	lwz		r1, -0x0004(r1)
	lwz		r28, PSA.NoIdeaR23(r1)
	lwz		r29,  0x0edc(r1)

	_Lock			PSA.DbugLock, scratch1=r30, scratch2=r31

	cmpwi	cr7, r28,  0x00
	andi.	r29, r29,  0x02
	beq		cr7, prints_skip_serial
	crmove	30, 2
	beq		PrintS_skip_serial
	mfmsr	r31
	bl		serial_io
	bl		serial_flush

prints_skip_serial
	addi	r8, r8, -0x01

prints_next_char
	bl		serial_busywait
	lbzu	r29,  0x0001(r8)
	cmpwi	r29,  0x00
	beq		print_common
	cmpwi	r29, 10
	beq		PrintS_newline
	cmpwi	r29, 13
	beq		PrintS_newline
	cmpwi	r29, '\\'
	beq		PrintS_escape_code
	cmpwi	r29, '^'
	bne		PrintS_normal_char

prints_escape_code
	lbzu	r29,  0x0001(r8)
	cmpwi	r29, 'n'
	beq		PrintS_newline
	cmpwi	r29, 'r'
	beq		PrintS_newline
	cmpwi	r29, 'b'
	bne		PrintS_literal_backslash_or_caret
	li		r29,  0x07
	b		PrintS_normal_char

prints_literal_backslash_or_caret
	lbzu	r29, -0x0001(r8)
	addi	r8, r8,  0x01

prints_normal_char
	mr		r24, r29

;	r1 = kdp
	bl		ScreenConsole_putchar
	beq		cr7, prints_0xe4
	ori		r30, r31,  0x10
	mtmsr	r30
	isync
	stb		r24,  0x0006(r28)
	eieio
	mtmsr	r31
	isync

prints_0xe4
	b		PrintS_next_char

prints_newline
	li		r29,  0x0d

;	r1 = kdp
	bl		ScreenConsole_putchar
	li		r29,  0x0a

;	r1 = kdp
	bl		ScreenConsole_putchar

;	r1 = kdp
	bl		ScreenConsole_redraw
	beq		cr7, prints_0x13c
	ori		r30, r31,  0x10
	mtmsr	r30
	isync
	li		r29,  0x0d
	stb		r29,  0x0006(r28)
	eieio

prints_0x118
	lbz		r29,  0x0002(r28)
	eieio
	andi.	r29, r29,  0x04
	beq		PrintS_0x118
	li		r29,  0x0a
	stb		r29,  0x0006(r28)
	eieio
	mtmsr	r31
	isync

prints_0x13c
	b		PrintS_next_char



print_common	;	OUTSIDE REFERER
	beq		cr7, print_common_0x8c
	mtmsr	r31
	isync
	lwz		r29, PSA.DecClockRateHzCopy(r1)
	srwi	r29, r29,  8
	mfspr	r30, dec
	subf	r29, r29, r30
	ori		r30, r31,  0x10
	mtmsr	r30
	isync

print_common_0x28
	mfspr	r30, dec
	subf.	r30, r29, r30
	ble		print_common_0x50
	li		r30,  0x01
	stb		r30,  0x0002(r28)
	eieio
	lbz		r30,  0x0002(r28)
	eieio
	andi.	r30, r30,  0x01
	beq		print_common_0x28

print_common_0x50
	sync
	mtmsr	r31
	isync
	mfspr	r30, pvr
	rlwinm.	r30, r30,  0,  0, 14
	li		r31,  0x00
	beq		print_common_0x78
	mtspr	dbat3u, r31
	mtspr	dbat3l, r31
	b		print_common_0x80

print_common_0x78
	mtspr	ibat3l, r31
	mtspr	ibat3u, r31

print_common_0x80
	isync
	mtspr	srr0, r26
	mtspr	srr1, r27

print_common_0x8c
	_AssertAndRelease	PSA.DbugLock, scratch=r30



;	                      print_return

;	Restores registers from EWA and returns.

print_return	;	OUTSIDE REFERER
	mfsprg	r1, 0
	lwz		r24, -0x0110(r1)
	lwz		r25, -0x010c(r1)
	mtlr	r24
	mtcr	r25
	lmw		r24, -0x0108(r1)
	lwz		r1, -0x0004(r1)
	blr



;	                         printd

;	_log decimal

printd	;	OUTSIDE REFERER
	mfsprg	r1, 0
	stmw	r24, -0x0108(r1)
	mflr	r24
	mfcr	r25
	stw		r24, -0x0110(r1)
	stw		r25, -0x010c(r1)
	lwz		r1, -0x0004(r1)
	lwz		r28, PSA.NoIdeaR23(r1)
	lwz		r29,  0x0edc(r1)

	_Lock			PSA.DbugLock, scratch1=r30, scratch2=r31

	cmpwi	cr7, r28,  0x00
	andi.	r29, r29,  0x02
	beq		cr7, printd_0x58
	crmove	30, 2
	beq		Printd_0x58
	bl		serial_io
	bl		serial_flush

printd_0x58
	cmpwi	r8,  0x00
	li		r25,  0x2d
	blt		Printd_0x9c

printd_0x64
	mr.		r24, r8
	li		r25,  0x30
	beq		Printd_0x9c
	lis		r24,  0x3b9a
	ori		r24, r24,  0xca00

printd_0x78
	divw.	r25, r8, r24
	bne		Printd_0x8c
	li		r25,  0x0a
	divw	r24, r24, r25
	b		Printd_0x78

printd_0x8c
	divw	r29, r8, r24
	addi	r25, r29,  0x30
	mullw	r29, r29, r24
	subf	r8, r29, r8

printd_0x9c
	bl		serial_busywait
	mr		r29, r25

;	r1 = kdp
	bl		ScreenConsole_putchar
	beq		cr7, printd_0xc8
	ori		r30, r31,  0x10
	mtmsr	r30
	isync
	stb		r25,  0x0006(r28)
	eieio
	mtmsr	r31
	isync

printd_0xc8
	cmpwi	r8,  0x00
	bge		Printd_0xd8
	neg		r8, r8
	b		Printd_0x64

printd_0xd8
	li		r25,  0x0a
	divw.	r24, r24, r25
	bne		Printd_0x8c
	li		r29,  0x20

;	r1 = kdp
	bl		ScreenConsole_putchar
	beq		cr7, printd_0x120
	ori		r30, r31,  0x10
	mtmsr	r30
	isync

printd_0xfc
	lbz		r30,  0x0002(r28)
	eieio
	andi.	r30, r30,  0x04
	beq		Printd_0xfc
	li		r29,  0x20
	stb		r29,  0x0006(r28)
	eieio
	mtmsr	r31
	isync

printd_0x120
	b		print_common



;	                         printw

;	_log word (hex) then a space

printw	;	OUTSIDE REFERER
	mfsprg	r1, 0
	stmw	r24, -0x0108(r1)
	mflr	r24
	mfcr	r25
	stw		r24, -0x0110(r1)
	stw		r25, -0x010c(r1)
	li		r24,  0x08
	crset	cr6_eq
	b		print_digity_common



;	                         printh

;	_log halfword (hex) then a space

printh	;	OUTSIDE REFERER
	mfsprg	r1, 0
	stmw	r24, -0x0108(r1)
	mflr	r24
	mfcr	r25
	stw		r24, -0x0110(r1)
	stw		r25, -0x010c(r1)
	li		r24,  0x04
	rotlwi	r8, r8,  0x10
	crset	cr6_eq
	b		print_digity_common



;	                         printb

;	_log byte (hex) then a space

printb	;	OUTSIDE REFERER
	mfsprg	r1, 0
	stmw	r24, -0x0108(r1)
	mflr	r24
	mfcr	r25
	stw		r24, -0x0110(r1)
	stw		r25, -0x010c(r1)
	li		r24,  0x02
	rotlwi	r8, r8,  0x18
	crset	cr6_eq
	b		print_digity_common



print_unknown	;	OUTSIDE REFERER
	mfsprg	r1, 0
	stmw	r24, -0x0108(r1)
	mflr	r24
	mfcr	r25
	stw		r24, -0x0110(r1)
	stw		r25, -0x010c(r1)
	li		r24,  0x02
	rotlwi	r8, r8,  0x18
	crclr	cr6_eq
	b		print_digity_common



print_digity_common	;	OUTSIDE REFERER
	lwz		r1, -0x0004(r1)
	lwz		r28, PSA.NoIdeaR23(r1)
	lwz		r29,  0x0edc(r1)

	_Lock			PSA.DbugLock, scratch1=r30, scratch2=r31

	cmpwi	cr7, r28,  0x00
	andi.	r29, r29,  0x02
	beq		cr7, print_digity_common_0x40
	crmove	30, 2
	beq		print_digity_common_0x40
	bl		serial_io
	bl		serial_flush

print_digity_common_0x40
	bl		serial_busywait
	li		r25,  0x30
	rlwimi	r25, r8,  4, 28, 31
	rotlwi	r8, r8,  0x04
	cmpwi	r25,  0x39
	ble		print_digity_common_0x5c
	addi	r25, r25,  0x27

print_digity_common_0x5c
	mr		r29, r25

;	r1 = kdp
	bl		ScreenConsole_putchar
	beq		cr7, print_digity_common_0x84
	ori		r30, r31,  0x10
	mtmsr	r30
	isync
	stb		r25,  0x0006(r28)
	eieio
	mtmsr	r31
	isync

print_digity_common_0x84
	addi	r24, r24, -0x01
	mr.		r24, r24
	bne		print_digity_common_0x40
	bne		cr6, print_digity_common_0xd0
	li		r29,  0x20

;	r1 = kdp
	bl		ScreenConsole_putchar
	beq		cr7, print_digity_common_0xd0
	ori		r30, r31,  0x10
	mtmsr	r30
	isync

print_digity_common_0xac
	lbz		r30,  0x0002(r28)
	eieio
	andi.	r30, r30,  0x04
	beq		print_digity_common_0xac
	li		r29,  0x20
	stb		r29,  0x0006(r28)
	eieio
	mtmsr	r31
	isync

print_digity_common_0xd0
	b		print_common



getchar	;	OUTSIDE REFERER
	mfsprg	r1, 0
	stmw	r24, -0x0108(r1)
	mflr	r24
	mfcr	r25
	stw		r24, -0x0110(r1)
	stw		r25, -0x010c(r1)
	
	lwz		r1, EWA.PA_KDP(r1)
	lwz		r28, PSA.NoIdeaR23(r1)
	cmpwi	cr7, r28,  0x00
	li		r8, -0x01
	beq		cr7, print_return

	_Lock			PSA.DbugLock, scratch1=r30, scratch2=r31

	bl		serial_io
	ori		r30, r31,  0x10
	mtmsr	r30
	isync
	lbz		r30,  0x0002(r28)
	eieio
	andi.	r30, r30,  0x01
	beq		print_common
	lbz		r8,  0x0006(r28)
	b		print_common



;	                         printc

;	_log char

printc	;	OUTSIDE REFERER
	mfsprg	r1, 0
	stmw	r24, -0x0108(r1)
	mflr	r24
	mfcr	r25
	stw		r24, -0x0110(r1)
	stw		r25, -0x010c(r1)
	lwz		r1, -0x0004(r1)
	lwz		r28, PSA.NoIdeaR23(r1)
	lwz		r29,  0x0edc(r1)

	_Lock			PSA.DbugLock, scratch1=r30, scratch2=r31

	cmpwi	cr7, r28,  0x00
	andi.	r29, r29,  0x02
	beq		cr7, printc_0x58
	crmove	30, 2
	beq		Printc_0x58
	bl		serial_io
	bl		serial_flush

printc_0x58
	mr		r29, r8

;	r1 = kdp
	bl		ScreenConsole_putchar
	beq		cr7, printc_0x90
	ori		r30, r31,  0x10
	mtmsr	r30
	isync

printc_0x70
	lbz		r30,  0x0002(r28)
	eieio
	andi.	r30, r30,  0x04
	beq		Printc_0x70
	stb		r8,  0x0006(r28)
	eieio
	mtmsr	r31
	isync

printc_0x90
	b		print_common



;	                      serial_flush

;	This and the following func are a bit speculative, but
;	whatever.

;	Whoa. Turns on data but not code paging. Crikey.

serial_flush	;	OUTSIDE REFERER
	ori		r30, r31, MSR_DR
	mtmsr	r30
	isync
	lbz		r29,  0x0002(r28);make sure next write goes to command register
	li		r29,  0x09
	stb		r29,  0x0002(r28);set register pointer to 9 (next write goes to WR9)
	eieio
	li		r29,  0x80;load code for channel A (also disables interrupts)
	stb		r29,  0x0002(r28);reset channel A
	eieio
	lbz		r29,  0x0002(r28);make sure next write goes to command register
	li		r29,  0x04
	stb		r29,  0x0002(r28);set register pointer to 4 (next write goes to WR4)
	eieio
	li		r29,  0x48;X16 clock, 8-bit sync, 1.5 stop bits, parity off
	stb		r29,  0x0002(r28)
	eieio
	lbz		r29,  0x0002(r28);make sure next write goes to command register
	li		r29,  0x03
	stb		r29,  0x0002(r28);set reg pointer to 3 (next write to WR3)
	eieio
	li		r29,  0xc0;recieve 8 bits per character (but recieve off)
	stb		r29,  0x0002(r28)
	eieio
	lbz		r29,  0x0002(r28);make sure next write goes to command register
	li		r29,  0x05
	stb		r29,  0x0002(r28);set reg pointer to 5 (next write to WR5)
	eieio
	li		r29,  0x60;transmit 8 bits per char (but transmit off)
	stb		r29,  0x0002(r28)
	eieio
	lbz		r29,  0x0002(r28);make sure next write goes to command register
	li		r29,  0x09
	stb		r29,  0x0002(r28);set reg pointer to 9 (next write to WR9)
	eieio
	li		r29,  0x00
	stb		r29,  0x0002(r28);stop channel A reset?
	eieio
	lbz		r29,  0x0002(r28);make sure next write goes to command register
	li		r29,  0x0a
	stb		r29,  0x0002(r28);set reg pointer to 10 (next write to WR10)
	eieio
	li		r29,  0x00;8-bit sync, NRZ encoding
	stb		r29,  0x0002(r28)
	eieio
	lbz		r29,  0x0002(r28);make sure next write goes to command register
	li		r29,  0x0b
	stb		r29,  0x0002(r28);set reg pointer to 11 (next write to WR11)
	eieio
	li		r29,  0x50;rx and tx using BR Generator
	stb		r29,  0x0002(r28)
	eieio
	lbz		r29,  0x0002(r28);make sure next write goes to command register
	li		r29,  0x0c
	stb		r29,  0x0002(r28);set reg pointer to 12 (next write to WR12)
	eieio
	li		r29,  0x00;0 time constant low byte
	stb		r29,  0x0002(r28)
	eieio
	lbz		r29,  0x0002(r28);make sure next write goes to command register
	li		r29,  0x0d
	stb		r29,  0x0002(r28);set reg pointer to 13 (next write to WR13)
	eieio
	li		r29,  0x00;0 time constant high byte
	stb		r29,  0x0002(r28)
	eieio
	lbz		r29,  0x0002(r28);make sure next write goes to command register
	li		r29,  0x0e
	stb		r29,  0x0002(r28);set reg pointer to 14 (next write to WR14)
	eieio
	li		r29,  0x01;enable Baud Rate generator
	stb		r29,  0x0002(r28)
	eieio
	lbz		r29,  0x0002(r28);make sure next write goes to command register
	li		r29,  0x03
	stb		r29,  0x0002(r28);set reg pointer to 3 (next write to WR3)
	eieio
	li		r29,  0xc1;enable reciever
	stb		r29,  0x0002(r28)
	eieio
	lbz		r29,  0x0002(r28);make sure next write goes to command register
	li		r29,  0x05
	stb		r29,  0x0002(r28);set reg pointer to 5 (next write to WR5)
	eieio
	li		r29,  0xea;assert DTR and RTS, set 8 bit characters, and enable transmitter
	stb		r29,  0x0002(r28)
	eieio
	mtmsr	r31		;restore previous MSR
	isync
	blr



;	                       serial_io
;appears to set BAT 3 so the scc can be accessed from logical memory space.

serial_io	;	OUTSIDE REFERER
	mfspr	r26, srr0
	mfspr	r27, srr1
	isync
	mfspr	r30, pvr
	rlwinm.	r30, r30,  0,  0, 14
	rlwinm	r29, r28,  0,  0, 14
	beq		serial_io_0x38
	li		r30,  0x03
	or		r30, r30, r29
	li		r31,  0x3a
	or		r31, r31, r29
	mtspr	dbat3l, r31
	mtspr	dbat3u, r30
	b		serial_io_0x50

serial_io_0x38
	li		r30,  0x32
	or		r30, r30, r29
	li		r31,  0x40
	or		r31, r31, r29
	mtspr	ibat3u, r30
	mtspr	ibat3l, r31

serial_io_0x50
	isync
	mfmsr	r31
	blr



;	                    serial_busywait

;	See disclaimer above.

serial_busywait	;	OUTSIDE 
	beqlr	cr7
	ori		r30, r31,  0x10
	mtmsr	r30
	isync

serial_busywait_0x10
	lbz		r30,  0x0002(r28)
	eieio
	andi.	r30, r30,  0x04
	beq		serial_busywait_0x10
	mtmsr	r31
	isync
	blr
