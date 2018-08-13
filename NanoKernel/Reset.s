; Code that inits the NanoKernel after Init.s runs,
; or re-inits the NanoKernel after a 68k RESET trap

; These registers will be used throughout:
rCI     set     r26
        lwz     rCI, KDP.ConfigInfoPtr(r1)
rNK     set     r25
        lwz     rNK, KDP.CodeBase(r1)
rPgMap  set     r18
        lwz     rPgMap, KDP.PageMapStartPtr(r1)
rXER    set     r17
        mfxer   rXER

########################################################################

InitVectorTables
    ;   System/Alternate Context tables

    _kaddr  r23, rNK, Crash
    addi    r8, r1, KDP.VecTblSystem
    li      r22, 3 * VecTbl.Size
@vectab_initnext_segment
    subic.  r22, r22, 4
    stwx    r23, r8, r22
    bne     @vectab_initnext_segment

rSys set r9 ; to clarify which table is which
rAlt set r8

    addi    rSys, r1, KDP.VecTblSystem
    mtsprg  3, rSys

    addi    rAlt, r1, KDP.VecTblAlternate

    _kaddr  r23, rNK, Crash
    stw     r23, VecTbl.SystemReset(rSys)
    stw     r23, VecTbl.SystemReset(rAlt)

    _kaddr  r23, rNK, MachineCheckInt
    stw     r23, VecTbl.MachineCheck(rSys)
    stw     r23, VecTbl.MachineCheck(rAlt)

    _kaddr  r23, rNK, DataStorageInt
    stw     r23, VecTbl.DSI(rSys)
    stw     r23, VecTbl.DSI(rAlt)

    _kaddr  r23, rNK, InstStorageInt
    stw     r23, VecTbl.ISI(rSys)
    stw     r23, VecTbl.ISI(rAlt)

    lbz     r22, NKConfigurationInfo.InterruptHandlerKind(rCI)

    cmpwi   r22, 0
    _kaddr  r23, rNK, ExternalInt0
    beq     @chosenIntHandler
    cmpwi   r22, 1
    _kaddr  r23, rNK, ExternalInt1
    beq     @chosenIntHandler
    cmpwi   r22, 2
    _kaddr  r23, rNK, ExternalInt2
    beq     @chosenIntHandler

@chosenIntHandler
    stw     r23, VecTbl.External(rSys)

    _kaddr  r23, rNK, ProgramInt
    stw     r23, VecTbl.External(rAlt)

    _kaddr  r23, rNK, AlignmentInt
    stw     r23, VecTbl.Alignment(rSys)
    stw     r23, VecTbl.Alignment(rAlt)

    _kaddr  r23, rNK, ProgramInt
    stw     r23, VecTbl.Program(rSys)
    stw     r23, VecTbl.Program(rAlt)

    _kaddr  r23, rNK, FPUnavailInt
    stw     r23, VecTbl.FPUnavail(rSys)
    stw     r23, VecTbl.FPUnavail(rAlt)

    _kaddr  r23, rNK, DecrementerIntSys
    stw     r23, VecTbl.Decrementer(rSys)
    _kaddr  r23, rNK, DecrementerIntAlt
    stw     r23, VecTbl.Decrementer(rAlt)

    _kaddr  r23, rNK, SyscallInt
    stw     r23, VecTbl.Syscall(rSys)
    stw     r23, VecTbl.Syscall(rAlt)

    _kaddr  r23, rNK, TraceInt
    stw     r23, VecTbl.Trace(rSys)
    stw     r23, VecTbl.Trace(rAlt)
    stw     r23, VecTbl.OtherTrace(rSys)
    stw     r23, VecTbl.OtherTrace(rAlt)


    ;   MemRetry vector table

    addi    r8, r1, KDP.VecTblMemRetry

    _kaddr  r23, rNK, MRMachineCheckInt
    stw     r23, VecTbl.MachineCheck(r8)

    _kaddr  r23, rNK, MRDataStorageInt
    stw     r23, VecTbl.DSI(r8)

