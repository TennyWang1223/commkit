	.amdgcn_target "amdgcn-amd-amdhsa--gfx942"
	.amdhsa_code_object_version 6
	.section	.text._ZN7commkit7kernels26cross_device_reduce_2stageIDF16bLi8EEEvPNS_8RankDataENS_11RankSignalsEPNS_6SignalEPT_ii,"axG",@progbits,_ZN7commkit7kernels26cross_device_reduce_2stageIDF16bLi8EEEvPNS_8RankDataENS_11RankSignalsEPNS_6SignalEPT_ii,comdat
	.protected	_ZN7commkit7kernels26cross_device_reduce_2stageIDF16bLi8EEEvPNS_8RankDataENS_11RankSignalsEPNS_6SignalEPT_ii ; -- Begin function _ZN7commkit7kernels26cross_device_reduce_2stageIDF16bLi8EEEvPNS_8RankDataENS_11RankSignalsEPNS_6SignalEPT_ii
	.globl	_ZN7commkit7kernels26cross_device_reduce_2stageIDF16bLi8EEEvPNS_8RankDataENS_11RankSignalsEPNS_6SignalEPT_ii
	.p2align	8
	.type	_ZN7commkit7kernels26cross_device_reduce_2stageIDF16bLi8EEEvPNS_8RankDataENS_11RankSignalsEPNS_6SignalEPT_ii,@function
