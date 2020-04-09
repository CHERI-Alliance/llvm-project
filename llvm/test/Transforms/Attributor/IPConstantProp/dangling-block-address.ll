; NOTE: Assertions have been autogenerated by utils/update_test_checks.py UTC_ARGS: --function-signature --scrub-attributes
; RUN: opt -attributor -attributor-manifest-internal -attributor-disable=false -attributor-max-iterations-verify -attributor-annotate-decl-cs -attributor-max-iterations=1 -S < %s | FileCheck %s --check-prefixes=CHECK,NOT_CGSCC_NPM,NOT_CGSCC_OPM,NOT_TUNIT_NPM,IS__TUNIT____,IS________OPM,IS__TUNIT_OPM
; RUN: opt -aa-pipeline=basic-aa -passes=attributor -attributor-manifest-internal -attributor-disable=false -attributor-max-iterations-verify -attributor-annotate-decl-cs -attributor-max-iterations=1 -S < %s | FileCheck %s --check-prefixes=CHECK,NOT_CGSCC_OPM,NOT_CGSCC_NPM,NOT_TUNIT_OPM,IS__TUNIT____,IS________NPM,IS__TUNIT_NPM
; RUN: opt -attributor-cgscc -attributor-manifest-internal -attributor-disable=false -attributor-annotate-decl-cs -S < %s | FileCheck %s --check-prefixes=CHECK,NOT_TUNIT_NPM,NOT_TUNIT_OPM,NOT_CGSCC_NPM,IS__CGSCC____,IS________OPM,IS__CGSCC_OPM
; RUN: opt -aa-pipeline=basic-aa -passes=attributor-cgscc -attributor-manifest-internal -attributor-disable=false -attributor-annotate-decl-cs -S < %s | FileCheck %s --check-prefixes=CHECK,NOT_TUNIT_NPM,NOT_TUNIT_OPM,NOT_CGSCC_OPM,IS__CGSCC____,IS________NPM,IS__CGSCC_NPM
; PR5569

; IPSCCP should prove that the blocks are dead and delete them, and
; properly handle the dangling blockaddress constants.

; NOT_CGSCC_OPM: @bar.l = internal constant [2 x i8*] [i8* inttoptr (i32 1 to i8*), i8* inttoptr (i32 1 to i8*)]
; IS__CGSCC_OPM: @bar.l = internal constant [2 x i8*] [i8* blockaddress(@bar, %lab0), i8* blockaddress(@bar, %end)]

@code = global [5 x i32] [i32 0, i32 0, i32 0, i32 0, i32 1], align 4 ; <[5 x i32]*> [#uses=0]
@bar.l = internal constant [2 x i8*] [i8* blockaddress(@bar, %lab0), i8* blockaddress(@bar, %end)] ; <[2 x i8*]*> [#uses=1]

define internal void @foo(i32 %x) nounwind readnone {
; IS__CGSCC____-LABEL: define {{[^@]+}}@foo
; IS__CGSCC____-SAME: (i32 [[X:%.*]])
; IS__CGSCC____-NEXT:  entry:
; IS__CGSCC____-NEXT:    [[B:%.*]] = alloca i32, align 4
; IS__CGSCC____-NEXT:    store volatile i32 -1, i32* [[B]]
; IS__CGSCC____-NEXT:    ret void
;
entry:
  %b = alloca i32, align 4                        ; <i32*> [#uses=1]
  store volatile i32 -1, i32* %b
  ret void
}

define internal void @bar(i32* nocapture %pc) nounwind readonly {
; IS__CGSCC_OPM-LABEL: define {{[^@]+}}@bar
; IS__CGSCC_OPM-SAME: (i32* nocapture [[PC:%.*]])
; IS__CGSCC_OPM-NEXT:  entry:
; IS__CGSCC_OPM-NEXT:    br label [[INDIRECTGOTO:%.*]]
; IS__CGSCC_OPM:       lab0:
; IS__CGSCC_OPM-NEXT:    [[INDVAR_NEXT:%.*]] = add i32 [[INDVAR:%.*]], 1
; IS__CGSCC_OPM-NEXT:    br label [[INDIRECTGOTO]]
; IS__CGSCC_OPM:       end:
; IS__CGSCC_OPM-NEXT:    ret void
; IS__CGSCC_OPM:       indirectgoto:
; IS__CGSCC_OPM-NEXT:    [[INDVAR]] = phi i32 [ [[INDVAR_NEXT]], [[LAB0:%.*]] ], [ 0, [[ENTRY:%.*]] ]
; IS__CGSCC_OPM-NEXT:    [[PC_ADDR_0:%.*]] = getelementptr i32, i32* [[PC]], i32 [[INDVAR]]
; IS__CGSCC_OPM-NEXT:    [[TMP1_PN:%.*]] = load i32, i32* [[PC_ADDR_0]]
; IS__CGSCC_OPM-NEXT:    [[INDIRECT_GOTO_DEST_IN:%.*]] = getelementptr inbounds [2 x i8*], [2 x i8*]* @bar.l, i32 0, i32 [[TMP1_PN]]
; IS__CGSCC_OPM-NEXT:    [[INDIRECT_GOTO_DEST:%.*]] = load i8*, i8** [[INDIRECT_GOTO_DEST_IN]]
; IS__CGSCC_OPM-NEXT:    indirectbr i8* [[INDIRECT_GOTO_DEST]], [label [[LAB0]], label %end]
;
entry:
  br label %indirectgoto

lab0:                                             ; preds = %indirectgoto
  %indvar.next = add i32 %indvar, 1               ; <i32> [#uses=1]
  br label %indirectgoto

end:                                              ; preds = %indirectgoto
  ret void

indirectgoto:                                     ; preds = %lab0, %entry
  %indvar = phi i32 [ %indvar.next, %lab0 ], [ 0, %entry ] ; <i32> [#uses=2]
  %pc.addr.0 = getelementptr i32, i32* %pc, i32 %indvar ; <i32*> [#uses=1]
  %tmp1.pn = load i32, i32* %pc.addr.0                 ; <i32> [#uses=1]
  %indirect.goto.dest.in = getelementptr inbounds [2 x i8*], [2 x i8*]* @bar.l, i32 0, i32 %tmp1.pn ; <i8**> [#uses=1]
  %indirect.goto.dest = load i8*, i8** %indirect.goto.dest.in ; <i8*> [#uses=1]
  indirectbr i8* %indirect.goto.dest, [label %lab0, label %end]
}

define i32 @main() nounwind readnone {
; CHECK-LABEL: define {{[^@]+}}@main()
; CHECK-NEXT:  entry:
; CHECK-NEXT:    ret i32 0
;
entry:
  ret i32 0
}
