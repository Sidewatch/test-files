; ── LLVM IR: a warehouse stock library exercising the language ──
; Line comment. TODO: vectorise the sum loop. FIXME: tail-call the helper.
; ModuleID = 'warehouse.c'
source_filename = "warehouse.c"
target datalayout = "e-m:o-i64:64-i128:128-n32:64-S128"
target triple = "arm64-apple-macosx14.0.0"

; ── Metadata-free module-level asm ──
module asm ".globl _legacy_symbol"

; ── Type definitions ──
%struct.Item = type { i32, i32, double, ptr }
%struct.Warehouse = type <{ i8, [3 x i8], i64, %struct.Item }>
%union.Value = type { i64 }
%opaque.Handle = type opaque
%vec4 = type { <4 x float> }

; ── Global variables and constants ──
@total_count = global i32 0, align 4
@max_bins = constant i32 1000, align 4
@version = private unnamed_addr constant [6 x i8] c"1.0.0\00", align 1
@.fmt = private unnamed_addr constant [19 x i8] c"sku=%s qty=%d \E2\9C\93\0A\00", align 1
@greeting = internal constant [14 x i8] c"Hello, world!\00", section "__TEXT,__cstring", align 1
@table = internal global [3 x i32] [i32 10, i32 20, i32 30], align 4
@zero = global %struct.Item zeroinitializer
@ptr_to_table = global ptr @table
@gep_const = global ptr getelementptr inbounds ([3 x i32], ptr @table, i64 0, i64 1)
@tls_var = thread_local(initialexec) global i32 0
@weak_sym = weak global i32 0
@alias_sym = alias i32, ptr @total_count
@ifunc_sym = ifunc void (), ptr @resolver
@ints = global [4 x i32] [i32 -1, i32 0, i32 u0x7FFFFFFF, i32 s0x7FFFFFFF]
@floats = global [4 x double] [double 1.5, double 0x3FF8000000000000, double 6.022e23, double -0.0]
@bools = global [2 x i1] [i1 true, i1 false]
@undefs = global i32 undef
@poison = global i32 poison
@null_ptr = global ptr null

; ── Declarations ──
declare i32 @printf(ptr noundef, ...) #1
declare noalias ptr @malloc(i64) nounwind
declare void @free(ptr nocapture)
declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly, ptr noalias nocapture readonly, i64, i1 immarg) #2
declare i32 @llvm.smax.i32(i32, i32)
declare { i32, i1 } @llvm.sadd.with.overflow.i32(i32, i32)
declare void @llvm.dbg.value(metadata, metadata, metadata)
declare i32 @__gxx_personality_v0(...)
declare void @opaque_call()

; ── Function: arithmetic and loop with phi ──
define i64 @sum_to(i64 %n) #0 !dbg !10 {
entry:
  %cmp0 = icmp slt i64 %n, 1
  br i1 %cmp0, label %exit, label %loop

loop:                                             ; preds = %entry, %loop
  %i = phi i64 [ 1, %entry ], [ %i.next, %loop ]
  %acc = phi i64 [ 0, %entry ], [ %acc.next, %loop ]
  %acc.next = add nsw i64 %acc, %i
  %i.next = add nuw i64 %i, 1
  %done = icmp sgt i64 %i.next, %n
  br i1 %done, label %exit, label %loop, !llvm.loop !12

exit:
  %result = phi i64 [ 0, %entry ], [ %acc.next, %loop ]
  ret i64 %result
}

