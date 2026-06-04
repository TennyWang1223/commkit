	.amdgcn_target "amdgcn-amd-amdhsa--gfx942"
	.amdhsa_code_object_version 6
	.section	.text._ZN7commkit7kernels23local_vs_remote_rw_demoIDF16bEEvPNS_8RankDataENS_11RankSignalsEPT_S6_ii,"axG",@progbits,_ZN7commkit7kernels23local_vs_remote_rw_demoIDF16bEEvPNS_8RankDataENS_11RankSignalsEPT_S6_ii,comdat
	.protected	_ZN7commkit7kernels23local_vs_remote_rw_demoIDF16bEEvPNS_8RankDataENS_11RankSignalsEPT_S6_ii ; -- Begin function _ZN7commkit7kernels23local_vs_remote_rw_demoIDF16bEEvPNS_8RankDataENS_11RankSignalsEPT_S6_ii
	.globl	_ZN7commkit7kernels23local_vs_remote_rw_demoIDF16bEEvPNS_8RankDataENS_11RankSignalsEPT_S6_ii
	.p2align	8
	.type	_ZN7commkit7kernels23local_vs_remote_rw_demoIDF16bEEvPNS_8RankDataENS_11RankSignalsEPT_S6_ii,@function
_ZN7commkit7kernels23local_vs_remote_rw_demoIDF16bEEvPNS_8RankDataENS_11RankSignalsEPT_S6_ii: ; @_ZN7commkit7kernels23local_vs_remote_rw_demoIDF16bEEvPNS_8RankDataENS_11RankSignalsEPT_S6_ii
; %bb.0:
	s_load_dwordx2 s[8:9], s[0:1], 0x60
	s_load_dwordx2 s[4:5], s[0:1], 0x0
	s_load_dword s3, s[0:1], 0x68
	s_load_dword s16, s[0:1], 0x74
	s_waitcnt lgkmcnt(0)
	s_ashr_i32 s7, s8, 31
	s_mov_b32 s6, s8
	s_lshl_b64 s[6:7], s[6:7], 3
	s_add_u32 s14, s0, s6
	s_addc_u32 s15, s1, s7
	s_add_u32 s4, s4, s6
	s_addc_u32 s5, s5, s7
	s_load_dwordx2 s[10:11], s[4:5], 0x0
	s_load_dwordx2 s[12:13], s[14:15], 0x10
	s_and_b32 s4, s16, 0xffff
	s_mul_i32 s2, s2, s4
	v_add_u32_e32 v0, s2, v0
	s_mul_i32 s2, s3, s4
	v_cmp_gt_i32_e32 vcc, s9, v0
	v_ashrrev_i32_e32 v1, 31, v0
	s_and_saveexec_b64 s[14:15], vcc
	s_cbranch_execz .LBB0_3
; %bb.1:
	s_load_dwordx4 s[4:7], s[0:1], 0x50
	s_ashr_i32 s3, s2, 31
	v_lshlrev_b64 v[2:3], 4, v[0:1]
	s_lshl_b64 s[16:17], s[2:3], 4
	s_mov_b64 s[18:19], 0
	v_mov_b32_e32 v4, v0
.LBB0_2:                                ; =>This Inner Loop Header: Depth=1
	s_waitcnt lgkmcnt(0)
	v_lshl_add_u64 v[6:7], s[4:5], 0, v[2:3]
	global_load_dwordx4 v[6:9], v[6:7], off
	v_lshl_add_u64 v[10:11], s[6:7], 0, v[2:3]
	;;#ASMSTART
	s_waitcnt vmcnt(0)
	;;#ASMEND
	v_add_u32_e32 v4, s2, v4
	v_cmp_le_i32_e64 s[0:1], s9, v4
	s_or_b64 s[18:19], s[0:1], s[18:19]
	v_lshl_add_u64 v[2:3], v[2:3], 0, s[16:17]
	s_waitcnt vmcnt(0)
	global_store_dwordx4 v[10:11], v[6:9], off
	;;#ASMSTART
	s_waitcnt vmcnt(0)
	;;#ASMEND
	s_andn2_b64 exec, exec, s[18:19]
	s_cbranch_execnz .LBB0_2
.LBB0_3:
	s_or_b64 exec, exec, s[14:15]
	s_waitcnt lgkmcnt(0)
	; wave barrier
	s_waitcnt lgkmcnt(0)
	;;#ASMSTART
	s_waitcnt vmcnt(0)
	;;#ASMEND
	s_waitcnt lgkmcnt(0)
	; wave barrier
	s_and_saveexec_b64 s[0:1], vcc
	s_cbranch_execz .LBB0_6
; %bb.4:
	s_add_u32 s0, s12, 0x1780
	s_addc_u32 s1, s13, 0
	s_ashr_i32 s3, s2, 31
	v_lshlrev_b64 v[2:3], 4, v[0:1]
	s_lshl_b64 s[4:5], s[2:3], 4
	s_mov_b64 s[6:7], 0
.LBB0_5:                                ; =>This Inner Loop Header: Depth=1
	v_lshl_add_u64 v[4:5], s[10:11], 0, v[2:3]
	flat_load_dwordx4 v[4:7], v[4:5]
	v_lshl_add_u64 v[8:9], s[0:1], 0, v[2:3]
	;;#ASMSTART
	s_waitcnt vmcnt(0)
	;;#ASMEND
	v_add_u32_e32 v0, s2, v0
	v_cmp_le_i32_e32 vcc, s9, v0
	s_or_b64 s[6:7], vcc, s[6:7]
	v_lshl_add_u64 v[2:3], v[2:3], 0, s[4:5]
	s_waitcnt vmcnt(0) lgkmcnt(0)
	global_store_dwordx4 v[8:9], v[4:7], off
	;;#ASMSTART
	s_waitcnt vmcnt(0)
	;;#ASMEND
	s_andn2_b64 exec, exec, s[6:7]
	s_cbranch_execnz .LBB0_5
