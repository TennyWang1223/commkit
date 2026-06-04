	.amdgcn_target "amdgcn-amd-amdhsa--gfx942"
	.amdhsa_code_object_version 6
	.section	.text._ZN7commkit7kernels26cross_device_reduce_1stageIDF16bLi8EEEvPNS_8RankDataENS_11RankSignalsEPNS_6SignalEPT_ii,"axG",@progbits,_ZN7commkit7kernels26cross_device_reduce_1stageIDF16bLi8EEEvPNS_8RankDataENS_11RankSignalsEPNS_6SignalEPT_ii,comdat
	.protected	_ZN7commkit7kernels26cross_device_reduce_1stageIDF16bLi8EEEvPNS_8RankDataENS_11RankSignalsEPNS_6SignalEPT_ii ; -- Begin function _ZN7commkit7kernels26cross_device_reduce_1stageIDF16bLi8EEEvPNS_8RankDataENS_11RankSignalsEPNS_6SignalEPT_ii
	.globl	_ZN7commkit7kernels26cross_device_reduce_1stageIDF16bLi8EEEvPNS_8RankDataENS_11RankSignalsEPNS_6SignalEPT_ii
	.p2align	8
	.type	_ZN7commkit7kernels26cross_device_reduce_1stageIDF16bLi8EEEvPNS_8RankDataENS_11RankSignalsEPNS_6SignalEPT_ii,@function
_ZN7commkit7kernels26cross_device_reduce_1stageIDF16bLi8EEEvPNS_8RankDataENS_11RankSignalsEPNS_6SignalEPT_ii: ; @_ZN7commkit7kernels26cross_device_reduce_1stageIDF16bLi8EEEvPNS_8RankDataENS_11RankSignalsEPNS_6SignalEPT_ii
; %bb.0:
	s_load_dwordx2 s[4:5], s[0:1], 0x0
	s_load_dwordx2 s[28:29], s[0:1], 0x50
	s_add_u32 s24, s0, 16
	s_mov_b32 s3, 0
	s_addc_u32 s25, s1, 0
	s_lshl_b64 s[6:7], s[2:3], 2
	s_waitcnt lgkmcnt(0)
	s_add_u32 s6, s28, s6
	s_addc_u32 s7, s29, s7
	s_load_dwordx2 s[26:27], s[0:1], 0x60
	s_load_dword s33, s[6:7], 0x1400
	s_load_dwordx16 s[8:23], s[4:5], 0x0
	s_add_u32 s6, s6, 0x1400
	s_addc_u32 s7, s7, 0
	v_cmp_gt_u32_e32 vcc, 8, v0
	s_waitcnt lgkmcnt(0)
	s_add_i32 s33, s33, 1
	v_lshlrev_b32_e32 v6, 3, v0
	v_lshlrev_b32_e32 v2, 2, v0
	s_and_saveexec_b64 s[30:31], vcc
	s_cbranch_execz .LBB0_3
; %bb.1:
	global_load_dwordx2 v[8:9], v6, s[24:25]
	s_ashr_i32 s5, s26, 31
	s_mov_b32 s4, s26
	s_lshl_b64 s[34:35], s[2:3], 5
	s_lshl_b64 s[4:5], s[4:5], 2
	s_add_u32 s4, s4, s34
	s_addc_u32 s5, s5, s35
	s_add_u32 s34, s28, s34
	v_mov_b32_e32 v3, 0
	s_addc_u32 s35, s29, s35
	v_mov_b32_e32 v1, s33
	v_lshl_add_u64 v[4:5], s[34:35], 0, v[2:3]
	s_mov_b64 s[34:35], 0
	s_waitcnt vmcnt(0)
	v_lshl_add_u64 v[8:9], s[4:5], 0, v[8:9]
	global_store_dword v[8:9], v1, off sc0 sc1
.LBB0_2:                                ; =>This Inner Loop Header: Depth=1
	global_load_dword v1, v[4:5], off sc1
	s_waitcnt vmcnt(0)
	v_cmp_le_u32_e64 s[4:5], s33, v1
	s_or_b64 s[34:35], s[4:5], s[34:35]
	s_andn2_b64 exec, exec, s[34:35]
	s_cbranch_execnz .LBB0_2