########################################################################

InitKCalls
; Fill the KCallTbl, the ProgramInt interface to the NanoKernel
    _kaddr  r23, rNK, KCallSystemCrash      ; Uninited call -> crash
    addi    r8, r1, KDP.KCallTbl
    li      r22, KCallTbl.Size
@loop
    subic.  r22, r22, 4
    stwx    r23, r8, r22
    bne     @loop

    _kaddr  r23, rNK, KCallReturnFromException
    stw     r23, KCallTbl.ReturnFromException(r8)

    _kaddr  r23, rNK, KCallRunAlternateContext
    stw     r23, KCallTbl.RunAlternateContext(r8)

    _kaddr  r23, rNK, KCallResetSystem
    stw     r23, KCallTbl.ResetSystem(r8)

    _kaddr  r23, rNK, KCallVMDispatch
    stw     r23, KCallTbl.VMDispatch(r8)

    _kaddr  r23, rNK, KCallPrioritizeInterrupts
    stw     r23, KCallTbl.PrioritizeInterrupts(r8)

    _kaddr  r23, rNK, KCallSystemCrash
    stw     r23, KCallTbl.SystemCrash(r8)

########################################################################

; Init the NCB Pointer Cache

    _clrNCBCache scr=r23

########################################################################

; Put HTABORG and PTEGMask in KDP, and zero out the last PTEG
InitHTAB
    mfspr   r8, sdr1

    rlwinm  r22, r8, 16, 7, 15      ; Get settable HTABMASK bits
    rlwinm  r8, r8, 0, 0, 15        ; and HTABORG

    ori     r22, r22, (-64) & 0xffff; "PTEGMask" from upper half of HTABMASK

    stw     r8, KDP.HTABORG(r1)     ; Save
    stw     r22, KDP.PTEGMask(r1)

    li      r23, 0                  ; Zero out the last PTEG in the HTAB
    addi    r22, r22, 64
@next_segment
    subic.  r22, r22, 4
    stwx    r23, r8, r22
    bgt     @next_segment
@skip_zeroing_pteg

    bl      FlushTLB                ; Flush the TLB after touching the HTAB

########################################################################

; From ConfigInfo, copy the PageMap (unstructured buffer of 8-byte
; "PMDTs") and SegMaps (four structured 16-element arrays of pointers
; into the former buffer). Edit slightly as we go.
InitPageMap
    lwz     r9, NKConfigurationInfo.PageMapInitOffset(rCI) ; PageMap
    lwz     r22, NKConfigurationInfo.PageMapInitSize(rCI)
    add     r9, r9, rCI
@next_pmdt
    subi    r22, r22, 4

    lwzx    r21, r9, r22                ; Get RealPgNum/Flags word
    andi.   r23, r21, Pattr_NotPTE | Pattr_PTE_Rel
    cmpwi   r23, Pattr_PTE_Rel       ; Change if physical
    bne     @notrelative                ; address is relative.
    rlwinm  r21, r21, 0, ~Pattr_PTE_Rel
    add     r21, r21, rCI
@notrelative
    stwx    r21, rPgMap, r22            ; ...Save

    subic.  r22, r22, 4                 ; Get Logical/Len word
    lwzx    r20, r9, r22
    stwx    r20, rPgMap, r22            ; ...Save

    bgt     @next_pmdt


