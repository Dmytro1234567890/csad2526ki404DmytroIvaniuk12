module SPI_Master #(
    parameter CPOL = 0,
    parameter CPHA = 0,
    parameter CLK_DIV = 4
)(
    input  wire clk, // Системний тактовий сигнал
    input  wire rst, // Сигнал скидання
    input  wire start, // Команда "почати передачу"
    input  wire [7:0] mosi_data, // Дані для передачі
    output reg  [7:0] miso_data, // Дані, які отримав Master
    output reg  done, // Сигнал "передача завершена"
    output reg  sck, // SPI шина
    output reg  mosi, // SPI шина
    input  wire miso, // SPI шина
    output reg  cs // SPI шина
);

    reg [7:0] tx_shift;
    reg [7:0] rx_shift;
    reg [2:0] bit_cnt;
    reg [15:0] clk_cnt;
    reg sck_en;
    reg sck_int;
    reg sck_edge;
    
    localparam [1:0] IDLE = 2'b00;
    localparam [1:0] TRANSFER = 2'b01;
    localparam [1:0] DONE_ST = 2'b10;
    
    reg [1:0] state;

    // Дільник тактової частоти для SCK
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            clk_cnt <= 16'd0;
            sck_int <= CPOL;
            sck_edge <= 1'b0;
        end else if (sck_en) begin
            if (clk_cnt == CLK_DIV - 1) begin
                clk_cnt <= 16'd0;
                sck_int <= ~sck_int;
                sck_edge <= 1'b1;
            end else begin
                clk_cnt <= clk_cnt + 1'b1;
                sck_edge <= 1'b0;
            end
        end else begin
            sck_int <= CPOL;
            sck_edge <= 1'b0;
            clk_cnt <= 16'd0;
        end
    end

    always @(*) begin
        sck = sck_int;
    end

    // Основна машина станів - CPOL=0, CPHA=0
    generate
        if (CPOL == 0 && CPHA == 0) begin : mode_cpha0_cpol0
            
            always @(posedge clk or posedge rst) begin
                if (rst) begin
                    state <= IDLE;
                    cs <= 1'b1;
                    done <= 1'b0;
                    sck_en <= 1'b0;
                    bit_cnt <= 3'd0;
                    mosi <= 1'b0;
                    tx_shift <= 8'd0;
                    rx_shift <= 8'd0;
                    miso_data <= 8'd0;
                end else begin
                    case (state)
                        IDLE: begin
                            done <= 1'b0;
                            cs <= 1'b1;
                            sck_en <= 1'b0;
                            
                            if (start) begin
                                tx_shift <= mosi_data;
                                rx_shift <= 8'd0;
                                bit_cnt <= 3'd7;
                                
                                // CPHA=0: виставляємо перший біт до активації CS
                                mosi <= mosi_data[7];
                                
                                cs <= 1'b0;
                                sck_en <= 1'b1;
                                state <= TRANSFER;
                            end
                        end

                        TRANSFER: begin
                            if (sck_edge) begin
                                if (sck_int == 1'b1) begin
                                    // Наростаючий фронт - читаємо MISO
                                    rx_shift[bit_cnt] <= miso;
                                    
                                    if (bit_cnt == 3'd0) begin
                                        // Передача завершена
                                        sck_en <= 1'b0;
                                        miso_data <= {rx_shift[7:1], miso};
                                        done <= 1'b1;
                                        state <= DONE_ST;
                                    end else begin
                                        bit_cnt <= bit_cnt - 1'b1;
                                    end
                                end else begin
                                    // Спадаючий фронт - виставляємо MOSI
                                    mosi <= tx_shift[bit_cnt];
                                end
                            end
                        end

                        DONE_ST: begin
                            cs <= 1'b1;
                            done <= 1'b0;
                            state <= IDLE;
                        end
                        
                        default: state <= IDLE;
                    endcase
                end
            end
            
        end else if (CPOL == 0 && CPHA == 1) begin : mode_cpha1_cpol0
            
            always @(posedge clk or posedge rst) begin
                if (rst) begin
                    state <= IDLE;
                    cs <= 1'b1;
                    done <= 1'b0;
                    sck_en <= 1'b0;
                    bit_cnt <= 3'd0;
                    mosi <= 1'b0;
                    tx_shift <= 8'd0;
                    rx_shift <= 8'd0;
                    miso_data <= 8'd0;
                end else begin
                    case (state)
                        IDLE: begin
                            done <= 1'b0;
                            cs <= 1'b1;
                            sck_en <= 1'b0;
                            mosi <= 1'b0;
                            
                            if (start) begin
                                tx_shift <= mosi_data;
                                rx_shift <= 8'd0;
                                bit_cnt <= 3'd7;
                                cs <= 1'b0;
                                sck_en <= 1'b1;
                                state <= TRANSFER;
                            end
                        end

                        TRANSFER: begin
                            if (sck_edge) begin
                                if (sck_int == 1'b1) begin
                                    // Наростаючий фронт - виставляємо MOSI
                                    mosi <= tx_shift[bit_cnt];
                                end else begin
                                    // Спадаючий фронт - читаємо MISO
                                    rx_shift[bit_cnt] <= miso;
                                    
                                    if (bit_cnt == 3'd0) begin
                                        sck_en <= 1'b0;
                                        miso_data <= {rx_shift[7:1], miso};
                                        done <= 1'b1;
                                        state <= DONE_ST;
                                    end else begin
                                        bit_cnt <= bit_cnt - 1'b1;
                                    end
                                end
                            end
                        end

                        DONE_ST: begin
                            cs <= 1'b1;
                            done <= 1'b0;
                            state <= IDLE;
                        end
                        
                        default: state <= IDLE;
                    endcase
                end
            end
            
        end else begin : mode_cpol1
            
            always @(posedge clk or posedge rst) begin
                if (rst) begin
                    state <= IDLE;
                    cs <= 1'b1;
                    done <= 1'b0;
                    sck_en <= 1'b0;
                    bit_cnt <= 3'd0;
                    mosi <= 1'b0;
                    tx_shift <= 8'd0;
                    rx_shift <= 8'd0;
                    miso_data <= 8'd0;
                end else begin
                    state <= IDLE;
                end
            end
            
        end
    endgenerate

endmodule