.LBB0_3:
	s_or_b64 exec, exec, s[30:31]
	s_load_dwordx2 s[30:31], s[0:1], 0x58
	v_cmp_eq_u32_e64 s[4:5], 0, v0
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_saveexec_b64 s[34:35], s[4:5]
	s_cbranch_execz .LBB0_5
; %bb.4:
	v_mov_b32_e32 v1, 0
	v_mov_b32_e32 v3, s33
	global_store_dword v1, v3, s[6:7]
.LBB0_5:
	s_or_b64 exec, exec, s[34:35]
	s_load_dword s33, s[0:1], 0x74
	s_add_u32 s36, s0, 0x68
	s_addc_u32 s37, s1, 0
	s_waitcnt lgkmcnt(0)
	s_and_b32 s33, s33, 0xffff
	s_mul_i32 s0, s2, s33
	v_add_u32_e32 v0, s0, v0
	v_cmp_gt_i32_e64 s[0:1], s27, v0
	s_and_saveexec_b64 s[34:35], s[0:1]
	s_cbranch_execz .LBB0_8
; %bb.6:
	s_load_dword s0, s[36:37], 0x0
	s_mov_b64 s[36:37], 0
	s_mov_b32 s38, 0x7060302
	s_waitcnt lgkmcnt(0)
	s_mul_i32 s33, s0, s33