InitSegMaps
    lwz     r8, NKConfigurationInfo.PageMapIRPOffset(rCI)
    add     r8, rPgMap, r8              ; The NK chooses the physical
    lwz     r23, PMDT.Word2(r8)  ; addresses of these pages
    rlwimi  r23, r1, 0, 0xFFFFF000
    stw     r23, PMDT.Word2(r8)

    lwz     r8, NKConfigurationInfo.PageMapKDPOffset(rCI)
    add     r8, rPgMap, r8
    lwz     r23, PMDT.Word2(r8)
    rlwimi  r23, r1, 0, 0xFFFFF000
    stw     r23, PMDT.Word2(r8)

    lwz     r19, KDP.EDPPtr(r1)
    lwz     r8, NKConfigurationInfo.PageMapEDPOffset(rCI)
    add     r8, rPgMap, r8
    lwz     r23, PMDT.Word2(r8)
    rlwimi  r23, r19, 0, 0xFFFFF000
    stw     r23, PMDT.Word2(r8)


    addi    r9, rCI, NKConfigurationInfo.SegMaps-4 ; SegMaps
    addi    r8, r1, KDP.SegMaps-4
    li      r22, 4*16*8                 ; 4 maps * 16 segs * (ptr+flags=8b)
@next_seg
    lwzu    r23, 4(r9)
    subic.  r22, r22, 8
    add     r23, rPgMap, r23
    stwu    r23, 4(r8)

    lwzu    r23, 4(r9)
    stwu    r23, 4(r8)

    bgt     @next_seg


CopyBATRangeInit
    addi    r9, rCI, NKConfigurationInfo.BATRangeInit - 4
    addi    r8, r1, KDP.BATs - 4
    li      r22, 4*4*8 ; 4 maps * 4 BATs * (UBAT+LBAT=8b)

@bat_copynext_segment
    lwzu    r20, 4(r9)      ; grab UBAT
    lwzu    r21, 4(r9)      ; grab LBAT
    stwu    r20, 4(r8)      ; store UBAT

    rlwinm  r23, r21, 0, ~Pattr_PTE_Rel
    cmpw    r21, r23
    beq     @bitnotset
    add     r21, r23, rCI   ; then LBAT[BRPN] is relative to ConfigInfo struct
@bitnotset

    subic.  r22, r22, 8
    stwu    r21, 4(r8)      ; store LBAT
    bgt     @bat_copynext_segment

########################################################################

; Save some ptrs that allow us to enable Overlay mode, etc

    addi    r23, r1, KDP.SegMap32SupInit
    stw     r23, KDP.SupervisorMap.SegMapPtr(r1)
    lwz     r23, NKConfigurationInfo.BatMap32SupInit(rCI)
    stw     r23, KDP.SupervisorMap.BatMap(r1)

    addi    r23, r1, KDP.SegMap32UsrInit
    stw     r23, KDP.UserMap.SegMapPtr(r1)
    lwz     r23, NKConfigurationInfo.BatMap32UsrInit(rCI)
    stw     r23, KDP.UserMap.BatMap(r1)

    addi    r23, r1, KDP.SegMap32CPUInit
    stw     r23, KDP.CpuMap.SegMapPtr(r1)
    lwz     r23, NKConfigurationInfo.BatMap32CPUInit(rCI)
    stw     r23, KDP.CpuMap.BatMap(r1)

    addi    r23, r1, KDP.SegMap32OvlInit
    stw     r23, KDP.OverlayMap.SegMapPtr(r1)
    lwz     r23, NKConfigurationInfo.BatMap32OvlInit(rCI)
    stw     r23, KDP.OverlayMap.BatMap(r1)

########################################################################

; Create a 68k PTE for every page in the initial logical area.
; (The logical area will equal physical RAM size, so make a PTE for
; every physical page inside a RAM bank but outside kernel memory.
; Later on, the VM Manager can replace this table with its own.)

Create68kPTEs
    lwz     r21, KDP.KernelMemoryBase(r1)   ; this range is forbidden
    lwz     r20, KDP.KernelMemoryEnd(r1)
    subi    r29, r21, 4                     ; ptr to last added entry

    addi    r19, r1, KDP.SysInfo.Bank0Start - 8

    lwz     r23, KDP.PageAttributeInit(r1)  ; "default WIMG/PP settings for PTE creation"

    li      r30, M68pdResident
    _mvbit  r30, bM68pdCacheinhib, r23, bLpteInhibcache
    _mvbit  r30, bM68pdCacheNotIO, r23, bLpteWritethru
    xori    r30, r30, M68pdCacheNotIO
    _mvbit  r30, bM68pdModified, r23, bLpteChange
    _mvbit  r30, bM68pdUsed, r23, bLpteReference

    li      r23, NKSystemInfo.MaxBanks
