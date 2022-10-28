`timescale 1ps / 1ps
module inst_rom (  // 指令寄存器模块 同步读
    input clk,
    input [7:0] addr,
    output [31:0] inst
);
  wire [31:0] inst_rom[49:0];  // 指令存储器，字节地址7'b000_0000~7'b111_1111
  //------------- 指令编码 ---------|指令地址|----------- 汇编指令 -----------|- 指令结果 -----//
  assign inst_rom[0] = 32'h3c010000;  //(00) | main:    lui $1, #0            | $1 = 0000_0000H 
  assign inst_rom[1] = 32'h34240000;  //(04) |          ori $4, $1, #0x00     | $4 = 0000_0000H 
  assign inst_rom[2] = 32'h24050004;  //(08) |          addiu $5, $0, #4      | $5 = 0000_0004H
  assign inst_rom[3] = 32'h0c000018;  //(0C) | call:    jal sum               | pc = 0000_0060H 

  assign inst_rom[4] = 32'hac820000;  //(10) |          sw $2, #0($4)         | Mem[10H] = 0000_000AH 
  assign inst_rom[5] = 32'h8c890000;  //(14) |          lw $9, #0($4)         | $9 = 0000_000AH 
  assign inst_rom[6] = 32'h01244023;  //(18) |          subu $8, $9, $4       | $8 =  FFFF_FFFAH (-6D)
  assign inst_rom[7] = 32'h24050003;  //(1C) |          addiu $5, $0, #3      | $5 = 0000_0003H 
  assign inst_rom[8] = 32'h24a5ffff;  //(20) | loop2:   addiu $5, $5, #-1     | $5 = $5 - 1 
  assign inst_rom[9]  = 32'h34a8ffff; //(24) |          ori $8, $5, #0xffff   | $8 = 0000_FFFFH 
  assign inst_rom[10] = 32'h39085555; //(28) |          xori $8, $8, #0x5555  | $8 = 0000_AAAAH
  assign inst_rom[11] = 32'h2409ffff; //(2C) |          addiu $9, $0, #-1     | $9 = FFFF_FFFFH 
  assign inst_rom[12] = 32'h312affff; //(30) |          andi $10, $9, #0xffff | $10 = 0000_FFFFH 
  assign inst_rom[13] = 32'h01493025; //(34) |          or $6, $10, $9        | $6 = FFFF_FFFFH 
  assign inst_rom[14] = 32'h01494026; //(38) |          xor $8, $10, $9       | $8 = FFFF_0000H 
  assign inst_rom[15] = 32'h01463824; //(3C) |          and $7, $10, $6       | $7 = 0000_FFFFH 
  assign inst_rom[16] = 32'h10a00002; //(40) |          beq $5, $0, shift     | if $5 == 0: pc = 0000_0048H 
  assign inst_rom[17] = 32'h08000008; //(44) |          j loop2               | pc = 0000_0020H
  assign inst_rom[18] = 32'h2405ffff; //(48) | shift:   addiu $5, $0, #-1     | $5 = FFFF_FFFFH 
  assign inst_rom[19] = 32'h000543c0; //(4C) |          sll $8, $5, #15       | $8 = FFFF_8000H 
  assign inst_rom[20] = 32'h00084400; //(50) |          sll $8, $8, #16       | $8 = 8000_0000H 
  assign inst_rom[21] = 32'h00084403; //(54) |          sra $8, $8, #16       | $8 = FFFF_8000H 
  assign inst_rom[22] = 32'h000843c2; //(58) |          srl $8, $8, #15       | $8 = 0001_FFFFH 
  assign inst_rom[23] = 32'h08000017; //(5C) | finish:  j finish              | pc = 0000_005CH

  assign inst_rom[24] = 32'h00004021; //(60) | sum:     addu $8, $0, $0       | $8 = 0000_0000H 
  assign inst_rom[25] = 32'h8c890000; //(64) | loop1:   lw $9, #0($4)         | $9 = Mem[00H] = 0000_0001H 
  assign inst_rom[26] = 32'h24840004; //(68) |          addiu $4, $4, #4      | $4 = $4 + 4 
  assign inst_rom[27] = 32'h01094021; //(6C) |          addu $8, $8, $9       | $8 = $8 + $9 
  assign inst_rom[28] = 32'h24a5ffff; //(70) |          addiu $5, $5, #-1     | $5 = $5 - 1
  assign inst_rom[29] = 32'h14a0fffc; //(74) |          bne $5, $0, loop1     | if $5 != 0: pc = 0000_0064H 
  assign inst_rom[30] = 32'h00081000; //(78) |          sll $2, $8, #0        | $2 = 0000_000AH 
  assign inst_rom[31] = 32'h03e00008; //(7c) |          jr $31                | pc = 0000_0010H 

  reg [31:0] inst_r;
  always @(posedge clk) begin  // 同步读
    inst_r <= inst_rom[addr];
  end
  assign inst = inst_r;
endmodule