.LBB0_7:                                ; =>This Inner Loop Header: Depth=1
	v_ashrrev_i32_e32 v1, 31, v0
	v_lshlrev_b64 v[4:5], 4, v[0:1]
	v_lshl_add_u64 v[8:9], s[8:9], 0, v[4:5]
	flat_load_dwordx4 v[8:11], v[8:9]
	v_lshl_add_u64 v[12:13], s[10:11], 0, v[4:5]
	flat_load_dwordx4 v[12:15], v[12:13]
	v_lshl_add_u64 v[16:17], s[12:13], 0, v[4:5]
	flat_load_dwordx4 v[16:19], v[16:17]
	v_lshl_add_u64 v[20:21], s[14:15], 0, v[4:5]
	flat_load_dwordx4 v[20:23], v[20:21]
	v_lshl_add_u64 v[24:25], s[16:17], 0, v[4:5]
	flat_load_dwordx4 v[24:27], v[24:25]
	v_lshl_add_u64 v[28:29], s[18:19], 0, v[4:5]
	flat_load_dwordx4 v[28:31], v[28:29]
	v_lshl_add_u64 v[32:33], s[20:21], 0, v[4:5]
	flat_load_dwordx4 v[32:35], v[32:33]
	v_add_u32_e32 v0, s33, v0
	v_cmp_le_i32_e64 s[0:1], s27, v0
	s_or_b64 s[36:37], s[0:1], s[36:37]
	s_waitcnt vmcnt(0) lgkmcnt(0)
	v_and_b32_e32 v41, 0xffff0000, v9
	v_lshlrev_b32_e32 v40, 16, v9
	v_and_b32_e32 v43, 0xffff0000, v8
	v_lshlrev_b32_e32 v42, 16, v8
	v_lshl_add_u64 v[8:9], s[22:23], 0, v[4:5]
	v_and_b32_e32 v37, 0xffff0000, v11
	v_lshlrev_b32_e32 v36, 16, v11
	v_and_b32_e32 v39, 0xffff0000, v10
	v_lshlrev_b32_e32 v38, 16, v10
	flat_load_dwordx4 v[8:11], v[8:9]
	v_and_b32_e32 v45, 0xffff0000, v15
	v_lshlrev_b32_e32 v44, 16, v15
	v_and_b32_e32 v15, 0xffff0000, v14
	v_lshlrev_b32_e32 v14, 16, v14
	v_and_b32_e32 v47, 0xffff0000, v13
	v_lshlrev_b32_e32 v46, 16, v13
	v_and_b32_e32 v13, 0xffff0000, v12
	v_lshlrev_b32_e32 v12, 16, v12
	v_and_b32_e32 v49, 0xffff0000, v16
	v_lshlrev_b32_e32 v48, 16, v16
	v_and_b32_e32 v51, 0xffff0000, v17
	v_lshlrev_b32_e32 v50, 16, v17
	v_and_b32_e32 v17, 0xffff0000, v18
	v_lshlrev_b32_e32 v16, 16, v18
	v_and_b32_e32 v53, 0xffff0000, v19
	v_lshlrev_b32_e32 v52, 16, v19
	v_pk_add_f32 v[12:13], v[42:43], v[12:13]
	v_pk_add_f32 v[40:41], v[40:41], v[46:47]
	v_pk_add_f32 v[14:15], v[38:39], v[14:15]
	v_pk_add_f32 v[36:37], v[36:37], v[44:45]
	v_and_b32_e32 v19, 0xffff0000, v23
	v_lshlrev_b32_e32 v18, 16, v23
	v_and_b32_e32 v23, 0xffff0000, v22
	v_lshlrev_b32_e32 v22, 16, v22
	v_and_b32_e32 v55, 0xffff0000, v21
	v_lshlrev_b32_e32 v54, 16, v21
	v_and_b32_e32 v21, 0xffff0000, v20
	v_lshlrev_b32_e32 v20, 16, v20
	v_pk_add_f32 v[36:37], v[36:37], v[52:53]
	v_pk_add_f32 v[14:15], v[14:15], v[16:17]
	v_pk_add_f32 v[16:17], v[40:41], v[50:51]
	v_pk_add_f32 v[12:13], v[12:13], v[48:49]
	v_and_b32_e32 v57, 0xffff0000, v24
	v_lshlrev_b32_e32 v56, 16, v24
	v_and_b32_e32 v59, 0xffff0000, v25
	v_lshlrev_b32_e32 v58, 16, v25
	v_and_b32_e32 v25, 0xffff0000, v26
	v_lshlrev_b32_e32 v24, 16, v26
	v_and_b32_e32 v61, 0xffff0000, v27
	v_lshlrev_b32_e32 v60, 16, v27
	v_pk_add_f32 v[12:13], v[12:13], v[20:21]
	v_pk_add_f32 v[16:17], v[16:17], v[54:55]
	v_pk_add_f32 v[14:15], v[14:15], v[22:23]
	v_pk_add_f32 v[18:19], v[36:37], v[18:19]
	v_and_b32_e32 v27, 0xffff0000, v31
	v_lshlrev_b32_e32 v26, 16, v31
	v_and_b32_e32 v31, 0xffff0000, v30
	v_lshlrev_b32_e32 v30, 16, v30
	v_and_b32_e32 v63, 0xffff0000, v29
	v_lshlrev_b32_e32 v62, 16, v29
	v_and_b32_e32 v29, 0xffff0000, v28
	v_lshlrev_b32_e32 v28, 16, v28
	v_pk_add_f32 v[18:19], v[18:19], v[60:61]
	v_pk_add_f32 v[14:15], v[14:15], v[24:25]
	v_pk_add_f32 v[16:17], v[16:17], v[58:59]
	v_pk_add_f32 v[12:13], v[12:13], v[56:57]
	v_and_b32_e32 v43, 0xffff0000, v32
	v_lshlrev_b32_e32 v42, 16, v32
	v_and_b32_e32 v47, 0xffff0000, v33
	v_pk_add_f32 v[12:13], v[12:13], v[28:29]
	v_pk_add_f32 v[16:17], v[16:17], v[62:63]
	v_pk_add_f32 v[14:15], v[14:15], v[30:31]
	v_pk_add_f32 v[18:19], v[18:19], v[26:27]
	v_lshlrev_b32_e32 v46, 16, v33
	v_and_b32_e32 v21, 0xffff0000, v34
	v_lshlrev_b32_e32 v20, 16, v34
	v_and_b32_e32 v23, 0xffff0000, v35
	v_lshlrev_b32_e32 v22, 16, v35
	v_pk_add_f32 v[18:19], v[18:19], v[22:23]
	v_pk_add_f32 v[14:15], v[14:15], v[20:21]
	v_pk_add_f32 v[16:17], v[16:17], v[46:47]
	v_pk_add_f32 v[12:13], v[12:13], v[42:43]
	v_lshl_add_u64 v[4:5], s[30:31], 0, v[4:5]
	s_waitcnt vmcnt(0) lgkmcnt(0)
	v_and_b32_e32 v21, 0xffff0000, v11
	v_lshlrev_b32_e32 v20, 16, v11
	v_and_b32_e32 v11, 0xffff0000, v10
	v_lshlrev_b32_e32 v10, 16, v10
	v_and_b32_e32 v23, 0xffff0000, v9
	v_lshlrev_b32_e32 v22, 16, v9
	v_and_b32_e32 v9, 0xffff0000, v8
	v_lshlrev_b32_e32 v8, 16, v8
	v_pk_add_f32 v[12:13], v[12:13], v[8:9]
	v_pk_add_f32 v[8:9], v[16:17], v[22:23]
	v_pk_add_f32 v[14:15], v[14:15], v[10:11]
	v_pk_add_f32 v[10:11], v[18:19], v[20:21]
	v_perm_b32 v9, v9, v8, s38
	v_perm_b32 v11, v11, v10, s38
	v_perm_b32 v10, v15, v14, s38
	v_perm_b32 v8, v13, v12, s38
	global_store_dwordx4 v[4:5], v[8:11], off
	s_andn2_b64 exec, exec, s[36:37]
	s_cbranch_execnz .LBB0_7