_ZN7commkit7kernels26cross_device_reduce_2stageIDF16bLi8EEEvPNS_8RankDataENS_11RankSignalsEPNS_6SignalEPT_ii: ; @_ZN7commkit7kernels26cross_device_reduce_2stageIDF16bLi8EEEvPNS_8RankDataENS_11RankSignalsEPNS_6SignalEPT_ii
; %bb.0:
	s_load_dwordx2 s[18:19], s[0:1], 0x60
	s_load_dwordx2 s[4:5], s[0:1], 0x0
	s_load_dwordx2 s[20:21], s[0:1], 0x50
	s_add_u32 s24, s0, 16
	s_addc_u32 s25, s1, 0
	s_waitcnt lgkmcnt(0)
	s_ashr_i32 s23, s18, 31
	s_lshr_b32 s3, s23, 29
	s_add_i32 s3, s18, s3
	s_and_b32 s3, s3, -8
	s_sub_i32 s6, s18, s3
	s_ashr_i32 s7, s6, 31
	s_lshl_b64 s[6:7], s[6:7], 3
	s_add_u32 s8, s4, s6
	s_addc_u32 s9, s5, s7
	s_add_u32 s6, s24, s6
	s_addc_u32 s7, s25, s7
	s_add_i32 s3, s18, 1
	s_load_dwordx2 s[38:39], s[8:9], 0x0
	s_load_dword s34, s[0:1], 0x68
	v_cmp_gt_u32_e32 vcc, 8, v0
	s_load_dwordx2 s[8:9], s[6:7], 0x0
	s_ashr_i32 s6, s3, 31
	s_lshr_b32 s6, s6, 29
	s_add_i32 s6, s3, s6
	s_and_b32 s6, s6, -8
	s_sub_i32 s6, s3, s6
	s_ashr_i32 s7, s6, 31
	s_lshl_b64 s[6:7], s[6:7], 3
	s_add_u32 s10, s4, s6
	s_addc_u32 s11, s5, s7
	s_add_u32 s6, s24, s6
	s_addc_u32 s7, s25, s7
	s_add_i32 s3, s18, 2
	s_load_dwordx2 s[40:41], s[10:11], 0x0
	s_ashr_i32 s10, s3, 31
	s_lshr_b32 s10, s10, 29
	s_add_i32 s10, s3, s10
	s_and_b32 s10, s10, -8
	s_sub_i32 s10, s3, s10
	s_ashr_i32 s11, s10, 31
	s_lshl_b64 s[10:11], s[10:11], 3
	s_add_u32 s12, s4, s10
	s_addc_u32 s13, s5, s11
	s_add_u32 s10, s24, s10
	s_addc_u32 s11, s25, s11
	s_add_i32 s3, s18, 3
	s_load_dwordx2 s[42:43], s[12:13], 0x0
	s_ashr_i32 s12, s3, 31
	s_lshr_b32 s12, s12, 29
	s_add_i32 s12, s3, s12
	s_and_b32 s12, s12, -8
	s_sub_i32 s12, s3, s12
	s_ashr_i32 s13, s12, 31
	s_lshl_b64 s[12:13], s[12:13], 3
	s_add_u32 s14, s4, s12
	s_addc_u32 s15, s5, s13
	s_add_u32 s12, s24, s12
	s_addc_u32 s13, s25, s13
	s_add_i32 s3, s18, 4
	s_load_dwordx2 s[44:45], s[14:15], 0x0
	s_ashr_i32 s14, s3, 31
	s_lshr_b32 s14, s14, 29
	s_add_i32 s14, s3, s14
	s_and_b32 s14, s14, -8
	s_sub_i32 s14, s3, s14
	s_ashr_i32 s15, s14, 31
	s_lshl_b64 s[14:15], s[14:15], 3
	s_add_u32 s16, s4, s14
	s_addc_u32 s17, s5, s15
	s_add_u32 s14, s24, s14
	s_addc_u32 s15, s25, s15
	s_add_i32 s3, s18, 5
	s_load_dwordx2 s[46:47], s[16:17], 0x0
	s_ashr_i32 s16, s3, 31
	s_lshr_b32 s16, s16, 29
	s_add_i32 s16, s3, s16
	s_and_b32 s16, s16, -8
	s_sub_i32 s16, s3, s16
	s_ashr_i32 s17, s16, 31
	s_lshl_b64 s[16:17], s[16:17], 3
	s_add_u32 s26, s4, s16
	s_addc_u32 s27, s5, s17
	s_add_u32 s16, s24, s16
	s_addc_u32 s17, s25, s17
	s_add_i32 s3, s18, 6
	s_ashr_i32 s22, s3, 31
	s_lshr_b32 s22, s22, 29
	s_add_i32 s22, s3, s22
	s_and_b32 s22, s22, -8
	s_load_dwordx2 s[48:49], s[26:27], 0x0
	s_sub_i32 s26, s3, s22
	s_ashr_i32 s27, s26, 31
	s_lshl_b64 s[26:27], s[26:27], 3
	s_add_u32 s28, s4, s26
	s_addc_u32 s29, s5, s27
	s_add_u32 s26, s24, s26
	s_addc_u32 s27, s25, s27
	s_add_i32 s3, s18, 7
	s_ashr_i32 s22, s3, 31
	s_lshr_b32 s22, s22, 29
	s_add_i32 s22, s3, s22
	s_and_b32 s22, s22, -8
	s_load_dwordx2 s[54:55], s[26:27], 0x0
	s_sub_i32 s26, s3, s22
	s_ashr_i32 s27, s26, 31
	s_lshl_b64 s[26:27], s[26:27], 3
	s_add_u32 s4, s4, s26
	s_addc_u32 s5, s5, s27
	s_add_u32 s26, s24, s26
	s_mov_b32 s3, 0
	s_load_dwordx2 s[50:51], s[28:29], 0x0
	s_addc_u32 s27, s25, s27
	s_lshl_b64 s[28:29], s[2:3], 2
	s_load_dwordx2 s[6:7], s[6:7], 0x0
	s_add_u32 s28, s20, s28
	s_load_dwordx2 s[10:11], s[10:11], 0x0
	s_addc_u32 s29, s21, s29
	s_load_dwordx2 s[12:13], s[12:13], 0x0
	v_lshlrev_b32_e32 v11, 3, v0
	s_load_dwordx2 s[14:15], s[14:15], 0x0
	v_lshlrev_b32_e32 v2, 2, v0
	s_load_dwordx2 s[16:17], s[16:17], 0x0
	s_nop 0
	s_load_dword s33, s[28:29], 0x1400
	s_load_dwordx2 s[52:53], s[4:5], 0x0
                                        ; kill: killed $sgpr4 killed $sgpr5
	s_load_dwordx2 s[56:57], s[26:27], 0x0
	s_add_u32 s26, s28, 0x1400
	s_addc_u32 s27, s29, 0
	s_waitcnt lgkmcnt(0)
	s_add_i32 s33, s33, 1
	s_and_saveexec_b64 s[28:29], vcc
	s_cbranch_execz .LBB0_3
