module rpn_stack

(
    // inputs
    input wire clk,
    input wire [4:0] in_num,
    input wire intro,           // key pressed flag
    // outputs
    output reg [31:0] disp_num
);

    parameter sp_size = 4;
    parameter sp_max = (2 ** sp_size) - 1;
    parameter stack_array_size = (2**sp_size) * 16 - 1;
    localparam integer BRUH = 32'h763D507C;     // error (bruh)

    reg error;

    reg [15:0] stack [sp_max:0];
    reg [(sp_size - 1):0] sp;
    reg [1:0] dp;
    reg [(sp_size - 1):0] disp_p;

    // registers for BCD arithmetic

    reg [4:0] dig0;
    reg [4:0] dig1;
    reg [4:0] dig2;
    reg [4:0] dig3;
    reg [3:0] carry;
    reg start_op;

    initial begin
        sp <= 0;
        dp <= 0;
        disp_p <= 0;
        error <= 0;
    end

    // operations
    parameter [4:0] PLUS    = 5'b10000;
    parameter [4:0] MINUS   = 5'b10001;
    parameter [4:0] BACKS   = 5'b10010;
    parameter [4:0] ENTER   = 5'b10011;
    parameter [4:0] UP      = 5'b10100;
    parameter [4:0] DOWN    = 5'b10101;
    parameter [4:0] NOP     = 5'b10110;

    // state machine

    reg [1:0] curr_state;
    reg [1:0] next_state;

    parameter [1:0] IDLE  = 2'b00;
    parameter [1:0] INTR  = 2'b01;
    parameter [1:0] SUM   = 2'b10;
    parameter [1:0] SUBS  = 2'b11;

    parameter [3:0] NULL = 4'b1111;

    always @(posedge clk) begin
        curr_state <= next_state;

        case (curr_state)
            IDLE: begin
                if (intro) begin
                    next_state <= INTR;
                end else begin
                    next_state <= IDLE;
                end
            end
            INTR: begin
                error <= 0;
                if (in_num[4]) begin
                    case (in_num)
                        PLUS: begin
                            if (sp >= 1) begin 
                                start_op <= 1;
                                next_state <= SUM;
                            end else begin
                                next_state <= IDLE;
                            end
                        end
                        MINUS: begin
                            if (sp >= 1) begin 
                                next_state <= SUBS;
                            end else begin
                                next_state <= IDLE;
                            end
                        end
                        BACKS: begin
                            case (dp)
                                2'd0: stack[sp] <= stack[sp] & 16'hFFF0;    // clear 1 position
                                2'd1: stack[sp] <= stack[sp] & 16'hFF0F;    // clear 10 position
                                2'd2: stack[sp] <= stack[sp] & 16'hF0FF;    // clear 100 position
                                2'd3: stack[sp] <= stack[sp] & 16'h0FFF;    // clear 1000 position
                            endcase
                            dp <= (dp > 0) ? dp - 1 : dp;
                            next_state <= IDLE;
                        end
                        ENTER: begin
                            if (sp < sp_max) begin
                                stack[sp + 1] <= 16'b0;
                                sp <= sp + 1;
                                disp_p <= sp + 1;
                                dp <= 0;
                            end
                            next_state <= IDLE;
                        end
                        UP: begin
                            if (disp_p < sp) begin
                                disp_p <= disp_p + 1;
                            end
                        next_state <= IDLE;
                        end
                        DOWN: begin
                            if (disp_p > 0) begin
                                disp_p <= disp_p - 1;
                            end
                            next_state <= IDLE;
                        end
                        NOP: begin
                            next_state <= IDLE;
                        end
                        default: begin
                            next_state <= IDLE;
                        end
                    endcase
                end else begin
                    if ((in_num[3:0] < 10) & (dp != 3)) begin
                        case (dp)
                            2'd0: stack[sp] <= {12'b0, in_num[3:0]};                    // 1
                            2'd1: stack[sp] <= {stack[sp][15:12], 8'b0, in_num[3:0]};   // 10
                            2'd2: stack[sp] <= {stack[sp][15:8], 4'b0, in_num[3:0]};    // 100
                            2'd3: stack[sp] <= {stack[sp][15:4], in_num[3:0]};          // 1000
                        endcase
                        dp <= dp + 1;
                        disp_p <= sp;
                    end
                    next_state <= IDLE;
                end
            end
            SUM: begin
                if (start_op) begin
                    dig0 <= stack[sp][3:0] + stack[sp-1][3:0];
                    dig1 <= stack[sp][7:4] + stack[sp-1][7:4];
                    dig2 <= stack[sp][11:8] + stack[sp-1][11:8];
                    dig3 <= stack[sp][15:12] + stack[sp-1][15:12];
                    start_op <= 0;
                    carry <= 0;
                    next_state <= SUM;
                end else begin
                    
                    dig1 <= dig1 + carry[0];
                    dig2 <= dig2 + carry[1];
                    dig3 <= dig3 + carry[2];

                    // 1 digit
                    if (dig0 > 9) begin
                        dig0 <= dig0 - 10;
                        carry[0] <= 1;
                    end else begin
                        carry[0] <= 0;
                    end
                    // 10 digit
                    if (dig1 > 9) begin
                        dig1 <= dig1 - 10;
                        carry[1] <= 1;
                    end else begin
                        carry[1] <= 0;
                    end
                    // 100 digit
                    if (dig2 > 9) begin
                        dig2 <= dig2 - 10;
                        carry[2] <= 1;
                    end else begin
                        carry[2] <= 0;
                    end
                    // 1000 digit
                    if (dig3 > 9) begin
                        dig3 <= dig3 - 10;
                        carry[3] <= 1;
                    end else begin
                        carry[3] <= 0;
                    end
                    // state logic
                    if (carry == 0) begin
                        stack[sp - 1] <= {dig3, dig2, dig1, dig0};
                        stack[sp] <= 0;
                        sp <= sp - 1;
                        disp_p <= sp - 1;
                        next_state <= IDLE;
                    end else if (carry[3]) begin
                        error <= 1;
                        next_state <= IDLE;
                    end else begin
                        next_state <= SUM;
                    end
                end
            end
            SUBS: begin
                next_state <= IDLE;
            end
        endcase
    end

    always @(posedge clk) begin
        if (error) begin
            disp_num[7:0]   <= get_segment(stack[disp_p][15:12]);  // 1000
            disp_num[15:8]  <= get_segment(stack[disp_p][11:8]);   // 100  
            disp_num[23:16] <= get_segment(stack[disp_p][7:4]);    // 10
            disp_num[31:24] <= get_segment(stack[disp_p][3:0]);    // 1
        end else begin
            disp_num <= BRUH;
        end
    end

    function [7:0] get_segment;     // switch-case con valores del display
        input [3:0] bcd_digit;
        begin
            case (bcd_digit)
                4'd0: get_segment       = 8'b00111111;      // 0;
                4'd1: get_segment       = 8'b00000110;      // 1;
                4'd2: get_segment       = 8'b01011011;      // 2;
                4'd3: get_segment       = 8'b01001111;      // 3;
                4'd4: get_segment       = 8'b01100110;      // 4;
                4'd5: get_segment       = 8'b01101101;      // 5;
                4'd6: get_segment       = 8'b01111101;      // 6;
                4'd7: get_segment       = 8'b00000111;      // 7;
                4'd8: get_segment       = 8'b01111111;      // 8;
                4'd9: get_segment       = 8'b01101111;      // 9;
                NULL: get_segment       = 8'b00000000;      // null
                default: get_segment    = 8'b00000000;      // null;
            endcase
        end
    endfunction

endmodule