.LBB0_8:
	s_or_b64 exec, exec, s[34:35]
	v_mov_b32_e32 v3, 0
	s_barrier
	global_load_dword v0, v3, s[6:7]
	s_waitcnt vmcnt(0)
	v_add_u32_e32 v4, 1, v0
	s_and_saveexec_b64 s[8:9], vcc
	s_cbranch_execz .LBB0_11
; %bb.9:
	global_load_dwordx2 v[8:9], v6, s[24:25]
	s_ashr_i32 s27, s26, 31
	s_lshl_b64 s[0:1], s[2:3], 5
	s_lshl_b64 s[10:11], s[26:27], 2
	s_add_u32 s10, s10, s0
	s_addc_u32 s11, s11, s1
	s_add_u32 s0, s28, s0
	s_addc_u32 s1, s29, s1
	v_lshl_add_u64 v[0:1], s[0:1], 0, v[2:3]
	s_waitcnt vmcnt(0)
	v_lshl_add_u64 v[8:9], s[10:11], 0, v[8:9]
	s_mov_b64 s[10:11], 0
	buffer_wbl2 sc0 sc1
	global_store_dword v[8:9], v4, off offset:2560 sc0 sc1
.LBB0_10:                               ; =>This Inner Loop Header: Depth=1
	global_load_dword v3, v[0:1], off offset:2560 sc1
	s_waitcnt vmcnt(0)
	buffer_inv sc1
	v_cmp_ge_u32_e64 s[0:1], v3, v4
	s_or_b64 s[10:11], s[0:1], s[10:11]
	s_andn2_b64 exec, exec, s[10:11]
	s_cbranch_execnz .LBB0_10
.LBB0_11:
	s_or_b64 exec, exec, s[8:9]
	s_barrier
	s_and_saveexec_b64 s[0:1], s[4:5]
	s_cbranch_execz .LBB0_13
; %bb.12:
	v_mov_b32_e32 v0, 0
	global_store_dword v0, v4, s[6:7]
.LBB0_13:
	s_or_b64 exec, exec, s[0:1]
	v_mov_b32_e32 v3, 0
	s_barrier
	global_load_dword v0, v3, s[6:7]
	s_waitcnt vmcnt(0)
	v_add_u32_e32 v4, 1, v0
	s_and_saveexec_b64 s[8:9], vcc
	s_cbranch_execz .LBB0_16