; %bb.1:
	global_load_dwordx2 v[6:7], v11, s[24:25]
	s_mov_b32 s22, s18
	s_lshl_b64 s[4:5], s[2:3], 5
	s_lshl_b64 s[30:31], s[22:23], 2
	s_add_u32 s30, s30, s4
	s_addc_u32 s31, s31, s5
	s_add_u32 s4, s20, s4
	v_mov_b32_e32 v3, 0
	s_addc_u32 s5, s21, s5
	v_mov_b32_e32 v1, s33
	v_lshl_add_u64 v[4:5], s[4:5], 0, v[2:3]
	s_waitcnt vmcnt(0)
	v_lshl_add_u64 v[6:7], s[30:31], 0, v[6:7]
	s_mov_b64 s[30:31], 0
	global_store_dword v[6:7], v1, off sc0 sc1
.LBB0_2:                                ; =>This Inner Loop Header: Depth=1
	global_load_dword v1, v[4:5], off sc1
	s_waitcnt vmcnt(0)
	v_cmp_le_u32_e64 s[4:5], s33, v1
	s_or_b64 s[30:31], s[4:5], s[30:31]
	s_andn2_b64 exec, exec, s[30:31]
	s_cbranch_execnz .LBB0_2
.LBB0_3:                                ; %Flow131
	s_or_b64 exec, exec, s[28:29]
	s_load_dwordx2 s[28:29], s[0:1], 0x58
	v_cmp_eq_u32_e64 s[0:1], 0, v0
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_saveexec_b64 s[4:5], s[0:1]
	s_cbranch_execz .LBB0_5
; %bb.4:
	v_mov_b32_e32 v1, 0
	v_mov_b32_e32 v3, s33
	global_store_dword v1, v3, s[26:27]
.LBB0_5:                                ; %_ZN7commkit10start_syncILi8EEEvRKNS_11RankSignalsEPNS_6SignalEi.exit
	s_or_b64 exec, exec, s[4:5]
	s_add_u32 s30, s8, 0x1580
	s_addc_u32 s31, s9, 0
	s_ashr_i32 s4, s19, 31
	s_lshr_b32 s4, s4, 29
	s_add_i32 s4, s19, s4
	s_ashr_i32 s58, s4, 3
	s_mul_i32 s4, s58, s18
	v_and_b32_e32 v13, 63, v0
	s_lshl_b32 s33, s2, 6
	s_lshl_b32 s34, s34, 6
	s_add_i32 s5, s4, s58
	v_or_b32_e32 v10, s33, v13
	s_cmp_eq_u32 s18, 7
	s_cselect_b32 s22, s19, s5
	v_add_u32_e32 v4, s4, v10
	v_lshrrev_b32_e32 v12, 6, v0
	v_cmp_gt_i32_e64 s[4:5], s22, v4
	s_and_saveexec_b64 s[36:37], s[4:5]
	s_cbranch_execz .LBB0_8
