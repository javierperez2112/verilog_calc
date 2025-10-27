//`timescale 1ns/10ps

module main 

    (
        // inputs
        input wire [3:0] gpio_sense_pins,
        input wire int_osc,             // oscilador no gay
        // outputs
        output wire [3:0] gpio_drive_pins,
        output reg gpio_sclk,            // serial clock
        output wire gpio_data_enable,    // data enable / chip select
        output wire gpio_sdo,            // serial data out
        output reg gpio_dclk,            // digit clock
        output wire test_intr
    );

    reg [15:0] scnt;
    reg [15:0] dcnt;
    reg [15:0] pcnt;
    wire m_load_data;
    wire [4:0] m_num;
    wire [31:0] m_digits;
    wire m_conv_done;
    wire m_tran_done;
    wire m_intro;
    reg pclk;

    assign test_intr = m_intro;
    
    // SB_HFOSC u_SB_HFOSC(.CLKHFPU(1'b1), .CLKHFEN(1'b1), .CLKHF(int_osc));   // oscilador gay

    // serial & digit clocks

    always @(posedge int_osc) begin     // serial clock
        if (scnt >= 255) begin
            gpio_sclk <= ~gpio_sclk;
            scnt <= 0;
        end else begin
            scnt <= scnt + 1;
        end
    end

    always @(posedge int_osc) begin     // digit clock
        if (dcnt >= 4095) begin
            gpio_dclk <= ~gpio_dclk;
            dcnt <= 0;
        end else begin
            dcnt <= dcnt + 1;
        end
    end

    always @(posedge int_osc) begin     // polling clock
        if (pcnt >= 1023) begin
            pclk <= ~pclk;
            pcnt <= 0;
        end else begin
            pcnt <= pcnt + 1;
        end
    end

    // module instances
    
    serial digit_spi(.load_data(gpio_dclk), .data_in(m_digits), .sclk(gpio_sclk), .clk(int_osc),
        .data_enable(gpio_data_enable), .sdo(gpio_sdo), .tran_done(m_tran_done));

    rpn_stack calculator(.clk(int_osc), .in_num(m_num), .intro(m_intro),
        .disp_num(m_digits));

    keyboard keyb(.clk(int_osc), .poll_clk(pclk), .sense_pins(gpio_sense_pins),
        .drive_pins(gpio_drive_pins), .value(m_num), .intro(m_intro));

endmodule