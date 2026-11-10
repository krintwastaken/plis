`timescale 1ns / 1ps

module index_counter #(
    parameter integer WIDTH = 4
)(
    input wire clk,
    input wire reset,
    input wire load,
    input wire en_count,
    input wire [WIDTH-1:0] data_load,
    input wire [WIDTH-1:0] max_len,
    output reg [WIDTH-1:0] count,
    output wire over
);

    // Немедленный пересчет флага достижения конца последовательности
    assign over = (max_len == {WIDTH{1'b0}}) ? 1'b1 : (count >= (max_len - 1'b1));

    always @(posedge clk) begin
        if (reset) begin
            count <= {WIDTH{1'b0}};
        end else if (load) begin
            count <= data_load;
        end else if (en_count) begin
            if (max_len == {WIDTH{1'b0}}) begin
                count <= {WIDTH{1'b0}};
            end else if (count < (max_len - 1'b1)) begin
                count <= count + 1'b1;
            end
        end
    end

endmodule