; %bb.6:                                ; %.lr.ph
	s_add_u32 s35, s6, 0x1580
	s_addc_u32 s59, s7, 0
	s_add_u32 s60, s10, 0x1580
	s_addc_u32 s61, s11, 0
	v_mov_b32_e32 v3, s39
	v_mov_b32_e32 v5, s41
	v_cmp_eq_u32_e64 s[4:5], 1, v12
	s_add_u32 s62, s12, 0x1580
	v_cmp_eq_u32_e64 s[6:7], 2, v12
	v_cndmask_b32_e64 v3, v3, v5, s[4:5]
	v_mov_b32_e32 v5, s43
	s_addc_u32 s63, s13, 0
	v_cndmask_b32_e64 v3, v3, v5, s[6:7]
	v_mov_b32_e32 v5, s45
	v_cmp_eq_u32_e64 s[8:9], 3, v12
	s_add_u32 s64, s14, 0x1580
	v_cmp_eq_u32_e64 s[10:11], 4, v12
	v_cndmask_b32_e64 v3, v3, v5, s[8:9]
	v_mov_b32_e32 v5, s47
	s_addc_u32 s65, s15, 0
	v_cndmask_b32_e64 v3, v3, v5, s[10:11]
	v_mov_b32_e32 v5, s49
	v_cmp_eq_u32_e64 s[12:13], 5, v12
	s_add_u32 s66, s16, 0x1580
	v_cmp_eq_u32_e64 s[14:15], 6, v12
	v_cndmask_b32_e64 v3, v3, v5, s[12:13]
	v_mov_b32_e32 v5, s51
	v_mov_b32_e32 v8, s31
	v_mov_b32_e32 v9, s59
	s_addc_u32 s67, s17, 0
	v_cndmask_b32_e64 v3, v3, v5, s[14:15]
	v_mov_b32_e32 v5, s53
	v_cmp_eq_u32_e64 s[16:17], 7, v12
	v_cndmask_b32_e64 v8, v8, v9, s[4:5]
	v_mov_b32_e32 v9, s61
	s_add_u32 s54, s54, 0x1580
	v_cndmask_b32_e64 v7, v3, v5, s[16:17]
	v_mov_b32_e32 v3, s38
	v_mov_b32_e32 v5, s40
	v_cndmask_b32_e64 v8, v8, v9, s[6:7]
	v_mov_b32_e32 v9, s63
	s_addc_u32 s55, s55, 0
	v_cndmask_b32_e64 v3, v3, v5, s[4:5]
	v_mov_b32_e32 v5, s42
	v_cndmask_b32_e64 v8, v8, v9, s[8:9]
	v_mov_b32_e32 v9, s65
	s_add_u32 s56, s56, 0x1580
	v_cndmask_b32_e64 v3, v3, v5, s[6:7]
	v_mov_b32_e32 v5, s44
	v_cndmask_b32_e64 v8, v8, v9, s[10:11]
	v_mov_b32_e32 v9, s67
	s_addc_u32 s57, s57, 0
	v_cndmask_b32_e64 v3, v3, v5, s[8:9]
	v_mov_b32_e32 v5, s46
	v_cndmask_b32_e64 v8, v8, v9, s[12:13]
	v_mov_b32_e32 v9, s55
	v_cndmask_b32_e64 v3, v3, v5, s[10:11]
	v_mov_b32_e32 v5, s48
	v_cndmask_b32_e64 v8, v8, v9, s[14:15]
	v_mov_b32_e32 v9, s57
	v_cndmask_b32_e64 v3, v3, v5, s[12:13]
	v_mov_b32_e32 v5, s50
	v_cndmask_b32_e64 v9, v8, v9, s[16:17]
	v_mov_b32_e32 v8, s30
	v_mov_b32_e32 v15, s35
	v_cndmask_b32_e64 v3, v3, v5, s[14:15]
	v_mov_b32_e32 v5, s52
	v_cndmask_b32_e64 v8, v8, v15, s[4:5]
	v_mov_b32_e32 v15, s60
	v_lshlrev_b32_e32 v1, 4, v13
	v_cndmask_b32_e64 v6, v3, v5, s[16:17]
	v_and_b32_e32 v5, 0x1c0, v0
	v_cndmask_b32_e64 v8, v8, v15, s[6:7]
	v_mov_b32_e32 v15, s62
	v_lshl_or_b32 v14, v5, 4, v1
	v_cndmask_b32_e64 v8, v8, v15, s[8:9]
	v_mov_b32_e32 v15, s64
	v_xor_b32_e32 v5, 0x100, v5
	v_cndmask_b32_e64 v8, v8, v15, s[10:11]
	v_mov_b32_e32 v15, s66
	v_lshl_or_b32 v18, v5, 4, v1
	v_add_u32_e32 v5, 0x140, v0
	v_cndmask_b32_e64 v8, v8, v15, s[12:13]
	v_mov_b32_e32 v15, s54
	v_and_b32_e32 v5, 0x1c0, v5
	v_cndmask_b32_e64 v8, v8, v15, s[14:15]
	v_mov_b32_e32 v15, s56
	v_lshl_or_b32 v19, v5, 4, v1
	v_add_u32_e32 v5, 0x180, v0
	v_lshlrev_b32_e32 v3, 4, v0
	v_cndmask_b32_e64 v8, v8, v15, s[16:17]
	v_add_u32_e32 v15, 64, v0
	v_add_u32_e32 v16, 0x80, v0
	v_add_u32_e32 v17, 0xc0, v0
	v_and_b32_e32 v5, 0x1c0, v5
	v_add_u32_e32 v0, 0x1c0, v0
	v_and_b32_e32 v15, 0x1c0, v15
	v_and_b32_e32 v16, 0x1c0, v16
	v_and_b32_e32 v17, 0x1c0, v17
	v_lshl_or_b32 v20, v5, 4, v1
	v_and_b32_e32 v0, 0x1c0, v0
	v_ashrrev_i32_e32 v5, 31, v4
	s_ashr_i32 s35, s34, 31
	v_lshl_or_b32 v15, v15, 4, v1
	v_lshl_or_b32 v16, v16, 4, v1
	v_lshl_or_b32 v17, v17, 4, v1
	v_lshl_or_b32 v21, v0, 4, v1
	v_lshlrev_b64 v[0:1], 4, v[4:5]
	s_lshl_b64 s[6:7], s[34:35], 4
	s_mov_b64 s[8:9], 0
	s_mov_b32 s10, 0x7060302
