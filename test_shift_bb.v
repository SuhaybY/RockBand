// megafunction wizard: %Shift register (RAM-based)%VBB%
// GENERATION: STANDARD
// VERSION: WM1.0
// MODULE: ALTSHIFT_TAPS 

// ============================================================
// File Name: test_shift.v
// Megafunction Name(s):
// 			ALTSHIFT_TAPS
//
// Simulation Library Files(s):
// 			altera_mf
// ============================================================
// ************************************************************
// THIS IS A WIZARD-GENERATED FILE. DO NOT EDIT THIS FILE!
//
// 18.0.0 Build 614 04/24/2018 SJ Lite Edition
// ************************************************************

//Copyright (C) 2018  Intel Corporation. All rights reserved.
//Your use of Intel Corporation's design tools, logic functions 
//and other software and tools, and its AMPP partner logic 
//functions, and any output files from any of the foregoing 
//(including device programming or simulation files), and any 
//associated documentation or information are expressly subject 
//to the terms and conditions of the Intel Program License 
//Subscription Agreement, the Intel Quartus Prime License Agreement,
//the Intel FPGA IP License Agreement, or other applicable license
//agreement, including, without limitation, that your use is for
//the sole purpose of programming logic devices manufactured by
//Intel and sold by Intel or its authorized distributors.  Please
//refer to the applicable agreement for further details.

module test_shift (
	aclr,
	clken,
	clock,
	shiftin,
	shiftout,
	taps);

	input	  aclr;
	input	  clken;
	input	  clock;
	input	[4:0]  shiftin;
	output	[4:0]  shiftout;
	output	[9:0]  taps;
`ifndef ALTERA_RESERVED_QIS
// synopsys translate_off
`endif
	tri1	  aclr;
	tri1	  clken;
`ifndef ALTERA_RESERVED_QIS
// synopsys translate_on
`endif

endmodule

// ============================================================
// CNX file retrieval info
// ============================================================
// Retrieval info: PRIVATE: ACLR NUMERIC "1"
// Retrieval info: PRIVATE: CLKEN NUMERIC "1"
// Retrieval info: PRIVATE: GROUP_TAPS NUMERIC "0"
// Retrieval info: PRIVATE: INTENDED_DEVICE_FAMILY STRING "Cyclone V"
// Retrieval info: PRIVATE: NUMBER_OF_TAPS NUMERIC "2"
// Retrieval info: PRIVATE: RAM_BLOCK_TYPE NUMERIC "3"
// Retrieval info: PRIVATE: SYNTH_WRAPPER_GEN_POSTFIX STRING "0"
// Retrieval info: PRIVATE: TAP_DISTANCE NUMERIC "250"
// Retrieval info: PRIVATE: WIDTH NUMERIC "5"
// Retrieval info: LIBRARY: altera_mf altera_mf.altera_mf_components.all
// Retrieval info: CONSTANT: INTENDED_DEVICE_FAMILY STRING "Cyclone V"
// Retrieval info: CONSTANT: LPM_HINT STRING "RAM_BLOCK_TYPE=AUTO"
// Retrieval info: CONSTANT: LPM_TYPE STRING "altshift_taps"
// Retrieval info: CONSTANT: NUMBER_OF_TAPS NUMERIC "2"
// Retrieval info: CONSTANT: TAP_DISTANCE NUMERIC "250"
// Retrieval info: CONSTANT: WIDTH NUMERIC "5"
// Retrieval info: USED_PORT: aclr 0 0 0 0 INPUT VCC "aclr"
// Retrieval info: USED_PORT: clken 0 0 0 0 INPUT VCC "clken"
// Retrieval info: USED_PORT: clock 0 0 0 0 INPUT NODEFVAL "clock"
// Retrieval info: USED_PORT: shiftin 0 0 5 0 INPUT NODEFVAL "shiftin[4..0]"
// Retrieval info: USED_PORT: shiftout 0 0 5 0 OUTPUT NODEFVAL "shiftout[4..0]"
// Retrieval info: USED_PORT: taps 0 0 10 0 OUTPUT NODEFVAL "taps[9..0]"
// Retrieval info: CONNECT: @aclr 0 0 0 0 aclr 0 0 0 0
// Retrieval info: CONNECT: @clken 0 0 0 0 clken 0 0 0 0
// Retrieval info: CONNECT: @clock 0 0 0 0 clock 0 0 0 0
// Retrieval info: CONNECT: @shiftin 0 0 5 0 shiftin 0 0 5 0
// Retrieval info: CONNECT: shiftout 0 0 5 0 @shiftout 0 0 5 0
// Retrieval info: CONNECT: taps 0 0 10 0 @taps 0 0 10 0
// Retrieval info: GEN_FILE: TYPE_NORMAL test_shift.v TRUE
// Retrieval info: GEN_FILE: TYPE_NORMAL test_shift.inc FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL test_shift.cmp FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL test_shift.bsf FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL test_shift_inst.v TRUE
// Retrieval info: GEN_FILE: TYPE_NORMAL test_shift_bb.v TRUE
// Retrieval info: LIB_FILE: altera_mf
