	.amdgcn_target "amdgcn-amd-amdhsa--gfx942"
	.amdhsa_code_object_version 6
	.section	.text._ZN7commkit7kernels26cross_device_reduce_2stageIDF16bLi8EEEvPNS_8RankDataES3_NS_11RankSignalsEPNS_6SignalEPT_ii,"axG",@progbits,_ZN7commkit7kernels26cross_device_reduce_2stageIDF16bLi8EEEvPNS_8RankDataES3_NS_11RankSignalsEPNS_6SignalEPT_ii,comdat
	.protected	_ZN7commkit7kernels26cross_device_reduce_2stageIDF16bLi8EEEvPNS_8RankDataES3_NS_11RankSignalsEPNS_6SignalEPT_ii ; -- Begin function _ZN7commkit7kernels26cross_device_reduce_2stageIDF16bLi8EEEvPNS_8RankDataES3_NS_11RankSignalsEPNS_6SignalEPT_ii
	.globl	_ZN7commkit7kernels26cross_device_reduce_2stageIDF16bLi8EEEvPNS_8RankDataES3_NS_11RankSignalsEPNS_6SignalEPT_ii
	.p2align	8
	.type	_ZN7commkit7kernels26cross_device_reduce_2stageIDF16bLi8EEEvPNS_8RankDataES3_NS_11RankSignalsEPNS_6SignalEPT_ii,@function
_ZN7commkit7kernels26cross_device_reduce_2stageIDF16bLi8EEEvPNS_8RankDataES3_NS_11RankSignalsEPNS_6SignalEPT_ii: ; @_ZN7commkit7kernels26cross_device_reduce_2stageIDF16bLi8EEEvPNS_8RankDataES3_NS_11RankSignalsEPNS_6SignalEPT_ii
; %bb.0:
	s_load_dwordx2 s[18:19], s[0:1], 0x60
	s_load_dwordx4 s[20:23], s[0:1], 0x50
	s_load_dwordx2 s[4:5], s[0:1], 0x0
	s_add_u32 s34, s0, 16
	s_addc_u32 s35, s1, 0
	s_waitcnt lgkmcnt(0)
	s_ashr_i32 s31, s18, 31
	s_load_dword s8, s[0:1], 0x68
	s_lshr_b32 s0, s31, 29
	s_add_i32 s0, s18, s0
	s_and_b32 s0, s0, -8
	s_sub_i32 s0, s18, s0
	s_ashr_i32 s1, s0, 31
	s_lshl_b64 s[0:1], s[0:1], 3
	s_add_u32 s6, s4, s0
	s_addc_u32 s7, s5, s1
	s_add_u32 s0, s34, s0
	s_addc_u32 s1, s35, s1
	s_load_dwordx2 s[24:25], s[0:1], 0x0
	s_add_i32 s0, s18, 1
	s_ashr_i32 s1, s0, 31
	s_lshr_b32 s1, s1, 29
	s_add_i32 s1, s0, s1
	s_and_b32 s1, s1, -8
	s_sub_i32 s0, s0, s1
	s_ashr_i32 s1, s0, 31
	s_lshl_b64 s[0:1], s[0:1], 3
	s_load_dwordx2 s[52:53], s[6:7], 0x0
	s_add_u32 s6, s4, s0
	s_addc_u32 s7, s5, s1
	s_add_u32 s0, s34, s0
	s_addc_u32 s1, s35, s1
	s_load_dwordx2 s[26:27], s[0:1], 0x0
	s_add_i32 s0, s18, 2
	s_ashr_i32 s1, s0, 31
	s_lshr_b32 s1, s1, 29
	s_add_i32 s1, s0, s1
	s_and_b32 s1, s1, -8
	s_sub_i32 s0, s0, s1
	s_ashr_i32 s1, s0, 31
	s_lshl_b64 s[0:1], s[0:1], 3
	s_load_dwordx2 s[54:55], s[6:7], 0x0
	s_add_u32 s6, s4, s0
	s_addc_u32 s7, s5, s1
	s_add_u32 s0, s34, s0
	s_addc_u32 s1, s35, s1
	s_load_dwordx2 s[28:29], s[0:1], 0x0
	s_add_i32 s0, s18, 3
	s_ashr_i32 s1, s0, 31
	s_lshr_b32 s1, s1, 29
	s_add_i32 s1, s0, s1
	s_and_b32 s1, s1, -8
	s_sub_i32 s0, s0, s1
	s_ashr_i32 s1, s0, 31
	s_lshl_b64 s[0:1], s[0:1], 3
	s_load_dwordx2 s[56:57], s[6:7], 0x0
	s_add_u32 s6, s4, s0
	s_addc_u32 s7, s5, s1
	s_add_u32 s0, s34, s0
	s_addc_u32 s1, s35, s1
	s_load_dwordx2 s[36:37], s[0:1], 0x0
	s_add_i32 s0, s18, 4
	s_ashr_i32 s1, s0, 31
	s_lshr_b32 s1, s1, 29
	s_add_i32 s1, s0, s1
	s_and_b32 s1, s1, -8
	s_sub_i32 s0, s0, s1
	s_ashr_i32 s1, s0, 31
	s_lshl_b64 s[0:1], s[0:1], 3
	s_load_dwordx2 s[58:59], s[6:7], 0x0
	s_add_u32 s6, s4, s0
	s_addc_u32 s7, s5, s1
	s_add_u32 s0, s34, s0
	s_addc_u32 s1, s35, s1
	s_load_dwordx2 s[38:39], s[0:1], 0x0
	s_add_i32 s0, s18, 5
	s_ashr_i32 s1, s0, 31
	s_lshr_b32 s1, s1, 29
	s_add_i32 s1, s0, s1
	s_and_b32 s1, s1, -8
	s_sub_i32 s0, s0, s1
	s_ashr_i32 s1, s0, 31
	s_lshl_b64 s[0:1], s[0:1], 3
	s_load_dwordx2 s[60:61], s[6:7], 0x0
	s_add_u32 s6, s4, s0
	s_addc_u32 s7, s5, s1
	s_add_u32 s0, s34, s0
	s_addc_u32 s1, s35, s1
	s_load_dwordx2 s[40:41], s[0:1], 0x0
	s_add_i32 s0, s18, 6
	s_ashr_i32 s1, s0, 31
	s_lshr_b32 s1, s1, 29
	s_add_i32 s1, s0, s1
	s_and_b32 s1, s1, -8
	s_sub_i32 s0, s0, s1
	s_ashr_i32 s1, s0, 31
	s_lshl_b64 s[0:1], s[0:1], 3
	s_load_dwordx2 s[62:63], s[6:7], 0x0
	s_add_u32 s6, s4, s0
	s_addc_u32 s7, s5, s1
	s_add_u32 s0, s34, s0
	s_addc_u32 s1, s35, s1
	s_load_dwordx2 s[42:43], s[0:1], 0x0
	s_add_i32 s0, s18, 7
	s_ashr_i32 s1, s0, 31
	s_lshr_b32 s1, s1, 29
	s_add_i32 s1, s0, s1
	s_and_b32 s1, s1, -8
	s_sub_i32 s0, s0, s1
	s_ashr_i32 s1, s0, 31
	s_lshl_b64 s[0:1], s[0:1], 3
	s_add_u32 s4, s4, s0
	s_addc_u32 s5, s5, s1
	s_add_u32 s0, s34, s0
	s_mov_b32 s3, 0
	s_load_dwordx2 s[64:65], s[6:7], 0x0
	s_addc_u32 s1, s35, s1
	s_lshl_b64 s[6:7], s[2:3], 2
	s_add_u32 s6, s20, s6
	s_addc_u32 s7, s21, s7
	s_load_dword s9, s[6:7], 0x1400
	s_load_dwordx2 s[66:67], s[4:5], 0x0
                                        ; kill: killed $sgpr4 killed $sgpr5
	s_load_dwordx2 s[46:47], s[0:1], 0x0
	s_add_u32 s48, s6, 0x1400
	s_addc_u32 s49, s7, 0
	s_waitcnt lgkmcnt(0)
	s_add_i32 s9, s9, 1
	v_cmp_gt_u32_e32 vcc, 8, v0
	v_lshlrev_b32_e32 v11, 3, v0
	v_lshlrev_b32_e32 v2, 2, v0
	s_and_saveexec_b64 s[4:5], vcc
	s_cbranch_execz .LBB0_3
; %bb.1:
	global_load_dwordx2 v[6:7], v11, s[34:35]
	s_mov_b32 s30, s18
	s_lshl_b64 s[0:1], s[2:3], 5
	s_lshl_b64 s[6:7], s[30:31], 2
	s_add_u32 s6, s6, s0
	s_addc_u32 s7, s7, s1
	s_add_u32 s0, s20, s0
	v_mov_b32_e32 v3, 0
	s_addc_u32 s1, s21, s1
	v_mov_b32_e32 v1, s9
	v_lshl_add_u64 v[4:5], s[0:1], 0, v[2:3]
	s_waitcnt vmcnt(0)
	v_lshl_add_u64 v[6:7], s[6:7], 0, v[6:7]
	s_mov_b64 s[6:7], 0
	global_store_dword v[6:7], v1, off sc0 sc1
.LBB0_2:                                ; =>This Inner Loop Header: Depth=1
	global_load_dword v1, v[4:5], off sc1
	s_waitcnt vmcnt(0)
	v_cmp_le_u32_e64 s[0:1], s9, v1
	s_or_b64 s[6:7], s[0:1], s[6:7]
	s_andn2_b64 exec, exec, s[6:7]
	s_cbranch_execnz .LBB0_2
.LBB0_3:                                ; %Flow162
	s_or_b64 exec, exec, s[4:5]
	v_cmp_eq_u32_e64 s[0:1], 0, v0
	s_barrier
	s_and_saveexec_b64 s[4:5], s[0:1]
	s_cbranch_execz .LBB0_5
; %bb.4:
	v_mov_b32_e32 v1, 0
	v_mov_b32_e32 v3, s9
	global_store_dword v1, v3, s[48:49]
.LBB0_5:                                ; %_ZN7commkit10start_syncILi8EEEvRKNS_11RankSignalsEPNS_6SignalEi.exit
	s_or_b64 exec, exec, s[4:5]
	s_ashr_i32 s4, s19, 31
	s_lshr_b32 s4, s4, 29
	s_add_i32 s4, s19, s4
	s_ashr_i32 s33, s4, 3
	s_mul_i32 s68, s33, s18
	v_and_b32_e32 v9, 63, v0
	s_lshl_b32 s70, s2, 6
	s_lshl_b32 s44, s8, 6
	s_add_i32 s4, s68, s33
	v_or_b32_e32 v8, s70, v9
	s_cmp_eq_u32 s18, 7
	s_cselect_b32 s30, s19, s4
	v_add_u32_e32 v4, s68, v8
	v_lshrrev_b32_e32 v10, 6, v0
	v_cmp_gt_i32_e64 s[4:5], s30, v4
	s_and_saveexec_b64 s[50:51], s[4:5]
	s_cbranch_execz .LBB0_10
; %bb.6:                                ; %.lr.ph
	v_mov_b32_e32 v1, s53
	v_mov_b32_e32 v3, s55
	v_cmp_eq_u32_e64 s[4:5], 1, v10
	v_cmp_eq_u32_e64 s[6:7], 2, v10
	v_cmp_eq_u32_e64 s[8:9], 3, v10
	v_cndmask_b32_e64 v1, v1, v3, s[4:5]
	v_mov_b32_e32 v3, s57
	v_cndmask_b32_e64 v1, v1, v3, s[6:7]
	v_mov_b32_e32 v3, s59
	v_cndmask_b32_e64 v1, v1, v3, s[8:9]
	v_mov_b32_e32 v3, s61
	v_cmp_eq_u32_e64 s[10:11], 4, v10
	v_cmp_eq_u32_e64 s[12:13], 5, v10
	v_cmp_eq_u32_e64 s[14:15], 6, v10
	v_cndmask_b32_e64 v1, v1, v3, s[10:11]
	v_mov_b32_e32 v3, s63
	v_cndmask_b32_e64 v1, v1, v3, s[12:13]
	v_mov_b32_e32 v3, s65
	v_cndmask_b32_e64 v1, v1, v3, s[14:15]
	v_mov_b32_e32 v3, s67
	v_cmp_eq_u32_e64 s[16:17], 7, v10
	s_ashr_i32 s69, s68, 31
	v_ashrrev_i32_e32 v5, 31, v4
	v_cndmask_b32_e64 v7, v1, v3, s[16:17]
	v_mov_b32_e32 v1, s52
	v_mov_b32_e32 v3, s54
	v_cndmask_b32_e64 v1, v1, v3, s[4:5]
	v_mov_b32_e32 v3, s56
	v_cndmask_b32_e64 v1, v1, v3, s[6:7]
	v_mov_b32_e32 v3, s58
	s_lshl_b64 s[6:7], s[68:69], 4
	v_cndmask_b32_e64 v1, v1, v3, s[8:9]
	v_mov_b32_e32 v3, s60
	s_sub_u32 s6, s24, s6
	v_cndmask_b32_e64 v1, v1, v3, s[10:11]
	v_mov_b32_e32 v3, s62
	s_subb_u32 s7, s25, s7
	v_cndmask_b32_e64 v1, v1, v3, s[12:13]
	v_mov_b32_e32 v3, s64
	s_add_u32 s8, s6, 0x1780
	v_cndmask_b32_e64 v1, v1, v3, s[14:15]
	v_mov_b32_e32 v3, s66
	s_addc_u32 s9, s7, 0
	s_ashr_i32 s45, s44, 31
	v_cndmask_b32_e64 v6, v1, v3, s[16:17]
	v_lshlrev_b32_e32 v3, 4, v0
	v_cmp_gt_u32_e64 s[4:5], 64, v0
	v_lshlrev_b64 v[0:1], 4, v[4:5]
	s_lshl_b64 s[10:11], s[44:45], 4
	s_mov_b64 s[12:13], 0
	s_mov_b32 s14, 0x7060302
	s_branch .LBB0_8
.LBB0_7:                                ;   in Loop: Header=BB0_8 Depth=1
	s_or_b64 exec, exec, s[6:7]
	v_add_u32_e32 v4, s44, v4
	v_cmp_le_i32_e64 s[6:7], s30, v4
	s_or_b64 s[12:13], s[6:7], s[12:13]
	v_lshl_add_u64 v[0:1], v[0:1], 0, s[10:11]
	s_barrier
	s_andn2_b64 exec, exec, s[12:13]
	s_cbranch_execz .LBB0_10
.LBB0_8:                                ; =>This Inner Loop Header: Depth=1
	v_lshl_add_u64 v[12:13], v[6:7], 0, v[0:1]
	flat_load_dwordx4 v[12:15], v[12:13]
	s_waitcnt vmcnt(0) lgkmcnt(0)
	ds_write_b128 v3, v[12:15]
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_saveexec_b64 s[6:7], s[4:5]
	s_cbranch_execz .LBB0_7
; %bb.9:                                ; %.preheader86.preheader
                                        ;   in Loop: Header=BB0_8 Depth=1
	ds_read_b128 v[12:15], v3
	ds_read_b128 v[16:19], v3 offset:1024
	ds_read_b128 v[32:35], v3 offset:7168
	s_waitcnt lgkmcnt(2)
	v_and_b32_e32 v21, 0xffff0000, v12
	v_lshlrev_b32_e32 v20, 16, v12
	v_and_b32_e32 v37, 0xffff0000, v13
	v_lshlrev_b32_e32 v36, 16, v13
	v_and_b32_e32 v39, 0xffff0000, v14
	v_lshlrev_b32_e32 v38, 16, v14
	v_and_b32_e32 v41, 0xffff0000, v15
	v_lshlrev_b32_e32 v40, 16, v15
	ds_read_b128 v[12:15], v3 offset:2048
	s_waitcnt lgkmcnt(2)
	v_and_b32_e32 v23, 0xffff0000, v16
	v_lshlrev_b32_e32 v22, 16, v16
	v_and_b32_e32 v43, 0xffff0000, v17
	v_lshlrev_b32_e32 v42, 16, v17
	v_and_b32_e32 v45, 0xffff0000, v18
	v_lshlrev_b32_e32 v44, 16, v18
	v_and_b32_e32 v47, 0xffff0000, v19
	v_lshlrev_b32_e32 v46, 16, v19
	ds_read_b128 v[16:19], v3 offset:3072
	v_pk_add_f32 v[20:21], v[20:21], v[22:23]
	s_waitcnt lgkmcnt(1)
	v_and_b32_e32 v23, 0xffff0000, v12
	v_lshlrev_b32_e32 v22, 16, v12
	v_pk_add_f32 v[24:25], v[20:21], v[22:23]
	ds_read_b128 v[20:23], v3 offset:4096
	s_waitcnt lgkmcnt(1)
	v_and_b32_e32 v27, 0xffff0000, v16
	v_lshlrev_b32_e32 v26, 16, v16
	v_pk_add_f32 v[28:29], v[24:25], v[26:27]
	ds_read_b128 v[24:27], v3 offset:5120
	s_waitcnt lgkmcnt(1)
	v_and_b32_e32 v31, 0xffff0000, v20
	v_lshlrev_b32_e32 v30, 16, v20
	v_pk_add_f32 v[48:49], v[28:29], v[30:31]
	ds_read_b128 v[28:31], v3 offset:6144
	v_pk_add_f32 v[36:37], v[36:37], v[42:43]
	v_and_b32_e32 v43, 0xffff0000, v13
	v_lshlrev_b32_e32 v42, 16, v13
	v_pk_add_f32 v[12:13], v[36:37], v[42:43]
	v_and_b32_e32 v37, 0xffff0000, v17
	v_lshlrev_b32_e32 v36, 16, v17
	v_pk_add_f32 v[12:13], v[12:13], v[36:37]
	v_and_b32_e32 v17, 0xffff0000, v21
	v_lshlrev_b32_e32 v16, 16, v21
	v_pk_add_f32 v[12:13], v[12:13], v[16:17]
	s_waitcnt lgkmcnt(1)
	v_and_b32_e32 v17, 0xffff0000, v25
	v_lshlrev_b32_e32 v16, 16, v25
	v_pk_add_f32 v[12:13], v[12:13], v[16:17]
	s_waitcnt lgkmcnt(0)
	v_and_b32_e32 v17, 0xffff0000, v29
	v_lshlrev_b32_e32 v16, 16, v29
	v_pk_add_f32 v[12:13], v[12:13], v[16:17]
	v_and_b32_e32 v17, 0xffff0000, v33
	v_lshlrev_b32_e32 v16, 16, v33
	v_pk_add_f32 v[12:13], v[12:13], v[16:17]
	v_pk_add_f32 v[16:17], v[38:39], v[44:45]
	v_and_b32_e32 v21, 0xffff0000, v14
	v_lshlrev_b32_e32 v20, 16, v14
	v_pk_add_f32 v[16:17], v[16:17], v[20:21]
	v_and_b32_e32 v21, 0xffff0000, v18
	v_lshlrev_b32_e32 v20, 16, v18
	v_pk_add_f32 v[16:17], v[16:17], v[20:21]
	v_and_b32_e32 v21, 0xffff0000, v22
	v_lshlrev_b32_e32 v20, 16, v22
	v_pk_add_f32 v[16:17], v[16:17], v[20:21]
	v_and_b32_e32 v21, 0xffff0000, v26
	v_lshlrev_b32_e32 v20, 16, v26
	v_pk_add_f32 v[16:17], v[16:17], v[20:21]
	v_and_b32_e32 v21, 0xffff0000, v30
	v_lshlrev_b32_e32 v20, 16, v30
	v_pk_add_f32 v[16:17], v[16:17], v[20:21]
	v_and_b32_e32 v21, 0xffff0000, v34
	v_lshlrev_b32_e32 v20, 16, v34
	v_and_b32_e32 v51, 0xffff0000, v24
	v_lshlrev_b32_e32 v50, 16, v24
	v_pk_add_f32 v[16:17], v[16:17], v[20:21]
	v_pk_add_f32 v[20:21], v[40:41], v[46:47]
	v_and_b32_e32 v25, 0xffff0000, v15
	v_lshlrev_b32_e32 v24, 16, v15
	v_pk_add_f32 v[14:15], v[20:21], v[24:25]
	v_and_b32_e32 v21, 0xffff0000, v19
	v_lshlrev_b32_e32 v20, 16, v19
	v_pk_add_f32 v[14:15], v[14:15], v[20:21]
	v_and_b32_e32 v19, 0xffff0000, v23
	v_lshlrev_b32_e32 v18, 16, v23
	v_pk_add_f32 v[14:15], v[14:15], v[18:19]
	v_and_b32_e32 v19, 0xffff0000, v27
	v_lshlrev_b32_e32 v18, 16, v27
	v_pk_add_f32 v[48:49], v[48:49], v[50:51]
	v_and_b32_e32 v51, 0xffff0000, v28
	v_lshlrev_b32_e32 v50, 16, v28
	v_pk_add_f32 v[14:15], v[14:15], v[18:19]
	v_and_b32_e32 v19, 0xffff0000, v31
	v_lshlrev_b32_e32 v18, 16, v31
	v_pk_add_f32 v[48:49], v[48:49], v[50:51]
	v_and_b32_e32 v51, 0xffff0000, v32
	v_lshlrev_b32_e32 v50, 16, v32
	v_pk_add_f32 v[14:15], v[14:15], v[18:19]
	v_and_b32_e32 v19, 0xffff0000, v35
	v_lshlrev_b32_e32 v18, 16, v35
	v_pk_add_f32 v[48:49], v[48:49], v[50:51]
	v_pk_add_f32 v[14:15], v[14:15], v[18:19]
	v_perm_b32 v13, v13, v12, s14
	v_perm_b32 v15, v15, v14, s14
	v_perm_b32 v14, v17, v16, s14
	v_perm_b32 v12, v49, v48, s14
	v_lshl_add_u64 v[16:17], s[8:9], 0, v[0:1]
	global_store_dwordx4 v[16:17], v[12:15], off
	s_branch .LBB0_7
.LBB0_10:                               ; %Flow160
	s_or_b64 exec, exec, s[50:51]
	v_mov_b32_e32 v3, 0
	s_barrier
	global_load_dword v0, v3, s[48:49]
	s_waitcnt vmcnt(0)
	v_add_u32_e32 v4, 1, v0
	s_and_saveexec_b64 s[4:5], vcc
	s_cbranch_execz .LBB0_13
; %bb.11:
	global_load_dwordx2 v[6:7], v11, s[34:35]
	s_mov_b32 s30, s18
	s_lshl_b64 s[2:3], s[2:3], 5
	s_lshl_b64 s[6:7], s[30:31], 2
	s_add_u32 s6, s6, s2
	s_addc_u32 s7, s7, s3
	s_add_u32 s2, s20, s2
	s_addc_u32 s3, s21, s3
	v_lshl_add_u64 v[0:1], s[2:3], 0, v[2:3]
	s_mov_b64 s[2:3], 0
	s_waitcnt vmcnt(0)
	v_lshl_add_u64 v[2:3], s[6:7], 0, v[6:7]
	buffer_wbl2 sc0 sc1
	global_store_dword v[2:3], v4, off offset:2560 sc0 sc1
.LBB0_12:                               ; =>This Inner Loop Header: Depth=1
	global_load_dword v2, v[0:1], off offset:2560 sc1
	s_waitcnt vmcnt(0)
	buffer_inv sc1
	v_cmp_ge_u32_e32 vcc, v2, v4
	s_or_b64 s[2:3], vcc, s[2:3]
	s_andn2_b64 exec, exec, s[2:3]
	s_cbranch_execnz .LBB0_12
.LBB0_13:                               ; %Flow158
	s_or_b64 exec, exec, s[4:5]
	s_barrier
	s_and_saveexec_b64 s[2:3], s[0:1]
	s_cbranch_execz .LBB0_15
; %bb.14:
	v_mov_b32_e32 v0, 0
	global_store_dword v0, v4, s[48:49]
.LBB0_15:                               ; %_ZN7commkit8end_syncILi8ELb0EEEvRKNS_11RankSignalsEPNS_6SignalEi.exit
	s_or_b64 exec, exec, s[2:3]
	s_mul_i32 s12, s33, -7
	s_add_i32 s12, s12, s19
	v_cmp_gt_i32_e32 vcc, s12, v8
	s_and_saveexec_b64 s[0:1], vcc
	s_cbranch_execz .LBB0_18
; %bb.16:                               ; %.lr.ph102
	s_add_u32 s13, s24, 0x1780
	s_addc_u32 s0, s25, 0
	s_add_u32 s14, s26, 0x1780
	s_addc_u32 s1, s27, 0
	s_add_u32 s15, s28, 0x1780
	s_addc_u32 s2, s29, 0
	v_add_u32_e32 v0, s18, v10
	s_add_u32 s16, s36, 0x1780
	v_ashrrev_i32_e32 v1, 31, v0
	s_addc_u32 s3, s37, 0
	v_lshrrev_b32_e32 v1, 29, v1
	s_add_u32 s17, s38, 0x1780
	v_add_u32_e32 v1, v0, v1
	s_addc_u32 s4, s39, 0
	v_and_b32_e32 v1, -8, v1
	s_add_u32 s19, s40, 0x1780
	v_sub_u32_e32 v4, v0, v1
	v_mov_b32_e32 v0, s0
	v_mov_b32_e32 v1, s1
	v_cmp_eq_u32_e32 vcc, 1, v10
	s_addc_u32 s6, s41, 0
	v_cmp_eq_u32_e64 s[0:1], 2, v10
	v_cndmask_b32_e32 v0, v0, v1, vcc
	v_mov_b32_e32 v1, s2
	s_add_u32 s20, s42, 0x1780
	v_cndmask_b32_e64 v0, v0, v1, s[0:1]
	v_mov_b32_e32 v1, s3
	v_cmp_eq_u32_e64 s[2:3], 3, v10
	s_addc_u32 s8, s43, 0
	s_add_u32 s21, s46, 0x1780
	v_cndmask_b32_e64 v0, v0, v1, s[2:3]
	v_mov_b32_e32 v1, s4
	v_cmp_eq_u32_e64 s[4:5], 4, v10
	s_addc_u32 s10, s47, 0
	v_mov_b32_e32 v2, s14
	v_cndmask_b32_e64 v0, v0, v1, s[4:5]
	v_mov_b32_e32 v1, s6
	v_cmp_eq_u32_e64 s[6:7], 5, v10
	s_ashr_i32 s45, s44, 31
	s_nop 0
	v_cndmask_b32_e64 v0, v0, v1, s[6:7]
	v_mov_b32_e32 v1, s8
	v_cmp_eq_u32_e64 s[8:9], 6, v10
	s_nop 1
	v_cndmask_b32_e64 v0, v0, v1, s[8:9]
	v_mov_b32_e32 v1, s10
	v_cmp_eq_u32_e64 s[10:11], 7, v10
	s_nop 1
	v_cndmask_b32_e64 v1, v0, v1, s[10:11]
	v_mov_b32_e32 v0, s13
	v_cndmask_b32_e32 v0, v0, v2, vcc
	v_mov_b32_e32 v2, s15
	v_cndmask_b32_e64 v0, v0, v2, s[0:1]
	v_mov_b32_e32 v2, s16
	v_cndmask_b32_e64 v0, v0, v2, s[2:3]
	v_mov_b32_e32 v2, s17
	v_cndmask_b32_e64 v0, v0, v2, s[4:5]
	v_mov_b32_e32 v2, s19
	v_cndmask_b32_e64 v0, v0, v2, s[6:7]
	v_mov_b32_e32 v2, s20
	v_cndmask_b32_e64 v0, v0, v2, s[8:9]
	v_mov_b32_e32 v2, s21
	v_cndmask_b32_e64 v0, v0, v2, s[10:11]
	v_add_u32_e32 v2, s70, v9
	v_ashrrev_i32_e32 v3, 31, v2
	v_lshl_add_u64 v[0:1], v[2:3], 4, v[0:1]
	v_mad_u64_u32 v[2:3], s[2:3], v4, s33, v[2:3]
	v_ashrrev_i32_e32 v3, 31, v2
	s_lshl_b64 s[0:1], s[44:45], 4
	v_lshl_add_u64 v[2:3], v[2:3], 4, s[22:23]
	s_mov_b64 s[2:3], 0
	s_mov_b64 s[4:5], 0
.LBB0_17:                               ; =>This Inner Loop Header: Depth=1
	v_lshl_add_u64 v[4:5], v[0:1], 0, s[4:5]
	flat_load_dwordx4 v[4:7], v[4:5]
	v_lshl_add_u64 v[10:11], v[2:3], 0, s[4:5]
	v_add_u32_e32 v8, s44, v8
	s_add_u32 s4, s4, s0
	s_addc_u32 s5, s5, s1
	v_cmp_le_i32_e32 vcc, s12, v8
	s_or_b64 s[2:3], vcc, s[2:3]
	s_waitcnt vmcnt(0) lgkmcnt(0)
	global_store_dwordx4 v[10:11], v[4:7], off
	s_andn2_b64 exec, exec, s[2:3]
	s_cbranch_execnz .LBB0_17
.LBB0_18:                               ; %Flow156
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel _ZN7commkit7kernels26cross_device_reduce_2stageIDF16bLi8EEEvPNS_8RankDataES3_NS_11RankSignalsEPNS_6SignalEPT_ii
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
		.amdhsa_next_free_vgpr 52
		.amdhsa_next_free_sgpr 71
		.amdhsa_accum_offset 52
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
	.section	.text._ZN7commkit7kernels26cross_device_reduce_2stageIDF16bLi8EEEvPNS_8RankDataES3_NS_11RankSignalsEPNS_6SignalEPT_ii,"axG",@progbits,_ZN7commkit7kernels26cross_device_reduce_2stageIDF16bLi8EEEvPNS_8RankDataES3_NS_11RankSignalsEPNS_6SignalEPT_ii,comdat
.Lfunc_end0:
	.size	_ZN7commkit7kernels26cross_device_reduce_2stageIDF16bLi8EEEvPNS_8RankDataES3_NS_11RankSignalsEPNS_6SignalEPT_ii, .Lfunc_end0-_ZN7commkit7kernels26cross_device_reduce_2stageIDF16bLi8EEEvPNS_8RankDataES3_NS_11RankSignalsEPNS_6SignalEPT_ii
                                        ; -- End function
	.set _ZN7commkit7kernels26cross_device_reduce_2stageIDF16bLi8EEEvPNS_8RankDataES3_NS_11RankSignalsEPNS_6SignalEPT_ii.num_vgpr, 52
	.set _ZN7commkit7kernels26cross_device_reduce_2stageIDF16bLi8EEEvPNS_8RankDataES3_NS_11RankSignalsEPNS_6SignalEPT_ii.num_agpr, 0
	.set _ZN7commkit7kernels26cross_device_reduce_2stageIDF16bLi8EEEvPNS_8RankDataES3_NS_11RankSignalsEPNS_6SignalEPT_ii.numbered_sgpr, 71
	.set _ZN7commkit7kernels26cross_device_reduce_2stageIDF16bLi8EEEvPNS_8RankDataES3_NS_11RankSignalsEPNS_6SignalEPT_ii.private_seg_size, 0
	.set _ZN7commkit7kernels26cross_device_reduce_2stageIDF16bLi8EEEvPNS_8RankDataES3_NS_11RankSignalsEPNS_6SignalEPT_ii.uses_vcc, 1
	.set _ZN7commkit7kernels26cross_device_reduce_2stageIDF16bLi8EEEvPNS_8RankDataES3_NS_11RankSignalsEPNS_6SignalEPT_ii.uses_flat_scratch, 0
	.set _ZN7commkit7kernels26cross_device_reduce_2stageIDF16bLi8EEEvPNS_8RankDataES3_NS_11RankSignalsEPNS_6SignalEPT_ii.has_dyn_sized_stack, 0
	.set _ZN7commkit7kernels26cross_device_reduce_2stageIDF16bLi8EEEvPNS_8RankDataES3_NS_11RankSignalsEPNS_6SignalEPT_ii.has_recursion, 0
	.set _ZN7commkit7kernels26cross_device_reduce_2stageIDF16bLi8EEEvPNS_8RankDataES3_NS_11RankSignalsEPNS_6SignalEPT_ii.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 2656
; TotalNumSgprs: 77
; NumVgprs: 52
; NumAgprs: 0
; TotalNumVgprs: 52
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 8192 bytes/workgroup (compile time only)
; SGPRBlocks: 9
; VGPRBlocks: 6
; NumSGPRsForWavesPerEU: 77
; NumVGPRsForWavesPerEU: 52
; AccumOffset: 52
; Occupancy: 8
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 2
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 0
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 0
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 0
; COMPUTE_PGM_RSRC3_GFX90A:ACCUM_OFFSET: 12
; COMPUTE_PGM_RSRC3_GFX90A:TG_SPLIT: 0
	.section	.text._ZN7commkit7kernels6car_wtIDF16bLi8EEEvPNS_8RankDataES3_NS_11RankSignalsEPNS_6SignalEPT_ii,"axG",@progbits,_ZN7commkit7kernels6car_wtIDF16bLi8EEEvPNS_8RankDataES3_NS_11RankSignalsEPNS_6SignalEPT_ii,comdat
	.protected	_ZN7commkit7kernels6car_wtIDF16bLi8EEEvPNS_8RankDataES3_NS_11RankSignalsEPNS_6SignalEPT_ii ; -- Begin function _ZN7commkit7kernels6car_wtIDF16bLi8EEEvPNS_8RankDataES3_NS_11RankSignalsEPNS_6SignalEPT_ii
	.globl	_ZN7commkit7kernels6car_wtIDF16bLi8EEEvPNS_8RankDataES3_NS_11RankSignalsEPNS_6SignalEPT_ii
	.p2align	8
	.type	_ZN7commkit7kernels6car_wtIDF16bLi8EEEvPNS_8RankDataES3_NS_11RankSignalsEPNS_6SignalEPT_ii,@function
_ZN7commkit7kernels6car_wtIDF16bLi8EEEvPNS_8RankDataES3_NS_11RankSignalsEPNS_6SignalEPT_ii: ; @_ZN7commkit7kernels6car_wtIDF16bLi8EEEvPNS_8RankDataES3_NS_11RankSignalsEPNS_6SignalEPT_ii
; %bb.0:
	s_load_dwordx4 s[20:23], s[0:1], 0x58
	s_load_dword s8, s[0:1], 0x68
	s_add_u32 s28, s0, 16
	s_addc_u32 s29, s1, 0
	v_lshrrev_b32_e32 v1, 6, v0
	s_waitcnt lgkmcnt(0)
	s_ashr_i32 s27, s22, 31
	s_lshr_b32 s3, s27, 29
	s_add_i32 s3, s22, s3
	s_and_b32 s3, s3, -8
	s_sub_i32 s4, s22, s3
	s_ashr_i32 s5, s4, 31
	s_lshl_b64 s[6:7], s[4:5], 3
	s_add_u32 s4, s28, s6
	s_addc_u32 s5, s29, s7
	s_load_dwordx2 s[38:39], s[4:5], 0x0
	v_and_b32_e32 v11, 63, v0
	s_waitcnt lgkmcnt(0)
	s_add_u32 s24, s38, 0x1780
	s_addc_u32 s25, s39, 0
	s_add_i32 s3, s22, 1
	s_ashr_i32 s4, s3, 31
	s_lshr_b32 s4, s4, 29
	s_add_i32 s4, s3, s4
	s_and_b32 s4, s4, -8
	s_sub_i32 s4, s3, s4
	s_ashr_i32 s5, s4, 31
	s_lshl_b64 s[4:5], s[4:5], 3
	s_add_u32 s4, s28, s4
	s_addc_u32 s5, s29, s5
	s_load_dwordx2 s[4:5], s[4:5], 0x0
	s_waitcnt lgkmcnt(0)
	s_add_u32 s42, s4, 0x1780
	s_addc_u32 s44, s5, 0
	s_add_i32 s3, s22, 2
	s_ashr_i32 s4, s3, 31
	s_lshr_b32 s4, s4, 29
	s_add_i32 s4, s3, s4
	s_and_b32 s4, s4, -8
	s_sub_i32 s4, s3, s4
	s_ashr_i32 s5, s4, 31
	s_lshl_b64 s[4:5], s[4:5], 3
	s_add_u32 s4, s28, s4
	s_addc_u32 s5, s29, s5
	s_load_dwordx2 s[4:5], s[4:5], 0x0
	s_waitcnt lgkmcnt(0)
	s_add_u32 s43, s4, 0x1780
	s_addc_u32 s46, s5, 0
	s_add_i32 s3, s22, 3
	s_ashr_i32 s4, s3, 31
	s_lshr_b32 s4, s4, 29
	s_add_i32 s4, s3, s4
	s_and_b32 s4, s4, -8
	s_sub_i32 s4, s3, s4
	s_ashr_i32 s5, s4, 31
	s_lshl_b64 s[4:5], s[4:5], 3
	s_add_u32 s4, s28, s4
	s_addc_u32 s5, s29, s5
	s_load_dwordx2 s[4:5], s[4:5], 0x0
	s_waitcnt lgkmcnt(0)
	s_add_u32 s45, s4, 0x1780
	s_addc_u32 s48, s5, 0
	s_add_i32 s3, s22, 4
	s_ashr_i32 s4, s3, 31
	s_lshr_b32 s4, s4, 29
	s_add_i32 s4, s3, s4
	s_and_b32 s4, s4, -8
	s_sub_i32 s4, s3, s4
	s_ashr_i32 s5, s4, 31
	s_lshl_b64 s[4:5], s[4:5], 3
	s_add_u32 s4, s28, s4
	s_addc_u32 s5, s29, s5
	s_load_dwordx2 s[4:5], s[4:5], 0x0
	s_waitcnt lgkmcnt(0)
	s_add_u32 s47, s4, 0x1780
	s_addc_u32 s50, s5, 0
	s_add_i32 s3, s22, 5
	s_ashr_i32 s4, s3, 31
	s_lshr_b32 s4, s4, 29
	s_add_i32 s4, s3, s4
	s_and_b32 s4, s4, -8
	s_sub_i32 s4, s3, s4
	s_ashr_i32 s5, s4, 31
	s_lshl_b64 s[4:5], s[4:5], 3
	s_add_u32 s4, s28, s4
	s_addc_u32 s5, s29, s5
	s_load_dwordx2 s[4:5], s[4:5], 0x0
	s_waitcnt lgkmcnt(0)
	s_add_u32 s49, s4, 0x1780
	s_addc_u32 s52, s5, 0
	s_add_i32 s3, s22, 6
	s_ashr_i32 s4, s3, 31
	s_lshr_b32 s4, s4, 29
	s_add_i32 s4, s3, s4
	s_and_b32 s4, s4, -8
	s_sub_i32 s4, s3, s4
	s_ashr_i32 s5, s4, 31
	s_lshl_b64 s[4:5], s[4:5], 3
	s_add_u32 s4, s28, s4
	s_addc_u32 s5, s29, s5
	s_load_dwordx2 s[4:5], s[4:5], 0x0
	s_waitcnt lgkmcnt(0)
	s_add_u32 s51, s4, 0x1780
	s_addc_u32 s53, s5, 0
	s_add_i32 s3, s22, 7
	s_ashr_i32 s4, s3, 31
	s_lshr_b32 s4, s4, 29
	s_add_i32 s4, s3, s4
	s_and_b32 s4, s4, -8
	s_sub_i32 s4, s3, s4
	s_ashr_i32 s5, s4, 31
	s_lshl_b64 s[4:5], s[4:5], 3
	s_add_u32 s4, s28, s4
	s_addc_u32 s5, s29, s5
	s_load_dwordx2 s[4:5], s[4:5], 0x0
	s_waitcnt lgkmcnt(0)
	s_add_u32 s54, s4, 0x1780
	s_addc_u32 s56, s5, 0
	s_ashr_i32 s4, s23, 31
	s_lshr_b32 s4, s4, 29
	s_add_i32 s4, s23, s4
	s_lshl_b32 s3, s2, 6
	s_ashr_i32 s33, s4, 3
	v_or_b32_e32 v8, s3, v11
	v_mul_lo_u32 v9, s33, v1
	s_lshl_b32 s30, s8, 6
	s_mul_i32 s55, s33, s22
	v_cmp_gt_i32_e64 s[4:5], s33, v8
	v_add3_u32 v2, v9, s3, v11
	s_and_saveexec_b64 s[18:19], s[4:5]
	s_cbranch_execz .LBB1_3
; %bb.1:                                ; %.lr.ph
	s_load_dwordx2 s[8:9], s[0:1], 0x0
	v_subrev_u32_e32 v3, s22, v1
	v_add_u32_e32 v4, 8, v3
	v_cmp_gt_i32_e32 vcc, 0, v3
	v_mov_b32_e32 v5, s44
	s_waitcnt lgkmcnt(0)
	s_add_u32 s6, s8, s6
	v_cndmask_b32_e32 v3, v3, v4, vcc
	s_addc_u32 s7, s9, s7
	v_mov_b32_e32 v4, s25
	v_cmp_eq_u32_e32 vcc, 1, v3
	s_load_dwordx2 s[34:35], s[6:7], 0x0
	v_cmp_eq_u32_e64 s[6:7], 2, v3
	v_cndmask_b32_e32 v4, v4, v5, vcc
	v_mov_b32_e32 v5, s46
	v_cndmask_b32_e64 v4, v4, v5, s[6:7]
	v_mov_b32_e32 v5, s48
	v_cmp_eq_u32_e64 s[8:9], 3, v3
	v_cmp_eq_u32_e64 s[10:11], 4, v3
	v_cmp_eq_u32_e64 s[12:13], 5, v3
	v_cndmask_b32_e64 v4, v4, v5, s[8:9]
	v_mov_b32_e32 v5, s50
	v_cndmask_b32_e64 v4, v4, v5, s[10:11]
	v_mov_b32_e32 v5, s52
	v_cndmask_b32_e64 v4, v4, v5, s[12:13]
	v_mov_b32_e32 v5, s53
	v_cmp_eq_u32_e64 s[14:15], 6, v3
	v_cmp_eq_u32_e64 s[16:17], 7, v3
	v_mov_b32_e32 v3, s24
	v_cndmask_b32_e64 v4, v4, v5, s[14:15]
	v_mov_b32_e32 v5, s56
	v_cndmask_b32_e64 v5, v4, v5, s[16:17]
	v_mov_b32_e32 v4, s42
	v_cndmask_b32_e32 v3, v3, v4, vcc
	v_mov_b32_e32 v4, s43
	v_cndmask_b32_e64 v3, v3, v4, s[6:7]
	v_mov_b32_e32 v4, s45
	v_cndmask_b32_e64 v3, v3, v4, s[8:9]
	v_mov_b32_e32 v4, s47
	v_cndmask_b32_e64 v3, v3, v4, s[10:11]
	v_mov_b32_e32 v4, s49
	v_cndmask_b32_e64 v3, v3, v4, s[12:13]
	v_mov_b32_e32 v4, s51
	s_add_i32 s3, s55, s3
	v_cndmask_b32_e64 v3, v3, v4, s[14:15]
	v_mov_b32_e32 v4, s54
	v_add_u32_e32 v6, s3, v11
	v_cndmask_b32_e64 v4, v3, v4, s[16:17]
	v_ashrrev_i32_e32 v7, 31, v6
	s_ashr_i32 s31, s30, 31
	v_ashrrev_i32_e32 v3, 31, v2
	v_lshl_add_u64 v[4:5], v[6:7], 4, v[4:5]
	s_lshl_b64 s[6:7], s[30:31], 4
	s_waitcnt lgkmcnt(0)
	v_lshl_add_u64 v[6:7], v[2:3], 4, s[34:35]
	s_mov_b64 s[8:9], 0
	s_mov_b64 s[10:11], 0
	v_mov_b32_e32 v3, v8
.LBB1_2:                                ; =>This Inner Loop Header: Depth=1
	v_lshl_add_u64 v[12:13], v[6:7], 0, s[10:11]
	flat_load_dwordx4 v[12:15], v[12:13]
	v_lshl_add_u64 v[16:17], v[4:5], 0, s[10:11]
	v_add_u32_e32 v3, s30, v3
	s_add_u32 s10, s10, s6
	s_addc_u32 s11, s11, s7
	v_cmp_le_i32_e32 vcc, s33, v3
	s_or_b64 s[8:9], vcc, s[8:9]
	s_waitcnt vmcnt(0) lgkmcnt(0)
	flat_store_dwordx4 v[16:17], v[12:15]
	s_andn2_b64 exec, exec, s[8:9]
	s_cbranch_execnz .LBB1_2
.LBB1_3:                                ; %Flow200
	s_or_b64 exec, exec, s[18:19]
	s_load_dwordx2 s[36:37], s[0:1], 0x50
	s_mov_b32 s3, 0
	s_lshl_b64 s[0:1], s[2:3], 2
	v_mov_b32_e32 v3, 0x1000
	s_waitcnt lgkmcnt(0)
	s_add_u32 s0, s36, s0
	s_addc_u32 s1, s37, s1
	s_barrier
	global_load_dword v3, v3, s[0:1] offset:1024
	s_add_u32 s34, s0, 0x1400
	v_cmp_gt_u32_e32 vcc, 8, v0
	v_lshlrev_b32_e32 v10, 3, v0
	s_addc_u32 s35, s1, 0
	v_lshlrev_b32_e32 v4, 2, v0
	s_waitcnt vmcnt(0)
	v_add_u32_e32 v3, 1, v3
	s_and_saveexec_b64 s[6:7], vcc
	s_cbranch_execz .LBB1_6
; %bb.4:
	global_load_dwordx2 v[6:7], v10, s[28:29]
	s_mov_b32 s26, s22
	s_lshl_b64 s[0:1], s[2:3], 5
	s_lshl_b64 s[10:11], s[26:27], 2
	s_add_u32 s10, s10, s0
	s_addc_u32 s11, s11, s1
	s_add_u32 s0, s36, s0
	s_mov_b64 s[8:9], 0xa00
	s_addc_u32 s1, s37, s1
	s_add_u32 s0, s0, 0xa00
	v_mov_b32_e32 v5, 0
	s_addc_u32 s1, s1, 0
	s_waitcnt vmcnt(0)
	v_lshl_add_u64 v[6:7], v[6:7], 0, s[10:11]
	v_lshl_add_u64 v[12:13], v[6:7], 0, s[8:9]
	;;#ASMSTART
	buffer_wbl2 sc0 sc1
	global_store_dword v[12:13], v3, off sc0 sc1
	
	;;#ASMEND
	v_lshl_add_u64 v[6:7], s[0:1], 0, v[4:5]
	s_mov_b64 s[8:9], 0
.LBB1_5:                                ; =>This Inner Loop Header: Depth=1
	;;#ASMSTART
	global_load_dword v5, v[6:7], off sc1
	s_waitcnt vmcnt(0)
	buffer_inv sc1
	
	;;#ASMEND
	s_nop 0
	v_cmp_ge_u32_e64 s[0:1], v5, v3
	s_or_b64 s[8:9], s[0:1], s[8:9]
	s_andn2_b64 exec, exec, s[8:9]
	s_cbranch_execnz .LBB1_5
.LBB1_6:                                ; %Flow198
	s_or_b64 exec, exec, s[6:7]
	v_cmp_eq_u32_e64 s[0:1], 0, v0
	s_barrier
	s_and_saveexec_b64 s[6:7], s[0:1]
	s_cbranch_execz .LBB1_8
; %bb.7:
	v_mov_b32_e32 v5, 0
	global_store_dword v5, v3, s[34:35]
.LBB1_8:                                ; %_ZN7commkit12end_sync_asmILi8ELb1ELb1EEEvRKNS_11RankSignalsEPNS_6SignalEi.exit
	s_or_b64 exec, exec, s[6:7]
	s_and_saveexec_b64 s[40:41], s[4:5]
	s_cbranch_execz .LBB1_13
; %bb.9:                                ; %.lr.ph151
	v_lshlrev_b32_e32 v5, 4, v11
	v_lshlrev_b32_e32 v11, 4, v0
	v_cmp_gt_u32_e64 s[4:5], 64, v0
	v_and_b32_e32 v0, 0x1c0, v0
	v_lshl_or_b32 v12, v0, 4, v5
	v_mov_b32_e32 v0, s25
	v_mov_b32_e32 v3, s44
	v_cmp_eq_u32_e64 s[6:7], 1, v1
	v_cmp_eq_u32_e64 s[8:9], 2, v1
	v_cmp_eq_u32_e64 s[10:11], 3, v1
	v_cndmask_b32_e64 v0, v0, v3, s[6:7]
	v_mov_b32_e32 v3, s46
	v_cndmask_b32_e64 v0, v0, v3, s[8:9]
	v_mov_b32_e32 v3, s48
	v_cndmask_b32_e64 v0, v0, v3, s[10:11]
	v_mov_b32_e32 v3, s50
	v_cmp_eq_u32_e64 s[12:13], 4, v1
	v_cmp_eq_u32_e64 s[14:15], 5, v1
	v_cmp_eq_u32_e64 s[16:17], 6, v1
	v_cndmask_b32_e64 v0, v0, v3, s[12:13]
	v_mov_b32_e32 v3, s52
	v_cndmask_b32_e64 v0, v0, v3, s[14:15]
	v_mov_b32_e32 v3, s53
	v_cndmask_b32_e64 v0, v0, v3, s[16:17]
	v_mov_b32_e32 v3, s56
	v_cmp_eq_u32_e64 s[18:19], 7, v1
	s_ashr_i32 s31, s30, 31
	s_add_i32 s55, s55, s23
	v_cndmask_b32_e64 v1, v0, v3, s[18:19]
	v_mov_b32_e32 v0, s24
	v_mov_b32_e32 v3, s42
	v_cndmask_b32_e64 v0, v0, v3, s[6:7]
	v_mov_b32_e32 v3, s43
	v_cndmask_b32_e64 v0, v0, v3, s[8:9]
	v_mov_b32_e32 v3, s45
	v_cndmask_b32_e64 v0, v0, v3, s[10:11]
	v_mov_b32_e32 v3, s47
	v_cndmask_b32_e64 v0, v0, v3, s[12:13]
	v_mov_b32_e32 v3, s49
	v_cndmask_b32_e64 v0, v0, v3, s[14:15]
	v_mov_b32_e32 v3, s51
	v_cndmask_b32_e64 v0, v0, v3, s[16:17]
	v_mov_b32_e32 v3, s54
	v_cndmask_b32_e64 v0, v0, v3, s[18:19]
	v_ashrrev_i32_e32 v3, 31, v2
	v_lshl_add_u64 v[6:7], v[2:3], 4, s[38:39]
	s_mov_b64 s[6:7], 0x1780
	v_lshl_add_u64 v[6:7], v[6:7], 0, s[6:7]
	s_lshl_b64 s[8:9], s[30:31], 4
	s_mov_b64 s[10:11], 0
	s_mov_b32 s12, 0x7060302
	v_mov_b32_e32 v3, v8
	s_branch .LBB1_11
.LBB1_10:                               ;   in Loop: Header=BB1_11 Depth=1
	s_or_b64 exec, exec, s[6:7]
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read_b128 v[14:17], v12
	v_add_u32_e32 v18, s55, v3
	v_add_u32_e32 v3, s30, v3
	v_ashrrev_i32_e32 v19, 31, v18
	v_cmp_le_i32_e64 s[6:7], s33, v3
	v_lshl_add_u64 v[18:19], v[18:19], 4, v[0:1]
	s_or_b64 s[10:11], s[6:7], s[10:11]
	v_lshl_add_u64 v[6:7], v[6:7], 0, s[8:9]
	s_waitcnt lgkmcnt(0)
	flat_store_dwordx4 v[18:19], v[14:17]
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_andn2_b64 exec, exec, s[10:11]
	s_cbranch_execz .LBB1_13
.LBB1_11:                               ; =>This Inner Loop Header: Depth=1
	global_load_dwordx4 v[14:17], v[6:7], off
	s_waitcnt vmcnt(0)
	ds_write_b128 v11, v[14:17]
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_saveexec_b64 s[6:7], s[4:5]
	s_cbranch_execz .LBB1_10
; %bb.12:                               ; %.preheader129
                                        ;   in Loop: Header=BB1_11 Depth=1
	ds_read_b128 v[14:17], v5
	ds_read_b128 v[18:21], v5 offset:1024
	ds_read_b128 v[22:25], v5 offset:2048
	ds_read_b128 v[26:29], v5 offset:3072
	ds_read_b128 v[30:33], v5 offset:4096
	ds_read_b128 v[34:37], v5 offset:5120
	ds_read_b128 v[38:41], v5 offset:6144
	ds_read_b128 v[42:45], v5 offset:7168
	s_waitcnt lgkmcnt(7)
	v_and_b32_e32 v47, 0xffff0000, v14
	v_lshlrev_b32_e32 v46, 16, v14
	v_and_b32_e32 v49, 0xffff0000, v15
	v_lshlrev_b32_e32 v48, 16, v15
	v_and_b32_e32 v15, 0xffff0000, v16
	v_lshlrev_b32_e32 v14, 16, v16
	v_and_b32_e32 v51, 0xffff0000, v17
	v_lshlrev_b32_e32 v50, 16, v17
	s_waitcnt lgkmcnt(6)
	v_and_b32_e32 v17, 0xffff0000, v18
	v_lshlrev_b32_e32 v16, 16, v18
	v_and_b32_e32 v53, 0xffff0000, v19
	v_lshlrev_b32_e32 v52, 16, v19
	v_and_b32_e32 v19, 0xffff0000, v20
	v_lshlrev_b32_e32 v18, 16, v20
	v_and_b32_e32 v55, 0xffff0000, v21
	v_lshlrev_b32_e32 v54, 16, v21
	v_pk_add_f32 v[16:17], v[46:47], v[16:17]
	s_waitcnt lgkmcnt(5)
	v_and_b32_e32 v21, 0xffff0000, v22
	v_lshlrev_b32_e32 v20, 16, v22
	v_pk_add_f32 v[16:17], v[16:17], v[20:21]
	s_waitcnt lgkmcnt(4)
	v_and_b32_e32 v21, 0xffff0000, v26
	v_lshlrev_b32_e32 v20, 16, v26
	v_pk_add_f32 v[16:17], v[16:17], v[20:21]
	s_waitcnt lgkmcnt(3)
	v_and_b32_e32 v21, 0xffff0000, v30
	v_lshlrev_b32_e32 v20, 16, v30
	v_pk_add_f32 v[16:17], v[16:17], v[20:21]
	s_waitcnt lgkmcnt(2)
	v_and_b32_e32 v21, 0xffff0000, v34
	v_lshlrev_b32_e32 v20, 16, v34
	v_pk_add_f32 v[16:17], v[16:17], v[20:21]
	s_waitcnt lgkmcnt(1)
	v_and_b32_e32 v21, 0xffff0000, v38
	v_lshlrev_b32_e32 v20, 16, v38
	v_pk_add_f32 v[16:17], v[16:17], v[20:21]
	s_waitcnt lgkmcnt(0)
	v_and_b32_e32 v21, 0xffff0000, v42
	v_lshlrev_b32_e32 v20, 16, v42
	v_pk_add_f32 v[20:21], v[16:17], v[20:21]
	v_pk_add_f32 v[16:17], v[48:49], v[52:53]
	v_and_b32_e32 v47, 0xffff0000, v23
	v_lshlrev_b32_e32 v46, 16, v23
	v_pk_add_f32 v[16:17], v[16:17], v[46:47]
	v_and_b32_e32 v23, 0xffff0000, v27
	v_lshlrev_b32_e32 v22, 16, v27
	v_pk_add_f32 v[16:17], v[16:17], v[22:23]
	v_and_b32_e32 v23, 0xffff0000, v31
	v_lshlrev_b32_e32 v22, 16, v31
	v_pk_add_f32 v[16:17], v[16:17], v[22:23]
	v_and_b32_e32 v23, 0xffff0000, v35
	v_lshlrev_b32_e32 v22, 16, v35
	v_pk_add_f32 v[16:17], v[16:17], v[22:23]
	v_and_b32_e32 v23, 0xffff0000, v39
	v_lshlrev_b32_e32 v22, 16, v39
	v_pk_add_f32 v[16:17], v[16:17], v[22:23]
	v_and_b32_e32 v23, 0xffff0000, v43
	v_lshlrev_b32_e32 v22, 16, v43
	v_pk_add_f32 v[22:23], v[16:17], v[22:23]
	v_pk_add_f32 v[14:15], v[14:15], v[18:19]
	v_and_b32_e32 v17, 0xffff0000, v24
	v_lshlrev_b32_e32 v16, 16, v24
	v_pk_add_f32 v[14:15], v[14:15], v[16:17]
	v_and_b32_e32 v17, 0xffff0000, v28
	v_lshlrev_b32_e32 v16, 16, v28
	v_pk_add_f32 v[14:15], v[14:15], v[16:17]
	v_and_b32_e32 v17, 0xffff0000, v32
	v_lshlrev_b32_e32 v16, 16, v32
	v_pk_add_f32 v[14:15], v[14:15], v[16:17]
	v_and_b32_e32 v17, 0xffff0000, v36
	v_lshlrev_b32_e32 v16, 16, v36
	v_pk_add_f32 v[14:15], v[14:15], v[16:17]
	v_and_b32_e32 v17, 0xffff0000, v40
	v_lshlrev_b32_e32 v16, 16, v40
	v_pk_add_f32 v[14:15], v[14:15], v[16:17]
	v_and_b32_e32 v17, 0xffff0000, v44
	v_lshlrev_b32_e32 v16, 16, v44
	v_pk_add_f32 v[14:15], v[14:15], v[16:17]
	v_pk_add_f32 v[16:17], v[50:51], v[54:55]
	v_and_b32_e32 v19, 0xffff0000, v25
	v_lshlrev_b32_e32 v18, 16, v25
	v_pk_add_f32 v[16:17], v[16:17], v[18:19]
	v_and_b32_e32 v19, 0xffff0000, v29
	v_lshlrev_b32_e32 v18, 16, v29
	v_pk_add_f32 v[16:17], v[16:17], v[18:19]
	v_and_b32_e32 v19, 0xffff0000, v33
	v_lshlrev_b32_e32 v18, 16, v33
	v_pk_add_f32 v[16:17], v[16:17], v[18:19]
	v_and_b32_e32 v19, 0xffff0000, v37
	v_lshlrev_b32_e32 v18, 16, v37
	v_pk_add_f32 v[16:17], v[16:17], v[18:19]
	v_and_b32_e32 v19, 0xffff0000, v41
	v_lshlrev_b32_e32 v18, 16, v41
	v_pk_add_f32 v[16:17], v[16:17], v[18:19]
	v_and_b32_e32 v19, 0xffff0000, v45
	v_lshlrev_b32_e32 v18, 16, v45
	v_pk_add_f32 v[16:17], v[16:17], v[18:19]
	s_nop 0
	v_perm_b32 v17, v17, v16, s12
	v_perm_b32 v16, v15, v14, s12
	v_perm_b32 v15, v23, v22, s12
	v_perm_b32 v14, v21, v20, s12
	ds_write_b128 v5, v[14:17]
	ds_write_b128 v5, v[14:17] offset:1024
	ds_write_b128 v5, v[14:17] offset:2048
	ds_write_b128 v5, v[14:17] offset:3072
	ds_write_b128 v5, v[14:17] offset:4096
	ds_write_b128 v5, v[14:17] offset:5120
	ds_write_b128 v5, v[14:17] offset:6144
	ds_write_b128 v5, v[14:17] offset:7168
	s_branch .LBB1_10
.LBB1_13:                               ; %Flow196
	s_or_b64 exec, exec, s[40:41]
	v_mov_b32_e32 v5, 0
	s_barrier
	global_load_dword v0, v5, s[34:35]
	s_waitcnt vmcnt(0)
	v_add_u32_e32 v3, 1, v0
	s_and_saveexec_b64 s[4:5], vcc
	s_cbranch_execz .LBB1_16
; %bb.14:
	global_load_dwordx2 v[0:1], v10, s[28:29]
	s_mov_b32 s26, s22
	s_lshl_b64 s[2:3], s[2:3], 5
	s_lshl_b64 s[8:9], s[26:27], 2
	s_add_u32 s8, s8, s2
	s_addc_u32 s9, s9, s3
	s_add_u32 s2, s36, s2
	s_mov_b64 s[6:7], 0xa00
	s_addc_u32 s3, s37, s3
	s_add_u32 s2, s2, 0xa00
	s_addc_u32 s3, s3, 0
	s_waitcnt vmcnt(0)
	v_lshl_add_u64 v[0:1], v[0:1], 0, s[8:9]
	v_lshl_add_u64 v[6:7], v[0:1], 0, s[6:7]
	;;#ASMSTART
	buffer_wbl2 sc0 sc1
	global_store_dword v[6:7], v3, off sc0 sc1
	
	;;#ASMEND
	v_lshl_add_u64 v[0:1], s[2:3], 0, v[4:5]
	s_mov_b64 s[2:3], 0
.LBB1_15:                               ; =>This Inner Loop Header: Depth=1
	;;#ASMSTART
	global_load_dword v4, v[0:1], off sc1
	s_waitcnt vmcnt(0)
	buffer_inv sc1
	
	;;#ASMEND
	s_nop 0
	v_cmp_ge_u32_e32 vcc, v4, v3
	s_or_b64 s[2:3], vcc, s[2:3]
	s_andn2_b64 exec, exec, s[2:3]
	s_cbranch_execnz .LBB1_15
.LBB1_16:                               ; %Flow194
	s_or_b64 exec, exec, s[4:5]
	s_barrier
	s_and_saveexec_b64 s[2:3], s[0:1]
	s_cbranch_execz .LBB1_18
; %bb.17:
	v_mov_b32_e32 v0, 0
	global_store_dword v0, v3, s[34:35]
.LBB1_18:                               ; %_ZN7commkit12end_sync_asmILi8ELb1ELb1EEEvRKNS_11RankSignalsEPNS_6SignalEi.exit121
	s_or_b64 exec, exec, s[2:3]
	s_mul_i32 s4, s33, -7
	s_add_i32 s4, s4, s23
	v_cmp_gt_i32_e32 vcc, s4, v8
	s_and_saveexec_b64 s[0:1], vcc
	s_cbranch_execz .LBB1_21
; %bb.19:                               ; %.lr.ph154
	v_ashrrev_i32_e32 v3, 31, v2
	s_ashr_i32 s31, s30, 31
	v_add_u32_e32 v4, s23, v9
	v_lshl_add_u64 v[0:1], v[2:3], 4, s[20:21]
	s_lshl_b64 s[0:1], s[30:31], 4
	s_mov_b64 s[2:3], 0
.LBB1_20:                               ; =>This Inner Loop Header: Depth=1
	v_add_u32_e32 v2, v4, v8
	v_ashrrev_i32_e32 v3, 31, v2
	v_lshl_add_u64 v[2:3], v[2:3], 4, s[24:25]
	global_load_dwordx4 v[10:13], v[2:3], off
	v_add_u32_e32 v8, s30, v8
	v_cmp_le_i32_e32 vcc, s4, v8
	s_or_b64 s[2:3], vcc, s[2:3]
	s_waitcnt vmcnt(0)
	global_store_dwordx4 v[0:1], v[10:13], off
	v_lshl_add_u64 v[0:1], v[0:1], 0, s[0:1]
	s_andn2_b64 exec, exec, s[2:3]
	s_cbranch_execnz .LBB1_20
.LBB1_21:                               ; %Flow192
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel _ZN7commkit7kernels6car_wtIDF16bLi8EEEvPNS_8RankDataES3_NS_11RankSignalsEPNS_6SignalEPT_ii
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
		.amdhsa_next_free_vgpr 56
		.amdhsa_next_free_sgpr 57
		.amdhsa_accum_offset 56
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
	.section	.text._ZN7commkit7kernels6car_wtIDF16bLi8EEEvPNS_8RankDataES3_NS_11RankSignalsEPNS_6SignalEPT_ii,"axG",@progbits,_ZN7commkit7kernels6car_wtIDF16bLi8EEEvPNS_8RankDataES3_NS_11RankSignalsEPNS_6SignalEPT_ii,comdat
.Lfunc_end1:
	.size	_ZN7commkit7kernels6car_wtIDF16bLi8EEEvPNS_8RankDataES3_NS_11RankSignalsEPNS_6SignalEPT_ii, .Lfunc_end1-_ZN7commkit7kernels6car_wtIDF16bLi8EEEvPNS_8RankDataES3_NS_11RankSignalsEPNS_6SignalEPT_ii
                                        ; -- End function
	.set _ZN7commkit7kernels6car_wtIDF16bLi8EEEvPNS_8RankDataES3_NS_11RankSignalsEPNS_6SignalEPT_ii.num_vgpr, 56
	.set _ZN7commkit7kernels6car_wtIDF16bLi8EEEvPNS_8RankDataES3_NS_11RankSignalsEPNS_6SignalEPT_ii.num_agpr, 0
	.set _ZN7commkit7kernels6car_wtIDF16bLi8EEEvPNS_8RankDataES3_NS_11RankSignalsEPNS_6SignalEPT_ii.numbered_sgpr, 57
	.set _ZN7commkit7kernels6car_wtIDF16bLi8EEEvPNS_8RankDataES3_NS_11RankSignalsEPNS_6SignalEPT_ii.private_seg_size, 0
	.set _ZN7commkit7kernels6car_wtIDF16bLi8EEEvPNS_8RankDataES3_NS_11RankSignalsEPNS_6SignalEPT_ii.uses_vcc, 1
	.set _ZN7commkit7kernels6car_wtIDF16bLi8EEEvPNS_8RankDataES3_NS_11RankSignalsEPNS_6SignalEPT_ii.uses_flat_scratch, 0
	.set _ZN7commkit7kernels6car_wtIDF16bLi8EEEvPNS_8RankDataES3_NS_11RankSignalsEPNS_6SignalEPT_ii.has_dyn_sized_stack, 0
	.set _ZN7commkit7kernels6car_wtIDF16bLi8EEEvPNS_8RankDataES3_NS_11RankSignalsEPNS_6SignalEPT_ii.has_recursion, 0
	.set _ZN7commkit7kernels6car_wtIDF16bLi8EEEvPNS_8RankDataES3_NS_11RankSignalsEPNS_6SignalEPT_ii.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 2876
; TotalNumSgprs: 63
; NumVgprs: 56
; NumAgprs: 0
; TotalNumVgprs: 56
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 8192 bytes/workgroup (compile time only)
; SGPRBlocks: 7
; VGPRBlocks: 6
; NumSGPRsForWavesPerEU: 63
; NumVGPRsForWavesPerEU: 56
; AccumOffset: 56
; Occupancy: 8
; WaveLimiterHint : 1
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 2
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 0
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 0
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 0
; COMPUTE_PGM_RSRC3_GFX90A:ACCUM_OFFSET: 13
; COMPUTE_PGM_RSRC3_GFX90A:TG_SPLIT: 0
	.section	.text._ZN7commkit7kernels7car_tp8IDF16bEEvPNS_8RankDataENS_11RankSignalsEPNS_6SignalEPT_ii,"axG",@progbits,_ZN7commkit7kernels7car_tp8IDF16bEEvPNS_8RankDataENS_11RankSignalsEPNS_6SignalEPT_ii,comdat
	.protected	_ZN7commkit7kernels7car_tp8IDF16bEEvPNS_8RankDataENS_11RankSignalsEPNS_6SignalEPT_ii ; -- Begin function _ZN7commkit7kernels7car_tp8IDF16bEEvPNS_8RankDataENS_11RankSignalsEPNS_6SignalEPT_ii
	.globl	_ZN7commkit7kernels7car_tp8IDF16bEEvPNS_8RankDataENS_11RankSignalsEPNS_6SignalEPT_ii
	.p2align	8
	.type	_ZN7commkit7kernels7car_tp8IDF16bEEvPNS_8RankDataENS_11RankSignalsEPNS_6SignalEPT_ii,@function
_ZN7commkit7kernels7car_tp8IDF16bEEvPNS_8RankDataENS_11RankSignalsEPNS_6SignalEPT_ii: ; @_ZN7commkit7kernels7car_tp8IDF16bEEvPNS_8RankDataENS_11RankSignalsEPNS_6SignalEPT_ii
; %bb.0:
	s_load_dwordx2 s[24:25], s[0:1], 0x60
	s_load_dwordx2 s[4:5], s[0:1], 0x0
	s_add_u32 s26, s0, 16
	s_addc_u32 s27, s1, 0
	s_load_dword s33, s[0:1], 0x68
	s_waitcnt lgkmcnt(0)
	s_ashr_i32 s58, s24, 31
	s_lshr_b32 s3, s58, 29
	s_add_i32 s3, s24, s3
	s_and_b32 s3, s3, -8
	s_sub_i32 s6, s24, s3
	s_ashr_i32 s7, s6, 31
	s_lshl_b64 s[6:7], s[6:7], 3
	s_add_u32 s8, s4, s6
	s_addc_u32 s9, s5, s7
	s_add_u32 s6, s26, s6
	s_addc_u32 s7, s27, s7
	s_add_i32 s3, s24, 1
	s_load_dwordx2 s[38:39], s[8:9], 0x0
	s_ashr_i32 s8, s3, 31
	s_lshr_b32 s8, s8, 29
	s_add_i32 s8, s3, s8
	s_and_b32 s8, s8, -8
	s_sub_i32 s8, s3, s8
	s_ashr_i32 s9, s8, 31
	s_lshl_b64 s[8:9], s[8:9], 3
	s_add_u32 s10, s4, s8
	s_addc_u32 s11, s5, s9
	s_add_u32 s8, s26, s8
	s_addc_u32 s9, s27, s9
	s_add_i32 s3, s24, 2
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
	s_add_u32 s10, s26, s10
	s_addc_u32 s11, s27, s11
	s_add_i32 s3, s24, 3
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
	s_add_u32 s12, s26, s12
	s_addc_u32 s13, s27, s13
	s_add_i32 s3, s24, 4
	s_load_dwordx2 s[44:45], s[14:15], 0x0
	v_and_b32_e32 v3, 31, v0
	s_load_dwordx2 s[14:15], s[12:13], 0x0
	s_ashr_i32 s12, s3, 31
	s_lshr_b32 s12, s12, 29
	s_add_i32 s12, s3, s12
	s_and_b32 s12, s12, -8
	s_sub_i32 s12, s3, s12
	s_ashr_i32 s13, s12, 31
	s_lshl_b64 s[12:13], s[12:13], 3
	s_add_u32 s16, s4, s12
	s_addc_u32 s17, s5, s13
	s_add_u32 s12, s26, s12
	s_addc_u32 s13, s27, s13
	s_add_i32 s3, s24, 5
	s_load_dwordx2 s[46:47], s[16:17], 0x0
	v_mov_b32_e32 v18, 0
	s_load_dwordx2 s[16:17], s[12:13], 0x0
	s_ashr_i32 s12, s3, 31
	s_lshr_b32 s12, s12, 29
	s_add_i32 s12, s3, s12
	s_and_b32 s12, s12, -8
	s_sub_i32 s12, s3, s12
	s_ashr_i32 s13, s12, 31
	s_lshl_b64 s[12:13], s[12:13], 3
	s_add_u32 s18, s4, s12
	s_addc_u32 s19, s5, s13
	s_add_u32 s12, s26, s12
	s_addc_u32 s13, s27, s13
	s_add_i32 s3, s24, 6
	s_load_dwordx2 s[50:51], s[18:19], 0x0
	s_nop 0
	s_load_dwordx2 s[18:19], s[12:13], 0x0
	s_ashr_i32 s12, s3, 31
	s_lshr_b32 s12, s12, 29
	s_add_i32 s12, s3, s12
	s_and_b32 s12, s12, -8
	s_sub_i32 s12, s3, s12
	s_ashr_i32 s13, s12, 31
	s_lshl_b64 s[12:13], s[12:13], 3
	s_add_u32 s20, s4, s12
	s_addc_u32 s21, s5, s13
	s_add_u32 s12, s26, s12
	s_addc_u32 s13, s27, s13
	s_add_i32 s3, s24, 7
	s_load_dwordx2 s[52:53], s[20:21], 0x0
	s_nop 0
	s_load_dwordx2 s[20:21], s[12:13], 0x0
	s_ashr_i32 s12, s3, 31
	s_lshr_b32 s12, s12, 29
	s_add_i32 s12, s3, s12
	s_and_b32 s12, s12, -8
	s_sub_i32 s12, s3, s12
	s_ashr_i32 s13, s12, 31
	s_lshl_b64 s[12:13], s[12:13], 3
	s_add_u32 s4, s4, s12
	s_addc_u32 s5, s5, s13
	s_load_dwordx2 s[54:55], s[4:5], 0x0
	s_add_u32 s4, s26, s12
	s_addc_u32 s5, s27, s13
	s_ashr_i32 s3, s25, 31
	s_lshr_b32 s3, s3, 29
	s_add_i32 s3, s25, s3
	s_ashr_i32 s60, s3, 3
	s_load_dwordx2 s[6:7], s[6:7], 0x0
	s_lshl_b32 s61, s2, 5
	s_load_dwordx2 s[22:23], s[4:5], 0x0
	s_mul_i32 s4, s60, s24
	s_load_dwordx2 s[8:9], s[8:9], 0x0
	s_lshl_b32 s59, s33, 5
	s_load_dwordx2 s[10:11], s[10:11], 0x0
	s_add_i32 s3, s4, s60
	v_or_b32_e32 v2, s61, v3
	s_cmp_eq_u32 s24, 7
	s_cselect_b32 s3, s25, s3
	v_add_u32_e32 v4, s4, v2
	v_cmp_gt_i32_e32 vcc, s3, v4
	s_and_saveexec_b64 s[12:13], vcc
	s_cbranch_execz .LBB2_12
; %bb.1:                                ; %.lr.ph.preheader
	v_cvt_f32_u32_e32 v1, s59
	v_add_u32_e32 v5, s59, v4
	v_mov_b32_e32 v6, s59
	s_sub_i32 s25, 0, s59
	v_rcp_iflag_f32_e32 v7, v1
	v_cmp_gt_i32_e32 vcc, s3, v5
	v_max_i32_e32 v1, s3, v5
	s_mov_b32 s28, 0
	v_mul_f32_e32 v7, 0x4f7ffffe, v7
	v_cvt_u32_f32_e32 v7, v7
	v_addc_co_u32_e64 v5, s[4:5], v4, v6, vcc
	v_sub_u32_e32 v5, v1, v5
	v_mul_lo_u32 v6, s25, v7
	v_mul_hi_u32 v6, v7, v6
	v_add_u32_e32 v6, v7, v6
	v_mul_hi_u32 v6, v5, v6
	v_mul_lo_u32 v7, v6, s59
	v_sub_u32_e32 v5, v5, v7
	v_add_u32_e32 v7, 1, v6
	v_cmp_le_u32_e64 s[4:5], s59, v5
	s_mov_b64 s[30:31], -1
                                        ; implicit-def: $vgpr18
	s_nop 0
	v_cndmask_b32_e64 v6, v6, v7, s[4:5]
	v_subrev_u32_e32 v7, s59, v5
	v_cndmask_b32_e64 v5, v5, v7, s[4:5]
	v_add_u32_e32 v7, 1, v6
	v_cmp_le_u32_e64 s[4:5], s59, v5
	s_nop 1
	v_cndmask_b32_e64 v5, v6, v7, s[4:5]
	v_addc_co_u32_e32 v8, vcc, 1, v5, vcc
	v_cmp_lt_u32_e32 vcc, 1, v8
	v_mov_b32_e32 v5, 0
	v_mov_b32_e32 v6, v4
	s_and_saveexec_b64 s[4:5], vcc
	s_cbranch_execz .LBB2_7
; %bb.2:                                ; %vector.ph
	v_and_b32_e32 v9, -2, v8
	s_mov_b64 s[30:31], 0
	v_mov_b32_e32 v1, v9
	s_mov_b32 s29, s28
.LBB2_3:                                ; %vector.body
                                        ; =>This Inner Loop Header: Depth=1
	v_add_u32_e32 v1, -2, v1
	s_add_i32 s29, s29, 1
	s_add_i32 s28, s28, 1
	v_cmp_eq_u32_e32 vcc, 0, v1
	s_or_b64 s[30:31], vcc, s[30:31]
	v_mov_b64_e32 v[6:7], s[28:29]
	s_andn2_b64 exec, exec, s[30:31]
	s_cbranch_execnz .LBB2_3
; %bb.4:                                ; %middle.block
	s_or_b64 exec, exec, s[30:31]
	v_add_u32_e32 v18, v6, v7
	v_cmp_ne_u32_e32 vcc, v8, v9
	s_mov_b64 s[28:29], 0
	v_mov_b32_e32 v5, 0
                                        ; implicit-def: $vgpr6
                                        ; implicit-def: $vgpr1
	s_and_saveexec_b64 s[30:31], vcc
; %bb.5:                                ; %middle.block..lr.ph.preheader238_crit_edge
	v_mad_u64_u32 v[6:7], s[34:35], v9, s59, v[4:5]
	v_add_u32_e32 v1, s59, v6
	s_mov_b64 s[28:29], exec
	v_max_i32_e32 v1, s3, v1
	v_mov_b32_e32 v5, v18
; %bb.6:                                ; %Flow309
	s_or_b64 exec, exec, s[30:31]
	s_orn2_b64 s[30:31], s[28:29], exec
.LBB2_7:                                ; %Flow308
	s_or_b64 exec, exec, s[4:5]
	s_and_saveexec_b64 s[4:5], s[30:31]
	s_cbranch_execz .LBB2_11
; %bb.8:                                ; %.lr.ph.preheader238
	s_max_u32 s25, s59, 1
	v_cvt_f32_u32_e32 v7, s25
	v_sub_u32_e32 v1, v1, v6
	v_subrev_u32_e32 v8, s59, v1
	s_sub_i32 s28, 0, s25
	v_rcp_iflag_f32_e32 v7, v7
	v_min_u32_e32 v8, 1, v8
	v_add_u32_e32 v5, v5, v8
	v_sub_u32_e32 v1, v1, v8
	v_mul_f32_e32 v7, 0x4f7ffffe, v7
	v_cvt_u32_f32_e32 v7, v7
	v_subrev_u32_e32 v1, s59, v1
	v_mul_lo_u32 v8, s28, v7
	v_mul_hi_u32 v8, v7, v8
	v_add_u32_e32 v7, v7, v8
	v_mul_hi_u32 v7, v1, v7
	v_mul_lo_u32 v8, v7, s25
	v_sub_u32_e32 v1, v1, v8
	v_add_u32_e32 v9, 1, v7
	v_subrev_u32_e32 v8, s25, v1
	v_cmp_le_u32_e32 vcc, s25, v1
	s_mov_b64 s[28:29], 0
	s_nop 0
	v_cndmask_b32_e32 v1, v1, v8, vcc
	v_cndmask_b32_e32 v7, v7, v9, vcc
	v_add_u32_e32 v8, 1, v7
	v_cmp_le_u32_e32 vcc, s25, v1
	s_nop 1
	v_cndmask_b32_e32 v1, v7, v8, vcc
	v_add3_u32 v18, v5, v1, 1
.LBB2_9:                                ; %.lr.ph
                                        ; =>This Inner Loop Header: Depth=1
	v_add_u32_e32 v6, s59, v6
	v_cmp_le_i32_e32 vcc, s3, v6
	s_or_b64 s[28:29], vcc, s[28:29]
	s_andn2_b64 exec, exec, s[28:29]
	s_cbranch_execnz .LBB2_9
; %bb.10:                               ; %Flow307
	s_or_b64 exec, exec, s[28:29]
.LBB2_11:                               ; %Flow310
	s_or_b64 exec, exec, s[4:5]
.LBB2_12:                               ; %._crit_edge
	s_or_b64 exec, exec, s[12:13]
	s_load_dwordx2 s[36:37], s[0:1], 0x50
	s_mov_b32 s3, 0
	s_lshl_b64 s[4:5], s[2:3], 2
	v_cmp_gt_u32_e64 s[12:13], 8, v0
	v_lshlrev_b32_e32 v1, 3, v0
	s_waitcnt lgkmcnt(0)
	s_add_u32 s4, s36, s4
	s_addc_u32 s5, s37, s5
	s_load_dword s30, s[4:5], 0x1400
	s_add_u32 s34, s4, 0x1400
	s_addc_u32 s35, s5, 0
	v_lshlrev_b32_e32 v6, 2, v0
	s_waitcnt lgkmcnt(0)
	s_add_i32 s30, s30, 1
	s_and_saveexec_b64 s[4:5], s[12:13]
	s_cbranch_execz .LBB2_15
; %bb.13:
	global_load_dwordx2 v[10:11], v1, s[26:27]
	s_mov_b32 s25, s58
	s_lshl_b64 s[28:29], s[2:3], 5
	s_lshl_b64 s[48:49], s[24:25], 2
	s_add_u32 s48, s48, s28
	s_addc_u32 s49, s49, s29
	s_add_u32 s28, s36, s28
	v_mov_b32_e32 v7, 0
	s_addc_u32 s29, s37, s29
	v_mov_b32_e32 v5, s30
	v_lshl_add_u64 v[8:9], s[28:29], 0, v[6:7]
	s_mov_b64 s[28:29], 0
	s_waitcnt vmcnt(0)
	v_lshl_add_u64 v[10:11], s[48:49], 0, v[10:11]
	global_store_dword v[10:11], v5, off sc0 sc1
.LBB2_14:                               ; =>This Inner Loop Header: Depth=1
	global_load_dword v5, v[8:9], off sc1
	s_waitcnt vmcnt(0)
	v_cmp_le_u32_e32 vcc, s30, v5
	s_or_b64 s[28:29], vcc, s[28:29]
	s_andn2_b64 exec, exec, s[28:29]
	s_cbranch_execnz .LBB2_14
.LBB2_15:                               ; %Flow305
	s_or_b64 exec, exec, s[4:5]
	s_load_dwordx2 s[28:29], s[0:1], 0x58
	v_cmp_eq_u32_e64 s[4:5], 0, v0
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_saveexec_b64 s[0:1], s[4:5]
	s_cbranch_execz .LBB2_17
; %bb.16:
	v_mov_b32_e32 v5, 0
	v_mov_b32_e32 v7, s30
	global_store_dword v5, v7, s[34:35]
.LBB2_17:                               ; %_ZN7commkit10start_syncILi8EEEvRKNS_11RankSignalsEPNS_6SignalEi.exit
	s_or_b64 exec, exec, s[0:1]
	s_add_u32 s30, s6, 0x1780
	s_addc_u32 s31, s7, 0
	s_add_u32 s25, s8, 0x1780
	s_addc_u32 s74, s9, 0
	s_add_u32 s62, s10, 0x1780
	s_addc_u32 s73, s11, 0
	s_add_u32 s63, s14, 0x1780
	s_addc_u32 s72, s15, 0
	s_add_u32 s64, s16, 0x1780
	s_addc_u32 s71, s17, 0
	s_add_u32 s65, s18, 0x1780
	s_addc_u32 s70, s19, 0
	s_add_u32 s66, s20, 0x1780
	s_addc_u32 s69, s21, 0
	s_movk_i32 s6, 0x100
	s_add_u32 s67, s22, 0x1780
	v_cmp_gt_u32_e32 vcc, s6, v0
	s_movk_i32 s6, 0xff
	s_addc_u32 s68, s23, 0
	v_lshrrev_b32_e32 v19, 5, v0
	v_cmp_gt_u32_e64 s[0:1], 2, v18
	v_cmp_lt_u32_e64 s[6:7], s6, v0
	s_and_saveexec_b64 s[8:9], s[0:1]
	s_xor_b64 s[22:23], exec, s[8:9]
	s_cbranch_execz .LBB2_23
; %bb.18:
	s_and_saveexec_b64 s[48:49], vcc
	s_cbranch_execz .LBB2_22
; %bb.19:
	v_mov_b32_e32 v5, s39
	v_mov_b32_e32 v7, s41
	v_cmp_eq_u32_e64 s[0:1], 1, v19
	v_cmp_eq_u32_e64 s[8:9], 2, v19
	v_cmp_eq_u32_e64 s[10:11], 3, v19
	v_cndmask_b32_e64 v5, v5, v7, s[0:1]
	v_mov_b32_e32 v7, s43
	v_cndmask_b32_e64 v5, v5, v7, s[8:9]
	v_mov_b32_e32 v7, s45
	v_cndmask_b32_e64 v5, v5, v7, s[10:11]
	v_mov_b32_e32 v7, s47
	v_cmp_eq_u32_e64 s[14:15], 4, v19
	v_cmp_eq_u32_e64 s[16:17], 5, v19
	v_cmp_eq_u32_e64 s[18:19], 6, v19
	v_cndmask_b32_e64 v5, v5, v7, s[14:15]
	v_mov_b32_e32 v7, s51
	v_cndmask_b32_e64 v5, v5, v7, s[16:17]
	v_mov_b32_e32 v7, s53
	v_cndmask_b32_e64 v5, v5, v7, s[18:19]
	v_mov_b32_e32 v7, s55
	v_cmp_eq_u32_e64 s[20:21], 7, v19
	s_nop 1
	v_cndmask_b32_e64 v9, v5, v7, s[20:21]
	v_mov_b32_e32 v5, s38
	v_mov_b32_e32 v7, s40
	v_cndmask_b32_e64 v5, v5, v7, s[0:1]
	v_mov_b32_e32 v7, s42
	v_cndmask_b32_e64 v5, v5, v7, s[8:9]
	v_mov_b32_e32 v7, s44
	v_cndmask_b32_e64 v5, v5, v7, s[10:11]
	v_mov_b32_e32 v7, s46
	v_cndmask_b32_e64 v5, v5, v7, s[14:15]
	v_mov_b32_e32 v7, s50
	v_cndmask_b32_e64 v5, v5, v7, s[16:17]
	v_mov_b32_e32 v7, s52
	v_cndmask_b32_e64 v5, v5, v7, s[18:19]
	v_mov_b32_e32 v7, s54
	v_cndmask_b32_e64 v8, v5, v7, s[20:21]
	v_ashrrev_i32_e32 v5, 31, v4
	v_lshl_add_u64 v[8:9], v[4:5], 4, v[8:9]
	flat_load_dwordx4 v[8:11], v[8:9]
	v_lshlrev_b32_e32 v7, 4, v0
	v_cmp_gt_u32_e64 s[0:1], 32, v0
	s_waitcnt vmcnt(0) lgkmcnt(0)
	ds_write_b128 v7, v[8:11]
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_saveexec_b64 s[8:9], s[0:1]
	s_cbranch_execz .LBB2_21
; %bb.20:                               ; %.preheader5.i213
	v_lshlrev_b32_e32 v0, 4, v3
	ds_read_b128 v[8:11], v0
	ds_read_b128 v[12:15], v0 offset:512
	s_mov_b32 s0, 0x7060302
	s_waitcnt lgkmcnt(1)
	v_and_b32_e32 v17, 0xffff0000, v8
	v_lshlrev_b32_e32 v16, 16, v8
	s_waitcnt lgkmcnt(0)
	v_and_b32_e32 v43, 0xffff0000, v12
	v_lshlrev_b32_e32 v42, 16, v12
	v_and_b32_e32 v37, 0xffff0000, v9
	v_lshlrev_b32_e32 v36, 16, v9
	v_and_b32_e32 v39, 0xffff0000, v10
	v_lshlrev_b32_e32 v38, 16, v10
	v_and_b32_e32 v41, 0xffff0000, v11
	v_lshlrev_b32_e32 v40, 16, v11
	v_and_b32_e32 v45, 0xffff0000, v13
	v_lshlrev_b32_e32 v44, 16, v13
	v_and_b32_e32 v47, 0xffff0000, v14
	v_lshlrev_b32_e32 v46, 16, v14
	v_and_b32_e32 v49, 0xffff0000, v15
	v_lshlrev_b32_e32 v48, 16, v15
	ds_read_b128 v[8:11], v0 offset:1024
	ds_read_b128 v[12:15], v0 offset:1536
	ds_read_b128 v[20:23], v0 offset:2048
	ds_read_b128 v[24:27], v0 offset:2560
	ds_read_b128 v[28:31], v0 offset:3072
	ds_read_b128 v[32:35], v0 offset:3584
	v_pk_add_f32 v[16:17], v[16:17], v[42:43]
	s_waitcnt lgkmcnt(5)
	v_and_b32_e32 v43, 0xffff0000, v8
	v_lshlrev_b32_e32 v42, 16, v8
	v_pk_add_f32 v[16:17], v[16:17], v[42:43]
	s_waitcnt lgkmcnt(4)
	v_and_b32_e32 v43, 0xffff0000, v12
	v_lshlrev_b32_e32 v42, 16, v12
	v_pk_add_f32 v[16:17], v[16:17], v[42:43]
	s_waitcnt lgkmcnt(3)
	v_and_b32_e32 v43, 0xffff0000, v20
	v_lshlrev_b32_e32 v42, 16, v20
	v_pk_add_f32 v[16:17], v[16:17], v[42:43]
	s_waitcnt lgkmcnt(2)
	v_and_b32_e32 v43, 0xffff0000, v24
	v_lshlrev_b32_e32 v42, 16, v24
	v_pk_add_f32 v[16:17], v[16:17], v[42:43]
	s_waitcnt lgkmcnt(1)
	v_and_b32_e32 v43, 0xffff0000, v28
	v_lshlrev_b32_e32 v42, 16, v28
	v_pk_add_f32 v[16:17], v[16:17], v[42:43]
	s_waitcnt lgkmcnt(0)
	v_and_b32_e32 v43, 0xffff0000, v32
	v_lshlrev_b32_e32 v42, 16, v32
	v_pk_add_f32 v[16:17], v[16:17], v[42:43]
	v_pk_add_f32 v[36:37], v[36:37], v[44:45]
	v_and_b32_e32 v43, 0xffff0000, v9
	v_lshlrev_b32_e32 v42, 16, v9
	v_pk_add_f32 v[8:9], v[36:37], v[42:43]
	v_and_b32_e32 v37, 0xffff0000, v13
	v_lshlrev_b32_e32 v36, 16, v13
	v_pk_add_f32 v[8:9], v[8:9], v[36:37]
	v_and_b32_e32 v13, 0xffff0000, v21
	v_lshlrev_b32_e32 v12, 16, v21
	v_pk_add_f32 v[8:9], v[8:9], v[12:13]
	v_and_b32_e32 v13, 0xffff0000, v25
	v_lshlrev_b32_e32 v12, 16, v25
	v_pk_add_f32 v[8:9], v[8:9], v[12:13]
	v_and_b32_e32 v13, 0xffff0000, v29
	v_lshlrev_b32_e32 v12, 16, v29
	v_pk_add_f32 v[8:9], v[8:9], v[12:13]
	v_and_b32_e32 v13, 0xffff0000, v33
	v_lshlrev_b32_e32 v12, 16, v33
	v_pk_add_f32 v[8:9], v[8:9], v[12:13]
	v_pk_add_f32 v[12:13], v[38:39], v[46:47]
	v_and_b32_e32 v21, 0xffff0000, v10
	v_lshlrev_b32_e32 v20, 16, v10
	v_pk_add_f32 v[12:13], v[12:13], v[20:21]
	v_and_b32_e32 v21, 0xffff0000, v14
	v_lshlrev_b32_e32 v20, 16, v14
	v_pk_add_f32 v[12:13], v[12:13], v[20:21]
	v_and_b32_e32 v21, 0xffff0000, v22
	v_lshlrev_b32_e32 v20, 16, v22
	v_pk_add_f32 v[12:13], v[12:13], v[20:21]
	v_and_b32_e32 v21, 0xffff0000, v26
	v_lshlrev_b32_e32 v20, 16, v26
	v_pk_add_f32 v[12:13], v[12:13], v[20:21]
	v_and_b32_e32 v21, 0xffff0000, v30
	v_lshlrev_b32_e32 v20, 16, v30
	v_pk_add_f32 v[12:13], v[12:13], v[20:21]
	v_and_b32_e32 v21, 0xffff0000, v34
	v_lshlrev_b32_e32 v20, 16, v34
	v_pk_add_f32 v[12:13], v[12:13], v[20:21]
	v_pk_add_f32 v[20:21], v[40:41], v[48:49]
	v_and_b32_e32 v25, 0xffff0000, v11
	v_lshlrev_b32_e32 v24, 16, v11
	v_pk_add_f32 v[10:11], v[20:21], v[24:25]
	v_and_b32_e32 v21, 0xffff0000, v15
	v_lshlrev_b32_e32 v20, 16, v15
	v_pk_add_f32 v[10:11], v[10:11], v[20:21]
	v_and_b32_e32 v15, 0xffff0000, v23
	v_lshlrev_b32_e32 v14, 16, v23
	v_pk_add_f32 v[10:11], v[10:11], v[14:15]
	v_and_b32_e32 v15, 0xffff0000, v27
	v_lshlrev_b32_e32 v14, 16, v27
	v_pk_add_f32 v[10:11], v[10:11], v[14:15]
	v_and_b32_e32 v15, 0xffff0000, v31
	v_lshlrev_b32_e32 v14, 16, v31
	v_pk_add_f32 v[10:11], v[10:11], v[14:15]
	v_and_b32_e32 v15, 0xffff0000, v35
	v_lshlrev_b32_e32 v14, 16, v35
	v_pk_add_f32 v[10:11], v[10:11], v[14:15]
	v_perm_b32 v9, v9, v8, s0
	v_perm_b32 v11, v11, v10, s0
	v_perm_b32 v10, v13, v12, s0
	v_perm_b32 v8, v17, v16, s0
	ds_write_b128 v0, v[8:11]
	ds_write_b128 v0, v[8:11] offset:512
	ds_write_b128 v0, v[8:11] offset:1024
	ds_write_b128 v0, v[8:11] offset:1536
	ds_write_b128 v0, v[8:11] offset:2048
	ds_write_b128 v0, v[8:11] offset:2560
	ds_write_b128 v0, v[8:11] offset:3072
	ds_write_b128 v0, v[8:11] offset:3584
.LBB2_21:                               ; %_ZN7commkit7kernels6step_aIDF16bLb1EEEvPT_ii.exit221
	s_or_b64 exec, exec, s[8:9]
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read_b128 v[8:11], v7
	v_mov_b32_e32 v0, s31
	v_mov_b32_e32 v7, s74
	v_cmp_eq_u32_e64 s[0:1], 1, v19
	v_cmp_eq_u32_e64 s[8:9], 2, v19
	v_cmp_eq_u32_e64 s[10:11], 3, v19
	v_cndmask_b32_e64 v0, v0, v7, s[0:1]
	v_mov_b32_e32 v7, s73
	v_cndmask_b32_e64 v0, v0, v7, s[8:9]
	v_mov_b32_e32 v7, s72
	v_cndmask_b32_e64 v0, v0, v7, s[10:11]
	v_mov_b32_e32 v7, s71
	v_cmp_eq_u32_e64 s[14:15], 4, v19
	v_cmp_eq_u32_e64 s[16:17], 5, v19
	v_cmp_eq_u32_e64 s[18:19], 6, v19
	v_cndmask_b32_e64 v0, v0, v7, s[14:15]
	v_mov_b32_e32 v7, s70
	v_cndmask_b32_e64 v0, v0, v7, s[16:17]
	v_mov_b32_e32 v7, s69
	v_cndmask_b32_e64 v0, v0, v7, s[18:19]
	v_mov_b32_e32 v7, s68
	v_cmp_eq_u32_e64 s[20:21], 7, v19
	s_nop 1
	v_cndmask_b32_e64 v13, v0, v7, s[20:21]
	v_mov_b32_e32 v0, s30
	v_mov_b32_e32 v7, s25
	v_cndmask_b32_e64 v0, v0, v7, s[0:1]
	v_mov_b32_e32 v7, s62
	v_cndmask_b32_e64 v0, v0, v7, s[8:9]
	v_mov_b32_e32 v7, s63
	v_cndmask_b32_e64 v0, v0, v7, s[10:11]
	v_mov_b32_e32 v7, s64
	v_cndmask_b32_e64 v0, v0, v7, s[14:15]
	v_mov_b32_e32 v7, s65
	v_cndmask_b32_e64 v0, v0, v7, s[16:17]
	v_mov_b32_e32 v7, s66
	v_cndmask_b32_e64 v0, v0, v7, s[18:19]
	v_mov_b32_e32 v7, s67
	v_cndmask_b32_e64 v12, v0, v7, s[20:21]
	v_lshl_add_u64 v[4:5], v[4:5], 4, v[12:13]
	s_waitcnt lgkmcnt(0)
	flat_store_dwordx4 v[4:5], v[8:11]
.LBB2_22:                               ; %Flow280
	s_or_b64 exec, exec, s[48:49]
                                        ; implicit-def: $vgpr0
                                        ; implicit-def: $vgpr4
.LBB2_23:                               ; %Flow301
	s_or_saveexec_b64 s[48:49], s[22:23]
	v_lshrrev_b32_e32 v20, 1, v18
	s_xor_b64 exec, exec, s[48:49]
	s_cbranch_execz .LBB2_74
; %bb.24:
	v_lshlrev_b32_e32 v7, 4, v0
	s_and_saveexec_b64 s[22:23], vcc
	s_cbranch_execz .LBB2_26
; %bb.25:
	v_mov_b32_e32 v5, s39
	v_mov_b32_e32 v8, s41
	v_cmp_eq_u32_e64 s[0:1], 1, v19
	v_cmp_eq_u32_e64 s[8:9], 2, v19
	v_cmp_eq_u32_e64 s[10:11], 3, v19
	v_cndmask_b32_e64 v5, v5, v8, s[0:1]
	v_mov_b32_e32 v8, s43
	v_cndmask_b32_e64 v5, v5, v8, s[8:9]
	v_mov_b32_e32 v8, s45
	v_cndmask_b32_e64 v5, v5, v8, s[10:11]
	v_mov_b32_e32 v8, s47
	v_cmp_eq_u32_e64 s[14:15], 4, v19
	v_cmp_eq_u32_e64 s[16:17], 5, v19
	v_cmp_eq_u32_e64 s[18:19], 6, v19
	v_cndmask_b32_e64 v5, v5, v8, s[14:15]
	v_mov_b32_e32 v8, s51
	v_cndmask_b32_e64 v5, v5, v8, s[16:17]
	v_mov_b32_e32 v8, s53
	v_cndmask_b32_e64 v5, v5, v8, s[18:19]
	v_mov_b32_e32 v8, s55
	v_cmp_eq_u32_e64 s[20:21], 7, v19
	s_nop 1
	v_cndmask_b32_e64 v9, v5, v8, s[20:21]
	v_mov_b32_e32 v5, s38
	v_mov_b32_e32 v8, s40
	v_cndmask_b32_e64 v5, v5, v8, s[0:1]
	v_mov_b32_e32 v8, s42
	v_cndmask_b32_e64 v5, v5, v8, s[8:9]
	v_mov_b32_e32 v8, s44
	v_cndmask_b32_e64 v5, v5, v8, s[10:11]
	v_mov_b32_e32 v8, s46
	v_cndmask_b32_e64 v5, v5, v8, s[14:15]
	v_mov_b32_e32 v8, s50
	v_cndmask_b32_e64 v5, v5, v8, s[16:17]
	v_mov_b32_e32 v8, s52
	v_cndmask_b32_e64 v5, v5, v8, s[18:19]
	v_mov_b32_e32 v8, s54
	v_cndmask_b32_e64 v8, v5, v8, s[20:21]
	v_ashrrev_i32_e32 v5, 31, v4
	v_lshl_add_u64 v[8:9], v[4:5], 4, v[8:9]
	flat_load_dwordx4 v[8:11], v[8:9]
	s_waitcnt vmcnt(0) lgkmcnt(0)
	ds_write_b128 v7, v[8:11]
.LBB2_26:
	s_or_b64 exec, exec, s[22:23]
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_saveexec_b64 s[0:1], s[6:7]
	s_xor_b64 s[22:23], exec, s[0:1]
	s_cbranch_execz .LBB2_28
; %bb.27:
	v_add_u32_e32 v5, -8, v19
	v_mov_b32_e32 v8, s39
	v_mov_b32_e32 v9, s41
	v_cmp_eq_u32_e64 s[0:1], 1, v5
	v_cmp_eq_u32_e64 s[8:9], 2, v5
	v_cmp_eq_u32_e64 s[10:11], 3, v5
	v_cndmask_b32_e64 v8, v8, v9, s[0:1]
	v_mov_b32_e32 v9, s43
	v_cndmask_b32_e64 v8, v8, v9, s[8:9]
	v_mov_b32_e32 v9, s45
	v_cndmask_b32_e64 v8, v8, v9, s[10:11]
	v_mov_b32_e32 v9, s47
	v_cmp_eq_u32_e64 s[14:15], 4, v5
	v_cmp_eq_u32_e64 s[16:17], 5, v5
	v_cmp_eq_u32_e64 s[18:19], 6, v5
	v_cndmask_b32_e64 v8, v8, v9, s[14:15]
	v_mov_b32_e32 v9, s51
	v_cndmask_b32_e64 v8, v8, v9, s[16:17]
	v_mov_b32_e32 v9, s53
	v_cndmask_b32_e64 v8, v8, v9, s[18:19]
	v_mov_b32_e32 v9, s55
	v_cmp_eq_u32_e64 s[20:21], 7, v5
	v_mov_b32_e32 v5, s38
	v_add_u32_e32 v10, s59, v4
	v_cndmask_b32_e64 v9, v8, v9, s[20:21]
	v_mov_b32_e32 v8, s40
	v_cndmask_b32_e64 v5, v5, v8, s[0:1]
	v_mov_b32_e32 v8, s42
	v_cndmask_b32_e64 v5, v5, v8, s[8:9]
	v_mov_b32_e32 v8, s44
	v_cndmask_b32_e64 v5, v5, v8, s[10:11]
	v_mov_b32_e32 v8, s46
	v_cndmask_b32_e64 v5, v5, v8, s[14:15]
	v_mov_b32_e32 v8, s50
	v_cndmask_b32_e64 v5, v5, v8, s[16:17]
	v_mov_b32_e32 v8, s52
	v_cndmask_b32_e64 v5, v5, v8, s[18:19]
	v_mov_b32_e32 v8, s54
	v_cndmask_b32_e64 v8, v5, v8, s[20:21]
	v_ashrrev_i32_e32 v11, 31, v10
	v_lshl_add_u64 v[8:9], v[10:11], 4, v[8:9]
	flat_load_dwordx4 v[8:11], v[8:9]
	s_waitcnt vmcnt(0) lgkmcnt(0)
	ds_write_b128 v7, v[8:11]
.LBB2_28:                               ; %Flow299
	s_andn2_saveexec_b64 s[8:9], s[22:23]
	s_cbranch_execz .LBB2_32
; %bb.29:
	v_cmp_gt_u32_e64 s[0:1], 32, v0
	s_and_saveexec_b64 s[10:11], s[0:1]
	s_cbranch_execz .LBB2_31
; %bb.30:                               ; %.preheader5.i
	v_lshlrev_b32_e32 v5, 4, v3
	ds_read_b128 v[8:11], v5
	ds_read_b128 v[12:15], v5 offset:512
	s_mov_b32 s0, 0x7060302
	s_waitcnt lgkmcnt(0)
	v_and_b32_e32 v17, 0xffff0000, v8
	v_lshlrev_b32_e32 v16, 16, v8
	v_and_b32_e32 v45, 0xffff0000, v12
	v_lshlrev_b32_e32 v44, 16, v12
	v_and_b32_e32 v39, 0xffff0000, v9
	v_lshlrev_b32_e32 v38, 16, v9
	v_and_b32_e32 v41, 0xffff0000, v10
	v_lshlrev_b32_e32 v40, 16, v10
	v_and_b32_e32 v43, 0xffff0000, v11
	v_lshlrev_b32_e32 v42, 16, v11
	v_and_b32_e32 v47, 0xffff0000, v13
	v_lshlrev_b32_e32 v46, 16, v13
	v_and_b32_e32 v49, 0xffff0000, v14
	v_lshlrev_b32_e32 v48, 16, v14
	v_and_b32_e32 v51, 0xffff0000, v15
	v_lshlrev_b32_e32 v50, 16, v15
	ds_read_b128 v[8:11], v5 offset:1024
	ds_read_b128 v[12:15], v5 offset:1536
	ds_read_b128 v[22:25], v5 offset:2048
	ds_read_b128 v[26:29], v5 offset:2560
	ds_read_b128 v[30:33], v5 offset:3072
	ds_read_b128 v[34:37], v5 offset:3584
	v_pk_add_f32 v[16:17], v[16:17], v[44:45]
	s_waitcnt lgkmcnt(0)
	v_and_b32_e32 v45, 0xffff0000, v8
	v_lshlrev_b32_e32 v44, 16, v8
	v_pk_add_f32 v[16:17], v[16:17], v[44:45]
	v_and_b32_e32 v45, 0xffff0000, v12
	v_lshlrev_b32_e32 v44, 16, v12
	v_pk_add_f32 v[16:17], v[16:17], v[44:45]
	v_and_b32_e32 v45, 0xffff0000, v22
	v_lshlrev_b32_e32 v44, 16, v22
	v_pk_add_f32 v[16:17], v[16:17], v[44:45]
	v_and_b32_e32 v45, 0xffff0000, v26
	v_lshlrev_b32_e32 v44, 16, v26
	v_pk_add_f32 v[16:17], v[16:17], v[44:45]
	v_and_b32_e32 v45, 0xffff0000, v30
	v_lshlrev_b32_e32 v44, 16, v30
	v_pk_add_f32 v[16:17], v[16:17], v[44:45]
	v_and_b32_e32 v45, 0xffff0000, v34
	v_lshlrev_b32_e32 v44, 16, v34
	v_pk_add_f32 v[16:17], v[16:17], v[44:45]
	v_pk_add_f32 v[38:39], v[38:39], v[46:47]
	v_and_b32_e32 v45, 0xffff0000, v9
	v_lshlrev_b32_e32 v44, 16, v9
	v_pk_add_f32 v[8:9], v[38:39], v[44:45]
	v_and_b32_e32 v39, 0xffff0000, v13
	v_lshlrev_b32_e32 v38, 16, v13
	v_pk_add_f32 v[8:9], v[8:9], v[38:39]
	v_and_b32_e32 v13, 0xffff0000, v23
	v_lshlrev_b32_e32 v12, 16, v23
	v_pk_add_f32 v[8:9], v[8:9], v[12:13]
	v_and_b32_e32 v13, 0xffff0000, v27
	v_lshlrev_b32_e32 v12, 16, v27
	v_pk_add_f32 v[8:9], v[8:9], v[12:13]
	v_and_b32_e32 v13, 0xffff0000, v31
	v_lshlrev_b32_e32 v12, 16, v31
	v_pk_add_f32 v[8:9], v[8:9], v[12:13]
	v_and_b32_e32 v13, 0xffff0000, v35
	v_lshlrev_b32_e32 v12, 16, v35
	v_pk_add_f32 v[8:9], v[8:9], v[12:13]
	v_pk_add_f32 v[12:13], v[40:41], v[48:49]
	v_and_b32_e32 v23, 0xffff0000, v10
	v_lshlrev_b32_e32 v22, 16, v10
	v_pk_add_f32 v[12:13], v[12:13], v[22:23]
	v_and_b32_e32 v23, 0xffff0000, v14
	v_lshlrev_b32_e32 v22, 16, v14
	v_pk_add_f32 v[12:13], v[12:13], v[22:23]
	v_and_b32_e32 v23, 0xffff0000, v24
	v_lshlrev_b32_e32 v22, 16, v24
	v_pk_add_f32 v[12:13], v[12:13], v[22:23]
	v_and_b32_e32 v23, 0xffff0000, v28
	v_lshlrev_b32_e32 v22, 16, v28
	v_pk_add_f32 v[12:13], v[12:13], v[22:23]
	v_and_b32_e32 v23, 0xffff0000, v32
	v_lshlrev_b32_e32 v22, 16, v32
	v_pk_add_f32 v[12:13], v[12:13], v[22:23]
	v_and_b32_e32 v23, 0xffff0000, v36
	v_lshlrev_b32_e32 v22, 16, v36
	v_pk_add_f32 v[12:13], v[12:13], v[22:23]
	v_pk_add_f32 v[22:23], v[42:43], v[50:51]
	v_and_b32_e32 v27, 0xffff0000, v11
	v_lshlrev_b32_e32 v26, 16, v11
	v_pk_add_f32 v[10:11], v[22:23], v[26:27]
	v_and_b32_e32 v23, 0xffff0000, v15
	v_lshlrev_b32_e32 v22, 16, v15
	v_pk_add_f32 v[10:11], v[10:11], v[22:23]
	v_and_b32_e32 v15, 0xffff0000, v25
	v_lshlrev_b32_e32 v14, 16, v25
	v_pk_add_f32 v[10:11], v[10:11], v[14:15]
	v_and_b32_e32 v15, 0xffff0000, v29
	v_lshlrev_b32_e32 v14, 16, v29
	v_pk_add_f32 v[10:11], v[10:11], v[14:15]
	v_and_b32_e32 v15, 0xffff0000, v33
	v_lshlrev_b32_e32 v14, 16, v33
	v_pk_add_f32 v[10:11], v[10:11], v[14:15]
	v_and_b32_e32 v15, 0xffff0000, v37
	v_lshlrev_b32_e32 v14, 16, v37
	v_pk_add_f32 v[10:11], v[10:11], v[14:15]
	v_perm_b32 v9, v9, v8, s0
	v_perm_b32 v11, v11, v10, s0
	v_perm_b32 v10, v13, v12, s0
	v_perm_b32 v8, v17, v16, s0
	ds_write_b128 v5, v[8:11]
	ds_write_b128 v5, v[8:11] offset:512
	ds_write_b128 v5, v[8:11] offset:1024
	ds_write_b128 v5, v[8:11] offset:1536
	ds_write_b128 v5, v[8:11] offset:2048
	ds_write_b128 v5, v[8:11] offset:2560
	ds_write_b128 v5, v[8:11] offset:3072
	ds_write_b128 v5, v[8:11] offset:3584
.LBB2_31:                               ; %Flow298
	s_or_b64 exec, exec, s[10:11]
.LBB2_32:                               ; %_ZN7commkit7kernels6step_aIDF16bLb1EEEvPT_ii.exit
	s_or_b64 exec, exec, s[8:9]
	v_add_u32_e32 v5, -1, v20
	v_cmp_lt_u32_e64 s[0:1], 3, v18
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_saveexec_b64 s[56:57], s[0:1]
	s_cbranch_execz .LBB2_47
; %bb.33:                               ; %.lr.ph230
	v_mov_b32_e32 v12, s31
	v_mov_b32_e32 v13, s74
	v_cmp_eq_u32_e64 s[0:1], 1, v19
	v_mov_b32_e32 v33, s39
	v_mov_b32_e32 v34, s41
	v_cndmask_b32_e64 v8, v12, v13, s[0:1]
	v_mov_b32_e32 v14, s73
	v_cmp_eq_u32_e64 s[10:11], 2, v19
	v_cndmask_b32_e64 v10, v33, v34, s[0:1]
	v_mov_b32_e32 v35, s43
	v_cndmask_b32_e64 v8, v8, v14, s[10:11]
	v_mov_b32_e32 v15, s72
	v_cmp_eq_u32_e64 s[14:15], 3, v19
	v_cndmask_b32_e64 v10, v10, v35, s[10:11]
	v_mov_b32_e32 v36, s45
	v_cndmask_b32_e64 v8, v8, v15, s[14:15]
	v_mov_b32_e32 v16, s71
	v_cmp_eq_u32_e64 s[16:17], 4, v19
	v_cndmask_b32_e64 v10, v10, v36, s[14:15]
	v_mov_b32_e32 v37, s47
	v_cndmask_b32_e64 v8, v8, v16, s[16:17]
	v_mov_b32_e32 v17, s70
	v_cmp_eq_u32_e64 s[18:19], 5, v19
	v_cndmask_b32_e64 v10, v10, v37, s[16:17]
	v_mov_b32_e32 v38, s51
	v_cndmask_b32_e64 v8, v8, v17, s[18:19]
	v_mov_b32_e32 v23, s69
	v_cmp_eq_u32_e64 s[20:21], 6, v19
	v_cndmask_b32_e64 v10, v10, v38, s[18:19]
	v_mov_b32_e32 v39, s53
	v_cndmask_b32_e64 v8, v8, v23, s[20:21]
	v_mov_b32_e32 v24, s68
	v_cmp_eq_u32_e64 s[22:23], 7, v19
	v_mov_b32_e32 v25, s30
	v_mov_b32_e32 v26, s25
	v_cndmask_b32_e64 v10, v10, v39, s[20:21]
	v_mov_b32_e32 v40, s55
	v_mov_b32_e32 v41, s38
	v_mov_b32_e32 v42, s40
	v_add_u32_e32 v49, -8, v19
	v_cndmask_b32_e64 v9, v8, v24, s[22:23]
	v_cndmask_b32_e64 v8, v25, v26, s[0:1]
	v_mov_b32_e32 v27, s62
	v_cndmask_b32_e64 v11, v10, v40, s[22:23]
	v_cndmask_b32_e64 v10, v41, v42, s[0:1]
	v_mov_b32_e32 v43, s42
	v_cmp_eq_u32_e64 s[0:1], 1, v49
	v_cndmask_b32_e64 v8, v8, v27, s[10:11]
	v_cndmask_b32_e64 v10, v10, v43, s[10:11]
	v_cndmask_b32_e64 v12, v12, v13, s[0:1]
	v_cmp_eq_u32_e64 s[10:11], 2, v49
	v_mov_b32_e32 v28, s63
	v_mov_b32_e32 v44, s44
	v_cndmask_b32_e64 v12, v12, v14, s[10:11]
	v_cndmask_b32_e64 v14, v33, v34, s[0:1]
	v_cndmask_b32_e64 v8, v8, v28, s[14:15]
	v_mov_b32_e32 v29, s64
	v_cndmask_b32_e64 v10, v10, v44, s[14:15]
	v_mov_b32_e32 v45, s46
	v_cmp_eq_u32_e64 s[14:15], 3, v49
	v_cndmask_b32_e64 v14, v14, v35, s[10:11]
	v_cndmask_b32_e64 v8, v8, v29, s[16:17]
	v_mov_b32_e32 v30, s65
	v_cndmask_b32_e64 v10, v10, v45, s[16:17]
	v_mov_b32_e32 v46, s50
	v_cndmask_b32_e64 v12, v12, v15, s[14:15]
	v_cmp_eq_u32_e64 s[16:17], 4, v49
	v_cndmask_b32_e64 v14, v14, v36, s[14:15]
	v_cndmask_b32_e64 v8, v8, v30, s[18:19]
	v_mov_b32_e32 v31, s66
	v_cndmask_b32_e64 v10, v10, v46, s[18:19]
	v_mov_b32_e32 v47, s52
	v_cndmask_b32_e64 v12, v12, v16, s[16:17]
	v_cmp_eq_u32_e64 s[18:19], 5, v49
	v_cndmask_b32_e64 v14, v14, v37, s[16:17]
	v_cndmask_b32_e64 v8, v8, v31, s[20:21]
	v_mov_b32_e32 v32, s67
	v_cndmask_b32_e64 v10, v10, v47, s[20:21]
	v_mov_b32_e32 v48, s54
	v_cndmask_b32_e64 v12, v12, v17, s[18:19]
	v_cmp_eq_u32_e64 s[20:21], 6, v49
	v_cndmask_b32_e64 v14, v14, v38, s[18:19]
	v_cndmask_b32_e64 v8, v8, v32, s[22:23]
	v_cndmask_b32_e64 v10, v10, v48, s[22:23]
	v_cndmask_b32_e64 v12, v12, v23, s[20:21]
	v_cmp_eq_u32_e64 s[22:23], 7, v49
	v_cndmask_b32_e64 v14, v14, v39, s[20:21]
	v_lshlrev_b32_e32 v21, 4, v3
	v_cndmask_b32_e64 v13, v12, v24, s[22:23]
	v_cndmask_b32_e64 v12, v25, v26, s[0:1]
	v_cndmask_b32_e64 v15, v14, v40, s[22:23]
	v_cndmask_b32_e64 v14, v41, v42, s[0:1]
	v_cndmask_b32_e64 v12, v12, v27, s[10:11]
	v_cndmask_b32_e64 v14, v14, v43, s[10:11]
	v_cndmask_b32_e64 v12, v12, v28, s[14:15]
	v_cndmask_b32_e64 v14, v14, v44, s[14:15]
	v_cndmask_b32_e64 v12, v12, v29, s[16:17]
	v_cndmask_b32_e64 v14, v14, v45, s[16:17]
	v_cndmask_b32_e64 v12, v12, v30, s[18:19]
	v_cndmask_b32_e64 v14, v14, v46, s[18:19]
	v_cndmask_b32_e64 v12, v12, v31, s[20:21]
	v_cndmask_b32_e64 v14, v14, v47, s[20:21]
	v_cmp_eq_u32_e64 s[8:9], 8, v19
	v_or_b32_e32 v22, 0x1000, v21
	v_cndmask_b32_e64 v12, v12, v32, s[22:23]
	v_cndmask_b32_e64 v14, v14, v48, s[22:23]
	v_cmp_gt_u32_e64 s[10:11], 32, v0
	s_lshl_b32 s18, s59, 1
	s_mul_i32 s19, s33, 0x60
	s_mov_b64 s[14:15], 0
	s_mov_b32 s20, 0x7060302
	v_mov_b32_e32 v16, v4
	v_mov_b32_e32 v23, v5
	s_branch .LBB2_36
.LBB2_34:                               ; %Flow292
                                        ;   in Loop: Header=BB2_36 Depth=1
	s_or_b64 exec, exec, s[16:17]
.LBB2_35:                               ; %_ZN7commkit7kernels6step_aIDF16bLb1EEEvPT_ii.exit181
                                        ;   in Loop: Header=BB2_36 Depth=1
	s_or_b64 exec, exec, s[0:1]
	v_add_u32_e32 v23, -1, v23
	v_cmp_eq_u32_e64 s[0:1], 0, v23
	s_or_b64 s[14:15], s[0:1], s[14:15]
	v_add_u32_e32 v16, s18, v16
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_andn2_b64 exec, exec, s[14:15]
	s_cbranch_execz .LBB2_47
.LBB2_36:                               ; =>This Inner Loop Header: Depth=1
	s_and_saveexec_b64 s[0:1], s[6:7]
	s_xor_b64 s[0:1], exec, s[0:1]
	s_cbranch_execz .LBB2_40
; %bb.37:                               ;   in Loop: Header=BB2_36 Depth=1
	s_and_saveexec_b64 s[16:17], s[8:9]
	s_cbranch_execz .LBB2_39
; %bb.38:                               ; %.preheader5.i164
                                        ;   in Loop: Header=BB2_36 Depth=1
	ds_read_b128 v[24:27], v22
	ds_read_b128 v[28:31], v22 offset:512
	s_waitcnt lgkmcnt(0)
	v_and_b32_e32 v49, 0xffff0000, v24
	v_lshlrev_b32_e32 v48, 16, v24
	v_and_b32_e32 v57, 0xffff0000, v28
	v_lshlrev_b32_e32 v56, 16, v28
	v_and_b32_e32 v51, 0xffff0000, v25
	v_lshlrev_b32_e32 v50, 16, v25
	v_and_b32_e32 v53, 0xffff0000, v26
	v_lshlrev_b32_e32 v52, 16, v26
	v_and_b32_e32 v55, 0xffff0000, v27
	v_lshlrev_b32_e32 v54, 16, v27
	v_and_b32_e32 v59, 0xffff0000, v29
	v_lshlrev_b32_e32 v58, 16, v29
	v_and_b32_e32 v61, 0xffff0000, v30
	v_lshlrev_b32_e32 v60, 16, v30
	v_and_b32_e32 v63, 0xffff0000, v31
	v_lshlrev_b32_e32 v62, 16, v31
	ds_read_b128 v[24:27], v22 offset:1024
	ds_read_b128 v[28:31], v22 offset:1536
	ds_read_b128 v[32:35], v22 offset:2048
	ds_read_b128 v[36:39], v22 offset:2560
	ds_read_b128 v[40:43], v22 offset:3072
	ds_read_b128 v[44:47], v22 offset:3584
	v_pk_add_f32 v[48:49], v[48:49], v[56:57]
	s_waitcnt lgkmcnt(0)
	v_and_b32_e32 v57, 0xffff0000, v24
	v_lshlrev_b32_e32 v56, 16, v24
	v_pk_add_f32 v[48:49], v[48:49], v[56:57]
	v_and_b32_e32 v57, 0xffff0000, v28
	v_lshlrev_b32_e32 v56, 16, v28
	v_pk_add_f32 v[48:49], v[48:49], v[56:57]
	v_and_b32_e32 v57, 0xffff0000, v32
	v_lshlrev_b32_e32 v56, 16, v32
	v_pk_add_f32 v[48:49], v[48:49], v[56:57]
	v_and_b32_e32 v57, 0xffff0000, v36
	v_lshlrev_b32_e32 v56, 16, v36
	v_pk_add_f32 v[48:49], v[48:49], v[56:57]
	v_and_b32_e32 v57, 0xffff0000, v40
	v_lshlrev_b32_e32 v56, 16, v40
	v_pk_add_f32 v[48:49], v[48:49], v[56:57]
	v_and_b32_e32 v57, 0xffff0000, v44
	v_lshlrev_b32_e32 v56, 16, v44
	v_pk_add_f32 v[48:49], v[48:49], v[56:57]
	v_pk_add_f32 v[50:51], v[50:51], v[58:59]
	v_and_b32_e32 v57, 0xffff0000, v25
	v_lshlrev_b32_e32 v56, 16, v25
	v_pk_add_f32 v[24:25], v[50:51], v[56:57]
	v_and_b32_e32 v51, 0xffff0000, v29
	v_lshlrev_b32_e32 v50, 16, v29
	v_pk_add_f32 v[24:25], v[24:25], v[50:51]
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
	v_pk_add_f32 v[28:29], v[52:53], v[60:61]
	v_and_b32_e32 v33, 0xffff0000, v26
	v_lshlrev_b32_e32 v32, 16, v26
	v_pk_add_f32 v[28:29], v[28:29], v[32:33]
	v_and_b32_e32 v33, 0xffff0000, v30
	v_lshlrev_b32_e32 v32, 16, v30
	v_pk_add_f32 v[28:29], v[28:29], v[32:33]
	v_and_b32_e32 v33, 0xffff0000, v34
	v_lshlrev_b32_e32 v32, 16, v34
	v_pk_add_f32 v[28:29], v[28:29], v[32:33]
	v_and_b32_e32 v33, 0xffff0000, v38
	v_lshlrev_b32_e32 v32, 16, v38
	v_pk_add_f32 v[28:29], v[28:29], v[32:33]
	v_and_b32_e32 v33, 0xffff0000, v42
	v_lshlrev_b32_e32 v32, 16, v42
	v_pk_add_f32 v[28:29], v[28:29], v[32:33]
	v_and_b32_e32 v33, 0xffff0000, v46
	v_lshlrev_b32_e32 v32, 16, v46
	v_pk_add_f32 v[28:29], v[28:29], v[32:33]
	v_pk_add_f32 v[32:33], v[54:55], v[62:63]
	v_and_b32_e32 v37, 0xffff0000, v27
	v_lshlrev_b32_e32 v36, 16, v27
	v_pk_add_f32 v[26:27], v[32:33], v[36:37]
	v_and_b32_e32 v33, 0xffff0000, v31
	v_lshlrev_b32_e32 v32, 16, v31
	v_pk_add_f32 v[26:27], v[26:27], v[32:33]
	v_and_b32_e32 v31, 0xffff0000, v35
	v_lshlrev_b32_e32 v30, 16, v35
	v_pk_add_f32 v[26:27], v[26:27], v[30:31]
	v_and_b32_e32 v31, 0xffff0000, v39
	v_lshlrev_b32_e32 v30, 16, v39
	v_pk_add_f32 v[26:27], v[26:27], v[30:31]
	v_and_b32_e32 v31, 0xffff0000, v43
	v_lshlrev_b32_e32 v30, 16, v43
	v_pk_add_f32 v[26:27], v[26:27], v[30:31]
	v_and_b32_e32 v31, 0xffff0000, v47
	v_lshlrev_b32_e32 v30, 16, v47
	v_pk_add_f32 v[26:27], v[26:27], v[30:31]
	v_perm_b32 v25, v25, v24, s20
	v_perm_b32 v27, v27, v26, s20
	v_perm_b32 v26, v29, v28, s20
	v_perm_b32 v24, v49, v48, s20
	ds_write_b128 v22, v[24:27]
	ds_write_b128 v22, v[24:27] offset:512
	ds_write_b128 v22, v[24:27] offset:1024
	ds_write_b128 v22, v[24:27] offset:1536
	ds_write_b128 v22, v[24:27] offset:2048
	ds_write_b128 v22, v[24:27] offset:2560
	ds_write_b128 v22, v[24:27] offset:3072
	ds_write_b128 v22, v[24:27] offset:3584
.LBB2_39:                               ; %Flow294
                                        ;   in Loop: Header=BB2_36 Depth=1
	s_or_b64 exec, exec, s[16:17]
.LBB2_40:                               ; %Flow295
                                        ;   in Loop: Header=BB2_36 Depth=1
	s_andn2_saveexec_b64 s[0:1], s[0:1]
	s_cbranch_execz .LBB2_42
; %bb.41:                               ;   in Loop: Header=BB2_36 Depth=1
	ds_read_b128 v[24:27], v7
	v_ashrrev_i32_e32 v17, 31, v16
	v_add_u32_e32 v28, s18, v16
	v_lshl_add_u64 v[30:31], v[16:17], 4, v[8:9]
	v_ashrrev_i32_e32 v29, 31, v28
	s_waitcnt lgkmcnt(0)
	flat_store_dwordx4 v[30:31], v[24:27]
	s_nop 1
	v_lshl_add_u64 v[24:25], v[28:29], 4, v[10:11]
	flat_load_dwordx4 v[24:27], v[24:25]
	s_waitcnt vmcnt(0) lgkmcnt(0)
	ds_write_b128 v7, v[24:27]
.LBB2_42:                               ; %_ZN7commkit7kernels6step_aIDF16bLb0EEEvPT_ii.exit
                                        ;   in Loop: Header=BB2_36 Depth=1
	s_or_b64 exec, exec, s[0:1]
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_saveexec_b64 s[0:1], s[6:7]
	s_xor_b64 s[0:1], exec, s[0:1]
	s_cbranch_execz .LBB2_44
; %bb.43:                               ;   in Loop: Header=BB2_36 Depth=1
	ds_read_b128 v[24:27], v7
	v_add_u32_e32 v28, s59, v16
	v_add_u32_e32 v30, s19, v16
	v_ashrrev_i32_e32 v29, 31, v28
	v_lshl_add_u64 v[28:29], v[28:29], 4, v[12:13]
	v_ashrrev_i32_e32 v31, 31, v30
	s_waitcnt lgkmcnt(0)
	flat_store_dwordx4 v[28:29], v[24:27]
	s_nop 1
	v_lshl_add_u64 v[24:25], v[30:31], 4, v[14:15]
	flat_load_dwordx4 v[24:27], v[24:25]
	s_waitcnt vmcnt(0) lgkmcnt(0)
	ds_write_b128 v7, v[24:27]
.LBB2_44:                               ; %Flow293
                                        ;   in Loop: Header=BB2_36 Depth=1
	s_andn2_saveexec_b64 s[0:1], s[0:1]
	s_cbranch_execz .LBB2_35
; %bb.45:                               ;   in Loop: Header=BB2_36 Depth=1
	s_and_saveexec_b64 s[16:17], s[10:11]
	s_cbranch_execz .LBB2_34
; %bb.46:                               ; %.preheader5.i173
                                        ;   in Loop: Header=BB2_36 Depth=1
	ds_read_b128 v[24:27], v21
	ds_read_b128 v[28:31], v21 offset:512
	s_waitcnt lgkmcnt(0)
	v_and_b32_e32 v49, 0xffff0000, v24
	v_lshlrev_b32_e32 v48, 16, v24
	v_and_b32_e32 v57, 0xffff0000, v28
	v_lshlrev_b32_e32 v56, 16, v28
	v_and_b32_e32 v51, 0xffff0000, v25
	v_lshlrev_b32_e32 v50, 16, v25
	v_and_b32_e32 v53, 0xffff0000, v26
	v_lshlrev_b32_e32 v52, 16, v26
	v_and_b32_e32 v55, 0xffff0000, v27
	v_lshlrev_b32_e32 v54, 16, v27
	v_and_b32_e32 v59, 0xffff0000, v29
	v_lshlrev_b32_e32 v58, 16, v29
	v_and_b32_e32 v61, 0xffff0000, v30
	v_lshlrev_b32_e32 v60, 16, v30
	v_and_b32_e32 v63, 0xffff0000, v31
	v_lshlrev_b32_e32 v62, 16, v31
	ds_read_b128 v[24:27], v21 offset:1024
	ds_read_b128 v[28:31], v21 offset:1536
	ds_read_b128 v[32:35], v21 offset:2048
	ds_read_b128 v[36:39], v21 offset:2560
	ds_read_b128 v[40:43], v21 offset:3072
	ds_read_b128 v[44:47], v21 offset:3584
	v_pk_add_f32 v[48:49], v[48:49], v[56:57]
	s_waitcnt lgkmcnt(0)
	v_and_b32_e32 v57, 0xffff0000, v24
	v_lshlrev_b32_e32 v56, 16, v24
	v_pk_add_f32 v[48:49], v[48:49], v[56:57]
	v_and_b32_e32 v57, 0xffff0000, v28
	v_lshlrev_b32_e32 v56, 16, v28
	v_pk_add_f32 v[48:49], v[48:49], v[56:57]
	v_and_b32_e32 v57, 0xffff0000, v32
	v_lshlrev_b32_e32 v56, 16, v32
	v_pk_add_f32 v[48:49], v[48:49], v[56:57]
	v_and_b32_e32 v57, 0xffff0000, v36
	v_lshlrev_b32_e32 v56, 16, v36
	v_pk_add_f32 v[48:49], v[48:49], v[56:57]
	v_and_b32_e32 v57, 0xffff0000, v40
	v_lshlrev_b32_e32 v56, 16, v40
	v_pk_add_f32 v[48:49], v[48:49], v[56:57]
	v_and_b32_e32 v57, 0xffff0000, v44
	v_lshlrev_b32_e32 v56, 16, v44
	v_pk_add_f32 v[48:49], v[48:49], v[56:57]
	v_pk_add_f32 v[50:51], v[50:51], v[58:59]
	v_and_b32_e32 v57, 0xffff0000, v25
	v_lshlrev_b32_e32 v56, 16, v25
	v_pk_add_f32 v[24:25], v[50:51], v[56:57]
	v_and_b32_e32 v51, 0xffff0000, v29
	v_lshlrev_b32_e32 v50, 16, v29
	v_pk_add_f32 v[24:25], v[24:25], v[50:51]
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
	v_pk_add_f32 v[28:29], v[52:53], v[60:61]
	v_and_b32_e32 v33, 0xffff0000, v26
	v_lshlrev_b32_e32 v32, 16, v26
	v_pk_add_f32 v[28:29], v[28:29], v[32:33]
	v_and_b32_e32 v33, 0xffff0000, v30
	v_lshlrev_b32_e32 v32, 16, v30
	v_pk_add_f32 v[28:29], v[28:29], v[32:33]
	v_and_b32_e32 v33, 0xffff0000, v34
	v_lshlrev_b32_e32 v32, 16, v34
	v_pk_add_f32 v[28:29], v[28:29], v[32:33]
	v_and_b32_e32 v33, 0xffff0000, v38
	v_lshlrev_b32_e32 v32, 16, v38
	v_pk_add_f32 v[28:29], v[28:29], v[32:33]
	v_and_b32_e32 v33, 0xffff0000, v42
	v_lshlrev_b32_e32 v32, 16, v42
	v_pk_add_f32 v[28:29], v[28:29], v[32:33]
	v_and_b32_e32 v33, 0xffff0000, v46
	v_lshlrev_b32_e32 v32, 16, v46
	v_pk_add_f32 v[28:29], v[28:29], v[32:33]
	v_pk_add_f32 v[32:33], v[54:55], v[62:63]
	v_and_b32_e32 v37, 0xffff0000, v27
	v_lshlrev_b32_e32 v36, 16, v27
	v_pk_add_f32 v[26:27], v[32:33], v[36:37]
	v_and_b32_e32 v33, 0xffff0000, v31
	v_lshlrev_b32_e32 v32, 16, v31
	v_pk_add_f32 v[26:27], v[26:27], v[32:33]
	v_and_b32_e32 v31, 0xffff0000, v35
	v_lshlrev_b32_e32 v30, 16, v35
	v_pk_add_f32 v[26:27], v[26:27], v[30:31]
	v_and_b32_e32 v31, 0xffff0000, v39
	v_lshlrev_b32_e32 v30, 16, v39
	v_pk_add_f32 v[26:27], v[26:27], v[30:31]
	v_and_b32_e32 v31, 0xffff0000, v43
	v_lshlrev_b32_e32 v30, 16, v43
	v_pk_add_f32 v[26:27], v[26:27], v[30:31]
	v_and_b32_e32 v31, 0xffff0000, v47
	v_lshlrev_b32_e32 v30, 16, v47
	v_pk_add_f32 v[26:27], v[26:27], v[30:31]
	v_perm_b32 v25, v25, v24, s20
	v_perm_b32 v27, v27, v26, s20
	v_perm_b32 v26, v29, v28, s20
	v_perm_b32 v24, v49, v48, s20
	ds_write_b128 v21, v[24:27]
	ds_write_b128 v21, v[24:27] offset:512
	ds_write_b128 v21, v[24:27] offset:1024
	ds_write_b128 v21, v[24:27] offset:1536
	ds_write_b128 v21, v[24:27] offset:2048
	ds_write_b128 v21, v[24:27] offset:2560
	ds_write_b128 v21, v[24:27] offset:3072
	ds_write_b128 v21, v[24:27] offset:3584
	s_branch .LBB2_34
.LBB2_47:                               ; %Flow297
	s_or_b64 exec, exec, s[56:57]
	v_and_b32_e32 v8, 1, v18
	v_cmp_eq_u32_e64 s[0:1], 1, v8
	s_and_saveexec_b64 s[8:9], s[0:1]
	s_xor_b64 s[22:23], exec, s[8:9]
	s_cbranch_execz .LBB2_63
; %bb.48:
	s_and_saveexec_b64 s[0:1], s[6:7]
	s_xor_b64 s[8:9], exec, s[0:1]
	s_cbranch_execz .LBB2_52
; %bb.49:
	v_cmp_eq_u32_e64 s[0:1], 8, v19
	s_and_saveexec_b64 s[10:11], s[0:1]
	s_cbranch_execz .LBB2_51
; %bb.50:                               ; %.preheader5.i193
	v_lshlrev_b32_e32 v21, 4, v3
	ds_read_b128 v[8:11], v21 offset:4096
	ds_read_b128 v[12:15], v21 offset:4608
	s_mov_b32 s0, 0x7060302
	s_waitcnt lgkmcnt(0)
	v_and_b32_e32 v17, 0xffff0000, v8
	v_lshlrev_b32_e32 v16, 16, v8
	v_and_b32_e32 v45, 0xffff0000, v12
	v_lshlrev_b32_e32 v44, 16, v12
	v_and_b32_e32 v39, 0xffff0000, v9
	v_lshlrev_b32_e32 v38, 16, v9
	v_and_b32_e32 v41, 0xffff0000, v10
	v_lshlrev_b32_e32 v40, 16, v10
	v_and_b32_e32 v43, 0xffff0000, v11
	v_lshlrev_b32_e32 v42, 16, v11
	v_and_b32_e32 v47, 0xffff0000, v13
	v_lshlrev_b32_e32 v46, 16, v13
	v_and_b32_e32 v49, 0xffff0000, v14
	v_lshlrev_b32_e32 v48, 16, v14
	v_and_b32_e32 v51, 0xffff0000, v15
	v_lshlrev_b32_e32 v50, 16, v15
	ds_read_b128 v[8:11], v21 offset:5120
	ds_read_b128 v[12:15], v21 offset:5632
	ds_read_b128 v[22:25], v21 offset:6144
	ds_read_b128 v[26:29], v21 offset:6656
	ds_read_b128 v[30:33], v21 offset:7168
	ds_read_b128 v[34:37], v21 offset:7680
	v_pk_add_f32 v[16:17], v[16:17], v[44:45]
	s_waitcnt lgkmcnt(0)
	v_and_b32_e32 v45, 0xffff0000, v8
	v_lshlrev_b32_e32 v44, 16, v8
	v_pk_add_f32 v[16:17], v[16:17], v[44:45]
	v_and_b32_e32 v45, 0xffff0000, v12
	v_lshlrev_b32_e32 v44, 16, v12
	v_pk_add_f32 v[16:17], v[16:17], v[44:45]
	v_and_b32_e32 v45, 0xffff0000, v22
	v_lshlrev_b32_e32 v44, 16, v22
	v_pk_add_f32 v[16:17], v[16:17], v[44:45]
	v_and_b32_e32 v45, 0xffff0000, v26
	v_lshlrev_b32_e32 v44, 16, v26
	v_pk_add_f32 v[16:17], v[16:17], v[44:45]
	v_and_b32_e32 v45, 0xffff0000, v30
	v_lshlrev_b32_e32 v44, 16, v30
	v_pk_add_f32 v[16:17], v[16:17], v[44:45]
	v_and_b32_e32 v45, 0xffff0000, v34
	v_lshlrev_b32_e32 v44, 16, v34
	v_pk_add_f32 v[16:17], v[16:17], v[44:45]
	v_pk_add_f32 v[38:39], v[38:39], v[46:47]
	v_and_b32_e32 v45, 0xffff0000, v9
	v_lshlrev_b32_e32 v44, 16, v9
	v_pk_add_f32 v[8:9], v[38:39], v[44:45]
	v_and_b32_e32 v39, 0xffff0000, v13
	v_lshlrev_b32_e32 v38, 16, v13
	v_pk_add_f32 v[8:9], v[8:9], v[38:39]
	v_and_b32_e32 v13, 0xffff0000, v23
	v_lshlrev_b32_e32 v12, 16, v23
	v_pk_add_f32 v[8:9], v[8:9], v[12:13]
	v_and_b32_e32 v13, 0xffff0000, v27
	v_lshlrev_b32_e32 v12, 16, v27
	v_pk_add_f32 v[8:9], v[8:9], v[12:13]
	v_and_b32_e32 v13, 0xffff0000, v31
	v_lshlrev_b32_e32 v12, 16, v31
	v_pk_add_f32 v[8:9], v[8:9], v[12:13]
	v_and_b32_e32 v13, 0xffff0000, v35
	v_lshlrev_b32_e32 v12, 16, v35
	v_pk_add_f32 v[8:9], v[8:9], v[12:13]
	v_pk_add_f32 v[12:13], v[40:41], v[48:49]
	v_and_b32_e32 v23, 0xffff0000, v10
	v_lshlrev_b32_e32 v22, 16, v10
	v_pk_add_f32 v[12:13], v[12:13], v[22:23]
	v_and_b32_e32 v23, 0xffff0000, v14
	v_lshlrev_b32_e32 v22, 16, v14
	v_pk_add_f32 v[12:13], v[12:13], v[22:23]
	v_and_b32_e32 v23, 0xffff0000, v24
	v_lshlrev_b32_e32 v22, 16, v24
	v_pk_add_f32 v[12:13], v[12:13], v[22:23]
	v_and_b32_e32 v23, 0xffff0000, v28
	v_lshlrev_b32_e32 v22, 16, v28
	v_pk_add_f32 v[12:13], v[12:13], v[22:23]
	v_and_b32_e32 v23, 0xffff0000, v32
	v_lshlrev_b32_e32 v22, 16, v32
	v_pk_add_f32 v[12:13], v[12:13], v[22:23]
	v_and_b32_e32 v23, 0xffff0000, v36
	v_lshlrev_b32_e32 v22, 16, v36
	v_pk_add_f32 v[12:13], v[12:13], v[22:23]
	v_pk_add_f32 v[22:23], v[42:43], v[50:51]
	v_and_b32_e32 v27, 0xffff0000, v11
	v_lshlrev_b32_e32 v26, 16, v11
	v_pk_add_f32 v[10:11], v[22:23], v[26:27]
	v_and_b32_e32 v23, 0xffff0000, v15
	v_lshlrev_b32_e32 v22, 16, v15
	v_pk_add_f32 v[10:11], v[10:11], v[22:23]
	v_and_b32_e32 v15, 0xffff0000, v25
	v_lshlrev_b32_e32 v14, 16, v25
	v_pk_add_f32 v[10:11], v[10:11], v[14:15]
	v_and_b32_e32 v15, 0xffff0000, v29
	v_lshlrev_b32_e32 v14, 16, v29
	v_pk_add_f32 v[10:11], v[10:11], v[14:15]
	v_and_b32_e32 v15, 0xffff0000, v33
	v_lshlrev_b32_e32 v14, 16, v33
	v_pk_add_f32 v[10:11], v[10:11], v[14:15]
	v_and_b32_e32 v15, 0xffff0000, v37
	v_lshlrev_b32_e32 v14, 16, v37
	v_pk_add_f32 v[10:11], v[10:11], v[14:15]
	v_perm_b32 v9, v9, v8, s0
	v_perm_b32 v11, v11, v10, s0
	v_perm_b32 v10, v13, v12, s0
	v_perm_b32 v8, v17, v16, s0
	ds_write_b128 v21, v[8:11] offset:4096
	ds_write_b128 v21, v[8:11] offset:4608
	ds_write_b128 v21, v[8:11] offset:5120
	ds_write_b128 v21, v[8:11] offset:5632
	ds_write_b128 v21, v[8:11] offset:6144
	ds_write_b128 v21, v[8:11] offset:6656
	ds_write_b128 v21, v[8:11] offset:7168
	ds_write_b128 v21, v[8:11] offset:7680
.LBB2_51:                               ; %Flow284
	s_or_b64 exec, exec, s[10:11]
.LBB2_52:                               ; %Flow285
	s_andn2_saveexec_b64 s[56:57], s[8:9]
	s_cbranch_execz .LBB2_54
; %bb.53:
	v_mov_b32_e32 v12, s31
	v_mov_b32_e32 v13, s74
	v_cmp_eq_u32_e64 s[0:1], 1, v19
	v_cmp_eq_u32_e64 s[8:9], 2, v19
	v_cmp_eq_u32_e64 s[10:11], 3, v19
	v_cndmask_b32_e64 v12, v12, v13, s[0:1]
	v_mov_b32_e32 v13, s73
	v_cndmask_b32_e64 v12, v12, v13, s[8:9]
	v_mov_b32_e32 v13, s72
	v_cndmask_b32_e64 v12, v12, v13, s[10:11]
	v_mov_b32_e32 v13, s71
	v_cmp_eq_u32_e64 s[14:15], 4, v19
	v_cmp_eq_u32_e64 s[16:17], 5, v19
	v_cmp_eq_u32_e64 s[18:19], 6, v19
	v_cndmask_b32_e64 v12, v12, v13, s[14:15]
	v_mov_b32_e32 v13, s70
	v_cndmask_b32_e64 v12, v12, v13, s[16:17]
	v_mov_b32_e32 v13, s69
	v_cndmask_b32_e64 v12, v12, v13, s[18:19]
	v_mov_b32_e32 v13, s68
	v_cmp_eq_u32_e64 s[20:21], 7, v19
	v_mov_b32_e32 v14, s25
	ds_read_b128 v[8:11], v7
	v_cndmask_b32_e64 v13, v12, v13, s[20:21]
	v_mov_b32_e32 v12, s30
	v_cndmask_b32_e64 v12, v12, v14, s[0:1]
	v_mov_b32_e32 v14, s62
	v_cndmask_b32_e64 v12, v12, v14, s[8:9]
	v_mov_b32_e32 v14, s63
	v_cndmask_b32_e64 v12, v12, v14, s[10:11]
	v_mov_b32_e32 v14, s64
	v_cndmask_b32_e64 v12, v12, v14, s[14:15]
	v_mov_b32_e32 v14, s65
	v_cndmask_b32_e64 v12, v12, v14, s[16:17]
	v_mov_b32_e32 v14, s66
	v_cndmask_b32_e64 v12, v12, v14, s[18:19]
	v_mov_b32_e32 v14, s67
	v_cndmask_b32_e64 v12, v12, v14, s[20:21]
	v_mul_lo_u32 v14, s33, v5
	v_lshl_add_u32 v14, v14, 6, v4
	v_ashrrev_i32_e32 v15, 31, v14
	v_lshl_add_u64 v[12:13], v[14:15], 4, v[12:13]
	s_waitcnt lgkmcnt(0)
	flat_store_dwordx4 v[12:13], v[8:11]
	s_nop 1
	v_mov_b32_e32 v8, s39
	v_mov_b32_e32 v9, s41
	v_cndmask_b32_e64 v8, v8, v9, s[0:1]
	v_mov_b32_e32 v9, s43
	v_cndmask_b32_e64 v8, v8, v9, s[8:9]
	v_mov_b32_e32 v9, s45
	v_cndmask_b32_e64 v8, v8, v9, s[10:11]
	v_mov_b32_e32 v9, s47
	v_cndmask_b32_e64 v8, v8, v9, s[14:15]
	v_mov_b32_e32 v9, s51
	v_cndmask_b32_e64 v8, v8, v9, s[16:17]
	v_mov_b32_e32 v9, s53
	v_cndmask_b32_e64 v8, v8, v9, s[18:19]
	v_mov_b32_e32 v9, s55
	v_cndmask_b32_e64 v9, v8, v9, s[20:21]
	v_mov_b32_e32 v8, s38
	v_mov_b32_e32 v10, s40
	v_cndmask_b32_e64 v8, v8, v10, s[0:1]
	v_mov_b32_e32 v10, s42
	v_cndmask_b32_e64 v8, v8, v10, s[8:9]
	v_mov_b32_e32 v10, s44
	v_cndmask_b32_e64 v8, v8, v10, s[10:11]
	v_mov_b32_e32 v10, s46
	v_cndmask_b32_e64 v8, v8, v10, s[14:15]
	v_mov_b32_e32 v10, s50
	v_cndmask_b32_e64 v8, v8, v10, s[16:17]
	v_mov_b32_e32 v10, s52
	v_cndmask_b32_e64 v8, v8, v10, s[18:19]
	v_mov_b32_e32 v10, s54
	v_cndmask_b32_e64 v8, v8, v10, s[20:21]
	v_and_b32_e32 v10, 0x7ffffffe, v18
	v_mad_u64_u32 v[10:11], s[0:1], v10, s59, v[4:5]
	v_ashrrev_i32_e32 v11, 31, v10
	v_lshl_add_u64 v[8:9], v[10:11], 4, v[8:9]
	flat_load_dwordx4 v[8:11], v[8:9]
	s_waitcnt vmcnt(0) lgkmcnt(0)
	ds_write_b128 v7, v[8:11]
.LBB2_54:                               ; %_ZN7commkit7kernels6step_aIDF16bLb0EEEvPT_ii.exit201
	s_or_b64 exec, exec, s[56:57]
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_saveexec_b64 s[0:1], s[6:7]
	s_xor_b64 s[38:39], exec, s[0:1]
	s_cbranch_execz .LBB2_56
; %bb.55:
	v_add_u32_e32 v0, -8, v19
	v_mov_b32_e32 v12, s31
	v_mov_b32_e32 v13, s74
	v_cmp_eq_u32_e64 s[0:1], 1, v0
	v_cmp_eq_u32_e64 s[8:9], 2, v0
	v_cmp_eq_u32_e64 s[10:11], 3, v0
	v_cndmask_b32_e64 v12, v12, v13, s[0:1]
	v_mov_b32_e32 v13, s73
	v_cndmask_b32_e64 v12, v12, v13, s[8:9]
	v_mov_b32_e32 v13, s72
	v_cndmask_b32_e64 v12, v12, v13, s[10:11]
	v_mov_b32_e32 v13, s71
	v_cmp_eq_u32_e64 s[14:15], 4, v0
	v_cmp_eq_u32_e64 s[16:17], 5, v0
	v_cmp_eq_u32_e64 s[18:19], 6, v0
	v_cndmask_b32_e64 v12, v12, v13, s[14:15]
	v_mov_b32_e32 v13, s70
	v_cndmask_b32_e64 v12, v12, v13, s[16:17]
	v_mov_b32_e32 v13, s69
	v_cndmask_b32_e64 v12, v12, v13, s[18:19]
	v_mov_b32_e32 v13, s68
	v_cmp_eq_u32_e64 s[20:21], 7, v0
	v_mov_b32_e32 v0, s30
	ds_read_b128 v[8:11], v7
	v_cndmask_b32_e64 v13, v12, v13, s[20:21]
	v_mov_b32_e32 v12, s25
	v_cndmask_b32_e64 v0, v0, v12, s[0:1]
	v_mov_b32_e32 v12, s62
	v_cndmask_b32_e64 v0, v0, v12, s[8:9]
	v_mov_b32_e32 v12, s63
	v_cndmask_b32_e64 v0, v0, v12, s[10:11]
	v_mov_b32_e32 v12, s64
	v_cndmask_b32_e64 v0, v0, v12, s[14:15]
	v_mov_b32_e32 v12, s65
	v_cndmask_b32_e64 v0, v0, v12, s[16:17]
	v_mov_b32_e32 v12, s66
	v_cndmask_b32_e64 v0, v0, v12, s[18:19]
	v_mov_b32_e32 v12, s67
	v_cndmask_b32_e64 v12, v0, v12, s[20:21]
	v_lshl_or_b32 v0, v5, 1, 1
	v_mad_u64_u32 v[14:15], s[0:1], v0, s59, v[4:5]
	v_ashrrev_i32_e32 v15, 31, v14
	v_lshl_add_u64 v[12:13], v[14:15], 4, v[12:13]
	s_waitcnt lgkmcnt(0)
	flat_store_dwordx4 v[12:13], v[8:11]
                                        ; implicit-def: $vgpr0
.LBB2_56:                               ; %Flow283
	s_andn2_saveexec_b64 s[8:9], s[38:39]
	s_cbranch_execz .LBB2_60
; %bb.57:
	v_cmp_gt_u32_e64 s[0:1], 32, v0
	s_and_saveexec_b64 s[10:11], s[0:1]
	s_cbranch_execz .LBB2_59
; %bb.58:                               ; %.preheader5.i203
	v_lshlrev_b32_e32 v0, 4, v3
	ds_read_b128 v[8:11], v0
	ds_read_b128 v[12:15], v0 offset:512
	s_mov_b32 s0, 0x7060302
	s_waitcnt lgkmcnt(0)
	v_and_b32_e32 v17, 0xffff0000, v8
	v_lshlrev_b32_e32 v16, 16, v8
	v_and_b32_e32 v45, 0xffff0000, v12
	v_lshlrev_b32_e32 v44, 16, v12
	v_and_b32_e32 v39, 0xffff0000, v9
	v_lshlrev_b32_e32 v38, 16, v9
	v_and_b32_e32 v41, 0xffff0000, v10
	v_lshlrev_b32_e32 v40, 16, v10
	v_and_b32_e32 v43, 0xffff0000, v11
	v_lshlrev_b32_e32 v42, 16, v11
	v_and_b32_e32 v47, 0xffff0000, v13
	v_lshlrev_b32_e32 v46, 16, v13
	v_and_b32_e32 v49, 0xffff0000, v14
	v_lshlrev_b32_e32 v48, 16, v14
	v_and_b32_e32 v51, 0xffff0000, v15
	v_lshlrev_b32_e32 v50, 16, v15
	ds_read_b128 v[8:11], v0 offset:1024
	ds_read_b128 v[12:15], v0 offset:1536
	ds_read_b128 v[22:25], v0 offset:2048
	ds_read_b128 v[26:29], v0 offset:2560
	ds_read_b128 v[30:33], v0 offset:3072
	ds_read_b128 v[34:37], v0 offset:3584
	v_pk_add_f32 v[16:17], v[16:17], v[44:45]
	s_waitcnt lgkmcnt(0)
	v_and_b32_e32 v45, 0xffff0000, v8
	v_lshlrev_b32_e32 v44, 16, v8
	v_pk_add_f32 v[16:17], v[16:17], v[44:45]
	v_and_b32_e32 v45, 0xffff0000, v12
	v_lshlrev_b32_e32 v44, 16, v12
	v_pk_add_f32 v[16:17], v[16:17], v[44:45]
	v_and_b32_e32 v45, 0xffff0000, v22
	v_lshlrev_b32_e32 v44, 16, v22
	v_pk_add_f32 v[16:17], v[16:17], v[44:45]
	v_and_b32_e32 v45, 0xffff0000, v26
	v_lshlrev_b32_e32 v44, 16, v26
	v_pk_add_f32 v[16:17], v[16:17], v[44:45]
	v_and_b32_e32 v45, 0xffff0000, v30
	v_lshlrev_b32_e32 v44, 16, v30
	v_pk_add_f32 v[16:17], v[16:17], v[44:45]
	v_and_b32_e32 v45, 0xffff0000, v34
	v_lshlrev_b32_e32 v44, 16, v34
	v_pk_add_f32 v[16:17], v[16:17], v[44:45]
	v_pk_add_f32 v[38:39], v[38:39], v[46:47]
	v_and_b32_e32 v45, 0xffff0000, v9
	v_lshlrev_b32_e32 v44, 16, v9
	v_pk_add_f32 v[8:9], v[38:39], v[44:45]
	v_and_b32_e32 v39, 0xffff0000, v13
	v_lshlrev_b32_e32 v38, 16, v13
	v_pk_add_f32 v[8:9], v[8:9], v[38:39]
	v_and_b32_e32 v13, 0xffff0000, v23
	v_lshlrev_b32_e32 v12, 16, v23
	v_pk_add_f32 v[8:9], v[8:9], v[12:13]
	v_and_b32_e32 v13, 0xffff0000, v27
	v_lshlrev_b32_e32 v12, 16, v27
	v_pk_add_f32 v[8:9], v[8:9], v[12:13]
	v_and_b32_e32 v13, 0xffff0000, v31
	v_lshlrev_b32_e32 v12, 16, v31
	v_pk_add_f32 v[8:9], v[8:9], v[12:13]
	v_and_b32_e32 v13, 0xffff0000, v35
	v_lshlrev_b32_e32 v12, 16, v35
	v_pk_add_f32 v[8:9], v[8:9], v[12:13]
	v_pk_add_f32 v[12:13], v[40:41], v[48:49]
	v_and_b32_e32 v23, 0xffff0000, v10
	v_lshlrev_b32_e32 v22, 16, v10
	v_pk_add_f32 v[12:13], v[12:13], v[22:23]
	v_and_b32_e32 v23, 0xffff0000, v14
	v_lshlrev_b32_e32 v22, 16, v14
	v_pk_add_f32 v[12:13], v[12:13], v[22:23]
	v_and_b32_e32 v23, 0xffff0000, v24
	v_lshlrev_b32_e32 v22, 16, v24
	v_pk_add_f32 v[12:13], v[12:13], v[22:23]
	v_and_b32_e32 v23, 0xffff0000, v28
	v_lshlrev_b32_e32 v22, 16, v28
	v_pk_add_f32 v[12:13], v[12:13], v[22:23]
	v_and_b32_e32 v23, 0xffff0000, v32
	v_lshlrev_b32_e32 v22, 16, v32
	v_pk_add_f32 v[12:13], v[12:13], v[22:23]
	v_and_b32_e32 v23, 0xffff0000, v36
	v_lshlrev_b32_e32 v22, 16, v36
	v_pk_add_f32 v[12:13], v[12:13], v[22:23]
	v_pk_add_f32 v[22:23], v[42:43], v[50:51]
	v_and_b32_e32 v27, 0xffff0000, v11
	v_lshlrev_b32_e32 v26, 16, v11
	v_pk_add_f32 v[10:11], v[22:23], v[26:27]
	v_and_b32_e32 v23, 0xffff0000, v15
	v_lshlrev_b32_e32 v22, 16, v15
	v_pk_add_f32 v[10:11], v[10:11], v[22:23]
	v_and_b32_e32 v15, 0xffff0000, v25
	v_lshlrev_b32_e32 v14, 16, v25
	v_pk_add_f32 v[10:11], v[10:11], v[14:15]
	v_and_b32_e32 v15, 0xffff0000, v29
	v_lshlrev_b32_e32 v14, 16, v29
	v_pk_add_f32 v[10:11], v[10:11], v[14:15]
	v_and_b32_e32 v15, 0xffff0000, v33
	v_lshlrev_b32_e32 v14, 16, v33
	v_pk_add_f32 v[10:11], v[10:11], v[14:15]
	v_and_b32_e32 v15, 0xffff0000, v37
	v_lshlrev_b32_e32 v14, 16, v37
	v_pk_add_f32 v[10:11], v[10:11], v[14:15]
	v_perm_b32 v9, v9, v8, s0
	v_perm_b32 v11, v11, v10, s0
	v_perm_b32 v10, v13, v12, s0
	v_perm_b32 v8, v17, v16, s0
	ds_write_b128 v0, v[8:11]
	ds_write_b128 v0, v[8:11] offset:512
	ds_write_b128 v0, v[8:11] offset:1024
	ds_write_b128 v0, v[8:11] offset:1536
	ds_write_b128 v0, v[8:11] offset:2048
	ds_write_b128 v0, v[8:11] offset:2560
	ds_write_b128 v0, v[8:11] offset:3072
	ds_write_b128 v0, v[8:11] offset:3584
.LBB2_59:                               ; %Flow282
	s_or_b64 exec, exec, s[10:11]
.LBB2_60:                               ; %_ZN7commkit7kernels6step_aIDF16bLb1EEEvPT_ii.exit211
	s_or_b64 exec, exec, s[8:9]
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_saveexec_b64 s[38:39], vcc
	s_cbranch_execz .LBB2_62
; %bb.61:
	v_mov_b32_e32 v0, s31
	v_mov_b32_e32 v5, s74
	v_cmp_eq_u32_e64 s[0:1], 1, v19
	v_cmp_eq_u32_e64 s[8:9], 2, v19
	v_cmp_eq_u32_e64 s[10:11], 3, v19
	v_cndmask_b32_e64 v0, v0, v5, s[0:1]
	v_mov_b32_e32 v5, s73
	v_cndmask_b32_e64 v0, v0, v5, s[8:9]
	v_mov_b32_e32 v5, s72
	v_cndmask_b32_e64 v0, v0, v5, s[10:11]
	v_mov_b32_e32 v5, s71
	v_cmp_eq_u32_e64 s[14:15], 4, v19
	v_cmp_eq_u32_e64 s[16:17], 5, v19
	v_cmp_eq_u32_e64 s[18:19], 6, v19
	v_cndmask_b32_e64 v0, v0, v5, s[14:15]
	v_mov_b32_e32 v5, s70
	v_cndmask_b32_e64 v0, v0, v5, s[16:17]
	v_mov_b32_e32 v5, s69
	v_cndmask_b32_e64 v0, v0, v5, s[18:19]
	v_mov_b32_e32 v5, s68
	v_cmp_eq_u32_e64 s[20:21], 7, v19
	ds_read_b128 v[8:11], v7
	s_nop 0
	v_cndmask_b32_e64 v13, v0, v5, s[20:21]
	v_mov_b32_e32 v0, s30
	v_mov_b32_e32 v5, s25
	v_cndmask_b32_e64 v0, v0, v5, s[0:1]
	v_mov_b32_e32 v5, s62
	v_cndmask_b32_e64 v0, v0, v5, s[8:9]
	v_mov_b32_e32 v5, s63
	v_cndmask_b32_e64 v0, v0, v5, s[10:11]
	v_mov_b32_e32 v5, s64
	v_cndmask_b32_e64 v0, v0, v5, s[14:15]
	v_mov_b32_e32 v5, s65
	v_cndmask_b32_e64 v0, v0, v5, s[16:17]
	v_mov_b32_e32 v5, s66
	v_cndmask_b32_e64 v0, v0, v5, s[18:19]
	v_mov_b32_e32 v5, s67
	v_cndmask_b32_e64 v12, v0, v5, s[20:21]
	v_and_b32_e32 v0, 0x7ffffffe, v18
	v_mad_u64_u32 v[4:5], s[0:1], v0, s59, v[4:5]
	v_ashrrev_i32_e32 v5, 31, v4
	v_lshl_add_u64 v[4:5], v[4:5], 4, v[12:13]
	s_waitcnt lgkmcnt(0)
	flat_store_dwordx4 v[4:5], v[8:11]
.LBB2_62:                               ; %Flow281
	s_or_b64 exec, exec, s[38:39]
                                        ; implicit-def: $vgpr0
                                        ; implicit-def: $vgpr7
                                        ; implicit-def: $vgpr5
                                        ; implicit-def: $vgpr4
.LBB2_63:                               ; %Flow290
	s_andn2_saveexec_b64 s[20:21], s[22:23]
	s_cbranch_execz .LBB2_73
; %bb.64:
	s_and_saveexec_b64 s[0:1], s[6:7]
	s_xor_b64 s[6:7], exec, s[0:1]
	s_cbranch_execz .LBB2_68
; %bb.65:
	v_cmp_eq_u32_e64 s[0:1], 8, v19
	s_and_saveexec_b64 s[8:9], s[0:1]
	s_cbranch_execz .LBB2_67
; %bb.66:                               ; %.preheader5.i183
	v_lshlrev_b32_e32 v21, 4, v3
	ds_read_b128 v[8:11], v21 offset:4096
	ds_read_b128 v[12:15], v21 offset:4608
	s_mov_b32 s0, 0x7060302
	s_waitcnt lgkmcnt(0)
	v_and_b32_e32 v17, 0xffff0000, v8
	v_lshlrev_b32_e32 v16, 16, v8
	v_and_b32_e32 v45, 0xffff0000, v12
	v_lshlrev_b32_e32 v44, 16, v12
	v_and_b32_e32 v39, 0xffff0000, v9
	v_lshlrev_b32_e32 v38, 16, v9
	v_and_b32_e32 v41, 0xffff0000, v10
	v_lshlrev_b32_e32 v40, 16, v10
	v_and_b32_e32 v43, 0xffff0000, v11
	v_lshlrev_b32_e32 v42, 16, v11
	v_and_b32_e32 v47, 0xffff0000, v13
	v_lshlrev_b32_e32 v46, 16, v13
	v_and_b32_e32 v49, 0xffff0000, v14
	v_lshlrev_b32_e32 v48, 16, v14
	v_and_b32_e32 v51, 0xffff0000, v15
	v_lshlrev_b32_e32 v50, 16, v15
	ds_read_b128 v[8:11], v21 offset:5120
	ds_read_b128 v[12:15], v21 offset:5632
	ds_read_b128 v[22:25], v21 offset:6144
	ds_read_b128 v[26:29], v21 offset:6656
	ds_read_b128 v[30:33], v21 offset:7168
	ds_read_b128 v[34:37], v21 offset:7680
	v_pk_add_f32 v[16:17], v[16:17], v[44:45]
	s_waitcnt lgkmcnt(0)
	v_and_b32_e32 v45, 0xffff0000, v8
	v_lshlrev_b32_e32 v44, 16, v8
	v_pk_add_f32 v[16:17], v[16:17], v[44:45]
	v_and_b32_e32 v45, 0xffff0000, v12
	v_lshlrev_b32_e32 v44, 16, v12
	v_pk_add_f32 v[16:17], v[16:17], v[44:45]
	v_and_b32_e32 v45, 0xffff0000, v22
	v_lshlrev_b32_e32 v44, 16, v22
	v_pk_add_f32 v[16:17], v[16:17], v[44:45]
	v_and_b32_e32 v45, 0xffff0000, v26
	v_lshlrev_b32_e32 v44, 16, v26
	v_pk_add_f32 v[16:17], v[16:17], v[44:45]
	v_and_b32_e32 v45, 0xffff0000, v30
	v_lshlrev_b32_e32 v44, 16, v30
	v_pk_add_f32 v[16:17], v[16:17], v[44:45]
	v_and_b32_e32 v45, 0xffff0000, v34
	v_lshlrev_b32_e32 v44, 16, v34
	v_pk_add_f32 v[16:17], v[16:17], v[44:45]
	v_pk_add_f32 v[38:39], v[38:39], v[46:47]
	v_and_b32_e32 v45, 0xffff0000, v9
	v_lshlrev_b32_e32 v44, 16, v9
	v_pk_add_f32 v[8:9], v[38:39], v[44:45]
	v_and_b32_e32 v39, 0xffff0000, v13
	v_lshlrev_b32_e32 v38, 16, v13
	v_pk_add_f32 v[8:9], v[8:9], v[38:39]
	v_and_b32_e32 v13, 0xffff0000, v23
	v_lshlrev_b32_e32 v12, 16, v23
	v_pk_add_f32 v[8:9], v[8:9], v[12:13]
	v_and_b32_e32 v13, 0xffff0000, v27
	v_lshlrev_b32_e32 v12, 16, v27
	v_pk_add_f32 v[8:9], v[8:9], v[12:13]
	v_and_b32_e32 v13, 0xffff0000, v31
	v_lshlrev_b32_e32 v12, 16, v31
	v_pk_add_f32 v[8:9], v[8:9], v[12:13]
	v_and_b32_e32 v13, 0xffff0000, v35
	v_lshlrev_b32_e32 v12, 16, v35
	v_pk_add_f32 v[8:9], v[8:9], v[12:13]
	v_pk_add_f32 v[12:13], v[40:41], v[48:49]
	v_and_b32_e32 v23, 0xffff0000, v10
	v_lshlrev_b32_e32 v22, 16, v10
	v_pk_add_f32 v[12:13], v[12:13], v[22:23]
	v_and_b32_e32 v23, 0xffff0000, v14
	v_lshlrev_b32_e32 v22, 16, v14
	v_pk_add_f32 v[12:13], v[12:13], v[22:23]
	v_and_b32_e32 v23, 0xffff0000, v24
	v_lshlrev_b32_e32 v22, 16, v24
	v_pk_add_f32 v[12:13], v[12:13], v[22:23]
	v_and_b32_e32 v23, 0xffff0000, v28
	v_lshlrev_b32_e32 v22, 16, v28
	v_pk_add_f32 v[12:13], v[12:13], v[22:23]
	v_and_b32_e32 v23, 0xffff0000, v32
	v_lshlrev_b32_e32 v22, 16, v32
	v_pk_add_f32 v[12:13], v[12:13], v[22:23]
	v_and_b32_e32 v23, 0xffff0000, v36
	v_lshlrev_b32_e32 v22, 16, v36
	v_pk_add_f32 v[12:13], v[12:13], v[22:23]
	v_pk_add_f32 v[22:23], v[42:43], v[50:51]
	v_and_b32_e32 v27, 0xffff0000, v11
	v_lshlrev_b32_e32 v26, 16, v11
	v_pk_add_f32 v[10:11], v[22:23], v[26:27]
	v_and_b32_e32 v23, 0xffff0000, v15
	v_lshlrev_b32_e32 v22, 16, v15
	v_pk_add_f32 v[10:11], v[10:11], v[22:23]
	v_and_b32_e32 v15, 0xffff0000, v25
	v_lshlrev_b32_e32 v14, 16, v25
	v_pk_add_f32 v[10:11], v[10:11], v[14:15]
	v_and_b32_e32 v15, 0xffff0000, v29
	v_lshlrev_b32_e32 v14, 16, v29
	v_pk_add_f32 v[10:11], v[10:11], v[14:15]
	v_and_b32_e32 v15, 0xffff0000, v33
	v_lshlrev_b32_e32 v14, 16, v33
	v_pk_add_f32 v[10:11], v[10:11], v[14:15]
	v_and_b32_e32 v15, 0xffff0000, v37
	v_lshlrev_b32_e32 v14, 16, v37
	v_pk_add_f32 v[10:11], v[10:11], v[14:15]
	v_perm_b32 v9, v9, v8, s0
	v_perm_b32 v11, v11, v10, s0
	v_perm_b32 v10, v13, v12, s0
	v_perm_b32 v8, v17, v16, s0
	ds_write_b128 v21, v[8:11] offset:4096
	ds_write_b128 v21, v[8:11] offset:4608
	ds_write_b128 v21, v[8:11] offset:5120
	ds_write_b128 v21, v[8:11] offset:5632
	ds_write_b128 v21, v[8:11] offset:6144
	ds_write_b128 v21, v[8:11] offset:6656
	ds_write_b128 v21, v[8:11] offset:7168
	ds_write_b128 v21, v[8:11] offset:7680
.LBB2_67:                               ; %Flow287
	s_or_b64 exec, exec, s[8:9]
.LBB2_68:                               ; %Flow288
	s_andn2_saveexec_b64 s[22:23], s[6:7]
	s_cbranch_execz .LBB2_70
; %bb.69:
	v_mov_b32_e32 v12, s31
	v_mov_b32_e32 v13, s74
	v_cmp_eq_u32_e64 s[0:1], 1, v19
	v_cmp_eq_u32_e64 s[6:7], 2, v19
	v_cmp_eq_u32_e64 s[8:9], 3, v19
	v_cndmask_b32_e64 v12, v12, v13, s[0:1]
	v_mov_b32_e32 v13, s73
	v_cndmask_b32_e64 v12, v12, v13, s[6:7]
	v_mov_b32_e32 v13, s72
	v_cndmask_b32_e64 v12, v12, v13, s[8:9]
	v_mov_b32_e32 v13, s71
	v_cmp_eq_u32_e64 s[10:11], 4, v19
	v_cmp_eq_u32_e64 s[14:15], 5, v19
	v_cmp_eq_u32_e64 s[16:17], 6, v19
	v_cndmask_b32_e64 v12, v12, v13, s[10:11]
	v_mov_b32_e32 v13, s70
	v_cndmask_b32_e64 v12, v12, v13, s[14:15]
	v_mov_b32_e32 v13, s69
	v_cndmask_b32_e64 v12, v12, v13, s[16:17]
	v_mov_b32_e32 v13, s68
	v_cmp_eq_u32_e64 s[18:19], 7, v19
	v_mov_b32_e32 v14, s25
	ds_read_b128 v[8:11], v7
	v_cndmask_b32_e64 v13, v12, v13, s[18:19]
	v_mov_b32_e32 v12, s30
	v_cndmask_b32_e64 v12, v12, v14, s[0:1]
	v_mov_b32_e32 v14, s62
	v_cndmask_b32_e64 v12, v12, v14, s[6:7]
	v_mov_b32_e32 v14, s63
	v_cndmask_b32_e64 v12, v12, v14, s[8:9]
	v_mov_b32_e32 v14, s64
	v_cndmask_b32_e64 v12, v12, v14, s[10:11]
	v_mov_b32_e32 v14, s65
	v_cndmask_b32_e64 v12, v12, v14, s[14:15]
	v_mov_b32_e32 v14, s66
	v_cndmask_b32_e64 v12, v12, v14, s[16:17]
	v_mov_b32_e32 v14, s67
	v_cndmask_b32_e64 v12, v12, v14, s[18:19]
	v_mul_lo_u32 v14, s33, v5
	v_lshl_add_u32 v14, v14, 6, v4
	v_ashrrev_i32_e32 v15, 31, v14
	v_lshl_add_u64 v[12:13], v[14:15], 4, v[12:13]
	s_waitcnt lgkmcnt(0)
	flat_store_dwordx4 v[12:13], v[8:11]
.LBB2_70:                               ; %_ZN7commkit7kernels6step_aIDF16bLb0EEEvPT_ii.exit191
	s_or_b64 exec, exec, s[22:23]
	s_movk_i32 s0, 0xff
	v_cmp_lt_u32_e64 s[0:1], s0, v0
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_saveexec_b64 s[22:23], s[0:1]
	s_cbranch_execz .LBB2_72
; %bb.71:
	v_add_u32_e32 v0, -8, v19
	ds_read_b128 v[8:11], v7
	v_mov_b32_e32 v7, s31
	v_mov_b32_e32 v12, s74
	v_cmp_eq_u32_e64 s[0:1], 1, v0
	v_cmp_eq_u32_e64 s[6:7], 2, v0
	v_cmp_eq_u32_e64 s[8:9], 3, v0
	v_cndmask_b32_e64 v7, v7, v12, s[0:1]
	v_mov_b32_e32 v12, s73
	v_cndmask_b32_e64 v7, v7, v12, s[6:7]
	v_mov_b32_e32 v12, s72
	v_cndmask_b32_e64 v7, v7, v12, s[8:9]
	v_mov_b32_e32 v12, s71
	v_cmp_eq_u32_e64 s[10:11], 4, v0
	v_cmp_eq_u32_e64 s[14:15], 5, v0
	v_cmp_eq_u32_e64 s[16:17], 6, v0
	v_cndmask_b32_e64 v7, v7, v12, s[10:11]
	v_mov_b32_e32 v12, s70
	v_cndmask_b32_e64 v7, v7, v12, s[14:15]
	v_mov_b32_e32 v12, s69
	v_cndmask_b32_e64 v7, v7, v12, s[16:17]
	v_mov_b32_e32 v12, s68
	v_cmp_eq_u32_e64 s[18:19], 7, v0
	v_mov_b32_e32 v0, s30
	s_nop 0
	v_cndmask_b32_e64 v13, v7, v12, s[18:19]
	v_mov_b32_e32 v7, s25
	v_cndmask_b32_e64 v0, v0, v7, s[0:1]
	v_mov_b32_e32 v7, s62
	v_cndmask_b32_e64 v0, v0, v7, s[6:7]
	v_mov_b32_e32 v7, s63
	v_cndmask_b32_e64 v0, v0, v7, s[8:9]
	v_mov_b32_e32 v7, s64
	v_cndmask_b32_e64 v0, v0, v7, s[10:11]
	v_mov_b32_e32 v7, s65
	v_cndmask_b32_e64 v0, v0, v7, s[14:15]
	v_mov_b32_e32 v7, s66
	v_cndmask_b32_e64 v0, v0, v7, s[16:17]
	v_mov_b32_e32 v7, s67
	v_cndmask_b32_e64 v12, v0, v7, s[18:19]
	v_lshl_or_b32 v0, v5, 1, 1
	v_mad_u64_u32 v[4:5], s[0:1], v0, s59, v[4:5]
	v_ashrrev_i32_e32 v5, 31, v4
	v_lshl_add_u64 v[4:5], v[4:5], 4, v[12:13]
	s_waitcnt lgkmcnt(0)
	flat_store_dwordx4 v[4:5], v[8:11]
.LBB2_72:                               ; %Flow286
	s_or_b64 exec, exec, s[22:23]
.LBB2_73:                               ; %Flow291
	s_or_b64 exec, exec, s[20:21]
.LBB2_74:                               ; %Flow302
	s_or_b64 exec, exec, s[48:49]
	v_mov_b32_e32 v7, 0
	s_waitcnt lgkmcnt(0)
	s_barrier
	global_load_dword v0, v7, s[34:35]
	s_waitcnt vmcnt(0)
	v_add_u32_e32 v4, 1, v0
	s_and_saveexec_b64 s[6:7], s[12:13]
	s_cbranch_execz .LBB2_77
; %bb.75:
	global_load_dwordx2 v[0:1], v1, s[26:27]
	s_mov_b32 s25, s58
	s_lshl_b64 s[0:1], s[2:3], 5
	s_lshl_b64 s[8:9], s[24:25], 2
	s_add_u32 s8, s8, s0
	s_addc_u32 s9, s9, s1
	s_add_u32 s0, s36, s0
	s_mov_b64 s[2:3], 0xa00
	s_addc_u32 s1, s37, s1
	s_add_u32 s0, s0, 0xa00
	s_addc_u32 s1, s1, 0
	s_waitcnt vmcnt(0)
	v_lshl_add_u64 v[0:1], v[0:1], 0, s[8:9]
	v_lshl_add_u64 v[8:9], v[0:1], 0, s[2:3]
	;;#ASMSTART
	buffer_wbl2 sc0 sc1
	global_store_dword v[8:9], v4, off sc0 sc1
	
	;;#ASMEND
	v_lshl_add_u64 v[0:1], s[0:1], 0, v[6:7]
	s_mov_b64 s[2:3], 0
.LBB2_76:                               ; =>This Inner Loop Header: Depth=1
	;;#ASMSTART
	global_load_dword v5, v[0:1], off sc1
	s_waitcnt vmcnt(0)
	
	;;#ASMEND
	s_nop 0
	v_cmp_ge_u32_e64 s[0:1], v5, v4
	s_or_b64 s[2:3], s[0:1], s[2:3]
	s_andn2_b64 exec, exec, s[2:3]
	s_cbranch_execnz .LBB2_76
.LBB2_77:                               ; %Flow279
	s_or_b64 exec, exec, s[6:7]
	s_barrier
	s_and_saveexec_b64 s[0:1], s[4:5]
	s_cbranch_execz .LBB2_79
; %bb.78:
	v_mov_b32_e32 v0, 0
	global_store_dword v0, v4, s[34:35]
.LBB2_79:                               ; %_ZN7commkit12end_sync_asmILi8ELb1ELb0EEEvRKNS_11RankSignalsEPNS_6SignalEi.exit
	s_or_b64 exec, exec, s[0:1]
	v_cmp_lt_u32_e64 s[0:1], 1, v18
	s_and_saveexec_b64 s[2:3], s[0:1]
	s_cbranch_execz .LBB2_84
; %bb.80:                               ; %.lr.ph233
	v_add_u32_e32 v0, -8, v19
	v_mul_lo_u32 v4, s60, v0
	v_mad_u64_u32 v[0:1], s[0:1], s60, v19, v[2:3]
	s_add_i32 s0, s59, s61
	s_lshl_b32 s6, s33, 6
	v_add3_u32 v1, s0, v4, v3
	s_mov_b32 s7, 0
	s_mov_b64 s[4:5], 0
	s_branch .LBB2_82
.LBB2_81:                               ;   in Loop: Header=BB2_82 Depth=1
	s_or_b64 exec, exec, s[0:1]
	v_ashrrev_i32_e32 v5, 31, v4
	v_lshlrev_b64 v[8:9], 4, v[4:5]
	v_lshl_add_u64 v[4:5], s[30:31], 0, v[8:9]
	global_load_dwordx4 v[4:7], v[4:5], off
	v_add_u32_e32 v20, -1, v20
	s_add_i32 s7, s7, 1
	v_cmp_eq_u32_e64 s[0:1], 0, v20
	v_lshl_add_u64 v[8:9], s[28:29], 0, v[8:9]
	s_or_b64 s[4:5], s[0:1], s[4:5]
	v_add_u32_e32 v1, s6, v1
	s_waitcnt vmcnt(0)
	global_store_dwordx4 v[8:9], v[4:7], off
	s_andn2_b64 exec, exec, s[4:5]
	s_cbranch_execz .LBB2_84
.LBB2_82:                               ; =>This Inner Loop Header: Depth=1
	v_mov_b32_e32 v4, v1
	s_and_saveexec_b64 s[0:1], vcc
	s_cbranch_execz .LBB2_81
; %bb.83:                               ;   in Loop: Header=BB2_82 Depth=1
	s_mul_i32 s8, s6, s7
	v_add_u32_e32 v4, s8, v0
	s_branch .LBB2_81
.LBB2_84:                               ; %Flow277
	s_or_b64 exec, exec, s[2:3]
	v_and_b32_e32 v0, 1, v18
	v_cmp_eq_u32_e64 s[0:1], 0, v0
	s_and_b64 s[0:1], s[0:1], vcc
	s_and_saveexec_b64 s[2:3], s[0:1]
	s_cbranch_execz .LBB2_86
; %bb.85:
	v_add_u32_e32 v1, -1, v18
	v_mul_lo_u32 v0, s60, v19
	v_mul_lo_u32 v1, v1, s59
	v_add3_u32 v0, v0, v2, v1
	v_ashrrev_i32_e32 v1, 31, v0
	v_lshlrev_b64 v[4:5], 4, v[0:1]
	v_lshl_add_u64 v[0:1], s[30:31], 0, v[4:5]
	global_load_dwordx4 v[0:3], v[0:1], off
	v_lshl_add_u64 v[4:5], s[28:29], 0, v[4:5]
	s_waitcnt vmcnt(0)
	global_store_dwordx4 v[4:5], v[0:3], off
.LBB2_86:
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel _ZN7commkit7kernels7car_tp8IDF16bEEvPNS_8RankDataENS_11RankSignalsEPNS_6SignalEPT_ii
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
		.amdhsa_next_free_vgpr 64
		.amdhsa_next_free_sgpr 75
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
	.section	.text._ZN7commkit7kernels7car_tp8IDF16bEEvPNS_8RankDataENS_11RankSignalsEPNS_6SignalEPT_ii,"axG",@progbits,_ZN7commkit7kernels7car_tp8IDF16bEEvPNS_8RankDataENS_11RankSignalsEPNS_6SignalEPT_ii,comdat
.Lfunc_end2:
	.size	_ZN7commkit7kernels7car_tp8IDF16bEEvPNS_8RankDataENS_11RankSignalsEPNS_6SignalEPT_ii, .Lfunc_end2-_ZN7commkit7kernels7car_tp8IDF16bEEvPNS_8RankDataENS_11RankSignalsEPNS_6SignalEPT_ii
                                        ; -- End function
	.set _ZN7commkit7kernels7car_tp8IDF16bEEvPNS_8RankDataENS_11RankSignalsEPNS_6SignalEPT_ii.num_vgpr, 64
	.set _ZN7commkit7kernels7car_tp8IDF16bEEvPNS_8RankDataENS_11RankSignalsEPNS_6SignalEPT_ii.num_agpr, 0
	.set _ZN7commkit7kernels7car_tp8IDF16bEEvPNS_8RankDataENS_11RankSignalsEPNS_6SignalEPT_ii.numbered_sgpr, 75
	.set _ZN7commkit7kernels7car_tp8IDF16bEEvPNS_8RankDataENS_11RankSignalsEPNS_6SignalEPT_ii.private_seg_size, 0
	.set _ZN7commkit7kernels7car_tp8IDF16bEEvPNS_8RankDataENS_11RankSignalsEPNS_6SignalEPT_ii.uses_vcc, 1
	.set _ZN7commkit7kernels7car_tp8IDF16bEEvPNS_8RankDataENS_11RankSignalsEPNS_6SignalEPT_ii.uses_flat_scratch, 0
	.set _ZN7commkit7kernels7car_tp8IDF16bEEvPNS_8RankDataENS_11RankSignalsEPNS_6SignalEPT_ii.has_dyn_sized_stack, 0
	.set _ZN7commkit7kernels7car_tp8IDF16bEEvPNS_8RankDataENS_11RankSignalsEPNS_6SignalEPT_ii.has_recursion, 0
	.set _ZN7commkit7kernels7car_tp8IDF16bEEvPNS_8RankDataENS_11RankSignalsEPNS_6SignalEPT_ii.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 11624
; TotalNumSgprs: 81
; NumVgprs: 64
; NumAgprs: 0
; TotalNumVgprs: 64
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 8192 bytes/workgroup (compile time only)
; SGPRBlocks: 10
; VGPRBlocks: 7
; NumSGPRsForWavesPerEU: 81
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
	.section	.text._ZN7commkit7kernels23allreduce_double_bufferIDF16bEEvPNS_8RankDataENS_11RankSignalsEPNS_6SignalEPT_ii,"axG",@progbits,_ZN7commkit7kernels23allreduce_double_bufferIDF16bEEvPNS_8RankDataENS_11RankSignalsEPNS_6SignalEPT_ii,comdat
	.protected	_ZN7commkit7kernels23allreduce_double_bufferIDF16bEEvPNS_8RankDataENS_11RankSignalsEPNS_6SignalEPT_ii ; -- Begin function _ZN7commkit7kernels23allreduce_double_bufferIDF16bEEvPNS_8RankDataENS_11RankSignalsEPNS_6SignalEPT_ii
	.globl	_ZN7commkit7kernels23allreduce_double_bufferIDF16bEEvPNS_8RankDataENS_11RankSignalsEPNS_6SignalEPT_ii
	.p2align	8
	.type	_ZN7commkit7kernels23allreduce_double_bufferIDF16bEEvPNS_8RankDataENS_11RankSignalsEPNS_6SignalEPT_ii,@function
_ZN7commkit7kernels23allreduce_double_bufferIDF16bEEvPNS_8RankDataENS_11RankSignalsEPNS_6SignalEPT_ii: ; @_ZN7commkit7kernels23allreduce_double_bufferIDF16bEEvPNS_8RankDataENS_11RankSignalsEPNS_6SignalEPT_ii
; %bb.0:
	s_load_dwordx2 s[24:25], s[0:1], 0x60
	s_load_dwordx2 s[4:5], s[0:1], 0x0
	s_add_u32 s26, s0, 16
	s_addc_u32 s27, s1, 0
	s_load_dword s33, s[0:1], 0x68
	s_waitcnt lgkmcnt(0)
	s_ashr_i32 s58, s24, 31
	s_lshr_b32 s3, s58, 29
	s_add_i32 s3, s24, s3
	s_and_b32 s3, s3, -8
	s_sub_i32 s6, s24, s3
	s_ashr_i32 s7, s6, 31
	s_lshl_b64 s[6:7], s[6:7], 3
	s_add_u32 s8, s4, s6
	s_addc_u32 s9, s5, s7
	s_add_u32 s6, s26, s6
	s_addc_u32 s7, s27, s7
	s_add_i32 s3, s24, 1
	s_load_dwordx2 s[38:39], s[8:9], 0x0
	s_ashr_i32 s8, s3, 31
	s_lshr_b32 s8, s8, 29
	s_add_i32 s8, s3, s8
	s_and_b32 s8, s8, -8
	s_sub_i32 s8, s3, s8
	s_ashr_i32 s9, s8, 31
	s_lshl_b64 s[8:9], s[8:9], 3
	s_add_u32 s10, s4, s8
	s_addc_u32 s11, s5, s9
	s_add_u32 s8, s26, s8
	s_addc_u32 s9, s27, s9
	s_add_i32 s3, s24, 2
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
	s_add_u32 s10, s26, s10
	s_addc_u32 s11, s27, s11
	s_add_i32 s3, s24, 3
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
	s_add_u32 s12, s26, s12
	s_addc_u32 s13, s27, s13
	s_add_i32 s3, s24, 4
	s_load_dwordx2 s[44:45], s[14:15], 0x0
	v_and_b32_e32 v15, 63, v0
	s_load_dwordx2 s[14:15], s[12:13], 0x0
	s_ashr_i32 s12, s3, 31
	s_lshr_b32 s12, s12, 29
	s_add_i32 s12, s3, s12
	s_and_b32 s12, s12, -8
	s_sub_i32 s12, s3, s12
	s_ashr_i32 s13, s12, 31
	s_lshl_b64 s[12:13], s[12:13], 3
	s_add_u32 s16, s4, s12
	s_addc_u32 s17, s5, s13
	s_add_u32 s12, s26, s12
	s_addc_u32 s13, s27, s13
	s_add_i32 s3, s24, 5
	s_load_dwordx2 s[48:49], s[16:17], 0x0
	v_mov_b32_e32 v30, 0
	s_load_dwordx2 s[16:17], s[12:13], 0x0
	s_ashr_i32 s12, s3, 31
	s_lshr_b32 s12, s12, 29
	s_add_i32 s12, s3, s12
	s_and_b32 s12, s12, -8
	s_sub_i32 s12, s3, s12
	s_ashr_i32 s13, s12, 31
	s_lshl_b64 s[12:13], s[12:13], 3
	s_add_u32 s18, s4, s12
	s_addc_u32 s19, s5, s13
	s_add_u32 s12, s26, s12
	s_addc_u32 s13, s27, s13
	s_add_i32 s3, s24, 6
	s_load_dwordx2 s[50:51], s[18:19], 0x0
	s_nop 0
	s_load_dwordx2 s[18:19], s[12:13], 0x0
	s_ashr_i32 s12, s3, 31
	s_lshr_b32 s12, s12, 29
	s_add_i32 s12, s3, s12
	s_and_b32 s12, s12, -8
	s_sub_i32 s12, s3, s12
	s_ashr_i32 s13, s12, 31
	s_lshl_b64 s[12:13], s[12:13], 3
	s_add_u32 s20, s4, s12
	s_addc_u32 s21, s5, s13
	s_add_u32 s12, s26, s12
	s_addc_u32 s13, s27, s13
	s_add_i32 s3, s24, 7
	s_load_dwordx2 s[52:53], s[20:21], 0x0
	s_nop 0
	s_load_dwordx2 s[20:21], s[12:13], 0x0
	s_ashr_i32 s12, s3, 31
	s_lshr_b32 s12, s12, 29
	s_add_i32 s12, s3, s12
	s_and_b32 s12, s12, -8
	s_sub_i32 s12, s3, s12
	s_ashr_i32 s13, s12, 31
	s_lshl_b64 s[12:13], s[12:13], 3
	s_add_u32 s4, s4, s12
	s_addc_u32 s5, s5, s13
	s_load_dwordx2 s[54:55], s[4:5], 0x0
	s_add_u32 s4, s26, s12
	s_addc_u32 s5, s27, s13
	s_ashr_i32 s3, s25, 31
	s_lshr_b32 s3, s3, 29
	s_add_i32 s3, s25, s3
	s_ashr_i32 s60, s3, 3
	s_load_dwordx2 s[6:7], s[6:7], 0x0
	s_lshl_b32 s61, s2, 6
	s_load_dwordx2 s[22:23], s[4:5], 0x0
	s_mul_i32 s4, s60, s24
	s_load_dwordx2 s[8:9], s[8:9], 0x0
	s_lshl_b32 s59, s33, 6
	s_load_dwordx2 s[10:11], s[10:11], 0x0
	s_add_i32 s3, s4, s60
	v_or_b32_e32 v14, s61, v15
	s_cmp_eq_u32 s24, 7
	s_cselect_b32 s3, s25, s3
	v_add_u32_e32 v16, s4, v14
	v_cmp_gt_i32_e32 vcc, s3, v16
	s_and_saveexec_b64 s[12:13], vcc
	s_cbranch_execz .LBB3_12
; %bb.1:                                ; %.lr.ph.preheader
	v_cvt_f32_u32_e32 v1, s59
	v_add_u32_e32 v2, s59, v16
	v_mov_b32_e32 v3, s59
	s_sub_i32 s25, 0, s59
	v_rcp_iflag_f32_e32 v4, v1
	v_cmp_gt_i32_e32 vcc, s3, v2
	v_max_i32_e32 v1, s3, v2
	s_mov_b32 s28, 0
	v_mul_f32_e32 v4, 0x4f7ffffe, v4
	v_cvt_u32_f32_e32 v4, v4
	v_addc_co_u32_e64 v2, s[4:5], v16, v3, vcc
	v_sub_u32_e32 v2, v1, v2
	v_mul_lo_u32 v3, s25, v4
	v_mul_hi_u32 v3, v4, v3
	v_add_u32_e32 v3, v4, v3
	v_mul_hi_u32 v3, v2, v3
	v_mul_lo_u32 v4, v3, s59
	v_sub_u32_e32 v2, v2, v4
	v_add_u32_e32 v4, 1, v3
	v_cmp_le_u32_e64 s[4:5], s59, v2
	s_mov_b64 s[30:31], -1
                                        ; implicit-def: $vgpr30
	s_nop 0
	v_cndmask_b32_e64 v3, v3, v4, s[4:5]
	v_subrev_u32_e32 v4, s59, v2
	v_cndmask_b32_e64 v2, v2, v4, s[4:5]
	v_add_u32_e32 v4, 1, v3
	v_cmp_le_u32_e64 s[4:5], s59, v2
	s_nop 1
	v_cndmask_b32_e64 v2, v3, v4, s[4:5]
	v_addc_co_u32_e32 v4, vcc, 1, v2, vcc
	v_cmp_lt_u32_e32 vcc, 1, v4
	v_mov_b32_e32 v3, 0
	v_mov_b32_e32 v2, v16
	s_and_saveexec_b64 s[4:5], vcc
	s_cbranch_execz .LBB3_7
; %bb.2:                                ; %vector.ph
	v_and_b32_e32 v5, -2, v4
	s_mov_b64 s[30:31], 0
	v_mov_b32_e32 v1, v5
	s_mov_b32 s29, s28
.LBB3_3:                                ; %vector.body
                                        ; =>This Inner Loop Header: Depth=1
	v_add_u32_e32 v1, -2, v1
	s_add_i32 s29, s29, 1
	s_add_i32 s28, s28, 1
	v_cmp_eq_u32_e32 vcc, 0, v1
	s_or_b64 s[30:31], vcc, s[30:31]
	v_mov_b64_e32 v[2:3], s[28:29]
	s_andn2_b64 exec, exec, s[30:31]
	s_cbranch_execnz .LBB3_3
; %bb.4:                                ; %middle.block
	s_or_b64 exec, exec, s[30:31]
	v_add_u32_e32 v30, v2, v3
	v_cmp_ne_u32_e32 vcc, v4, v5
	s_mov_b64 s[28:29], 0
	v_mov_b32_e32 v3, 0
                                        ; implicit-def: $vgpr2
                                        ; implicit-def: $vgpr1
	s_and_saveexec_b64 s[30:31], vcc
; %bb.5:                                ; %middle.block..lr.ph.preheader269_crit_edge
	v_mad_u64_u32 v[2:3], s[34:35], v5, s59, v[16:17]
	v_add_u32_e32 v1, s59, v2
	s_mov_b64 s[28:29], exec
	v_max_i32_e32 v1, s3, v1
	v_mov_b32_e32 v3, v30
; %bb.6:                                ; %Flow343
	s_or_b64 exec, exec, s[30:31]
	s_orn2_b64 s[30:31], s[28:29], exec
.LBB3_7:                                ; %Flow342
	s_or_b64 exec, exec, s[4:5]
	s_and_saveexec_b64 s[4:5], s[30:31]
	s_cbranch_execz .LBB3_11
; %bb.8:                                ; %.lr.ph.preheader269
	s_max_u32 s25, s59, 1
	v_cvt_f32_u32_e32 v4, s25
	v_sub_u32_e32 v1, v1, v2
	v_subrev_u32_e32 v5, s59, v1
	s_sub_i32 s28, 0, s25
	v_rcp_iflag_f32_e32 v4, v4
	v_min_u32_e32 v5, 1, v5
	v_add_u32_e32 v3, v3, v5
	v_sub_u32_e32 v1, v1, v5
	v_mul_f32_e32 v4, 0x4f7ffffe, v4
	v_cvt_u32_f32_e32 v4, v4
	v_subrev_u32_e32 v1, s59, v1
	v_mul_lo_u32 v5, s28, v4
	v_mul_hi_u32 v5, v4, v5
	v_add_u32_e32 v4, v4, v5
	v_mul_hi_u32 v4, v1, v4
	v_mul_lo_u32 v5, v4, s25
	v_sub_u32_e32 v1, v1, v5
	v_add_u32_e32 v6, 1, v4
	v_subrev_u32_e32 v5, s25, v1
	v_cmp_le_u32_e32 vcc, s25, v1
	s_mov_b64 s[28:29], 0
	s_nop 0
	v_cndmask_b32_e32 v1, v1, v5, vcc
	v_cndmask_b32_e32 v4, v4, v6, vcc
	v_add_u32_e32 v5, 1, v4
	v_cmp_le_u32_e32 vcc, s25, v1
	s_nop 1
	v_cndmask_b32_e32 v1, v4, v5, vcc
	v_add3_u32 v30, v3, v1, 1
.LBB3_9:                                ; %.lr.ph
                                        ; =>This Inner Loop Header: Depth=1
	v_add_u32_e32 v2, s59, v2
	v_cmp_le_i32_e32 vcc, s3, v2
	s_or_b64 s[28:29], vcc, s[28:29]
	s_andn2_b64 exec, exec, s[28:29]
	s_cbranch_execnz .LBB3_9
; %bb.10:                               ; %Flow341
	s_or_b64 exec, exec, s[28:29]
.LBB3_11:                               ; %Flow344
	s_or_b64 exec, exec, s[4:5]
.LBB3_12:                               ; %._crit_edge
	s_or_b64 exec, exec, s[12:13]
	s_load_dwordx2 s[36:37], s[0:1], 0x50
	s_mov_b32 s3, 0
	s_lshl_b64 s[4:5], s[2:3], 2
	v_cmp_gt_u32_e64 s[12:13], 8, v0
	v_lshlrev_b32_e32 v32, 3, v0
	s_waitcnt lgkmcnt(0)
	s_add_u32 s4, s36, s4
	s_addc_u32 s5, s37, s5
	s_load_dword s30, s[4:5], 0x1400
	s_add_u32 s34, s4, 0x1400
	s_addc_u32 s35, s5, 0
	v_lshlrev_b32_e32 v18, 2, v0
	s_waitcnt lgkmcnt(0)
	s_add_i32 s30, s30, 1
	s_and_saveexec_b64 s[4:5], s[12:13]
	s_cbranch_execz .LBB3_15
; %bb.13:
	global_load_dwordx2 v[4:5], v32, s[26:27]
	s_mov_b32 s25, s58
	s_lshl_b64 s[28:29], s[2:3], 5
	s_lshl_b64 s[46:47], s[24:25], 2
	s_add_u32 s46, s46, s28
	s_addc_u32 s47, s47, s29
	s_add_u32 s28, s36, s28
	v_mov_b32_e32 v19, 0
	s_addc_u32 s29, s37, s29
	v_mov_b32_e32 v1, s30
	v_lshl_add_u64 v[2:3], s[28:29], 0, v[18:19]
	s_mov_b64 s[28:29], 0
	s_waitcnt vmcnt(0)
	v_lshl_add_u64 v[4:5], s[46:47], 0, v[4:5]
	global_store_dword v[4:5], v1, off sc0 sc1
.LBB3_14:                               ; =>This Inner Loop Header: Depth=1
	global_load_dword v1, v[2:3], off sc1
	s_waitcnt vmcnt(0)
	v_cmp_le_u32_e32 vcc, s30, v1
	s_or_b64 s[28:29], vcc, s[28:29]
	s_andn2_b64 exec, exec, s[28:29]
	s_cbranch_execnz .LBB3_14
.LBB3_15:                               ; %Flow339
	s_or_b64 exec, exec, s[4:5]
	s_load_dwordx2 s[28:29], s[0:1], 0x58
	v_cmp_eq_u32_e64 s[4:5], 0, v0
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_saveexec_b64 s[0:1], s[4:5]
	s_cbranch_execz .LBB3_17
; %bb.16:
	v_mov_b32_e32 v1, 0
	v_mov_b32_e32 v2, s30
	global_store_dword v1, v2, s[34:35]
.LBB3_17:                               ; %_ZN7commkit10start_syncILi8EEEvRKNS_11RankSignalsEPNS_6SignalEi.exit
	s_or_b64 exec, exec, s[0:1]
	s_add_u32 s30, s6, 0x1780
	s_addc_u32 s31, s7, 0
	s_add_u32 s25, s8, 0x1780
	s_addc_u32 s74, s9, 0
	s_add_u32 s62, s10, 0x1780
	s_addc_u32 s73, s11, 0
	s_add_u32 s63, s14, 0x1780
	s_addc_u32 s72, s15, 0
	s_add_u32 s64, s16, 0x1780
	s_addc_u32 s71, s17, 0
	s_add_u32 s65, s18, 0x1780
	s_addc_u32 s70, s19, 0
	s_add_u32 s66, s20, 0x1780
	s_addc_u32 s69, s21, 0
	s_movk_i32 s6, 0x200
	s_add_u32 s67, s22, 0x1780
	v_cmp_gt_u32_e32 vcc, s6, v0
	s_movk_i32 s6, 0x1ff
	s_addc_u32 s68, s23, 0
	v_lshrrev_b32_e32 v31, 6, v0
	v_and_b32_e32 v34, 0x3c0, v0
	v_cmp_gt_u32_e64 s[0:1], 2, v30
	v_cmp_lt_u32_e64 s[6:7], s6, v0
	s_and_saveexec_b64 s[8:9], s[0:1]
	s_xor_b64 s[22:23], exec, s[8:9]
	s_cbranch_execz .LBB3_23
; %bb.18:
	s_and_saveexec_b64 s[46:47], vcc
	s_cbranch_execz .LBB3_22
; %bb.19:
	v_mov_b32_e32 v1, s39
	v_mov_b32_e32 v2, s41
	v_cmp_eq_u32_e64 s[0:1], 1, v31
	v_cmp_eq_u32_e64 s[8:9], 2, v31
	v_cmp_eq_u32_e64 s[10:11], 3, v31
	v_cndmask_b32_e64 v1, v1, v2, s[0:1]
	v_mov_b32_e32 v2, s43
	v_cndmask_b32_e64 v1, v1, v2, s[8:9]
	v_mov_b32_e32 v2, s45
	v_cndmask_b32_e64 v1, v1, v2, s[10:11]
	v_mov_b32_e32 v2, s49
	v_cmp_eq_u32_e64 s[14:15], 4, v31
	v_cmp_eq_u32_e64 s[16:17], 5, v31
	v_cmp_eq_u32_e64 s[18:19], 6, v31
	v_cndmask_b32_e64 v1, v1, v2, s[14:15]
	v_mov_b32_e32 v2, s51
	v_cndmask_b32_e64 v1, v1, v2, s[16:17]
	v_mov_b32_e32 v2, s53
	v_cndmask_b32_e64 v1, v1, v2, s[18:19]
	v_mov_b32_e32 v2, s55
	v_cmp_eq_u32_e64 s[20:21], 7, v31
	v_ashrrev_i32_e32 v17, 31, v16
	v_lshlrev_b32_e32 v13, 4, v15
	v_cndmask_b32_e64 v3, v1, v2, s[20:21]
	v_mov_b32_e32 v1, s38
	v_mov_b32_e32 v2, s40
	v_cndmask_b32_e64 v1, v1, v2, s[0:1]
	v_mov_b32_e32 v2, s42
	v_cndmask_b32_e64 v1, v1, v2, s[8:9]
	v_mov_b32_e32 v2, s44
	v_cndmask_b32_e64 v1, v1, v2, s[10:11]
	v_mov_b32_e32 v2, s48
	v_cndmask_b32_e64 v1, v1, v2, s[14:15]
	v_mov_b32_e32 v2, s50
	v_cndmask_b32_e64 v1, v1, v2, s[16:17]
	v_mov_b32_e32 v2, s52
	v_cndmask_b32_e64 v1, v1, v2, s[18:19]
	v_mov_b32_e32 v2, s54
	v_cndmask_b32_e64 v2, v1, v2, s[20:21]
	v_lshl_add_u64 v[2:3], v[16:17], 4, v[2:3]
	flat_load_dwordx4 v[2:5], v[2:3]
	v_lshl_add_u32 v12, v34, 4, v13
	v_cmp_gt_u32_e64 s[0:1], 64, v0
	s_waitcnt vmcnt(0) lgkmcnt(0)
	ds_write_b128 v12, v[2:5]
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_saveexec_b64 s[8:9], s[0:1]
	s_cbranch_execz .LBB3_21
; %bb.20:                               ; %.preheader5.i241
	ds_read_b128 v[0:3], v13
	ds_read_b128 v[4:7], v13 offset:1024
	s_mov_b32 s0, 0x7060302
	s_waitcnt lgkmcnt(1)
	v_and_b32_e32 v29, 0xffff0000, v0
	v_lshlrev_b32_e32 v28, 16, v0
	s_waitcnt lgkmcnt(0)
	v_and_b32_e32 v45, 0xffff0000, v4
	v_lshlrev_b32_e32 v44, 16, v4
	v_and_b32_e32 v39, 0xffff0000, v1
	v_lshlrev_b32_e32 v38, 16, v1
	v_and_b32_e32 v41, 0xffff0000, v2
	v_lshlrev_b32_e32 v40, 16, v2
	v_and_b32_e32 v43, 0xffff0000, v3
	v_lshlrev_b32_e32 v42, 16, v3
	v_and_b32_e32 v47, 0xffff0000, v5
	v_lshlrev_b32_e32 v46, 16, v5
	v_and_b32_e32 v49, 0xffff0000, v6
	v_lshlrev_b32_e32 v48, 16, v6
	v_and_b32_e32 v51, 0xffff0000, v7
	v_lshlrev_b32_e32 v50, 16, v7
	ds_read_b128 v[20:23], v13 offset:2048
	ds_read_b128 v[24:27], v13 offset:3072
	ds_read_b128 v[34:37], v13 offset:4096
	ds_read_b128 v[8:11], v13 offset:5120
	ds_read_b128 v[4:7], v13 offset:6144
	ds_read_b128 v[0:3], v13 offset:7168
	v_pk_add_f32 v[28:29], v[28:29], v[44:45]
	s_waitcnt lgkmcnt(5)
	v_and_b32_e32 v45, 0xffff0000, v20
	v_lshlrev_b32_e32 v44, 16, v20
	v_pk_add_f32 v[28:29], v[28:29], v[44:45]
	s_waitcnt lgkmcnt(4)
	v_and_b32_e32 v45, 0xffff0000, v24
	v_lshlrev_b32_e32 v44, 16, v24
	v_pk_add_f32 v[28:29], v[28:29], v[44:45]
	s_waitcnt lgkmcnt(3)
	v_and_b32_e32 v45, 0xffff0000, v34
	v_lshlrev_b32_e32 v44, 16, v34
	v_pk_add_f32 v[28:29], v[28:29], v[44:45]
	s_waitcnt lgkmcnt(2)
	v_and_b32_e32 v45, 0xffff0000, v8
	v_lshlrev_b32_e32 v44, 16, v8
	v_pk_add_f32 v[28:29], v[28:29], v[44:45]
	s_waitcnt lgkmcnt(1)
	v_and_b32_e32 v45, 0xffff0000, v4
	v_lshlrev_b32_e32 v44, 16, v4
	v_pk_add_f32 v[28:29], v[28:29], v[44:45]
	s_waitcnt lgkmcnt(0)
	v_and_b32_e32 v45, 0xffff0000, v0
	v_lshlrev_b32_e32 v44, 16, v0
	v_pk_add_f32 v[28:29], v[28:29], v[44:45]
	v_pk_add_f32 v[38:39], v[38:39], v[46:47]
	v_and_b32_e32 v45, 0xffff0000, v21
	v_lshlrev_b32_e32 v44, 16, v21
	v_pk_add_f32 v[20:21], v[38:39], v[44:45]
	v_and_b32_e32 v39, 0xffff0000, v25
	v_lshlrev_b32_e32 v38, 16, v25
	v_pk_add_f32 v[20:21], v[20:21], v[38:39]
	v_and_b32_e32 v25, 0xffff0000, v35
	v_lshlrev_b32_e32 v24, 16, v35
	v_pk_add_f32 v[20:21], v[20:21], v[24:25]
	v_and_b32_e32 v25, 0xffff0000, v9
	v_lshlrev_b32_e32 v24, 16, v9
	v_pk_add_f32 v[8:9], v[20:21], v[24:25]
	v_and_b32_e32 v21, 0xffff0000, v5
	v_lshlrev_b32_e32 v20, 16, v5
	v_pk_add_f32 v[4:5], v[8:9], v[20:21]
	v_and_b32_e32 v9, 0xffff0000, v1
	v_lshlrev_b32_e32 v8, 16, v1
	v_pk_add_f32 v[0:1], v[4:5], v[8:9]
	v_pk_add_f32 v[4:5], v[40:41], v[48:49]
	v_and_b32_e32 v9, 0xffff0000, v22
	v_lshlrev_b32_e32 v8, 16, v22
	v_pk_add_f32 v[4:5], v[4:5], v[8:9]
	v_and_b32_e32 v9, 0xffff0000, v26
	v_lshlrev_b32_e32 v8, 16, v26
	v_pk_add_f32 v[4:5], v[4:5], v[8:9]
	v_and_b32_e32 v9, 0xffff0000, v36
	v_lshlrev_b32_e32 v8, 16, v36
	v_pk_add_f32 v[4:5], v[4:5], v[8:9]
	v_and_b32_e32 v9, 0xffff0000, v10
	v_lshlrev_b32_e32 v8, 16, v10
	v_pk_add_f32 v[4:5], v[4:5], v[8:9]
	v_and_b32_e32 v9, 0xffff0000, v6
	v_lshlrev_b32_e32 v8, 16, v6
	v_pk_add_f32 v[4:5], v[4:5], v[8:9]
	v_and_b32_e32 v9, 0xffff0000, v2
	v_lshlrev_b32_e32 v8, 16, v2
	v_pk_add_f32 v[4:5], v[4:5], v[8:9]
	v_pk_add_f32 v[8:9], v[42:43], v[50:51]
	v_and_b32_e32 v21, 0xffff0000, v23
	v_lshlrev_b32_e32 v20, 16, v23
	v_pk_add_f32 v[8:9], v[8:9], v[20:21]
	v_and_b32_e32 v21, 0xffff0000, v27
	v_lshlrev_b32_e32 v20, 16, v27
	v_pk_add_f32 v[8:9], v[8:9], v[20:21]
	v_and_b32_e32 v21, 0xffff0000, v37
	v_lshlrev_b32_e32 v20, 16, v37
	v_pk_add_f32 v[8:9], v[8:9], v[20:21]
	v_and_b32_e32 v21, 0xffff0000, v11
	v_lshlrev_b32_e32 v20, 16, v11
	v_pk_add_f32 v[8:9], v[8:9], v[20:21]
	v_and_b32_e32 v11, 0xffff0000, v7
	v_lshlrev_b32_e32 v10, 16, v7
	v_pk_add_f32 v[6:7], v[8:9], v[10:11]
	v_and_b32_e32 v9, 0xffff0000, v3
	v_lshlrev_b32_e32 v8, 16, v3
	v_pk_add_f32 v[2:3], v[6:7], v[8:9]
	v_perm_b32 v1, v1, v0, s0
	v_perm_b32 v3, v3, v2, s0
	v_perm_b32 v2, v5, v4, s0
	v_perm_b32 v0, v29, v28, s0
	ds_write_b128 v13, v[0:3]
	ds_write_b128 v13, v[0:3] offset:1024
	ds_write_b128 v13, v[0:3] offset:2048
	ds_write_b128 v13, v[0:3] offset:3072
	ds_write_b128 v13, v[0:3] offset:4096
	ds_write_b128 v13, v[0:3] offset:5120
	ds_write_b128 v13, v[0:3] offset:6144
	ds_write_b128 v13, v[0:3] offset:7168
.LBB3_21:                               ; %_ZN7commkit7kernels22vmemload_cal_vmemstoreIDF16bLi8ELi0EEEvPT_ii.exit249
	s_or_b64 exec, exec, s[8:9]
	v_mov_b32_e32 v4, s31
	v_mov_b32_e32 v5, s74
	v_cmp_eq_u32_e64 s[0:1], 1, v31
	v_cmp_eq_u32_e64 s[8:9], 2, v31
	v_cmp_eq_u32_e64 s[10:11], 3, v31
	v_cndmask_b32_e64 v4, v4, v5, s[0:1]
	v_mov_b32_e32 v5, s73
	v_cndmask_b32_e64 v4, v4, v5, s[8:9]
	v_mov_b32_e32 v5, s72
	v_cndmask_b32_e64 v4, v4, v5, s[10:11]
	v_mov_b32_e32 v5, s71
	v_cmp_eq_u32_e64 s[14:15], 4, v31
	v_cmp_eq_u32_e64 s[16:17], 5, v31
	v_cmp_eq_u32_e64 s[18:19], 6, v31
	v_cndmask_b32_e64 v4, v4, v5, s[14:15]
	v_mov_b32_e32 v5, s70
	v_cndmask_b32_e64 v4, v4, v5, s[16:17]
	v_mov_b32_e32 v5, s69
	v_cndmask_b32_e64 v4, v4, v5, s[18:19]
	v_mov_b32_e32 v5, s68
	v_cmp_eq_u32_e64 s[20:21], 7, v31
	v_mov_b32_e32 v6, s25
	s_waitcnt lgkmcnt(0)
	v_cndmask_b32_e64 v5, v4, v5, s[20:21]
	v_mov_b32_e32 v4, s30
	v_cndmask_b32_e64 v4, v4, v6, s[0:1]
	v_mov_b32_e32 v6, s62
	v_cndmask_b32_e64 v4, v4, v6, s[8:9]
	v_mov_b32_e32 v6, s63
	v_cndmask_b32_e64 v4, v4, v6, s[10:11]
	v_mov_b32_e32 v6, s64
	s_barrier
	ds_read_b128 v[0:3], v12
	v_cndmask_b32_e64 v4, v4, v6, s[14:15]
	v_mov_b32_e32 v6, s65
	v_cndmask_b32_e64 v4, v4, v6, s[16:17]
	v_mov_b32_e32 v6, s66
	v_cndmask_b32_e64 v4, v4, v6, s[18:19]
	v_mov_b32_e32 v6, s67
	v_cndmask_b32_e64 v4, v4, v6, s[20:21]
	v_lshl_add_u64 v[4:5], v[16:17], 4, v[4:5]
	s_waitcnt lgkmcnt(0)
	flat_store_dwordx4 v[4:5], v[0:3]
.LBB3_22:                               ; %Flow314
	s_or_b64 exec, exec, s[46:47]
                                        ; implicit-def: $vgpr0
                                        ; implicit-def: $vgpr16
                                        ; implicit-def: $vgpr34
.LBB3_23:                               ; %Flow335
	s_or_saveexec_b64 s[46:47], s[22:23]
	v_lshrrev_b32_e32 v33, 1, v30
	s_xor_b64 exec, exec, s[46:47]
	s_cbranch_execz .LBB3_74
; %bb.24:
	v_lshlrev_b32_e32 v19, 4, v15
	s_and_saveexec_b64 s[22:23], vcc
	s_cbranch_execz .LBB3_26
; %bb.25:
	v_mov_b32_e32 v1, s39
	v_mov_b32_e32 v2, s41
	v_cmp_eq_u32_e64 s[0:1], 1, v31
	v_cmp_eq_u32_e64 s[8:9], 2, v31
	v_cmp_eq_u32_e64 s[10:11], 3, v31
	v_cndmask_b32_e64 v1, v1, v2, s[0:1]
	v_mov_b32_e32 v2, s43
	v_cndmask_b32_e64 v1, v1, v2, s[8:9]
	v_mov_b32_e32 v2, s45
	v_cndmask_b32_e64 v1, v1, v2, s[10:11]
	v_mov_b32_e32 v2, s49
	v_cmp_eq_u32_e64 s[14:15], 4, v31
	v_cmp_eq_u32_e64 s[16:17], 5, v31
	v_cmp_eq_u32_e64 s[18:19], 6, v31
	v_cndmask_b32_e64 v1, v1, v2, s[14:15]
	v_mov_b32_e32 v2, s51
	v_cndmask_b32_e64 v1, v1, v2, s[16:17]
	v_mov_b32_e32 v2, s53
	v_cndmask_b32_e64 v1, v1, v2, s[18:19]
	v_mov_b32_e32 v2, s55
	v_cmp_eq_u32_e64 s[20:21], 7, v31
	v_ashrrev_i32_e32 v17, 31, v16
	s_nop 0
	v_cndmask_b32_e64 v3, v1, v2, s[20:21]
	v_mov_b32_e32 v1, s38
	v_mov_b32_e32 v2, s40
	v_cndmask_b32_e64 v1, v1, v2, s[0:1]
	v_mov_b32_e32 v2, s42
	v_cndmask_b32_e64 v1, v1, v2, s[8:9]
	v_mov_b32_e32 v2, s44
	v_cndmask_b32_e64 v1, v1, v2, s[10:11]
	v_mov_b32_e32 v2, s48
	v_cndmask_b32_e64 v1, v1, v2, s[14:15]
	v_mov_b32_e32 v2, s50
	v_cndmask_b32_e64 v1, v1, v2, s[16:17]
	v_mov_b32_e32 v2, s52
	v_cndmask_b32_e64 v1, v1, v2, s[18:19]
	v_mov_b32_e32 v2, s54
	v_cndmask_b32_e64 v2, v1, v2, s[20:21]
	v_lshl_add_u64 v[2:3], v[16:17], 4, v[2:3]
	flat_load_dwordx4 v[2:5], v[2:3]
	v_lshl_add_u32 v1, v34, 4, v19
	s_waitcnt vmcnt(0) lgkmcnt(0)
	ds_write_b128 v1, v[2:5]
.LBB3_26:
	s_or_b64 exec, exec, s[22:23]
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_saveexec_b64 s[0:1], s[6:7]
	s_xor_b64 s[22:23], exec, s[0:1]
	s_cbranch_execz .LBB3_28
; %bb.27:
	v_add_u32_e32 v1, -8, v31
	v_mov_b32_e32 v2, s39
	v_mov_b32_e32 v3, s41
	v_cmp_eq_u32_e64 s[0:1], 1, v1
	v_cmp_eq_u32_e64 s[8:9], 2, v1
	v_cmp_eq_u32_e64 s[10:11], 3, v1
	v_cndmask_b32_e64 v2, v2, v3, s[0:1]
	v_mov_b32_e32 v3, s43
	v_cndmask_b32_e64 v2, v2, v3, s[8:9]
	v_mov_b32_e32 v3, s45
	v_cndmask_b32_e64 v2, v2, v3, s[10:11]
	v_mov_b32_e32 v3, s49
	v_cmp_eq_u32_e64 s[14:15], 4, v1
	v_cmp_eq_u32_e64 s[16:17], 5, v1
	v_cmp_eq_u32_e64 s[18:19], 6, v1
	v_cndmask_b32_e64 v2, v2, v3, s[14:15]
	v_mov_b32_e32 v3, s51
	v_cndmask_b32_e64 v2, v2, v3, s[16:17]
	v_mov_b32_e32 v3, s53
	v_cndmask_b32_e64 v2, v2, v3, s[18:19]
	v_mov_b32_e32 v3, s55
	v_cmp_eq_u32_e64 s[20:21], 7, v1
	v_mov_b32_e32 v4, s40
	v_lshl_or_b32 v1, v1, 10, v19
	v_cndmask_b32_e64 v3, v2, v3, s[20:21]
	v_mov_b32_e32 v2, s38
	v_cndmask_b32_e64 v2, v2, v4, s[0:1]
	v_mov_b32_e32 v4, s42
	v_cndmask_b32_e64 v2, v2, v4, s[8:9]
	v_mov_b32_e32 v4, s44
	v_cndmask_b32_e64 v2, v2, v4, s[10:11]
	v_mov_b32_e32 v4, s48
	v_cndmask_b32_e64 v2, v2, v4, s[14:15]
	v_mov_b32_e32 v4, s50
	v_cndmask_b32_e64 v2, v2, v4, s[16:17]
	v_mov_b32_e32 v4, s52
	v_cndmask_b32_e64 v2, v2, v4, s[18:19]
	v_mov_b32_e32 v4, s54
	v_cndmask_b32_e64 v2, v2, v4, s[20:21]
	v_add_u32_e32 v4, s59, v16
	v_ashrrev_i32_e32 v5, 31, v4
	v_lshl_add_u64 v[2:3], v[4:5], 4, v[2:3]
	flat_load_dwordx4 v[2:5], v[2:3]
	s_waitcnt vmcnt(0) lgkmcnt(0)
	ds_write_b128 v1, v[2:5] offset:8192
.LBB3_28:                               ; %Flow333
	s_andn2_saveexec_b64 s[8:9], s[22:23]
	s_cbranch_execz .LBB3_32
; %bb.29:
	v_cmp_gt_u32_e64 s[0:1], 64, v0
	s_and_saveexec_b64 s[10:11], s[0:1]
	s_cbranch_execz .LBB3_31
; %bb.30:                               ; %.preheader5.i
	ds_read_b128 v[2:5], v19
	ds_read_b128 v[6:9], v19 offset:1024
	s_mov_b32 s0, 0x7060302
	s_waitcnt lgkmcnt(0)
	v_and_b32_e32 v29, 0xffff0000, v2
	v_lshlrev_b32_e32 v28, 16, v2
	v_and_b32_e32 v47, 0xffff0000, v6
	v_lshlrev_b32_e32 v46, 16, v6
	v_and_b32_e32 v41, 0xffff0000, v3
	v_lshlrev_b32_e32 v40, 16, v3
	v_and_b32_e32 v43, 0xffff0000, v4
	v_lshlrev_b32_e32 v42, 16, v4
	v_and_b32_e32 v45, 0xffff0000, v5
	v_lshlrev_b32_e32 v44, 16, v5
	v_and_b32_e32 v49, 0xffff0000, v7
	v_lshlrev_b32_e32 v48, 16, v7
	v_and_b32_e32 v51, 0xffff0000, v8
	v_lshlrev_b32_e32 v50, 16, v8
	v_and_b32_e32 v53, 0xffff0000, v9
	v_lshlrev_b32_e32 v52, 16, v9
	ds_read_b128 v[20:23], v19 offset:2048
	ds_read_b128 v[24:27], v19 offset:3072
	ds_read_b128 v[36:39], v19 offset:4096
	ds_read_b128 v[10:13], v19 offset:5120
	ds_read_b128 v[6:9], v19 offset:6144
	ds_read_b128 v[2:5], v19 offset:7168
	v_pk_add_f32 v[28:29], v[28:29], v[46:47]
	s_waitcnt lgkmcnt(0)
	v_and_b32_e32 v47, 0xffff0000, v20
	v_lshlrev_b32_e32 v46, 16, v20
	v_pk_add_f32 v[28:29], v[28:29], v[46:47]
	v_and_b32_e32 v47, 0xffff0000, v24
	v_lshlrev_b32_e32 v46, 16, v24
	v_pk_add_f32 v[28:29], v[28:29], v[46:47]
	v_and_b32_e32 v47, 0xffff0000, v36
	v_lshlrev_b32_e32 v46, 16, v36
	v_pk_add_f32 v[28:29], v[28:29], v[46:47]
	v_and_b32_e32 v47, 0xffff0000, v10
	v_lshlrev_b32_e32 v46, 16, v10
	v_pk_add_f32 v[28:29], v[28:29], v[46:47]
	v_and_b32_e32 v47, 0xffff0000, v6
	v_lshlrev_b32_e32 v46, 16, v6
	v_pk_add_f32 v[28:29], v[28:29], v[46:47]
	v_and_b32_e32 v47, 0xffff0000, v2
	v_lshlrev_b32_e32 v46, 16, v2
	v_pk_add_f32 v[28:29], v[28:29], v[46:47]
	v_pk_add_f32 v[40:41], v[40:41], v[48:49]
	v_and_b32_e32 v47, 0xffff0000, v21
	v_lshlrev_b32_e32 v46, 16, v21
	v_pk_add_f32 v[20:21], v[40:41], v[46:47]
	v_and_b32_e32 v41, 0xffff0000, v25
	v_lshlrev_b32_e32 v40, 16, v25
	v_pk_add_f32 v[20:21], v[20:21], v[40:41]
	v_and_b32_e32 v25, 0xffff0000, v37
	v_lshlrev_b32_e32 v24, 16, v37
	v_pk_add_f32 v[20:21], v[20:21], v[24:25]
	v_and_b32_e32 v25, 0xffff0000, v11
	v_lshlrev_b32_e32 v24, 16, v11
	v_pk_add_f32 v[10:11], v[20:21], v[24:25]
	v_and_b32_e32 v21, 0xffff0000, v7
	v_lshlrev_b32_e32 v20, 16, v7
	v_pk_add_f32 v[6:7], v[10:11], v[20:21]
	v_and_b32_e32 v11, 0xffff0000, v3
	v_lshlrev_b32_e32 v10, 16, v3
	v_pk_add_f32 v[2:3], v[6:7], v[10:11]
	v_pk_add_f32 v[6:7], v[42:43], v[50:51]
	v_and_b32_e32 v11, 0xffff0000, v22
	v_lshlrev_b32_e32 v10, 16, v22
	v_pk_add_f32 v[6:7], v[6:7], v[10:11]
	v_and_b32_e32 v11, 0xffff0000, v26
	v_lshlrev_b32_e32 v10, 16, v26
	v_pk_add_f32 v[6:7], v[6:7], v[10:11]
	v_and_b32_e32 v11, 0xffff0000, v38
	v_lshlrev_b32_e32 v10, 16, v38
	v_pk_add_f32 v[6:7], v[6:7], v[10:11]
	v_and_b32_e32 v11, 0xffff0000, v12
	v_lshlrev_b32_e32 v10, 16, v12
	v_pk_add_f32 v[6:7], v[6:7], v[10:11]
	v_and_b32_e32 v11, 0xffff0000, v8
	v_lshlrev_b32_e32 v10, 16, v8
	v_pk_add_f32 v[6:7], v[6:7], v[10:11]
	v_and_b32_e32 v11, 0xffff0000, v4
	v_lshlrev_b32_e32 v10, 16, v4
	v_pk_add_f32 v[6:7], v[6:7], v[10:11]
	v_pk_add_f32 v[10:11], v[44:45], v[52:53]
	v_and_b32_e32 v21, 0xffff0000, v23
	v_lshlrev_b32_e32 v20, 16, v23
	v_pk_add_f32 v[10:11], v[10:11], v[20:21]
	v_and_b32_e32 v21, 0xffff0000, v27
	v_lshlrev_b32_e32 v20, 16, v27
	v_pk_add_f32 v[10:11], v[10:11], v[20:21]
	v_and_b32_e32 v21, 0xffff0000, v39
	v_lshlrev_b32_e32 v20, 16, v39
	v_pk_add_f32 v[10:11], v[10:11], v[20:21]
	v_and_b32_e32 v21, 0xffff0000, v13
	v_lshlrev_b32_e32 v20, 16, v13
	v_pk_add_f32 v[10:11], v[10:11], v[20:21]
	v_and_b32_e32 v13, 0xffff0000, v9
	v_lshlrev_b32_e32 v12, 16, v9
	v_pk_add_f32 v[8:9], v[10:11], v[12:13]
	v_and_b32_e32 v11, 0xffff0000, v5
	v_lshlrev_b32_e32 v10, 16, v5
	v_pk_add_f32 v[4:5], v[8:9], v[10:11]
	v_perm_b32 v3, v3, v2, s0
	v_perm_b32 v5, v5, v4, s0
	v_perm_b32 v4, v7, v6, s0
	v_perm_b32 v2, v29, v28, s0
	ds_write_b128 v19, v[2:5]
	ds_write_b128 v19, v[2:5] offset:1024
	ds_write_b128 v19, v[2:5] offset:2048
	ds_write_b128 v19, v[2:5] offset:3072
	ds_write_b128 v19, v[2:5] offset:4096
	ds_write_b128 v19, v[2:5] offset:5120
	ds_write_b128 v19, v[2:5] offset:6144
	ds_write_b128 v19, v[2:5] offset:7168
.LBB3_31:                               ; %Flow332
	s_or_b64 exec, exec, s[10:11]
.LBB3_32:                               ; %_ZN7commkit7kernels22vmemload_cal_vmemstoreIDF16bLi8ELi0EEEvPT_ii.exit
	s_or_b64 exec, exec, s[8:9]
	v_add_u32_e32 v1, -1, v33
	v_cmp_lt_u32_e64 s[0:1], 3, v30
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_saveexec_b64 s[56:57], s[0:1]
	s_cbranch_execz .LBB3_47
; %bb.33:                               ; %.lr.ph261
	v_mov_b32_e32 v2, s31
	v_mov_b32_e32 v3, s74
	v_cmp_eq_u32_e64 s[0:1], 1, v31
	v_mov_b32_e32 v5, s73
	v_cmp_eq_u32_e64 s[10:11], 2, v31
	v_cndmask_b32_e64 v4, v2, v3, s[0:1]
	v_mov_b32_e32 v6, s72
	v_cndmask_b32_e64 v4, v4, v5, s[10:11]
	v_cmp_eq_u32_e64 s[14:15], 3, v31
	v_mov_b32_e32 v7, s71
	v_cmp_eq_u32_e64 s[16:17], 4, v31
	v_cndmask_b32_e64 v4, v4, v6, s[14:15]
	v_mov_b32_e32 v8, s70
	v_cndmask_b32_e64 v4, v4, v7, s[16:17]
	v_cmp_eq_u32_e64 s[18:19], 5, v31
	v_mov_b32_e32 v9, s69
	v_cmp_eq_u32_e64 s[20:21], 6, v31
	v_cndmask_b32_e64 v4, v4, v8, s[18:19]
	v_mov_b32_e32 v10, s68
	v_cndmask_b32_e64 v4, v4, v9, s[20:21]
	v_cmp_eq_u32_e64 s[22:23], 7, v31
	v_mov_b32_e32 v11, s25
	v_mov_b32_e32 v13, s62
	v_cndmask_b32_e64 v21, v4, v10, s[22:23]
	v_mov_b32_e32 v4, s30
	v_cndmask_b32_e64 v12, v4, v11, s[0:1]
	v_cndmask_b32_e64 v12, v12, v13, s[10:11]
	v_mov_b32_e32 v24, s63
	v_cndmask_b32_e64 v12, v12, v24, s[14:15]
	v_mov_b32_e32 v26, s64
	v_cndmask_b32_e64 v12, v12, v26, s[16:17]
	v_mov_b32_e32 v27, s65
	v_cndmask_b32_e64 v12, v12, v27, s[18:19]
	v_mov_b32_e32 v28, s66
	v_cndmask_b32_e64 v12, v12, v28, s[20:21]
	v_mov_b32_e32 v29, s67
	v_cndmask_b32_e64 v20, v12, v29, s[22:23]
	v_mov_b32_e32 v12, s39
	v_mov_b32_e32 v35, s41
	v_cndmask_b32_e64 v22, v12, v35, s[0:1]
	v_mov_b32_e32 v36, s43
	v_cndmask_b32_e64 v22, v22, v36, s[10:11]
	v_mov_b32_e32 v37, s45
	v_cndmask_b32_e64 v22, v22, v37, s[14:15]
	v_mov_b32_e32 v38, s49
	v_cndmask_b32_e64 v22, v22, v38, s[16:17]
	v_mov_b32_e32 v39, s51
	v_cndmask_b32_e64 v22, v22, v39, s[18:19]
	v_mov_b32_e32 v40, s53
	v_cndmask_b32_e64 v22, v22, v40, s[20:21]
	v_mov_b32_e32 v41, s55
	v_mov_b32_e32 v42, s38
	v_mov_b32_e32 v43, s40
	v_add_u32_e32 v25, -8, v31
	v_cndmask_b32_e64 v23, v22, v41, s[22:23]
	v_cndmask_b32_e64 v22, v42, v43, s[0:1]
	v_mov_b32_e32 v44, s42
	v_cmp_eq_u32_e64 s[0:1], 1, v25
	v_cndmask_b32_e64 v22, v22, v44, s[10:11]
	v_mov_b32_e32 v45, s44
	v_cndmask_b32_e64 v2, v2, v3, s[0:1]
	v_cmp_eq_u32_e64 s[10:11], 2, v25
	v_cndmask_b32_e64 v22, v22, v45, s[14:15]
	v_mov_b32_e32 v46, s48
	v_cndmask_b32_e64 v2, v2, v5, s[10:11]
	v_cmp_eq_u32_e64 s[14:15], 3, v25
	v_cndmask_b32_e64 v22, v22, v46, s[16:17]
	v_mov_b32_e32 v47, s50
	v_cndmask_b32_e64 v2, v2, v6, s[14:15]
	v_cmp_eq_u32_e64 s[16:17], 4, v25
	v_cndmask_b32_e64 v22, v22, v47, s[18:19]
	v_mov_b32_e32 v48, s52
	v_cndmask_b32_e64 v2, v2, v7, s[16:17]
	v_cmp_eq_u32_e64 s[18:19], 5, v25
	v_cndmask_b32_e64 v22, v22, v48, s[20:21]
	v_mov_b32_e32 v49, s54
	v_cndmask_b32_e64 v2, v2, v8, s[18:19]
	v_cmp_eq_u32_e64 s[20:21], 6, v25
	v_cndmask_b32_e64 v22, v22, v49, s[22:23]
	v_cmp_eq_u32_e64 s[22:23], 7, v25
	v_cndmask_b32_e64 v2, v2, v9, s[20:21]
	v_lshlrev_b32_e32 v50, 10, v25
	v_cndmask_b32_e64 v25, v2, v10, s[22:23]
	v_cndmask_b32_e64 v2, v4, v11, s[0:1]
	v_cndmask_b32_e64 v2, v2, v13, s[10:11]
	v_cndmask_b32_e64 v2, v2, v24, s[14:15]
	v_cndmask_b32_e64 v2, v2, v26, s[16:17]
	v_cndmask_b32_e64 v2, v2, v27, s[18:19]
	v_cndmask_b32_e64 v2, v2, v28, s[20:21]
	v_cndmask_b32_e64 v24, v2, v29, s[22:23]
	v_cndmask_b32_e64 v2, v12, v35, s[0:1]
	v_cndmask_b32_e64 v2, v2, v36, s[10:11]
	v_cndmask_b32_e64 v2, v2, v37, s[14:15]
	v_cndmask_b32_e64 v2, v2, v38, s[16:17]
	v_cndmask_b32_e64 v2, v2, v39, s[18:19]
	v_cndmask_b32_e64 v2, v2, v40, s[20:21]
	v_cndmask_b32_e64 v27, v2, v41, s[22:23]
	v_cndmask_b32_e64 v2, v42, v43, s[0:1]
	v_cndmask_b32_e64 v2, v2, v44, s[10:11]
	v_cndmask_b32_e64 v2, v2, v45, s[14:15]
	v_cndmask_b32_e64 v2, v2, v46, s[16:17]
	v_cndmask_b32_e64 v2, v2, v47, s[18:19]
	v_cndmask_b32_e64 v2, v2, v48, s[20:21]
	v_cmp_eq_u32_e64 s[8:9], 8, v31
	v_lshl_add_u32 v17, v34, 4, v19
	v_cndmask_b32_e64 v26, v2, v49, s[22:23]
	v_cmp_gt_u32_e64 s[10:11], 64, v0
	s_lshl_b32 s18, s59, 1
	s_mul_i32 s19, s33, 0xc0
	s_mov_b64 s[14:15], 0
	s_mov_b32 s20, 0x7060302
	v_add_u32_e32 v35, v19, v50
	v_mov_b32_e32 v28, v16
	v_mov_b32_e32 v36, v1
	s_branch .LBB3_36
.LBB3_34:                               ; %Flow326
                                        ;   in Loop: Header=BB3_36 Depth=1
	s_or_b64 exec, exec, s[16:17]
.LBB3_35:                               ; %_ZN7commkit7kernels22vmemload_cal_vmemstoreIDF16bLi8ELi0EEEvPT_ii.exit209
                                        ;   in Loop: Header=BB3_36 Depth=1
	s_or_b64 exec, exec, s[0:1]
	v_add_u32_e32 v36, -1, v36
	v_cmp_eq_u32_e64 s[0:1], 0, v36
	s_or_b64 s[14:15], s[0:1], s[14:15]
	v_add_u32_e32 v28, s18, v28
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_andn2_b64 exec, exec, s[14:15]
	s_cbranch_execz .LBB3_47
.LBB3_36:                               ; =>This Inner Loop Header: Depth=1
	s_and_saveexec_b64 s[0:1], s[6:7]
	s_xor_b64 s[0:1], exec, s[0:1]
	s_cbranch_execz .LBB3_40
; %bb.37:                               ;   in Loop: Header=BB3_36 Depth=1
	s_and_saveexec_b64 s[16:17], s[8:9]
	s_cbranch_execz .LBB3_39
; %bb.38:                               ; %.preheader5.i192
                                        ;   in Loop: Header=BB3_36 Depth=1
	ds_read_b128 v[2:5], v19 offset:8192
	ds_read_b128 v[6:9], v19 offset:9216
	s_waitcnt lgkmcnt(0)
	v_and_b32_e32 v51, 0xffff0000, v2
	v_lshlrev_b32_e32 v50, 16, v2
	v_and_b32_e32 v59, 0xffff0000, v6
	v_lshlrev_b32_e32 v58, 16, v6
	v_and_b32_e32 v53, 0xffff0000, v3
	v_lshlrev_b32_e32 v52, 16, v3
	v_and_b32_e32 v55, 0xffff0000, v4
	v_lshlrev_b32_e32 v54, 16, v4
	v_and_b32_e32 v57, 0xffff0000, v5
	v_lshlrev_b32_e32 v56, 16, v5
	v_and_b32_e32 v61, 0xffff0000, v7
	v_lshlrev_b32_e32 v60, 16, v7
	v_and_b32_e32 v63, 0xffff0000, v8
	v_lshlrev_b32_e32 v62, 16, v8
	v_and_b32_e32 v65, 0xffff0000, v9
	v_lshlrev_b32_e32 v64, 16, v9
	ds_read_b128 v[38:41], v19 offset:10240
	ds_read_b128 v[42:45], v19 offset:11264
	ds_read_b128 v[46:49], v19 offset:12288
	ds_read_b128 v[10:13], v19 offset:13312
	ds_read_b128 v[6:9], v19 offset:14336
	ds_read_b128 v[2:5], v19 offset:15360
	v_pk_add_f32 v[50:51], v[50:51], v[58:59]
	s_waitcnt lgkmcnt(0)
	v_and_b32_e32 v59, 0xffff0000, v38
	v_lshlrev_b32_e32 v58, 16, v38
	v_pk_add_f32 v[50:51], v[50:51], v[58:59]
	v_and_b32_e32 v59, 0xffff0000, v42
	v_lshlrev_b32_e32 v58, 16, v42
	v_pk_add_f32 v[50:51], v[50:51], v[58:59]
	v_and_b32_e32 v59, 0xffff0000, v46
	v_lshlrev_b32_e32 v58, 16, v46
	v_pk_add_f32 v[50:51], v[50:51], v[58:59]
	v_and_b32_e32 v59, 0xffff0000, v10
	v_lshlrev_b32_e32 v58, 16, v10
	v_pk_add_f32 v[50:51], v[50:51], v[58:59]
	v_and_b32_e32 v59, 0xffff0000, v6
	v_lshlrev_b32_e32 v58, 16, v6
	v_pk_add_f32 v[50:51], v[50:51], v[58:59]
	v_and_b32_e32 v59, 0xffff0000, v2
	v_lshlrev_b32_e32 v58, 16, v2
	v_pk_add_f32 v[50:51], v[50:51], v[58:59]
	v_pk_add_f32 v[52:53], v[52:53], v[60:61]
	v_and_b32_e32 v59, 0xffff0000, v39
	v_lshlrev_b32_e32 v58, 16, v39
	v_pk_add_f32 v[38:39], v[52:53], v[58:59]
	v_and_b32_e32 v53, 0xffff0000, v43
	v_lshlrev_b32_e32 v52, 16, v43
	v_pk_add_f32 v[38:39], v[38:39], v[52:53]
	v_and_b32_e32 v43, 0xffff0000, v47
	v_lshlrev_b32_e32 v42, 16, v47
	v_pk_add_f32 v[38:39], v[38:39], v[42:43]
	v_and_b32_e32 v43, 0xffff0000, v11
	v_lshlrev_b32_e32 v42, 16, v11
	v_pk_add_f32 v[10:11], v[38:39], v[42:43]
	v_and_b32_e32 v39, 0xffff0000, v7
	v_lshlrev_b32_e32 v38, 16, v7
	v_pk_add_f32 v[6:7], v[10:11], v[38:39]
	v_and_b32_e32 v11, 0xffff0000, v3
	v_lshlrev_b32_e32 v10, 16, v3
	v_pk_add_f32 v[2:3], v[6:7], v[10:11]
	v_pk_add_f32 v[6:7], v[54:55], v[62:63]
	v_and_b32_e32 v11, 0xffff0000, v40
	v_lshlrev_b32_e32 v10, 16, v40
	v_pk_add_f32 v[6:7], v[6:7], v[10:11]
	v_and_b32_e32 v11, 0xffff0000, v44
	v_lshlrev_b32_e32 v10, 16, v44
	v_pk_add_f32 v[6:7], v[6:7], v[10:11]
	v_and_b32_e32 v11, 0xffff0000, v48
	v_lshlrev_b32_e32 v10, 16, v48
	v_pk_add_f32 v[6:7], v[6:7], v[10:11]
	v_and_b32_e32 v11, 0xffff0000, v12
	v_lshlrev_b32_e32 v10, 16, v12
	v_pk_add_f32 v[6:7], v[6:7], v[10:11]
	v_and_b32_e32 v11, 0xffff0000, v8
	v_lshlrev_b32_e32 v10, 16, v8
	v_pk_add_f32 v[6:7], v[6:7], v[10:11]
	v_and_b32_e32 v11, 0xffff0000, v4
	v_lshlrev_b32_e32 v10, 16, v4
	v_pk_add_f32 v[6:7], v[6:7], v[10:11]
	v_pk_add_f32 v[10:11], v[56:57], v[64:65]
	v_and_b32_e32 v39, 0xffff0000, v41
	v_lshlrev_b32_e32 v38, 16, v41
	v_pk_add_f32 v[10:11], v[10:11], v[38:39]
	v_and_b32_e32 v39, 0xffff0000, v45
	v_lshlrev_b32_e32 v38, 16, v45
	v_pk_add_f32 v[10:11], v[10:11], v[38:39]
	v_and_b32_e32 v39, 0xffff0000, v49
	v_lshlrev_b32_e32 v38, 16, v49
	v_pk_add_f32 v[10:11], v[10:11], v[38:39]
	v_and_b32_e32 v39, 0xffff0000, v13
	v_lshlrev_b32_e32 v38, 16, v13
	v_pk_add_f32 v[10:11], v[10:11], v[38:39]
	v_and_b32_e32 v13, 0xffff0000, v9
	v_lshlrev_b32_e32 v12, 16, v9
	v_pk_add_f32 v[8:9], v[10:11], v[12:13]
	v_and_b32_e32 v11, 0xffff0000, v5
	v_lshlrev_b32_e32 v10, 16, v5
	v_pk_add_f32 v[4:5], v[8:9], v[10:11]
	v_perm_b32 v3, v3, v2, s20
	v_perm_b32 v5, v5, v4, s20
	v_perm_b32 v4, v7, v6, s20
	v_perm_b32 v2, v51, v50, s20
	ds_write_b128 v19, v[2:5] offset:8192
	ds_write_b128 v19, v[2:5] offset:9216
	ds_write_b128 v19, v[2:5] offset:10240
	ds_write_b128 v19, v[2:5] offset:11264
	ds_write_b128 v19, v[2:5] offset:12288
	ds_write_b128 v19, v[2:5] offset:13312
	ds_write_b128 v19, v[2:5] offset:14336
	ds_write_b128 v19, v[2:5] offset:15360
.LBB3_39:                               ; %Flow328
                                        ;   in Loop: Header=BB3_36 Depth=1
	s_or_b64 exec, exec, s[16:17]
.LBB3_40:                               ; %Flow329
                                        ;   in Loop: Header=BB3_36 Depth=1
	s_andn2_saveexec_b64 s[0:1], s[0:1]
	s_cbranch_execz .LBB3_42
; %bb.41:                               ;   in Loop: Header=BB3_36 Depth=1
	ds_read_b128 v[2:5], v17
	v_ashrrev_i32_e32 v29, 31, v28
	v_add_u32_e32 v6, s18, v28
	v_lshl_add_u64 v[8:9], v[28:29], 4, v[20:21]
	v_ashrrev_i32_e32 v7, 31, v6
	s_waitcnt lgkmcnt(0)
	flat_store_dwordx4 v[8:9], v[2:5]
	s_nop 1
	v_lshl_add_u64 v[2:3], v[6:7], 4, v[22:23]
	flat_load_dwordx4 v[2:5], v[2:3]
	s_waitcnt vmcnt(0) lgkmcnt(0)
	ds_write_b128 v17, v[2:5]
.LBB3_42:                               ; %_ZN7commkit7kernels22vmemload_cal_vmemstoreIDF16bLi8ELi8EEEvPT_ii.exit
                                        ;   in Loop: Header=BB3_36 Depth=1
	s_or_b64 exec, exec, s[0:1]
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_saveexec_b64 s[0:1], s[6:7]
	s_xor_b64 s[0:1], exec, s[0:1]
	s_cbranch_execz .LBB3_44
; %bb.43:                               ;   in Loop: Header=BB3_36 Depth=1
	ds_read_b128 v[2:5], v35 offset:8192
	v_add_u32_e32 v6, s59, v28
	v_add_u32_e32 v8, s19, v28
	v_ashrrev_i32_e32 v7, 31, v6
	v_lshl_add_u64 v[6:7], v[6:7], 4, v[24:25]
	v_ashrrev_i32_e32 v9, 31, v8
	s_waitcnt lgkmcnt(0)
	flat_store_dwordx4 v[6:7], v[2:5]
	s_nop 1
	v_lshl_add_u64 v[2:3], v[8:9], 4, v[26:27]
	flat_load_dwordx4 v[2:5], v[2:3]
	s_waitcnt vmcnt(0) lgkmcnt(0)
	ds_write_b128 v35, v[2:5] offset:8192
.LBB3_44:                               ; %Flow327
                                        ;   in Loop: Header=BB3_36 Depth=1
	s_andn2_saveexec_b64 s[0:1], s[0:1]
	s_cbranch_execz .LBB3_35
; %bb.45:                               ;   in Loop: Header=BB3_36 Depth=1
	s_and_saveexec_b64 s[16:17], s[10:11]
	s_cbranch_execz .LBB3_34
; %bb.46:                               ; %.preheader5.i201
                                        ;   in Loop: Header=BB3_36 Depth=1
	ds_read_b128 v[2:5], v19
	ds_read_b128 v[6:9], v19 offset:1024
	s_waitcnt lgkmcnt(0)
	v_and_b32_e32 v51, 0xffff0000, v2
	v_lshlrev_b32_e32 v50, 16, v2
	v_and_b32_e32 v59, 0xffff0000, v6
	v_lshlrev_b32_e32 v58, 16, v6
	v_and_b32_e32 v53, 0xffff0000, v3
	v_lshlrev_b32_e32 v52, 16, v3
	v_and_b32_e32 v55, 0xffff0000, v4
	v_lshlrev_b32_e32 v54, 16, v4
	v_and_b32_e32 v57, 0xffff0000, v5
	v_lshlrev_b32_e32 v56, 16, v5
	v_and_b32_e32 v61, 0xffff0000, v7
	v_lshlrev_b32_e32 v60, 16, v7
	v_and_b32_e32 v63, 0xffff0000, v8
	v_lshlrev_b32_e32 v62, 16, v8
	v_and_b32_e32 v65, 0xffff0000, v9
	v_lshlrev_b32_e32 v64, 16, v9
	ds_read_b128 v[38:41], v19 offset:2048
	ds_read_b128 v[42:45], v19 offset:3072
	ds_read_b128 v[46:49], v19 offset:4096
	ds_read_b128 v[10:13], v19 offset:5120
	ds_read_b128 v[6:9], v19 offset:6144
	ds_read_b128 v[2:5], v19 offset:7168
	v_pk_add_f32 v[50:51], v[50:51], v[58:59]
	s_waitcnt lgkmcnt(0)
	v_and_b32_e32 v59, 0xffff0000, v38
	v_lshlrev_b32_e32 v58, 16, v38
	v_pk_add_f32 v[50:51], v[50:51], v[58:59]
	v_and_b32_e32 v59, 0xffff0000, v42
	v_lshlrev_b32_e32 v58, 16, v42
	v_pk_add_f32 v[50:51], v[50:51], v[58:59]
	v_and_b32_e32 v59, 0xffff0000, v46
	v_lshlrev_b32_e32 v58, 16, v46
	v_pk_add_f32 v[50:51], v[50:51], v[58:59]
	v_and_b32_e32 v59, 0xffff0000, v10
	v_lshlrev_b32_e32 v58, 16, v10
	v_pk_add_f32 v[50:51], v[50:51], v[58:59]
	v_and_b32_e32 v59, 0xffff0000, v6
	v_lshlrev_b32_e32 v58, 16, v6
	v_pk_add_f32 v[50:51], v[50:51], v[58:59]
	v_and_b32_e32 v59, 0xffff0000, v2
	v_lshlrev_b32_e32 v58, 16, v2
	v_pk_add_f32 v[50:51], v[50:51], v[58:59]
	v_pk_add_f32 v[52:53], v[52:53], v[60:61]
	v_and_b32_e32 v59, 0xffff0000, v39
	v_lshlrev_b32_e32 v58, 16, v39
	v_pk_add_f32 v[38:39], v[52:53], v[58:59]
	v_and_b32_e32 v53, 0xffff0000, v43
	v_lshlrev_b32_e32 v52, 16, v43
	v_pk_add_f32 v[38:39], v[38:39], v[52:53]
	v_and_b32_e32 v43, 0xffff0000, v47
	v_lshlrev_b32_e32 v42, 16, v47
	v_pk_add_f32 v[38:39], v[38:39], v[42:43]
	v_and_b32_e32 v43, 0xffff0000, v11
	v_lshlrev_b32_e32 v42, 16, v11
	v_pk_add_f32 v[10:11], v[38:39], v[42:43]
	v_and_b32_e32 v39, 0xffff0000, v7
	v_lshlrev_b32_e32 v38, 16, v7
	v_pk_add_f32 v[6:7], v[10:11], v[38:39]
	v_and_b32_e32 v11, 0xffff0000, v3
	v_lshlrev_b32_e32 v10, 16, v3
	v_pk_add_f32 v[2:3], v[6:7], v[10:11]
	v_pk_add_f32 v[6:7], v[54:55], v[62:63]
	v_and_b32_e32 v11, 0xffff0000, v40
	v_lshlrev_b32_e32 v10, 16, v40
	v_pk_add_f32 v[6:7], v[6:7], v[10:11]
	v_and_b32_e32 v11, 0xffff0000, v44
	v_lshlrev_b32_e32 v10, 16, v44
	v_pk_add_f32 v[6:7], v[6:7], v[10:11]
	v_and_b32_e32 v11, 0xffff0000, v48
	v_lshlrev_b32_e32 v10, 16, v48
	v_pk_add_f32 v[6:7], v[6:7], v[10:11]
	v_and_b32_e32 v11, 0xffff0000, v12
	v_lshlrev_b32_e32 v10, 16, v12
	v_pk_add_f32 v[6:7], v[6:7], v[10:11]
	v_and_b32_e32 v11, 0xffff0000, v8
	v_lshlrev_b32_e32 v10, 16, v8
	v_pk_add_f32 v[6:7], v[6:7], v[10:11]
	v_and_b32_e32 v11, 0xffff0000, v4
	v_lshlrev_b32_e32 v10, 16, v4
	v_pk_add_f32 v[6:7], v[6:7], v[10:11]
	v_pk_add_f32 v[10:11], v[56:57], v[64:65]
	v_and_b32_e32 v39, 0xffff0000, v41
	v_lshlrev_b32_e32 v38, 16, v41
	v_pk_add_f32 v[10:11], v[10:11], v[38:39]
	v_and_b32_e32 v39, 0xffff0000, v45
	v_lshlrev_b32_e32 v38, 16, v45
	v_pk_add_f32 v[10:11], v[10:11], v[38:39]
	v_and_b32_e32 v39, 0xffff0000, v49
	v_lshlrev_b32_e32 v38, 16, v49
	v_pk_add_f32 v[10:11], v[10:11], v[38:39]
	v_and_b32_e32 v39, 0xffff0000, v13
	v_lshlrev_b32_e32 v38, 16, v13
	v_pk_add_f32 v[10:11], v[10:11], v[38:39]
	v_and_b32_e32 v13, 0xffff0000, v9
	v_lshlrev_b32_e32 v12, 16, v9
	v_pk_add_f32 v[8:9], v[10:11], v[12:13]
	v_and_b32_e32 v11, 0xffff0000, v5
	v_lshlrev_b32_e32 v10, 16, v5
	v_pk_add_f32 v[4:5], v[8:9], v[10:11]
	v_perm_b32 v3, v3, v2, s20
	v_perm_b32 v5, v5, v4, s20
	v_perm_b32 v4, v7, v6, s20
	v_perm_b32 v2, v51, v50, s20
	ds_write_b128 v19, v[2:5]
	ds_write_b128 v19, v[2:5] offset:1024
	ds_write_b128 v19, v[2:5] offset:2048
	ds_write_b128 v19, v[2:5] offset:3072
	ds_write_b128 v19, v[2:5] offset:4096
	ds_write_b128 v19, v[2:5] offset:5120
	ds_write_b128 v19, v[2:5] offset:6144
	ds_write_b128 v19, v[2:5] offset:7168
	s_branch .LBB3_34
.LBB3_47:                               ; %Flow331
	s_or_b64 exec, exec, s[56:57]
	v_and_b32_e32 v2, 1, v30
	v_cmp_eq_u32_e64 s[0:1], 1, v2
	s_and_saveexec_b64 s[8:9], s[0:1]
	s_xor_b64 s[22:23], exec, s[8:9]
	s_cbranch_execz .LBB3_63
; %bb.48:
	s_and_saveexec_b64 s[0:1], s[6:7]
	s_xor_b64 s[8:9], exec, s[0:1]
	s_cbranch_execz .LBB3_52
; %bb.49:
	v_cmp_eq_u32_e64 s[0:1], 8, v31
	s_and_saveexec_b64 s[10:11], s[0:1]
	s_cbranch_execz .LBB3_51
; %bb.50:                               ; %.preheader5.i221
	ds_read_b128 v[2:5], v19 offset:8192
	ds_read_b128 v[6:9], v19 offset:9216
	s_mov_b32 s0, 0x7060302
	s_waitcnt lgkmcnt(0)
	v_and_b32_e32 v29, 0xffff0000, v2
	v_lshlrev_b32_e32 v28, 16, v2
	v_and_b32_e32 v47, 0xffff0000, v6
	v_lshlrev_b32_e32 v46, 16, v6
	v_and_b32_e32 v41, 0xffff0000, v3
	v_lshlrev_b32_e32 v40, 16, v3
	v_and_b32_e32 v43, 0xffff0000, v4
	v_lshlrev_b32_e32 v42, 16, v4
	v_and_b32_e32 v45, 0xffff0000, v5
	v_lshlrev_b32_e32 v44, 16, v5
	v_and_b32_e32 v49, 0xffff0000, v7
	v_lshlrev_b32_e32 v48, 16, v7
	v_and_b32_e32 v51, 0xffff0000, v8
	v_lshlrev_b32_e32 v50, 16, v8
	v_and_b32_e32 v53, 0xffff0000, v9
	v_lshlrev_b32_e32 v52, 16, v9
	ds_read_b128 v[20:23], v19 offset:10240
	ds_read_b128 v[24:27], v19 offset:11264
	ds_read_b128 v[36:39], v19 offset:12288
	ds_read_b128 v[10:13], v19 offset:13312
	ds_read_b128 v[6:9], v19 offset:14336
	ds_read_b128 v[2:5], v19 offset:15360
	v_pk_add_f32 v[28:29], v[28:29], v[46:47]
	s_waitcnt lgkmcnt(0)
	v_and_b32_e32 v47, 0xffff0000, v20
	v_lshlrev_b32_e32 v46, 16, v20
	v_pk_add_f32 v[28:29], v[28:29], v[46:47]
	v_and_b32_e32 v47, 0xffff0000, v24
	v_lshlrev_b32_e32 v46, 16, v24
	v_pk_add_f32 v[28:29], v[28:29], v[46:47]
	v_and_b32_e32 v47, 0xffff0000, v36
	v_lshlrev_b32_e32 v46, 16, v36
	v_pk_add_f32 v[28:29], v[28:29], v[46:47]
	v_and_b32_e32 v47, 0xffff0000, v10
	v_lshlrev_b32_e32 v46, 16, v10
	v_pk_add_f32 v[28:29], v[28:29], v[46:47]
	v_and_b32_e32 v47, 0xffff0000, v6
	v_lshlrev_b32_e32 v46, 16, v6
	v_pk_add_f32 v[28:29], v[28:29], v[46:47]
	v_and_b32_e32 v47, 0xffff0000, v2
	v_lshlrev_b32_e32 v46, 16, v2
	v_pk_add_f32 v[28:29], v[28:29], v[46:47]
	v_pk_add_f32 v[40:41], v[40:41], v[48:49]
	v_and_b32_e32 v47, 0xffff0000, v21
	v_lshlrev_b32_e32 v46, 16, v21
	v_pk_add_f32 v[20:21], v[40:41], v[46:47]
	v_and_b32_e32 v41, 0xffff0000, v25
	v_lshlrev_b32_e32 v40, 16, v25
	v_pk_add_f32 v[20:21], v[20:21], v[40:41]
	v_and_b32_e32 v25, 0xffff0000, v37
	v_lshlrev_b32_e32 v24, 16, v37
	v_pk_add_f32 v[20:21], v[20:21], v[24:25]
	v_and_b32_e32 v25, 0xffff0000, v11
	v_lshlrev_b32_e32 v24, 16, v11
	v_pk_add_f32 v[10:11], v[20:21], v[24:25]
	v_and_b32_e32 v21, 0xffff0000, v7
	v_lshlrev_b32_e32 v20, 16, v7
	v_pk_add_f32 v[6:7], v[10:11], v[20:21]
	v_and_b32_e32 v11, 0xffff0000, v3
	v_lshlrev_b32_e32 v10, 16, v3
	v_pk_add_f32 v[2:3], v[6:7], v[10:11]
	v_pk_add_f32 v[6:7], v[42:43], v[50:51]
	v_and_b32_e32 v11, 0xffff0000, v22
	v_lshlrev_b32_e32 v10, 16, v22
	v_pk_add_f32 v[6:7], v[6:7], v[10:11]
	v_and_b32_e32 v11, 0xffff0000, v26
	v_lshlrev_b32_e32 v10, 16, v26
	v_pk_add_f32 v[6:7], v[6:7], v[10:11]
	v_and_b32_e32 v11, 0xffff0000, v38
	v_lshlrev_b32_e32 v10, 16, v38
	v_pk_add_f32 v[6:7], v[6:7], v[10:11]
	v_and_b32_e32 v11, 0xffff0000, v12
	v_lshlrev_b32_e32 v10, 16, v12
	v_pk_add_f32 v[6:7], v[6:7], v[10:11]
	v_and_b32_e32 v11, 0xffff0000, v8
	v_lshlrev_b32_e32 v10, 16, v8
	v_pk_add_f32 v[6:7], v[6:7], v[10:11]
	v_and_b32_e32 v11, 0xffff0000, v4
	v_lshlrev_b32_e32 v10, 16, v4
	v_pk_add_f32 v[6:7], v[6:7], v[10:11]
	v_pk_add_f32 v[10:11], v[44:45], v[52:53]
	v_and_b32_e32 v21, 0xffff0000, v23
	v_lshlrev_b32_e32 v20, 16, v23
	v_pk_add_f32 v[10:11], v[10:11], v[20:21]
	v_and_b32_e32 v21, 0xffff0000, v27
	v_lshlrev_b32_e32 v20, 16, v27
	v_pk_add_f32 v[10:11], v[10:11], v[20:21]
	v_and_b32_e32 v21, 0xffff0000, v39
	v_lshlrev_b32_e32 v20, 16, v39
	v_pk_add_f32 v[10:11], v[10:11], v[20:21]
	v_and_b32_e32 v21, 0xffff0000, v13
	v_lshlrev_b32_e32 v20, 16, v13
	v_pk_add_f32 v[10:11], v[10:11], v[20:21]
	v_and_b32_e32 v13, 0xffff0000, v9
	v_lshlrev_b32_e32 v12, 16, v9
	v_pk_add_f32 v[8:9], v[10:11], v[12:13]
	v_and_b32_e32 v11, 0xffff0000, v5
	v_lshlrev_b32_e32 v10, 16, v5
	v_pk_add_f32 v[4:5], v[8:9], v[10:11]
	v_perm_b32 v3, v3, v2, s0
	v_perm_b32 v5, v5, v4, s0
	v_perm_b32 v4, v7, v6, s0
	v_perm_b32 v2, v29, v28, s0
	ds_write_b128 v19, v[2:5] offset:8192
	ds_write_b128 v19, v[2:5] offset:9216
	ds_write_b128 v19, v[2:5] offset:10240
	ds_write_b128 v19, v[2:5] offset:11264
	ds_write_b128 v19, v[2:5] offset:12288
	ds_write_b128 v19, v[2:5] offset:13312
	ds_write_b128 v19, v[2:5] offset:14336
	ds_write_b128 v19, v[2:5] offset:15360
.LBB3_51:                               ; %Flow318
	s_or_b64 exec, exec, s[10:11]
.LBB3_52:                               ; %Flow319
	s_andn2_saveexec_b64 s[56:57], s[8:9]
	s_cbranch_execz .LBB3_54
; %bb.53:
	v_mov_b32_e32 v6, s31
	v_mov_b32_e32 v7, s74
	v_cmp_eq_u32_e64 s[0:1], 1, v31
	v_cmp_eq_u32_e64 s[8:9], 2, v31
	v_cmp_eq_u32_e64 s[10:11], 3, v31
	v_cndmask_b32_e64 v6, v6, v7, s[0:1]
	v_mov_b32_e32 v7, s73
	v_cndmask_b32_e64 v6, v6, v7, s[8:9]
	v_mov_b32_e32 v7, s72
	v_cndmask_b32_e64 v6, v6, v7, s[10:11]
	v_mov_b32_e32 v7, s71
	v_cmp_eq_u32_e64 s[14:15], 4, v31
	v_cmp_eq_u32_e64 s[16:17], 5, v31
	v_cmp_eq_u32_e64 s[18:19], 6, v31
	v_cndmask_b32_e64 v6, v6, v7, s[14:15]
	v_mov_b32_e32 v7, s70
	v_cndmask_b32_e64 v6, v6, v7, s[16:17]
	v_mov_b32_e32 v7, s69
	v_cndmask_b32_e64 v6, v6, v7, s[18:19]
	v_mov_b32_e32 v7, s68
	v_cmp_eq_u32_e64 s[20:21], 7, v31
	v_mov_b32_e32 v8, s25
	v_lshl_add_u32 v10, v34, 4, v19
	v_cndmask_b32_e64 v7, v6, v7, s[20:21]
	v_mov_b32_e32 v6, s30
	v_cndmask_b32_e64 v6, v6, v8, s[0:1]
	v_mov_b32_e32 v8, s62
	v_cndmask_b32_e64 v6, v6, v8, s[8:9]
	v_mov_b32_e32 v8, s63
	v_cndmask_b32_e64 v6, v6, v8, s[10:11]
	v_mov_b32_e32 v8, s64
	v_cndmask_b32_e64 v6, v6, v8, s[14:15]
	v_mov_b32_e32 v8, s65
	v_cndmask_b32_e64 v6, v6, v8, s[16:17]
	v_mov_b32_e32 v8, s66
	ds_read_b128 v[2:5], v10
	v_cndmask_b32_e64 v6, v6, v8, s[18:19]
	v_mov_b32_e32 v8, s67
	v_cndmask_b32_e64 v6, v6, v8, s[20:21]
	v_mul_lo_u32 v8, s33, v1
	v_lshl_add_u32 v8, v8, 7, v16
	v_ashrrev_i32_e32 v9, 31, v8
	v_lshl_add_u64 v[6:7], v[8:9], 4, v[6:7]
	s_waitcnt lgkmcnt(0)
	flat_store_dwordx4 v[6:7], v[2:5]
	s_nop 1
	v_mov_b32_e32 v2, s39
	v_mov_b32_e32 v3, s41
	v_cndmask_b32_e64 v2, v2, v3, s[0:1]
	v_mov_b32_e32 v3, s43
	v_cndmask_b32_e64 v2, v2, v3, s[8:9]
	v_mov_b32_e32 v3, s45
	v_cndmask_b32_e64 v2, v2, v3, s[10:11]
	v_mov_b32_e32 v3, s49
	v_cndmask_b32_e64 v2, v2, v3, s[14:15]
	v_mov_b32_e32 v3, s51
	v_cndmask_b32_e64 v2, v2, v3, s[16:17]
	v_mov_b32_e32 v3, s53
	v_cndmask_b32_e64 v2, v2, v3, s[18:19]
	v_mov_b32_e32 v3, s55
	v_cndmask_b32_e64 v3, v2, v3, s[20:21]
	v_mov_b32_e32 v2, s38
	v_mov_b32_e32 v4, s40
	v_cndmask_b32_e64 v2, v2, v4, s[0:1]
	v_mov_b32_e32 v4, s42
	v_cndmask_b32_e64 v2, v2, v4, s[8:9]
	v_mov_b32_e32 v4, s44
	v_cndmask_b32_e64 v2, v2, v4, s[10:11]
	v_mov_b32_e32 v4, s48
	v_cndmask_b32_e64 v2, v2, v4, s[14:15]
	v_mov_b32_e32 v4, s50
	v_cndmask_b32_e64 v2, v2, v4, s[16:17]
	v_mov_b32_e32 v4, s52
	v_cndmask_b32_e64 v2, v2, v4, s[18:19]
	v_mov_b32_e32 v4, s54
	v_cndmask_b32_e64 v2, v2, v4, s[20:21]
	v_and_b32_e32 v4, 0x7ffffffe, v30
	v_mad_u64_u32 v[4:5], s[0:1], v4, s59, v[16:17]
	v_ashrrev_i32_e32 v5, 31, v4
	v_lshl_add_u64 v[2:3], v[4:5], 4, v[2:3]
	flat_load_dwordx4 v[2:5], v[2:3]
	s_waitcnt vmcnt(0) lgkmcnt(0)
	ds_write_b128 v10, v[2:5]
.LBB3_54:                               ; %_ZN7commkit7kernels22vmemload_cal_vmemstoreIDF16bLi8ELi8EEEvPT_ii.exit229
	s_or_b64 exec, exec, s[56:57]
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_saveexec_b64 s[0:1], s[6:7]
	s_xor_b64 s[38:39], exec, s[0:1]
	s_cbranch_execz .LBB3_56
; %bb.55:
	v_add_u32_e32 v0, -8, v31
	v_mov_b32_e32 v6, s31
	v_mov_b32_e32 v7, s74
	v_cmp_eq_u32_e64 s[0:1], 1, v0
	v_cmp_eq_u32_e64 s[8:9], 2, v0
	v_cmp_eq_u32_e64 s[10:11], 3, v0
	v_cndmask_b32_e64 v6, v6, v7, s[0:1]
	v_mov_b32_e32 v7, s73
	v_cndmask_b32_e64 v6, v6, v7, s[8:9]
	v_mov_b32_e32 v7, s72
	v_cndmask_b32_e64 v6, v6, v7, s[10:11]
	v_mov_b32_e32 v7, s71
	v_cmp_eq_u32_e64 s[14:15], 4, v0
	v_cmp_eq_u32_e64 s[16:17], 5, v0
	v_cmp_eq_u32_e64 s[18:19], 6, v0
	v_cndmask_b32_e64 v6, v6, v7, s[14:15]
	v_mov_b32_e32 v7, s70
	v_cndmask_b32_e64 v6, v6, v7, s[16:17]
	v_mov_b32_e32 v7, s69
	v_cndmask_b32_e64 v6, v6, v7, s[18:19]
	v_mov_b32_e32 v7, s68
	v_cmp_eq_u32_e64 s[20:21], 7, v0
	v_lshl_or_b32 v2, v0, 10, v19
	v_mov_b32_e32 v0, s30
	v_cndmask_b32_e64 v7, v6, v7, s[20:21]
	v_mov_b32_e32 v6, s25
	v_cndmask_b32_e64 v0, v0, v6, s[0:1]
	v_mov_b32_e32 v6, s62
	v_cndmask_b32_e64 v0, v0, v6, s[8:9]
	v_mov_b32_e32 v6, s63
	v_cndmask_b32_e64 v0, v0, v6, s[10:11]
	v_mov_b32_e32 v6, s64
	v_cndmask_b32_e64 v0, v0, v6, s[14:15]
	v_mov_b32_e32 v6, s65
	v_cndmask_b32_e64 v0, v0, v6, s[16:17]
	v_mov_b32_e32 v6, s66
	ds_read_b128 v[2:5], v2 offset:8192
	v_cndmask_b32_e64 v0, v0, v6, s[18:19]
	v_mov_b32_e32 v6, s67
	v_cndmask_b32_e64 v6, v0, v6, s[20:21]
	v_lshl_or_b32 v0, v1, 1, 1
	v_mad_u64_u32 v[0:1], s[0:1], v0, s59, v[16:17]
	v_ashrrev_i32_e32 v1, 31, v0
	v_lshl_add_u64 v[0:1], v[0:1], 4, v[6:7]
	s_waitcnt lgkmcnt(0)
	flat_store_dwordx4 v[0:1], v[2:5]
                                        ; implicit-def: $vgpr0
.LBB3_56:                               ; %Flow317
	s_andn2_saveexec_b64 s[8:9], s[38:39]
	s_cbranch_execz .LBB3_60
; %bb.57:
	v_cmp_gt_u32_e64 s[0:1], 64, v0
	s_and_saveexec_b64 s[10:11], s[0:1]
	s_cbranch_execz .LBB3_59
; %bb.58:                               ; %.preheader5.i231
	ds_read_b128 v[0:3], v19
	ds_read_b128 v[4:7], v19 offset:1024
	s_mov_b32 s0, 0x7060302
	s_waitcnt lgkmcnt(0)
	v_and_b32_e32 v13, 0xffff0000, v0
	v_lshlrev_b32_e32 v12, 16, v0
	v_and_b32_e32 v45, 0xffff0000, v4
	v_lshlrev_b32_e32 v44, 16, v4
	v_and_b32_e32 v29, 0xffff0000, v1
	v_lshlrev_b32_e32 v28, 16, v1
	v_and_b32_e32 v41, 0xffff0000, v2
	v_lshlrev_b32_e32 v40, 16, v2
	v_and_b32_e32 v43, 0xffff0000, v3
	v_lshlrev_b32_e32 v42, 16, v3
	v_and_b32_e32 v47, 0xffff0000, v5
	v_lshlrev_b32_e32 v46, 16, v5
	v_and_b32_e32 v49, 0xffff0000, v6
	v_lshlrev_b32_e32 v48, 16, v6
	v_and_b32_e32 v51, 0xffff0000, v7
	v_lshlrev_b32_e32 v50, 16, v7
	ds_read_b128 v[20:23], v19 offset:2048
	ds_read_b128 v[24:27], v19 offset:3072
	ds_read_b128 v[36:39], v19 offset:4096
	ds_read_b128 v[8:11], v19 offset:5120
	ds_read_b128 v[4:7], v19 offset:6144
	ds_read_b128 v[0:3], v19 offset:7168
	v_pk_add_f32 v[12:13], v[12:13], v[44:45]
	s_waitcnt lgkmcnt(0)
	v_and_b32_e32 v45, 0xffff0000, v20
	v_lshlrev_b32_e32 v44, 16, v20
	v_pk_add_f32 v[12:13], v[12:13], v[44:45]
	v_and_b32_e32 v45, 0xffff0000, v24
	v_lshlrev_b32_e32 v44, 16, v24
	v_pk_add_f32 v[12:13], v[12:13], v[44:45]
	v_and_b32_e32 v45, 0xffff0000, v36
	v_lshlrev_b32_e32 v44, 16, v36
	v_pk_add_f32 v[12:13], v[12:13], v[44:45]
	v_and_b32_e32 v45, 0xffff0000, v8
	v_lshlrev_b32_e32 v44, 16, v8
	v_pk_add_f32 v[12:13], v[12:13], v[44:45]
	v_and_b32_e32 v45, 0xffff0000, v4
	v_lshlrev_b32_e32 v44, 16, v4
	v_pk_add_f32 v[12:13], v[12:13], v[44:45]
	v_and_b32_e32 v45, 0xffff0000, v0
	v_lshlrev_b32_e32 v44, 16, v0
	v_pk_add_f32 v[12:13], v[12:13], v[44:45]
	v_pk_add_f32 v[28:29], v[28:29], v[46:47]
	v_and_b32_e32 v45, 0xffff0000, v21
	v_lshlrev_b32_e32 v44, 16, v21
	v_pk_add_f32 v[20:21], v[28:29], v[44:45]
	v_and_b32_e32 v29, 0xffff0000, v25
	v_lshlrev_b32_e32 v28, 16, v25
	v_pk_add_f32 v[20:21], v[20:21], v[28:29]
	v_and_b32_e32 v25, 0xffff0000, v37
	v_lshlrev_b32_e32 v24, 16, v37
	v_pk_add_f32 v[20:21], v[20:21], v[24:25]
	v_and_b32_e32 v25, 0xffff0000, v9
	v_lshlrev_b32_e32 v24, 16, v9
	v_pk_add_f32 v[8:9], v[20:21], v[24:25]
	v_and_b32_e32 v21, 0xffff0000, v5
	v_lshlrev_b32_e32 v20, 16, v5
	v_pk_add_f32 v[4:5], v[8:9], v[20:21]
	v_and_b32_e32 v9, 0xffff0000, v1
	v_lshlrev_b32_e32 v8, 16, v1
	v_pk_add_f32 v[0:1], v[4:5], v[8:9]
	v_pk_add_f32 v[4:5], v[40:41], v[48:49]
	v_and_b32_e32 v9, 0xffff0000, v22
	v_lshlrev_b32_e32 v8, 16, v22
	v_pk_add_f32 v[4:5], v[4:5], v[8:9]
	v_and_b32_e32 v9, 0xffff0000, v26
	v_lshlrev_b32_e32 v8, 16, v26
	v_pk_add_f32 v[4:5], v[4:5], v[8:9]
	v_and_b32_e32 v9, 0xffff0000, v38
	v_lshlrev_b32_e32 v8, 16, v38
	v_pk_add_f32 v[4:5], v[4:5], v[8:9]
	v_and_b32_e32 v9, 0xffff0000, v10
	v_lshlrev_b32_e32 v8, 16, v10
	v_pk_add_f32 v[4:5], v[4:5], v[8:9]
	v_and_b32_e32 v9, 0xffff0000, v6
	v_lshlrev_b32_e32 v8, 16, v6
	v_pk_add_f32 v[4:5], v[4:5], v[8:9]
	v_and_b32_e32 v9, 0xffff0000, v2
	v_lshlrev_b32_e32 v8, 16, v2
	v_pk_add_f32 v[4:5], v[4:5], v[8:9]
	v_pk_add_f32 v[8:9], v[42:43], v[50:51]
	v_and_b32_e32 v21, 0xffff0000, v23
	v_lshlrev_b32_e32 v20, 16, v23
	v_pk_add_f32 v[8:9], v[8:9], v[20:21]
	v_and_b32_e32 v21, 0xffff0000, v27
	v_lshlrev_b32_e32 v20, 16, v27
	v_pk_add_f32 v[8:9], v[8:9], v[20:21]
	v_and_b32_e32 v21, 0xffff0000, v39
	v_lshlrev_b32_e32 v20, 16, v39
	v_pk_add_f32 v[8:9], v[8:9], v[20:21]
	v_and_b32_e32 v21, 0xffff0000, v11
	v_lshlrev_b32_e32 v20, 16, v11
	v_pk_add_f32 v[8:9], v[8:9], v[20:21]
	v_and_b32_e32 v11, 0xffff0000, v7
	v_lshlrev_b32_e32 v10, 16, v7
	v_pk_add_f32 v[6:7], v[8:9], v[10:11]
	v_and_b32_e32 v9, 0xffff0000, v3
	v_lshlrev_b32_e32 v8, 16, v3
	v_pk_add_f32 v[2:3], v[6:7], v[8:9]
	v_perm_b32 v1, v1, v0, s0
	v_perm_b32 v3, v3, v2, s0
	v_perm_b32 v2, v5, v4, s0
	v_perm_b32 v0, v13, v12, s0
	ds_write_b128 v19, v[0:3]
	ds_write_b128 v19, v[0:3] offset:1024
	ds_write_b128 v19, v[0:3] offset:2048
	ds_write_b128 v19, v[0:3] offset:3072
	ds_write_b128 v19, v[0:3] offset:4096
	ds_write_b128 v19, v[0:3] offset:5120
	ds_write_b128 v19, v[0:3] offset:6144
	ds_write_b128 v19, v[0:3] offset:7168
.LBB3_59:                               ; %Flow316
	s_or_b64 exec, exec, s[10:11]
.LBB3_60:                               ; %_ZN7commkit7kernels22vmemload_cal_vmemstoreIDF16bLi8ELi0EEEvPT_ii.exit239
	s_or_b64 exec, exec, s[8:9]
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_saveexec_b64 s[38:39], vcc
	s_cbranch_execz .LBB3_62
; %bb.61:
	v_mov_b32_e32 v4, s31
	v_mov_b32_e32 v5, s74
	v_cmp_eq_u32_e64 s[0:1], 1, v31
	v_cmp_eq_u32_e64 s[8:9], 2, v31
	v_cmp_eq_u32_e64 s[10:11], 3, v31
	v_cndmask_b32_e64 v4, v4, v5, s[0:1]
	v_mov_b32_e32 v5, s73
	v_cndmask_b32_e64 v4, v4, v5, s[8:9]
	v_mov_b32_e32 v5, s72
	v_cndmask_b32_e64 v4, v4, v5, s[10:11]
	v_mov_b32_e32 v5, s71
	v_cmp_eq_u32_e64 s[14:15], 4, v31
	v_cmp_eq_u32_e64 s[16:17], 5, v31
	v_cmp_eq_u32_e64 s[18:19], 6, v31
	v_cndmask_b32_e64 v4, v4, v5, s[14:15]
	v_mov_b32_e32 v5, s70
	v_cndmask_b32_e64 v4, v4, v5, s[16:17]
	v_mov_b32_e32 v5, s69
	v_cndmask_b32_e64 v4, v4, v5, s[18:19]
	v_mov_b32_e32 v5, s68
	v_cmp_eq_u32_e64 s[20:21], 7, v31
	v_mov_b32_e32 v6, s25
	v_lshl_add_u32 v0, v34, 4, v19
	v_cndmask_b32_e64 v5, v4, v5, s[20:21]
	v_mov_b32_e32 v4, s30
	v_cndmask_b32_e64 v4, v4, v6, s[0:1]
	v_mov_b32_e32 v6, s62
	v_cndmask_b32_e64 v4, v4, v6, s[8:9]
	v_mov_b32_e32 v6, s63
	v_cndmask_b32_e64 v4, v4, v6, s[10:11]
	v_mov_b32_e32 v6, s64
	v_cndmask_b32_e64 v4, v4, v6, s[14:15]
	v_mov_b32_e32 v6, s65
	v_cndmask_b32_e64 v4, v4, v6, s[16:17]
	v_mov_b32_e32 v6, s66
	ds_read_b128 v[0:3], v0
	v_cndmask_b32_e64 v4, v4, v6, s[18:19]
	v_mov_b32_e32 v6, s67
	v_cndmask_b32_e64 v4, v4, v6, s[20:21]
	v_and_b32_e32 v6, 0x7ffffffe, v30
	v_mad_u64_u32 v[6:7], s[0:1], v6, s59, v[16:17]
	v_ashrrev_i32_e32 v7, 31, v6
	v_lshl_add_u64 v[4:5], v[6:7], 4, v[4:5]
	s_waitcnt lgkmcnt(0)
	flat_store_dwordx4 v[4:5], v[0:3]
.LBB3_62:                               ; %Flow315
	s_or_b64 exec, exec, s[38:39]
                                        ; implicit-def: $vgpr0
                                        ; implicit-def: $vgpr19
                                        ; implicit-def: $vgpr1
                                        ; implicit-def: $vgpr16
                                        ; implicit-def: $vgpr34
.LBB3_63:                               ; %Flow324
	s_andn2_saveexec_b64 s[20:21], s[22:23]
	s_cbranch_execz .LBB3_73
; %bb.64:
	s_and_saveexec_b64 s[0:1], s[6:7]
	s_xor_b64 s[6:7], exec, s[0:1]
	s_cbranch_execz .LBB3_68
; %bb.65:
	v_cmp_eq_u32_e64 s[0:1], 8, v31
	s_and_saveexec_b64 s[8:9], s[0:1]
	s_cbranch_execz .LBB3_67
; %bb.66:                               ; %.preheader5.i211
	ds_read_b128 v[2:5], v19 offset:8192
	ds_read_b128 v[6:9], v19 offset:9216
	s_mov_b32 s0, 0x7060302
	s_waitcnt lgkmcnt(0)
	v_and_b32_e32 v29, 0xffff0000, v2
	v_lshlrev_b32_e32 v28, 16, v2
	v_and_b32_e32 v45, 0xffff0000, v6
	v_lshlrev_b32_e32 v44, 16, v6
	v_and_b32_e32 v39, 0xffff0000, v3
	v_lshlrev_b32_e32 v38, 16, v3
	v_and_b32_e32 v41, 0xffff0000, v4
	v_lshlrev_b32_e32 v40, 16, v4
	v_and_b32_e32 v43, 0xffff0000, v5
	v_lshlrev_b32_e32 v42, 16, v5
	v_and_b32_e32 v47, 0xffff0000, v7
	v_lshlrev_b32_e32 v46, 16, v7
	v_and_b32_e32 v49, 0xffff0000, v8
	v_lshlrev_b32_e32 v48, 16, v8
	v_and_b32_e32 v51, 0xffff0000, v9
	v_lshlrev_b32_e32 v50, 16, v9
	ds_read_b128 v[20:23], v19 offset:10240
	ds_read_b128 v[24:27], v19 offset:11264
	ds_read_b128 v[34:37], v19 offset:12288
	ds_read_b128 v[10:13], v19 offset:13312
	ds_read_b128 v[6:9], v19 offset:14336
	ds_read_b128 v[2:5], v19 offset:15360
	v_pk_add_f32 v[28:29], v[28:29], v[44:45]
	s_waitcnt lgkmcnt(0)
	v_and_b32_e32 v45, 0xffff0000, v20
	v_lshlrev_b32_e32 v44, 16, v20
	v_pk_add_f32 v[28:29], v[28:29], v[44:45]
	v_and_b32_e32 v45, 0xffff0000, v24
	v_lshlrev_b32_e32 v44, 16, v24
	v_pk_add_f32 v[28:29], v[28:29], v[44:45]
	v_and_b32_e32 v45, 0xffff0000, v34
	v_lshlrev_b32_e32 v44, 16, v34
	v_pk_add_f32 v[28:29], v[28:29], v[44:45]
	v_and_b32_e32 v45, 0xffff0000, v10
	v_lshlrev_b32_e32 v44, 16, v10
	v_pk_add_f32 v[28:29], v[28:29], v[44:45]
	v_and_b32_e32 v45, 0xffff0000, v6
	v_lshlrev_b32_e32 v44, 16, v6
	v_pk_add_f32 v[28:29], v[28:29], v[44:45]
	v_and_b32_e32 v45, 0xffff0000, v2
	v_lshlrev_b32_e32 v44, 16, v2
	v_pk_add_f32 v[28:29], v[28:29], v[44:45]
	v_pk_add_f32 v[38:39], v[38:39], v[46:47]
	v_and_b32_e32 v45, 0xffff0000, v21
	v_lshlrev_b32_e32 v44, 16, v21
	v_pk_add_f32 v[20:21], v[38:39], v[44:45]
	v_and_b32_e32 v39, 0xffff0000, v25
	v_lshlrev_b32_e32 v38, 16, v25
	v_pk_add_f32 v[20:21], v[20:21], v[38:39]
	v_and_b32_e32 v25, 0xffff0000, v35
	v_lshlrev_b32_e32 v24, 16, v35
	v_pk_add_f32 v[20:21], v[20:21], v[24:25]
	v_and_b32_e32 v25, 0xffff0000, v11
	v_lshlrev_b32_e32 v24, 16, v11
	v_pk_add_f32 v[10:11], v[20:21], v[24:25]
	v_and_b32_e32 v21, 0xffff0000, v7
	v_lshlrev_b32_e32 v20, 16, v7
	v_pk_add_f32 v[6:7], v[10:11], v[20:21]
	v_and_b32_e32 v11, 0xffff0000, v3
	v_lshlrev_b32_e32 v10, 16, v3
	v_pk_add_f32 v[2:3], v[6:7], v[10:11]
	v_pk_add_f32 v[6:7], v[40:41], v[48:49]
	v_and_b32_e32 v11, 0xffff0000, v22
	v_lshlrev_b32_e32 v10, 16, v22
	v_pk_add_f32 v[6:7], v[6:7], v[10:11]
	v_and_b32_e32 v11, 0xffff0000, v26
	v_lshlrev_b32_e32 v10, 16, v26
	v_pk_add_f32 v[6:7], v[6:7], v[10:11]
	v_and_b32_e32 v11, 0xffff0000, v36
	v_lshlrev_b32_e32 v10, 16, v36
	v_pk_add_f32 v[6:7], v[6:7], v[10:11]
	v_and_b32_e32 v11, 0xffff0000, v12
	v_lshlrev_b32_e32 v10, 16, v12
	v_pk_add_f32 v[6:7], v[6:7], v[10:11]
	v_and_b32_e32 v11, 0xffff0000, v8
	v_lshlrev_b32_e32 v10, 16, v8
	v_pk_add_f32 v[6:7], v[6:7], v[10:11]
	v_and_b32_e32 v11, 0xffff0000, v4
	v_lshlrev_b32_e32 v10, 16, v4
	v_pk_add_f32 v[6:7], v[6:7], v[10:11]
	v_pk_add_f32 v[10:11], v[42:43], v[50:51]
	v_and_b32_e32 v21, 0xffff0000, v23
	v_lshlrev_b32_e32 v20, 16, v23
	v_pk_add_f32 v[10:11], v[10:11], v[20:21]
	v_and_b32_e32 v21, 0xffff0000, v27
	v_lshlrev_b32_e32 v20, 16, v27
	v_pk_add_f32 v[10:11], v[10:11], v[20:21]
	v_and_b32_e32 v21, 0xffff0000, v37
	v_lshlrev_b32_e32 v20, 16, v37
	v_pk_add_f32 v[10:11], v[10:11], v[20:21]
	v_and_b32_e32 v21, 0xffff0000, v13
	v_lshlrev_b32_e32 v20, 16, v13
	v_pk_add_f32 v[10:11], v[10:11], v[20:21]
	v_and_b32_e32 v13, 0xffff0000, v9
	v_lshlrev_b32_e32 v12, 16, v9
	v_pk_add_f32 v[8:9], v[10:11], v[12:13]
	v_and_b32_e32 v11, 0xffff0000, v5
	v_lshlrev_b32_e32 v10, 16, v5
	v_pk_add_f32 v[4:5], v[8:9], v[10:11]
	v_perm_b32 v3, v3, v2, s0
	v_perm_b32 v5, v5, v4, s0
	v_perm_b32 v4, v7, v6, s0
	v_perm_b32 v2, v29, v28, s0
	ds_write_b128 v19, v[2:5] offset:8192
	ds_write_b128 v19, v[2:5] offset:9216
	ds_write_b128 v19, v[2:5] offset:10240
	ds_write_b128 v19, v[2:5] offset:11264
	ds_write_b128 v19, v[2:5] offset:12288
	ds_write_b128 v19, v[2:5] offset:13312
	ds_write_b128 v19, v[2:5] offset:14336
	ds_write_b128 v19, v[2:5] offset:15360
.LBB3_67:                               ; %Flow321
	s_or_b64 exec, exec, s[8:9]
                                        ; implicit-def: $vgpr34
.LBB3_68:                               ; %Flow322
	s_andn2_saveexec_b64 s[22:23], s[6:7]
	s_cbranch_execz .LBB3_70
; %bb.69:
	v_mov_b32_e32 v6, s31
	v_mov_b32_e32 v7, s74
	v_cmp_eq_u32_e64 s[0:1], 1, v31
	v_cmp_eq_u32_e64 s[6:7], 2, v31
	v_cmp_eq_u32_e64 s[8:9], 3, v31
	v_cndmask_b32_e64 v6, v6, v7, s[0:1]
	v_mov_b32_e32 v7, s73
	v_cndmask_b32_e64 v6, v6, v7, s[6:7]
	v_mov_b32_e32 v7, s72
	v_cndmask_b32_e64 v6, v6, v7, s[8:9]
	v_mov_b32_e32 v7, s71
	v_cmp_eq_u32_e64 s[10:11], 4, v31
	v_cmp_eq_u32_e64 s[14:15], 5, v31
	v_cmp_eq_u32_e64 s[16:17], 6, v31
	v_cndmask_b32_e64 v6, v6, v7, s[10:11]
	v_mov_b32_e32 v7, s70
	v_cndmask_b32_e64 v6, v6, v7, s[14:15]
	v_mov_b32_e32 v7, s69
	v_cndmask_b32_e64 v6, v6, v7, s[16:17]
	v_mov_b32_e32 v7, s68
	v_cmp_eq_u32_e64 s[18:19], 7, v31
	v_mov_b32_e32 v8, s25
	v_lshl_add_u32 v2, v34, 4, v19
	v_cndmask_b32_e64 v7, v6, v7, s[18:19]
	v_mov_b32_e32 v6, s30
	v_cndmask_b32_e64 v6, v6, v8, s[0:1]
	v_mov_b32_e32 v8, s62
	v_cndmask_b32_e64 v6, v6, v8, s[6:7]
	v_mov_b32_e32 v8, s63
	v_cndmask_b32_e64 v6, v6, v8, s[8:9]
	v_mov_b32_e32 v8, s64
	v_cndmask_b32_e64 v6, v6, v8, s[10:11]
	v_mov_b32_e32 v8, s65
	v_cndmask_b32_e64 v6, v6, v8, s[14:15]
	v_mov_b32_e32 v8, s66
	ds_read_b128 v[2:5], v2
	v_cndmask_b32_e64 v6, v6, v8, s[16:17]
	v_mov_b32_e32 v8, s67
	v_cndmask_b32_e64 v6, v6, v8, s[18:19]
	v_mul_lo_u32 v8, s33, v1
	v_lshl_add_u32 v8, v8, 7, v16
	v_ashrrev_i32_e32 v9, 31, v8
	v_lshl_add_u64 v[6:7], v[8:9], 4, v[6:7]
	s_waitcnt lgkmcnt(0)
	flat_store_dwordx4 v[6:7], v[2:5]
.LBB3_70:                               ; %_ZN7commkit7kernels22vmemload_cal_vmemstoreIDF16bLi8ELi8EEEvPT_ii.exit219
	s_or_b64 exec, exec, s[22:23]
	s_movk_i32 s0, 0x1ff
	v_cmp_lt_u32_e64 s[0:1], s0, v0
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_saveexec_b64 s[22:23], s[0:1]
	s_cbranch_execz .LBB3_72
; %bb.71:
	v_add_u32_e32 v0, -8, v31
	v_mov_b32_e32 v6, s31
	v_mov_b32_e32 v7, s74
	v_cmp_eq_u32_e64 s[0:1], 1, v0
	v_cmp_eq_u32_e64 s[6:7], 2, v0
	v_cmp_eq_u32_e64 s[8:9], 3, v0
	v_cndmask_b32_e64 v6, v6, v7, s[0:1]
	v_mov_b32_e32 v7, s73
	v_cndmask_b32_e64 v6, v6, v7, s[6:7]
	v_mov_b32_e32 v7, s72
	v_cndmask_b32_e64 v6, v6, v7, s[8:9]
	v_mov_b32_e32 v7, s71
	v_cmp_eq_u32_e64 s[10:11], 4, v0
	v_cmp_eq_u32_e64 s[14:15], 5, v0
	v_cmp_eq_u32_e64 s[16:17], 6, v0
	v_cndmask_b32_e64 v6, v6, v7, s[10:11]
	v_mov_b32_e32 v7, s70
	v_cndmask_b32_e64 v6, v6, v7, s[14:15]
	v_mov_b32_e32 v7, s69
	v_cndmask_b32_e64 v6, v6, v7, s[16:17]
	v_mov_b32_e32 v7, s68
	v_cmp_eq_u32_e64 s[18:19], 7, v0
	v_lshl_or_b32 v2, v0, 10, v19
	v_mov_b32_e32 v0, s30
	v_cndmask_b32_e64 v7, v6, v7, s[18:19]
	v_mov_b32_e32 v6, s25
	v_cndmask_b32_e64 v0, v0, v6, s[0:1]
	v_mov_b32_e32 v6, s62
	v_cndmask_b32_e64 v0, v0, v6, s[6:7]
	v_mov_b32_e32 v6, s63
	v_cndmask_b32_e64 v0, v0, v6, s[8:9]
	v_mov_b32_e32 v6, s64
	v_cndmask_b32_e64 v0, v0, v6, s[10:11]
	v_mov_b32_e32 v6, s65
	v_cndmask_b32_e64 v0, v0, v6, s[14:15]
	v_mov_b32_e32 v6, s66
	ds_read_b128 v[2:5], v2 offset:8192
	v_cndmask_b32_e64 v0, v0, v6, s[16:17]
	v_mov_b32_e32 v6, s67
	v_cndmask_b32_e64 v6, v0, v6, s[18:19]
	v_lshl_or_b32 v0, v1, 1, 1
	v_mad_u64_u32 v[0:1], s[0:1], v0, s59, v[16:17]
	v_ashrrev_i32_e32 v1, 31, v0
	v_lshl_add_u64 v[0:1], v[0:1], 4, v[6:7]
	s_waitcnt lgkmcnt(0)
	flat_store_dwordx4 v[0:1], v[2:5]
.LBB3_72:                               ; %Flow320
	s_or_b64 exec, exec, s[22:23]
.LBB3_73:                               ; %Flow325
	s_or_b64 exec, exec, s[20:21]
.LBB3_74:                               ; %Flow336
	s_or_b64 exec, exec, s[46:47]
	v_mov_b32_e32 v19, 0
	s_waitcnt lgkmcnt(0)
	s_barrier
	global_load_dword v0, v19, s[34:35]
	s_waitcnt vmcnt(0)
	v_add_u32_e32 v2, 1, v0
	s_and_saveexec_b64 s[6:7], s[12:13]
	s_cbranch_execz .LBB3_77
; %bb.75:
	global_load_dwordx2 v[0:1], v32, s[26:27]
	s_mov_b32 s25, s58
	s_lshl_b64 s[0:1], s[2:3], 5
	s_lshl_b64 s[8:9], s[24:25], 2
	s_add_u32 s8, s8, s0
	s_addc_u32 s9, s9, s1
	s_add_u32 s0, s36, s0
	s_mov_b64 s[2:3], 0xa00
	s_addc_u32 s1, s37, s1
	s_add_u32 s0, s0, 0xa00
	s_addc_u32 s1, s1, 0
	s_waitcnt vmcnt(0)
	v_lshl_add_u64 v[0:1], v[0:1], 0, s[8:9]
	v_lshl_add_u64 v[4:5], v[0:1], 0, s[2:3]
	;;#ASMSTART
	buffer_wbl2 sc0 sc1
	global_store_dword v[4:5], v2, off sc0 sc1
	
	;;#ASMEND
	v_lshl_add_u64 v[0:1], s[0:1], 0, v[18:19]
	s_mov_b64 s[2:3], 0
.LBB3_76:                               ; =>This Inner Loop Header: Depth=1
	;;#ASMSTART
	global_load_dword v3, v[0:1], off sc1
	s_waitcnt vmcnt(0)
	
	;;#ASMEND
	s_nop 0
	v_cmp_ge_u32_e64 s[0:1], v3, v2
	s_or_b64 s[2:3], s[0:1], s[2:3]
	s_andn2_b64 exec, exec, s[2:3]
	s_cbranch_execnz .LBB3_76
.LBB3_77:                               ; %Flow313
	s_or_b64 exec, exec, s[6:7]
	s_barrier
	s_and_saveexec_b64 s[0:1], s[4:5]
	s_cbranch_execz .LBB3_79
; %bb.78:
	v_mov_b32_e32 v0, 0
	global_store_dword v0, v2, s[34:35]
.LBB3_79:                               ; %_ZN7commkit12end_sync_asmILi8ELb1ELb0EEEvRKNS_11RankSignalsEPNS_6SignalEi.exit
	s_or_b64 exec, exec, s[0:1]
	v_cmp_lt_u32_e64 s[0:1], 1, v30
	s_and_saveexec_b64 s[2:3], s[0:1]
	s_cbranch_execz .LBB3_84
; %bb.80:                               ; %.lr.ph264
	v_add_u32_e32 v0, -8, v31
	v_mul_lo_u32 v2, s60, v0
	v_mad_u64_u32 v[0:1], s[0:1], s60, v31, v[14:15]
	s_add_i32 s0, s59, s61
	s_lshl_b32 s6, s33, 7
	v_add3_u32 v1, s0, v2, v15
	s_mov_b32 s7, 0
	s_mov_b64 s[4:5], 0
	s_branch .LBB3_82
.LBB3_81:                               ;   in Loop: Header=BB3_82 Depth=1
	s_or_b64 exec, exec, s[0:1]
	v_ashrrev_i32_e32 v3, 31, v2
	v_lshlrev_b64 v[6:7], 4, v[2:3]
	v_lshl_add_u64 v[2:3], s[30:31], 0, v[6:7]
	global_load_dwordx4 v[2:5], v[2:3], off
	v_add_u32_e32 v33, -1, v33
	s_add_i32 s7, s7, 1
	v_cmp_eq_u32_e64 s[0:1], 0, v33
	v_lshl_add_u64 v[6:7], s[28:29], 0, v[6:7]
	s_or_b64 s[4:5], s[0:1], s[4:5]
	v_add_u32_e32 v1, s6, v1
	s_waitcnt vmcnt(0)
	global_store_dwordx4 v[6:7], v[2:5], off
	s_andn2_b64 exec, exec, s[4:5]
	s_cbranch_execz .LBB3_84
.LBB3_82:                               ; =>This Inner Loop Header: Depth=1
	v_mov_b32_e32 v2, v1
	s_and_saveexec_b64 s[0:1], vcc
	s_cbranch_execz .LBB3_81
; %bb.83:                               ;   in Loop: Header=BB3_82 Depth=1
	s_mul_i32 s8, s6, s7
	v_add_u32_e32 v2, s8, v0
	s_branch .LBB3_81
.LBB3_84:                               ; %Flow311
	s_or_b64 exec, exec, s[2:3]
	v_and_b32_e32 v0, 1, v30
	v_cmp_eq_u32_e64 s[0:1], 0, v0
	s_and_b64 s[0:1], s[0:1], vcc
	s_and_saveexec_b64 s[2:3], s[0:1]
	s_cbranch_execz .LBB3_86
; %bb.85:
	v_add_u32_e32 v1, -1, v30
	v_mul_lo_u32 v0, s60, v31
	v_mul_lo_u32 v1, v1, s59
	v_add3_u32 v0, v0, v14, v1
	v_ashrrev_i32_e32 v1, 31, v0
	v_lshlrev_b64 v[4:5], 4, v[0:1]
	v_lshl_add_u64 v[0:1], s[30:31], 0, v[4:5]
	global_load_dwordx4 v[0:3], v[0:1], off
	v_lshl_add_u64 v[4:5], s[28:29], 0, v[4:5]
	s_waitcnt vmcnt(0)
	global_store_dwordx4 v[4:5], v[0:3], off
.LBB3_86:
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel _ZN7commkit7kernels23allreduce_double_bufferIDF16bEEvPNS_8RankDataENS_11RankSignalsEPNS_6SignalEPT_ii
		.amdhsa_group_segment_fixed_size 16384
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
		.amdhsa_next_free_vgpr 66
		.amdhsa_next_free_sgpr 75
		.amdhsa_accum_offset 68
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
	.section	.text._ZN7commkit7kernels23allreduce_double_bufferIDF16bEEvPNS_8RankDataENS_11RankSignalsEPNS_6SignalEPT_ii,"axG",@progbits,_ZN7commkit7kernels23allreduce_double_bufferIDF16bEEvPNS_8RankDataENS_11RankSignalsEPNS_6SignalEPT_ii,comdat
.Lfunc_end3:
	.size	_ZN7commkit7kernels23allreduce_double_bufferIDF16bEEvPNS_8RankDataENS_11RankSignalsEPNS_6SignalEPT_ii, .Lfunc_end3-_ZN7commkit7kernels23allreduce_double_bufferIDF16bEEvPNS_8RankDataENS_11RankSignalsEPNS_6SignalEPT_ii
                                        ; -- End function
	.set _ZN7commkit7kernels23allreduce_double_bufferIDF16bEEvPNS_8RankDataENS_11RankSignalsEPNS_6SignalEPT_ii.num_vgpr, 66
	.set _ZN7commkit7kernels23allreduce_double_bufferIDF16bEEvPNS_8RankDataENS_11RankSignalsEPNS_6SignalEPT_ii.num_agpr, 0
	.set _ZN7commkit7kernels23allreduce_double_bufferIDF16bEEvPNS_8RankDataENS_11RankSignalsEPNS_6SignalEPT_ii.numbered_sgpr, 75
	.set _ZN7commkit7kernels23allreduce_double_bufferIDF16bEEvPNS_8RankDataENS_11RankSignalsEPNS_6SignalEPT_ii.private_seg_size, 0
	.set _ZN7commkit7kernels23allreduce_double_bufferIDF16bEEvPNS_8RankDataENS_11RankSignalsEPNS_6SignalEPT_ii.uses_vcc, 1
	.set _ZN7commkit7kernels23allreduce_double_bufferIDF16bEEvPNS_8RankDataENS_11RankSignalsEPNS_6SignalEPT_ii.uses_flat_scratch, 0
	.set _ZN7commkit7kernels23allreduce_double_bufferIDF16bEEvPNS_8RankDataENS_11RankSignalsEPNS_6SignalEPT_ii.has_dyn_sized_stack, 0
	.set _ZN7commkit7kernels23allreduce_double_bufferIDF16bEEvPNS_8RankDataENS_11RankSignalsEPNS_6SignalEPT_ii.has_recursion, 0
	.set _ZN7commkit7kernels23allreduce_double_bufferIDF16bEEvPNS_8RankDataENS_11RankSignalsEPNS_6SignalEPT_ii.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 11664
; TotalNumSgprs: 81
; NumVgprs: 66
; NumAgprs: 0
; TotalNumVgprs: 66
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 16384 bytes/workgroup (compile time only)
; SGPRBlocks: 10
; VGPRBlocks: 8
; NumSGPRsForWavesPerEU: 81
; NumVGPRsForWavesPerEU: 66
; AccumOffset: 68
; Occupancy: 7
; WaveLimiterHint : 1
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 2
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 0
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 0
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 0
; COMPUTE_PGM_RSRC3_GFX90A:ACCUM_OFFSET: 16
; COMPUTE_PGM_RSRC3_GFX90A:TG_SPLIT: 0
	.section	.text._ZN7commkit7kernels16ar_naive_overlapIDF16bEEvPNS_8RankDataES3_NS_11RankSignalsEPNS_6SignalEPT_ii,"axG",@progbits,_ZN7commkit7kernels16ar_naive_overlapIDF16bEEvPNS_8RankDataES3_NS_11RankSignalsEPNS_6SignalEPT_ii,comdat
	.protected	_ZN7commkit7kernels16ar_naive_overlapIDF16bEEvPNS_8RankDataES3_NS_11RankSignalsEPNS_6SignalEPT_ii ; -- Begin function _ZN7commkit7kernels16ar_naive_overlapIDF16bEEvPNS_8RankDataES3_NS_11RankSignalsEPNS_6SignalEPT_ii
	.globl	_ZN7commkit7kernels16ar_naive_overlapIDF16bEEvPNS_8RankDataES3_NS_11RankSignalsEPNS_6SignalEPT_ii
	.p2align	8
	.type	_ZN7commkit7kernels16ar_naive_overlapIDF16bEEvPNS_8RankDataES3_NS_11RankSignalsEPNS_6SignalEPT_ii,@function
_ZN7commkit7kernels16ar_naive_overlapIDF16bEEvPNS_8RankDataES3_NS_11RankSignalsEPNS_6SignalEPT_ii: ; @_ZN7commkit7kernels16ar_naive_overlapIDF16bEEvPNS_8RankDataES3_NS_11RankSignalsEPNS_6SignalEPT_ii
; %bb.0:
	s_load_dwordx2 s[18:19], s[0:1], 0x60
	s_load_dwordx4 s[20:23], s[0:1], 0x50
	s_load_dwordx2 s[4:5], s[0:1], 0x0
	s_add_u32 s34, s0, 16
	s_addc_u32 s35, s1, 0
	s_waitcnt lgkmcnt(0)
	s_ashr_i32 s31, s18, 31
	s_load_dword s8, s[0:1], 0x68
	s_lshr_b32 s0, s31, 29
	s_add_i32 s0, s18, s0
	s_and_b32 s0, s0, -8
	s_sub_i32 s0, s18, s0
	s_ashr_i32 s1, s0, 31
	s_lshl_b64 s[0:1], s[0:1], 3
	s_add_u32 s6, s4, s0
	s_addc_u32 s7, s5, s1
	s_add_u32 s0, s34, s0
	s_addc_u32 s1, s35, s1
	s_load_dwordx2 s[24:25], s[0:1], 0x0
	s_add_i32 s0, s18, 1
	s_ashr_i32 s1, s0, 31
	s_lshr_b32 s1, s1, 29
	s_add_i32 s1, s0, s1
	s_and_b32 s1, s1, -8
	s_sub_i32 s0, s0, s1
	s_ashr_i32 s1, s0, 31
	s_lshl_b64 s[0:1], s[0:1], 3
	s_load_dwordx2 s[48:49], s[6:7], 0x0
	s_add_u32 s6, s4, s0
	s_addc_u32 s7, s5, s1
	s_add_u32 s0, s34, s0
	s_addc_u32 s1, s35, s1
	s_load_dwordx2 s[26:27], s[0:1], 0x0
	s_add_i32 s0, s18, 2
	s_ashr_i32 s1, s0, 31
	s_lshr_b32 s1, s1, 29
	s_add_i32 s1, s0, s1
	s_and_b32 s1, s1, -8
	s_sub_i32 s0, s0, s1
	s_ashr_i32 s1, s0, 31
	s_lshl_b64 s[0:1], s[0:1], 3
	s_load_dwordx2 s[50:51], s[6:7], 0x0
	s_add_u32 s6, s4, s0
	s_addc_u32 s7, s5, s1
	s_add_u32 s0, s34, s0
	s_addc_u32 s1, s35, s1
	s_load_dwordx2 s[28:29], s[0:1], 0x0
	s_add_i32 s0, s18, 3
	s_ashr_i32 s1, s0, 31
	s_lshr_b32 s1, s1, 29
	s_add_i32 s1, s0, s1
	s_and_b32 s1, s1, -8
	s_sub_i32 s0, s0, s1
	s_ashr_i32 s1, s0, 31
	s_lshl_b64 s[0:1], s[0:1], 3
	s_load_dwordx2 s[54:55], s[6:7], 0x0
	s_add_u32 s6, s4, s0
	s_addc_u32 s7, s5, s1
	s_add_u32 s0, s34, s0
	s_addc_u32 s1, s35, s1
	s_load_dwordx2 s[36:37], s[0:1], 0x0
	s_add_i32 s0, s18, 4
	s_ashr_i32 s1, s0, 31
	s_lshr_b32 s1, s1, 29
	s_add_i32 s1, s0, s1
	s_and_b32 s1, s1, -8
	s_sub_i32 s0, s0, s1
	s_ashr_i32 s1, s0, 31
	s_lshl_b64 s[0:1], s[0:1], 3
	s_load_dwordx2 s[56:57], s[6:7], 0x0
	s_add_u32 s6, s4, s0
	s_addc_u32 s7, s5, s1
	s_add_u32 s0, s34, s0
	s_addc_u32 s1, s35, s1
	s_load_dwordx2 s[38:39], s[0:1], 0x0
	s_add_i32 s0, s18, 5
	s_ashr_i32 s1, s0, 31
	s_lshr_b32 s1, s1, 29
	s_add_i32 s1, s0, s1
	s_and_b32 s1, s1, -8
	s_sub_i32 s0, s0, s1
	s_ashr_i32 s1, s0, 31
	s_lshl_b64 s[0:1], s[0:1], 3
	s_load_dwordx2 s[58:59], s[6:7], 0x0
	s_add_u32 s6, s4, s0
	s_addc_u32 s7, s5, s1
	s_add_u32 s0, s34, s0
	s_addc_u32 s1, s35, s1
	s_load_dwordx2 s[40:41], s[0:1], 0x0
	s_add_i32 s0, s18, 6
	s_ashr_i32 s1, s0, 31
	s_lshr_b32 s1, s1, 29
	s_add_i32 s1, s0, s1
	s_and_b32 s1, s1, -8
	s_sub_i32 s0, s0, s1
	s_ashr_i32 s1, s0, 31
	s_lshl_b64 s[0:1], s[0:1], 3
	s_load_dwordx2 s[60:61], s[6:7], 0x0
	s_add_u32 s6, s4, s0
	s_addc_u32 s7, s5, s1
	s_add_u32 s0, s34, s0
	s_addc_u32 s1, s35, s1
	s_load_dwordx2 s[42:43], s[0:1], 0x0
	s_add_i32 s0, s18, 7
	s_ashr_i32 s1, s0, 31
	s_lshr_b32 s1, s1, 29
	s_add_i32 s1, s0, s1
	s_and_b32 s1, s1, -8
	s_sub_i32 s0, s0, s1
	s_ashr_i32 s1, s0, 31
	s_lshl_b64 s[0:1], s[0:1], 3
	s_add_u32 s4, s4, s0
	s_addc_u32 s5, s5, s1
	s_add_u32 s0, s34, s0
	s_mov_b32 s3, 0
	s_load_dwordx2 s[62:63], s[6:7], 0x0
	s_addc_u32 s1, s35, s1
	s_lshl_b64 s[6:7], s[2:3], 2
	s_add_u32 s6, s20, s6
	s_addc_u32 s7, s21, s7
	s_load_dword s9, s[6:7], 0x1400
	s_load_dwordx2 s[64:65], s[4:5], 0x0
                                        ; kill: killed $sgpr4 killed $sgpr5
	s_load_dwordx2 s[46:47], s[0:1], 0x0
	s_add_u32 s52, s6, 0x1400
	s_addc_u32 s53, s7, 0
	s_waitcnt lgkmcnt(0)
	s_add_i32 s9, s9, 1
	v_cmp_gt_u32_e32 vcc, 8, v0
	v_lshlrev_b32_e32 v1, 3, v0
	v_lshlrev_b32_e32 v2, 2, v0
	s_and_saveexec_b64 s[4:5], vcc
	s_cbranch_execz .LBB4_3
; %bb.1:
	global_load_dwordx2 v[6:7], v1, s[34:35]
	s_mov_b32 s30, s18
	s_lshl_b64 s[0:1], s[2:3], 5
	s_lshl_b64 s[6:7], s[30:31], 2
	s_add_u32 s6, s6, s0
	s_addc_u32 s7, s7, s1
	s_add_u32 s0, s20, s0
	v_mov_b32_e32 v3, 0
	s_addc_u32 s1, s21, s1
	v_mov_b32_e32 v8, s9
	v_lshl_add_u64 v[4:5], s[0:1], 0, v[2:3]
	s_waitcnt vmcnt(0)
	v_lshl_add_u64 v[6:7], s[6:7], 0, v[6:7]
	s_mov_b64 s[6:7], 0
	global_store_dword v[6:7], v8, off sc0 sc1
.LBB4_2:                                ; =>This Inner Loop Header: Depth=1
	global_load_dword v3, v[4:5], off sc1
	s_waitcnt vmcnt(0)
	v_cmp_le_u32_e64 s[0:1], s9, v3
	s_or_b64 s[6:7], s[0:1], s[6:7]
	s_andn2_b64 exec, exec, s[6:7]
	s_cbranch_execnz .LBB4_2
.LBB4_3:                                ; %Flow222
	s_or_b64 exec, exec, s[4:5]
	v_cmp_eq_u32_e64 s[0:1], 0, v0
	s_barrier
	s_and_saveexec_b64 s[4:5], s[0:1]
	s_cbranch_execz .LBB4_5
; %bb.4:
	v_mov_b32_e32 v3, 0
	v_mov_b32_e32 v4, s9
	global_store_dword v3, v4, s[52:53]
.LBB4_5:                                ; %_ZN7commkit10start_syncILi8EEEvRKNS_11RankSignalsEPNS_6SignalEi.exit
	s_or_b64 exec, exec, s[4:5]
	s_ashr_i32 s4, s19, 31
	s_lshr_b32 s4, s4, 29
	s_add_i32 s4, s19, s4
	s_ashr_i32 s33, s4, 3
	s_mul_i32 s4, s33, s18
	v_and_b32_e32 v9, 63, v0
	s_lshl_b32 s45, s2, 6
	s_lshl_b32 s44, s8, 6
	s_add_i32 s5, s4, s33
	v_or_b32_e32 v8, s45, v9
	s_cmp_eq_u32 s18, 7
	s_cselect_b32 s14, s19, s5
	v_add_u32_e32 v4, s4, v8
	v_cmp_gt_i32_e64 s[4:5], s14, v4
	v_mov_b32_e32 v3, 0
	s_and_saveexec_b64 s[8:9], s[4:5]
	s_cbranch_execz .LBB4_17
; %bb.6:                                ; %.lr.ph.preheader
	v_cvt_f32_u32_e32 v3, s44
	v_add_u32_e32 v6, s44, v4
	v_mov_b32_e32 v7, s44
	s_sub_i32 s11, 0, s44
	v_rcp_iflag_f32_e32 v3, v3
	v_cmp_gt_i32_e64 s[4:5], s14, v6
	v_max_i32_e32 v5, s14, v6
	s_mov_b32 s10, 0
	v_mul_f32_e32 v3, 0x4f7ffffe, v3
	v_cvt_u32_f32_e32 v3, v3
	v_addc_co_u32_e64 v6, s[6:7], v4, v7, s[4:5]
	v_sub_u32_e32 v6, v5, v6
	v_mul_lo_u32 v7, s11, v3
	v_mul_hi_u32 v7, v3, v7
	v_add_u32_e32 v3, v3, v7
	v_mul_hi_u32 v3, v6, v3
	v_mul_lo_u32 v7, v3, s44
	v_sub_u32_e32 v6, v6, v7
	v_add_u32_e32 v7, 1, v3
	v_cmp_le_u32_e64 s[6:7], s44, v6
	s_mov_b64 s[12:13], -1
	s_nop 0
	v_cndmask_b32_e64 v3, v3, v7, s[6:7]
	v_subrev_u32_e32 v7, s44, v6
	v_cndmask_b32_e64 v6, v6, v7, s[6:7]
	v_add_u32_e32 v7, 1, v3
	v_cmp_le_u32_e64 s[6:7], s44, v6
	v_mov_b32_e32 v6, v4
	s_nop 0
	v_cndmask_b32_e64 v3, v3, v7, s[6:7]
	v_addc_co_u32_e64 v10, s[4:5], 1, v3, s[4:5]
	v_cmp_lt_u32_e64 s[4:5], 1, v10
	v_mov_b32_e32 v7, 0
                                        ; implicit-def: $vgpr3
	s_and_saveexec_b64 s[6:7], s[4:5]
	s_cbranch_execz .LBB4_12
; %bb.7:                                ; %vector.ph
	v_and_b32_e32 v11, -2, v10
	s_mov_b64 s[12:13], 0
	v_mov_b32_e32 v3, v11
	s_mov_b32 s11, s10
.LBB4_8:                                ; %vector.body
                                        ; =>This Inner Loop Header: Depth=1
	v_add_u32_e32 v3, -2, v3
	s_add_i32 s11, s11, 1
	s_add_i32 s10, s10, 1
	v_cmp_eq_u32_e64 s[4:5], 0, v3
	s_or_b64 s[12:13], s[4:5], s[12:13]
	v_mov_b64_e32 v[6:7], s[10:11]
	s_andn2_b64 exec, exec, s[12:13]
	s_cbranch_execnz .LBB4_8
; %bb.9:                                ; %middle.block
	s_or_b64 exec, exec, s[12:13]
	v_add_u32_e32 v3, v6, v7
	v_cmp_ne_u32_e64 s[4:5], v10, v11
	s_mov_b64 s[10:11], 0
	v_mov_b32_e32 v7, 0
                                        ; implicit-def: $vgpr6
                                        ; implicit-def: $vgpr5
	s_and_saveexec_b64 s[12:13], s[4:5]
; %bb.10:                               ; %middle.block..lr.ph.preheader185_crit_edge
	v_mad_u64_u32 v[6:7], s[4:5], v11, s44, v[4:5]
	v_add_u32_e32 v5, s44, v6
	s_mov_b64 s[10:11], exec
	v_max_i32_e32 v5, s14, v5
	v_mov_b32_e32 v7, v3
; %bb.11:                               ; %Flow219
	s_or_b64 exec, exec, s[12:13]
	s_orn2_b64 s[12:13], s[10:11], exec
.LBB4_12:                               ; %Flow218
	s_or_b64 exec, exec, s[6:7]
	s_and_saveexec_b64 s[6:7], s[12:13]
	s_cbranch_execz .LBB4_16
; %bb.13:                               ; %.lr.ph.preheader185
	s_max_u32 s10, s44, 1
	v_cvt_f32_u32_e32 v3, s10
	v_sub_u32_e32 v5, v5, v6
	v_subrev_u32_e32 v10, s44, v5
	s_sub_i32 s4, 0, s10
	v_rcp_iflag_f32_e32 v3, v3
	v_min_u32_e32 v10, 1, v10
	v_add_u32_e32 v7, v7, v10
	v_sub_u32_e32 v5, v5, v10
	v_mul_f32_e32 v3, 0x4f7ffffe, v3
	v_cvt_u32_f32_e32 v3, v3
	v_subrev_u32_e32 v5, s44, v5
	v_mul_lo_u32 v10, s4, v3
	v_mul_hi_u32 v10, v3, v10
	v_add_u32_e32 v3, v3, v10
	v_mul_hi_u32 v3, v5, v3
	v_mul_lo_u32 v10, v3, s10
	v_sub_u32_e32 v5, v5, v10
	v_add_u32_e32 v11, 1, v3
	v_subrev_u32_e32 v10, s10, v5
	v_cmp_le_u32_e64 s[4:5], s10, v5
	s_nop 1
	v_cndmask_b32_e64 v5, v5, v10, s[4:5]
	v_cndmask_b32_e64 v3, v3, v11, s[4:5]
	v_add_u32_e32 v10, 1, v3
	v_cmp_le_u32_e64 s[4:5], s10, v5
	s_mov_b64 s[10:11], 0
	s_nop 0
	v_cndmask_b32_e64 v3, v3, v10, s[4:5]
	v_add3_u32 v3, v7, v3, 1
.LBB4_14:                               ; %.lr.ph
                                        ; =>This Inner Loop Header: Depth=1
	v_add_u32_e32 v6, s44, v6
	v_cmp_le_i32_e64 s[4:5], s14, v6
	s_or_b64 s[10:11], s[4:5], s[10:11]
	s_andn2_b64 exec, exec, s[10:11]
	s_cbranch_execnz .LBB4_14
; %bb.15:                               ; %Flow217
	s_or_b64 exec, exec, s[10:11]
.LBB4_16:                               ; %Flow220
	s_or_b64 exec, exec, s[6:7]
.LBB4_17:                               ; %._crit_edge
	s_or_b64 exec, exec, s[8:9]
	v_lshrrev_b32_e32 v6, 6, v0
	v_mov_b32_e32 v5, s49
	v_mov_b32_e32 v7, s51
	v_cmp_eq_u32_e64 s[4:5], 1, v6
	v_cmp_eq_u32_e64 s[6:7], 2, v6
	v_cmp_eq_u32_e64 s[8:9], 3, v6
	v_cndmask_b32_e64 v5, v5, v7, s[4:5]
	v_mov_b32_e32 v7, s55
	v_cndmask_b32_e64 v5, v5, v7, s[6:7]
	v_mov_b32_e32 v7, s57
	v_cndmask_b32_e64 v5, v5, v7, s[8:9]
	v_mov_b32_e32 v7, s59
	v_cmp_eq_u32_e64 s[10:11], 4, v6
	v_cmp_eq_u32_e64 s[12:13], 5, v6
	v_cmp_eq_u32_e64 s[14:15], 6, v6
	v_cndmask_b32_e64 v5, v5, v7, s[10:11]
	v_mov_b32_e32 v7, s61
	v_cndmask_b32_e64 v5, v5, v7, s[12:13]
	v_mov_b32_e32 v7, s63
	v_cndmask_b32_e64 v5, v5, v7, s[14:15]
	v_mov_b32_e32 v7, s65
	v_cmp_eq_u32_e64 s[16:17], 7, v6
	v_lshlrev_b32_e32 v0, 4, v0
	s_nop 0
	v_cndmask_b32_e64 v11, v5, v7, s[16:17]
	v_mov_b32_e32 v5, s48
	v_mov_b32_e32 v7, s50
	v_cndmask_b32_e64 v5, v5, v7, s[4:5]
	v_mov_b32_e32 v7, s54
	v_cndmask_b32_e64 v5, v5, v7, s[6:7]
	v_mov_b32_e32 v7, s56
	v_cndmask_b32_e64 v5, v5, v7, s[8:9]
	v_mov_b32_e32 v7, s58
	v_cndmask_b32_e64 v5, v5, v7, s[10:11]
	v_mov_b32_e32 v7, s60
	v_cndmask_b32_e64 v5, v5, v7, s[12:13]
	v_mov_b32_e32 v7, s62
	v_cndmask_b32_e64 v5, v5, v7, s[14:15]
	v_mov_b32_e32 v7, s64
	v_cndmask_b32_e64 v10, v5, v7, s[16:17]
	v_ashrrev_i32_e32 v5, 31, v4
	v_lshl_add_u64 v[4:5], v[4:5], 4, v[10:11]
	flat_load_dwordx4 v[10:13], v[4:5]
	v_cmp_ne_u32_e64 s[4:5], 0, v3
	s_waitcnt vmcnt(0) lgkmcnt(0)
	ds_write_b128 v0, v[10:13]
	s_waitcnt lgkmcnt(0)
	s_barrier
	s_and_saveexec_b64 s[6:7], s[4:5]
	s_cbranch_execz .LBB4_20
; %bb.18:                               ; %.lr.ph162.preheader
	s_movk_i32 s12, 0x1000
	s_mov_b64 s[8:9], 0
	s_mov_b32 s10, s44
.LBB4_19:                               ; %.lr.ph162
                                        ; =>This Inner Loop Header: Depth=1
	s_ashr_i32 s11, s10, 31
	s_and_b32 s4, s12, 0x1000
	v_add_u32_e32 v3, -1, v3
	s_addk_i32 s12, 0x1000
	v_lshl_add_u64 v[10:11], s[10:11], 4, v[4:5]
	v_lshl_or_b32 v7, s4, 1, v0
	s_add_i32 s10, s10, s44
	v_cmp_eq_u32_e64 s[4:5], 0, v3
	s_or_b64 s[8:9], s[4:5], s[8:9]
	;;#ASMSTART
	global_load_dwordx4 v[10:13], v[10:11], off
	;;#ASMEND
	s_nop 0
	;;#ASMSTART
	s_waitcnt vmcnt(0)
	ds_write_b128 v7, v[10:13]
	;;#ASMEND
	s_barrier
	s_andn2_b64 exec, exec, s[8:9]
	s_cbranch_execnz .LBB4_19
.LBB4_20:                               ; %Flow216
	s_or_b64 exec, exec, s[6:7]
	v_mov_b32_e32 v3, 0
	s_barrier
	global_load_dword v0, v3, s[52:53]
	s_waitcnt vmcnt(0)
	v_add_u32_e32 v4, 1, v0
	s_and_saveexec_b64 s[4:5], vcc
	s_cbranch_execz .LBB4_23
; %bb.21:
	global_load_dwordx2 v[10:11], v1, s[34:35]
	s_mov_b32 s30, s18
	s_lshl_b64 s[2:3], s[2:3], 5
	s_lshl_b64 s[6:7], s[30:31], 2
	s_add_u32 s6, s6, s2
	s_addc_u32 s7, s7, s3
	s_add_u32 s2, s20, s2
	s_addc_u32 s3, s21, s3
	v_lshl_add_u64 v[0:1], s[2:3], 0, v[2:3]
	s_mov_b64 s[2:3], 0
	s_waitcnt vmcnt(0)
	v_lshl_add_u64 v[2:3], s[6:7], 0, v[10:11]
	buffer_wbl2 sc0 sc1
	global_store_dword v[2:3], v4, off offset:2560 sc0 sc1
.LBB4_22:                               ; =>This Inner Loop Header: Depth=1
	global_load_dword v2, v[0:1], off offset:2560 sc1
	s_waitcnt vmcnt(0)
	buffer_inv sc1
	v_cmp_ge_u32_e32 vcc, v2, v4
	s_or_b64 s[2:3], vcc, s[2:3]
	s_andn2_b64 exec, exec, s[2:3]
	s_cbranch_execnz .LBB4_22
.LBB4_23:                               ; %Flow214
	s_or_b64 exec, exec, s[4:5]
	s_barrier
	s_and_saveexec_b64 s[2:3], s[0:1]
	s_cbranch_execz .LBB4_25
; %bb.24:
	v_mov_b32_e32 v0, 0
	global_store_dword v0, v4, s[52:53]
.LBB4_25:                               ; %_ZN7commkit8end_syncILi8ELb0EEEvRKNS_11RankSignalsEPNS_6SignalEi.exit
	s_or_b64 exec, exec, s[2:3]
	s_mul_i32 s12, s33, -7
	s_add_i32 s12, s12, s19
	v_cmp_gt_i32_e32 vcc, s12, v8
	s_and_saveexec_b64 s[0:1], vcc
	s_cbranch_execz .LBB4_28
; %bb.26:                               ; %.lr.ph173
	s_add_u32 s13, s24, 0x1780
	s_addc_u32 s0, s25, 0
	s_add_u32 s14, s26, 0x1780
	s_addc_u32 s1, s27, 0
	s_add_u32 s15, s28, 0x1780
	s_addc_u32 s2, s29, 0
	v_add_u32_e32 v0, s18, v6
	s_add_u32 s16, s36, 0x1780
	v_ashrrev_i32_e32 v1, 31, v0
	s_addc_u32 s3, s37, 0
	v_lshrrev_b32_e32 v1, 29, v1
	s_add_u32 s17, s38, 0x1780
	v_add_u32_e32 v1, v0, v1
	s_addc_u32 s4, s39, 0
	v_and_b32_e32 v1, -8, v1
	s_add_u32 s19, s40, 0x1780
	v_sub_u32_e32 v4, v0, v1
	v_mov_b32_e32 v0, s0
	v_mov_b32_e32 v1, s1
	v_cmp_eq_u32_e32 vcc, 1, v6
	s_addc_u32 s6, s41, 0
	v_cmp_eq_u32_e64 s[0:1], 2, v6
	v_cndmask_b32_e32 v0, v0, v1, vcc
	v_mov_b32_e32 v1, s2
	s_add_u32 s20, s42, 0x1780
	v_cndmask_b32_e64 v0, v0, v1, s[0:1]
	v_mov_b32_e32 v1, s3
	v_cmp_eq_u32_e64 s[2:3], 3, v6
	s_addc_u32 s8, s43, 0
	s_add_u32 s21, s46, 0x1780
	v_cndmask_b32_e64 v0, v0, v1, s[2:3]
	v_mov_b32_e32 v1, s4
	v_cmp_eq_u32_e64 s[4:5], 4, v6
	s_addc_u32 s10, s47, 0
	v_mov_b32_e32 v2, s14
	v_cndmask_b32_e64 v0, v0, v1, s[4:5]
	v_mov_b32_e32 v1, s6
	v_cmp_eq_u32_e64 s[6:7], 5, v6
	s_nop 1
	v_cndmask_b32_e64 v0, v0, v1, s[6:7]
	v_mov_b32_e32 v1, s8
	v_cmp_eq_u32_e64 s[8:9], 6, v6
	s_nop 1
	v_cndmask_b32_e64 v0, v0, v1, s[8:9]
	v_mov_b32_e32 v1, s10
	v_cmp_eq_u32_e64 s[10:11], 7, v6
	s_nop 1
	v_cndmask_b32_e64 v1, v0, v1, s[10:11]
	v_mov_b32_e32 v0, s13
	v_cndmask_b32_e32 v0, v0, v2, vcc
	v_mov_b32_e32 v2, s15
	v_cndmask_b32_e64 v0, v0, v2, s[0:1]
	v_mov_b32_e32 v2, s16
	v_cndmask_b32_e64 v0, v0, v2, s[2:3]
	v_mov_b32_e32 v2, s17
	v_cndmask_b32_e64 v0, v0, v2, s[4:5]
	v_mov_b32_e32 v2, s19
	v_cndmask_b32_e64 v0, v0, v2, s[6:7]
	v_mov_b32_e32 v2, s20
	v_cndmask_b32_e64 v0, v0, v2, s[8:9]
	v_mov_b32_e32 v2, s21
	v_cndmask_b32_e64 v0, v0, v2, s[10:11]
	v_add_u32_e32 v2, s45, v9
	v_ashrrev_i32_e32 v3, 31, v2
	v_lshl_add_u64 v[0:1], v[2:3], 4, v[0:1]
	v_mad_u64_u32 v[2:3], s[2:3], v4, s33, v[2:3]
	s_ashr_i32 s45, s44, 31
	v_ashrrev_i32_e32 v3, 31, v2
	s_lshl_b64 s[0:1], s[44:45], 4
	v_lshl_add_u64 v[2:3], v[2:3], 4, s[22:23]
	s_mov_b64 s[2:3], 0
	s_mov_b64 s[4:5], 0
.LBB4_27:                               ; =>This Inner Loop Header: Depth=1
	v_lshl_add_u64 v[4:5], v[0:1], 0, s[4:5]
	flat_load_dwordx4 v[4:7], v[4:5]
	v_lshl_add_u64 v[10:11], v[2:3], 0, s[4:5]
	v_add_u32_e32 v8, s44, v8
	s_add_u32 s4, s4, s0
	s_addc_u32 s5, s5, s1
	v_cmp_le_i32_e32 vcc, s12, v8
	s_or_b64 s[2:3], vcc, s[2:3]
	s_waitcnt vmcnt(0) lgkmcnt(0)
	global_store_dwordx4 v[10:11], v[4:7], off
	s_andn2_b64 exec, exec, s[2:3]
	s_cbranch_execnz .LBB4_27
.LBB4_28:                               ; %Flow212
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel _ZN7commkit7kernels16ar_naive_overlapIDF16bEEvPNS_8RankDataES3_NS_11RankSignalsEPNS_6SignalEPT_ii
		.amdhsa_group_segment_fixed_size 16384
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
		.amdhsa_next_free_vgpr 14
		.amdhsa_next_free_sgpr 66
		.amdhsa_accum_offset 16
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
	.section	.text._ZN7commkit7kernels16ar_naive_overlapIDF16bEEvPNS_8RankDataES3_NS_11RankSignalsEPNS_6SignalEPT_ii,"axG",@progbits,_ZN7commkit7kernels16ar_naive_overlapIDF16bEEvPNS_8RankDataES3_NS_11RankSignalsEPNS_6SignalEPT_ii,comdat
.Lfunc_end4:
	.size	_ZN7commkit7kernels16ar_naive_overlapIDF16bEEvPNS_8RankDataES3_NS_11RankSignalsEPNS_6SignalEPT_ii, .Lfunc_end4-_ZN7commkit7kernels16ar_naive_overlapIDF16bEEvPNS_8RankDataES3_NS_11RankSignalsEPNS_6SignalEPT_ii
                                        ; -- End function
	.set _ZN7commkit7kernels16ar_naive_overlapIDF16bEEvPNS_8RankDataES3_NS_11RankSignalsEPNS_6SignalEPT_ii.num_vgpr, 14
	.set _ZN7commkit7kernels16ar_naive_overlapIDF16bEEvPNS_8RankDataES3_NS_11RankSignalsEPNS_6SignalEPT_ii.num_agpr, 0
	.set _ZN7commkit7kernels16ar_naive_overlapIDF16bEEvPNS_8RankDataES3_NS_11RankSignalsEPNS_6SignalEPT_ii.numbered_sgpr, 66
	.set _ZN7commkit7kernels16ar_naive_overlapIDF16bEEvPNS_8RankDataES3_NS_11RankSignalsEPNS_6SignalEPT_ii.private_seg_size, 0
	.set _ZN7commkit7kernels16ar_naive_overlapIDF16bEEvPNS_8RankDataES3_NS_11RankSignalsEPNS_6SignalEPT_ii.uses_vcc, 1
	.set _ZN7commkit7kernels16ar_naive_overlapIDF16bEEvPNS_8RankDataES3_NS_11RankSignalsEPNS_6SignalEPT_ii.uses_flat_scratch, 0
	.set _ZN7commkit7kernels16ar_naive_overlapIDF16bEEvPNS_8RankDataES3_NS_11RankSignalsEPNS_6SignalEPT_ii.has_dyn_sized_stack, 0
	.set _ZN7commkit7kernels16ar_naive_overlapIDF16bEEvPNS_8RankDataES3_NS_11RankSignalsEPNS_6SignalEPT_ii.has_recursion, 0
	.set _ZN7commkit7kernels16ar_naive_overlapIDF16bEEvPNS_8RankDataES3_NS_11RankSignalsEPNS_6SignalEPT_ii.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 2436
; TotalNumSgprs: 72
; NumVgprs: 14
; NumAgprs: 0
; TotalNumVgprs: 14
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 16384 bytes/workgroup (compile time only)
; SGPRBlocks: 8
; VGPRBlocks: 1
; NumSGPRsForWavesPerEU: 72
; NumVGPRsForWavesPerEU: 14
; AccumOffset: 16
; Occupancy: 8
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 2
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 0
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 0
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 0
; COMPUTE_PGM_RSRC3_GFX90A:ACCUM_OFFSET: 3
; COMPUTE_PGM_RSRC3_GFX90A:TG_SPLIT: 0
	.text
	.p2alignl 6, 3212836864
	.fill 256, 4, 3212836864
	.section	.AMDGPU.gpr_maximums,"",@progbits
	.set amdgpu.max_num_vgpr, 0
	.set amdgpu.max_num_agpr, 0
	.set amdgpu.max_num_sgpr, 0
	.text
	.type	__hip_cuid_24a6adf668896006,@object ; @__hip_cuid_24a6adf668896006
	.section	.bss,"aw",@nobits
	.globl	__hip_cuid_24a6adf668896006
__hip_cuid_24a6adf668896006:
	.byte	0                               ; 0x0
	.size	__hip_cuid_24a6adf668896006, 1

	.ident	"AMD clang version 20.0.0git (https://github.com/RadeonOpenCompute/llvm-project roc-7.0.2 25385 0dda3adf56766e0aac0d03173ced3759e1ffecbc)"
	.section	".note.GNU-stack","",@progbits
	.addrsig
	.addrsig_sym __hip_cuid_24a6adf668896006
	.amdgpu_metadata
---
amdhsa.kernels:
  - .agpr_count:     0
    .args:
      - .address_space:  global
        .offset:         0
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .offset:         8
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
    .name:           _ZN7commkit7kernels26cross_device_reduce_2stageIDF16bLi8EEEvPNS_8RankDataES3_NS_11RankSignalsEPNS_6SignalEPT_ii
    .private_segment_fixed_size: 0
    .sgpr_count:     77
    .sgpr_spill_count: 0
    .symbol:         _ZN7commkit7kernels26cross_device_reduce_2stageIDF16bLi8EEEvPNS_8RankDataES3_NS_11RankSignalsEPNS_6SignalEPT_ii.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     52
    .vgpr_spill_count: 0
    .wavefront_size: 64
  - .agpr_count:     0
    .args:
      - .address_space:  global
        .offset:         0
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .offset:         8
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
    .name:           _ZN7commkit7kernels6car_wtIDF16bLi8EEEvPNS_8RankDataES3_NS_11RankSignalsEPNS_6SignalEPT_ii
    .private_segment_fixed_size: 0
    .sgpr_count:     63
    .sgpr_spill_count: 0
    .symbol:         _ZN7commkit7kernels6car_wtIDF16bLi8EEEvPNS_8RankDataES3_NS_11RankSignalsEPNS_6SignalEPT_ii.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     56
    .vgpr_spill_count: 0
    .wavefront_size: 64
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
    .name:           _ZN7commkit7kernels7car_tp8IDF16bEEvPNS_8RankDataENS_11RankSignalsEPNS_6SignalEPT_ii
    .private_segment_fixed_size: 0
    .sgpr_count:     81
    .sgpr_spill_count: 0
    .symbol:         _ZN7commkit7kernels7car_tp8IDF16bEEvPNS_8RankDataENS_11RankSignalsEPNS_6SignalEPT_ii.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     64
    .vgpr_spill_count: 0
    .wavefront_size: 64
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
    .group_segment_fixed_size: 16384
    .kernarg_segment_align: 16
    .kernarg_segment_size: 360
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 1024
    .name:           _ZN7commkit7kernels23allreduce_double_bufferIDF16bEEvPNS_8RankDataENS_11RankSignalsEPNS_6SignalEPT_ii
    .private_segment_fixed_size: 0
    .sgpr_count:     81
    .sgpr_spill_count: 0
    .symbol:         _ZN7commkit7kernels23allreduce_double_bufferIDF16bEEvPNS_8RankDataENS_11RankSignalsEPNS_6SignalEPT_ii.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     66
    .vgpr_spill_count: 0
    .wavefront_size: 64
  - .agpr_count:     0
    .args:
      - .address_space:  global
        .offset:         0
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .offset:         8
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
    .group_segment_fixed_size: 16384
    .kernarg_segment_align: 16
    .kernarg_segment_size: 360
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 512
    .name:           _ZN7commkit7kernels16ar_naive_overlapIDF16bEEvPNS_8RankDataES3_NS_11RankSignalsEPNS_6SignalEPT_ii
    .private_segment_fixed_size: 0
    .sgpr_count:     72
    .sgpr_spill_count: 0
    .symbol:         _ZN7commkit7kernels16ar_naive_overlapIDF16bEEvPNS_8RankDataES3_NS_11RankSignalsEPNS_6SignalEPT_ii.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     14
    .vgpr_spill_count: 0
    .wavefront_size: 64
amdhsa.target:   amdgcn-amd-amdhsa--gfx942
amdhsa.version:
  - 1
  - 2
...

	.end_amdgpu_metadata