.LBB0_7:                                ; %.preheader87.preheader
                                        ; =>This Inner Loop Header: Depth=1
	v_lshl_add_u64 v[22:23], v[6:7], 0, v[0:1]
	flat_load_dwordx4 v[22:25], v[22:23]
	v_add_u32_e32 v4, s34, v4
	v_cmp_le_i32_e64 s[4:5], s22, v4
	s_or_b64 s[8:9], s[4:5], s[8:9]
	s_waitcnt vmcnt(0) lgkmcnt(0)
	ds_write_b128 v3, v[22:25]
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read_b128 v[22:25], v14
	s_waitcnt lgkmcnt(0)
	v_and_b32_e32 v47, 0xffff0000, v22
	v_lshlrev_b32_e32 v46, 16, v22
	v_and_b32_e32 v49, 0xffff0000, v23
	v_lshlrev_b32_e32 v48, 16, v23
	v_and_b32_e32 v51, 0xffff0000, v24
	v_lshlrev_b32_e32 v50, 16, v24
	v_and_b32_e32 v53, 0xffff0000, v25
	v_lshlrev_b32_e32 v52, 16, v25
	ds_read_b128 v[22:25], v15
	s_waitcnt lgkmcnt(0)
	v_and_b32_e32 v55, 0xffff0000, v22
	v_lshlrev_b32_e32 v54, 16, v22
	v_and_b32_e32 v57, 0xffff0000, v23
	v_lshlrev_b32_e32 v56, 16, v23
	v_and_b32_e32 v59, 0xffff0000, v24
	v_lshlrev_b32_e32 v58, 16, v24
	v_and_b32_e32 v61, 0xffff0000, v25
	v_lshlrev_b32_e32 v60, 16, v25
	ds_read_b128 v[22:25], v16
	ds_read_b128 v[26:29], v17
	ds_read_b128 v[30:33], v18
	ds_read_b128 v[34:37], v19
	ds_read_b128 v[38:41], v20
	ds_read_b128 v[42:45], v21
	v_pk_add_f32 v[46:47], v[46:47], v[54:55]
	s_waitcnt lgkmcnt(5)
	v_and_b32_e32 v55, 0xffff0000, v22
	v_lshlrev_b32_e32 v54, 16, v22
	v_pk_add_f32 v[46:47], v[46:47], v[54:55]
	s_waitcnt lgkmcnt(4)
	v_and_b32_e32 v55, 0xffff0000, v26
	v_lshlrev_b32_e32 v54, 16, v26
	v_pk_add_f32 v[46:47], v[46:47], v[54:55]
	s_waitcnt lgkmcnt(3)
	v_and_b32_e32 v55, 0xffff0000, v30
	v_lshlrev_b32_e32 v54, 16, v30
	v_pk_add_f32 v[46:47], v[46:47], v[54:55]
	s_waitcnt lgkmcnt(2)
	v_and_b32_e32 v55, 0xffff0000, v34
	v_lshlrev_b32_e32 v54, 16, v34
	v_pk_add_f32 v[46:47], v[46:47], v[54:55]
	s_waitcnt lgkmcnt(1)
	v_and_b32_e32 v55, 0xffff0000, v38
	v_lshlrev_b32_e32 v54, 16, v38
	v_pk_add_f32 v[46:47], v[46:47], v[54:55]
	s_waitcnt lgkmcnt(0)
	v_and_b32_e32 v55, 0xffff0000, v42
	v_lshlrev_b32_e32 v54, 16, v42
	v_pk_add_f32 v[46:47], v[46:47], v[54:55]
	v_pk_add_f32 v[48:49], v[48:49], v[56:57]
	v_and_b32_e32 v55, 0xffff0000, v23
	v_lshlrev_b32_e32 v54, 16, v23
	v_pk_add_f32 v[22:23], v[48:49], v[54:55]
	v_and_b32_e32 v49, 0xffff0000, v27
	v_lshlrev_b32_e32 v48, 16, v27
	v_pk_add_f32 v[22:23], v[22:23], v[48:49]
	v_and_b32_e32 v27, 0xffff0000, v31
	v_lshlrev_b32_e32 v26, 16, v31
	v_pk_add_f32 v[22:23], v[22:23], v[26:27]
	v_and_b32_e32 v27, 0xffff0000, v35
	v_lshlrev_b32_e32 v26, 16, v35
	v_pk_add_f32 v[22:23], v[22:23], v[26:27]
	v_and_b32_e32 v27, 0xffff0000, v39
	v_lshlrev_b32_e32 v26, 16, v39
	v_pk_add_f32 v[22:23], v[22:23], v[26:27]
	v_and_b32_e32 v27, 0xffff0000, v43
	v_lshlrev_b32_e32 v26, 16, v43
	v_pk_add_f32 v[22:23], v[22:23], v[26:27]
	v_pk_add_f32 v[26:27], v[50:51], v[58:59]
	v_and_b32_e32 v31, 0xffff0000, v24
	v_lshlrev_b32_e32 v30, 16, v24
	v_pk_add_f32 v[26:27], v[26:27], v[30:31]
	v_and_b32_e32 v31, 0xffff0000, v28
	v_lshlrev_b32_e32 v30, 16, v28
	v_pk_add_f32 v[26:27], v[26:27], v[30:31]
	v_and_b32_e32 v31, 0xffff0000, v32
	v_lshlrev_b32_e32 v30, 16, v32
	v_pk_add_f32 v[26:27], v[26:27], v[30:31]
	v_and_b32_e32 v31, 0xffff0000, v36
	v_lshlrev_b32_e32 v30, 16, v36
	v_pk_add_f32 v[26:27], v[26:27], v[30:31]
	v_and_b32_e32 v31, 0xffff0000, v40
	v_lshlrev_b32_e32 v30, 16, v40
	v_pk_add_f32 v[26:27], v[26:27], v[30:31]
	v_and_b32_e32 v31, 0xffff0000, v44
	v_lshlrev_b32_e32 v30, 16, v44
	v_pk_add_f32 v[26:27], v[26:27], v[30:31]
	v_pk_add_f32 v[30:31], v[52:53], v[60:61]
	v_and_b32_e32 v35, 0xffff0000, v25
	v_lshlrev_b32_e32 v34, 16, v25
	v_pk_add_f32 v[24:25], v[30:31], v[34:35]
	v_and_b32_e32 v31, 0xffff0000, v29
	v_lshlrev_b32_e32 v30, 16, v29
	v_pk_add_f32 v[24:25], v[24:25], v[30:31]
	v_and_b32_e32 v29, 0xffff0000, v33
	v_lshlrev_b32_e32 v28, 16, v33
	v_pk_add_f32 v[24:25], v[24:25], v[28:29]
	v_and_b32_e32 v29, 0xffff0000, v37
	v_lshlrev_b32_e32 v28, 16, v37
	v_pk_add_f32 v[24:25], v[24:25], v[28:29]
	v_and_b32_e32 v29, 0xffff0000, v41
	v_lshlrev_b32_e32 v28, 16, v41
	v_pk_add_f32 v[24:25], v[24:25], v[28:29]
	v_and_b32_e32 v29, 0xffff0000, v45
	v_lshlrev_b32_e32 v28, 16, v45
	v_pk_add_f32 v[24:25], v[24:25], v[28:29]
	v_perm_b32 v23, v23, v22, s10
	v_perm_b32 v25, v25, v24, s10
	v_perm_b32 v24, v27, v26, s10
	v_perm_b32 v22, v47, v46, s10
	v_lshl_add_u64 v[26:27], v[8:9], 0, v[0:1]
	v_lshl_add_u64 v[0:1], v[0:1], 0, s[6:7]
	flat_store_dwordx4 v[26:27], v[22:25]
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_andn2_b64 exec, exec, s[8:9]
	s_cbranch_execnz .LBB0_7
