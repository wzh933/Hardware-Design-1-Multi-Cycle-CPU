`timescale 1ps / 1ps
`define STARTADDR 32'd0
module st1_fetch (  // 取指
    input clk,  // 时钟信号
    input resetn,  // 复位信号，低电平有效
    input IF_valid,  // 取指级有效信号
    input next_fetch,  // 取下一条指令，用来锁存PC值
    input [31:0] inst,  // inst_rom取出的指令
    input [32:0] jbr_bus,  // 跳转总线 {jbr_taken, jbr_target}
    output [31:0] inst_addr,  // 发往inst_rom的取值地址
    output reg IF_over,  // IF模块执行完成
    output [63:0] IF_ID_bus,  // IF->ID总线

    //展示pc和取出的指令
    output [31:0] IF_pc,
    output [31:0] IF_inst
);
  //pc begin
  wire [31:0] next_pc;  // 下一指令地址
  wire [31:0] seq_pc;  // 非跳转（顺序执行）的下一指令地址
  reg [31:0] pc;  // 程序计数器pc
  // 跳转pc
  wire jbr_taken;  // 跳转信号
  wire [31:0] jbr_target;  // 跳转地址
  assign {jbr_taken, jbr_target} = jbr_bus;  // 跳转总线

  assign seq_pc[31:2] = pc[31:2] + 1'b1;  // 顺序执行的下一指令地址：b<PC>=b<PC>+b100
  assign seq_pc[1:0] = pc[1:0];

  // 新指令：若指令跳转，为跳转地址；否则为下一条指令
  assign next_pc = jbr_taken ? jbr_target : seq_pc;

  always @(posedge clk) begin  // pc程序计数器
    if (!resetn) begin
      pc <= `STARTADDR;  // 复位，取程序起始地址
    end else if (next_fetch) begin  // 锁存pc值
      pc <= next_pc;  // 不复位，取新指令
    end
  end
  // pc end

  // to instrom begin
  assign inst_addr = pc;
  // to instrom end

  // IF执行完成 begin
  // 由于inst_rom为同步读的
  // 取数据时，有一拍延时
  // 即发地址的下一拍时钟才能得到对应的指令
  // 故取值模块需要两拍时间
  // 将IF_valid锁存一拍即是IF_over信号
  always @(posedge clk) begin  // 同步读
    // always @(*) begin  // 异步读
    IF_over <= IF_valid;  // 非阻塞赋值 此时IF_valid还是上一时刻值0
  end
  // 如果inst_rom为异步读的
  // 则IF_valid即是IF_over信号
  // 即取指一拍完成
  // IF执行完成 end

  // IF->ID总线begin
  assign IF_ID_bus = {pc, inst};
  // IF->ID总线end

  // display IF_pc、IF_inst
  assign IF_pc = pc;
  assign IF_inst = inst;
  // display end
endmodule
