//`timescale 1ns/10ps

module main 

    (
        input wire [3:0] gpio_sense_pins,

        output wire [3:0] gpio_drive_pins,
        output reg gpio_sclk,            // serial clock
        output wire gpio_data_enable,    // data enable / chip select
        output wire gpio_sdo,            // serial data out
        output reg gpio_dclk            // digit clock
    );

    wire int_osc;
    reg [9:0] scnt;
    reg [10:0] dcnt;
    wire m_load_data;
    wire [3:0] m_num;
    wire [31:0] m_digits;
    wire m_conv_done;
    wire m_tran_done;
    
    SB_HFOSC u_SB_HFOSC(.CLKHFPU(1'b1), .CLKHFEN(1'b1), .CLKHF(int_osc));   // Código para FPGA

    always @(posedge int_osc) begin
        if (scnt >= 255) begin
            gpio_sclk <= ~gpio_sclk;
            scnt <= 0;
        end else begin
            scnt <= scnt + 1;
        end
    end

    always @(posedge int_osc) begin
        if (dcnt >= 2047) begin
            gpio_dclk <= ~gpio_dclk;
            dcnt <= 0;
        end else begin
            dcnt <= dcnt + 1;
        end
    end

    
    serial digit_spi(.load_data(gpio_dclk), .data_in(m_digits), .sclk(gpio_sclk),
        .data_enable(gpio_data_enable), .sdo(gpio_sdo), .tran_done(m_tran_done));

    int_seg conv(.num({10'd0, m_num}), .convert(m_load_data), .error(1'b0), .clk(gpio_sclk),
        .digits(m_digits), .conv_done(m_conv_done));

    keyboard keyb(.clk(gpio_sclk), .sense_pins(gpio_sense_pins),
        .drive_pins(gpio_drive_pins), .value(m_num), .intro(m_load_data));
endmodule