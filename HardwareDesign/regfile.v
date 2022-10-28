`timescale 1ns / 1ps
module regfile (
    input clk,  // 时钟
    input wen,  // 使能信号 1: 写; 0: 读
    input [4:0] raddr1,  // 读端口1地址
    input [4:0] raddr2,  // 读端口2地址
    input [4:0] waddr,  // 写端口地址
    input [31:0] wdata,  // 写数据
    output reg [31:0] rdata1,  // 读端口1数据
    output reg [31:0] rdata2,  // 读端口2数据

    // display rf
    input  [ 4:0] rf_addr,
    output [31:0] rf_data
);


  reg [31:0] regfile[31:0];
  initial begin
      regfile[0] <= 0;
  end


  always @(posedge clk) begin  // 写数据 同步
    if (wen) begin
      regfile[waddr] <= wdata;
    end
  end

  always @(*) begin  // 读数据 异步
  // always @(posedge clk) begin  // 读数据 同步
    if (raddr1 > 0 && raddr1 < 32) begin
      rdata1 <= regfile[raddr1];
    end else begin
      rdata1 <= 32'd0;
    end

    if (raddr2 > 0 && raddr2 < 32) begin
      rdata2 <= regfile[raddr2];
    end else begin
      rdata2 <= 32'd0;
    end
  end

  // display rf begin
  assign rf_data = regfile[rf_addr];
  // display rf end

endmodule
