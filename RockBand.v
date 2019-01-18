module RockBand
	(
		CLOCK_50,						//	On Board 50 MHz
		SW,								// On Board switches
		KEY,		// On Board Keys
		
		PS2_CLK,
		PS2_DAT,
		
		VGA_CLK,   						//	VGA Clock
		VGA_HS,							//	VGA H_SYNC
		VGA_VS,							//	VGA V_SYNC
		VGA_BLANK_N,						//	VGA BLANK
		VGA_SYNC_N,						//	VGA SYNC
		VGA_R,   						//	VGA Red[9:0]
		VGA_G,	 						//	VGA Green[9:0]
		VGA_B   						//	VGA Blue[9:0]
	);

	input				CLOCK_50;
	input	[3:0]		KEY;					
	input [9:0]   	SW;
	
	inout PS2_CLK;
	inout PS2_DAT;
	
	wire resetn;
	wire writeEn;
	reg [8:0] final_color;
	reg [9:0] x;
	reg [9:0] y;
	
	output			VGA_CLK;   				//	VGA Clock
	output			VGA_HS;					//	VGA H_SYNC
	output			VGA_VS;					//	VGA V_SYNC
	output			VGA_BLANK_N;			//	VGA BLANK
	output			VGA_SYNC_N;				//	VGA SYNC
	output [7:0]	VGA_R;   				//	VGA Red[7:0] Changed from 10 to 8-bit DAC
	output [7:0]	VGA_G;	 				//	VGA Green[7:0]
	output [7:0]	VGA_B;   				//	VGA Blue[7:0]
	
	vga_adapter VGA(
			.resetn(resetn),
			.clock(CLOCK_50),
			.colour(final_color),
			.x(x),
			.y(y),
			.plot(writeEn),
			/* Signals for the DAC to drive the monitor. */
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK(VGA_BLANK_N),
			.VGA_SYNC(VGA_SYNC_N),
			.VGA_CLK(VGA_CLK));
		defparam VGA.RESOLUTION = "320x240";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 3;
		defparam VGA.BACKGROUND_IMAGE = "start.mif";
			
	// Put your code here. Your code should produce signals x,y,colour and writeEn
	// for the VGA controller, in addition to any other functionality your design may require.
	wire [25:0] speed;
	
	// start enables
	wire draw_background, erase, draw_notes, draw, feed_ram, feed, load, remove, score, correct, wrong, hit, 
		display_score, display_correct, display_wrong, display_hit, over, draw_gameover, done_game, gameover, display_last_score, over_score;
	// plot enables
	wire erase_plot, note_plot, score_plot, correct_plot, wrong_plot, hit_plot, over_plot, score_over_plot;
	// done state
	wire done_erase, done_draw, done_feed, done_new, done_remove, done_score, done_correct, done_wrong, done_hit, again, done_game_over;
	assign writeEn = (erase_plot || note_plot || score_plot || correct_plot || wrong_plot || hit_plot || over_plot || score_over_plot);
	
	//assign wrong_plot = 0;
	//assign hit_plot = 0;
	//assign done_wrong = 1;
	//assign done_hit = 1;
	
	reg [4:0] data_in;
	reg [7:0] mem_address;
	reg wren, rden; 
	
	wire [8:0] background_color, over_color;
	wire [9:0] x_background, y_background, x_note, y_note, x_score, y_score, x_correct, y_correct, x_wrong, y_wrong, x_hit, y_hit,
		x_over, y_over, x_over_score, y_over_score;
	wire [8:0] colour_in;
	
	wire [7:0] notes_address, shift_address, hit_address, song_address;
	wire [9:0] correct_num, wrong_num, all_notes;

	assign resetn = KEY[0];
	
	wire wren_note, rden_note, wren_hit, check_hit;
	wire [4:0] data_out, out_ram, feed_note, last_note;
	
	wire [3:0] user_note;
	wire start;
	
	always @(*)
	begin
		if (draw_background)
		begin
			final_color <= background_color;
			x <= x_background;
			y <= y_background;
		end
		else if (display_score)
		begin
			final_color <= 3'b0;
			x <= x_score;
			y <= y_score;
		end
		else if (display_last_score)
		begin
			final_color <= 3'b0;
			x <= x_over_score;
			y <= y_over_score;
		end
		else if (display_correct)
		begin
			final_color <= 3'b0;
			x <= x_correct;
			y <= y_correct;
		end
		else if (display_wrong)
		begin
			final_color <= 3'b0;
			x <= x_wrong;
			y <= y_wrong;
		end
		else if (display_hit)
		begin
			final_color <= 3'b0;
			x <= x_hit;
			y <= y_hit;
		end
		else if (remove)
		begin
			data_in <= 5'b0;
			mem_address <= hit_address;
			wren = wren_hit;
			rden = 1'b0;
		end
		else if (draw_notes)
		begin
			final_color <= colour_in;
			x <= x_note;
			y <= y_note;
			data_in <= 5'b0;
			mem_address <= notes_address;
			wren = 1'b0;
			rden = 1'b1;
		end
		else if (draw_gameover)
		begin
			final_color <= over_color;
			x <= x_over;
			y <= y_over;
		end
		else if (feed_ram)
		begin
			data_in <= data_out;
			mem_address <= shift_address;
			wren = wren_note;
			rden = rden_note;
		end
	end
	
	reg [2:0] difficulty_level;
	
	hit_detection hit_detection0(.remove(remove), .resetn(done_draw), .clock(CLOCK_50), .user_note(user_note), 
		.wrong(wrong_num), .correct(correct_num), .last_note(last_note), .gameover(gameover));
	
	load_background load_background0(.draw_background(draw_background), .resetn(~erase), .clock(CLOCK_50), 
		.out_color(background_color), .done_erase(done_erase), .final_x(x_background), .final_y(y_background), .erase_plot(erase_plot));
	
	load_over load_over0(.draw_background(draw_gameover), .resetn(~gameover), .clock(CLOCK_50), 
		.out_color(over_color), .done_erase(done_game_over), .final_x(x_over), .final_y(y_over), .erase_plot(over_plot));
		
	load_notes load_notes0(.start_notes(draw_notes), .resetn(~draw), .clock(CLOCK_50), .out_color(colour_in),
		.done_draw(done_draw), .final_x(x_note), .final_y(y_note), .note_plot(note_plot), 
		.memory_address(notes_address), .note(out_ram), .last_note(last_note), .remove(remove), .done_remove(done_remove));
	
	note_to_ram note_to_ram0(.resetn(~feed), .clock(CLOCK_50), .enable(feed_ram), .note_in(feed_note), .done(done_feed), 
		.mem_address(shift_address), .rden_out(rden_note), .wren_out(wren_note), .data_out(data_out), .note_ram(out_ram));
	
	notes_display_test notes_display0(.clock(CLOCK_50), .data(data_in), .rdaddress(mem_address), .rden(rden), 
		.wraddress(mem_address), .wren(wren), .q(out_ram));
		
	erase_note remove_note0 (.clock(CLOCK_50), .resetn(~remove), .mem_address(hit_address), 
		.done_remove(done_remove), .wren(wren_hit), .check_hit(check_hit), .gameover(gameover), .done_game(done_game));
		
	song1 song (.address(song_address), .clock(CLOCK_50), .data(4'b0), .wren(1'b0), .q(feed_note));
	
	// Statistics
	load_score lscore(.correct(correct_num * 'd5), .display_score(display_score), .resetn(~score), .clock(CLOCK_50), 
		.done_score(done_score), .score_plot(score_plot), .final_x(x_score), .final_y(y_score), .offx('d6), .offy('d22));
	load_score lcorrect(.correct(correct_num / 'd2), .display_score(display_correct), .resetn(~correct), .clock(CLOCK_50), 
		.done_score(done_correct), .score_plot(correct_plot), .final_x(x_correct), .final_y(y_correct), .offx('d273), .offy('d34));
	load_score lwrong(.correct(wrong_num / 'd2), .display_score(display_wrong), .resetn(~wrong), .clock(CLOCK_50), 
		.done_score(done_wrong), .score_plot(wrong_plot), .final_x(x_wrong), .final_y(y_wrong), .offx('d273), .offy('d59));
	load_score lhit(.correct(SW[2:0]), .display_score(display_hit), .resetn(~hit), .clock(CLOCK_50), 
		.done_score(done_hit), .score_plot(hit_plot), .final_x(x_hit), .final_y(y_hit), .offx('d273), .offy('d84));
		
	load_score finalscore(.correct(correct_num * 'd5), .display_score(display_last_score), .resetn(~over_score), .clock(CLOCK_50), 
		.done_score(done_score_over), .score_plot(score_over_plot), .final_x(x_over_score), .final_y(y_over_score), .offx('d167), .offy('d218));
		
	difficulty difficulty0(.data(SW[2:0]), .out(speed));
		
	control control0(
				.clock(CLOCK_50),
				.resetn(resetn),
				.go(start),
				.done_erase(done_erase),
				.done_draw(done_draw),
				.done_feed(done_feed),
				.done_new(done_new),
				.done_score(done_score),
				.done_correct(done_correct),
				.done_wrong(done_wrong),
				.done_hit(done_hit),
				.speed(speed),
				.gameover(done_game),
				.done_game_over(done_game_over),
				
				.draw(draw),
				.erase(erase),
				.feed(feed),
				.load(load),
				.score(score),
				.correct(correct),
				.wrong(wrong),
				.hit(hit),
				.over(over),
				.again(again),
				.over_score(over_score)
				);
	
	datapath datapath0(
			.clock(CLOCK_50),
			.draw(draw),
			.erase(erase),
			.feed(feed),
			.load(load),
			.score(score),
			.correct(correct),
			.wrong(wrong),
			.hit(hit),
			.over(over),
			.over_score(over_score),
			
			.draw_gameover(draw_gameover),
			.draw_background(draw_background),
			.draw_notes(draw_notes),
			.feed_ram(feed_ram),
			.done_new(done_new),
			.display_score(display_score),
			.display_correct(display_correct),
			.display_wrong(display_wrong),
			.display_hit(display_hit),
			.display_last_score(display_last_score),
			.song_address(song_address)
			);
			
	wire		[15:0]	ps2_key_data;
	PS2_Controller PS2 (
		// Inputs
		.CLOCK_50				(CLOCK_50),
		.reset				(~resetn),

		// Bidirectionals
		.PS2_CLK			(PS2_CLK),
		.PS2_DAT			(PS2_DAT),

		// Outputs
		.received_data		(ps2_key_data),
		.received_data_en	(ps2_key_pressed)
	);
	
	// Use the keyboard lights to indicate when to hit note!!
	
	key_fsm start_pressed(.clock(CLOCK_50), .resetn(resetn), .value(8'h1B), .on(start), .data(ps2_key_data[15:8]),
		.ps2_key_pressed(ps2_key_pressed));
	key_fsm blue_pressed(.clock(CLOCK_50), .resetn(resetn), .value(8'h05), .on(user_note[3]), .data(ps2_key_data[15:8]),
		.ps2_key_pressed(ps2_key_pressed));
	key_fsm red_pressed(.clock(CLOCK_50), .resetn(resetn), .value(8'h06), .on(user_note[2]), .data(ps2_key_data[15:8]),
		.ps2_key_pressed(ps2_key_pressed));
	key_fsm green_pressed(.clock(CLOCK_50), .resetn(resetn), .value(8'h04), .on(user_note[1]), .data(ps2_key_data[15:8]), 
		.ps2_key_pressed(ps2_key_pressed));
	key_fsm yellow_pressed(.clock(CLOCK_50), .resetn(resetn), .value(8'h0C), .on(user_note[0]), .data(ps2_key_data[15:8]), 
		.ps2_key_pressed(ps2_key_pressed));
	
endmodule

module key_fsm(clock, resetn, value, on, data, ps2_key_pressed);
	
	input clock, resetn, ps2_key_pressed;
	input [7:0] value, data;
	output reg on;

	reg [5:0] current_state, next_state;
	
	localparam  S_OFF  	  		= 6'd0,
					S_WAIT			= 6'd1,
					S_ON       		= 6'd2;
 
	always @(posedge ps2_key_pressed)
	begin: state_table 
			case (current_state)
					S_ON: next_state 		<= (data == 8'hF0) ? S_WAIT : S_ON;
					S_WAIT: 
					begin
						if (data == 8'hF0) next_state <= S_WAIT;
						else if (data == value) next_state <= S_OFF;
						else next_state <= S_ON;
					end
					S_OFF: next_state		<= (data == value) ? S_ON : S_OFF;
					default: next_state 		<= S_OFF;
			endcase
	end
   
	always @(*)
	begin: enable_signals
		on	<= 1'b1;
		
		case (current_state)
			S_OFF: on <= 1'b0;
		endcase
	end
   
	always@(posedge clock)
	begin: state_FFs
		if(!resetn)
		begin
			current_state <= S_OFF;
		end
		else
		begin
			current_state <= next_state;
		end
	end
endmodule

module hit_detection(clock, resetn, remove, last_note, user_note, correct, wrong, gameover);
	
	input clock, remove, resetn;
	input [4:0] last_note, user_note;
	output [9:0] correct, wrong;
	output gameover;
	
	reg [9:0] correct, wrong, prev_hit;
	reg [3:0] early_note;
	initial 
	begin
		correct = 0;
		wrong = 0;
		prev_hit = 0;
		early_note = 0;
	end
	
	reg game_over = 1'b0;
	
	assign gameover = game_over;
	
	always@(posedge clock)
	begin
		if (resetn)
			prev_hit <= 0;
		if (last_note != 0 && prev_hit != last_note)
		begin
			prev_hit <= last_note;
			if (user_note == last_note) correct <= correct + 1;
			else wrong <= wrong + 1;
			if (last_note == 5'd16) game_over <= 1'b1;
		end
	end
endmodule

module erase_note(clock, resetn, mem_address, done_remove, wren, check_hit, gameover, done_game);
	
	input clock, resetn, gameover;
	output reg wren, done_remove, check_hit, done_game;
	output reg [7:0] mem_address;
	
	reg [3:0] correct, wrong;
	initial correct = 4'b0;
	initial wrong = 4'b0;
	
	always@(posedge clock)
	begin
		if (resetn)
		begin
			done_game <= 0;
			check_hit <= 0;
			done_remove <= 1'b0;
			mem_address <= 8'd175;
			wren <= 1'b0;
		end
		else
		begin
			if (mem_address == 8'd176) check_hit <= 1'b1;
			wren <= 1'b1;
			mem_address <= mem_address + 8'd1;
			if (mem_address == 8'd192)
			begin
				if (gameover) done_game <= 1'b1;
				done_remove <= 1'b1;
			end
		end
	end
endmodule

module decimal_counter(bin_counter, ones, tens, hundreds);

	input [9:0] bin_counter;
	output [3:0] ones, tens, hundreds;
	
	wire [9:0] val_counter;
	assign val_counter = bin_counter;
	// 987 % 10
	// 987 % 100 = 87 --> 87 / 10 = 5 
	// 987/100
	assign ones = val_counter % 'd10;
	assign tens = (val_counter % 'd100) / 'd10;
	assign hundreds = val_counter / 'd100;

endmodule

module load_score(correct, display_score, resetn, clock, done_score, score_plot, final_x, final_y, offx, offy);
	
	input clock, resetn, display_score;
	input [10:0] offx, offy;
	input [9:0] correct;
	output [9:0] final_x, final_y;
	output reg done_score, score_plot;
	
	wire [3:0] ones, tens, hundreds;
	
	reg next_seg;
	
	reg [9:0] counter_x, counter_y;
	wire [6:0] seg;
	reg [1:0] current_place = 2'b0;
	
	reg [3:0] current = 4'b0;
	reg [3:0] current_seg = 4'b0;
	
	decimal_counter d_counter(.bin_counter(correct), .ones(ones), .tens(tens), .hundreds(hundreds));
	always @(*)
	begin
		case (current_place)
			3'd0: current = hundreds;
			3'd1: current = tens;
			3'd2: current = ones;
		endcase
	end
	
	hex_decoder h0(.hex_digit(current), .segments(seg));
	
	always@(posedge clock)
	begin
		if (resetn)
		begin
			next_seg <= 1'b0;
			current_seg <= 3'b0;
			score_plot <= 1'b0;
			done_score <= 1'b0;
			current_place <= 2'b0;
			counter_x <= 10'b0;
			counter_y <= 10'b0;
		end
			
		if (display_score && !done_score)
		begin
			score_plot <= 1'b0;
			case (current_seg)
				3'd0:
				begin
					if (next_seg == 0)
					begin
						next_seg <= 1'b1;
						counter_x <= 'd0;
						counter_y <= 'd0;
					end
					else if (seg[current_seg] == 1 || counter_x == 10'd4)
					begin
						next_seg <= 1'b0;
						current_seg <= current_seg + 1;
					end
					else if (next_seg == 1)
					begin
						score_plot <= 1'b1;
						counter_x <= counter_x + 1;
					end
				end
				3'd1:
				begin
					if (next_seg == 0)
					begin
						next_seg <= 1'b1;
						counter_x <= 'd4;
						counter_y <= 'd0;
					end
					else if (seg[current_seg] == 1 || counter_y == 10'd4)
					begin
						next_seg <= 1'b0;
						current_seg <= current_seg + 1;
					end
					else if (next_seg == 1)
					begin
						score_plot <= 1'b1;
						counter_y <= counter_y + 1;
					end
				end
				3'd2:
				begin
					if (next_seg == 0)
					begin
						next_seg <= 1'b1;
						counter_x <= 'd4;
						counter_y <= 'd4;
					end
					else if (seg[current_seg] == 1 || counter_y == 10'd8)
					begin
						next_seg <= 1'b0;
						current_seg <= current_seg + 1;
					end
					else if (next_seg == 1)
					begin
						score_plot <= 1'b1;
						counter_y <= counter_y + 1;
					end
				end
				3'd3:
				begin
					if (next_seg == 0)
					begin
						next_seg <= 1'b1;
						counter_x <= 'd0;
						counter_y <= 'd8;
					end
					else if (seg[current_seg] == 1 || counter_x == 10'd4)
					begin
						next_seg <= 1'b0;
						current_seg <= current_seg + 1;
					end
					else if (next_seg == 1)
					begin
						score_plot <= 1'b1;
						counter_x <= counter_x + 1;
					end
				end
				3'd4: 
				begin
					if (next_seg == 0)
					begin
						next_seg <= 1'b1;
						counter_x <= 'd0;
						counter_y <= 'd4;
					end
					else if (seg[current_seg] == 1 || counter_y == 10'd8)
					begin
						next_seg <= 1'b0;
						current_seg <= current_seg + 1;
					end
					else if (next_seg == 1)
					begin
						score_plot <= 1'b1;
						counter_y <= counter_y + 1;
					end
				end
				3'd5:
				begin
					if (next_seg == 0)
					begin
						next_seg <= 1'b1;
						counter_x <= 'd0;
						counter_y <= 'd0;
					end
					else if (seg[current_seg] == 1 || counter_y == 10'd4)
					begin
						next_seg <= 1'b0;
						current_seg <= current_seg + 1;
					end
					else if (next_seg == 1)
					begin
						score_plot <= 1'b1;
						counter_y <= counter_y + 1;
					end
				end
				3'd6: 
				begin
					if (next_seg == 0)
					begin
						next_seg <= 1'b1;
						counter_x <= 'd0;
						counter_y <= 'd4;
					end
					else if (seg[current_seg] == 1 || counter_x == 10'd4)
					begin
						next_seg <= 1'b0;
						current_seg <= 0;
						current_place <= current_place + 1;
						if ((current_place + 1) == 2'b11) done_score <= 1'b1;
					end
					else if (next_seg == 1)
					begin
						score_plot <= 1'b1;
						counter_x <= counter_x + 1;
					end
				end
			endcase
		end
		
	end
	assign final_x = counter_x + current_place*12 + offx;
	assign final_y = counter_y + offy;
endmodule

module control(clock, resetn, go, done_erase, done_draw, done_feed, done_hit, speed, erase, draw, feed, load, 
	pass, hit, done_new, remove, done_remove, score, done_score, over, again, gameover,
	correct, wrong, done_correct, done_wrong, done_game_over, over_score);
	
	input clock, resetn, go, done_erase, done_draw, done_feed, done_hit, done_new, remove, done_remove, done_score, again, gameover,
		done_correct, done_wrong, done_game_over;
	input [25:0] speed;
	output reg erase, draw, feed, load, pass, hit, score, correct, wrong, over, over_score;

	reg [5:0] current_state, next_state;
	
	localparam  S_BEGIN  	  		= 6'd0,
					S_ERASE       		= 6'd1,
					S_FEED_RAM 			= 6'd2,
					S_DRAW	 	 		= 6'd3,
					S_WAIT 	      	= 6'd4,
					S_NEW_NOTE 	      = 6'd5,
					S_DISP_SCORE		= 6'd6,
					S_DISP_CORRECT		= 6'd7,
					S_DISP_WRONG		= 6'd8,
					S_DISP_HIT			= 6'd9,
					S_GAME_OVER 		= 6'd10,
					S_GAME_OVER_SCORE 	= 6'd11;
	
	wire counter;
	wire [25:0] w1;
	assign counter = (w1 == 26'b0) ? 1 : 0;
	
	rate_divider r0(
				.clock(clock),
				.load(speed),
				.enable(current_state == S_WAIT),
				.count(w1)
				);
 
	always @(*)
	begin: state_table 
			case (current_state)
					S_BEGIN: next_state 		<= go ? S_ERASE : S_BEGIN;
					S_ERASE: next_state 		<= done_erase ? S_FEED_RAM : S_ERASE;
					S_FEED_RAM: next_state 	<= done_feed ? S_DRAW : S_FEED_RAM;
					S_DRAW: next_state 	<= done_draw ? S_DISP_SCORE : S_DRAW;
					S_DISP_SCORE: next_state 		<= done_score ? S_DISP_CORRECT : S_DISP_SCORE;
					S_DISP_CORRECT: next_state 		<= done_correct ? S_DISP_WRONG : S_DISP_CORRECT;
					S_DISP_WRONG: next_state 		<= done_wrong ? S_DISP_HIT : S_DISP_WRONG;
					S_DISP_HIT: next_state 		<= done_hit ? S_WAIT : S_DISP_HIT;	
					S_WAIT: next_state 		<= counter ? S_NEW_NOTE : S_WAIT;
					S_NEW_NOTE: next_state 		<= done_new ? S_ERASE : S_NEW_NOTE;
					
					S_GAME_OVER: next_state <= done_game_over ? S_GAME_OVER_SCORE : S_GAME_OVER;
					S_GAME_OVER_SCORE: next_state <= S_GAME_OVER_SCORE;
					
					// For ModelSim:
//					S_BEGIN: next_state 		<= go ? S_ERASE : S_BEGIN;
//					S_ERASE: next_state 		<= done_erase ? S_FEED_RAM : S_ERASE;
//					S_FEED_RAM: next_state 	<= done_feed ? S_DRAW : S_FEED_RAM;
//					S_DRAW: next_state 	<= done_draw ? S_DISP_STATS : S_DRAW;
//					S_DISP_STATS: next_state 		<= done_stats ? S_NEW_NOTE : S_DISP_STATS; 
//					S_NEW_NOTE: next_state 		<= done_new ? S_ERASE : S_NEW_NOTE;

					default: next_state 		<= S_BEGIN;
			endcase
	end
   
	always @(*)
	begin: enable_signals
		load	<= 1'b0;
		erase	<= 1'b0;
		feed	<= 1'b0;
		draw	<= 1'b0;
		score <= 1'b0;
		correct <= 1'b0;
		wrong <= 1'b0;
		hit <= 1'b0;
		over 	<= 1'b0;
		over_score <= 1'b0;
		
		case (current_state)
			S_ERASE: 	erase <= 1'b1;
			S_NEW_NOTE: load 	<= 1'b1;
			S_FEED_RAM: feed 	<= 1'b1;
			S_DRAW: 		draw 	<= 1'b1;
			S_DISP_SCORE: score <= 1'b1;
			S_DISP_CORRECT: correct <= 1'b1;
			S_DISP_WRONG: wrong <= 1'b1;
			S_DISP_HIT: hit <= 1'b1;
			S_GAME_OVER: over <= 1'b1;
			S_GAME_OVER_SCORE: over_score <= 1'b1;
		endcase
	end
   
	always@(posedge clock)
	begin: state_FFs
		if(!resetn)
		begin
			current_state <= S_BEGIN;
		end
		else if (gameover)
			current_state <= S_GAME_OVER;
		else
		begin
			current_state <= next_state;
		end
	end
endmodule

module datapath(clock, erase, draw, feed, load, score, draw_background, draw_notes, feed_ram, display_score, done_new, song_address,
	over, draw_gameover, hit, correct, wrong, display_hit, display_correct, display_wrong, display_last_score, over_score);
	
	input clock, erase, draw, feed, load, score, over, hit, correct, wrong, over_score;
	output reg draw_background, draw_notes, feed_ram, done_new, display_score, draw_gameover, display_correct, display_wrong, display_hit,
		display_last_score;
	output reg [7:0] song_address;
	
	initial song_address = 8'b0;
	
	reg [4:0] note_count;
	initial note_count = 3'b0;
	
	always @(posedge clock)
	begin
		draw_background <= 1'b0;
		draw_notes <= 1'b0;
		feed_ram <= 1'b0;
		display_score <= 1'b0;
		display_correct <= 1'b0;
		display_wrong <= 1'b0;
		display_hit <= 1'b0;
		draw_gameover <= 1'b0;
		display_last_score <= 1'b0;
		if (erase)
			draw_background <= 1'b1;
		else if (draw)
			draw_notes <= 1'b1;
		else if (feed)
			feed_ram <= 1'b1;
		else if (score)
			display_score <= 1'b1;
		else if (correct)
			display_correct <= 1'b1;
		else if (wrong)
			display_wrong <= 1'b1;
		else if (hit)
			display_hit <= 1'b1;
		else if (over)
			draw_gameover <= 1'b1;
		else if (over_score)
			display_last_score <= 1'b1;
		else if (load)
		begin
			note_count <= note_count + 5'd1;
			if (note_count == 5'd13) // Height of note
			begin
				note_count <= 3'b0;
				done_new <= 1'b1;
				song_address <= song_address + 8'd1;
			end
			else done_new <= 1'b1;
		end
	end
	
endmodule

module load_notes(note, start_notes, resetn, clock, out_color, done_draw, final_x, final_y, note_plot, memory_address, last_note, remove, done_remove);
	
	input clock, resetn, start_notes, done_remove;
	input [4:0] note;
	output reg [8:0] out_color;
	output [9:0] final_x, final_y;
	output reg done_draw, remove, note_plot;
	output reg [4:0] last_note;
	
	reg [9:0] counter_x;
	output reg [7:0] memory_address;
	
	initial remove = 1'b0;
	
	reg note_bit, delay;
	reg [2:0] bit_counter; 
	reg [6:0] length;
	
//	always@(posedge clock)
//		note_bit <= note[4-bit_counter];
		
	always@(posedge clock)
	begin
		if (resetn && remove == 1'b0)
		begin
			delay <= 1'b0;
			last_note <= 5'b0;
			note_plot <= 1'b0;
			done_draw <= 1'b0;
			length <= 0;
			bit_counter <= 0;
			out_color <= 9'b0;
			counter_x <= 10'b0001010000; // leftmost x value of the notes container
			memory_address <= 8'b0;
		end
		
		else if (done_remove == 1'b1 && done_draw == 1'b0 && delay == 1'b0)
		begin
			remove <= 1'b0;
			done_draw <= 1'b1;
			delay <= 1'b1;
		end
		else if (done_remove == 1'b1 && done_draw == 1'b0 && delay == 1'b1)
		begin
			remove <= 1'b0;
			done_draw <= 1'b1;
			delay <= 1'b0;
		end
		else if (done_draw == 1'b0 && start_notes == 1'b1 && remove == 1'b0)
		begin
			note_plot <= 1'b0;
			//Modelsim:
//			if (memory_address == 8'd8)
//			begin
//				last_note <= note;
//				if (note != 5'b0) remove <= 1'b1;
//				else done_draw <= 1'b1;
//			end
			if (memory_address == 8'd190) // Max limit in height
			begin
				last_note <= note;
				if (note != 5'b0) remove <= 1'b1;
				else done_draw <= 1'b1;
			end
			else if (bit_counter == 3'd0) // enable stage
			begin
				length <= 0;
				counter_x <= 10'b0;
				if (note[4-bit_counter] == 1) // skip whole row
				begin
					memory_address <= memory_address + 1;
					bit_counter <= 3'd0;
				end
				else bit_counter <= bit_counter + 3'd1;
			end
			else
			begin
				if (bit_counter == 3'd1) out_color <= 9'b000000111; // Blue
				else if (bit_counter == 3'd2) out_color <= 9'b111000000; // Red
				else if (bit_counter == 3'd3) out_color <= 9'b000111000; // Green
				else if (bit_counter == 3'd4) out_color <= 9'b111111000; // Yellow
				
				if (note[4-bit_counter] == 1'b0) // skip note
				begin
					length <= 0;
					if (bit_counter != 3'd4)
					begin
						bit_counter <= bit_counter + 1;
						bit_counter <= bit_counter + 1;
						counter_x <= counter_x + 10'd32 + 10'd7; //10'd7 is the gap between the notes;
					end
					else 
					begin
						memory_address <= memory_address + 1;
						bit_counter <= 3'd0;
					end
				end
				
				else if (note[4-bit_counter] == 1'b1) // plot note
				begin
					if (length != 7'd32)
					begin
						note_plot <= 1'b1;
						counter_x <= counter_x + 1;
						length <= length + 1;
					end
					else if (length == 7'd32)
					begin
						length <= 0;
						if (bit_counter != 3'd4)
						begin
							counter_x <= counter_x + 10'd7;
							bit_counter <= bit_counter + 1;
						end
						else
						begin
							memory_address <= memory_address + 1;
							bit_counter <= 3'd0;
						end
					end
				end
			end
		end
			
	end
		
	assign final_x = counter_x + 10'b0001010000;
	assign final_y = memory_address + 10'd36;
endmodule

module note_to_ram(resetn, clock, enable, note_in, done, wren_out, rden_out, data_out, note_ram, mem_address);
	
	input [4:0] note_in, note_ram;
	input clock, enable, resetn;
	output reg done;
	output [4:0] data_out;
	output wren_out, rden_out;
	output [7:0] mem_address;
	
	wire [4:0] out;
	
	reg read, wren, rden, insert, read_stage;
	
	reg [4:0] data_in, delay;
	reg [7:0] wr;
	
	assign mem_address = wr;
	
	assign data_out = data_in;
	assign wren_out = wren;
	assign rden_out = rden;
	
	// HAVE TO ACCOUNT FOR PROPAGATION DELAYS!! (1 full clock cycle!)
	always@(posedge clock)
	begin
		if (resetn)
		begin
			read_stage <= 1'b0;
			insert <= 1'b0;
			done <= 1'b0;
			wren <= 1'b0;
			data_in <= note_in; // output from rd address
			wr <= 10'b0;
		end
		
		else if (enable && !done/* && counter*/)
		begin
			if (wr == 8'b0 && insert == 1'b0)
			begin
				rden <= 1'b1;
				insert <= 1'b1;
				wren <= 1'b1;
				data_in <= note_in;
				delay <= note_ram;
			end
			else if (wr != 8'd191 && read_stage)
			begin
				rden <= 1'b1;
				wr <= wr + 1;
				wren <= 1'b0;
				delay <= note_ram;
				read_stage <= ~read_stage;
			end
			else if (wr != 8'd191 && !read_stage)
			begin
				if (wr != 8'b0)
				begin
					rden <= 1'b0;
					wren <= 1'b1;
					data_in <= delay;
				end
				read_stage <= ~read_stage;
			end
			else
			begin
				wren <= 1'b0;
				done <= 1'b1;
			end
		end
		
	end
endmodule

module load_over(draw_background, resetn, clock, out_color, done_erase, erase_plot, final_x, final_y);
	
	input clock, resetn, draw_background;
	output reg [8:0] out_color; 
	output [10:0] final_x, final_y;
	output reg done_erase, erase_plot;
	
	reg [9:0] counter_x, counter_y, counter;
	reg [16:0] memory_address;
	
	wire [8:0] color_end;
	
	always@(posedge clock)
	begin
		if (resetn)
		begin
			erase_plot <= 1'b0;
			out_color <= 9'b0;
			done_erase <= 1'b0;
			counter_x <= 10'b0;
			counter_y <= 10'b0;
			memory_address <= 17'b0;
		end
			
		if (draw_background && !done_erase)
		begin
			erase_plot <= 1'b1;
			out_color <= color_end;
			memory_address <= memory_address + 1;
			if (counter_x < 10'd319)
				counter_x <= counter_x + 1;
			else if (counter_x == 10'd319 && counter_y < 10'd239)
			begin
				counter_x <= 10'b0;
				counter_y <= counter_y + 1;
			end
			else if (counter_x == 10'd319 && counter_y == 10'd239)
			begin
				erase_plot <= 1'b0;
				done_erase <= 1'b1;
			end
		end
		
	end
	assign final_x = counter_x - 11'd3;
	assign final_y = counter_y;
	
	gameover g0 (.address(memory_address), .clock(clock), .q(color_end));
endmodule

module load_background(draw_background, resetn, clock, out_color, done_erase, erase_plot, final_x, final_y);
	
	input clock, resetn, draw_background;
	output reg [8:0] out_color; 
	output [10:0] final_x, final_y;
	output reg done_erase, erase_plot;
	
	reg [9:0] counter_x, counter_y, counter;
	reg [16:0] memory_address;
	
	wire [8:0] color_play;
	
	always@(posedge clock)
	begin
		if (resetn)
		begin
			erase_plot <= 1'b0;
			out_color <= 9'b0;
			done_erase <= 1'b0;
			counter_x <= 10'b0;
			counter_y <= 10'b0;
			memory_address <= 17'b0;
		end
			
		if (draw_background && !done_erase)
		begin
			erase_plot <= 1'b1;
			out_color <= color_play;
			memory_address <= memory_address + 1;
			if (counter_x < 10'd319)
				counter_x <= counter_x + 1;
			else if (counter_x == 10'd319 && counter_y < 10'd239)
			begin
				counter_x <= 10'b0;
				counter_y <= counter_y + 1;
			end
			else if (counter_x == 10'd319 && counter_y == 10'd239)
			begin
				erase_plot <= 1'b0;
				done_erase <= 1'b1;
			end
		end
		
	end
	assign final_x = counter_x - 11'd3;
	assign final_y = counter_y;
	
	Background_ram b0 (.address(memory_address), .clock(clock), .data(9'b0), .wren(1'b0), .q(color_play));
	gameover g0 (.address(memory_address), .clock(clock), .q(color_end));
endmodule

module difficulty(data, out);
	input [1:0] data;
	output reg [25:0] out;
	
	always @(*) // declare always block
	begin
		case (data) // start case statement
			2'b00: out = 26'd2299999;//26'd12499999; // easy
			2'b01: out = 26'd1899999; // medium
			2'b10: out = 26'd1599999; // hard
			2'b11: out = 26'd1199999; // expert
			default: out = 26'd12499999; // default case
		endcase
	end
endmodule

module rate_divider(clock, load, enable, count);
	input [25:0] load;
	input clock, enable;
	output reg [25:0] count;
	
	always @(posedge clock)
	begin
		if (enable == 1'b0)
			count <= load;
		else if (count == 26'b0)
			count <= load;
		else count <= count - 1;
	end
endmodule

module hex_decoder(
    input [3:0] hex_digit, 
    output reg [6:0] segments
    );
   
    always @(*)
        case (hex_digit)
            4'h0: segments = 7'b100_0000;
            4'h1: segments = 7'b111_1001;
            4'h2: segments = 7'b010_0100;
            4'h3: segments = 7'b011_0000;
            4'h4: segments = 7'b001_1001;
            4'h5: segments = 7'b001_0010;
            4'h6: segments = 7'b000_0010;
            4'h7: segments = 7'b111_1000;
            4'h8: segments = 7'b000_0000;
            4'h9: segments = 7'b001_1000;
            4'hA: segments = 7'b000_1000;
            4'hB: segments = 7'b000_0011;
            4'hC: segments = 7'b100_0110;
            4'hD: segments = 7'b010_0001;
            4'hE: segments = 7'b000_0110;
            4'hF: segments = 7'b000_1110;   
            default: segments = 7'h7f;
        endcase
endmodule 