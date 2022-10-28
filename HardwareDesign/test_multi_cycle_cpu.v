`timescale 1ns / 1ps
module test_multi_cycle_cpu ();
  reg clk;
  reg resetn;

  wire [31:0] IF_pc;
  wire [31:0] IF_inst;
  wire [31:0] ID_pc;
  wire [31:0] EXE_pc;
  wire [31:0] MEM_pc;
  wire [31:0] WB_pc;
  wire [2:0] display_state;
  wire [31:0] rf_data;
  wire [31:0] mem_data;

  multi_cycle_cpu multi_cycle_cpu (
      .clk(clk),
      .resetn(resetn),

      // display data
      .rf_addr(5'd8),  // input
      .mem_addr(32'h10),  // input
      .rf_data(rf_data),  // output...
      .mem_data(mem_data),
      .IF_pc(IF_pc),
      .IF_inst(IF_inst),
      .ID_pc(ID_pc),
      .EXE_pc(EXE_pc),
      .MEM_pc(MEM_pc),
      .WB_pc(WB_pc),
      .display_state(display_state)
  );

  initial begin
    clk   = 1;
    resetn = 0;
  end

  always #0.5 begin
    resetn = 1;
    clk   = ~clk;
  end
  // 测试多周期cpu模块结束
endmodule
