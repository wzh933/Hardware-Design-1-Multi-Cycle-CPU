`timescale 1ps / 1ps
module st5_wb (  // 写回
    input WB_valid,  // 写回级有效
    input [69:0] MEM_WB_bus_r,  // MEM->WB总线
    output rf_wen,  // 寄存器写使能
    output [4:0] rf_wdest,  // 寄存器写地址
    output [31:0] rf_wdata,  // 寄存器写数据
    output WB_over,  // WB模块执行完成

    // 展示pc
    output [31:0] WB_pc
);
  // MEM->WB总线 begin
  // 寄存器堆写使能和写地址
  wire wen;
  wire [4:0] wdest;

  // MEM传来的result
  wire [31:0] mem_result;

  // pc
  wire [31:0] pc;
  assign {wen, wdest, mem_result, pc} = MEM_WB_bus_r;
  // MEM->WB end

  // WB执行完成 begin
  // WB模块只是传递寄存器堆的 写使能 写地址 写数据
  // 可在一拍内完成
  // 故WB_valid即是WB_over信号
  assign WB_over = WB_valid;
  // WB执行完成 end

  // WB->regfile信号 begin
  assign rf_wen = wen & WB_valid;
  assign rf_wdest = wdest;
  assign rf_wdata = mem_result;
  // WB->regfile信号 end

  // display WB_pc begin
  assign WB_pc = pc;
  // display WB_pc end
endmodule
