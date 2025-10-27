module rpn_stack

    (
        // inputs
        input wire clk,
        input wire [4:0] in_num,
        input wire intro,           // key pressed flag
        // outputs
        output reg [31:0] disp_num,
        output reg test
    );

    parameter sp_size = 4;
    parameter sp_max = 15;
    localparam integer BRUH = 32'h741C507C;     // error (bruh)

    reg error;
    reg intro_prev;
    reg [4:0] int_num;

    reg [15:0] stack [sp_max:0];
    reg [(sp_size - 1):0] sp;
    reg [1:0] dp;
    reg [(sp_size - 1):0] disp_p;

    // registers for BCD arithmetic

    reg [4:0] dig0;
    reg [4:0] dig1;
    reg [4:0] dig2;
    reg [4:0] dig3;
    reg [3:0] disp_zeros;
    reg [3:0] carry;

    initial begin
        sp <= 0;
        dp <= 0;
        disp_p <= 0;
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

    parameter [1:0] IDLE  = 2'b00;
    parameter [1:0] INTR  = 2'b01;
    parameter [1:0] SUM   = 2'b10;
    parameter [1:0] SUBS  = 2'b11;

    parameter [3:0] NULL = 4'b1111;

    always @(posedge clk) begin
        intro_prev <= intro;
        test <= intro && (~intro_prev);

        case (curr_state)
            IDLE: begin
                if (intro && (~intro_prev)) begin
                    curr_state <= INTR;
                    int_num <= in_num;
                end else begin
                    curr_state <= IDLE;
                end
            end
            INTR: begin
                if (~error) begin
                    if (int_num[4]) begin
                        case (int_num)
                            PLUS: begin     // nigga
                                if (sp >= 1) begin 
                                    if (stack[sp]) begin    // sum current number if != 0
                                        dig0 <= stack[sp][3:0] + stack[sp-1][3:0];
                                        dig1 <= stack[sp][7:4] + stack[sp-1][7:4];
                                        dig2 <= stack[sp][11:8] + stack[sp-1][11:8];
                                        dig3 <= stack[sp][15:12] + stack[sp-1][15:12];
                                        carry <= 4'd0;
                                        curr_state <= SUM;
                                    end else if (sp >= 2) begin // sum previous numbers if == 0
                                        dig0 <= stack[sp-1][3:0] + stack[sp-2][3:0];
                                        dig1 <= stack[sp-1][7:4] + stack[sp-2][7:4];
                                        dig2 <= stack[sp-1][11:8] + stack[sp-2][11:8];
                                        dig3 <= stack[sp-1][15:12] + stack[sp-2][15:12];
                                        // pop current (0) from stack
                                        sp <= sp - 1;
                                        disp_p <= sp - 1;
                                        carry <= 4'd0;
                                        curr_state <= SUM;
                                    end else begin  // or return same as sp-1 if current==0 and there arent enough nums
                                        sp <= sp - 1;
                                        disp_p <= sp - 1;
                                        curr_state <= IDLE;
                                    end
                                end else begin
                                    curr_state <= IDLE;
                                end
                            end
                            MINUS: begin    // nigga
                                if (sp >= 1) begin 
                                    if (stack[sp]) begin    // substract current number if != 0
                                        dig0 <= stack[sp-1][3:0] - stack[sp][3:0];
                                        dig1 <= stack[sp-1][7:4] - stack[sp][7:4];
                                        dig2 <= stack[sp-1][11:8] - stack[sp][11:8];
                                        dig3 <= stack[sp-1][15:12] - stack[sp][15:12];
                                        carry <= 4'd0;
                                        curr_state <= SUBS;
                                    end else if (sp >= 2) begin // substract previous numbers if == 0
                                        dig0 <= stack[sp-2][3:0] - stack[sp-1][3:0];
                                        dig1 <= stack[sp-2][7:4] - stack[sp-1][7:4];
                                        dig2 <= stack[sp-2][11:8] - stack[sp-1][11:8];
                                        dig3 <= stack[sp-2][15:12] - stack[sp-1][15:12];
                                        // pop current (0) from stack
                                        sp <= sp - 1;
                                        disp_p <= sp - 1;
                                        carry <= 4'd0;
                                        curr_state <= SUBS;
                                    end else begin  // or return same as sp-1 if current==0 and there arent enough nums
                                        sp <= sp - 1;
                                        disp_p <= sp - 1;
                                        curr_state <= IDLE;
                                    end
                                end else begin
                                    curr_state <= IDLE;
                                end
                            end
                            BACKS: begin
                                if (stack[sp] == 16'd0) begin
                                    if (sp > 0) begin
                                        sp <= sp - 1;
                                        disp_p <= sp - 1;
                                    end else begin
                                        sp <= sp;
                                        disp_p <= sp;
                                    end
                                end else begin
                                    stack[sp] <= {4'd0 ,stack[sp][15:4]};
                                    sp <= sp;
                                    disp_p <= sp;
                                end
                                curr_state <= IDLE;
                            end
                            ENTER: begin
                                if ((sp < sp_max) && (stack[sp] != 0)) begin
                                    stack[sp + 1] <= 16'b0;
                                    sp <= sp + 1;
                                    disp_p <= sp + 1;
                                end else if (sp == sp_max) begin
                                    error <= 1;
                                end
                                curr_state <= IDLE;
                            end
                            DOWN: begin
                                if (disp_p < sp) begin
                                    disp_p <= disp_p + 1;
                                end
                            curr_state <= IDLE;
                            end
                            UP: begin
                                if (disp_p > 0) begin
                                    disp_p <= disp_p - 1;
                                end
                                curr_state <= IDLE;
                            end
                            NOP: begin
                                curr_state <= IDLE;
                            end
                            default: begin
                                curr_state <= IDLE;
                            end
                        endcase
                    end else begin
                        if (int_num[3:0] < 10) begin
                            if (dp < 3) begin
                                stack[sp] <= {stack[sp][11:0], int_num[3:0]};
                            end else begin
                                if (stack[sp][15:12] == 4'd0) begin
                                    stack[sp] <= {stack[sp][11:0], int_num[3:0]};
                                end
                            end
                            disp_p <= sp;
                        end
                        curr_state <= IDLE;
                    end
                end else begin
                    error <= 0;
                    curr_state <= IDLE;
                end
            end 
            SUM: begin
                dig1 = dig1 + carry[0];
                dig2 = dig2 + carry[1];
                dig3 = dig3 + carry[2];

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
                if ((dig0<10) && (dig1<10) && (dig2<10) && (dig3<10)) begin
                    stack[sp - 1] <= {dig3[3:0], dig2[3:0], dig1[3:0], dig0[3:0]};
                    stack[sp] <= 0;
                    sp <= sp - 1;
                    disp_p <= sp - 1;
                    curr_state <= IDLE;
                end else if (carry[3] || (dig3 > 9)) begin
                    error <= 1;
                    curr_state <= IDLE;
                end else begin
                    curr_state <= SUM;
                end
            end
            SUBS: begin
                dig1 = dig1 - carry[0];
                dig2 = dig2 - carry[1];
                dig3 = dig3 - carry[2];

                // 1 digit
                if (dig0[4]) begin
                    dig0 <= dig0 + 10;
                    carry[0] <= 1;
                end else begin
                    carry[0] <= 0;
                end
                // 10 digit
                if (dig1[4]) begin
                    dig1 <= dig1 + 10;
                    carry[1] <= 1;
                end else begin
                    carry[1] <= 0;
                end
                // 100 digit
                if (dig2[4]) begin
                    dig2 <= dig2 + 10;
                    carry[2] <= 1;
                end else begin
                    carry[2] <= 0;
                end
                // 1000 digit
                if (dig3[4]) begin
                    dig3 <= dig3 + 10;
                    carry[3] <= 1;
                end else begin
                    carry[3] <= 0;
                end
                // state logic
                if ((~dig0[4]) && (~dig1[4]) && (~dig2[4]) && (~dig3[4])) begin
                    stack[sp - 1] <= {dig3[3:0], dig2[3:0], dig1[3:0], dig0[3:0]};
                    stack[sp] <= 0;
                    sp <= sp - 1;
                    disp_p <= sp - 1;
                    curr_state <= IDLE;
                end else if (carry[3] || (dig3[4])) begin
                    error <= 1;
                    curr_state <= IDLE;
                end else begin
                    curr_state <= SUBS;
                end
            end
        endcase
    end

    always @(posedge clk) begin
        if (error) begin
            disp_num <= BRUH;
        end else begin
            disp_num[7:0]   <= (disp_zeros[3]) ? 8'd0 : get_segment(stack[disp_p][15:12]);  // 1000
            disp_num[15:8]  <= (disp_zeros[2]) ? 8'd0 : get_segment(stack[disp_p][11:8]);   // 100  
            disp_num[23:16] <= (disp_zeros[1]) ? 8'd0 : get_segment(stack[disp_p][7:4]);    // 10
            disp_num[31:24] <= get_segment(stack[disp_p][3:0]);                             // 1
            if (disp_p ^ sp) begin
                disp_num[31] <= 1'd1;   // turn on last dot when disp_p != sp
            end
        end
    end

    always @(posedge clk) begin
        disp_zeros[3] <= (stack[disp_p][15:12] == 4'd0);
        disp_zeros[2] <= (stack[disp_p][11:8] == 4'd0) & (stack[disp_p][15:12] == 4'd0);
        disp_zeros[1] <= (stack[disp_p][7:4] == 4'd0) & (stack[disp_p][11:8] == 4'd0) & (stack[disp_p][15:12] == 4'd0);
        disp_zeros[0] <= (stack[disp_p][3:0] == 4'd0) & (stack[disp_p][7:4] == 4'd0) & (stack[disp_p][15:12] == 4'd0) & (stack[disp_p][11:8] == 4'd0);
        if (disp_zeros[0]) begin
            dp <= 0;
        end else if (disp_zeros[1]) begin
            dp <= 1;
        end else if (disp_zeros[2]) begin
            dp <= 2;
        end else begin
            dp <= 3;
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