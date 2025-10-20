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

    // Synchronize load_data to sclk domain
    always @(posedge sclk) begin
        int_load_data <= load_data;
    end

    // Main data shifting logic
    always @(posedge sclk) begin
        // Load new data when detected
        if (int_load_data) begin
            data_enable <= 1;           // Enable transmission
            shift_reg <= data_in;
            shift_cnt <= 6'd32;         // Start from MSB
            //sdo <= data_in[31];         // Output first bit immediately
        end 
        // Shift out data when active
        else if (data_enable) begin
            if (shift_cnt > 0) begin
                sdo <= shift_reg[31];   // Output current MSB
                shift_reg <= shift_reg << 1;
                shift_cnt <= shift_cnt - 1;
            end
            else begin 
                // Transmission complete
                data_enable <= 0;
                sdo <= 0;
                shift_cnt <= 0;
            end
        end
        // Idle state
        else begin
            sdo <= 0;
        end
    end

endmodule