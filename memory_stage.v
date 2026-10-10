`timescale 1ns/1ps

//==============================================================================
// MEM stage  (data memory + MEM/WB register)
//==============================================================================
module memory_stage (
    input         clk, rst_n,
    input         reg_write_M, mem_write_M, result_src_M,
    input  [4:0]  rd_M,
    input  [31:0] write_data_M, alu_result_M,
    output        reg_write_W, result_src_W,
    output [4:0]  rd_W,
    output [31:0] alu_result_W, read_data_W
);
    wire [31:0] read_data_M;

    data_memory u_dmem (.clk(clk), .we(mem_write_M), .addr(alu_result_M),
                        .wdata(write_data_M), .rdata(read_data_M));

    reg        reg_write_r, result_src_r;
    reg [4:0]  rd_r;
    reg [31:0] alu_result_r, read_data_r;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_write_r <= 1'b0;  result_src_r <= 1'b0;
            rd_r <= 5'd0;  alu_result_r <= 32'h0;  read_data_r <= 32'h0;
        end else begin
            reg_write_r <= reg_write_M;  result_src_r <= result_src_M;
            rd_r <= rd_M;  alu_result_r <= alu_result_M;  read_data_r <= read_data_M;
        end
    end

    assign reg_write_W  = reg_write_r;   assign result_src_W = result_src_r;
    assign rd_W         = rd_r;
    assign alu_result_W = alu_result_r;  assign read_data_W  = read_data_r;
endmodule