; ── Function: every instruction family ──
define dso_local i32 @operations(i32 noundef %a, i32 noundef %b, ptr nocapture readonly %p, float %f, double %d) local_unnamed_addr #0 personality ptr @__gxx_personality_v0 {
entry:
  ; Integer arithmetic
  %add = add i32 %a, %b
  %sub = sub nsw i32 %a, %b
  %mul = mul nuw nsw i32 %a, %b
  %sdiv = sdiv exact i32 %a, 3
  %udiv = udiv i32 %a, 3
  %srem = srem i32 %a, 7
  %urem = urem i32 %a, 7
  %neg = sub i32 0, %a
  ; Bitwise
  %and = and i32 %a, 255
  %or = or disjoint i32 %a, 16
  %xor = xor i32 %a, -1
  %shl = shl nuw i32 %a, 2
  %lshr = lshr exact i32 %a, 1
  %ashr = ashr i32 %a, 1
  ; Float arithmetic
  %fadd = fadd fast float %f, 1.000000e+00
  %fsub = fsub nnan float %f, 2.500000e-01
  %fmul = fmul reassoc float %f, %f
  %fdiv = fdiv double %d, 3.000000e+00
  %frem = frem double %d, 2.0
  %fneg = fneg float %f
  ; Comparisons
  %eq = icmp eq i32 %a, %b
  %ne = icmp ne i32 %a, %b
  %ult = icmp ult i32 %a, %b
  %sle = icmp sle i32 %a, %b
  %foeq = fcmp oeq float %f, 0.0
  %fune = fcmp une double %d, 0.0
  %ord = fcmp ord float %f, %f
  %sel = select i1 %eq, i32 %a, i32 %b
  ; Conversions
  %zext = zext i32 %a to i64
  %sext = sext i32 %a to i64
  %trunc = trunc i64 %zext to i16
  %fpext = fpext float %f to double
  %fptrunc = fptrunc double %d to float
  %sitofp = sitofp i32 %a to double
  %fptosi = fptosi double %d to i32
  %bitcast = bitcast float %f to i32
  %ptrtoint = ptrtoint ptr %p to i64
  %inttoptr = inttoptr i64 %ptrtoint to ptr
  ; Memory
  %slot = alloca %struct.Item, align 8
  %arr = alloca [16 x i8], i32 1, align 16
  store i32 %add, ptr %slot, align 8
  %loaded = load i32, ptr %slot, align 8
  store volatile i32 %loaded, ptr @total_count, align 4
  %vload = load volatile i32, ptr @total_count, align 4
  %atomic = load atomic i32, ptr @total_count seq_cst, align 4
  store atomic i32 1, ptr @total_count release, align 4
  %rmw = atomicrmw add ptr @total_count, i32 1 seq_cst
  %cas = cmpxchg ptr @total_count, i32 0, i32 1 acq_rel monotonic
  fence seq_cst
  %field = getelementptr inbounds %struct.Item, ptr %slot, i32 0, i32 2
  %elem = getelementptr inbounds [3 x i32], ptr @table, i64 0, i64 2
  %nuw_gep = getelementptr nuw i8, ptr %p, i64 8
  ; Aggregates and vectors
  %agg = insertvalue { i32, double } undef, i32 %a, 0
  %agg2 = insertvalue { i32, double } %agg, double %d, 1
  %ext = extractvalue { i32, double } %agg2, 1
  %vec = insertelement <4 x i32> zeroinitializer, i32 %a, i64 0
  %shuf = shufflevector <4 x i32> %vec, <4 x i32> poison, <4 x i32> <i32 0, i32 0, i32 0, i32 0>
  %lane = extractelement <4 x i32> %shuf, i32 1
  %vadd = add <4 x i32> %shuf, <i32 1, i32 2, i32 3, i32 4>
  ; Calls
  %call = call i32 (ptr, ...) @printf(ptr @.fmt, ptr @version, i32 %a)
  %tail = tail call i32 @llvm.smax.i32(i32 %a, i32 %b)
  %mem = call ptr @malloc(i64 64)
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %mem, ptr align 8 %slot, i64 24, i1 false)
  call void @free(ptr %mem)
  %ovf = call { i32, i1 } @llvm.sadd.with.overflow.i32(i32 %a, i32 %b)
  call void @llvm.dbg.value(metadata i32 %a, metadata !20, metadata !DIExpression()), !dbg !21
  switch i32 %a, label %default [
    i32 0, label %zero
    i32 1, label %one
    i32 2, label %one
  ]

zero:
  br label %join

one:
  %inv = invoke i32 @might_throw(i32 %a) to label %cont unwind label %lpad

cont:
  br label %join

lpad:
  %lp = landingpad { ptr, i32 }
          cleanup
          catch ptr null
  resume { ptr, i32 } %lp

default:
  unreachable

join:
  %merged = phi i32 [ 0, %zero ], [ %inv, %cont ]
  %frozen = freeze i32 %merged
  ret i32 %frozen
}

