// Send a 32 bit word throug SPI-like serial port. A pulse in load_data sends the content of data_in.

module serial
(
    // inputs
    input wire load_data,       // load data
    input wire [31:0] data_in,  // data in
    input wire sclk,            // serial clock

    // outputs
    output reg data_enable,     // data enable / chip select
    output reg sdo,             // serial data out
    output wire tran_done        // transmission done flag
);

    reg [31:0] shift_reg;
    reg [5:0] i;    // shift counter
    reg int_tran_done;

    assign tran_done = int_tran_done;

    reg curr_state;
    reg next_state;

    parameter IDLE = 1'b0;
    parameter TRAN = 1'b1;

    initial begin
        data_enable <= 0;
        sdo <= 0;
        shift_reg <= 0;
        i <= 0;
        curr_state <= IDLE;
        next_state <= IDLE;
        int_tran_done <= 0;
    end

    always @(curr_state, load_data, i) begin
        case (curr_state)
            IDLE: begin
                if (load_data) begin
                    next_state = TRAN;
                    shift_reg = data_in;
                    i = 0;
                end else begin
                    next_state = IDLE;
                end
            end
            TRAN: begin
                if (i < 31) begin 
                    next_state = TRAN;
                end else begin
                    next_state = IDLE;
                end
            end
        endcase
    end

    always @(negedge sclk) begin
        curr_state <= next_state;
        case (curr_state)
            TRAN: begin
                i <= i + 1;
                data_enable <= 1;
                sdo <= shift_reg[31];
                shift_reg <= shift_reg << 1;
            end
            IDLE: begin
                data_enable <= 0;
                sdo <= 0;
                i <= 0;
                int_tran_done <= (i == 32) ? 1 : 0;
            end
        endcase
    end

endmodule