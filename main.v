`timescale 1ns/10ps

module main 

    (
        output reg gpio_sclk,           // serial clock
        output wire gpio_data_enable,    // data enable / chip select
        output wire gpio_sdo,            // serial data out
        output wire gpio_dclk            // digit clock
    );

    reg int_osc;
    reg [9:0] sclk_cnt;
    reg [9:0] cnt;
    reg m_load_data;

    assign gpio_dclk = m_load_data;

    initial begin
        int_osc = 0;
        m_load_data = 0;
        gpio_sclk = 0;
        sclk_cnt = 0;
        cnt = 0;
    end

    // SB_HFOSC u_SB_HFOSC(.CLKHFPU(1'b1), .CLKHFEN(1'b1), .CLKHF(int_osc));   // Código para FPGA

    // Código para GTKwave

    initial begin
        $dumpfile("my_dumpfile.vcd");
        $dumpvars(0, main);
        #10000000 $finish;
    end

    always
        #5 int_osc = ~int_osc;

    // Código para todo

    always @(posedge int_osc) begin
        if (sclk_cnt > 255) begin
            gpio_sclk <= ~gpio_sclk;
            sclk_cnt <= 0;
            cnt <= cnt + 1;
            if (gpio_sclk == 1) begin
                if (cnt > 255) begin
                    m_load_data <= 1;
                    cnt <= 0;
                end else begin
                    cnt <= cnt + 1;
                    m_load_data <= 0;
                end
            end
        end else begin
            sclk_cnt <= sclk_cnt + 1;
        end
    end

    serial digit_spi(.load_data(m_load_data), .data_in(32'hF0F00F0F), .sclk(gpio_sclk),
        .data_enable(gpio_data_enable), .sdo(gpio_sdo));

endmodule