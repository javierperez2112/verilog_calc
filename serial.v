// Send a 32 bit word throug SPI-like serial port. A pulse in load_data sends the content of data_in.

module serial
(
    // inputs
    input wire load_data,       // load data
    input wire [31:0] data_in,  // data in
    input wire sclk,            // serial clock
    
    // outputs
    output reg data_enable,     // data enable / chip select
    output reg sdo              // serial data out
);

    reg [31:0] shift_reg;
    reg int_load_data;      // internal load data
    reg [5:0] shift_cnt;    // shift counter

    // Initialize registers
    initial begin
        data_enable <= 0;
        sdo <= 0;
        shift_reg <= 0;
        shift_cnt <= 0;
        int_load_data <= 0;
    end

    // load_data -> int_load_data
    always @(posedge sclk) begin
        int_load_data <= load_data;
    end

    always @(posedge sclk) begin
        // cargar data_in
        if (int_load_data) begin
            data_enable <= 1;    
            shift_reg <= data_in;
            shift_cnt <= 6'd32;
            sdo <= data_in[31];
        end 
        // transmitir mientras data_enable = 1
        else if (data_enable) begin
            if (shift_cnt > 1) begin
                sdo <= shift_reg[30];   // esto huele a negrada
                shift_reg <= shift_reg << 1;
                shift_cnt <= shift_cnt - 1;
            end
            else begin 
                // transmisión completa
                data_enable <= 0;
                sdo <= 0;
                shift_cnt <= 0;
                shift_reg <= 32'd0;
            end
        end
        // idle
        else begin
            sdo <= 0;
        end
    end

endmodule