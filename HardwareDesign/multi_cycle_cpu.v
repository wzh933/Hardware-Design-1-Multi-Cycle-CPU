`timescale 1ps / 1ps
`include "st1_fetch.v"
`include "st2_decode.v"
`include "st3_exe.v"
`include "st4_mem.v"
`include "st5_wb.v"
`include "inst_rom.v"
`include "data_ram.v"
`include "regfile.v"
module multi_cycle_cpu (  // 多周期cpu
    // 时钟与复位信号
    input clk,
    input resetn, // 后缀"n"代表低电平有效

    // display data
    input  [ 4:0] rf_addr,
    input  [31:0] mem_addr,
    output [31:0] rf_data,
    output [31:0] mem_data,
    output [31:0] IF_pc,
    output [31:0] IF_inst,
    output [31:0] ID_pc,
    output [31:0] EXE_pc,
    output [31:0] MEM_pc,
    output [31:0] WB_pc,
    output [31:0] display_state
);

  // 控制多周期的状态机 begin
  reg [2:0] state;  // 当前状态
  reg [2:0] next_state;  // 下一状态
  assign display_state = {29'd0, state};  //展示当前处理机正在处理哪个模块
  //状态机状态
  parameter IDLE = 3'd0;  //开始
  parameter FETCH = 3'd1;  //取指
  parameter DECODE = 3'd2;  // 译码
  parameter EXE = 3'd3;  // 执行
  parameter MEM = 3'd4;  // 仿存
  parameter WB = 3'd5;  // 写回

  always @(posedge clk) begin  // 当前状态
    if (!resetn) begin  // 如果复位信号有效
      state <= IDLE;  // 当前状态为 开始
    end else begin  // 否则
      state <= next_state;  // 为下一状态
    end
  end

  wire IF_over;  // IF模块已执行完
  wire ID_over;  // ID模块已执行完
  wire EXE_over;  // EXE模块已执行完
  wire MEM_over;  // MEM模块已执行完
  wire WB_over;  // WB模块已执行完
  wire jbr_not_link;  // 分支指令（非link类），只走IF和ID级
  always @(*) begin
    case (state)
      IDLE: begin
        next_state = FETCH;  // IDLE->IF
      end
      FETCH: begin
        if (IF_over) begin
          next_state = DECODE;  // IF->ID
        end else begin
          next_state = FETCH;  // continue IF
        end
      end
      DECODE: begin
        if (ID_over) begin  // 如果是非link类的分支指令则写回，否则执行
          next_state = jbr_not_link ? FETCH : EXE;  // ID->WB/EXE
        end else begin
          next_state = DECODE;  // continue ID
        end
      end
      EXE: begin
        if (EXE_over) begin
          next_state = MEM;  // EXE->MEM
        end else begin
          next_state = EXE;  // continue EXE
        end
      end
      MEM: begin
        if (MEM_over) begin
          next_state = WB;  // MEM->WB
        end else begin
          next_state = MEM;  // continue MEM
        end
      end
      WB: begin
        if (WB_over) begin
          next_state = FETCH;  // WB->IF
        end else begin
          next_state = WB;  // continue WB
        end
      end
      default: next_state = IDLE;
    endcase
  end
  // 5模块的valid信号
  wire IF_valid;
  wire ID_valid;
  wire EXE_valid;
  wire MEM_valid;
  wire WB_valid;
  assign IF_valid  = (state == FETCH);  // 当前状态为取指时 IF级有效
  assign ID_valid  = (state == DECODE);  // 当前状态为译码时 ID级有效
  assign EXE_valid = (state == EXE);  // 当前状态为执行时 EXE级有效
  assign MEM_valid = (state == MEM);  // 当前状态为访存时 MEM级有效
  assign WB_valid  = (state == WB);  // 当前状态为写回时 WB级有效
  // 控制多周期的状态机 end

  // 5级间的总线 begin
  wire [ 63:0] IF_ID_bus;  // IF->ID级总线
  wire [149:0] ID_EXE_bus;  // ID->EXE级总线
  wire [105:0] EXE_MEM_bus;  // EXE->MEM级总线
  wire [ 69:0] MEM_WB_bus;  // MEM->WB级总线

  // 锁存以上总线信号
  reg  [ 63:0] IF_ID_bus_r;
  reg  [149:0] ID_EXE_bus_r;
  reg  [105:0] EXE_MEM_bus_r;
  reg  [ 69:0] MEM_WB_bus_r;

  //IF->ID的锁存信号
  always @(posedge clk) begin
    if (IF_over) begin
      IF_ID_bus_r <= IF_ID_bus;
    end
  end

  //ID->EXE的锁存信号
  always @(posedge clk) begin
    if (ID_over) begin
      ID_EXE_bus_r <= ID_EXE_bus;
    end
  end

  //EXE->MEM的锁存信号
  always @(posedge clk) begin
    if (EXE_over) begin
      EXE_MEM_bus_r <= EXE_MEM_bus;
    end
  end

  //MEM->WB的锁存信号
  always @(posedge clk) begin
    if (MEM_over) begin
      MEM_WB_bus_r <= MEM_WB_bus;
    end
  end
  // 5级间的总线 end

  // 其他交互信号 begin
  // 跳转总线
  wire [32:0] jbr_bus;

  // IF与inst_rom交互
  wire [31:0] inst_addr;
  wire [31:0] inst;

  // MEM与data_ram交互
  wire [3:0] dm_wen;
  wire [31:0] dm_addr;
  wire [31:0] dm_wdata;
  wire [31:0] dm_rdata;

  // ID与regfile交互
  wire [4:0] rs;
  wire [4:0] rt;
  wire [31:0] rs_value;
  wire [31:0] rt_value;

  // WB与regfile交互
  wire rf_wen;
  wire [4:0] rf_wdest;
  wire [31:0] rf_wdata;  //透
  // 其他交互信号 end

  // 各模块实例化 begin
  wire next_fetch;  // next_state_is_fetch 即将运行取值模块，需要先锁存pc值
  // 当前状态为ID，且指令为跳转分支指令（非link类），且ID执行完成
  // 或者，当前状态为WB，且WB执行完成，则即将进入IF状态
  assign next_fetch = (state == DECODE & ID_over & jbr_not_link) | (state == WB & WB_over);

  st1_fetch IF_module (  // 取指
      .clk(clk),  // input, 1
      .resetn(resetn),  // input, 1
      .IF_valid(IF_valid),  // input, 1
      .next_fetch(next_fetch),  // input, 1
      .inst(inst),  // input, 32
      .jbr_bus(jbr_bus),  // input, 33
      .inst_addr(inst_addr),  // optput, 32
      .IF_over(IF_over),  // output, 1
      .IF_ID_bus(IF_ID_bus),  // output, 64

      // 展示pc和取出的指令
      .IF_pc  (IF_pc),
      .IF_inst(IF_inst)
  );

  st2_decode ID_module (  // 译码
      .ID_valid(ID_valid),  // input, 1
      .IF_ID_bus_r(IF_ID_bus_r),  // input, 64
      .rs_value(rs_value),  // input, 32
      .rt_value(rt_value),  // input, 32
      .rs(rs),  // output, 5
      .rt(rt),  // output, 5
      .jbr_bus(jbr_bus),  // output, 33
      .jbr_not_link(jbr_not_link),  // output, 1
      .ID_over(ID_over),  // output, 1
      .ID_EXE_bus(ID_EXE_bus),  // output, 150

      // 展示pc
      .ID_pc(ID_pc)
  );

  st3_exe EXE_module (  // 执行级
      .EXE_valid(EXE_valid),  // input, 1
      .ID_EXE_bus_r(ID_EXE_bus_r),  // input, 150
      .EXE_over(EXE_over),  // output, 1
      .EXE_MEM_bus(EXE_MEM_bus),  // output, 106

      //展示pc
      .EXE_pc(EXE_pc)
  );

  st4_mem MEM_module (  // 访存级
      .clk(clk),  // input, 1
      .MEM_valid(MEM_valid),  // input, 1
      .EXE_MEM_bus_r(EXE_MEM_bus_r),  // input, 106
      .dm_rdata(dm_rdata),  // input, 32
      .dm_addr(dm_addr),  // output, 32
      .dm_wen(dm_wen),  // output, 4
      .dm_wdata(dm_wdata),  // output, 32
      .MEM_over(MEM_over),  // output, 1
      .MEM_WB_bus(MEM_WB_bus),  // output, 70

      //展示pc
      .MEM_pc(MEM_pc)
  );

  st5_wb WB_module (  // 写回级
      .WB_valid(WB_valid),  // input, 1
      .MEM_WB_bus_r(MEM_WB_bus_r),  // input, 70
      .rf_wen(rf_wen),  // output, 1
      .rf_wdest(rf_wdest),  // output, 5
      .rf_wdata(rf_wdata),  // output, 32
      .WB_over(WB_over),  // output, 1

      // 展示pc
      .WB_pc(WB_pc)
  );

  inst_rom inst_rom_module (  // 指令存储器
      .clk(clk),  // input, 1 ,时钟
      .addr(inst_addr[9:2]),  // input, 8, 指令地址：pc[9:2]
      .inst(inst)  // output, 32, 指令
  );

  regfile rf_module (  // 寄存器堆模块
      .clk(clk),  // input, 1
      .wen(rf_wen),  // input, 1
      .raddr1(rs),  // input, 5
      .raddr2(rt),  // input, 5
      .waddr(rf_wdest),  // input, 5
      .wdata(rf_wdata),  // input, 32
      .rdata1(rs_value),  // output, 32
      .rdata2(rt_value),  // output, 32

      //display rf
      .rf_addr(rf_addr),  // input, 4
      .rf_data(rf_data)   // output, 32
  );

  data_ram data_ram_module (  // 数据存储模块
      .clk(clk),  // input, 1, 时钟
      .wen(dm_wen),  // input, 4, 写使能
      .addr(dm_addr[9:2]),  // input, 8, 读地址
      .wdata(dm_wdata),  // input, 32, 写数据
      .rdata(dm_rdata),  // output, 32, 读数据

      //display mem
      .clka(clk),
      .wea(4'd0),
      .addra(mem_addr[9:2]),  // input, 8
      .rdataa(mem_data),  // output, 32
      .wdataa(32'd0)
  );

  //各模块实例化 end
endmodule
