module serial
(
    // inputs
    input wire load_data,       // load data
    input wire [31:0] data_in,  // data in
    input wire sclk,            // serial clock

    // outputs
    output reg data_enable,     // data enable / chip select
    output reg sdo,             // serial data out
    output wire tran_done       // transmission done flag
);

    reg [31:0] shift_reg;
    reg [5:0] i;
    reg int_tran_done;
    reg curr_state;

    assign tran_done = int_tran_done;

    parameter IDLE = 1'b0;
    parameter TRAN = 1'b1;

    always @(negedge sclk) begin
        case (curr_state)
            IDLE: begin
                data_enable <= 0;
                sdo <= 0;
                int_tran_done <= 0;
                if (load_data) begin
                    curr_state <= TRAN;
                    shift_reg <= data_in;
                    i <= 0;
                    data_enable <= 1;
                    sdo <= data_in[31];
                end
            end
            TRAN: begin
                if (i < 32) begin
                    sdo <= shift_reg[31];
                    shift_reg <= shift_reg << 1;
                    i <= i + 1;
                end else begin
                    int_tran_done <= 1;
                    curr_state <= IDLE;
                    data_enable <= 0;
                    sdo <= 0;
                end
            end
        endcase
    end

endmodule