define internal fastcc i32 @might_throw(i32 %x) personality ptr @__gxx_personality_v0 {
  %r = mul i32 %x, 2
  ret i32 %r
}

define weak_odr hidden void @indirect(ptr %fn) {
  call void %fn()
  tail call void @opaque_call() #3
  notail call void @opaque_call()
  indirectbr ptr blockaddress(@indirect, %l1), [label %l1]
l1:
  ret void
}

define void @with_attrs(ptr byval(%struct.Item) align 8 %item, ptr sret(%struct.Item) %out, i32 signext %n, ptr noalias nonnull dereferenceable(16) %q) {
  ret void
}

define ptr @resolver() {
  ret ptr null
}

define i32 @main() #0 {
  %s = call i64 @sum_to(i64 100)
  %t = trunc i64 %s to i32
  %r = call i32 (ptr, ...) @printf(ptr @.fmt, ptr @greeting, i32 %t)
  ret i32 0
}

; ── Attributes and metadata ──
attributes #0 = { noinline nounwind optnone ssp uwtable(sync) "frame-pointer"="non-leaf" "target-cpu"="apple-m1" "target-features"="+aes,+crc" }
attributes #1 = { "no-trapping-math"="true" }
attributes #2 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
attributes #3 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !6}
!llvm.ident = !{!3}
!llvm.dbg.cu = !{!4}
!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 14, i32 5]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!6 = !{i32 2, !"Debug Info Version", i32 3}
!3 = !{!"Apple clang version 15.0.0"}
!4 = distinct !DICompileUnit(language: DW_LANG_C11, file: !5, producer: "clang", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
!5 = !DIFile(filename: "warehouse.c", directory: "/src")
!10 = distinct !DISubprogram(name: "sum_to", scope: !5, file: !5, line: 3, unit: !4)
!12 = distinct !{!12, !13}
!13 = !{!"llvm.loop.mustprogress"}
!20 = !DILocalVariable(name: "a", scope: !10, file: !5, line: 5)
!21 = !DILocation(line: 5, column: 3, scope: !10)

; ── Rare constructs: types ──
%rare.types = type { half, bfloat, float, double, x86_fp80, fp128, ppc_fp128, i1, i7, i128, ptr, ptr addrspace(1), <4 x i16>, <vscale x 4 x i32>, [0 x i8], {}, { i8, { i16, [2 x i32] } }, <{ i8, i32 }> }
%rare.fnptr = type { ptr }
%rare.target = type { target("aarch64.svcount") }

; ── Rare constructs: comdat, linkage, visibility ──
$comdat_any = comdat any
$comdat_exact = comdat exactmatch
$comdat_largest = comdat largest
$comdat_nodedup = comdat nodeduplicate
$comdat_samesize = comdat samesize
@lnk.private = private global i32 1
@lnk.internal = internal global i32 2
@lnk.available = available_externally global i32 3
@lnk.linkonce = linkonce global i32 4, comdat($comdat_any)
@lnk.weak_odr = weak_odr global i32 6
@lnk.common = common global i32 0
@lnk.appending = appending global [1 x ptr] [ptr @lnk.private], section "llvm.metadata"
@lnk.extern_weak = extern_weak global i32, align 4
@lnk.external = external global i32, align 4
@lnk.hidden = hidden global i32 7
@lnk.protected = protected global i32 8
@lnk.default = default global i32 9
@lnk.dllimport = external dllimport global i32, align 4
@lnk.dllexport = dllexport global i32 10
@lnk.local_unnamed = local_unnamed_addr constant i32 11
@lnk.externally_init = externally_initialized global i32 12
@lnk.addrspace = addrspace(3) global i32 undef
@lnk.align_section = global i32 13, section ".data.rare", partition "part", align 16, !dbg !30
@lnk.sanitizers = global i32 14, no_sanitize_address, sanitize_address_dyninit
@lnk.code_model = global i32 15, code_model "large"
@lnk.tls_ld = thread_local(localdynamic) global i32 0
@lnk.tls_ie = thread_local(initialexec) global i32 0
@lnk.tls_le = thread_local(localexec) global i32 0
@lnk.tls = thread_local global i32 0
@alias.weak = weak_odr hidden alias i32, ptr @lnk.private
@"quoted global name" = global i32 16
@"quoted \22 escaped" = global i32 17
@0 = global i32 18
@1 = private unnamed_addr constant [2 x i8] c"\5C\00"
@fp.half = global half 0xH3C00
@fp.bfloat = global bfloat 0xR3F80
@fp.x86 = global x86_fp80 0xK3FFF8000000000000000
@fp.fp128 = global fp128 0xL00000000000000003FFF000000000000
@fp.ppc = global ppc_fp128 0xM3FF00000000000000000000000000000
@fp.dec = global double 1.250000e+00
@fp.inf = global double 0x7FF0000000000000
@fp.nan = global double 0x7FF8000000000000
@vec.const = global <4 x float> <float 1.0, float 2.0, float 3.0, float 4.0>
@vec.splat = global <4 x i32> splat (i32 7)
@struct.const = global { i32, ptr } { i32 1, ptr null }
@ce.cast = global i64 ptrtoint (ptr @lnk.private to i64)
@ce.gep = global ptr getelementptr inbounds nuw (i8, ptr @lnk.private, i64 4)
@ce.gep_inrange = global ptr getelementptr inbounds inrange(0, 16) ({ [4 x ptr] }, ptr @vt, i32 0, i32 0, i32 2)
@vt = constant { [4 x ptr] } { [4 x ptr] [ptr null, ptr null, ptr @rare_callee, ptr null] }
@ce.addr = global ptr blockaddress(@rare_fn, %bb2)
@ce.dso_local = global ptr dso_local_equivalent @rare_callee
@ce.no_cfi = global ptr no_cfi @rare_callee
@ce.ptrauth = global ptr ptrauth (ptr @rare_callee, i32 0, i64 1234)
@ce.trunc = global i8 trunc (i32 256 to i8)
@ce.bitcast = global i64 bitcast (double 1.0 to i64)
@ce.vec_idx = global i32 extractelement (<2 x i32> <i32 1, i32 2>, i32 0)
@ce.shuffle = global <2 x i32> shufflevector (<2 x i32> <i32 1, i32 2>, <2 x i32> poison, <2 x i32> <i32 1, i32 0>)

; ── Rare constructs: functions ──
declare void @rare_callee() #0
declare coldcc void @cold()
declare ghccc void @ghc()
declare cc 10 void @cc10()
declare swiftcc void @swift(ptr swiftself, ptr swifterror, ptr swiftasync)
declare preserve_mostcc void @pm()
declare preserve_allcc void @pa()
declare cxx_fast_tlscc void @tls()
declare x86_stdcallcc void @stdcall()
declare x86_fastcallcc void @fastcall()
declare x86_vectorcallcc void @vectorcall()
declare arm_aapcscc void @aapcs()
declare arm_aapcs_vfpcc void @aapcs_vfp()
declare aarch64_vector_pcs void @a64vpcs()
declare ptx_kernel void @kernel()
declare amdgpu_kernel void @amdk()
declare void @va(ptr, ...)
declare i32 @attrs(i32 zeroext, i32 signext, ptr inreg, ptr byref(i8), ptr nonnull align 8 dereferenceable_or_null(8), ptr noundef nofree nocapture, i64 range(i64 0, 10), ptr captures(none)) nounwind readonly willreturn
declare noundef nonnull ptr @retattrs()
declare i32 @fnattrs() cold convergent hot inlinehint minsize mustprogress naked nobuiltin nocf_check noduplicate nofree noimplicitfloat noinline nomerge nonlazybind noredzone noreturn norecurse nosync nounwind null_pointer_is_valid optforfuzzing optsize readnone returns_twice safestack sanitize_address sanitize_memory sanitize_thread speculatable ssp sspreq sspstrong strictfp uwtable willreturn "string-attr"="value" "bare-attr"

define void @rare_fn(i32 %x, ptr %p) section "text.rare" align 16 gc "statepoint-example" prefix i32 123 prologue i32 456 personality ptr @__gxx_personality_v0 !prof !31 {
entry:
  %cmpx = cmpxchg weak volatile ptr %p, i32 0, i32 1 syncscope("singlethread") release acquire, align 4
  %rmw.xchg = atomicrmw xchg ptr %p, i32 1 monotonic
  %rmw.sub = atomicrmw sub ptr %p, i32 1 acquire
  %rmw.and = atomicrmw and ptr %p, i32 1 release
  %rmw.nand = atomicrmw nand ptr %p, i32 1 acq_rel
  %rmw.or = atomicrmw or ptr %p, i32 1 seq_cst
  %rmw.xor = atomicrmw xor ptr %p, i32 1 syncscope("agent") seq_cst
  %rmw.max = atomicrmw max ptr %p, i32 1 seq_cst
  %rmw.min = atomicrmw min ptr %p, i32 1 seq_cst
  %rmw.umax = atomicrmw umax ptr %p, i32 1 seq_cst
  %rmw.umin = atomicrmw umin ptr %p, i32 1 seq_cst
  %rmw.fadd = atomicrmw fadd ptr %p, float 1.0 seq_cst
  %rmw.fsub = atomicrmw fsub ptr %p, float 1.0 seq_cst
  %rmw.fmax = atomicrmw fmax ptr %p, float 1.0 seq_cst
  %rmw.fmin = atomicrmw fmin ptr %p, float 1.0 seq_cst
  %rmw.uinc = atomicrmw uinc_wrap ptr %p, i32 1 seq_cst
  %rmw.udec = atomicrmw udec_wrap ptr %p, i32 1 seq_cst
  fence syncscope("singlethread") acquire
  %ld.tbaa = load i32, ptr %p, align 4, !tbaa !32, !range !33, !invariant.load !34
  %ld.ordered = load atomic volatile i32, ptr %p syncscope("singlethread") acquire, align 4
  store i32 %x, ptr %p, align 4, !nontemporal !35
  %ic.eq = icmp eq i32 %x, 0
  %ic.ne = icmp ne i32 %x, 0
  %ic.ugt = icmp ugt i32 %x, 0
  %ic.uge = icmp uge i32 %x, 0
  %ic.ult = icmp ult i32 %x, 0
  %ic.ule = icmp ule i32 %x, 0
  %ic.sgt = icmp sgt i32 %x, 0
  %ic.sge = icmp sge i32 %x, 0
  %ic.slt = icmp slt i32 %x, 0
  %ic.sle = icmp sle i32 %x, 0
  %ic.samesign = icmp samesign ult i32 %x, 5
  %f = sitofp i32 %x to float
  %fc.false = fcmp false float %f, %f
  %fc.oeq = fcmp oeq float %f, %f
  %fc.ogt = fcmp ogt float %f, %f
  %fc.oge = fcmp oge float %f, %f
  %fc.olt = fcmp olt float %f, %f
  %fc.ole = fcmp ole float %f, %f
  %fc.one = fcmp one float %f, %f
  %fc.ord = fcmp ord float %f, %f
  %fc.ueq = fcmp ueq float %f, %f
  %fc.ugt = fcmp ugt float %f, %f
  %fc.uge = fcmp uge float %f, %f
  %fc.ult = fcmp ult float %f, %f
  %fc.ule = fcmp ule float %f, %f
  %fc.une = fcmp une float %f, %f
  %fc.uno = fcmp uno float %f, %f
  %fc.true = fcmp true float %f, %f
  %fm.all = fadd nnan ninf nsz arcp contract afn reassoc float %f, %f
  %fm.fast = fmul fast float %f, %f
  %nneg = zext nneg i32 %x to i64
  %nuwtrunc = trunc nuw nsw i32 %x to i16
  %sh.nuw = shl nuw nsw i32 %x, 1
  %fp2ui = fptoui float %f to i32
  %ui2fp = uitofp i32 %x to float
  %addrspace = addrspacecast ptr %p to ptr addrspace(1)
  %sel.fm = select nnan i1 %ic.eq, float %f, float %f
  %agg.undef = insertvalue { i32, i32 } poison, i32 1, 0
  %call.bundle = call i32 @attrs(i32 zeroext 1, i32 signext 2, ptr inreg null, ptr byref(i8) null, ptr nonnull align 8 dereferenceable_or_null(8) null, ptr null, i64 1, ptr captures(none) null) [ "deopt"(i32 1, i32 2) ], !srcloc !36
  %call.fmf = call fast float @llvm.fabs.f32(float %f)
  %call.cc = call fastcc i32 @attrs_ccc(i32 1)
  %call.va = call i32 (ptr, ...) @printf(ptr @1, i32 1, double 2.0)
  %call.inline = call i32 asm sideeffect alignstack inteldialect unwind "mov $0, $1", "=r,r,~{memory},~{dirflag},~{fpsr},~{flags}"(i32 %x)
  %va.list = alloca ptr
  %va.arg = va_arg ptr %va.list, i32
  %alloca.full = alloca inalloca [4 x i32], i64 2, align 16, addrspace(5)
  %vscale = call i64 @llvm.vscale.i64()
  callbr void asm "", "!i"() to label %bb2 [label %bb3]
bb2:
  br label %bb3, !llvm.loop !38, !make.implicit !34
bb3:
  switch i32 %x, label %bb4 [ i32 1, label %bb4 ], !prof !39
bb4:
  unreachable
}

define void @eh_funclets() personality ptr @__CxxFrameHandler3 {
entry:
  invoke void @rare_callee() to label %ok unwind label %cs
cs:
  %cs.tok = catchswitch within none [label %catch] unwind label %cleanup
catch:
  %cp = catchpad within %cs.tok [ptr null, i32 64, ptr null]
  catchret from %cp to label %ok
cleanup:
  %cl = cleanuppad within none []
  cleanupret from %cl unwind to caller
ok:
  ret void
}
declare i32 @__CxxFrameHandler3(...)
declare i32 @attrs_ccc(i32)
declare float @llvm.fabs.f32(float)
declare i64 @llvm.vscale.i64()

; ── Rare constructs: metadata ──
uselistorder_bb @rare_fn, %bb2, { 1, 0 }
!30 = !DIGlobalVariableExpression(var: !40, expr: !DIExpression())
!31 = !{!"function_entry_count", i64 100}
!32 = !{!41, !41, i64 0}
!33 = !{i32 0, i32 10}
!34 = !{}
!35 = !{i32 1}
!36 = !{i32 100}
!37 = !{!"branch_weights", i32 1, i32 99}
!38 = distinct !{!38, !{!"llvm.loop.unroll.disable"}}
!39 = !{!"branch_weights", i32 1, i32 2}
!40 = distinct !DIGlobalVariable(name: "g", scope: !4, file: !5, line: 1, type: !42, isLocal: false, isDefinition: true)
!41 = !{!"int", !43, i64 0}
!42 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!43 = !{!"omnipotent char", !44, i64 0}
!44 = !{!"Simple C/C++ TBAA"}
!llvm.named.rare = !{!31, !34}
!45 = !DICompositeType(tag: DW_TAG_structure_type, name: "S", file: !5, line: 2, size: 64, flags: DIFlagPublic | DIFlagFwdDecl, elements: !{})
!46 = !DISubroutineType(types: !{null, !42})
!47 = !DILexicalBlock(scope: !10, file: !5, line: 3, column: 1)
!48 = !DIDerivedType(tag: DW_TAG_member, name: "m", scope: !45, baseType: !42, size: 32, offset: 32)
!49 = !DIEnumerator(name: "A", value: 0)
!50 = !DISubrange(count: 4)
!51 = !DITemplateTypeParameter(name: "T", type: !42)
!52 = !DINamespace(name: "ns", scope: null)
!53 = !DILabel(scope: !10, name: "lbl", file: !5, line: 4)
!54 = !DIImportedEntity(tag: DW_TAG_imported_module, scope: !4, entity: !52, file: !5, line: 5)
!55 = !DIMacro(type: DW_MACINFO_define, line: 1, name: "X", value: "1")
!58 = !DIStringType(name: "str", size: 8)
!59 = !DICommonBlock(scope: !10, declaration: null, name: "cb")
!60 = !DIGenericSubrange(count: !{}, lowerBound: !{}, upperBound: !{}, stride: !{})
!61 = !DILocalVariable(name: "v", arg: 1, scope: !10, file: !5, line: 6, type: !42, flags: DIFlagArtificial)
!62 = !DIExpression(DW_OP_plus_uconst, 4, DW_OP_deref, DW_OP_LLVM_fragment, 0, 32)
!64 = !{ptr @rare_fn, !"kernel", i32 1}
!65 = !{i1 true, i8 7, half 1.0, float 2.0, double 3.0, <2 x i32> <i32 1, i32 2>, [1 x i8] zeroinitializer, ptr null}