.LBB0_6:
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel _ZN7commkit7kernels23local_vs_remote_rw_demoIDF16bEEvPNS_8RankDataENS_11RankSignalsEPT_S6_ii
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
		.amdhsa_next_free_vgpr 12
		.amdhsa_next_free_sgpr 20
		.amdhsa_accum_offset 12
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
	.section	.text._ZN7commkit7kernels23local_vs_remote_rw_demoIDF16bEEvPNS_8RankDataENS_11RankSignalsEPT_S6_ii,"axG",@progbits,_ZN7commkit7kernels23local_vs_remote_rw_demoIDF16bEEvPNS_8RankDataENS_11RankSignalsEPT_S6_ii,comdat
.Lfunc_end0:
	.size	_ZN7commkit7kernels23local_vs_remote_rw_demoIDF16bEEvPNS_8RankDataENS_11RankSignalsEPT_S6_ii, .Lfunc_end0-_ZN7commkit7kernels23local_vs_remote_rw_demoIDF16bEEvPNS_8RankDataENS_11RankSignalsEPT_S6_ii
                                        ; -- End function
	.set _ZN7commkit7kernels23local_vs_remote_rw_demoIDF16bEEvPNS_8RankDataENS_11RankSignalsEPT_S6_ii.num_vgpr, 12
	.set _ZN7commkit7kernels23local_vs_remote_rw_demoIDF16bEEvPNS_8RankDataENS_11RankSignalsEPT_S6_ii.num_agpr, 0
	.set _ZN7commkit7kernels23local_vs_remote_rw_demoIDF16bEEvPNS_8RankDataENS_11RankSignalsEPT_S6_ii.numbered_sgpr, 20
	.set _ZN7commkit7kernels23local_vs_remote_rw_demoIDF16bEEvPNS_8RankDataENS_11RankSignalsEPT_S6_ii.private_seg_size, 0
	.set _ZN7commkit7kernels23local_vs_remote_rw_demoIDF16bEEvPNS_8RankDataENS_11RankSignalsEPT_S6_ii.uses_vcc, 1
	.set _ZN7commkit7kernels23local_vs_remote_rw_demoIDF16bEEvPNS_8RankDataENS_11RankSignalsEPT_S6_ii.uses_flat_scratch, 0
	.set _ZN7commkit7kernels23local_vs_remote_rw_demoIDF16bEEvPNS_8RankDataENS_11RankSignalsEPT_S6_ii.has_dyn_sized_stack, 0
	.set _ZN7commkit7kernels23local_vs_remote_rw_demoIDF16bEEvPNS_8RankDataENS_11RankSignalsEPT_S6_ii.has_recursion, 0
	.set _ZN7commkit7kernels23local_vs_remote_rw_demoIDF16bEEvPNS_8RankDataENS_11RankSignalsEPT_S6_ii.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 384
; TotalNumSgprs: 26
; NumVgprs: 12
; NumAgprs: 0
; TotalNumVgprs: 12
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 3
; VGPRBlocks: 1
; NumSGPRsForWavesPerEU: 26
; NumVGPRsForWavesPerEU: 12
; AccumOffset: 12
; Occupancy: 8
; WaveLimiterHint : 1
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 2
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 0
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 0
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 0
; COMPUTE_PGM_RSRC3_GFX90A:ACCUM_OFFSET: 2
; COMPUTE_PGM_RSRC3_GFX90A:TG_SPLIT: 0
	.text
	.p2alignl 6, 3212836864
	.fill 256, 4, 3212836864
	.section	.AMDGPU.gpr_maximums,"",@progbits
	.set amdgpu.max_num_vgpr, 0
	.set amdgpu.max_num_agpr, 0
	.set amdgpu.max_num_sgpr, 0
	.text
	.type	__hip_cuid_8d0c4661fc30fef,@object ; @__hip_cuid_8d0c4661fc30fef
	.section	.bss,"aw",@nobits
	.globl	__hip_cuid_8d0c4661fc30fef
__hip_cuid_8d0c4661fc30fef:
	.byte	0                               ; 0x0
	.size	__hip_cuid_8d0c4661fc30fef, 1

	.ident	"AMD clang version 20.0.0git (https://github.com/RadeonOpenCompute/llvm-project roc-7.0.2 25385 0dda3adf56766e0aac0d03173ced3759e1ffecbc)"
	.section	".note.GNU-stack","",@progbits
	.addrsig
	.addrsig_sym __hip_cuid_8d0c4661fc30fef
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
      - .address_space:  global
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
    .max_flat_workgroup_size: 64
    .name:           _ZN7commkit7kernels23local_vs_remote_rw_demoIDF16bEEvPNS_8RankDataENS_11RankSignalsEPT_S6_ii
    .private_segment_fixed_size: 0
    .sgpr_count:     26
    .sgpr_spill_count: 0
    .symbol:         _ZN7commkit7kernels23local_vs_remote_rw_demoIDF16bEEvPNS_8RankDataENS_11RankSignalsEPT_S6_ii.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     12
    .vgpr_spill_count: 0
    .wavefront_size: 64
amdhsa.target:   amdgcn-amd-amdhsa--gfx942
amdhsa.version:
  - 1
  - 2
...

	.end_amdgpu_metadata