; %bb.14:
	global_load_dwordx2 v[8:9], v6, s[24:25]
	s_ashr_i32 s27, s26, 31
	s_lshl_b64 s[0:1], s[2:3], 5
	s_lshl_b64 s[10:11], s[26:27], 2
	s_add_u32 s10, s10, s0
	s_addc_u32 s11, s11, s1
	s_add_u32 s0, s28, s0
	s_addc_u32 s1, s29, s1
	v_lshl_add_u64 v[0:1], s[0:1], 0, v[2:3]
	s_waitcnt vmcnt(0)
	v_lshl_add_u64 v[8:9], s[10:11], 0, v[8:9]
	s_mov_b64 s[10:11], 0
	global_store_dword v[8:9], v4, off offset:2560 sc0 sc1
.LBB0_15:                               ; =>This Inner Loop Header: Depth=1
	global_load_dword v3, v[0:1], off offset:2560 sc1
	s_waitcnt vmcnt(0)
	v_cmp_ge_u32_e64 s[0:1], v3, v4
	s_or_b64 s[10:11], s[0:1], s[10:11]
	s_andn2_b64 exec, exec, s[10:11]
	s_cbranch_execnz .LBB0_15
.LBB0_16:
	s_or_b64 exec, exec, s[8:9]
	s_barrier
	s_and_saveexec_b64 s[0:1], s[4:5]
	s_cbranch_execz .LBB0_18
; %bb.17:
	v_mov_b32_e32 v0, 0
	global_store_dword v0, v4, s[6:7]
.LBB0_18:
	s_or_b64 exec, exec, s[0:1]
	v_mov_b32_e32 v3, 0
	s_barrier
	global_load_dword v0, v3, s[6:7]
	s_waitcnt vmcnt(0)
	v_add_u32_e32 v4, 1, v0
	s_and_saveexec_b64 s[8:9], vcc
	s_cbranch_execz .LBB0_21
; %bb.19:
	global_load_dwordx2 v[8:9], v6, s[24:25]
	s_ashr_i32 s27, s26, 31
	s_lshl_b64 s[0:1], s[2:3], 5
	s_lshl_b64 s[10:11], s[26:27], 2
	s_add_u32 s10, s10, s0
	s_addc_u32 s11, s11, s1
	s_add_u32 s0, s28, s0
	s_addc_u32 s1, s29, s1
	v_lshl_add_u64 v[0:1], s[0:1], 0, v[2:3]
	s_waitcnt vmcnt(0)
	v_lshl_add_u64 v[8:9], s[10:11], 0, v[8:9]
	s_mov_b64 s[10:11], 0
	buffer_wbl2 sc0 sc1
	global_store_dword v[8:9], v4, off offset:2560 sc0 sc1
.LBB0_20:                               ; =>This Inner Loop Header: Depth=1
	global_load_dword v3, v[0:1], off offset:2560 sc0 sc1
	s_waitcnt vmcnt(0)
	buffer_inv sc0 sc1
	v_cmp_ge_u32_e64 s[0:1], v3, v4
	s_or_b64 s[10:11], s[0:1], s[10:11]
	s_andn2_b64 exec, exec, s[10:11]
	s_cbranch_execnz .LBB0_20
.LBB0_21:
	s_or_b64 exec, exec, s[8:9]
	s_barrier
	s_and_saveexec_b64 s[0:1], s[4:5]
	s_cbranch_execz .LBB0_23
; %bb.22:
	v_mov_b32_e32 v0, 0
	global_store_dword v0, v4, s[6:7]
.LBB0_23:
	s_or_b64 exec, exec, s[0:1]
	v_mov_b32_e32 v3, 0
	s_barrier
	global_load_dword v0, v3, s[6:7]
	s_waitcnt vmcnt(0)
	v_add_u32_e32 v4, 1, v0
	s_and_saveexec_b64 s[8:9], vcc
	s_cbranch_execz .LBB0_26
