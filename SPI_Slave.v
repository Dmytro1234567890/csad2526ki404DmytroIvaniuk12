module SPI_Slave #(
    parameter CPOL = 0,
    parameter CPHA = 0
)(
    input  wire sck, // SPI шина
    input  wire cs, // SPI шина
    input  wire mosi, // SPI шина
    output reg  miso, // SPI шина
    output reg [7:0] recv_data //Отримані дані
);

    reg [7:0] tx_data;
    reg [2:0] bit_cnt;
    reg [7:0] rx_buffer;
    
    initial begin
        tx_data = 8'hA5;
        miso = 1'b0;
        bit_cnt = 3'd7;
        recv_data = 8'd0;
        rx_buffer = 8'd0;
    end

    generate
        if (CPOL == 0 && CPHA == 0) begin : mode_cpha0_cpol0
            
            // Ініціалізація при падінні CS (початок транзакції)
            always @(negedge cs) begin
                bit_cnt <= 3'd7;
                rx_buffer <= 8'd0;
                // Виставляємо перший біт MSB
                miso <= tx_data[7];
            end
            
            // Скидання при підйомі CS (кінець транзакції)
            always @(posedge cs) begin
                miso <= 1'b0;
                recv_data <= rx_buffer; // Зберігаємо отримані дані
            end
            
            // На наростаючому фронті SCK - читаємо MOSI (Master виставляє на спадаючому)
            always @(posedge sck) begin
                if (!cs) begin
                    // Записуємо біт у буфер
                    rx_buffer[bit_cnt] <= mosi;
                    
                    // Оновлюємо лічильник
                    if (bit_cnt == 3'd0)
                        bit_cnt <= 3'd7;
                    else
                        bit_cnt <= bit_cnt - 1'b1;
                end
            end
            
            // На спадаючому фронті SCK - виставляємо MISO для наступного біту
            always @(negedge sck) begin
                if (!cs) begin
                    // Виставляємо наступний біт
                    miso <= tx_data[bit_cnt];
                end
            end
            
        end else if (CPOL == 0 && CPHA == 1) begin : mode_cpha1_cpol0
            
            always @(negedge cs) begin
                bit_cnt <= 3'd7;
                rx_buffer <= 8'd0;
            end
            
            always @(posedge cs) begin
                miso <= 1'b0;
                recv_data <= rx_buffer;
            end
            
            // CPHA=1: виставляємо дані на naростаючому, читаємо на спадаючому
            always @(posedge sck) begin
                if (!cs) begin
                    miso <= tx_data[bit_cnt];
                    
                    if (bit_cnt == 3'd0)
                        bit_cnt <= 3'd7;
                    else
                        bit_cnt <= bit_cnt - 1'b1;
                end
            end
            
            always @(negedge sck) begin
                if (!cs) begin
                    rx_buffer[bit_cnt] <= mosi;
                end
            end
            
        end else if (CPOL == 1 && CPHA == 0) begin : mode_cpha0_cpol1
            
            always @(negedge cs) begin
                bit_cnt <= 3'd7;
                rx_buffer <= 8'd0;
                miso <= tx_data[7];
            end
            
            always @(posedge cs) begin
                miso <= 1'b0;
                recv_data <= rx_buffer;
            end
            
            // CPOL=1, CPHA=0: читаємо на спадаючому, виставляємо на naростаючому
            always @(negedge sck) begin
                if (!cs) begin
                    rx_buffer[bit_cnt] <= mosi;
                    
                    if (bit_cnt == 3'd0)
                        bit_cnt <= 3'd7;
                    else
                        bit_cnt <= bit_cnt - 1'b1;
                end
            end
            
            always @(posedge sck) begin
                if (!cs) begin
                    miso <= tx_data[bit_cnt];
                end
            end
            
        end else begin : mode_cpha1_cpol1
            
            always @(negedge cs) begin
                bit_cnt <= 3'd7;
                rx_buffer <= 8'd0;
            end
            
            always @(posedge cs) begin
                miso <= 1'b0;
                recv_data <= rx_buffer;
            end
            
            // CPOL=1, CPHA=1: виставляємо на спадаючому, читаємо на naростаючому
            always @(negedge sck) begin
                if (!cs) begin
                    miso <= tx_data[bit_cnt];
                    
                    if (bit_cnt == 3'd0)
                        bit_cnt <= 3'd7;
                    else
                        bit_cnt <= bit_cnt - 1'b1;
                end
            end
            
            always @(posedge sck) begin
                if (!cs) begin
                    rx_buffer[bit_cnt] <= mosi;
                end
            end
            
        end
    endgenerate

endmodule