.LBB0_8:                                ; %Flow129
	s_or_b64 exec, exec, s[36:37]
	v_mov_b32_e32 v3, 0
	s_barrier
	global_load_dword v0, v3, s[26:27]
	s_waitcnt vmcnt(0)
	v_add_u32_e32 v4, 1, v0
	s_and_saveexec_b64 s[4:5], vcc
	s_cbranch_execz .LBB0_11
; %bb.9:
	global_load_dwordx2 v[0:1], v11, s[24:25]
	s_mov_b32 s22, s18
	s_lshl_b64 s[2:3], s[2:3], 5
	s_lshl_b64 s[8:9], s[22:23], 2
	s_add_u32 s8, s8, s2
	s_addc_u32 s9, s9, s3
	s_add_u32 s2, s20, s2
	s_mov_b64 s[6:7], 0xa00
	s_addc_u32 s3, s21, s3
	s_add_u32 s2, s2, 0xa00
	s_addc_u32 s3, s3, 0
	s_waitcnt vmcnt(0)
	v_lshl_add_u64 v[0:1], v[0:1], 0, s[8:9]
	v_lshl_add_u64 v[6:7], v[0:1], 0, s[6:7]
	;;#ASMSTART
	buffer_wbl2 sc0 sc1
	global_store_dword v[6:7], v4, off sc0 sc1
	
	;;#ASMEND
	v_lshl_add_u64 v[0:1], s[2:3], 0, v[2:3]
	s_mov_b64 s[2:3], 0
