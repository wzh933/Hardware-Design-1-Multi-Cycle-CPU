`timescale 1ps / 1ps
`include "adder.v"
module alu (  // ALU模块，可进行12种操作
    input [11:0] alu_control,  // ALU控制信号
    input [31:0] alu_src1,  // ALU操作数1，为补码
    input [31:0] alu_src2,  // ALU操作数2，为补码
    output [31:0] alu_result  // ALU结果
);

  // ALU控制信号，独热码
  wire alu_add;  // 加法操作
  wire alu_sub;  // 减法操作
  wire alu_slt;  // 有符号比较，小于置位，复用加法器做减法
  wire alu_sltu;  // 无符号比较，小于置位，复用加法器做减法
  wire alu_and;  // 按位与
  wire alu_nor;  // 按位或非
  wire alu_or;  // 按位或
  wire alu_xor;  // 按位异或
  wire alu_sll;  // 逻辑左移
  wire alu_srl;  // 逻辑右移
  wire alu_sra;  // 算术右移
  wire alu_lui;  // 高位加载

  assign alu_add  = alu_control[11];
  assign alu_sub  = alu_control[10];
  assign alu_slt  = alu_control[9];
  assign alu_sltu = alu_control[8];
  assign alu_and  = alu_control[7];
  assign alu_nor  = alu_control[6];
  assign alu_or   = alu_control[5];
  assign alu_xor  = alu_control[4];
  assign alu_sll  = alu_control[3];
  assign alu_srl  = alu_control[2];
  assign alu_sra  = alu_control[1];
  assign alu_lui  = alu_control[0];

  wire [31:0] add_sub_result;
  wire [31:0] slt_result;
  wire [31:0] sltu_result;
  wire [31:0] and_result;
  wire [31:0] nor_result;
  wire [31:0] or_result;
  wire [31:0] xor_result;
  wire [31:0] sll_result;
  wire [31:0] srl_result;
  wire [31:0] sra_result;
  wire [31:0] lui_result;

  assign and_result = alu_src1 & alu_src2;
  assign or_result  = alu_src1 | alu_src2;
  assign nor_result = ~or_result;
  assign xor_result = alu_src1 ^ alu_src2;
  assign lui_result = {alu_src2[15:0], 16'd0};  // src2低16位装载至高16位

  // 加法器 begin
  // add, sub, slt, sltu均使用该模块
  wire [31:0] adder_operand1;
  wire [31:0] adder_operand2;
  wire adder_cin;
  wire [31:0] adder_result;
  wire adder_cout;
  assign adder_operand1 = alu_src1;
  assign adder_operand2 = alu_add ? alu_src2 : ~alu_src2;  // 判断做加法还是减法
  assign adder_cin = ~alu_add;  // 减法需要cin，因为负数的补码是取反加1，前面已将alu_src2按位取反

  // 调用加法器模快
  adder adder_module (
      .operand1(adder_operand1),  // input, 32
      .operand2(adder_operand2),  // input, 32
      .cin(adder_cin),  // input, 1
      .result(adder_result),  // output, 32
      .cout(adder_cout)  // output, 1
  );

  // 加减结果
  assign add_sub_result = adder_result;

  // slt结果
  assign slt_result = adder_result[31] ? 1'b1 : 1'b0;

  // sltu结果
  assign sltu_result = adder_cout ? 1'b0 : 1'b1;  //无符号数小于置位  


  // 逻辑左移
  assign sll_result = alu_src2 << alu_src1;

  // 逻辑右移
  assign srl_result = alu_src2 >> alu_src1;

  // 算术右移
  wire signed [31:0] temp_src2;  //带符号数的临时变量
  assign temp_src2  = alu_src2;
  assign sra_result = temp_src2 >>> alu_src1;

  // 选择相应结果输出
  // assign alu_result = (alu_add | alu_sub) ? add_sub_result[31:0] : alu_slt ? slt_result : alu_sltu ? sltu_result : alu_and ? and_result : alu_nor ? nor_result : alu_or ? or_result : alu_xor ? xor_result : alu_sll ? sll_result : alu_srl ? srl_result : alu_sra ? sra_result : alu_lui ? lui_result : 32'd0;
  reg [31:0] alu_result_r;
  always @(*) begin
    if (alu_add | alu_sub) alu_result_r <= add_sub_result;
    else if (alu_slt) alu_result_r <= slt_result;
    else if (alu_sltu) alu_result_r <= sltu_result;
    else if (alu_and) alu_result_r <= and_result;
    else if (alu_nor) alu_result_r <= nor_result;
    else if (alu_or) alu_result_r <= or_result;
    else if (alu_xor) alu_result_r <= xor_result;
    else if (alu_sll) alu_result_r <= sll_result;
    else if (alu_srl) alu_result_r <= srl_result;
    else if (alu_sra) alu_result_r <= sra_result;
    else if (alu_lui) alu_result_r <= lui_result;
  end
  assign alu_result = alu_result_r;
endmodule