; %bb.24:
	global_load_dwordx2 v[0:1], v6, s[24:25]
	s_ashr_i32 s27, s26, 31
	s_lshl_b64 s[0:1], s[2:3], 5
	s_lshl_b64 s[12:13], s[26:27], 2
	s_add_u32 s12, s12, s0
	s_addc_u32 s13, s13, s1
	s_add_u32 s0, s28, s0
	s_mov_b64 s[10:11], 0xa00
	s_addc_u32 s1, s29, s1
	s_add_u32 s0, s0, 0xa00
	s_addc_u32 s1, s1, 0
	s_waitcnt vmcnt(0)
	v_lshl_add_u64 v[0:1], v[0:1], 0, s[12:13]
	v_lshl_add_u64 v[8:9], v[0:1], 0, s[10:11]
	;;#ASMSTART
	buffer_wbl2 sc0 sc1
	global_store_dword v[8:9], v4, off sc0 sc1
	
	;;#ASMEND
	v_lshl_add_u64 v[0:1], s[0:1], 0, v[2:3]
	s_mov_b64 s[10:11], 0
.LBB0_25:                               ; =>This Inner Loop Header: Depth=1
	;;#ASMSTART
	global_load_dword v2, v[0:1], off sc1
	s_waitcnt vmcnt(0)
	buffer_inv sc1
	
	;;#ASMEND
	s_nop 0
	v_cmp_ge_u32_e64 s[0:1], v2, v4
	s_or_b64 s[10:11], s[0:1], s[10:11]
	s_andn2_b64 exec, exec, s[10:11]
	s_cbranch_execnz .LBB0_25
.LBB0_26:
	s_or_b64 exec, exec, s[8:9]
	s_barrier
	s_and_saveexec_b64 s[0:1], s[4:5]
	s_cbranch_execz .LBB0_28
; %bb.27:
	v_mov_b32_e32 v0, 0
	global_store_dword v0, v4, s[6:7]
.LBB0_28:
	s_or_b64 exec, exec, s[0:1]
	v_mov_b32_e32 v0, 0
	s_barrier
	global_load_dword v0, v0, s[6:7]
	s_waitcnt vmcnt(0)
	v_add_u32_e32 v0, 1, v0
	s_and_saveexec_b64 s[0:1], vcc
	s_cbranch_execz .LBB0_30
; %bb.29:
	global_load_dwordx2 v[2:3], v6, s[24:25]
	s_ashr_i32 s27, s26, 31
	s_lshl_b64 s[2:3], s[2:3], 5
	s_lshl_b64 s[8:9], s[26:27], 2
	s_add_u32 s2, s8, s2
	s_addc_u32 s3, s9, s3
	s_waitcnt vmcnt(0)
	v_lshl_add_u64 v[2:3], v[2:3], 0, s[2:3]
	s_mov_b64 s[2:3], 0xa00
	v_lshl_add_u64 v[2:3], v[2:3], 0, s[2:3]
	;;#ASMSTART
	buffer_wbl2 sc0 sc1
	global_store_dword v[2:3], v0, off sc0 sc1
	
	;;#ASMEND
.LBB0_30:
	s_or_b64 exec, exec, s[0:1]
	s_barrier
	s_and_saveexec_b64 s[0:1], s[4:5]
	s_cbranch_execz .LBB0_32
; %bb.31:
	v_mov_b32_e32 v1, 0
	global_store_dword v1, v0, s[6:7]
