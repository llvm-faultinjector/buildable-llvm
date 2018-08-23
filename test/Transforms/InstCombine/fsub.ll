; NOTE: Assertions have been autogenerated by utils/update_test_checks.py
; RUN: opt < %s -instcombine -S | FileCheck %s

; PR4374

define float @test1(float %x, float %y) {
; CHECK-LABEL: @test1(
; CHECK-NEXT:    [[T1:%.*]] = fsub float [[X:%.*]], [[Y:%.*]]
; CHECK-NEXT:    [[T2:%.*]] = fsub float -0.000000e+00, [[T1]]
; CHECK-NEXT:    ret float [[T2]]
;
  %t1 = fsub float %x, %y
  %t2 = fsub float -0.0, %t1
  ret float %t2
}

; Can't do anything with the test above because -0.0 - 0.0 = -0.0, but if we have nsz:
; -(X - Y) --> Y - X

define float @neg_sub_nsz(float %x, float %y) {
; CHECK-LABEL: @neg_sub_nsz(
; CHECK-NEXT:    [[TMP1:%.*]] = fsub nsz float [[Y:%.*]], [[X:%.*]]
; CHECK-NEXT:    ret float [[TMP1]]
;
  %t1 = fsub float %x, %y
  %t2 = fsub nsz float -0.0, %t1
  ret float %t2
}

; If the subtract has another use, we don't do the transform (even though it
; doesn't increase the IR instruction count) because we assume that fneg is
; easier to analyze and generally cheaper than generic fsub.

declare void @use(float)
declare void @use2(float, double)

define float @neg_sub_nsz_extra_use(float %x, float %y) {
; CHECK-LABEL: @neg_sub_nsz_extra_use(
; CHECK-NEXT:    [[T1:%.*]] = fsub float [[X:%.*]], [[Y:%.*]]
; CHECK-NEXT:    [[T2:%.*]] = fsub nsz float -0.000000e+00, [[T1]]
; CHECK-NEXT:    call void @use(float [[T1]])
; CHECK-NEXT:    ret float [[T2]]
;
  %t1 = fsub float %x, %y
  %t2 = fsub nsz float -0.0, %t1
  call void @use(float %t1)
  ret float %t2
}

; With nsz: Z - (X - Y) --> Z + (Y - X)

define float @sub_sub_nsz(float %x, float %y, float %z) {
; CHECK-LABEL: @sub_sub_nsz(
; CHECK-NEXT:    [[TMP1:%.*]] = fsub nsz float [[Y:%.*]], [[X:%.*]]
; CHECK-NEXT:    [[T2:%.*]] = fadd nsz float [[TMP1]], [[Z:%.*]]
; CHECK-NEXT:    ret float [[T2]]
;
  %t1 = fsub float %x, %y
  %t2 = fsub nsz float %z, %t1
  ret float %t2
}

; With nsz and reassoc: Y - ((X * 5) + Y) --> X * -5

define float @sub_add_neg_x(float %x, float %y) {
; CHECK-LABEL: @sub_add_neg_x(
; CHECK-NEXT:    [[TMP1:%.*]] = fmul reassoc nsz float [[X:%.*]], -5.000000e+00
; CHECK-NEXT:    ret float [[TMP1]]
;
  %mul = fmul float %x, 5.000000e+00
  %add = fadd float %mul, %y
  %r = fsub nsz reassoc float %y, %add
  ret float %r
}

; Same as above: if 'Z' is not -0.0, swap fsub operands and convert to fadd.

define float @sub_sub_known_not_negzero(float %x, float %y) {
; CHECK-LABEL: @sub_sub_known_not_negzero(
; CHECK-NEXT:    [[TMP1:%.*]] = fsub float [[Y:%.*]], [[X:%.*]]
; CHECK-NEXT:    [[T2:%.*]] = fadd float [[TMP1]], 4.200000e+01
; CHECK-NEXT:    ret float [[T2]]
;
  %t1 = fsub float %x, %y
  %t2 = fsub float 42.0, %t1
  ret float %t2
}

; <rdar://problem/7530098>

define double @test2(double %x, double %y) {
; CHECK-LABEL: @test2(
; CHECK-NEXT:    [[T1:%.*]] = fadd double [[X:%.*]], [[Y:%.*]]
; CHECK-NEXT:    [[T2:%.*]] = fsub double [[X]], [[T1]]
; CHECK-NEXT:    ret double [[T2]]
;
  %t1 = fadd double %x, %y
  %t2 = fsub double %x, %t1
  ret double %t2
}

; X - C --> X + (-C)

define float @constant_op1(float %x, float %y) {
; CHECK-LABEL: @constant_op1(
; CHECK-NEXT:    [[R:%.*]] = fadd float [[X:%.*]], -4.200000e+01
; CHECK-NEXT:    ret float [[R]]
;
  %r = fsub float %x, 42.0
  ret float %r
}

define <2 x float> @constant_op1_vec(<2 x float> %x, <2 x float> %y) {
; CHECK-LABEL: @constant_op1_vec(
; CHECK-NEXT:    [[R:%.*]] = fadd <2 x float> [[X:%.*]], <float -4.200000e+01, float 4.200000e+01>
; CHECK-NEXT:    ret <2 x float> [[R]]
;
  %r = fsub <2 x float> %x, <float 42.0, float -42.0>
  ret <2 x float> %r
}

define <2 x float> @constant_op1_vec_undef(<2 x float> %x, <2 x float> %y) {
; CHECK-LABEL: @constant_op1_vec_undef(
; CHECK-NEXT:    [[R:%.*]] = fadd <2 x float> [[X:%.*]], <float 0x7FF8000000000000, float 4.200000e+01>
; CHECK-NEXT:    ret <2 x float> [[R]]
;
  %r = fsub <2 x float> %x, <float undef, float -42.0>
  ret <2 x float> %r
}

; X - (-Y) --> X + Y

define float @neg_op1(float %x, float %y) {
; CHECK-LABEL: @neg_op1(
; CHECK-NEXT:    [[R:%.*]] = fadd float [[X:%.*]], [[Y:%.*]]
; CHECK-NEXT:    ret float [[R]]
;
  %negy = fsub float -0.0, %y
  %r = fsub float %x, %negy
  ret float %r
}

define <2 x float> @neg_op1_vec(<2 x float> %x, <2 x float> %y) {
; CHECK-LABEL: @neg_op1_vec(
; CHECK-NEXT:    [[R:%.*]] = fadd <2 x float> [[X:%.*]], [[Y:%.*]]
; CHECK-NEXT:    ret <2 x float> [[R]]
;
  %negy = fsub <2 x float> <float -0.0, float -0.0>, %y
  %r = fsub <2 x float> %x, %negy
  ret <2 x float> %r
}

define <2 x float> @neg_op1_vec_undef(<2 x float> %x, <2 x float> %y) {
; CHECK-LABEL: @neg_op1_vec_undef(
; CHECK-NEXT:    [[R:%.*]] = fadd <2 x float> [[X:%.*]], [[Y:%.*]]
; CHECK-NEXT:    ret <2 x float> [[R]]
;
  %negy = fsub <2 x float> <float -0.0, float undef>, %y
  %r = fsub <2 x float> %x, %negy
  ret <2 x float> %r
}

; Similar to above - but look through fpext/fptrunc casts to find the fneg.

define double @neg_ext_op1(float %a, double %b) {
; CHECK-LABEL: @neg_ext_op1(
; CHECK-NEXT:    [[TMP1:%.*]] = fpext float [[A:%.*]] to double
; CHECK-NEXT:    [[T3:%.*]] = fadd double [[TMP1]], [[B:%.*]]
; CHECK-NEXT:    ret double [[T3]]
;
  %t1 = fsub float -0.0, %a
  %t2 = fpext float %t1 to double
  %t3 = fsub double %b, %t2
  ret double %t3
}

; Verify that vectors work too.

define <2 x float> @neg_trunc_op1(<2 x double> %a, <2 x float> %b) {
; CHECK-LABEL: @neg_trunc_op1(
; CHECK-NEXT:    [[TMP1:%.*]] = fptrunc <2 x double> [[A:%.*]] to <2 x float>
; CHECK-NEXT:    [[T3:%.*]] = fadd <2 x float> [[TMP1]], [[B:%.*]]
; CHECK-NEXT:    ret <2 x float> [[T3]]
;
  %t1 = fsub <2 x double> <double -0.0, double -0.0>, %a
  %t2 = fptrunc <2 x double> %t1 to <2 x float>
  %t3 = fsub <2 x float> %b, %t2
  ret <2 x float> %t3
}

; No FMF needed, but they should propagate to the fadd.

define double @neg_ext_op1_fast(float %a, double %b) {
; CHECK-LABEL: @neg_ext_op1_fast(
; CHECK-NEXT:    [[TMP1:%.*]] = fpext float [[A:%.*]] to double
; CHECK-NEXT:    [[T3:%.*]] = fadd fast double [[TMP1]], [[B:%.*]]
; CHECK-NEXT:    ret double [[T3]]
;
  %t1 = fsub float -0.0, %a
  %t2 = fpext float %t1 to double
  %t3 = fsub fast double %b, %t2
  ret double %t3
}

; Extra use should prevent the transform.

define float @neg_ext_op1_extra_use(half %a, float %b) {
; CHECK-LABEL: @neg_ext_op1_extra_use(
; CHECK-NEXT:    [[T1:%.*]] = fsub half 0xH8000, [[A:%.*]]
; CHECK-NEXT:    [[T2:%.*]] = fpext half [[T1]] to float
; CHECK-NEXT:    [[T3:%.*]] = fsub float [[B:%.*]], [[T2]]
; CHECK-NEXT:    call void @use(float [[T2]])
; CHECK-NEXT:    ret float [[T3]]
;
  %t1 = fsub half -0.0, %a
  %t2 = fpext half %t1 to float
  %t3 = fsub float %b, %t2
  call void @use(float %t2)
  ret float %t3
}

; One-use fptrunc is always hoisted above fneg, so the corresponding
; multi-use bug for fptrunc isn't visible with a fold starting from
; the last fsub.

define float @neg_trunc_op1_extra_use(double %a, float %b) {
; CHECK-LABEL: @neg_trunc_op1_extra_use(
; CHECK-NEXT:    [[TMP1:%.*]] = fptrunc double [[A:%.*]] to float
; CHECK-NEXT:    [[T2:%.*]] = fsub float -0.000000e+00, [[TMP1]]
; CHECK-NEXT:    [[T3:%.*]] = fadd float [[TMP1]], [[B:%.*]]
; CHECK-NEXT:    call void @use(float [[T2]])
; CHECK-NEXT:    ret float [[T3]]
;
  %t1 = fsub double -0.0, %a
  %t2 = fptrunc double %t1 to float
  %t3 = fsub float %b, %t2
  call void @use(float %t2)
  ret float %t3
}

; Extra uses should prevent the transform.

define float @neg_trunc_op1_extra_uses(double %a, float %b) {
; CHECK-LABEL: @neg_trunc_op1_extra_uses(
; CHECK-NEXT:    [[T1:%.*]] = fsub double -0.000000e+00, [[A:%.*]]
; CHECK-NEXT:    [[T2:%.*]] = fptrunc double [[T1]] to float
; CHECK-NEXT:    [[T3:%.*]] = fsub float [[B:%.*]], [[T2]]
; CHECK-NEXT:    call void @use2(float [[T2]], double [[T1]])
; CHECK-NEXT:    ret float [[T3]]
;
  %t1 = fsub double -0.0, %a
  %t2 = fptrunc double %t1 to float
  %t3 = fsub float %b, %t2
  call void @use2(float %t2, double %t1)
  ret float %t3
}

; Don't negate a constant expression to form fadd and induce infinite looping:
; https://bugs.llvm.org/show_bug.cgi?id=37605

@b = external global i16, align 1

define float @PR37605(float %conv) {
; CHECK-LABEL: @PR37605(
; CHECK-NEXT:    [[SUB:%.*]] = fsub float [[CONV:%.*]], bitcast (i32 ptrtoint (i16* @b to i32) to float)
; CHECK-NEXT:    ret float [[SUB]]
;
  %sub = fsub float %conv, bitcast (i32 ptrtoint (i16* @b to i32) to float)
  ret float %sub
}
