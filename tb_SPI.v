`timescale 1ns/1ps

module tb_SPI;
    reg clk = 0;
    reg rst = 0;
    reg start = 0;
    reg [7:0] mosi_data = 8'h00;
    wire [7:0] miso_data;
    wire done;
    wire sck, mosi, miso, cs;
    wire [7:0] slave_recv;

    always #5 clk = ~clk;

    SPI_Master #(.CPOL(0), .CPHA(0), .CLK_DIV(8)) master (
        .clk(clk), .rst(rst), .start(start),
        .mosi_data(mosi_data), .miso_data(miso_data), .done(done),
        .sck(sck), .mosi(mosi), .miso(miso), .cs(cs)
    );

    SPI_Slave #(.CPOL(0), .CPHA(0)) slave (
        .sck(sck), .cs(cs), .mosi(mosi), .miso(miso),
        .recv_data(slave_recv)
    );

    initial begin
        $dumpfile("spi_wave.vcd");
        $dumpvars(0, tb_SPI);
        
        $display("========================================");
        $display("SPI Test Started");
        $display("========================================");

        // Reset
        rst = 1;
        #50;
        rst = 0;
        #20;

        // Test 1: Send 0x3C
        $display("\nTest 1: Sending 0x3C");
        mosi_data = 8'h3C;
        start = 1;
        #10;
        start = 0;

        wait(done);
        #100;

        $display("Master sent:     0x%h", 8'h3C);
        $display("Slave received:  0x%h", slave_recv);
        $display("Master received: 0x%h", miso_data);
        
        if (slave_recv == 8'h3C)
            $display("[PASS] Slave RX correct");
        else
            $display("[FAIL] Slave RX wrong!");
            
        if (miso_data == 8'hA5)
            $display("[PASS] Master RX correct");
        else
            $display("[FAIL] Master RX wrong!");

        // Test 2: Send 0xFF
        #100;
        $display("\nTest 2: Sending 0xFF");
        mosi_data = 8'hFF;
        start = 1;
        #10;
        start = 0;

        wait(done);
        #100;

        $display("Slave received:  0x%h", slave_recv);
        if (slave_recv == 8'hFF)
            $display("[PASS] Test 2 passed");
        else
            $display("[FAIL] Test 2 failed");

        #200;
        $display("\n========================================");
        $display("Tests completed");
        $display("========================================");
        $finish;
    end

endmodule