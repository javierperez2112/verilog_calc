module keyboard

(
    input wire clk,
    input wire [3:0] sense_pins,

    output reg [3:0] drive_pins,
    output reg [3:0] value,
    output reg intro
);

    reg [1:0] drive_cnt;
    reg int_intro_prev;
    reg int_intro;

    always @(posedge clk) begin
        //int_intro_prev <= int_intro;
        //intro <= int_intro & (~int_intro_prev);
        drive_cnt <= drive_cnt + 1;
        drive_pins = 4'b1 << drive_cnt;
        if (sense_pins) begin
            intro <= 1;
            value <= 4*(sum_term(drive_pins)) + sum_term(sense_pins);
        end else begin
            intro <= 0;
        end
    end

    function [1:0] sum_term;
        input [3:0] sense;
        case (sense)
            4'd1: sum_term = 0;
            4'd2: sum_term = 1;
            4'd4: sum_term = 2;
            4'd8: sum_term = 3;
            default: sum_term = 0;
        endcase
    endfunction

endmodule