.LBB0_32:
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel _ZN7commkit7kernels26cross_device_reduce_1stageIDF16bLi8EEEvPNS_8RankDataENS_11RankSignalsEPNS_6SignalEPT_ii
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 360
		.amdhsa_user_sgpr_count 2
		.amdhsa_user_sgpr_dispatch_ptr 0
		.amdhsa_user_sgpr_queue_ptr 0
		.amdhsa_user_sgpr_kernarg_segment_ptr 1
		.amdhsa_user_sgpr_dispatch_id 0
		.amdhsa_user_sgpr_kernarg_preload_length 0
		.amdhsa_user_sgpr_kernarg_preload_offset 0
		.amdhsa_user_sgpr_private_segment_size 0
		.amdhsa_uses_dynamic_stack 0
		.amdhsa_enable_private_segment 0
		.amdhsa_system_sgpr_workgroup_id_x 1
		.amdhsa_system_sgpr_workgroup_id_y 0
		.amdhsa_system_sgpr_workgroup_id_z 0
		.amdhsa_system_sgpr_workgroup_info 0
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 64
		.amdhsa_next_free_sgpr 39
		.amdhsa_accum_offset 64
		.amdhsa_reserve_vcc 1
		.amdhsa_float_round_mode_32 0
		.amdhsa_float_round_mode_16_64 0
		.amdhsa_float_denorm_mode_32 3
		.amdhsa_float_denorm_mode_16_64 3
		.amdhsa_dx10_clamp 1
		.amdhsa_ieee_mode 1
		.amdhsa_fp16_overflow 0
		.amdhsa_tg_split 0
		.amdhsa_exception_fp_ieee_invalid_op 0
		.amdhsa_exception_fp_denorm_src 0
		.amdhsa_exception_fp_ieee_div_zero 0
		.amdhsa_exception_fp_ieee_overflow 0
		.amdhsa_exception_fp_ieee_underflow 0
		.amdhsa_exception_fp_ieee_inexact 0
		.amdhsa_exception_int_div_zero 0
	.end_amdhsa_kernel
	.section	.text._ZN7commkit7kernels26cross_device_reduce_1stageIDF16bLi8EEEvPNS_8RankDataENS_11RankSignalsEPNS_6SignalEPT_ii,"axG",@progbits,_ZN7commkit7kernels26cross_device_reduce_1stageIDF16bLi8EEEvPNS_8RankDataENS_11RankSignalsEPNS_6SignalEPT_ii,comdat
.Lfunc_end0:
	.size	_ZN7commkit7kernels26cross_device_reduce_1stageIDF16bLi8EEEvPNS_8RankDataENS_11RankSignalsEPNS_6SignalEPT_ii, .Lfunc_end0-_ZN7commkit7kernels26cross_device_reduce_1stageIDF16bLi8EEEvPNS_8RankDataENS_11RankSignalsEPNS_6SignalEPT_ii
                                        ; -- End function
	.set _ZN7commkit7kernels26cross_device_reduce_1stageIDF16bLi8EEEvPNS_8RankDataENS_11RankSignalsEPNS_6SignalEPT_ii.num_vgpr, 64
	.set _ZN7commkit7kernels26cross_device_reduce_1stageIDF16bLi8EEEvPNS_8RankDataENS_11RankSignalsEPNS_6SignalEPT_ii.num_agpr, 0
	.set _ZN7commkit7kernels26cross_device_reduce_1stageIDF16bLi8EEEvPNS_8RankDataENS_11RankSignalsEPNS_6SignalEPT_ii.numbered_sgpr, 39
	.set _ZN7commkit7kernels26cross_device_reduce_1stageIDF16bLi8EEEvPNS_8RankDataENS_11RankSignalsEPNS_6SignalEPT_ii.private_seg_size, 0
	.set _ZN7commkit7kernels26cross_device_reduce_1stageIDF16bLi8EEEvPNS_8RankDataENS_11RankSignalsEPNS_6SignalEPT_ii.uses_vcc, 1
	.set _ZN7commkit7kernels26cross_device_reduce_1stageIDF16bLi8EEEvPNS_8RankDataENS_11RankSignalsEPNS_6SignalEPT_ii.uses_flat_scratch, 0
	.set _ZN7commkit7kernels26cross_device_reduce_1stageIDF16bLi8EEEvPNS_8RankDataENS_11RankSignalsEPNS_6SignalEPT_ii.has_dyn_sized_stack, 0
	.set _ZN7commkit7kernels26cross_device_reduce_1stageIDF16bLi8EEEvPNS_8RankDataENS_11RankSignalsEPNS_6SignalEPT_ii.has_recursion, 0
	.set _ZN7commkit7kernels26cross_device_reduce_1stageIDF16bLi8EEEvPNS_8RankDataENS_11RankSignalsEPNS_6SignalEPT_ii.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 2068
