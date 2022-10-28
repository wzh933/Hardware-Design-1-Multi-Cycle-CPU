`timescale 1ps / 1ps
module st2_decode (  // 译码
    input ID_valid,  // 译码级有效信号
    input [63:0] IF_ID_bus_r,  // IF->ID总线
    input [31:0] rs_value,  // 源操作数1数值
    input [31:0] rt_value,  // 源操作数2数值
    output [4:0] rs,  // 源操作数1地址
    output [4:0] rt,  // 源操作数2地址
    output [32:0] jbr_bus,  // 跳转总线 {jbr_taken, jbr_target}
    output jbr_not_link,  // 指令为跳转分支指令且非link类指令
    output ID_over,  // ID模块执行完成
    output [149:0] ID_EXE_bus,  // ID->EXE总线

    //展示pc
    output [31:0] ID_pc
);
  // IF->ID begin
  wire [31:0] pc;
  wire [31:0] inst;
  assign {pc, inst} = IF_ID_bus_r;  // IF->ID总线传pc和指令
  // IF->ID end

  //inst decode begin
  wire [ 5:0] op;
  wire [ 4:0] rd;
  wire [ 4:0] sa;
  wire [ 5:0] funct;
  wire [15:0] imm;
  wire [15:0] offset;
  wire [25:0] target;

  assign op = inst[31:26];  // 操作码
  assign rs = inst[25:21];  // 源操作数1
  assign rt = inst[20:16];  // 源操作数2
  assign rd = inst[15:11];  // 目标操作数
  assign sa = inst[10:6];  // 特殊域 可能存放偏移量
  assign funct = inst[5:0];  // 功能码
  assign imm = inst[15:0];  //立即数
  assign offset = inst[15:0];  // 地址偏移量
  assign target = inst[25:0];  // 目标地址

  // 实现指令列表
  wire inst_ADDU, inst_SUBU, inst_SLT, inst_AND;
  wire inst_NOR, inst_OR, inst_XOR, inst_SLL;
  wire inst_SRL, inst_ADDIU, inst_BEQ, inst_BNE;
  wire inst_LW, inst_SW, inst_LUI, inst_J;
  wire inst_SLTU, inst_JALR, inst_JR, inst_SLLV;
  wire inst_SRA, inst_SRAV, inst_SRLV, inst_SLTIU;
  wire inst_SLTI, inst_BGEZ, inst_BGTZ, inst_BLEZ;
  wire inst_BLTZ, inst_LB, inst_LBU, inst_SB;
  wire inst_ANDI, inst_ORI, inst_XORI, inst_JAL;
  wire op_zero;  // 操作码全 0 信号量
  wire sa_zero;  // sa域 全 0 信号量
  assign op_zero = ~(|op);
  assign sa_zero = ~(|sa);
  assign inst_ADDU = op_zero & sa_zero & (funct == 6'b100001);  // 无符号加法
  assign inst_SUBU = op_zero & sa_zero & (funct == 6'b100011);  // 无符号减法
  assign inst_SLT = op_zero & sa_zero & (funct == 6'b101010);  // 小于则置位
  assign inst_SLTU = op_zero & sa_zero & (funct == 6'b101011);  // 无符号小则置
  assign inst_JALR = op_zero & (rt==5'd0) & (rd==5'd31) & sa_zero & (funct == 6'b001001); // 跳转寄存器并链接
  assign inst_JR = op_zero & (rt==5'd0) & (rd==5'd0) & sa_zero & (funct == 6'b001000); // 跳转寄存器
  assign inst_AND = op_zero & sa_zero & (funct == 6'b100100);  // 与运算
  assign inst_NOR = op_zero & sa_zero & (funct == 6'b100111);  // 或非运算
  assign inst_OR = op_zero & sa_zero & (funct == 6'b100101);  // 或运算
  assign inst_XOR = op_zero & sa_zero & (funct == 6'b100110);  // 异或运算
  assign inst_SLL = op_zero & (rs == 5'd0) & (funct == 6'b000000);  // 逻辑左移
  assign inst_SLLV = op_zero & sa_zero & (funct == 6'b000100);  // 变量逻辑左移
  assign inst_SRA = op_zero & (rs == 5'd0) & (funct == 6'b000011);  // 算术右移
  assign inst_SRAV = op_zero & sa_zero & (funct == 6'b000111);  // 变量算术右移
  assign inst_SRL = op_zero & (rs == 5'd0) & (funct == 6'b000010);  // 逻辑右移
  assign inst_SRLV = op_zero & sa_zero & (funct == 6'b000110);  // 变量逻辑右移
  assign inst_ADDIU = (op == 6'b001001);  // 立即数无符号加法
  assign inst_SLTI = (op == 6'b001010);  // 小于立即数则置位
  assign inst_SLTIU = (op == 6'b001011);  // 无符号小于立即数则置位
  assign inst_BEQ = (op == 6'b000100);  // 判断相等跳转
  assign inst_BGEZ = (op == 6'b000001) & (rt == 5'd1);  // 大于等于 0 跳转
  assign inst_BGTZ = (op == 6'b000111) & (rt == 5'd0);  // 大于 0 跳转
  assign inst_BLEZ = (op == 6'b000110) & (rt == 5'd0);  // 小于等于 0 跳转
  assign inst_BLTZ = (op == 6'b000001) & (rt == 5'd0);  // 小于 0 跳转
  assign inst_BNE = (op == 6'b000101);  // 判断不等跳转
  assign inst_LW = (op == 6'b100011);  // 从内存装载字
  assign inst_SW = (op == 6'b101011);  // 向内存存储字
  assign inst_LB = (op == 6'b100000);  // load 字节（符号扩展）
  assign inst_LBU = (op == 6'b100100);  // load 字节（无符号扩展）
  assign inst_SB = (op == 6'b101000);  // 向内存存储字节
  assign inst_ANDI = (op == 6'b001100);  // 立即数与
  assign inst_LUI = (op == 6'b001111) & (rs == 5'd0);  // 立即数装载高半字节
  assign inst_ORI = (op == 6'b001101);  // 立即数或
  assign inst_XORI = (op == 6'b001110);  // 立即数异或
  assign inst_J = (op == 6'b000010);  // 跳转
  assign inst_JAL = (op == 6'b000011);  // 跳转和链接

  // 指令分类：
  // 1、跳转分支指令
  wire inst_jr;  // 寄存器跳转指令
  wire inst_j_link;  // 链接跳转指令
  assign inst_jr = inst_JALR | inst_JR;  // 两种寄存器跳转指令
  assign inst_j_link = inst_JAL | inst_JALR;  // 两种链接跳转指令
  // 全部非link类跳转指令
  assign jbr_not_link = inst_J | inst_JR | inst_BEQ | inst_BNE | inst_BGEZ | inst_BGTZ | inst_BLEZ | inst_BLTZ;

  // 2、load / store
  wire inst_load;
  wire inst_store;
  assign inst_load  = inst_LW | inst_LB | inst_LBU;  // load型指令
  assign inst_store = inst_SW | inst_SB;  // store型指令

  // 3、alu操作分类（12个操作）
  wire inst_add, inst_sub, inst_slt, inst_sltu;
  wire inst_and, inst_nor, inst_or, inst_xor;
  wire inst_sll, inst_srl, inst_sra, inst_lui;
  assign inst_add = inst_ADDU | inst_ADDIU | inst_load | inst_store | inst_j_link;// 做加法的指令
  assign inst_sub = inst_SUBU;  // 做减法的指令
  assign inst_slt = inst_SLT | inst_SLTI;  // 有符号小于置位
  assign inst_sltu = inst_SLTIU | inst_SLTU;  // 无符号小于置位
  assign inst_and = inst_AND | inst_ANDI;  // 逻辑与
  assign inst_nor = inst_NOR;  // 逻辑或非
  assign inst_or = inst_OR | inst_ORI;  // 逻辑或
  assign inst_xor = inst_XOR | inst_XORI;  // 逻辑或非
  assign inst_sll = inst_SLL | inst_SLLV;  // 逻辑左移
  assign inst_srl = inst_SRL | inst_SRLV;  // 逻辑右移
  assign inst_sra = inst_SRA | inst_SRAV;  // 算术右移
  assign inst_lui = inst_LUI;  // 立即数装载高位

  // 4、使用 sa域 作为偏移量的移位指令
  wire inst_shf_sa;
  assign inst_shf_sa = inst_SLL | inst_SRL | inst_SRA;

  // 5、依据立即数扩展方式分类
  wire inst_imm_zero;  // 立即数 0 扩展
  wire inst_imm_sign;  // 立即数符号扩展
  assign inst_imm_zero = inst_ANDI | inst_LUI | inst_ORI | inst_XORI;
  assign inst_imm_sign = inst_ADDIU | inst_SLTI | inst_SLTIU | inst_load | inst_store;

  // 6、依据目的寄存器号分类
  wire inst_wdset_rt;  // 寄存器堆写入地址为rt的指令
  wire inst_wdset_31;  // 寄存器堆写入地址为31的指令
  wire inst_wdset_rd;  // 寄存器堆写入地址为rd的指令
  assign inst_wdset_rt = inst_imm_zero | inst_ADDIU | inst_SLTI | inst_SLTIU | inst_load;
  assign inst_wdset_31 = inst_JAL;
  assign inst_wdset_rd = inst_ADDU | inst_SUBU | inst_SLT | inst_SLTU | inst_JALR | inst_AND | inst_NOR | inst_OR | inst_XOR | inst_SLL | inst_SLLV | inst_SRA | inst_SRAV | inst_SRL | inst_SRLV;
  // inst decode end

  // 分支指令执行 begin
  // 无条件跳转
  wire j_taken;
  wire [31:0] j_target;
  assign j_taken  = inst_J | inst_JAL | inst_jr;
  // 寄存器跳转地址为rs_value，其他跳转为{pc[31:28], target, 2'b00}
  assign j_target = inst_jr ? rs_value : {pc[31:28], target, 2'b00};

  // branch指令
  wire rs_equql_rt;
  wire rs_ez;
  wire rs_ltz;
  assign rs_equql_rt = (rs_value == rt_value);  // GPR[rs]==GPR[rt]
  assign rs_ez = ~(|rs_value);  // rs寄存器值等于0
  assign rs_ltz = rs_value[31];  // rs寄存器值小于0
  wire br_taken;
  wire [31:0] br_target;
  // 相等跳转 | 不等跳转 | 大于等于0跳转 | 大于0跳转 | 小于等于0跳转 | 小于0跳转
  assign br_taken= (inst_BEQ & rs_equql_rt) | (inst_BNE & ~rs_equql_rt) | (inst_BGEZ & ~rs_ltz) | (inst_BGTZ & ~rs_ltz & ~rs_ez) | (inst_BGTZ & (rs_ltz | rs_ez)) | (inst_BLTZ & rs_ltz);

  // 分支跳转目标地址：pc = pc + offset << 2
  assign br_target[31:2] = pc[31:2] + {{14{offset[15]}}, offset};
  assign br_target[1:0] = pc[1:0];

  // 判断 jump or branch 指令
  wire jbr_taken;
  wire [31:0] jbr_target;
  assign jbr_taken = j_taken | br_taken;
  assign jbr_target = j_taken ? j_target : br_target;

  // IF->ID的跳转总线
  assign jbr_bus = {jbr_taken, jbr_target};
  // 分支指令执行 end

  // ID执行完成 begin
  // 由于是多周期的 不存在数据相关
  // 故ID模块一拍就能完成所有操作
  // 故ID_valid即是ID_over信号
  assign ID_over = ID_valid;
  // ID执行完成 end

  // ID->EXE总线 begin
  // EXE需要用到的信息
  // ALU两个源操作数和控制信号
  wire [11:0] alu_control;
  wire [31:0] alu_operand1;
  wire [31:0] alu_operand2;

  // 所谓链接跳转是将跳转返回的pc值存放到31号寄存器里
  // 在多周期CPU里，不考虑延迟槽，故链接跳转需要计算pc + 4，存放到31号寄存器里
  assign alu_operand1 = inst_j_link ? pc : (inst_shf_sa ? {27'd0, sa} : rs_value);
  assign alu_operand2 = inst_j_link ? 32'd4 : (inst_imm_zero ? {16'd0, imm} : (inst_imm_sign ? {{16{imm[15]}}, imm} : rt_value));
  assign alu_control = {  // ALU操作码，独热编码
        inst_add,
        inst_sub,
        inst_slt,
        inst_sltu,
        inst_and,
        inst_nor,
        inst_or,
        inst_xor,
        inst_sll,
        inst_srl,
        inst_sra,
        inst_lui
      };
  // 仿存需要用到的 load / store 信息
  wire lb_sign;  // load一字节为有符号load
  wire Is_word;  // load / store 为字节还是字 0: byte; 1: word
  wire [3:0] mem_control;  // MEM需要使用的控制信号
  wire [31:0] store_data;  // store操作的存的数据
  assign lb_sign = inst_LB;
  assign Is_word = inst_LW | inst_SW;
  assign mem_control = {inst_load, inst_store, Is_word, lb_sign};

  // 写回需要用到的信息
  wire rf_wen;  // 写回的寄存器写使能
  wire [4:0] rf_wdest;  // 写回的目的寄存器
  assign rf_wen = inst_wdset_rt | inst_wdset_31 | inst_wdset_rd;
  assign rf_wdest = inst_wdset_rt ? rt : (inst_wdset_31 ? 5'd31 : (inst_wdset_rd ? rd : 5'd0));// 在不写寄存器堆时，设置为0
  assign store_data = rt_value;
  assign ID_EXE_bus = {
    alu_control,
    alu_operand1,
    alu_operand2,  // EXE需要使用的信息
    mem_control,
    store_data,  // MEM需要使用的信号
    rf_wen,
    rf_wdest,  // WB需要使用的信号
    pc  // pc值
  };
  // ID->EXE总线 end

  // display ID_pc begin
  assign ID_pc = pc;
  // display ID_pc end
endmodule