@next_bank
    subic.  r23, r23, 1
    blt     @done
    lwzu    r31, 8(r19)                     ; bank start address
    lwz     r22, 4(r19)                     ; bank size
    or      r31, r31, r30                   ; OR the RPN with the flags in r30
@next_page
    cmplwi  r22, 4096
    cmplw   cr6, r31, r21
    cmplw   cr7, r31, r20
    subi    r22, r22, 4096
    blt     @next_bank

    blt     cr6, @notkernelmem              ; check that page is not kernel memory
    blt     cr7, @kernelmem
@notkernelmem
    stwu    r31, 4(r29)                     ; write the PageList entry
@kernelmem

    addi    r31, r31, 4096
    b       @next_page
@done

; Now r21/r29 point to first/last element of PageList

; Overwrite the dummy PMDT in every logical-area segment (0-3)
; to point into the logical-area 68k PTE array
; (Overwrite first PMDT in each segment)

PutLogicalAreaInPageMap
    subf    r22, r21, r29
    li      r30, 0
    addi    r19, r22, 4
    slwi    r19, r19, 10
    ori     r30, r30, 0xffff
    stw     r19, KDP.SysInfo.UsableMemorySize(r1)
    srwi    r22, r22, 2
    stw     r19, KDP.SysInfo.LogicalMemorySize(r1)

    ;   convert r19 to pages, and save in some places
    srwi    r19, r19, 12
    stw     r19, KDP.VMLogicalPages(r1)
    stw     r19, KDP.VMPhysicalPages(r1)

    addi    r29, r1, KDP.PhysicalPageArray-4       ; where to save per-segment PLE ptr
    addi    r19, r1, KDP.SegMap32SupInit-8         ; which part of PageMap to update 

    stw     r21, KDP.VMPageArray(r1)

@next_segment
    cmplwi  r22, 0xffff             ; continue (bgt) while there are still pages left
    
    ;   Rewrite the first PMDT in this segment
    lwzu    r8, 8(r19)              ; find PMDT using SegMap32SupInit
    rotlwi  r31, r21, 10
    ori     r31, r31, PMDT_Paged
    stw     r30, 0(r8)              ; use entire segment (PageIdx = 0, PageCount = 0xFFFF)
    stw     r31, 4(r8)              ; RPN = PLE ptr | PMDT_NotPTE_PageList

    stwu    r21, 4(r29)             ; point PhysicalPageArray to segments's first PLE

    addis   r21, r21, 4             ; increment pointer into PLE (64k pages/segment * 4b/PLE)
    subis   r22, r22, 1             ; decrement number of pending pages (64k pages/segment)

    bgt     @next_segment

    sth     r22, PMDT.PageCount(r8) ; shrink PMDT in last segment to fit

########################################################################

; Enable the ROM Overlay
    addi    r29, r1, KDP.OverlayMap
    bl      SetMap

########################################################################

; Make sure some important areas of RAM are in the HTAB
    lwz     r27, KDP.ConfigInfoPtr(r1)
    lwz     r27, NKConfigurationInfo.LA_InterruptCtl(r27)
    bl      PutPTE

    lwz     r27, KDP.ConfigInfoPtr(r1)
    lwz     r27, NKConfigurationInfo.LA_KernelData(r27)
    bl      PutPTE

    lwz     r27, KDP.ConfigInfoPtr(r1)
    lwz     r27, NKConfigurationInfo.LA_EmulatorData(r27)
    bl      PutPTE

########################################################################

; Restore the fixedpt exception register (clobbered by addic)

    mtxer   rXER
