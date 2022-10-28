`timescale 1ns / 1ps
module data_ram (  // 数据存储模块 同步读写
    input clk,  // 时钟
    input [3:0] wen,  // 字节写使能
    input [4:0] addr,  // 地址
    input [31:0] wdata,  // 写数据
    output reg [31:0] rdata,  // 读数据

    //调试端口，用于读出数据显示
    input clka,
    input [3:0] wea,
    input [7:0] addra,
    output reg [31:0] rdataa,
    input [31:0] wdataa
    // input [4:0] test_addr,
    // output reg [31:0] test_data
);
  reg [31:0] DM[31:0];  //数据存储器 字节地址 7'b000_0000~7'b111_1111 可以存32个整数
  integer i;
  initial begin // 32个整数分别为:1,2,3,...,31,32
    for( i = 0; i < 32; i = i + 1)
        begin
            DM[i] = i + 1;
        end
  end

  //写数据 begin
  always @(posedge clk) begin  // 当写控制信号为1 数据写入内存
    if (wen[3]) begin
      DM[addr][31:24] <= wdata[31:24];
    end
  end
  always @(posedge clk) begin
    if (wen[2]) begin
      DM[addr][23:16] <= wdata[23:16];
    end
  end
  always @(posedge clk) begin
    if (wen[1]) begin
      DM[addr][15:8] <= wdata[15:8];
    end
  end
  always @(posedge clk) begin
    if (wen[0]) begin
      DM[addr][7:0] <= wdata[7:0];
    end
  end
  // 写数据 end


  // 读数据 取4字节 
  always @(posedge clk) begin  // 当写控制信号为0 数据读出内存
    if (wen == 4'b0) begin
      case (addr)
        5'd0:  rdata <= DM[0];
        5'd1:  rdata <= DM[1];
        5'd2:  rdata <= DM[2];
        5'd3:  rdata <= DM[3];
        5'd4:  rdata <= DM[4];
        5'd5:  rdata <= DM[5];
        5'd6:  rdata <= DM[6];
        5'd7:  rdata <= DM[7];
        5'd8:  rdata <= DM[8];
        5'd9:  rdata <= DM[9];
        5'd10: rdata <= DM[10];
        5'd11: rdata <= DM[11];
        5'd12: rdata <= DM[12];
        5'd13: rdata <= DM[13];
        5'd14: rdata <= DM[14];
        5'd15: rdata <= DM[15];
        5'd16: rdata <= DM[16];
        5'd17: rdata <= DM[17];
        5'd18: rdata <= DM[18];
        5'd19: rdata <= DM[19];
        5'd20: rdata <= DM[20];
        5'd21: rdata <= DM[21];
        5'd22: rdata <= DM[22];
        5'd23: rdata <= DM[23];
        5'd24: rdata <= DM[24];
        5'd25: rdata <= DM[25];
        5'd26: rdata <= DM[26];
        5'd27: rdata <= DM[27];
        5'd28: rdata <= DM[28];
        5'd29: rdata <= DM[29];
        5'd30: rdata <= DM[30];
        5'd31: rdata <= DM[31];
      endcase
    end
  end


  //调试端口 读出特定内存的数据
  always @(posedge clka) begin
    if (wea == 4'b0) begin
      case (addra)
        5'd0:  rdataa <= DM[0];
        5'd1:  rdataa <= DM[1];
        5'd2:  rdataa <= DM[2];
        5'd3:  rdataa <= DM[3];
        5'd4:  rdataa <= DM[4];
        5'd5:  rdataa <= DM[5];
        5'd6:  rdataa <= DM[6];
        5'd7:  rdataa <= DM[7];
        5'd8:  rdataa <= DM[8];
        5'd9:  rdataa <= DM[9];
        5'd10: rdataa <= DM[10];
        5'd11: rdataa <= DM[11];
        5'd12: rdataa <= DM[12];
        5'd13: rdataa <= DM[13];
        5'd14: rdataa <= DM[14];
        5'd15: rdataa <= DM[15];
        5'd16: rdataa <= DM[16];
        5'd17: rdataa <= DM[17];
        5'd18: rdataa <= DM[18];
        5'd19: rdataa <= DM[19];
        5'd20: rdataa <= DM[20];
        5'd21: rdataa <= DM[21];
        5'd22: rdataa <= DM[22];
        5'd23: rdataa <= DM[23];
        5'd24: rdataa <= DM[24];
        5'd25: rdataa <= DM[25];
        5'd26: rdataa <= DM[26];
        5'd27: rdataa <= DM[27];
        5'd28: rdataa <= DM[28];
        5'd29: rdataa <= DM[29];
        5'd30: rdataa <= DM[30];
        5'd31: rdataa <= DM[31];
      endcase
    end
  end
endmodule