; TotalNumSgprs: 45
; NumVgprs: 64
; NumAgprs: 0
; TotalNumVgprs: 64
; ScratchSize: 0
; MemoryBound: 1
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 5
; VGPRBlocks: 7
; NumSGPRsForWavesPerEU: 45
; NumVGPRsForWavesPerEU: 64
; AccumOffset: 64
; Occupancy: 8
; WaveLimiterHint : 1
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 2
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 0
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 0
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 0
; COMPUTE_PGM_RSRC3_GFX90A:ACCUM_OFFSET: 15
; COMPUTE_PGM_RSRC3_GFX90A:TG_SPLIT: 0
	.text
	.p2alignl 6, 3212836864
	.fill 256, 4, 3212836864
	.section	.AMDGPU.gpr_maximums,"",@progbits
	.set amdgpu.max_num_vgpr, 0
	.set amdgpu.max_num_agpr, 0
	.set amdgpu.max_num_sgpr, 0
	.text
	.type	__hip_cuid_43c524aa37b98b11,@object ; @__hip_cuid_43c524aa37b98b11
	.section	.bss,"aw",@nobits
	.globl	__hip_cuid_43c524aa37b98b11
__hip_cuid_43c524aa37b98b11:
	.byte	0                               ; 0x0
	.size	__hip_cuid_43c524aa37b98b11, 1

	.ident	"AMD clang version 20.0.0git (https://github.com/RadeonOpenCompute/llvm-project roc-7.0.2 25385 0dda3adf56766e0aac0d03173ced3759e1ffecbc)"
	.section	".note.GNU-stack","",@progbits
	.addrsig
	.addrsig_sym __hip_cuid_43c524aa37b98b11
	.amdgpu_metadata
---
amdhsa.kernels:
  - .agpr_count:     0
    .args:
      - .address_space:  global
        .offset:         0
        .size:           8
        .value_kind:     global_buffer
      - .offset:         16
        .size:           64
        .value_kind:     by_value
      - .address_space:  global
        .offset:         80
        .size:           8
        .value_kind:     global_buffer
      - .actual_access:  write_only
        .address_space:  global
        .offset:         88
        .size:           8
        .value_kind:     global_buffer
      - .offset:         96
        .size:           4
        .value_kind:     by_value
      - .offset:         100
        .size:           4
        .value_kind:     by_value
      - .offset:         104
        .size:           4
        .value_kind:     hidden_block_count_x
      - .offset:         108
        .size:           4
        .value_kind:     hidden_block_count_y
      - .offset:         112
        .size:           4
        .value_kind:     hidden_block_count_z
      - .offset:         116
        .size:           2
        .value_kind:     hidden_group_size_x
      - .offset:         118
        .size:           2
        .value_kind:     hidden_group_size_y
      - .offset:         120
        .size:           2
        .value_kind:     hidden_group_size_z
      - .offset:         122
        .size:           2
        .value_kind:     hidden_remainder_x
      - .offset:         124
        .size:           2
        .value_kind:     hidden_remainder_y
      - .offset:         126
        .size:           2
        .value_kind:     hidden_remainder_z
      - .offset:         144
        .size:           8
        .value_kind:     hidden_global_offset_x
      - .offset:         152
        .size:           8
        .value_kind:     hidden_global_offset_y
      - .offset:         160
        .size:           8
        .value_kind:     hidden_global_offset_z
      - .offset:         168
        .size:           2
        .value_kind:     hidden_grid_dims
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 16
    .kernarg_segment_size: 360
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 512
    .name:           _ZN7commkit7kernels26cross_device_reduce_1stageIDF16bLi8EEEvPNS_8RankDataENS_11RankSignalsEPNS_6SignalEPT_ii
    .private_segment_fixed_size: 0
    .sgpr_count:     45
    .sgpr_spill_count: 0
    .symbol:         _ZN7commkit7kernels26cross_device_reduce_1stageIDF16bLi8EEEvPNS_8RankDataENS_11RankSignalsEPNS_6SignalEPT_ii.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     64
    .vgpr_spill_count: 0
    .wavefront_size: 64
amdhsa.target:   amdgcn-amd-amdhsa--gfx942
amdhsa.version:
  - 1
  - 2
...

	.end_amdgpu_metadata
