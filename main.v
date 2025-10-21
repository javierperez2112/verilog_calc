//`timescale 1ns/10ps

module main 

    (
        output reg gpio_sclk,            // serial clock
        output wire gpio_data_enable,    // data enable / chip select
        output wire gpio_sdo,            // serial data out
        output wire gpio_dclk            // digit clock
    );

    wire int_osc;
    reg [9:0] sclk_cnt;
    reg [9:0] cnt;
    reg m_load_data;
    wire [31:0] m_digits;
    wire m_conv_done;

    
    SB_HFOSC u_SB_HFOSC(.CLKHFPU(1'b1), .CLKHFEN(1'b1), .CLKHF(int_osc));   // Código para FPGA

    always @(posedge int_osc) begin
        if (sclk_cnt >= 255) begin
            gpio_sclk <= ~gpio_sclk;
            sclk_cnt <= 0;
            cnt <= cnt + 1;
            if (gpio_sclk == 0) begin
                if (cnt > 255) begin
                    m_load_data <= 1;
                    cnt <= 0;
                end else begin
                    cnt <= cnt + 1;
                    m_load_data <= 0;
                end
            end else begin end
        end else begin
            sclk_cnt <= sclk_cnt + 1;
        end
    end

    
    serial digit_spi(.load_data(m_conv_done), .data_in(m_digits), .sclk(gpio_sclk),
        .data_enable(gpio_data_enable), .sdo(gpio_sdo), .tran_done(gpio_dclk));

    int_seg conv(.num(14'd6942), .convert(m_load_data), .error(1'b0), .clk(gpio_sclk),
        .digits(m_digits), .conv_done(m_conv_done));
endmodule