.LBB0_10:                               ; =>This Inner Loop Header: Depth=1
	;;#ASMSTART
	global_load_dword v2, v[0:1], off sc1
	s_waitcnt vmcnt(0)
	
	;;#ASMEND
	s_nop 0
	v_cmp_ge_u32_e32 vcc, v2, v4
	s_or_b64 s[2:3], vcc, s[2:3]
	s_andn2_b64 exec, exec, s[2:3]
	s_cbranch_execnz .LBB0_10
.LBB0_11:                               ; %Flow127
	s_or_b64 exec, exec, s[4:5]
	s_barrier
	s_and_saveexec_b64 s[2:3], s[0:1]
	s_cbranch_execz .LBB0_13
; %bb.12:
	v_mov_b32_e32 v0, 0
	global_store_dword v0, v4, s[26:27]
.LBB0_13:                               ; %_ZN7commkit12end_sync_asmILi8ELb1ELb0EEEvRKNS_11RankSignalsEPNS_6SignalEi.exit
	s_or_b64 exec, exec, s[2:3]
	s_mul_i32 s4, s58, -7
	s_add_i32 s4, s4, s19
	v_cmp_gt_i32_e32 vcc, s4, v10
	s_and_saveexec_b64 s[0:1], vcc
	s_cbranch_execz .LBB0_16
; %bb.14:                               ; %.lr.ph105
	v_mul_lo_u32 v0, s58, v12
	v_add3_u32 v0, v0, s33, v13
	v_ashrrev_i32_e32 v1, 31, v0
	s_ashr_i32 s35, s34, 31
	v_lshlrev_b64 v[0:1], 4, v[0:1]
	s_lshl_b64 s[0:1], s[34:35], 4
	s_mov_b64 s[2:3], 0
.LBB0_15:                               ; =>This Inner Loop Header: Depth=1
	v_lshl_add_u64 v[2:3], s[30:31], 0, v[0:1]
	global_load_dwordx4 v[2:5], v[2:3], off
	v_add_u32_e32 v10, s34, v10
	v_cmp_le_i32_e32 vcc, s4, v10
	v_lshl_add_u64 v[6:7], s[28:29], 0, v[0:1]
	v_lshl_add_u64 v[0:1], v[0:1], 0, s[0:1]
	s_or_b64 s[2:3], vcc, s[2:3]
	s_waitcnt vmcnt(0)
	global_store_dwordx4 v[6:7], v[2:5], off
	s_andn2_b64 exec, exec, s[2:3]
	s_cbranch_execnz .LBB0_15
.LBB0_16:                               ; %Flow125
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel _ZN7commkit7kernels26cross_device_reduce_2stageIDF16bLi8EEEvPNS_8RankDataENS_11RankSignalsEPNS_6SignalEPT_ii
		.amdhsa_group_segment_fixed_size 8192
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
		.amdhsa_next_free_vgpr 62
		.amdhsa_next_free_sgpr 68
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
	.section	.text._ZN7commkit7kernels26cross_device_reduce_2stageIDF16bLi8EEEvPNS_8RankDataENS_11RankSignalsEPNS_6SignalEPT_ii,"axG",@progbits,_ZN7commkit7kernels26cross_device_reduce_2stageIDF16bLi8EEEvPNS_8RankDataENS_11RankSignalsEPNS_6SignalEPT_ii,comdat
