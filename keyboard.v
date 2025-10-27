module keyboard

    (
        input wire clk,
        input wire poll_clk,
        input wire [3:0] sense_pins,

        output reg [3:0] drive_pins,
        output reg [4:0] value,
        output reg intro    // key pressed flag
    );

    reg [1:0] drive_cnt;
    reg int_enable;
    reg prev_poll_clk;
    reg re_poll_clk;

    // operations
    parameter [4:0] PLUS    = 5'b10000;
    parameter [4:0] MINUS   = 5'b10001;
    parameter [4:0] BACKS   = 5'b10010;
    parameter [4:0] ENTER   = 5'b10011;
    parameter [4:0] UP      = 5'b10100;
    parameter [4:0] DOWN    = 5'b10101;
    parameter [4:0] NOP     = 5'b10110;

    always @(posedge clk) begin
        prev_poll_clk <= poll_clk;
        re_poll_clk <= poll_clk & (~prev_poll_clk);
        if (re_poll_clk) begin
            if (sense_pins) begin
                int_enable <= 0;
                intro <= 1;
                value <= out_val({drive_pins, sense_pins});
            end else begin
                drive_cnt <= drive_cnt + 1;
                drive_pins <= (4'b0001 << drive_cnt);
                int_enable <= 1;
                intro <= 0;
            end
        end
    end

    function [4:0] out_val;
        input [7:0] drive_sense;
        begin
        case (drive_sense)
            // numbers
            8'h82: out_val = 5'd0;
            8'h11: out_val = 5'd1;
            8'h12: out_val = 5'd2;
            8'h14: out_val = 5'd3;
            8'h21: out_val = 5'd4;
            8'h22: out_val = 5'd5;
            8'h24: out_val = 5'd6;
            8'h41: out_val = 5'd7;
            8'h42: out_val = 5'd8;
            8'h44: out_val = 5'd9;
            // operations
            8'h18: out_val = PLUS;
            8'h28: out_val = MINUS;
            8'h48: out_val = BACKS;
            8'h88: out_val = ENTER;
            8'h84: out_val = UP;
            8'h81: out_val = DOWN;
            default: out_val = NOP;
        endcase
        end
    endfunction

endmodule