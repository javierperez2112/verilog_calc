module int_seg

(
    // inputs
    input wire [13:0] num,      // number to convert to BCD
    input wire convert,         // start conversion signal
    input wire error,           // error signal
    input wire clk,             // clock

    // outputs
    output reg [31:0] digits,
    output reg conv_done
);

    localparam integer bruh = 32'h763D507C;     // error (bruh)

    reg [1:0] curr_state;
    reg [1:0] next_state;
    reg [3:0] i;

    parameter [1:0] IDLE = 2'b00;
    parameter [1:0] CONV = 2'b01;
    parameter [1:0] ERR = 2'b10;
    parameter [1:0] DEF = 2'b11;

    initial begin
        curr_state <= 0;
        next_state <= 0;
        i <= 0;
    end

    always @(curr_state, convert, error) begin
        case (curr_state) 
            IDLE: begin
                if (error) begin
                    next_state <= ERR;
                end else if (convert) begin
                    next_state <= CONV;
                    i <= 0;
                end
            end
            CONV: begin
                if (i < 14) begin
                    next_state <= CONV;
                end else if (i >=14) begin
                    next_state <= IDLE;
                end
            end
            ERR: begin
                next_state <= IDLE;
            end
            DEF: begin
                next_state <= IDLE;
            end
        endcase
    end

    always @(posedge clk) begin
        curr_state <= next_state;
    end

endmodule

/*

function [31:0] bin_bcd;    // binario (14 bits) -> BCD
        input [13:0] bin;
        reg [29:0] bcd_temp; // 16-bit BCD (4 digits * 4 bits) + 14-bit binary
        integer i;
        begin
            bcd_temp = 0;
            bcd_temp[13:0] = bin; // Place binary input at the bottom
            
            for (i = 0; i < 14; i = i + 1) begin
                // Check each BCD digit and add 3 if >= 5
                if (bcd_temp[17:14] >= 5) bcd_temp[17:14] = bcd_temp[17:14] + 3;
                if (bcd_temp[21:18] >= 5) bcd_temp[21:18] = bcd_temp[21:18] + 3;
                if (bcd_temp[25:22] >= 5) bcd_temp[25:22] = bcd_temp[25:22] + 3;
                if (bcd_temp[29:26] >= 5) bcd_temp[29:26] = bcd_temp[29:26] + 3;
                
                // Shift entire register left
                bcd_temp = bcd_temp << 1;
            end
            
            // Extract BCD digits and convert to 7-segment
            bin_bcd[7:0]   = get_segment(bcd_temp[17:14]); // digit 0
            bin_bcd[15:8]  = get_segment(bcd_temp[21:18]); // digit 1
            bin_bcd[23:16] = get_segment(bcd_temp[25:22]); // digit 2
            bin_bcd[31:24] = get_segment(bcd_temp[29:26]); // digit 3
        end
    endfunction

    function [7:0] get_segment;     // switch-case con valores del display
        input [3:0] bcd_digit;
        begin
            case (bcd_digit)
                4'd0: get_segment = 8'b00111111;    // 0;
                4'd1: get_segment = 8'b00000110;    // 1;
                4'd2: get_segment = 8'b01011011;    // 2;
                4'd3: get_segment = 8'b01001111;    // 3;
                4'd4: get_segment = 8'b01100110;    // 4;
                4'd5: get_segment = 8'b01101101;    // 5;
                4'd6: get_segment = 8'b01111101;    // 6;
                4'd7: get_segment = 8'b00000111;    // 7;
                4'd8: get_segment = 8'b01111111;    // 8;
                4'd9: get_segment = 8'b01101111;    // 9;
                default: get_segment = 8'b00111111; // 0;
            endcase
        end
    endfunction

    */