.Lfunc_end0:
	.size	_ZN7commkit7kernels26cross_device_reduce_2stageIDF16bLi8EEEvPNS_8RankDataENS_11RankSignalsEPNS_6SignalEPT_ii, .Lfunc_end0-_ZN7commkit7kernels26cross_device_reduce_2stageIDF16bLi8EEEvPNS_8RankDataENS_11RankSignalsEPNS_6SignalEPT_ii
                                        ; -- End function
	.set _ZN7commkit7kernels26cross_device_reduce_2stageIDF16bLi8EEEvPNS_8RankDataENS_11RankSignalsEPNS_6SignalEPT_ii.num_vgpr, 62
	.set _ZN7commkit7kernels26cross_device_reduce_2stageIDF16bLi8EEEvPNS_8RankDataENS_11RankSignalsEPNS_6SignalEPT_ii.num_agpr, 0
	.set _ZN7commkit7kernels26cross_device_reduce_2stageIDF16bLi8EEEvPNS_8RankDataENS_11RankSignalsEPNS_6SignalEPT_ii.numbered_sgpr, 68
	.set _ZN7commkit7kernels26cross_device_reduce_2stageIDF16bLi8EEEvPNS_8RankDataENS_11RankSignalsEPNS_6SignalEPT_ii.private_seg_size, 0
	.set _ZN7commkit7kernels26cross_device_reduce_2stageIDF16bLi8EEEvPNS_8RankDataENS_11RankSignalsEPNS_6SignalEPT_ii.uses_vcc, 1
	.set _ZN7commkit7kernels26cross_device_reduce_2stageIDF16bLi8EEEvPNS_8RankDataENS_11RankSignalsEPNS_6SignalEPT_ii.uses_flat_scratch, 0
	.set _ZN7commkit7kernels26cross_device_reduce_2stageIDF16bLi8EEEvPNS_8RankDataENS_11RankSignalsEPNS_6SignalEPT_ii.has_dyn_sized_stack, 0
	.set _ZN7commkit7kernels26cross_device_reduce_2stageIDF16bLi8EEEvPNS_8RankDataENS_11RankSignalsEPNS_6SignalEPT_ii.has_recursion, 0
	.set _ZN7commkit7kernels26cross_device_reduce_2stageIDF16bLi8EEEvPNS_8RankDataENS_11RankSignalsEPNS_6SignalEPT_ii.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 2736
; TotalNumSgprs: 74
; NumVgprs: 62
; NumAgprs: 0
; TotalNumVgprs: 62
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 8192 bytes/workgroup (compile time only)
; SGPRBlocks: 9
; VGPRBlocks: 7
; NumSGPRsForWavesPerEU: 74
; NumVGPRsForWavesPerEU: 62
; AccumOffset: 64
; Occupancy: 8
; WaveLimiterHint : 0
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
	.type	__hip_cuid_e44c92566f0ed516,@object ; @__hip_cuid_e44c92566f0ed516
	.section	.bss,"aw",@nobits
	.globl	__hip_cuid_e44c92566f0ed516
__hip_cuid_e44c92566f0ed516:
	.byte	0                               ; 0x0
	.size	__hip_cuid_e44c92566f0ed516, 1

	.ident	"AMD clang version 20.0.0git (https://github.com/RadeonOpenCompute/llvm-project roc-7.0.2 25385 0dda3adf56766e0aac0d03173ced3759e1ffecbc)"
	.section	".note.GNU-stack","",@progbits
	.addrsig
	.addrsig_sym __hip_cuid_e44c92566f0ed516
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
    .group_segment_fixed_size: 8192
    .kernarg_segment_align: 16
    .kernarg_segment_size: 360
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 512
    .name:           _ZN7commkit7kernels26cross_device_reduce_2stageIDF16bLi8EEEvPNS_8RankDataENS_11RankSignalsEPNS_6SignalEPT_ii
    .private_segment_fixed_size: 0
    .sgpr_count:     74
    .sgpr_spill_count: 0
    .symbol:         _ZN7commkit7kernels26cross_device_reduce_2stageIDF16bLi8EEEvPNS_8RankDataENS_11RankSignalsEPNS_6SignalEPT_ii.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     62
    .vgpr_spill_count: 0
    .wavefront_size: 64
amdhsa.target:   amdgcn-amd-amdhsa--gfx942
amdhsa.version:
  - 1
  - 2
...

	.end_amdgpu_metadata
