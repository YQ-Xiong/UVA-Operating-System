
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	0000a117          	auipc	sp,0xa
    80000004:	80010113          	addi	sp,sp,-2048 # 80009800 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	070000ef          	jal	ra,80000086 <start>

000000008000001a <junk>:
    8000001a:	a001                	j	8000001a <junk>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    80000026:	0037969b          	slliw	a3,a5,0x3
    8000002a:	02004737          	lui	a4,0x2004
    8000002e:	96ba                	add	a3,a3,a4
    80000030:	0200c737          	lui	a4,0x200c
    80000034:	ff873603          	ld	a2,-8(a4) # 200bff8 <_entry-0x7dff4008>
    80000038:	000f4737          	lui	a4,0xf4
    8000003c:	24070713          	addi	a4,a4,576 # f4240 <_entry-0x7ff0bdc0>
    80000040:	963a                	add	a2,a2,a4
    80000042:	e290                	sd	a2,0(a3)

  // prepare information in scratch[] for timervec.
  // scratch[0..3] : space for timervec to save registers.
  // scratch[4] : address of CLINT MTIMECMP register.
  // scratch[5] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &mscratch0[32 * id];
    80000044:	0057979b          	slliw	a5,a5,0x5
    80000048:	078e                	slli	a5,a5,0x3
    8000004a:	00009617          	auipc	a2,0x9
    8000004e:	fb660613          	addi	a2,a2,-74 # 80009000 <mscratch0>
    80000052:	97b2                	add	a5,a5,a2
  scratch[4] = CLINT_MTIMECMP(id);
    80000054:	f394                	sd	a3,32(a5)
  scratch[5] = interval;
    80000056:	f798                	sd	a4,40(a5)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000058:	34079073          	csrw	mscratch,a5
  asm volatile("csrw mtvec, %0" : : "r" (x));
    8000005c:	00006797          	auipc	a5,0x6
    80000060:	a2478793          	addi	a5,a5,-1500 # 80005a80 <timervec>
    80000064:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000068:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    8000006c:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000070:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    80000074:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000078:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    8000007c:	30479073          	csrw	mie,a5
}
    80000080:	6422                	ld	s0,8(sp)
    80000082:	0141                	addi	sp,sp,16
    80000084:	8082                	ret

0000000080000086 <start>:
{
    80000086:	1141                	addi	sp,sp,-16
    80000088:	e406                	sd	ra,8(sp)
    8000008a:	e022                	sd	s0,0(sp)
    8000008c:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000008e:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000092:	7779                	lui	a4,0xffffe
    80000094:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd87cb>
    80000098:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    8000009a:	6705                	lui	a4,0x1
    8000009c:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a0:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a2:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000a6:	00001797          	auipc	a5,0x1
    800000aa:	c7678793          	addi	a5,a5,-906 # 80000d1c <main>
    800000ae:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b2:	4781                	li	a5,0
    800000b4:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000b8:	67c1                	lui	a5,0x10
    800000ba:	17fd                	addi	a5,a5,-1
    800000bc:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c0:	30379073          	csrw	mideleg,a5
  timerinit();
    800000c4:	00000097          	auipc	ra,0x0
    800000c8:	f58080e7          	jalr	-168(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000cc:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000d0:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000d2:	823e                	mv	tp,a5
  asm volatile("mret");
    800000d4:	30200073          	mret
}
    800000d8:	60a2                	ld	ra,8(sp)
    800000da:	6402                	ld	s0,0(sp)
    800000dc:	0141                	addi	sp,sp,16
    800000de:	8082                	ret

00000000800000e0 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    800000e0:	7119                	addi	sp,sp,-128
    800000e2:	fc86                	sd	ra,120(sp)
    800000e4:	f8a2                	sd	s0,112(sp)
    800000e6:	f4a6                	sd	s1,104(sp)
    800000e8:	f0ca                	sd	s2,96(sp)
    800000ea:	ecce                	sd	s3,88(sp)
    800000ec:	e8d2                	sd	s4,80(sp)
    800000ee:	e4d6                	sd	s5,72(sp)
    800000f0:	e0da                	sd	s6,64(sp)
    800000f2:	fc5e                	sd	s7,56(sp)
    800000f4:	f862                	sd	s8,48(sp)
    800000f6:	f466                	sd	s9,40(sp)
    800000f8:	f06a                	sd	s10,32(sp)
    800000fa:	ec6e                	sd	s11,24(sp)
    800000fc:	0100                	addi	s0,sp,128
    800000fe:	8b2a                	mv	s6,a0
    80000100:	8aae                	mv	s5,a1
    80000102:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000104:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    80000108:	00011517          	auipc	a0,0x11
    8000010c:	6f850513          	addi	a0,a0,1784 # 80011800 <cons>
    80000110:	00001097          	auipc	ra,0x1
    80000114:	9be080e7          	jalr	-1602(ra) # 80000ace <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    80000118:	00011497          	auipc	s1,0x11
    8000011c:	6e848493          	addi	s1,s1,1768 # 80011800 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    80000120:	89a6                	mv	s3,s1
    80000122:	00011917          	auipc	s2,0x11
    80000126:	77690913          	addi	s2,s2,1910 # 80011898 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    8000012a:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    8000012c:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    8000012e:	4da9                	li	s11,10
  while(n > 0){
    80000130:	07405863          	blez	s4,800001a0 <consoleread+0xc0>
    while(cons.r == cons.w){
    80000134:	0984a783          	lw	a5,152(s1)
    80000138:	09c4a703          	lw	a4,156(s1)
    8000013c:	02f71463          	bne	a4,a5,80000164 <consoleread+0x84>
      if(myproc()->killed){
    80000140:	00001097          	auipc	ra,0x1
    80000144:	700080e7          	jalr	1792(ra) # 80001840 <myproc>
    80000148:	591c                	lw	a5,48(a0)
    8000014a:	e7b5                	bnez	a5,800001b6 <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    8000014c:	85ce                	mv	a1,s3
    8000014e:	854a                	mv	a0,s2
    80000150:	00002097          	auipc	ra,0x2
    80000154:	e92080e7          	jalr	-366(ra) # 80001fe2 <sleep>
    while(cons.r == cons.w){
    80000158:	0984a783          	lw	a5,152(s1)
    8000015c:	09c4a703          	lw	a4,156(s1)
    80000160:	fef700e3          	beq	a4,a5,80000140 <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF];
    80000164:	0017871b          	addiw	a4,a5,1
    80000168:	08e4ac23          	sw	a4,152(s1)
    8000016c:	07f7f713          	andi	a4,a5,127
    80000170:	9726                	add	a4,a4,s1
    80000172:	01874703          	lbu	a4,24(a4)
    80000176:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    8000017a:	079c0663          	beq	s8,s9,800001e6 <consoleread+0x106>
    cbuf = c;
    8000017e:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000182:	4685                	li	a3,1
    80000184:	f8f40613          	addi	a2,s0,-113
    80000188:	85d6                	mv	a1,s5
    8000018a:	855a                	mv	a0,s6
    8000018c:	00002097          	auipc	ra,0x2
    80000190:	0b6080e7          	jalr	182(ra) # 80002242 <either_copyout>
    80000194:	01a50663          	beq	a0,s10,800001a0 <consoleread+0xc0>
    dst++;
    80000198:	0a85                	addi	s5,s5,1
    --n;
    8000019a:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    8000019c:	f9bc1ae3          	bne	s8,s11,80000130 <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    800001a0:	00011517          	auipc	a0,0x11
    800001a4:	66050513          	addi	a0,a0,1632 # 80011800 <cons>
    800001a8:	00001097          	auipc	ra,0x1
    800001ac:	97a080e7          	jalr	-1670(ra) # 80000b22 <release>

  return target - n;
    800001b0:	414b853b          	subw	a0,s7,s4
    800001b4:	a811                	j	800001c8 <consoleread+0xe8>
        release(&cons.lock);
    800001b6:	00011517          	auipc	a0,0x11
    800001ba:	64a50513          	addi	a0,a0,1610 # 80011800 <cons>
    800001be:	00001097          	auipc	ra,0x1
    800001c2:	964080e7          	jalr	-1692(ra) # 80000b22 <release>
        return -1;
    800001c6:	557d                	li	a0,-1
}
    800001c8:	70e6                	ld	ra,120(sp)
    800001ca:	7446                	ld	s0,112(sp)
    800001cc:	74a6                	ld	s1,104(sp)
    800001ce:	7906                	ld	s2,96(sp)
    800001d0:	69e6                	ld	s3,88(sp)
    800001d2:	6a46                	ld	s4,80(sp)
    800001d4:	6aa6                	ld	s5,72(sp)
    800001d6:	6b06                	ld	s6,64(sp)
    800001d8:	7be2                	ld	s7,56(sp)
    800001da:	7c42                	ld	s8,48(sp)
    800001dc:	7ca2                	ld	s9,40(sp)
    800001de:	7d02                	ld	s10,32(sp)
    800001e0:	6de2                	ld	s11,24(sp)
    800001e2:	6109                	addi	sp,sp,128
    800001e4:	8082                	ret
      if(n < target){
    800001e6:	000a071b          	sext.w	a4,s4
    800001ea:	fb777be3          	bgeu	a4,s7,800001a0 <consoleread+0xc0>
        cons.r--;
    800001ee:	00011717          	auipc	a4,0x11
    800001f2:	6af72523          	sw	a5,1706(a4) # 80011898 <cons+0x98>
    800001f6:	b76d                	j	800001a0 <consoleread+0xc0>

00000000800001f8 <consputc>:
  if(panicked){
    800001f8:	00026797          	auipc	a5,0x26
    800001fc:	e087a783          	lw	a5,-504(a5) # 80026000 <panicked>
    80000200:	c391                	beqz	a5,80000204 <consputc+0xc>
    for(;;)
    80000202:	a001                	j	80000202 <consputc+0xa>
{
    80000204:	1141                	addi	sp,sp,-16
    80000206:	e406                	sd	ra,8(sp)
    80000208:	e022                	sd	s0,0(sp)
    8000020a:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    8000020c:	10000793          	li	a5,256
    80000210:	00f50a63          	beq	a0,a5,80000224 <consputc+0x2c>
    uartputc(c);
    80000214:	00000097          	auipc	ra,0x0
    80000218:	5d2080e7          	jalr	1490(ra) # 800007e6 <uartputc>
}
    8000021c:	60a2                	ld	ra,8(sp)
    8000021e:	6402                	ld	s0,0(sp)
    80000220:	0141                	addi	sp,sp,16
    80000222:	8082                	ret
    uartputc('\b'); uartputc(' '); uartputc('\b');
    80000224:	4521                	li	a0,8
    80000226:	00000097          	auipc	ra,0x0
    8000022a:	5c0080e7          	jalr	1472(ra) # 800007e6 <uartputc>
    8000022e:	02000513          	li	a0,32
    80000232:	00000097          	auipc	ra,0x0
    80000236:	5b4080e7          	jalr	1460(ra) # 800007e6 <uartputc>
    8000023a:	4521                	li	a0,8
    8000023c:	00000097          	auipc	ra,0x0
    80000240:	5aa080e7          	jalr	1450(ra) # 800007e6 <uartputc>
    80000244:	bfe1                	j	8000021c <consputc+0x24>

0000000080000246 <consolewrite>:
{
    80000246:	715d                	addi	sp,sp,-80
    80000248:	e486                	sd	ra,72(sp)
    8000024a:	e0a2                	sd	s0,64(sp)
    8000024c:	fc26                	sd	s1,56(sp)
    8000024e:	f84a                	sd	s2,48(sp)
    80000250:	f44e                	sd	s3,40(sp)
    80000252:	f052                	sd	s4,32(sp)
    80000254:	ec56                	sd	s5,24(sp)
    80000256:	0880                	addi	s0,sp,80
    80000258:	89aa                	mv	s3,a0
    8000025a:	84ae                	mv	s1,a1
    8000025c:	8ab2                	mv	s5,a2
  acquire(&cons.lock);
    8000025e:	00011517          	auipc	a0,0x11
    80000262:	5a250513          	addi	a0,a0,1442 # 80011800 <cons>
    80000266:	00001097          	auipc	ra,0x1
    8000026a:	868080e7          	jalr	-1944(ra) # 80000ace <acquire>
  for(i = 0; i < n; i++){
    8000026e:	03505e63          	blez	s5,800002aa <consolewrite+0x64>
    80000272:	00148913          	addi	s2,s1,1
    80000276:	fffa879b          	addiw	a5,s5,-1
    8000027a:	1782                	slli	a5,a5,0x20
    8000027c:	9381                	srli	a5,a5,0x20
    8000027e:	993e                	add	s2,s2,a5
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000280:	5a7d                	li	s4,-1
    80000282:	4685                	li	a3,1
    80000284:	8626                	mv	a2,s1
    80000286:	85ce                	mv	a1,s3
    80000288:	fbf40513          	addi	a0,s0,-65
    8000028c:	00002097          	auipc	ra,0x2
    80000290:	00c080e7          	jalr	12(ra) # 80002298 <either_copyin>
    80000294:	01450b63          	beq	a0,s4,800002aa <consolewrite+0x64>
    consputc(c);
    80000298:	fbf44503          	lbu	a0,-65(s0)
    8000029c:	00000097          	auipc	ra,0x0
    800002a0:	f5c080e7          	jalr	-164(ra) # 800001f8 <consputc>
  for(i = 0; i < n; i++){
    800002a4:	0485                	addi	s1,s1,1
    800002a6:	fd249ee3          	bne	s1,s2,80000282 <consolewrite+0x3c>
  release(&cons.lock);
    800002aa:	00011517          	auipc	a0,0x11
    800002ae:	55650513          	addi	a0,a0,1366 # 80011800 <cons>
    800002b2:	00001097          	auipc	ra,0x1
    800002b6:	870080e7          	jalr	-1936(ra) # 80000b22 <release>
}
    800002ba:	8556                	mv	a0,s5
    800002bc:	60a6                	ld	ra,72(sp)
    800002be:	6406                	ld	s0,64(sp)
    800002c0:	74e2                	ld	s1,56(sp)
    800002c2:	7942                	ld	s2,48(sp)
    800002c4:	79a2                	ld	s3,40(sp)
    800002c6:	7a02                	ld	s4,32(sp)
    800002c8:	6ae2                	ld	s5,24(sp)
    800002ca:	6161                	addi	sp,sp,80
    800002cc:	8082                	ret

00000000800002ce <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002ce:	1101                	addi	sp,sp,-32
    800002d0:	ec06                	sd	ra,24(sp)
    800002d2:	e822                	sd	s0,16(sp)
    800002d4:	e426                	sd	s1,8(sp)
    800002d6:	e04a                	sd	s2,0(sp)
    800002d8:	1000                	addi	s0,sp,32
    800002da:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002dc:	00011517          	auipc	a0,0x11
    800002e0:	52450513          	addi	a0,a0,1316 # 80011800 <cons>
    800002e4:	00000097          	auipc	ra,0x0
    800002e8:	7ea080e7          	jalr	2026(ra) # 80000ace <acquire>

  switch(c){
    800002ec:	47d5                	li	a5,21
    800002ee:	0af48663          	beq	s1,a5,8000039a <consoleintr+0xcc>
    800002f2:	0297ca63          	blt	a5,s1,80000326 <consoleintr+0x58>
    800002f6:	47a1                	li	a5,8
    800002f8:	0ef48763          	beq	s1,a5,800003e6 <consoleintr+0x118>
    800002fc:	47c1                	li	a5,16
    800002fe:	10f49a63          	bne	s1,a5,80000412 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    80000302:	00002097          	auipc	ra,0x2
    80000306:	fec080e7          	jalr	-20(ra) # 800022ee <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    8000030a:	00011517          	auipc	a0,0x11
    8000030e:	4f650513          	addi	a0,a0,1270 # 80011800 <cons>
    80000312:	00001097          	auipc	ra,0x1
    80000316:	810080e7          	jalr	-2032(ra) # 80000b22 <release>
}
    8000031a:	60e2                	ld	ra,24(sp)
    8000031c:	6442                	ld	s0,16(sp)
    8000031e:	64a2                	ld	s1,8(sp)
    80000320:	6902                	ld	s2,0(sp)
    80000322:	6105                	addi	sp,sp,32
    80000324:	8082                	ret
  switch(c){
    80000326:	07f00793          	li	a5,127
    8000032a:	0af48e63          	beq	s1,a5,800003e6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    8000032e:	00011717          	auipc	a4,0x11
    80000332:	4d270713          	addi	a4,a4,1234 # 80011800 <cons>
    80000336:	0a072783          	lw	a5,160(a4)
    8000033a:	09872703          	lw	a4,152(a4)
    8000033e:	9f99                	subw	a5,a5,a4
    80000340:	07f00713          	li	a4,127
    80000344:	fcf763e3          	bltu	a4,a5,8000030a <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000348:	47b5                	li	a5,13
    8000034a:	0cf48763          	beq	s1,a5,80000418 <consoleintr+0x14a>
      consputc(c);
    8000034e:	8526                	mv	a0,s1
    80000350:	00000097          	auipc	ra,0x0
    80000354:	ea8080e7          	jalr	-344(ra) # 800001f8 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000358:	00011797          	auipc	a5,0x11
    8000035c:	4a878793          	addi	a5,a5,1192 # 80011800 <cons>
    80000360:	0a07a703          	lw	a4,160(a5)
    80000364:	0017069b          	addiw	a3,a4,1
    80000368:	0006861b          	sext.w	a2,a3
    8000036c:	0ad7a023          	sw	a3,160(a5)
    80000370:	07f77713          	andi	a4,a4,127
    80000374:	97ba                	add	a5,a5,a4
    80000376:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    8000037a:	47a9                	li	a5,10
    8000037c:	0cf48563          	beq	s1,a5,80000446 <consoleintr+0x178>
    80000380:	4791                	li	a5,4
    80000382:	0cf48263          	beq	s1,a5,80000446 <consoleintr+0x178>
    80000386:	00011797          	auipc	a5,0x11
    8000038a:	5127a783          	lw	a5,1298(a5) # 80011898 <cons+0x98>
    8000038e:	0807879b          	addiw	a5,a5,128
    80000392:	f6f61ce3          	bne	a2,a5,8000030a <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000396:	863e                	mv	a2,a5
    80000398:	a07d                	j	80000446 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000039a:	00011717          	auipc	a4,0x11
    8000039e:	46670713          	addi	a4,a4,1126 # 80011800 <cons>
    800003a2:	0a072783          	lw	a5,160(a4)
    800003a6:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003aa:	00011497          	auipc	s1,0x11
    800003ae:	45648493          	addi	s1,s1,1110 # 80011800 <cons>
    while(cons.e != cons.w &&
    800003b2:	4929                	li	s2,10
    800003b4:	f4f70be3          	beq	a4,a5,8000030a <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003b8:	37fd                	addiw	a5,a5,-1
    800003ba:	07f7f713          	andi	a4,a5,127
    800003be:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003c0:	01874703          	lbu	a4,24(a4)
    800003c4:	f52703e3          	beq	a4,s2,8000030a <consoleintr+0x3c>
      cons.e--;
    800003c8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003cc:	10000513          	li	a0,256
    800003d0:	00000097          	auipc	ra,0x0
    800003d4:	e28080e7          	jalr	-472(ra) # 800001f8 <consputc>
    while(cons.e != cons.w &&
    800003d8:	0a04a783          	lw	a5,160(s1)
    800003dc:	09c4a703          	lw	a4,156(s1)
    800003e0:	fcf71ce3          	bne	a4,a5,800003b8 <consoleintr+0xea>
    800003e4:	b71d                	j	8000030a <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003e6:	00011717          	auipc	a4,0x11
    800003ea:	41a70713          	addi	a4,a4,1050 # 80011800 <cons>
    800003ee:	0a072783          	lw	a5,160(a4)
    800003f2:	09c72703          	lw	a4,156(a4)
    800003f6:	f0f70ae3          	beq	a4,a5,8000030a <consoleintr+0x3c>
      cons.e--;
    800003fa:	37fd                	addiw	a5,a5,-1
    800003fc:	00011717          	auipc	a4,0x11
    80000400:	4af72223          	sw	a5,1188(a4) # 800118a0 <cons+0xa0>
      consputc(BACKSPACE);
    80000404:	10000513          	li	a0,256
    80000408:	00000097          	auipc	ra,0x0
    8000040c:	df0080e7          	jalr	-528(ra) # 800001f8 <consputc>
    80000410:	bded                	j	8000030a <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000412:	ee048ce3          	beqz	s1,8000030a <consoleintr+0x3c>
    80000416:	bf21                	j	8000032e <consoleintr+0x60>
      consputc(c);
    80000418:	4529                	li	a0,10
    8000041a:	00000097          	auipc	ra,0x0
    8000041e:	dde080e7          	jalr	-546(ra) # 800001f8 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000422:	00011797          	auipc	a5,0x11
    80000426:	3de78793          	addi	a5,a5,990 # 80011800 <cons>
    8000042a:	0a07a703          	lw	a4,160(a5)
    8000042e:	0017069b          	addiw	a3,a4,1
    80000432:	0006861b          	sext.w	a2,a3
    80000436:	0ad7a023          	sw	a3,160(a5)
    8000043a:	07f77713          	andi	a4,a4,127
    8000043e:	97ba                	add	a5,a5,a4
    80000440:	4729                	li	a4,10
    80000442:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000446:	00011797          	auipc	a5,0x11
    8000044a:	44c7ab23          	sw	a2,1110(a5) # 8001189c <cons+0x9c>
        wakeup(&cons.r);
    8000044e:	00011517          	auipc	a0,0x11
    80000452:	44a50513          	addi	a0,a0,1098 # 80011898 <cons+0x98>
    80000456:	00002097          	auipc	ra,0x2
    8000045a:	d12080e7          	jalr	-750(ra) # 80002168 <wakeup>
    8000045e:	b575                	j	8000030a <consoleintr+0x3c>

0000000080000460 <consoleinit>:

void
consoleinit(void)
{
    80000460:	1141                	addi	sp,sp,-16
    80000462:	e406                	sd	ra,8(sp)
    80000464:	e022                	sd	s0,0(sp)
    80000466:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000468:	00007597          	auipc	a1,0x7
    8000046c:	cb058593          	addi	a1,a1,-848 # 80007118 <userret+0x88>
    80000470:	00011517          	auipc	a0,0x11
    80000474:	39050513          	addi	a0,a0,912 # 80011800 <cons>
    80000478:	00000097          	auipc	ra,0x0
    8000047c:	544080e7          	jalr	1348(ra) # 800009bc <initlock>

  uartinit();
    80000480:	00000097          	auipc	ra,0x0
    80000484:	330080e7          	jalr	816(ra) # 800007b0 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000488:	00021797          	auipc	a5,0x21
    8000048c:	5b878793          	addi	a5,a5,1464 # 80021a40 <devsw>
    80000490:	00000717          	auipc	a4,0x0
    80000494:	c5070713          	addi	a4,a4,-944 # 800000e0 <consoleread>
    80000498:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000049a:	00000717          	auipc	a4,0x0
    8000049e:	dac70713          	addi	a4,a4,-596 # 80000246 <consolewrite>
    800004a2:	ef98                	sd	a4,24(a5)
}
    800004a4:	60a2                	ld	ra,8(sp)
    800004a6:	6402                	ld	s0,0(sp)
    800004a8:	0141                	addi	sp,sp,16
    800004aa:	8082                	ret

00000000800004ac <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    800004ac:	7179                	addi	sp,sp,-48
    800004ae:	f406                	sd	ra,40(sp)
    800004b0:	f022                	sd	s0,32(sp)
    800004b2:	ec26                	sd	s1,24(sp)
    800004b4:	e84a                	sd	s2,16(sp)
    800004b6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004b8:	c219                	beqz	a2,800004be <printint+0x12>
    800004ba:	08054663          	bltz	a0,80000546 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004be:	2501                	sext.w	a0,a0
    800004c0:	4881                	li	a7,0
    800004c2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004c6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004c8:	2581                	sext.w	a1,a1
    800004ca:	00007617          	auipc	a2,0x7
    800004ce:	34660613          	addi	a2,a2,838 # 80007810 <digits>
    800004d2:	883a                	mv	a6,a4
    800004d4:	2705                	addiw	a4,a4,1
    800004d6:	02b577bb          	remuw	a5,a0,a1
    800004da:	1782                	slli	a5,a5,0x20
    800004dc:	9381                	srli	a5,a5,0x20
    800004de:	97b2                	add	a5,a5,a2
    800004e0:	0007c783          	lbu	a5,0(a5)
    800004e4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004e8:	0005079b          	sext.w	a5,a0
    800004ec:	02b5553b          	divuw	a0,a0,a1
    800004f0:	0685                	addi	a3,a3,1
    800004f2:	feb7f0e3          	bgeu	a5,a1,800004d2 <printint+0x26>

  if(sign)
    800004f6:	00088b63          	beqz	a7,8000050c <printint+0x60>
    buf[i++] = '-';
    800004fa:	fe040793          	addi	a5,s0,-32
    800004fe:	973e                	add	a4,a4,a5
    80000500:	02d00793          	li	a5,45
    80000504:	fef70823          	sb	a5,-16(a4)
    80000508:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    8000050c:	02e05763          	blez	a4,8000053a <printint+0x8e>
    80000510:	fd040793          	addi	a5,s0,-48
    80000514:	00e784b3          	add	s1,a5,a4
    80000518:	fff78913          	addi	s2,a5,-1
    8000051c:	993a                	add	s2,s2,a4
    8000051e:	377d                	addiw	a4,a4,-1
    80000520:	1702                	slli	a4,a4,0x20
    80000522:	9301                	srli	a4,a4,0x20
    80000524:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000528:	fff4c503          	lbu	a0,-1(s1)
    8000052c:	00000097          	auipc	ra,0x0
    80000530:	ccc080e7          	jalr	-820(ra) # 800001f8 <consputc>
  while(--i >= 0)
    80000534:	14fd                	addi	s1,s1,-1
    80000536:	ff2499e3          	bne	s1,s2,80000528 <printint+0x7c>
}
    8000053a:	70a2                	ld	ra,40(sp)
    8000053c:	7402                	ld	s0,32(sp)
    8000053e:	64e2                	ld	s1,24(sp)
    80000540:	6942                	ld	s2,16(sp)
    80000542:	6145                	addi	sp,sp,48
    80000544:	8082                	ret
    x = -xx;
    80000546:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000054a:	4885                	li	a7,1
    x = -xx;
    8000054c:	bf9d                	j	800004c2 <printint+0x16>

000000008000054e <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000054e:	1101                	addi	sp,sp,-32
    80000550:	ec06                	sd	ra,24(sp)
    80000552:	e822                	sd	s0,16(sp)
    80000554:	e426                	sd	s1,8(sp)
    80000556:	1000                	addi	s0,sp,32
    80000558:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000055a:	00011797          	auipc	a5,0x11
    8000055e:	3607a323          	sw	zero,870(a5) # 800118c0 <pr+0x18>
  printf("panic: ");
    80000562:	00007517          	auipc	a0,0x7
    80000566:	bbe50513          	addi	a0,a0,-1090 # 80007120 <userret+0x90>
    8000056a:	00000097          	auipc	ra,0x0
    8000056e:	02e080e7          	jalr	46(ra) # 80000598 <printf>
  printf(s);
    80000572:	8526                	mv	a0,s1
    80000574:	00000097          	auipc	ra,0x0
    80000578:	024080e7          	jalr	36(ra) # 80000598 <printf>
  printf("\n");
    8000057c:	00007517          	auipc	a0,0x7
    80000580:	c3450513          	addi	a0,a0,-972 # 800071b0 <userret+0x120>
    80000584:	00000097          	auipc	ra,0x0
    80000588:	014080e7          	jalr	20(ra) # 80000598 <printf>
  panicked = 1; // freeze other CPUs
    8000058c:	4785                	li	a5,1
    8000058e:	00026717          	auipc	a4,0x26
    80000592:	a6f72923          	sw	a5,-1422(a4) # 80026000 <panicked>
  for(;;)
    80000596:	a001                	j	80000596 <panic+0x48>

0000000080000598 <printf>:
{
    80000598:	7131                	addi	sp,sp,-192
    8000059a:	fc86                	sd	ra,120(sp)
    8000059c:	f8a2                	sd	s0,112(sp)
    8000059e:	f4a6                	sd	s1,104(sp)
    800005a0:	f0ca                	sd	s2,96(sp)
    800005a2:	ecce                	sd	s3,88(sp)
    800005a4:	e8d2                	sd	s4,80(sp)
    800005a6:	e4d6                	sd	s5,72(sp)
    800005a8:	e0da                	sd	s6,64(sp)
    800005aa:	fc5e                	sd	s7,56(sp)
    800005ac:	f862                	sd	s8,48(sp)
    800005ae:	f466                	sd	s9,40(sp)
    800005b0:	f06a                	sd	s10,32(sp)
    800005b2:	ec6e                	sd	s11,24(sp)
    800005b4:	0100                	addi	s0,sp,128
    800005b6:	8a2a                	mv	s4,a0
    800005b8:	e40c                	sd	a1,8(s0)
    800005ba:	e810                	sd	a2,16(s0)
    800005bc:	ec14                	sd	a3,24(s0)
    800005be:	f018                	sd	a4,32(s0)
    800005c0:	f41c                	sd	a5,40(s0)
    800005c2:	03043823          	sd	a6,48(s0)
    800005c6:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005ca:	00011d97          	auipc	s11,0x11
    800005ce:	2f6dad83          	lw	s11,758(s11) # 800118c0 <pr+0x18>
  if(locking)
    800005d2:	020d9b63          	bnez	s11,80000608 <printf+0x70>
  if (fmt == 0)
    800005d6:	040a0263          	beqz	s4,8000061a <printf+0x82>
  va_start(ap, fmt);
    800005da:	00840793          	addi	a5,s0,8
    800005de:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005e2:	000a4503          	lbu	a0,0(s4)
    800005e6:	16050263          	beqz	a0,8000074a <printf+0x1b2>
    800005ea:	4481                	li	s1,0
    if(c != '%'){
    800005ec:	02500a93          	li	s5,37
    switch(c){
    800005f0:	07000b13          	li	s6,112
  consputc('x');
    800005f4:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005f6:	00007b97          	auipc	s7,0x7
    800005fa:	21ab8b93          	addi	s7,s7,538 # 80007810 <digits>
    switch(c){
    800005fe:	07300c93          	li	s9,115
    80000602:	06400c13          	li	s8,100
    80000606:	a82d                	j	80000640 <printf+0xa8>
    acquire(&pr.lock);
    80000608:	00011517          	auipc	a0,0x11
    8000060c:	2a050513          	addi	a0,a0,672 # 800118a8 <pr>
    80000610:	00000097          	auipc	ra,0x0
    80000614:	4be080e7          	jalr	1214(ra) # 80000ace <acquire>
    80000618:	bf7d                	j	800005d6 <printf+0x3e>
    panic("null fmt");
    8000061a:	00007517          	auipc	a0,0x7
    8000061e:	b1650513          	addi	a0,a0,-1258 # 80007130 <userret+0xa0>
    80000622:	00000097          	auipc	ra,0x0
    80000626:	f2c080e7          	jalr	-212(ra) # 8000054e <panic>
      consputc(c);
    8000062a:	00000097          	auipc	ra,0x0
    8000062e:	bce080e7          	jalr	-1074(ra) # 800001f8 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000632:	2485                	addiw	s1,s1,1
    80000634:	009a07b3          	add	a5,s4,s1
    80000638:	0007c503          	lbu	a0,0(a5)
    8000063c:	10050763          	beqz	a0,8000074a <printf+0x1b2>
    if(c != '%'){
    80000640:	ff5515e3          	bne	a0,s5,8000062a <printf+0x92>
    c = fmt[++i] & 0xff;
    80000644:	2485                	addiw	s1,s1,1
    80000646:	009a07b3          	add	a5,s4,s1
    8000064a:	0007c783          	lbu	a5,0(a5)
    8000064e:	0007891b          	sext.w	s2,a5
    if(c == 0)
    80000652:	cfe5                	beqz	a5,8000074a <printf+0x1b2>
    switch(c){
    80000654:	05678a63          	beq	a5,s6,800006a8 <printf+0x110>
    80000658:	02fb7663          	bgeu	s6,a5,80000684 <printf+0xec>
    8000065c:	09978963          	beq	a5,s9,800006ee <printf+0x156>
    80000660:	07800713          	li	a4,120
    80000664:	0ce79863          	bne	a5,a4,80000734 <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    80000668:	f8843783          	ld	a5,-120(s0)
    8000066c:	00878713          	addi	a4,a5,8
    80000670:	f8e43423          	sd	a4,-120(s0)
    80000674:	4605                	li	a2,1
    80000676:	85ea                	mv	a1,s10
    80000678:	4388                	lw	a0,0(a5)
    8000067a:	00000097          	auipc	ra,0x0
    8000067e:	e32080e7          	jalr	-462(ra) # 800004ac <printint>
      break;
    80000682:	bf45                	j	80000632 <printf+0x9a>
    switch(c){
    80000684:	0b578263          	beq	a5,s5,80000728 <printf+0x190>
    80000688:	0b879663          	bne	a5,s8,80000734 <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    8000068c:	f8843783          	ld	a5,-120(s0)
    80000690:	00878713          	addi	a4,a5,8
    80000694:	f8e43423          	sd	a4,-120(s0)
    80000698:	4605                	li	a2,1
    8000069a:	45a9                	li	a1,10
    8000069c:	4388                	lw	a0,0(a5)
    8000069e:	00000097          	auipc	ra,0x0
    800006a2:	e0e080e7          	jalr	-498(ra) # 800004ac <printint>
      break;
    800006a6:	b771                	j	80000632 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    800006a8:	f8843783          	ld	a5,-120(s0)
    800006ac:	00878713          	addi	a4,a5,8
    800006b0:	f8e43423          	sd	a4,-120(s0)
    800006b4:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006b8:	03000513          	li	a0,48
    800006bc:	00000097          	auipc	ra,0x0
    800006c0:	b3c080e7          	jalr	-1220(ra) # 800001f8 <consputc>
  consputc('x');
    800006c4:	07800513          	li	a0,120
    800006c8:	00000097          	auipc	ra,0x0
    800006cc:	b30080e7          	jalr	-1232(ra) # 800001f8 <consputc>
    800006d0:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006d2:	03c9d793          	srli	a5,s3,0x3c
    800006d6:	97de                	add	a5,a5,s7
    800006d8:	0007c503          	lbu	a0,0(a5)
    800006dc:	00000097          	auipc	ra,0x0
    800006e0:	b1c080e7          	jalr	-1252(ra) # 800001f8 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006e4:	0992                	slli	s3,s3,0x4
    800006e6:	397d                	addiw	s2,s2,-1
    800006e8:	fe0915e3          	bnez	s2,800006d2 <printf+0x13a>
    800006ec:	b799                	j	80000632 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006ee:	f8843783          	ld	a5,-120(s0)
    800006f2:	00878713          	addi	a4,a5,8
    800006f6:	f8e43423          	sd	a4,-120(s0)
    800006fa:	0007b903          	ld	s2,0(a5)
    800006fe:	00090e63          	beqz	s2,8000071a <printf+0x182>
      for(; *s; s++)
    80000702:	00094503          	lbu	a0,0(s2)
    80000706:	d515                	beqz	a0,80000632 <printf+0x9a>
        consputc(*s);
    80000708:	00000097          	auipc	ra,0x0
    8000070c:	af0080e7          	jalr	-1296(ra) # 800001f8 <consputc>
      for(; *s; s++)
    80000710:	0905                	addi	s2,s2,1
    80000712:	00094503          	lbu	a0,0(s2)
    80000716:	f96d                	bnez	a0,80000708 <printf+0x170>
    80000718:	bf29                	j	80000632 <printf+0x9a>
        s = "(null)";
    8000071a:	00007917          	auipc	s2,0x7
    8000071e:	a0e90913          	addi	s2,s2,-1522 # 80007128 <userret+0x98>
      for(; *s; s++)
    80000722:	02800513          	li	a0,40
    80000726:	b7cd                	j	80000708 <printf+0x170>
      consputc('%');
    80000728:	8556                	mv	a0,s5
    8000072a:	00000097          	auipc	ra,0x0
    8000072e:	ace080e7          	jalr	-1330(ra) # 800001f8 <consputc>
      break;
    80000732:	b701                	j	80000632 <printf+0x9a>
      consputc('%');
    80000734:	8556                	mv	a0,s5
    80000736:	00000097          	auipc	ra,0x0
    8000073a:	ac2080e7          	jalr	-1342(ra) # 800001f8 <consputc>
      consputc(c);
    8000073e:	854a                	mv	a0,s2
    80000740:	00000097          	auipc	ra,0x0
    80000744:	ab8080e7          	jalr	-1352(ra) # 800001f8 <consputc>
      break;
    80000748:	b5ed                	j	80000632 <printf+0x9a>
  if(locking)
    8000074a:	020d9163          	bnez	s11,8000076c <printf+0x1d4>
}
    8000074e:	70e6                	ld	ra,120(sp)
    80000750:	7446                	ld	s0,112(sp)
    80000752:	74a6                	ld	s1,104(sp)
    80000754:	7906                	ld	s2,96(sp)
    80000756:	69e6                	ld	s3,88(sp)
    80000758:	6a46                	ld	s4,80(sp)
    8000075a:	6aa6                	ld	s5,72(sp)
    8000075c:	6b06                	ld	s6,64(sp)
    8000075e:	7be2                	ld	s7,56(sp)
    80000760:	7c42                	ld	s8,48(sp)
    80000762:	7ca2                	ld	s9,40(sp)
    80000764:	7d02                	ld	s10,32(sp)
    80000766:	6de2                	ld	s11,24(sp)
    80000768:	6129                	addi	sp,sp,192
    8000076a:	8082                	ret
    release(&pr.lock);
    8000076c:	00011517          	auipc	a0,0x11
    80000770:	13c50513          	addi	a0,a0,316 # 800118a8 <pr>
    80000774:	00000097          	auipc	ra,0x0
    80000778:	3ae080e7          	jalr	942(ra) # 80000b22 <release>
}
    8000077c:	bfc9                	j	8000074e <printf+0x1b6>

000000008000077e <printfinit>:
    ;
}

void
printfinit(void)
{
    8000077e:	1101                	addi	sp,sp,-32
    80000780:	ec06                	sd	ra,24(sp)
    80000782:	e822                	sd	s0,16(sp)
    80000784:	e426                	sd	s1,8(sp)
    80000786:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000788:	00011497          	auipc	s1,0x11
    8000078c:	12048493          	addi	s1,s1,288 # 800118a8 <pr>
    80000790:	00007597          	auipc	a1,0x7
    80000794:	9b058593          	addi	a1,a1,-1616 # 80007140 <userret+0xb0>
    80000798:	8526                	mv	a0,s1
    8000079a:	00000097          	auipc	ra,0x0
    8000079e:	222080e7          	jalr	546(ra) # 800009bc <initlock>
  pr.locking = 1;
    800007a2:	4785                	li	a5,1
    800007a4:	cc9c                	sw	a5,24(s1)
}
    800007a6:	60e2                	ld	ra,24(sp)
    800007a8:	6442                	ld	s0,16(sp)
    800007aa:	64a2                	ld	s1,8(sp)
    800007ac:	6105                	addi	sp,sp,32
    800007ae:	8082                	ret

00000000800007b0 <uartinit>:
#define ReadReg(reg) (*(Reg(reg)))
#define WriteReg(reg, v) (*(Reg(reg)) = (v))

void
uartinit(void)
{
    800007b0:	1141                	addi	sp,sp,-16
    800007b2:	e422                	sd	s0,8(sp)
    800007b4:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007b6:	100007b7          	lui	a5,0x10000
    800007ba:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, 0x80);
    800007be:	f8000713          	li	a4,-128
    800007c2:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007c6:	470d                	li	a4,3
    800007c8:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007cc:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, 0x03);
    800007d0:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, 0x07);
    800007d4:	471d                	li	a4,7
    800007d6:	00e78123          	sb	a4,2(a5)

  // enable receive interrupts.
  WriteReg(IER, 0x01);
    800007da:	4705                	li	a4,1
    800007dc:	00e780a3          	sb	a4,1(a5)
}
    800007e0:	6422                	ld	s0,8(sp)
    800007e2:	0141                	addi	sp,sp,16
    800007e4:	8082                	ret

00000000800007e6 <uartputc>:

// write one output character to the UART.
void
uartputc(int c)
{
    800007e6:	1141                	addi	sp,sp,-16
    800007e8:	e422                	sd	s0,8(sp)
    800007ea:	0800                	addi	s0,sp,16
  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & (1 << 5)) == 0)
    800007ec:	10000737          	lui	a4,0x10000
    800007f0:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    800007f4:	0ff7f793          	andi	a5,a5,255
    800007f8:	0207f793          	andi	a5,a5,32
    800007fc:	dbf5                	beqz	a5,800007f0 <uartputc+0xa>
    ;
  WriteReg(THR, c);
    800007fe:	0ff57513          	andi	a0,a0,255
    80000802:	100007b7          	lui	a5,0x10000
    80000806:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>
}
    8000080a:	6422                	ld	s0,8(sp)
    8000080c:	0141                	addi	sp,sp,16
    8000080e:	8082                	ret

0000000080000810 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000810:	1141                	addi	sp,sp,-16
    80000812:	e422                	sd	s0,8(sp)
    80000814:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000816:	100007b7          	lui	a5,0x10000
    8000081a:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    8000081e:	8b85                	andi	a5,a5,1
    80000820:	cb81                	beqz	a5,80000830 <uartgetc+0x20>
    // input data is ready.
    return ReadReg(RHR);
    80000822:	100007b7          	lui	a5,0x10000
    80000826:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    8000082a:	6422                	ld	s0,8(sp)
    8000082c:	0141                	addi	sp,sp,16
    8000082e:	8082                	ret
    return -1;
    80000830:	557d                	li	a0,-1
    80000832:	bfe5                	j	8000082a <uartgetc+0x1a>

0000000080000834 <uartintr>:

// trap.c calls here when the uart interrupts.
void
uartintr(void)
{
    80000834:	1101                	addi	sp,sp,-32
    80000836:	ec06                	sd	ra,24(sp)
    80000838:	e822                	sd	s0,16(sp)
    8000083a:	e426                	sd	s1,8(sp)
    8000083c:	1000                	addi	s0,sp,32
  while(1){
    int c = uartgetc();
    if(c == -1)
    8000083e:	54fd                	li	s1,-1
    int c = uartgetc();
    80000840:	00000097          	auipc	ra,0x0
    80000844:	fd0080e7          	jalr	-48(ra) # 80000810 <uartgetc>
    if(c == -1)
    80000848:	00950763          	beq	a0,s1,80000856 <uartintr+0x22>
      break;
    consoleintr(c);
    8000084c:	00000097          	auipc	ra,0x0
    80000850:	a82080e7          	jalr	-1406(ra) # 800002ce <consoleintr>
  while(1){
    80000854:	b7f5                	j	80000840 <uartintr+0xc>
  }
}
    80000856:	60e2                	ld	ra,24(sp)
    80000858:	6442                	ld	s0,16(sp)
    8000085a:	64a2                	ld	s1,8(sp)
    8000085c:	6105                	addi	sp,sp,32
    8000085e:	8082                	ret

0000000080000860 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    80000860:	1101                	addi	sp,sp,-32
    80000862:	ec06                	sd	ra,24(sp)
    80000864:	e822                	sd	s0,16(sp)
    80000866:	e426                	sd	s1,8(sp)
    80000868:	e04a                	sd	s2,0(sp)
    8000086a:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    8000086c:	03451793          	slli	a5,a0,0x34
    80000870:	ebb9                	bnez	a5,800008c6 <kfree+0x66>
    80000872:	84aa                	mv	s1,a0
    80000874:	00025797          	auipc	a5,0x25
    80000878:	7c078793          	addi	a5,a5,1984 # 80026034 <end>
    8000087c:	04f56563          	bltu	a0,a5,800008c6 <kfree+0x66>
    80000880:	47c5                	li	a5,17
    80000882:	07ee                	slli	a5,a5,0x1b
    80000884:	04f57163          	bgeu	a0,a5,800008c6 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000888:	6605                	lui	a2,0x1
    8000088a:	4585                	li	a1,1
    8000088c:	00000097          	auipc	ra,0x0
    80000890:	2de080e7          	jalr	734(ra) # 80000b6a <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000894:	00011917          	auipc	s2,0x11
    80000898:	03490913          	addi	s2,s2,52 # 800118c8 <kmem>
    8000089c:	854a                	mv	a0,s2
    8000089e:	00000097          	auipc	ra,0x0
    800008a2:	230080e7          	jalr	560(ra) # 80000ace <acquire>
  r->next = kmem.freelist;
    800008a6:	01893783          	ld	a5,24(s2)
    800008aa:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    800008ac:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    800008b0:	854a                	mv	a0,s2
    800008b2:	00000097          	auipc	ra,0x0
    800008b6:	270080e7          	jalr	624(ra) # 80000b22 <release>
}
    800008ba:	60e2                	ld	ra,24(sp)
    800008bc:	6442                	ld	s0,16(sp)
    800008be:	64a2                	ld	s1,8(sp)
    800008c0:	6902                	ld	s2,0(sp)
    800008c2:	6105                	addi	sp,sp,32
    800008c4:	8082                	ret
    panic("kfree");
    800008c6:	00007517          	auipc	a0,0x7
    800008ca:	88250513          	addi	a0,a0,-1918 # 80007148 <userret+0xb8>
    800008ce:	00000097          	auipc	ra,0x0
    800008d2:	c80080e7          	jalr	-896(ra) # 8000054e <panic>

00000000800008d6 <freerange>:
{
    800008d6:	7179                	addi	sp,sp,-48
    800008d8:	f406                	sd	ra,40(sp)
    800008da:	f022                	sd	s0,32(sp)
    800008dc:	ec26                	sd	s1,24(sp)
    800008de:	e84a                	sd	s2,16(sp)
    800008e0:	e44e                	sd	s3,8(sp)
    800008e2:	e052                	sd	s4,0(sp)
    800008e4:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    800008e6:	6785                	lui	a5,0x1
    800008e8:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    800008ec:	94aa                	add	s1,s1,a0
    800008ee:	757d                	lui	a0,0xfffff
    800008f0:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    800008f2:	94be                	add	s1,s1,a5
    800008f4:	0095ee63          	bltu	a1,s1,80000910 <freerange+0x3a>
    800008f8:	892e                	mv	s2,a1
    kfree(p);
    800008fa:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    800008fc:	6985                	lui	s3,0x1
    kfree(p);
    800008fe:	01448533          	add	a0,s1,s4
    80000902:	00000097          	auipc	ra,0x0
    80000906:	f5e080e7          	jalr	-162(ra) # 80000860 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    8000090a:	94ce                	add	s1,s1,s3
    8000090c:	fe9979e3          	bgeu	s2,s1,800008fe <freerange+0x28>
}
    80000910:	70a2                	ld	ra,40(sp)
    80000912:	7402                	ld	s0,32(sp)
    80000914:	64e2                	ld	s1,24(sp)
    80000916:	6942                	ld	s2,16(sp)
    80000918:	69a2                	ld	s3,8(sp)
    8000091a:	6a02                	ld	s4,0(sp)
    8000091c:	6145                	addi	sp,sp,48
    8000091e:	8082                	ret

0000000080000920 <kinit>:
{
    80000920:	1141                	addi	sp,sp,-16
    80000922:	e406                	sd	ra,8(sp)
    80000924:	e022                	sd	s0,0(sp)
    80000926:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000928:	00007597          	auipc	a1,0x7
    8000092c:	82858593          	addi	a1,a1,-2008 # 80007150 <userret+0xc0>
    80000930:	00011517          	auipc	a0,0x11
    80000934:	f9850513          	addi	a0,a0,-104 # 800118c8 <kmem>
    80000938:	00000097          	auipc	ra,0x0
    8000093c:	084080e7          	jalr	132(ra) # 800009bc <initlock>
  freerange(end, (void*)PHYSTOP);
    80000940:	45c5                	li	a1,17
    80000942:	05ee                	slli	a1,a1,0x1b
    80000944:	00025517          	auipc	a0,0x25
    80000948:	6f050513          	addi	a0,a0,1776 # 80026034 <end>
    8000094c:	00000097          	auipc	ra,0x0
    80000950:	f8a080e7          	jalr	-118(ra) # 800008d6 <freerange>
}
    80000954:	60a2                	ld	ra,8(sp)
    80000956:	6402                	ld	s0,0(sp)
    80000958:	0141                	addi	sp,sp,16
    8000095a:	8082                	ret

000000008000095c <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    8000095c:	1101                	addi	sp,sp,-32
    8000095e:	ec06                	sd	ra,24(sp)
    80000960:	e822                	sd	s0,16(sp)
    80000962:	e426                	sd	s1,8(sp)
    80000964:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000966:	00011497          	auipc	s1,0x11
    8000096a:	f6248493          	addi	s1,s1,-158 # 800118c8 <kmem>
    8000096e:	8526                	mv	a0,s1
    80000970:	00000097          	auipc	ra,0x0
    80000974:	15e080e7          	jalr	350(ra) # 80000ace <acquire>
  r = kmem.freelist;
    80000978:	6c84                	ld	s1,24(s1)
  if(r)
    8000097a:	c885                	beqz	s1,800009aa <kalloc+0x4e>
    kmem.freelist = r->next;
    8000097c:	609c                	ld	a5,0(s1)
    8000097e:	00011517          	auipc	a0,0x11
    80000982:	f4a50513          	addi	a0,a0,-182 # 800118c8 <kmem>
    80000986:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000988:	00000097          	auipc	ra,0x0
    8000098c:	19a080e7          	jalr	410(ra) # 80000b22 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000990:	6605                	lui	a2,0x1
    80000992:	4595                	li	a1,5
    80000994:	8526                	mv	a0,s1
    80000996:	00000097          	auipc	ra,0x0
    8000099a:	1d4080e7          	jalr	468(ra) # 80000b6a <memset>
  return (void*)r;
}
    8000099e:	8526                	mv	a0,s1
    800009a0:	60e2                	ld	ra,24(sp)
    800009a2:	6442                	ld	s0,16(sp)
    800009a4:	64a2                	ld	s1,8(sp)
    800009a6:	6105                	addi	sp,sp,32
    800009a8:	8082                	ret
  release(&kmem.lock);
    800009aa:	00011517          	auipc	a0,0x11
    800009ae:	f1e50513          	addi	a0,a0,-226 # 800118c8 <kmem>
    800009b2:	00000097          	auipc	ra,0x0
    800009b6:	170080e7          	jalr	368(ra) # 80000b22 <release>
  if(r)
    800009ba:	b7d5                	j	8000099e <kalloc+0x42>

00000000800009bc <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    800009bc:	1141                	addi	sp,sp,-16
    800009be:	e422                	sd	s0,8(sp)
    800009c0:	0800                	addi	s0,sp,16
  lk->name = name;
    800009c2:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    800009c4:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    800009c8:	00053823          	sd	zero,16(a0)
}
    800009cc:	6422                	ld	s0,8(sp)
    800009ce:	0141                	addi	sp,sp,16
    800009d0:	8082                	ret

00000000800009d2 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    800009d2:	1101                	addi	sp,sp,-32
    800009d4:	ec06                	sd	ra,24(sp)
    800009d6:	e822                	sd	s0,16(sp)
    800009d8:	e426                	sd	s1,8(sp)
    800009da:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800009dc:	100024f3          	csrr	s1,sstatus
    800009e0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800009e4:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800009e6:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    800009ea:	00001097          	auipc	ra,0x1
    800009ee:	e3a080e7          	jalr	-454(ra) # 80001824 <mycpu>
    800009f2:	5d3c                	lw	a5,120(a0)
    800009f4:	cf89                	beqz	a5,80000a0e <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    800009f6:	00001097          	auipc	ra,0x1
    800009fa:	e2e080e7          	jalr	-466(ra) # 80001824 <mycpu>
    800009fe:	5d3c                	lw	a5,120(a0)
    80000a00:	2785                	addiw	a5,a5,1
    80000a02:	dd3c                	sw	a5,120(a0)
}
    80000a04:	60e2                	ld	ra,24(sp)
    80000a06:	6442                	ld	s0,16(sp)
    80000a08:	64a2                	ld	s1,8(sp)
    80000a0a:	6105                	addi	sp,sp,32
    80000a0c:	8082                	ret
    mycpu()->intena = old;
    80000a0e:	00001097          	auipc	ra,0x1
    80000a12:	e16080e7          	jalr	-490(ra) # 80001824 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000a16:	8085                	srli	s1,s1,0x1
    80000a18:	8885                	andi	s1,s1,1
    80000a1a:	dd64                	sw	s1,124(a0)
    80000a1c:	bfe9                	j	800009f6 <push_off+0x24>

0000000080000a1e <pop_off>:

void
pop_off(void)
{
    80000a1e:	1141                	addi	sp,sp,-16
    80000a20:	e406                	sd	ra,8(sp)
    80000a22:	e022                	sd	s0,0(sp)
    80000a24:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000a26:	00001097          	auipc	ra,0x1
    80000a2a:	dfe080e7          	jalr	-514(ra) # 80001824 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000a2e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000a32:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000a34:	ef8d                	bnez	a5,80000a6e <pop_off+0x50>
    panic("pop_off - interruptible");
  c->noff -= 1;
    80000a36:	5d3c                	lw	a5,120(a0)
    80000a38:	37fd                	addiw	a5,a5,-1
    80000a3a:	0007871b          	sext.w	a4,a5
    80000a3e:	dd3c                	sw	a5,120(a0)
  if(c->noff < 0)
    80000a40:	02079693          	slli	a3,a5,0x20
    80000a44:	0206cd63          	bltz	a3,80000a7e <pop_off+0x60>
    panic("pop_off");
  if(c->noff == 0 && c->intena)
    80000a48:	ef19                	bnez	a4,80000a66 <pop_off+0x48>
    80000a4a:	5d7c                	lw	a5,124(a0)
    80000a4c:	cf89                	beqz	a5,80000a66 <pop_off+0x48>
  asm volatile("csrr %0, sie" : "=r" (x) );
    80000a4e:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    80000a52:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    80000a56:	10479073          	csrw	sie,a5
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000a5a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000a5e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000a62:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000a66:	60a2                	ld	ra,8(sp)
    80000a68:	6402                	ld	s0,0(sp)
    80000a6a:	0141                	addi	sp,sp,16
    80000a6c:	8082                	ret
    panic("pop_off - interruptible");
    80000a6e:	00006517          	auipc	a0,0x6
    80000a72:	6ea50513          	addi	a0,a0,1770 # 80007158 <userret+0xc8>
    80000a76:	00000097          	auipc	ra,0x0
    80000a7a:	ad8080e7          	jalr	-1320(ra) # 8000054e <panic>
    panic("pop_off");
    80000a7e:	00006517          	auipc	a0,0x6
    80000a82:	6f250513          	addi	a0,a0,1778 # 80007170 <userret+0xe0>
    80000a86:	00000097          	auipc	ra,0x0
    80000a8a:	ac8080e7          	jalr	-1336(ra) # 8000054e <panic>

0000000080000a8e <holding>:
{
    80000a8e:	1101                	addi	sp,sp,-32
    80000a90:	ec06                	sd	ra,24(sp)
    80000a92:	e822                	sd	s0,16(sp)
    80000a94:	e426                	sd	s1,8(sp)
    80000a96:	1000                	addi	s0,sp,32
    80000a98:	84aa                	mv	s1,a0
  push_off();
    80000a9a:	00000097          	auipc	ra,0x0
    80000a9e:	f38080e7          	jalr	-200(ra) # 800009d2 <push_off>
  r = (lk->locked && lk->cpu == mycpu());
    80000aa2:	409c                	lw	a5,0(s1)
    80000aa4:	ef81                	bnez	a5,80000abc <holding+0x2e>
    80000aa6:	4481                	li	s1,0
  pop_off();
    80000aa8:	00000097          	auipc	ra,0x0
    80000aac:	f76080e7          	jalr	-138(ra) # 80000a1e <pop_off>
}
    80000ab0:	8526                	mv	a0,s1
    80000ab2:	60e2                	ld	ra,24(sp)
    80000ab4:	6442                	ld	s0,16(sp)
    80000ab6:	64a2                	ld	s1,8(sp)
    80000ab8:	6105                	addi	sp,sp,32
    80000aba:	8082                	ret
  r = (lk->locked && lk->cpu == mycpu());
    80000abc:	6884                	ld	s1,16(s1)
    80000abe:	00001097          	auipc	ra,0x1
    80000ac2:	d66080e7          	jalr	-666(ra) # 80001824 <mycpu>
    80000ac6:	8c89                	sub	s1,s1,a0
    80000ac8:	0014b493          	seqz	s1,s1
    80000acc:	bff1                	j	80000aa8 <holding+0x1a>

0000000080000ace <acquire>:
{
    80000ace:	1101                	addi	sp,sp,-32
    80000ad0:	ec06                	sd	ra,24(sp)
    80000ad2:	e822                	sd	s0,16(sp)
    80000ad4:	e426                	sd	s1,8(sp)
    80000ad6:	1000                	addi	s0,sp,32
    80000ad8:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000ada:	00000097          	auipc	ra,0x0
    80000ade:	ef8080e7          	jalr	-264(ra) # 800009d2 <push_off>
  if(holding(lk))
    80000ae2:	8526                	mv	a0,s1
    80000ae4:	00000097          	auipc	ra,0x0
    80000ae8:	faa080e7          	jalr	-86(ra) # 80000a8e <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000aec:	4705                	li	a4,1
  if(holding(lk))
    80000aee:	e115                	bnez	a0,80000b12 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000af0:	87ba                	mv	a5,a4
    80000af2:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000af6:	2781                	sext.w	a5,a5
    80000af8:	ffe5                	bnez	a5,80000af0 <acquire+0x22>
  __sync_synchronize();
    80000afa:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000afe:	00001097          	auipc	ra,0x1
    80000b02:	d26080e7          	jalr	-730(ra) # 80001824 <mycpu>
    80000b06:	e888                	sd	a0,16(s1)
}
    80000b08:	60e2                	ld	ra,24(sp)
    80000b0a:	6442                	ld	s0,16(sp)
    80000b0c:	64a2                	ld	s1,8(sp)
    80000b0e:	6105                	addi	sp,sp,32
    80000b10:	8082                	ret
    panic("acquire");
    80000b12:	00006517          	auipc	a0,0x6
    80000b16:	66650513          	addi	a0,a0,1638 # 80007178 <userret+0xe8>
    80000b1a:	00000097          	auipc	ra,0x0
    80000b1e:	a34080e7          	jalr	-1484(ra) # 8000054e <panic>

0000000080000b22 <release>:
{
    80000b22:	1101                	addi	sp,sp,-32
    80000b24:	ec06                	sd	ra,24(sp)
    80000b26:	e822                	sd	s0,16(sp)
    80000b28:	e426                	sd	s1,8(sp)
    80000b2a:	1000                	addi	s0,sp,32
    80000b2c:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000b2e:	00000097          	auipc	ra,0x0
    80000b32:	f60080e7          	jalr	-160(ra) # 80000a8e <holding>
    80000b36:	c115                	beqz	a0,80000b5a <release+0x38>
  lk->cpu = 0;
    80000b38:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000b3c:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000b40:	0f50000f          	fence	iorw,ow
    80000b44:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000b48:	00000097          	auipc	ra,0x0
    80000b4c:	ed6080e7          	jalr	-298(ra) # 80000a1e <pop_off>
}
    80000b50:	60e2                	ld	ra,24(sp)
    80000b52:	6442                	ld	s0,16(sp)
    80000b54:	64a2                	ld	s1,8(sp)
    80000b56:	6105                	addi	sp,sp,32
    80000b58:	8082                	ret
    panic("release");
    80000b5a:	00006517          	auipc	a0,0x6
    80000b5e:	62650513          	addi	a0,a0,1574 # 80007180 <userret+0xf0>
    80000b62:	00000097          	auipc	ra,0x0
    80000b66:	9ec080e7          	jalr	-1556(ra) # 8000054e <panic>

0000000080000b6a <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000b6a:	1141                	addi	sp,sp,-16
    80000b6c:	e422                	sd	s0,8(sp)
    80000b6e:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000b70:	ce09                	beqz	a2,80000b8a <memset+0x20>
    80000b72:	87aa                	mv	a5,a0
    80000b74:	fff6071b          	addiw	a4,a2,-1
    80000b78:	1702                	slli	a4,a4,0x20
    80000b7a:	9301                	srli	a4,a4,0x20
    80000b7c:	0705                	addi	a4,a4,1
    80000b7e:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000b80:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000b84:	0785                	addi	a5,a5,1
    80000b86:	fee79de3          	bne	a5,a4,80000b80 <memset+0x16>
  }
  return dst;
}
    80000b8a:	6422                	ld	s0,8(sp)
    80000b8c:	0141                	addi	sp,sp,16
    80000b8e:	8082                	ret

0000000080000b90 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000b90:	1141                	addi	sp,sp,-16
    80000b92:	e422                	sd	s0,8(sp)
    80000b94:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000b96:	ca05                	beqz	a2,80000bc6 <memcmp+0x36>
    80000b98:	fff6069b          	addiw	a3,a2,-1
    80000b9c:	1682                	slli	a3,a3,0x20
    80000b9e:	9281                	srli	a3,a3,0x20
    80000ba0:	0685                	addi	a3,a3,1
    80000ba2:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000ba4:	00054783          	lbu	a5,0(a0)
    80000ba8:	0005c703          	lbu	a4,0(a1)
    80000bac:	00e79863          	bne	a5,a4,80000bbc <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000bb0:	0505                	addi	a0,a0,1
    80000bb2:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000bb4:	fed518e3          	bne	a0,a3,80000ba4 <memcmp+0x14>
  }

  return 0;
    80000bb8:	4501                	li	a0,0
    80000bba:	a019                	j	80000bc0 <memcmp+0x30>
      return *s1 - *s2;
    80000bbc:	40e7853b          	subw	a0,a5,a4
}
    80000bc0:	6422                	ld	s0,8(sp)
    80000bc2:	0141                	addi	sp,sp,16
    80000bc4:	8082                	ret
  return 0;
    80000bc6:	4501                	li	a0,0
    80000bc8:	bfe5                	j	80000bc0 <memcmp+0x30>

0000000080000bca <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000bca:	1141                	addi	sp,sp,-16
    80000bcc:	e422                	sd	s0,8(sp)
    80000bce:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000bd0:	02a5e563          	bltu	a1,a0,80000bfa <memmove+0x30>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000bd4:	fff6069b          	addiw	a3,a2,-1
    80000bd8:	ce11                	beqz	a2,80000bf4 <memmove+0x2a>
    80000bda:	1682                	slli	a3,a3,0x20
    80000bdc:	9281                	srli	a3,a3,0x20
    80000bde:	0685                	addi	a3,a3,1
    80000be0:	96ae                	add	a3,a3,a1
    80000be2:	87aa                	mv	a5,a0
      *d++ = *s++;
    80000be4:	0585                	addi	a1,a1,1
    80000be6:	0785                	addi	a5,a5,1
    80000be8:	fff5c703          	lbu	a4,-1(a1)
    80000bec:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80000bf0:	fed59ae3          	bne	a1,a3,80000be4 <memmove+0x1a>

  return dst;
}
    80000bf4:	6422                	ld	s0,8(sp)
    80000bf6:	0141                	addi	sp,sp,16
    80000bf8:	8082                	ret
  if(s < d && s + n > d){
    80000bfa:	02061713          	slli	a4,a2,0x20
    80000bfe:	9301                	srli	a4,a4,0x20
    80000c00:	00e587b3          	add	a5,a1,a4
    80000c04:	fcf578e3          	bgeu	a0,a5,80000bd4 <memmove+0xa>
    d += n;
    80000c08:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80000c0a:	fff6069b          	addiw	a3,a2,-1
    80000c0e:	d27d                	beqz	a2,80000bf4 <memmove+0x2a>
    80000c10:	02069613          	slli	a2,a3,0x20
    80000c14:	9201                	srli	a2,a2,0x20
    80000c16:	fff64613          	not	a2,a2
    80000c1a:	963e                	add	a2,a2,a5
      *--d = *--s;
    80000c1c:	17fd                	addi	a5,a5,-1
    80000c1e:	177d                	addi	a4,a4,-1
    80000c20:	0007c683          	lbu	a3,0(a5)
    80000c24:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    80000c28:	fec79ae3          	bne	a5,a2,80000c1c <memmove+0x52>
    80000c2c:	b7e1                	j	80000bf4 <memmove+0x2a>

0000000080000c2e <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000c2e:	1141                	addi	sp,sp,-16
    80000c30:	e406                	sd	ra,8(sp)
    80000c32:	e022                	sd	s0,0(sp)
    80000c34:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000c36:	00000097          	auipc	ra,0x0
    80000c3a:	f94080e7          	jalr	-108(ra) # 80000bca <memmove>
}
    80000c3e:	60a2                	ld	ra,8(sp)
    80000c40:	6402                	ld	s0,0(sp)
    80000c42:	0141                	addi	sp,sp,16
    80000c44:	8082                	ret

0000000080000c46 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000c46:	1141                	addi	sp,sp,-16
    80000c48:	e422                	sd	s0,8(sp)
    80000c4a:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000c4c:	ce11                	beqz	a2,80000c68 <strncmp+0x22>
    80000c4e:	00054783          	lbu	a5,0(a0)
    80000c52:	cf89                	beqz	a5,80000c6c <strncmp+0x26>
    80000c54:	0005c703          	lbu	a4,0(a1)
    80000c58:	00f71a63          	bne	a4,a5,80000c6c <strncmp+0x26>
    n--, p++, q++;
    80000c5c:	367d                	addiw	a2,a2,-1
    80000c5e:	0505                	addi	a0,a0,1
    80000c60:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000c62:	f675                	bnez	a2,80000c4e <strncmp+0x8>
  if(n == 0)
    return 0;
    80000c64:	4501                	li	a0,0
    80000c66:	a809                	j	80000c78 <strncmp+0x32>
    80000c68:	4501                	li	a0,0
    80000c6a:	a039                	j	80000c78 <strncmp+0x32>
  if(n == 0)
    80000c6c:	ca09                	beqz	a2,80000c7e <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000c6e:	00054503          	lbu	a0,0(a0)
    80000c72:	0005c783          	lbu	a5,0(a1)
    80000c76:	9d1d                	subw	a0,a0,a5
}
    80000c78:	6422                	ld	s0,8(sp)
    80000c7a:	0141                	addi	sp,sp,16
    80000c7c:	8082                	ret
    return 0;
    80000c7e:	4501                	li	a0,0
    80000c80:	bfe5                	j	80000c78 <strncmp+0x32>

0000000080000c82 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000c82:	1141                	addi	sp,sp,-16
    80000c84:	e422                	sd	s0,8(sp)
    80000c86:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000c88:	872a                	mv	a4,a0
    80000c8a:	8832                	mv	a6,a2
    80000c8c:	367d                	addiw	a2,a2,-1
    80000c8e:	01005963          	blez	a6,80000ca0 <strncpy+0x1e>
    80000c92:	0705                	addi	a4,a4,1
    80000c94:	0005c783          	lbu	a5,0(a1)
    80000c98:	fef70fa3          	sb	a5,-1(a4)
    80000c9c:	0585                	addi	a1,a1,1
    80000c9e:	f7f5                	bnez	a5,80000c8a <strncpy+0x8>
    ;
  while(n-- > 0)
    80000ca0:	86ba                	mv	a3,a4
    80000ca2:	00c05c63          	blez	a2,80000cba <strncpy+0x38>
    *s++ = 0;
    80000ca6:	0685                	addi	a3,a3,1
    80000ca8:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000cac:	fff6c793          	not	a5,a3
    80000cb0:	9fb9                	addw	a5,a5,a4
    80000cb2:	010787bb          	addw	a5,a5,a6
    80000cb6:	fef048e3          	bgtz	a5,80000ca6 <strncpy+0x24>
  return os;
}
    80000cba:	6422                	ld	s0,8(sp)
    80000cbc:	0141                	addi	sp,sp,16
    80000cbe:	8082                	ret

0000000080000cc0 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000cc0:	1141                	addi	sp,sp,-16
    80000cc2:	e422                	sd	s0,8(sp)
    80000cc4:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000cc6:	02c05363          	blez	a2,80000cec <safestrcpy+0x2c>
    80000cca:	fff6069b          	addiw	a3,a2,-1
    80000cce:	1682                	slli	a3,a3,0x20
    80000cd0:	9281                	srli	a3,a3,0x20
    80000cd2:	96ae                	add	a3,a3,a1
    80000cd4:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000cd6:	00d58963          	beq	a1,a3,80000ce8 <safestrcpy+0x28>
    80000cda:	0585                	addi	a1,a1,1
    80000cdc:	0785                	addi	a5,a5,1
    80000cde:	fff5c703          	lbu	a4,-1(a1)
    80000ce2:	fee78fa3          	sb	a4,-1(a5)
    80000ce6:	fb65                	bnez	a4,80000cd6 <safestrcpy+0x16>
    ;
  *s = 0;
    80000ce8:	00078023          	sb	zero,0(a5)
  return os;
}
    80000cec:	6422                	ld	s0,8(sp)
    80000cee:	0141                	addi	sp,sp,16
    80000cf0:	8082                	ret

0000000080000cf2 <strlen>:

int
strlen(const char *s)
{
    80000cf2:	1141                	addi	sp,sp,-16
    80000cf4:	e422                	sd	s0,8(sp)
    80000cf6:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000cf8:	00054783          	lbu	a5,0(a0)
    80000cfc:	cf91                	beqz	a5,80000d18 <strlen+0x26>
    80000cfe:	0505                	addi	a0,a0,1
    80000d00:	87aa                	mv	a5,a0
    80000d02:	4685                	li	a3,1
    80000d04:	9e89                	subw	a3,a3,a0
    80000d06:	00f6853b          	addw	a0,a3,a5
    80000d0a:	0785                	addi	a5,a5,1
    80000d0c:	fff7c703          	lbu	a4,-1(a5)
    80000d10:	fb7d                	bnez	a4,80000d06 <strlen+0x14>
    ;
  return n;
}
    80000d12:	6422                	ld	s0,8(sp)
    80000d14:	0141                	addi	sp,sp,16
    80000d16:	8082                	ret
  for(n = 0; s[n]; n++)
    80000d18:	4501                	li	a0,0
    80000d1a:	bfe5                	j	80000d12 <strlen+0x20>

0000000080000d1c <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000d1c:	1141                	addi	sp,sp,-16
    80000d1e:	e406                	sd	ra,8(sp)
    80000d20:	e022                	sd	s0,0(sp)
    80000d22:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000d24:	00001097          	auipc	ra,0x1
    80000d28:	af0080e7          	jalr	-1296(ra) # 80001814 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000d2c:	00025717          	auipc	a4,0x25
    80000d30:	2d870713          	addi	a4,a4,728 # 80026004 <started>
  if(cpuid() == 0){
    80000d34:	c139                	beqz	a0,80000d7a <main+0x5e>
    while(started == 0)
    80000d36:	431c                	lw	a5,0(a4)
    80000d38:	2781                	sext.w	a5,a5
    80000d3a:	dff5                	beqz	a5,80000d36 <main+0x1a>
      ;
    __sync_synchronize();
    80000d3c:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000d40:	00001097          	auipc	ra,0x1
    80000d44:	ad4080e7          	jalr	-1324(ra) # 80001814 <cpuid>
    80000d48:	85aa                	mv	a1,a0
    80000d4a:	00006517          	auipc	a0,0x6
    80000d4e:	45650513          	addi	a0,a0,1110 # 800071a0 <userret+0x110>
    80000d52:	00000097          	auipc	ra,0x0
    80000d56:	846080e7          	jalr	-1978(ra) # 80000598 <printf>
    kvminithart();    // turn on paging
    80000d5a:	00000097          	auipc	ra,0x0
    80000d5e:	1e8080e7          	jalr	488(ra) # 80000f42 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000d62:	00001097          	auipc	ra,0x1
    80000d66:	6e0080e7          	jalr	1760(ra) # 80002442 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000d6a:	00005097          	auipc	ra,0x5
    80000d6e:	d56080e7          	jalr	-682(ra) # 80005ac0 <plicinithart>
  }

  scheduler();        
    80000d72:	00001097          	auipc	ra,0x1
    80000d76:	fa8080e7          	jalr	-88(ra) # 80001d1a <scheduler>
    consoleinit();
    80000d7a:	fffff097          	auipc	ra,0xfffff
    80000d7e:	6e6080e7          	jalr	1766(ra) # 80000460 <consoleinit>
    printfinit();
    80000d82:	00000097          	auipc	ra,0x0
    80000d86:	9fc080e7          	jalr	-1540(ra) # 8000077e <printfinit>
    printf("\n");
    80000d8a:	00006517          	auipc	a0,0x6
    80000d8e:	42650513          	addi	a0,a0,1062 # 800071b0 <userret+0x120>
    80000d92:	00000097          	auipc	ra,0x0
    80000d96:	806080e7          	jalr	-2042(ra) # 80000598 <printf>
    printf("xv6 kernel is booting\n");
    80000d9a:	00006517          	auipc	a0,0x6
    80000d9e:	3ee50513          	addi	a0,a0,1006 # 80007188 <userret+0xf8>
    80000da2:	fffff097          	auipc	ra,0xfffff
    80000da6:	7f6080e7          	jalr	2038(ra) # 80000598 <printf>
    printf("\n");
    80000daa:	00006517          	auipc	a0,0x6
    80000dae:	40650513          	addi	a0,a0,1030 # 800071b0 <userret+0x120>
    80000db2:	fffff097          	auipc	ra,0xfffff
    80000db6:	7e6080e7          	jalr	2022(ra) # 80000598 <printf>
    kinit();         // physical page allocator
    80000dba:	00000097          	auipc	ra,0x0
    80000dbe:	b66080e7          	jalr	-1178(ra) # 80000920 <kinit>
    kvminit();       // create kernel page table
    80000dc2:	00000097          	auipc	ra,0x0
    80000dc6:	30a080e7          	jalr	778(ra) # 800010cc <kvminit>
    kvminithart();   // turn on paging
    80000dca:	00000097          	auipc	ra,0x0
    80000dce:	178080e7          	jalr	376(ra) # 80000f42 <kvminithart>
    procinit();      // process table
    80000dd2:	00001097          	auipc	ra,0x1
    80000dd6:	972080e7          	jalr	-1678(ra) # 80001744 <procinit>
    trapinit();      // trap vectors
    80000dda:	00001097          	auipc	ra,0x1
    80000dde:	640080e7          	jalr	1600(ra) # 8000241a <trapinit>
    trapinithart();  // install kernel trap vector
    80000de2:	00001097          	auipc	ra,0x1
    80000de6:	660080e7          	jalr	1632(ra) # 80002442 <trapinithart>
    plicinit();      // set up interrupt controller
    80000dea:	00005097          	auipc	ra,0x5
    80000dee:	cc0080e7          	jalr	-832(ra) # 80005aaa <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000df2:	00005097          	auipc	ra,0x5
    80000df6:	cce080e7          	jalr	-818(ra) # 80005ac0 <plicinithart>
    binit();         // buffer cache
    80000dfa:	00002097          	auipc	ra,0x2
    80000dfe:	ed4080e7          	jalr	-300(ra) # 80002cce <binit>
    iinit();         // inode cache
    80000e02:	00002097          	auipc	ra,0x2
    80000e06:	564080e7          	jalr	1380(ra) # 80003366 <iinit>
    fileinit();      // file table
    80000e0a:	00003097          	auipc	ra,0x3
    80000e0e:	4d8080e7          	jalr	1240(ra) # 800042e2 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000e12:	00005097          	auipc	ra,0x5
    80000e16:	dc8080e7          	jalr	-568(ra) # 80005bda <virtio_disk_init>
    userinit();      // first user process
    80000e1a:	00001097          	auipc	ra,0x1
    80000e1e:	c9a080e7          	jalr	-870(ra) # 80001ab4 <userinit>
    __sync_synchronize();
    80000e22:	0ff0000f          	fence
    started = 1;
    80000e26:	4785                	li	a5,1
    80000e28:	00025717          	auipc	a4,0x25
    80000e2c:	1cf72e23          	sw	a5,476(a4) # 80026004 <started>
    80000e30:	b789                	j	80000d72 <main+0x56>

0000000080000e32 <walk>:
//   21..39 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..12 -- 12 bits of byte offset within the page.
static pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000e32:	7139                	addi	sp,sp,-64
    80000e34:	fc06                	sd	ra,56(sp)
    80000e36:	f822                	sd	s0,48(sp)
    80000e38:	f426                	sd	s1,40(sp)
    80000e3a:	f04a                	sd	s2,32(sp)
    80000e3c:	ec4e                	sd	s3,24(sp)
    80000e3e:	e852                	sd	s4,16(sp)
    80000e40:	e456                	sd	s5,8(sp)
    80000e42:	e05a                	sd	s6,0(sp)
    80000e44:	0080                	addi	s0,sp,64
    80000e46:	84aa                	mv	s1,a0
    80000e48:	89ae                	mv	s3,a1
    80000e4a:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000e4c:	57fd                	li	a5,-1
    80000e4e:	83e9                	srli	a5,a5,0x1a
    80000e50:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000e52:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000e54:	04b7f263          	bgeu	a5,a1,80000e98 <walk+0x66>
    panic("walk");
    80000e58:	00006517          	auipc	a0,0x6
    80000e5c:	36050513          	addi	a0,a0,864 # 800071b8 <userret+0x128>
    80000e60:	fffff097          	auipc	ra,0xfffff
    80000e64:	6ee080e7          	jalr	1774(ra) # 8000054e <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000e68:	060a8663          	beqz	s5,80000ed4 <walk+0xa2>
    80000e6c:	00000097          	auipc	ra,0x0
    80000e70:	af0080e7          	jalr	-1296(ra) # 8000095c <kalloc>
    80000e74:	84aa                	mv	s1,a0
    80000e76:	c529                	beqz	a0,80000ec0 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80000e78:	6605                	lui	a2,0x1
    80000e7a:	4581                	li	a1,0
    80000e7c:	00000097          	auipc	ra,0x0
    80000e80:	cee080e7          	jalr	-786(ra) # 80000b6a <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80000e84:	00c4d793          	srli	a5,s1,0xc
    80000e88:	07aa                	slli	a5,a5,0xa
    80000e8a:	0017e793          	ori	a5,a5,1
    80000e8e:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80000e92:	3a5d                	addiw	s4,s4,-9
    80000e94:	036a0063          	beq	s4,s6,80000eb4 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80000e98:	0149d933          	srl	s2,s3,s4
    80000e9c:	1ff97913          	andi	s2,s2,511
    80000ea0:	090e                	slli	s2,s2,0x3
    80000ea2:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80000ea4:	00093483          	ld	s1,0(s2)
    80000ea8:	0014f793          	andi	a5,s1,1
    80000eac:	dfd5                	beqz	a5,80000e68 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80000eae:	80a9                	srli	s1,s1,0xa
    80000eb0:	04b2                	slli	s1,s1,0xc
    80000eb2:	b7c5                	j	80000e92 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80000eb4:	00c9d513          	srli	a0,s3,0xc
    80000eb8:	1ff57513          	andi	a0,a0,511
    80000ebc:	050e                	slli	a0,a0,0x3
    80000ebe:	9526                	add	a0,a0,s1
}
    80000ec0:	70e2                	ld	ra,56(sp)
    80000ec2:	7442                	ld	s0,48(sp)
    80000ec4:	74a2                	ld	s1,40(sp)
    80000ec6:	7902                	ld	s2,32(sp)
    80000ec8:	69e2                	ld	s3,24(sp)
    80000eca:	6a42                	ld	s4,16(sp)
    80000ecc:	6aa2                	ld	s5,8(sp)
    80000ece:	6b02                	ld	s6,0(sp)
    80000ed0:	6121                	addi	sp,sp,64
    80000ed2:	8082                	ret
        return 0;
    80000ed4:	4501                	li	a0,0
    80000ed6:	b7ed                	j	80000ec0 <walk+0x8e>

0000000080000ed8 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
static void
freewalk(pagetable_t pagetable)
{
    80000ed8:	7179                	addi	sp,sp,-48
    80000eda:	f406                	sd	ra,40(sp)
    80000edc:	f022                	sd	s0,32(sp)
    80000ede:	ec26                	sd	s1,24(sp)
    80000ee0:	e84a                	sd	s2,16(sp)
    80000ee2:	e44e                	sd	s3,8(sp)
    80000ee4:	e052                	sd	s4,0(sp)
    80000ee6:	1800                	addi	s0,sp,48
    80000ee8:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80000eea:	84aa                	mv	s1,a0
    80000eec:	6905                	lui	s2,0x1
    80000eee:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80000ef0:	4985                	li	s3,1
    80000ef2:	a821                	j	80000f0a <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80000ef4:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    80000ef6:	0532                	slli	a0,a0,0xc
    80000ef8:	00000097          	auipc	ra,0x0
    80000efc:	fe0080e7          	jalr	-32(ra) # 80000ed8 <freewalk>
      pagetable[i] = 0;
    80000f00:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80000f04:	04a1                	addi	s1,s1,8
    80000f06:	03248163          	beq	s1,s2,80000f28 <freewalk+0x50>
    pte_t pte = pagetable[i];
    80000f0a:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80000f0c:	00f57793          	andi	a5,a0,15
    80000f10:	ff3782e3          	beq	a5,s3,80000ef4 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80000f14:	8905                	andi	a0,a0,1
    80000f16:	d57d                	beqz	a0,80000f04 <freewalk+0x2c>
      panic("freewalk: leaf");
    80000f18:	00006517          	auipc	a0,0x6
    80000f1c:	2a850513          	addi	a0,a0,680 # 800071c0 <userret+0x130>
    80000f20:	fffff097          	auipc	ra,0xfffff
    80000f24:	62e080e7          	jalr	1582(ra) # 8000054e <panic>
    }
  }
  kfree((void*)pagetable);
    80000f28:	8552                	mv	a0,s4
    80000f2a:	00000097          	auipc	ra,0x0
    80000f2e:	936080e7          	jalr	-1738(ra) # 80000860 <kfree>
}
    80000f32:	70a2                	ld	ra,40(sp)
    80000f34:	7402                	ld	s0,32(sp)
    80000f36:	64e2                	ld	s1,24(sp)
    80000f38:	6942                	ld	s2,16(sp)
    80000f3a:	69a2                	ld	s3,8(sp)
    80000f3c:	6a02                	ld	s4,0(sp)
    80000f3e:	6145                	addi	sp,sp,48
    80000f40:	8082                	ret

0000000080000f42 <kvminithart>:
{
    80000f42:	1141                	addi	sp,sp,-16
    80000f44:	e422                	sd	s0,8(sp)
    80000f46:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000f48:	00025797          	auipc	a5,0x25
    80000f4c:	0c07b783          	ld	a5,192(a5) # 80026008 <kernel_pagetable>
    80000f50:	83b1                	srli	a5,a5,0xc
    80000f52:	577d                	li	a4,-1
    80000f54:	177e                	slli	a4,a4,0x3f
    80000f56:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000f58:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000f5c:	12000073          	sfence.vma
}
    80000f60:	6422                	ld	s0,8(sp)
    80000f62:	0141                	addi	sp,sp,16
    80000f64:	8082                	ret

0000000080000f66 <walkaddr>:
  if(va >= MAXVA)
    80000f66:	57fd                	li	a5,-1
    80000f68:	83e9                	srli	a5,a5,0x1a
    80000f6a:	00b7f463          	bgeu	a5,a1,80000f72 <walkaddr+0xc>
    return 0;
    80000f6e:	4501                	li	a0,0
}
    80000f70:	8082                	ret
{
    80000f72:	1141                	addi	sp,sp,-16
    80000f74:	e406                	sd	ra,8(sp)
    80000f76:	e022                	sd	s0,0(sp)
    80000f78:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80000f7a:	4601                	li	a2,0
    80000f7c:	00000097          	auipc	ra,0x0
    80000f80:	eb6080e7          	jalr	-330(ra) # 80000e32 <walk>
  if(pte == 0)
    80000f84:	c105                	beqz	a0,80000fa4 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80000f86:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80000f88:	0117f693          	andi	a3,a5,17
    80000f8c:	4745                	li	a4,17
    return 0;
    80000f8e:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80000f90:	00e68663          	beq	a3,a4,80000f9c <walkaddr+0x36>
}
    80000f94:	60a2                	ld	ra,8(sp)
    80000f96:	6402                	ld	s0,0(sp)
    80000f98:	0141                	addi	sp,sp,16
    80000f9a:	8082                	ret
  pa = PTE2PA(*pte);
    80000f9c:	00a7d513          	srli	a0,a5,0xa
    80000fa0:	0532                	slli	a0,a0,0xc
  return pa;
    80000fa2:	bfcd                	j	80000f94 <walkaddr+0x2e>
    return 0;
    80000fa4:	4501                	li	a0,0
    80000fa6:	b7fd                	j	80000f94 <walkaddr+0x2e>

0000000080000fa8 <kvmpa>:
{
    80000fa8:	1101                	addi	sp,sp,-32
    80000faa:	ec06                	sd	ra,24(sp)
    80000fac:	e822                	sd	s0,16(sp)
    80000fae:	e426                	sd	s1,8(sp)
    80000fb0:	1000                	addi	s0,sp,32
    80000fb2:	85aa                	mv	a1,a0
  uint64 off = va % PGSIZE;
    80000fb4:	03451493          	slli	s1,a0,0x34
  pte = walk(kernel_pagetable, va, 0);
    80000fb8:	4601                	li	a2,0
    80000fba:	00025517          	auipc	a0,0x25
    80000fbe:	04e53503          	ld	a0,78(a0) # 80026008 <kernel_pagetable>
    80000fc2:	00000097          	auipc	ra,0x0
    80000fc6:	e70080e7          	jalr	-400(ra) # 80000e32 <walk>
  if(pte == 0)
    80000fca:	cd11                	beqz	a0,80000fe6 <kvmpa+0x3e>
    80000fcc:	90d1                	srli	s1,s1,0x34
  if((*pte & PTE_V) == 0)
    80000fce:	6108                	ld	a0,0(a0)
    80000fd0:	00157793          	andi	a5,a0,1
    80000fd4:	c38d                	beqz	a5,80000ff6 <kvmpa+0x4e>
  pa = PTE2PA(*pte);
    80000fd6:	8129                	srli	a0,a0,0xa
    80000fd8:	0532                	slli	a0,a0,0xc
}
    80000fda:	9526                	add	a0,a0,s1
    80000fdc:	60e2                	ld	ra,24(sp)
    80000fde:	6442                	ld	s0,16(sp)
    80000fe0:	64a2                	ld	s1,8(sp)
    80000fe2:	6105                	addi	sp,sp,32
    80000fe4:	8082                	ret
    panic("kvmpa");
    80000fe6:	00006517          	auipc	a0,0x6
    80000fea:	1ea50513          	addi	a0,a0,490 # 800071d0 <userret+0x140>
    80000fee:	fffff097          	auipc	ra,0xfffff
    80000ff2:	560080e7          	jalr	1376(ra) # 8000054e <panic>
    panic("kvmpa");
    80000ff6:	00006517          	auipc	a0,0x6
    80000ffa:	1da50513          	addi	a0,a0,474 # 800071d0 <userret+0x140>
    80000ffe:	fffff097          	auipc	ra,0xfffff
    80001002:	550080e7          	jalr	1360(ra) # 8000054e <panic>

0000000080001006 <mappages>:
{
    80001006:	715d                	addi	sp,sp,-80
    80001008:	e486                	sd	ra,72(sp)
    8000100a:	e0a2                	sd	s0,64(sp)
    8000100c:	fc26                	sd	s1,56(sp)
    8000100e:	f84a                	sd	s2,48(sp)
    80001010:	f44e                	sd	s3,40(sp)
    80001012:	f052                	sd	s4,32(sp)
    80001014:	ec56                	sd	s5,24(sp)
    80001016:	e85a                	sd	s6,16(sp)
    80001018:	e45e                	sd	s7,8(sp)
    8000101a:	0880                	addi	s0,sp,80
    8000101c:	8aaa                	mv	s5,a0
    8000101e:	8b3a                	mv	s6,a4
  a = PGROUNDDOWN(va);
    80001020:	777d                	lui	a4,0xfffff
    80001022:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    80001026:	167d                	addi	a2,a2,-1
    80001028:	00b609b3          	add	s3,a2,a1
    8000102c:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    80001030:	893e                	mv	s2,a5
    80001032:	40f68a33          	sub	s4,a3,a5
    a += PGSIZE;
    80001036:	6b85                	lui	s7,0x1
    80001038:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    8000103c:	4605                	li	a2,1
    8000103e:	85ca                	mv	a1,s2
    80001040:	8556                	mv	a0,s5
    80001042:	00000097          	auipc	ra,0x0
    80001046:	df0080e7          	jalr	-528(ra) # 80000e32 <walk>
    8000104a:	c51d                	beqz	a0,80001078 <mappages+0x72>
    if(*pte & PTE_V)
    8000104c:	611c                	ld	a5,0(a0)
    8000104e:	8b85                	andi	a5,a5,1
    80001050:	ef81                	bnez	a5,80001068 <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001052:	80b1                	srli	s1,s1,0xc
    80001054:	04aa                	slli	s1,s1,0xa
    80001056:	0164e4b3          	or	s1,s1,s6
    8000105a:	0014e493          	ori	s1,s1,1
    8000105e:	e104                	sd	s1,0(a0)
    if(a == last)
    80001060:	03390863          	beq	s2,s3,80001090 <mappages+0x8a>
    a += PGSIZE;
    80001064:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001066:	bfc9                	j	80001038 <mappages+0x32>
      panic("remap");
    80001068:	00006517          	auipc	a0,0x6
    8000106c:	17050513          	addi	a0,a0,368 # 800071d8 <userret+0x148>
    80001070:	fffff097          	auipc	ra,0xfffff
    80001074:	4de080e7          	jalr	1246(ra) # 8000054e <panic>
      return -1;
    80001078:	557d                	li	a0,-1
}
    8000107a:	60a6                	ld	ra,72(sp)
    8000107c:	6406                	ld	s0,64(sp)
    8000107e:	74e2                	ld	s1,56(sp)
    80001080:	7942                	ld	s2,48(sp)
    80001082:	79a2                	ld	s3,40(sp)
    80001084:	7a02                	ld	s4,32(sp)
    80001086:	6ae2                	ld	s5,24(sp)
    80001088:	6b42                	ld	s6,16(sp)
    8000108a:	6ba2                	ld	s7,8(sp)
    8000108c:	6161                	addi	sp,sp,80
    8000108e:	8082                	ret
  return 0;
    80001090:	4501                	li	a0,0
    80001092:	b7e5                	j	8000107a <mappages+0x74>

0000000080001094 <kvmmap>:
{
    80001094:	1141                	addi	sp,sp,-16
    80001096:	e406                	sd	ra,8(sp)
    80001098:	e022                	sd	s0,0(sp)
    8000109a:	0800                	addi	s0,sp,16
    8000109c:	8736                	mv	a4,a3
  if(mappages(kernel_pagetable, va, sz, pa, perm) != 0)
    8000109e:	86ae                	mv	a3,a1
    800010a0:	85aa                	mv	a1,a0
    800010a2:	00025517          	auipc	a0,0x25
    800010a6:	f6653503          	ld	a0,-154(a0) # 80026008 <kernel_pagetable>
    800010aa:	00000097          	auipc	ra,0x0
    800010ae:	f5c080e7          	jalr	-164(ra) # 80001006 <mappages>
    800010b2:	e509                	bnez	a0,800010bc <kvmmap+0x28>
}
    800010b4:	60a2                	ld	ra,8(sp)
    800010b6:	6402                	ld	s0,0(sp)
    800010b8:	0141                	addi	sp,sp,16
    800010ba:	8082                	ret
    panic("kvmmap");
    800010bc:	00006517          	auipc	a0,0x6
    800010c0:	12450513          	addi	a0,a0,292 # 800071e0 <userret+0x150>
    800010c4:	fffff097          	auipc	ra,0xfffff
    800010c8:	48a080e7          	jalr	1162(ra) # 8000054e <panic>

00000000800010cc <kvminit>:
{
    800010cc:	1101                	addi	sp,sp,-32
    800010ce:	ec06                	sd	ra,24(sp)
    800010d0:	e822                	sd	s0,16(sp)
    800010d2:	e426                	sd	s1,8(sp)
    800010d4:	1000                	addi	s0,sp,32
  kernel_pagetable = (pagetable_t) kalloc();
    800010d6:	00000097          	auipc	ra,0x0
    800010da:	886080e7          	jalr	-1914(ra) # 8000095c <kalloc>
    800010de:	00025797          	auipc	a5,0x25
    800010e2:	f2a7b523          	sd	a0,-214(a5) # 80026008 <kernel_pagetable>
  memset(kernel_pagetable, 0, PGSIZE);
    800010e6:	6605                	lui	a2,0x1
    800010e8:	4581                	li	a1,0
    800010ea:	00000097          	auipc	ra,0x0
    800010ee:	a80080e7          	jalr	-1408(ra) # 80000b6a <memset>
  kvmmap(UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800010f2:	4699                	li	a3,6
    800010f4:	6605                	lui	a2,0x1
    800010f6:	100005b7          	lui	a1,0x10000
    800010fa:	10000537          	lui	a0,0x10000
    800010fe:	00000097          	auipc	ra,0x0
    80001102:	f96080e7          	jalr	-106(ra) # 80001094 <kvmmap>
  kvmmap(VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    80001106:	4699                	li	a3,6
    80001108:	6605                	lui	a2,0x1
    8000110a:	100015b7          	lui	a1,0x10001
    8000110e:	10001537          	lui	a0,0x10001
    80001112:	00000097          	auipc	ra,0x0
    80001116:	f82080e7          	jalr	-126(ra) # 80001094 <kvmmap>
  kvmmap(CLINT, CLINT, 0x10000, PTE_R | PTE_W);
    8000111a:	4699                	li	a3,6
    8000111c:	6641                	lui	a2,0x10
    8000111e:	020005b7          	lui	a1,0x2000
    80001122:	02000537          	lui	a0,0x2000
    80001126:	00000097          	auipc	ra,0x0
    8000112a:	f6e080e7          	jalr	-146(ra) # 80001094 <kvmmap>
  kvmmap(PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    8000112e:	4699                	li	a3,6
    80001130:	00400637          	lui	a2,0x400
    80001134:	0c0005b7          	lui	a1,0xc000
    80001138:	0c000537          	lui	a0,0xc000
    8000113c:	00000097          	auipc	ra,0x0
    80001140:	f58080e7          	jalr	-168(ra) # 80001094 <kvmmap>
  kvmmap(KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    80001144:	00007497          	auipc	s1,0x7
    80001148:	ebc48493          	addi	s1,s1,-324 # 80008000 <initcode>
    8000114c:	46a9                	li	a3,10
    8000114e:	80007617          	auipc	a2,0x80007
    80001152:	eb260613          	addi	a2,a2,-334 # 8000 <_entry-0x7fff8000>
    80001156:	4585                	li	a1,1
    80001158:	05fe                	slli	a1,a1,0x1f
    8000115a:	852e                	mv	a0,a1
    8000115c:	00000097          	auipc	ra,0x0
    80001160:	f38080e7          	jalr	-200(ra) # 80001094 <kvmmap>
  kvmmap((uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001164:	4699                	li	a3,6
    80001166:	4645                	li	a2,17
    80001168:	066e                	slli	a2,a2,0x1b
    8000116a:	8e05                	sub	a2,a2,s1
    8000116c:	85a6                	mv	a1,s1
    8000116e:	8526                	mv	a0,s1
    80001170:	00000097          	auipc	ra,0x0
    80001174:	f24080e7          	jalr	-220(ra) # 80001094 <kvmmap>
  kvmmap(TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001178:	46a9                	li	a3,10
    8000117a:	6605                	lui	a2,0x1
    8000117c:	00006597          	auipc	a1,0x6
    80001180:	e8458593          	addi	a1,a1,-380 # 80007000 <trampoline>
    80001184:	04000537          	lui	a0,0x4000
    80001188:	157d                	addi	a0,a0,-1
    8000118a:	0532                	slli	a0,a0,0xc
    8000118c:	00000097          	auipc	ra,0x0
    80001190:	f08080e7          	jalr	-248(ra) # 80001094 <kvmmap>
}
    80001194:	60e2                	ld	ra,24(sp)
    80001196:	6442                	ld	s0,16(sp)
    80001198:	64a2                	ld	s1,8(sp)
    8000119a:	6105                	addi	sp,sp,32
    8000119c:	8082                	ret

000000008000119e <uvmunmap>:
{
    8000119e:	715d                	addi	sp,sp,-80
    800011a0:	e486                	sd	ra,72(sp)
    800011a2:	e0a2                	sd	s0,64(sp)
    800011a4:	fc26                	sd	s1,56(sp)
    800011a6:	f84a                	sd	s2,48(sp)
    800011a8:	f44e                	sd	s3,40(sp)
    800011aa:	f052                	sd	s4,32(sp)
    800011ac:	ec56                	sd	s5,24(sp)
    800011ae:	e85a                	sd	s6,16(sp)
    800011b0:	e45e                	sd	s7,8(sp)
    800011b2:	0880                	addi	s0,sp,80
    800011b4:	8a2a                	mv	s4,a0
    800011b6:	8ab6                	mv	s5,a3
  a = PGROUNDDOWN(va);
    800011b8:	77fd                	lui	a5,0xfffff
    800011ba:	00f5f933          	and	s2,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800011be:	167d                	addi	a2,a2,-1
    800011c0:	00b609b3          	add	s3,a2,a1
    800011c4:	00f9f9b3          	and	s3,s3,a5
    if(PTE_FLAGS(*pte) == PTE_V)
    800011c8:	4b05                	li	s6,1
    a += PGSIZE;
    800011ca:	6b85                	lui	s7,0x1
    800011cc:	a8b1                	j	80001228 <uvmunmap+0x8a>
      panic("uvmunmap: walk");
    800011ce:	00006517          	auipc	a0,0x6
    800011d2:	01a50513          	addi	a0,a0,26 # 800071e8 <userret+0x158>
    800011d6:	fffff097          	auipc	ra,0xfffff
    800011da:	378080e7          	jalr	888(ra) # 8000054e <panic>
      printf("va=%p pte=%p\n", a, *pte);
    800011de:	862a                	mv	a2,a0
    800011e0:	85ca                	mv	a1,s2
    800011e2:	00006517          	auipc	a0,0x6
    800011e6:	01650513          	addi	a0,a0,22 # 800071f8 <userret+0x168>
    800011ea:	fffff097          	auipc	ra,0xfffff
    800011ee:	3ae080e7          	jalr	942(ra) # 80000598 <printf>
      panic("uvmunmap: not mapped");
    800011f2:	00006517          	auipc	a0,0x6
    800011f6:	01650513          	addi	a0,a0,22 # 80007208 <userret+0x178>
    800011fa:	fffff097          	auipc	ra,0xfffff
    800011fe:	354080e7          	jalr	852(ra) # 8000054e <panic>
      panic("uvmunmap: not a leaf");
    80001202:	00006517          	auipc	a0,0x6
    80001206:	01e50513          	addi	a0,a0,30 # 80007220 <userret+0x190>
    8000120a:	fffff097          	auipc	ra,0xfffff
    8000120e:	344080e7          	jalr	836(ra) # 8000054e <panic>
      pa = PTE2PA(*pte);
    80001212:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80001214:	0532                	slli	a0,a0,0xc
    80001216:	fffff097          	auipc	ra,0xfffff
    8000121a:	64a080e7          	jalr	1610(ra) # 80000860 <kfree>
    *pte = 0;
    8000121e:	0004b023          	sd	zero,0(s1)
    if(a == last)
    80001222:	03390763          	beq	s2,s3,80001250 <uvmunmap+0xb2>
    a += PGSIZE;
    80001226:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 0)) == 0)
    80001228:	4601                	li	a2,0
    8000122a:	85ca                	mv	a1,s2
    8000122c:	8552                	mv	a0,s4
    8000122e:	00000097          	auipc	ra,0x0
    80001232:	c04080e7          	jalr	-1020(ra) # 80000e32 <walk>
    80001236:	84aa                	mv	s1,a0
    80001238:	d959                	beqz	a0,800011ce <uvmunmap+0x30>
    if((*pte & PTE_V) == 0){
    8000123a:	6108                	ld	a0,0(a0)
    8000123c:	00157793          	andi	a5,a0,1
    80001240:	dfd9                	beqz	a5,800011de <uvmunmap+0x40>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001242:	3ff57793          	andi	a5,a0,1023
    80001246:	fb678ee3          	beq	a5,s6,80001202 <uvmunmap+0x64>
    if(do_free){
    8000124a:	fc0a8ae3          	beqz	s5,8000121e <uvmunmap+0x80>
    8000124e:	b7d1                	j	80001212 <uvmunmap+0x74>
}
    80001250:	60a6                	ld	ra,72(sp)
    80001252:	6406                	ld	s0,64(sp)
    80001254:	74e2                	ld	s1,56(sp)
    80001256:	7942                	ld	s2,48(sp)
    80001258:	79a2                	ld	s3,40(sp)
    8000125a:	7a02                	ld	s4,32(sp)
    8000125c:	6ae2                	ld	s5,24(sp)
    8000125e:	6b42                	ld	s6,16(sp)
    80001260:	6ba2                	ld	s7,8(sp)
    80001262:	6161                	addi	sp,sp,80
    80001264:	8082                	ret

0000000080001266 <uvmcreate>:
{
    80001266:	1101                	addi	sp,sp,-32
    80001268:	ec06                	sd	ra,24(sp)
    8000126a:	e822                	sd	s0,16(sp)
    8000126c:	e426                	sd	s1,8(sp)
    8000126e:	1000                	addi	s0,sp,32
  pagetable = (pagetable_t) kalloc();
    80001270:	fffff097          	auipc	ra,0xfffff
    80001274:	6ec080e7          	jalr	1772(ra) # 8000095c <kalloc>
  if(pagetable == 0)
    80001278:	cd11                	beqz	a0,80001294 <uvmcreate+0x2e>
    8000127a:	84aa                	mv	s1,a0
  memset(pagetable, 0, PGSIZE);
    8000127c:	6605                	lui	a2,0x1
    8000127e:	4581                	li	a1,0
    80001280:	00000097          	auipc	ra,0x0
    80001284:	8ea080e7          	jalr	-1814(ra) # 80000b6a <memset>
}
    80001288:	8526                	mv	a0,s1
    8000128a:	60e2                	ld	ra,24(sp)
    8000128c:	6442                	ld	s0,16(sp)
    8000128e:	64a2                	ld	s1,8(sp)
    80001290:	6105                	addi	sp,sp,32
    80001292:	8082                	ret
    panic("uvmcreate: out of memory");
    80001294:	00006517          	auipc	a0,0x6
    80001298:	fa450513          	addi	a0,a0,-92 # 80007238 <userret+0x1a8>
    8000129c:	fffff097          	auipc	ra,0xfffff
    800012a0:	2b2080e7          	jalr	690(ra) # 8000054e <panic>

00000000800012a4 <uvminit>:
{
    800012a4:	7179                	addi	sp,sp,-48
    800012a6:	f406                	sd	ra,40(sp)
    800012a8:	f022                	sd	s0,32(sp)
    800012aa:	ec26                	sd	s1,24(sp)
    800012ac:	e84a                	sd	s2,16(sp)
    800012ae:	e44e                	sd	s3,8(sp)
    800012b0:	e052                	sd	s4,0(sp)
    800012b2:	1800                	addi	s0,sp,48
  if(sz >= PGSIZE)
    800012b4:	6785                	lui	a5,0x1
    800012b6:	04f67863          	bgeu	a2,a5,80001306 <uvminit+0x62>
    800012ba:	8a2a                	mv	s4,a0
    800012bc:	89ae                	mv	s3,a1
    800012be:	84b2                	mv	s1,a2
  mem = kalloc();
    800012c0:	fffff097          	auipc	ra,0xfffff
    800012c4:	69c080e7          	jalr	1692(ra) # 8000095c <kalloc>
    800012c8:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    800012ca:	6605                	lui	a2,0x1
    800012cc:	4581                	li	a1,0
    800012ce:	00000097          	auipc	ra,0x0
    800012d2:	89c080e7          	jalr	-1892(ra) # 80000b6a <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800012d6:	4779                	li	a4,30
    800012d8:	86ca                	mv	a3,s2
    800012da:	6605                	lui	a2,0x1
    800012dc:	4581                	li	a1,0
    800012de:	8552                	mv	a0,s4
    800012e0:	00000097          	auipc	ra,0x0
    800012e4:	d26080e7          	jalr	-730(ra) # 80001006 <mappages>
  memmove(mem, src, sz);
    800012e8:	8626                	mv	a2,s1
    800012ea:	85ce                	mv	a1,s3
    800012ec:	854a                	mv	a0,s2
    800012ee:	00000097          	auipc	ra,0x0
    800012f2:	8dc080e7          	jalr	-1828(ra) # 80000bca <memmove>
}
    800012f6:	70a2                	ld	ra,40(sp)
    800012f8:	7402                	ld	s0,32(sp)
    800012fa:	64e2                	ld	s1,24(sp)
    800012fc:	6942                	ld	s2,16(sp)
    800012fe:	69a2                	ld	s3,8(sp)
    80001300:	6a02                	ld	s4,0(sp)
    80001302:	6145                	addi	sp,sp,48
    80001304:	8082                	ret
    panic("inituvm: more than a page");
    80001306:	00006517          	auipc	a0,0x6
    8000130a:	f5250513          	addi	a0,a0,-174 # 80007258 <userret+0x1c8>
    8000130e:	fffff097          	auipc	ra,0xfffff
    80001312:	240080e7          	jalr	576(ra) # 8000054e <panic>

0000000080001316 <uvmdealloc>:
{
    80001316:	1101                	addi	sp,sp,-32
    80001318:	ec06                	sd	ra,24(sp)
    8000131a:	e822                	sd	s0,16(sp)
    8000131c:	e426                	sd	s1,8(sp)
    8000131e:	1000                	addi	s0,sp,32
    return oldsz;
    80001320:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    80001322:	00b67d63          	bgeu	a2,a1,8000133c <uvmdealloc+0x26>
    80001326:	84b2                	mv	s1,a2
  uint64 newup = PGROUNDUP(newsz);
    80001328:	6785                	lui	a5,0x1
    8000132a:	17fd                	addi	a5,a5,-1
    8000132c:	00f60733          	add	a4,a2,a5
    80001330:	76fd                	lui	a3,0xfffff
    80001332:	8f75                	and	a4,a4,a3
  if(newup < PGROUNDUP(oldsz))
    80001334:	97ae                	add	a5,a5,a1
    80001336:	8ff5                	and	a5,a5,a3
    80001338:	00f76863          	bltu	a4,a5,80001348 <uvmdealloc+0x32>
}
    8000133c:	8526                	mv	a0,s1
    8000133e:	60e2                	ld	ra,24(sp)
    80001340:	6442                	ld	s0,16(sp)
    80001342:	64a2                	ld	s1,8(sp)
    80001344:	6105                	addi	sp,sp,32
    80001346:	8082                	ret
    uvmunmap(pagetable, newup, oldsz - newup, 1);
    80001348:	4685                	li	a3,1
    8000134a:	40e58633          	sub	a2,a1,a4
    8000134e:	85ba                	mv	a1,a4
    80001350:	00000097          	auipc	ra,0x0
    80001354:	e4e080e7          	jalr	-434(ra) # 8000119e <uvmunmap>
    80001358:	b7d5                	j	8000133c <uvmdealloc+0x26>

000000008000135a <uvmalloc>:
  if(newsz < oldsz)
    8000135a:	0ab66163          	bltu	a2,a1,800013fc <uvmalloc+0xa2>
{
    8000135e:	7139                	addi	sp,sp,-64
    80001360:	fc06                	sd	ra,56(sp)
    80001362:	f822                	sd	s0,48(sp)
    80001364:	f426                	sd	s1,40(sp)
    80001366:	f04a                	sd	s2,32(sp)
    80001368:	ec4e                	sd	s3,24(sp)
    8000136a:	e852                	sd	s4,16(sp)
    8000136c:	e456                	sd	s5,8(sp)
    8000136e:	0080                	addi	s0,sp,64
    80001370:	8aaa                	mv	s5,a0
    80001372:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001374:	6985                	lui	s3,0x1
    80001376:	19fd                	addi	s3,s3,-1
    80001378:	95ce                	add	a1,a1,s3
    8000137a:	79fd                	lui	s3,0xfffff
    8000137c:	0135f9b3          	and	s3,a1,s3
  for(; a < newsz; a += PGSIZE){
    80001380:	08c9f063          	bgeu	s3,a2,80001400 <uvmalloc+0xa6>
  a = oldsz;
    80001384:	894e                	mv	s2,s3
    mem = kalloc();
    80001386:	fffff097          	auipc	ra,0xfffff
    8000138a:	5d6080e7          	jalr	1494(ra) # 8000095c <kalloc>
    8000138e:	84aa                	mv	s1,a0
    if(mem == 0){
    80001390:	c51d                	beqz	a0,800013be <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    80001392:	6605                	lui	a2,0x1
    80001394:	4581                	li	a1,0
    80001396:	fffff097          	auipc	ra,0xfffff
    8000139a:	7d4080e7          	jalr	2004(ra) # 80000b6a <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    8000139e:	4779                	li	a4,30
    800013a0:	86a6                	mv	a3,s1
    800013a2:	6605                	lui	a2,0x1
    800013a4:	85ca                	mv	a1,s2
    800013a6:	8556                	mv	a0,s5
    800013a8:	00000097          	auipc	ra,0x0
    800013ac:	c5e080e7          	jalr	-930(ra) # 80001006 <mappages>
    800013b0:	e905                	bnez	a0,800013e0 <uvmalloc+0x86>
  for(; a < newsz; a += PGSIZE){
    800013b2:	6785                	lui	a5,0x1
    800013b4:	993e                	add	s2,s2,a5
    800013b6:	fd4968e3          	bltu	s2,s4,80001386 <uvmalloc+0x2c>
  return newsz;
    800013ba:	8552                	mv	a0,s4
    800013bc:	a809                	j	800013ce <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    800013be:	864e                	mv	a2,s3
    800013c0:	85ca                	mv	a1,s2
    800013c2:	8556                	mv	a0,s5
    800013c4:	00000097          	auipc	ra,0x0
    800013c8:	f52080e7          	jalr	-174(ra) # 80001316 <uvmdealloc>
      return 0;
    800013cc:	4501                	li	a0,0
}
    800013ce:	70e2                	ld	ra,56(sp)
    800013d0:	7442                	ld	s0,48(sp)
    800013d2:	74a2                	ld	s1,40(sp)
    800013d4:	7902                	ld	s2,32(sp)
    800013d6:	69e2                	ld	s3,24(sp)
    800013d8:	6a42                	ld	s4,16(sp)
    800013da:	6aa2                	ld	s5,8(sp)
    800013dc:	6121                	addi	sp,sp,64
    800013de:	8082                	ret
      kfree(mem);
    800013e0:	8526                	mv	a0,s1
    800013e2:	fffff097          	auipc	ra,0xfffff
    800013e6:	47e080e7          	jalr	1150(ra) # 80000860 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800013ea:	864e                	mv	a2,s3
    800013ec:	85ca                	mv	a1,s2
    800013ee:	8556                	mv	a0,s5
    800013f0:	00000097          	auipc	ra,0x0
    800013f4:	f26080e7          	jalr	-218(ra) # 80001316 <uvmdealloc>
      return 0;
    800013f8:	4501                	li	a0,0
    800013fa:	bfd1                	j	800013ce <uvmalloc+0x74>
    return oldsz;
    800013fc:	852e                	mv	a0,a1
}
    800013fe:	8082                	ret
  return newsz;
    80001400:	8532                	mv	a0,a2
    80001402:	b7f1                	j	800013ce <uvmalloc+0x74>

0000000080001404 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001404:	1101                	addi	sp,sp,-32
    80001406:	ec06                	sd	ra,24(sp)
    80001408:	e822                	sd	s0,16(sp)
    8000140a:	e426                	sd	s1,8(sp)
    8000140c:	1000                	addi	s0,sp,32
    8000140e:	84aa                	mv	s1,a0
    80001410:	862e                	mv	a2,a1
  uvmunmap(pagetable, 0, sz, 1);
    80001412:	4685                	li	a3,1
    80001414:	4581                	li	a1,0
    80001416:	00000097          	auipc	ra,0x0
    8000141a:	d88080e7          	jalr	-632(ra) # 8000119e <uvmunmap>
  freewalk(pagetable);
    8000141e:	8526                	mv	a0,s1
    80001420:	00000097          	auipc	ra,0x0
    80001424:	ab8080e7          	jalr	-1352(ra) # 80000ed8 <freewalk>
}
    80001428:	60e2                	ld	ra,24(sp)
    8000142a:	6442                	ld	s0,16(sp)
    8000142c:	64a2                	ld	s1,8(sp)
    8000142e:	6105                	addi	sp,sp,32
    80001430:	8082                	ret

0000000080001432 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001432:	c671                	beqz	a2,800014fe <uvmcopy+0xcc>
{
    80001434:	715d                	addi	sp,sp,-80
    80001436:	e486                	sd	ra,72(sp)
    80001438:	e0a2                	sd	s0,64(sp)
    8000143a:	fc26                	sd	s1,56(sp)
    8000143c:	f84a                	sd	s2,48(sp)
    8000143e:	f44e                	sd	s3,40(sp)
    80001440:	f052                	sd	s4,32(sp)
    80001442:	ec56                	sd	s5,24(sp)
    80001444:	e85a                	sd	s6,16(sp)
    80001446:	e45e                	sd	s7,8(sp)
    80001448:	0880                	addi	s0,sp,80
    8000144a:	8b2a                	mv	s6,a0
    8000144c:	8aae                	mv	s5,a1
    8000144e:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001450:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001452:	4601                	li	a2,0
    80001454:	85ce                	mv	a1,s3
    80001456:	855a                	mv	a0,s6
    80001458:	00000097          	auipc	ra,0x0
    8000145c:	9da080e7          	jalr	-1574(ra) # 80000e32 <walk>
    80001460:	c531                	beqz	a0,800014ac <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001462:	6118                	ld	a4,0(a0)
    80001464:	00177793          	andi	a5,a4,1
    80001468:	cbb1                	beqz	a5,800014bc <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    8000146a:	00a75593          	srli	a1,a4,0xa
    8000146e:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    80001472:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    80001476:	fffff097          	auipc	ra,0xfffff
    8000147a:	4e6080e7          	jalr	1254(ra) # 8000095c <kalloc>
    8000147e:	892a                	mv	s2,a0
    80001480:	c939                	beqz	a0,800014d6 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    80001482:	6605                	lui	a2,0x1
    80001484:	85de                	mv	a1,s7
    80001486:	fffff097          	auipc	ra,0xfffff
    8000148a:	744080e7          	jalr	1860(ra) # 80000bca <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    8000148e:	8726                	mv	a4,s1
    80001490:	86ca                	mv	a3,s2
    80001492:	6605                	lui	a2,0x1
    80001494:	85ce                	mv	a1,s3
    80001496:	8556                	mv	a0,s5
    80001498:	00000097          	auipc	ra,0x0
    8000149c:	b6e080e7          	jalr	-1170(ra) # 80001006 <mappages>
    800014a0:	e515                	bnez	a0,800014cc <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800014a2:	6785                	lui	a5,0x1
    800014a4:	99be                	add	s3,s3,a5
    800014a6:	fb49e6e3          	bltu	s3,s4,80001452 <uvmcopy+0x20>
    800014aa:	a83d                	j	800014e8 <uvmcopy+0xb6>
      panic("uvmcopy: pte should exist");
    800014ac:	00006517          	auipc	a0,0x6
    800014b0:	dcc50513          	addi	a0,a0,-564 # 80007278 <userret+0x1e8>
    800014b4:	fffff097          	auipc	ra,0xfffff
    800014b8:	09a080e7          	jalr	154(ra) # 8000054e <panic>
      panic("uvmcopy: page not present");
    800014bc:	00006517          	auipc	a0,0x6
    800014c0:	ddc50513          	addi	a0,a0,-548 # 80007298 <userret+0x208>
    800014c4:	fffff097          	auipc	ra,0xfffff
    800014c8:	08a080e7          	jalr	138(ra) # 8000054e <panic>
      kfree(mem);
    800014cc:	854a                	mv	a0,s2
    800014ce:	fffff097          	auipc	ra,0xfffff
    800014d2:	392080e7          	jalr	914(ra) # 80000860 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i, 1);
    800014d6:	4685                	li	a3,1
    800014d8:	864e                	mv	a2,s3
    800014da:	4581                	li	a1,0
    800014dc:	8556                	mv	a0,s5
    800014de:	00000097          	auipc	ra,0x0
    800014e2:	cc0080e7          	jalr	-832(ra) # 8000119e <uvmunmap>
  return -1;
    800014e6:	557d                	li	a0,-1
}
    800014e8:	60a6                	ld	ra,72(sp)
    800014ea:	6406                	ld	s0,64(sp)
    800014ec:	74e2                	ld	s1,56(sp)
    800014ee:	7942                	ld	s2,48(sp)
    800014f0:	79a2                	ld	s3,40(sp)
    800014f2:	7a02                	ld	s4,32(sp)
    800014f4:	6ae2                	ld	s5,24(sp)
    800014f6:	6b42                	ld	s6,16(sp)
    800014f8:	6ba2                	ld	s7,8(sp)
    800014fa:	6161                	addi	sp,sp,80
    800014fc:	8082                	ret
  return 0;
    800014fe:	4501                	li	a0,0
}
    80001500:	8082                	ret

0000000080001502 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001502:	1141                	addi	sp,sp,-16
    80001504:	e406                	sd	ra,8(sp)
    80001506:	e022                	sd	s0,0(sp)
    80001508:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    8000150a:	4601                	li	a2,0
    8000150c:	00000097          	auipc	ra,0x0
    80001510:	926080e7          	jalr	-1754(ra) # 80000e32 <walk>
  if(pte == 0)
    80001514:	c901                	beqz	a0,80001524 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001516:	611c                	ld	a5,0(a0)
    80001518:	9bbd                	andi	a5,a5,-17
    8000151a:	e11c                	sd	a5,0(a0)
}
    8000151c:	60a2                	ld	ra,8(sp)
    8000151e:	6402                	ld	s0,0(sp)
    80001520:	0141                	addi	sp,sp,16
    80001522:	8082                	ret
    panic("uvmclear");
    80001524:	00006517          	auipc	a0,0x6
    80001528:	d9450513          	addi	a0,a0,-620 # 800072b8 <userret+0x228>
    8000152c:	fffff097          	auipc	ra,0xfffff
    80001530:	022080e7          	jalr	34(ra) # 8000054e <panic>

0000000080001534 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001534:	c6bd                	beqz	a3,800015a2 <copyout+0x6e>
{
    80001536:	715d                	addi	sp,sp,-80
    80001538:	e486                	sd	ra,72(sp)
    8000153a:	e0a2                	sd	s0,64(sp)
    8000153c:	fc26                	sd	s1,56(sp)
    8000153e:	f84a                	sd	s2,48(sp)
    80001540:	f44e                	sd	s3,40(sp)
    80001542:	f052                	sd	s4,32(sp)
    80001544:	ec56                	sd	s5,24(sp)
    80001546:	e85a                	sd	s6,16(sp)
    80001548:	e45e                	sd	s7,8(sp)
    8000154a:	e062                	sd	s8,0(sp)
    8000154c:	0880                	addi	s0,sp,80
    8000154e:	8b2a                	mv	s6,a0
    80001550:	8c2e                	mv	s8,a1
    80001552:	8a32                	mv	s4,a2
    80001554:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001556:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001558:	6a85                	lui	s5,0x1
    8000155a:	a015                	j	8000157e <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000155c:	9562                	add	a0,a0,s8
    8000155e:	0004861b          	sext.w	a2,s1
    80001562:	85d2                	mv	a1,s4
    80001564:	41250533          	sub	a0,a0,s2
    80001568:	fffff097          	auipc	ra,0xfffff
    8000156c:	662080e7          	jalr	1634(ra) # 80000bca <memmove>

    len -= n;
    80001570:	409989b3          	sub	s3,s3,s1
    src += n;
    80001574:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    80001576:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000157a:	02098263          	beqz	s3,8000159e <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    8000157e:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001582:	85ca                	mv	a1,s2
    80001584:	855a                	mv	a0,s6
    80001586:	00000097          	auipc	ra,0x0
    8000158a:	9e0080e7          	jalr	-1568(ra) # 80000f66 <walkaddr>
    if(pa0 == 0)
    8000158e:	cd01                	beqz	a0,800015a6 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    80001590:	418904b3          	sub	s1,s2,s8
    80001594:	94d6                	add	s1,s1,s5
    if(n > len)
    80001596:	fc99f3e3          	bgeu	s3,s1,8000155c <copyout+0x28>
    8000159a:	84ce                	mv	s1,s3
    8000159c:	b7c1                	j	8000155c <copyout+0x28>
  }
  return 0;
    8000159e:	4501                	li	a0,0
    800015a0:	a021                	j	800015a8 <copyout+0x74>
    800015a2:	4501                	li	a0,0
}
    800015a4:	8082                	ret
      return -1;
    800015a6:	557d                	li	a0,-1
}
    800015a8:	60a6                	ld	ra,72(sp)
    800015aa:	6406                	ld	s0,64(sp)
    800015ac:	74e2                	ld	s1,56(sp)
    800015ae:	7942                	ld	s2,48(sp)
    800015b0:	79a2                	ld	s3,40(sp)
    800015b2:	7a02                	ld	s4,32(sp)
    800015b4:	6ae2                	ld	s5,24(sp)
    800015b6:	6b42                	ld	s6,16(sp)
    800015b8:	6ba2                	ld	s7,8(sp)
    800015ba:	6c02                	ld	s8,0(sp)
    800015bc:	6161                	addi	sp,sp,80
    800015be:	8082                	ret

00000000800015c0 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800015c0:	c6bd                	beqz	a3,8000162e <copyin+0x6e>
{
    800015c2:	715d                	addi	sp,sp,-80
    800015c4:	e486                	sd	ra,72(sp)
    800015c6:	e0a2                	sd	s0,64(sp)
    800015c8:	fc26                	sd	s1,56(sp)
    800015ca:	f84a                	sd	s2,48(sp)
    800015cc:	f44e                	sd	s3,40(sp)
    800015ce:	f052                	sd	s4,32(sp)
    800015d0:	ec56                	sd	s5,24(sp)
    800015d2:	e85a                	sd	s6,16(sp)
    800015d4:	e45e                	sd	s7,8(sp)
    800015d6:	e062                	sd	s8,0(sp)
    800015d8:	0880                	addi	s0,sp,80
    800015da:	8b2a                	mv	s6,a0
    800015dc:	8a2e                	mv	s4,a1
    800015de:	8c32                	mv	s8,a2
    800015e0:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    800015e2:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800015e4:	6a85                	lui	s5,0x1
    800015e6:	a015                	j	8000160a <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    800015e8:	9562                	add	a0,a0,s8
    800015ea:	0004861b          	sext.w	a2,s1
    800015ee:	412505b3          	sub	a1,a0,s2
    800015f2:	8552                	mv	a0,s4
    800015f4:	fffff097          	auipc	ra,0xfffff
    800015f8:	5d6080e7          	jalr	1494(ra) # 80000bca <memmove>

    len -= n;
    800015fc:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001600:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001602:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001606:	02098263          	beqz	s3,8000162a <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    8000160a:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000160e:	85ca                	mv	a1,s2
    80001610:	855a                	mv	a0,s6
    80001612:	00000097          	auipc	ra,0x0
    80001616:	954080e7          	jalr	-1708(ra) # 80000f66 <walkaddr>
    if(pa0 == 0)
    8000161a:	cd01                	beqz	a0,80001632 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    8000161c:	418904b3          	sub	s1,s2,s8
    80001620:	94d6                	add	s1,s1,s5
    if(n > len)
    80001622:	fc99f3e3          	bgeu	s3,s1,800015e8 <copyin+0x28>
    80001626:	84ce                	mv	s1,s3
    80001628:	b7c1                	j	800015e8 <copyin+0x28>
  }
  return 0;
    8000162a:	4501                	li	a0,0
    8000162c:	a021                	j	80001634 <copyin+0x74>
    8000162e:	4501                	li	a0,0
}
    80001630:	8082                	ret
      return -1;
    80001632:	557d                	li	a0,-1
}
    80001634:	60a6                	ld	ra,72(sp)
    80001636:	6406                	ld	s0,64(sp)
    80001638:	74e2                	ld	s1,56(sp)
    8000163a:	7942                	ld	s2,48(sp)
    8000163c:	79a2                	ld	s3,40(sp)
    8000163e:	7a02                	ld	s4,32(sp)
    80001640:	6ae2                	ld	s5,24(sp)
    80001642:	6b42                	ld	s6,16(sp)
    80001644:	6ba2                	ld	s7,8(sp)
    80001646:	6c02                	ld	s8,0(sp)
    80001648:	6161                	addi	sp,sp,80
    8000164a:	8082                	ret

000000008000164c <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    8000164c:	c6c5                	beqz	a3,800016f4 <copyinstr+0xa8>
{
    8000164e:	715d                	addi	sp,sp,-80
    80001650:	e486                	sd	ra,72(sp)
    80001652:	e0a2                	sd	s0,64(sp)
    80001654:	fc26                	sd	s1,56(sp)
    80001656:	f84a                	sd	s2,48(sp)
    80001658:	f44e                	sd	s3,40(sp)
    8000165a:	f052                	sd	s4,32(sp)
    8000165c:	ec56                	sd	s5,24(sp)
    8000165e:	e85a                	sd	s6,16(sp)
    80001660:	e45e                	sd	s7,8(sp)
    80001662:	0880                	addi	s0,sp,80
    80001664:	8a2a                	mv	s4,a0
    80001666:	8b2e                	mv	s6,a1
    80001668:	8bb2                	mv	s7,a2
    8000166a:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    8000166c:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000166e:	6985                	lui	s3,0x1
    80001670:	a035                	j	8000169c <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    80001672:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001676:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    80001678:	0017b793          	seqz	a5,a5
    8000167c:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    80001680:	60a6                	ld	ra,72(sp)
    80001682:	6406                	ld	s0,64(sp)
    80001684:	74e2                	ld	s1,56(sp)
    80001686:	7942                	ld	s2,48(sp)
    80001688:	79a2                	ld	s3,40(sp)
    8000168a:	7a02                	ld	s4,32(sp)
    8000168c:	6ae2                	ld	s5,24(sp)
    8000168e:	6b42                	ld	s6,16(sp)
    80001690:	6ba2                	ld	s7,8(sp)
    80001692:	6161                	addi	sp,sp,80
    80001694:	8082                	ret
    srcva = va0 + PGSIZE;
    80001696:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    8000169a:	c8a9                	beqz	s1,800016ec <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    8000169c:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800016a0:	85ca                	mv	a1,s2
    800016a2:	8552                	mv	a0,s4
    800016a4:	00000097          	auipc	ra,0x0
    800016a8:	8c2080e7          	jalr	-1854(ra) # 80000f66 <walkaddr>
    if(pa0 == 0)
    800016ac:	c131                	beqz	a0,800016f0 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800016ae:	41790833          	sub	a6,s2,s7
    800016b2:	984e                	add	a6,a6,s3
    if(n > max)
    800016b4:	0104f363          	bgeu	s1,a6,800016ba <copyinstr+0x6e>
    800016b8:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800016ba:	955e                	add	a0,a0,s7
    800016bc:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800016c0:	fc080be3          	beqz	a6,80001696 <copyinstr+0x4a>
    800016c4:	985a                	add	a6,a6,s6
    800016c6:	87da                	mv	a5,s6
      if(*p == '\0'){
    800016c8:	41650633          	sub	a2,a0,s6
    800016cc:	14fd                	addi	s1,s1,-1
    800016ce:	9b26                	add	s6,s6,s1
    800016d0:	00f60733          	add	a4,a2,a5
    800016d4:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd8fcc>
    800016d8:	df49                	beqz	a4,80001672 <copyinstr+0x26>
        *dst = *p;
    800016da:	00e78023          	sb	a4,0(a5)
      --max;
    800016de:	40fb04b3          	sub	s1,s6,a5
      dst++;
    800016e2:	0785                	addi	a5,a5,1
    while(n > 0){
    800016e4:	ff0796e3          	bne	a5,a6,800016d0 <copyinstr+0x84>
      dst++;
    800016e8:	8b42                	mv	s6,a6
    800016ea:	b775                	j	80001696 <copyinstr+0x4a>
    800016ec:	4781                	li	a5,0
    800016ee:	b769                	j	80001678 <copyinstr+0x2c>
      return -1;
    800016f0:	557d                	li	a0,-1
    800016f2:	b779                	j	80001680 <copyinstr+0x34>
  int got_null = 0;
    800016f4:	4781                	li	a5,0
  if(got_null){
    800016f6:	0017b793          	seqz	a5,a5
    800016fa:	40f00533          	neg	a0,a5
}
    800016fe:	8082                	ret

0000000080001700 <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    80001700:	1101                	addi	sp,sp,-32
    80001702:	ec06                	sd	ra,24(sp)
    80001704:	e822                	sd	s0,16(sp)
    80001706:	e426                	sd	s1,8(sp)
    80001708:	1000                	addi	s0,sp,32
    8000170a:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    8000170c:	fffff097          	auipc	ra,0xfffff
    80001710:	382080e7          	jalr	898(ra) # 80000a8e <holding>
    80001714:	c909                	beqz	a0,80001726 <wakeup1+0x26>
    panic("wakeup1");
  if(p->chan == p && p->state == SLEEPING) {
    80001716:	749c                	ld	a5,40(s1)
    80001718:	00978f63          	beq	a5,s1,80001736 <wakeup1+0x36>
    p->state = RUNNABLE;
  }
}
    8000171c:	60e2                	ld	ra,24(sp)
    8000171e:	6442                	ld	s0,16(sp)
    80001720:	64a2                	ld	s1,8(sp)
    80001722:	6105                	addi	sp,sp,32
    80001724:	8082                	ret
    panic("wakeup1");
    80001726:	00006517          	auipc	a0,0x6
    8000172a:	ba250513          	addi	a0,a0,-1118 # 800072c8 <userret+0x238>
    8000172e:	fffff097          	auipc	ra,0xfffff
    80001732:	e20080e7          	jalr	-480(ra) # 8000054e <panic>
  if(p->chan == p && p->state == SLEEPING) {
    80001736:	4c98                	lw	a4,24(s1)
    80001738:	4785                	li	a5,1
    8000173a:	fef711e3          	bne	a4,a5,8000171c <wakeup1+0x1c>
    p->state = RUNNABLE;
    8000173e:	4789                	li	a5,2
    80001740:	cc9c                	sw	a5,24(s1)
}
    80001742:	bfe9                	j	8000171c <wakeup1+0x1c>

0000000080001744 <procinit>:
{
    80001744:	715d                	addi	sp,sp,-80
    80001746:	e486                	sd	ra,72(sp)
    80001748:	e0a2                	sd	s0,64(sp)
    8000174a:	fc26                	sd	s1,56(sp)
    8000174c:	f84a                	sd	s2,48(sp)
    8000174e:	f44e                	sd	s3,40(sp)
    80001750:	f052                	sd	s4,32(sp)
    80001752:	ec56                	sd	s5,24(sp)
    80001754:	e85a                	sd	s6,16(sp)
    80001756:	e45e                	sd	s7,8(sp)
    80001758:	0880                	addi	s0,sp,80
  initlock(&pid_lock, "nextpid");
    8000175a:	00006597          	auipc	a1,0x6
    8000175e:	b7658593          	addi	a1,a1,-1162 # 800072d0 <userret+0x240>
    80001762:	00010517          	auipc	a0,0x10
    80001766:	18650513          	addi	a0,a0,390 # 800118e8 <pid_lock>
    8000176a:	fffff097          	auipc	ra,0xfffff
    8000176e:	252080e7          	jalr	594(ra) # 800009bc <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001772:	00010917          	auipc	s2,0x10
    80001776:	58e90913          	addi	s2,s2,1422 # 80011d00 <proc>
      initlock(&p->lock, "proc");
    8000177a:	00006b97          	auipc	s7,0x6
    8000177e:	b5eb8b93          	addi	s7,s7,-1186 # 800072d8 <userret+0x248>
      uint64 va = KSTACK((int) (p - proc));
    80001782:	8b4a                	mv	s6,s2
    80001784:	00006a97          	auipc	s5,0x6
    80001788:	194a8a93          	addi	s5,s5,404 # 80007918 <syscalls+0xb0>
    8000178c:	040009b7          	lui	s3,0x4000
    80001790:	19fd                	addi	s3,s3,-1
    80001792:	09b2                	slli	s3,s3,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001794:	00016a17          	auipc	s4,0x16
    80001798:	f6ca0a13          	addi	s4,s4,-148 # 80017700 <tickslock>
      initlock(&p->lock, "proc");
    8000179c:	85de                	mv	a1,s7
    8000179e:	854a                	mv	a0,s2
    800017a0:	fffff097          	auipc	ra,0xfffff
    800017a4:	21c080e7          	jalr	540(ra) # 800009bc <initlock>
      char *pa = kalloc();
    800017a8:	fffff097          	auipc	ra,0xfffff
    800017ac:	1b4080e7          	jalr	436(ra) # 8000095c <kalloc>
    800017b0:	85aa                	mv	a1,a0
      if(pa == 0)
    800017b2:	c929                	beqz	a0,80001804 <procinit+0xc0>
      uint64 va = KSTACK((int) (p - proc));
    800017b4:	416904b3          	sub	s1,s2,s6
    800017b8:	848d                	srai	s1,s1,0x3
    800017ba:	000ab783          	ld	a5,0(s5)
    800017be:	02f484b3          	mul	s1,s1,a5
    800017c2:	2485                	addiw	s1,s1,1
    800017c4:	00d4949b          	slliw	s1,s1,0xd
    800017c8:	409984b3          	sub	s1,s3,s1
      kvmmap(va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800017cc:	4699                	li	a3,6
    800017ce:	6605                	lui	a2,0x1
    800017d0:	8526                	mv	a0,s1
    800017d2:	00000097          	auipc	ra,0x0
    800017d6:	8c2080e7          	jalr	-1854(ra) # 80001094 <kvmmap>
      p->kstack = va;
    800017da:	04993023          	sd	s1,64(s2)
  for(p = proc; p < &proc[NPROC]; p++) {
    800017de:	16890913          	addi	s2,s2,360
    800017e2:	fb491de3          	bne	s2,s4,8000179c <procinit+0x58>
  kvminithart();
    800017e6:	fffff097          	auipc	ra,0xfffff
    800017ea:	75c080e7          	jalr	1884(ra) # 80000f42 <kvminithart>
}
    800017ee:	60a6                	ld	ra,72(sp)
    800017f0:	6406                	ld	s0,64(sp)
    800017f2:	74e2                	ld	s1,56(sp)
    800017f4:	7942                	ld	s2,48(sp)
    800017f6:	79a2                	ld	s3,40(sp)
    800017f8:	7a02                	ld	s4,32(sp)
    800017fa:	6ae2                	ld	s5,24(sp)
    800017fc:	6b42                	ld	s6,16(sp)
    800017fe:	6ba2                	ld	s7,8(sp)
    80001800:	6161                	addi	sp,sp,80
    80001802:	8082                	ret
        panic("kalloc");
    80001804:	00006517          	auipc	a0,0x6
    80001808:	adc50513          	addi	a0,a0,-1316 # 800072e0 <userret+0x250>
    8000180c:	fffff097          	auipc	ra,0xfffff
    80001810:	d42080e7          	jalr	-702(ra) # 8000054e <panic>

0000000080001814 <cpuid>:
{
    80001814:	1141                	addi	sp,sp,-16
    80001816:	e422                	sd	s0,8(sp)
    80001818:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    8000181a:	8512                	mv	a0,tp
}
    8000181c:	2501                	sext.w	a0,a0
    8000181e:	6422                	ld	s0,8(sp)
    80001820:	0141                	addi	sp,sp,16
    80001822:	8082                	ret

0000000080001824 <mycpu>:
mycpu(void) {
    80001824:	1141                	addi	sp,sp,-16
    80001826:	e422                	sd	s0,8(sp)
    80001828:	0800                	addi	s0,sp,16
    8000182a:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    8000182c:	2781                	sext.w	a5,a5
    8000182e:	079e                	slli	a5,a5,0x7
}
    80001830:	00010517          	auipc	a0,0x10
    80001834:	0d050513          	addi	a0,a0,208 # 80011900 <cpus>
    80001838:	953e                	add	a0,a0,a5
    8000183a:	6422                	ld	s0,8(sp)
    8000183c:	0141                	addi	sp,sp,16
    8000183e:	8082                	ret

0000000080001840 <myproc>:
myproc(void) {
    80001840:	1101                	addi	sp,sp,-32
    80001842:	ec06                	sd	ra,24(sp)
    80001844:	e822                	sd	s0,16(sp)
    80001846:	e426                	sd	s1,8(sp)
    80001848:	1000                	addi	s0,sp,32
  push_off();
    8000184a:	fffff097          	auipc	ra,0xfffff
    8000184e:	188080e7          	jalr	392(ra) # 800009d2 <push_off>
    80001852:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    80001854:	2781                	sext.w	a5,a5
    80001856:	079e                	slli	a5,a5,0x7
    80001858:	00010717          	auipc	a4,0x10
    8000185c:	09070713          	addi	a4,a4,144 # 800118e8 <pid_lock>
    80001860:	97ba                	add	a5,a5,a4
    80001862:	6f84                	ld	s1,24(a5)
  pop_off();
    80001864:	fffff097          	auipc	ra,0xfffff
    80001868:	1ba080e7          	jalr	442(ra) # 80000a1e <pop_off>
}
    8000186c:	8526                	mv	a0,s1
    8000186e:	60e2                	ld	ra,24(sp)
    80001870:	6442                	ld	s0,16(sp)
    80001872:	64a2                	ld	s1,8(sp)
    80001874:	6105                	addi	sp,sp,32
    80001876:	8082                	ret

0000000080001878 <forkret>:
{
    80001878:	1141                	addi	sp,sp,-16
    8000187a:	e406                	sd	ra,8(sp)
    8000187c:	e022                	sd	s0,0(sp)
    8000187e:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    80001880:	00000097          	auipc	ra,0x0
    80001884:	fc0080e7          	jalr	-64(ra) # 80001840 <myproc>
    80001888:	fffff097          	auipc	ra,0xfffff
    8000188c:	29a080e7          	jalr	666(ra) # 80000b22 <release>
  if (first) {
    80001890:	00006797          	auipc	a5,0x6
    80001894:	7a87a783          	lw	a5,1960(a5) # 80008038 <first.1653>
    80001898:	eb89                	bnez	a5,800018aa <forkret+0x32>
  usertrapret();
    8000189a:	00001097          	auipc	ra,0x1
    8000189e:	bc0080e7          	jalr	-1088(ra) # 8000245a <usertrapret>
}
    800018a2:	60a2                	ld	ra,8(sp)
    800018a4:	6402                	ld	s0,0(sp)
    800018a6:	0141                	addi	sp,sp,16
    800018a8:	8082                	ret
    first = 0;
    800018aa:	00006797          	auipc	a5,0x6
    800018ae:	7807a723          	sw	zero,1934(a5) # 80008038 <first.1653>
    fsinit(ROOTDEV);
    800018b2:	4505                	li	a0,1
    800018b4:	00002097          	auipc	ra,0x2
    800018b8:	a32080e7          	jalr	-1486(ra) # 800032e6 <fsinit>
    800018bc:	bff9                	j	8000189a <forkret+0x22>

00000000800018be <allocpid>:
allocpid() {
    800018be:	1101                	addi	sp,sp,-32
    800018c0:	ec06                	sd	ra,24(sp)
    800018c2:	e822                	sd	s0,16(sp)
    800018c4:	e426                	sd	s1,8(sp)
    800018c6:	e04a                	sd	s2,0(sp)
    800018c8:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    800018ca:	00010917          	auipc	s2,0x10
    800018ce:	01e90913          	addi	s2,s2,30 # 800118e8 <pid_lock>
    800018d2:	854a                	mv	a0,s2
    800018d4:	fffff097          	auipc	ra,0xfffff
    800018d8:	1fa080e7          	jalr	506(ra) # 80000ace <acquire>
  pid = nextpid;
    800018dc:	00006797          	auipc	a5,0x6
    800018e0:	76078793          	addi	a5,a5,1888 # 8000803c <nextpid>
    800018e4:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    800018e6:	0014871b          	addiw	a4,s1,1
    800018ea:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    800018ec:	854a                	mv	a0,s2
    800018ee:	fffff097          	auipc	ra,0xfffff
    800018f2:	234080e7          	jalr	564(ra) # 80000b22 <release>
}
    800018f6:	8526                	mv	a0,s1
    800018f8:	60e2                	ld	ra,24(sp)
    800018fa:	6442                	ld	s0,16(sp)
    800018fc:	64a2                	ld	s1,8(sp)
    800018fe:	6902                	ld	s2,0(sp)
    80001900:	6105                	addi	sp,sp,32
    80001902:	8082                	ret

0000000080001904 <proc_pagetable>:
{
    80001904:	1101                	addi	sp,sp,-32
    80001906:	ec06                	sd	ra,24(sp)
    80001908:	e822                	sd	s0,16(sp)
    8000190a:	e426                	sd	s1,8(sp)
    8000190c:	e04a                	sd	s2,0(sp)
    8000190e:	1000                	addi	s0,sp,32
    80001910:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001912:	00000097          	auipc	ra,0x0
    80001916:	954080e7          	jalr	-1708(ra) # 80001266 <uvmcreate>
    8000191a:	84aa                	mv	s1,a0
  mappages(pagetable, TRAMPOLINE, PGSIZE,
    8000191c:	4729                	li	a4,10
    8000191e:	00005697          	auipc	a3,0x5
    80001922:	6e268693          	addi	a3,a3,1762 # 80007000 <trampoline>
    80001926:	6605                	lui	a2,0x1
    80001928:	040005b7          	lui	a1,0x4000
    8000192c:	15fd                	addi	a1,a1,-1
    8000192e:	05b2                	slli	a1,a1,0xc
    80001930:	fffff097          	auipc	ra,0xfffff
    80001934:	6d6080e7          	jalr	1750(ra) # 80001006 <mappages>
  mappages(pagetable, TRAPFRAME, PGSIZE,
    80001938:	4719                	li	a4,6
    8000193a:	05893683          	ld	a3,88(s2)
    8000193e:	6605                	lui	a2,0x1
    80001940:	020005b7          	lui	a1,0x2000
    80001944:	15fd                	addi	a1,a1,-1
    80001946:	05b6                	slli	a1,a1,0xd
    80001948:	8526                	mv	a0,s1
    8000194a:	fffff097          	auipc	ra,0xfffff
    8000194e:	6bc080e7          	jalr	1724(ra) # 80001006 <mappages>
}
    80001952:	8526                	mv	a0,s1
    80001954:	60e2                	ld	ra,24(sp)
    80001956:	6442                	ld	s0,16(sp)
    80001958:	64a2                	ld	s1,8(sp)
    8000195a:	6902                	ld	s2,0(sp)
    8000195c:	6105                	addi	sp,sp,32
    8000195e:	8082                	ret

0000000080001960 <allocproc>:
{
    80001960:	1101                	addi	sp,sp,-32
    80001962:	ec06                	sd	ra,24(sp)
    80001964:	e822                	sd	s0,16(sp)
    80001966:	e426                	sd	s1,8(sp)
    80001968:	e04a                	sd	s2,0(sp)
    8000196a:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    8000196c:	00010497          	auipc	s1,0x10
    80001970:	39448493          	addi	s1,s1,916 # 80011d00 <proc>
    80001974:	00016917          	auipc	s2,0x16
    80001978:	d8c90913          	addi	s2,s2,-628 # 80017700 <tickslock>
    acquire(&p->lock);
    8000197c:	8526                	mv	a0,s1
    8000197e:	fffff097          	auipc	ra,0xfffff
    80001982:	150080e7          	jalr	336(ra) # 80000ace <acquire>
    if(p->state == UNUSED) {
    80001986:	4c9c                	lw	a5,24(s1)
    80001988:	cf81                	beqz	a5,800019a0 <allocproc+0x40>
      release(&p->lock);
    8000198a:	8526                	mv	a0,s1
    8000198c:	fffff097          	auipc	ra,0xfffff
    80001990:	196080e7          	jalr	406(ra) # 80000b22 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001994:	16848493          	addi	s1,s1,360
    80001998:	ff2492e3          	bne	s1,s2,8000197c <allocproc+0x1c>
  return 0;
    8000199c:	4481                	li	s1,0
    8000199e:	a0a9                	j	800019e8 <allocproc+0x88>
  p->pid = allocpid();
    800019a0:	00000097          	auipc	ra,0x0
    800019a4:	f1e080e7          	jalr	-226(ra) # 800018be <allocpid>
    800019a8:	dc88                	sw	a0,56(s1)
  if((p->tf = (struct trapframe *)kalloc()) == 0){
    800019aa:	fffff097          	auipc	ra,0xfffff
    800019ae:	fb2080e7          	jalr	-78(ra) # 8000095c <kalloc>
    800019b2:	892a                	mv	s2,a0
    800019b4:	eca8                	sd	a0,88(s1)
    800019b6:	c121                	beqz	a0,800019f6 <allocproc+0x96>
  p->pagetable = proc_pagetable(p);
    800019b8:	8526                	mv	a0,s1
    800019ba:	00000097          	auipc	ra,0x0
    800019be:	f4a080e7          	jalr	-182(ra) # 80001904 <proc_pagetable>
    800019c2:	e8a8                	sd	a0,80(s1)
  memset(&p->context, 0, sizeof p->context);
    800019c4:	07000613          	li	a2,112
    800019c8:	4581                	li	a1,0
    800019ca:	06048513          	addi	a0,s1,96
    800019ce:	fffff097          	auipc	ra,0xfffff
    800019d2:	19c080e7          	jalr	412(ra) # 80000b6a <memset>
  p->context.ra = (uint64)forkret;
    800019d6:	00000797          	auipc	a5,0x0
    800019da:	ea278793          	addi	a5,a5,-350 # 80001878 <forkret>
    800019de:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    800019e0:	60bc                	ld	a5,64(s1)
    800019e2:	6705                	lui	a4,0x1
    800019e4:	97ba                	add	a5,a5,a4
    800019e6:	f4bc                	sd	a5,104(s1)
}
    800019e8:	8526                	mv	a0,s1
    800019ea:	60e2                	ld	ra,24(sp)
    800019ec:	6442                	ld	s0,16(sp)
    800019ee:	64a2                	ld	s1,8(sp)
    800019f0:	6902                	ld	s2,0(sp)
    800019f2:	6105                	addi	sp,sp,32
    800019f4:	8082                	ret
    release(&p->lock);
    800019f6:	8526                	mv	a0,s1
    800019f8:	fffff097          	auipc	ra,0xfffff
    800019fc:	12a080e7          	jalr	298(ra) # 80000b22 <release>
    return 0;
    80001a00:	84ca                	mv	s1,s2
    80001a02:	b7dd                	j	800019e8 <allocproc+0x88>

0000000080001a04 <proc_freepagetable>:
{
    80001a04:	1101                	addi	sp,sp,-32
    80001a06:	ec06                	sd	ra,24(sp)
    80001a08:	e822                	sd	s0,16(sp)
    80001a0a:	e426                	sd	s1,8(sp)
    80001a0c:	e04a                	sd	s2,0(sp)
    80001a0e:	1000                	addi	s0,sp,32
    80001a10:	84aa                	mv	s1,a0
    80001a12:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, PGSIZE, 0);
    80001a14:	4681                	li	a3,0
    80001a16:	6605                	lui	a2,0x1
    80001a18:	040005b7          	lui	a1,0x4000
    80001a1c:	15fd                	addi	a1,a1,-1
    80001a1e:	05b2                	slli	a1,a1,0xc
    80001a20:	fffff097          	auipc	ra,0xfffff
    80001a24:	77e080e7          	jalr	1918(ra) # 8000119e <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, PGSIZE, 0);
    80001a28:	4681                	li	a3,0
    80001a2a:	6605                	lui	a2,0x1
    80001a2c:	020005b7          	lui	a1,0x2000
    80001a30:	15fd                	addi	a1,a1,-1
    80001a32:	05b6                	slli	a1,a1,0xd
    80001a34:	8526                	mv	a0,s1
    80001a36:	fffff097          	auipc	ra,0xfffff
    80001a3a:	768080e7          	jalr	1896(ra) # 8000119e <uvmunmap>
  if(sz > 0)
    80001a3e:	00091863          	bnez	s2,80001a4e <proc_freepagetable+0x4a>
}
    80001a42:	60e2                	ld	ra,24(sp)
    80001a44:	6442                	ld	s0,16(sp)
    80001a46:	64a2                	ld	s1,8(sp)
    80001a48:	6902                	ld	s2,0(sp)
    80001a4a:	6105                	addi	sp,sp,32
    80001a4c:	8082                	ret
    uvmfree(pagetable, sz);
    80001a4e:	85ca                	mv	a1,s2
    80001a50:	8526                	mv	a0,s1
    80001a52:	00000097          	auipc	ra,0x0
    80001a56:	9b2080e7          	jalr	-1614(ra) # 80001404 <uvmfree>
}
    80001a5a:	b7e5                	j	80001a42 <proc_freepagetable+0x3e>

0000000080001a5c <freeproc>:
{
    80001a5c:	1101                	addi	sp,sp,-32
    80001a5e:	ec06                	sd	ra,24(sp)
    80001a60:	e822                	sd	s0,16(sp)
    80001a62:	e426                	sd	s1,8(sp)
    80001a64:	1000                	addi	s0,sp,32
    80001a66:	84aa                	mv	s1,a0
  if(p->tf)
    80001a68:	6d28                	ld	a0,88(a0)
    80001a6a:	c509                	beqz	a0,80001a74 <freeproc+0x18>
    kfree((void*)p->tf);
    80001a6c:	fffff097          	auipc	ra,0xfffff
    80001a70:	df4080e7          	jalr	-524(ra) # 80000860 <kfree>
  p->tf = 0;
    80001a74:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001a78:	68a8                	ld	a0,80(s1)
    80001a7a:	c511                	beqz	a0,80001a86 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001a7c:	64ac                	ld	a1,72(s1)
    80001a7e:	00000097          	auipc	ra,0x0
    80001a82:	f86080e7          	jalr	-122(ra) # 80001a04 <proc_freepagetable>
  p->pagetable = 0;
    80001a86:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001a8a:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001a8e:	0204ac23          	sw	zero,56(s1)
  p->parent = 0;
    80001a92:	0204b023          	sd	zero,32(s1)
  p->name[0] = 0;
    80001a96:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001a9a:	0204b423          	sd	zero,40(s1)
  p->killed = 0;
    80001a9e:	0204a823          	sw	zero,48(s1)
  p->xstate = 0;
    80001aa2:	0204aa23          	sw	zero,52(s1)
  p->state = UNUSED;
    80001aa6:	0004ac23          	sw	zero,24(s1)
}
    80001aaa:	60e2                	ld	ra,24(sp)
    80001aac:	6442                	ld	s0,16(sp)
    80001aae:	64a2                	ld	s1,8(sp)
    80001ab0:	6105                	addi	sp,sp,32
    80001ab2:	8082                	ret

0000000080001ab4 <userinit>:
{
    80001ab4:	1101                	addi	sp,sp,-32
    80001ab6:	ec06                	sd	ra,24(sp)
    80001ab8:	e822                	sd	s0,16(sp)
    80001aba:	e426                	sd	s1,8(sp)
    80001abc:	1000                	addi	s0,sp,32
  p = allocproc();
    80001abe:	00000097          	auipc	ra,0x0
    80001ac2:	ea2080e7          	jalr	-350(ra) # 80001960 <allocproc>
    80001ac6:	84aa                	mv	s1,a0
  initproc = p;
    80001ac8:	00024797          	auipc	a5,0x24
    80001acc:	54a7b423          	sd	a0,1352(a5) # 80026010 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001ad0:	03300613          	li	a2,51
    80001ad4:	00006597          	auipc	a1,0x6
    80001ad8:	52c58593          	addi	a1,a1,1324 # 80008000 <initcode>
    80001adc:	6928                	ld	a0,80(a0)
    80001ade:	fffff097          	auipc	ra,0xfffff
    80001ae2:	7c6080e7          	jalr	1990(ra) # 800012a4 <uvminit>
  p->sz = PGSIZE;
    80001ae6:	6785                	lui	a5,0x1
    80001ae8:	e4bc                	sd	a5,72(s1)
  p->tf->epc = 0;      // user program counter
    80001aea:	6cb8                	ld	a4,88(s1)
    80001aec:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->tf->sp = PGSIZE;  // user stack pointer
    80001af0:	6cb8                	ld	a4,88(s1)
    80001af2:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001af4:	4641                	li	a2,16
    80001af6:	00005597          	auipc	a1,0x5
    80001afa:	7f258593          	addi	a1,a1,2034 # 800072e8 <userret+0x258>
    80001afe:	15848513          	addi	a0,s1,344
    80001b02:	fffff097          	auipc	ra,0xfffff
    80001b06:	1be080e7          	jalr	446(ra) # 80000cc0 <safestrcpy>
  p->cwd = namei("/");
    80001b0a:	00005517          	auipc	a0,0x5
    80001b0e:	7ee50513          	addi	a0,a0,2030 # 800072f8 <userret+0x268>
    80001b12:	00002097          	auipc	ra,0x2
    80001b16:	1d6080e7          	jalr	470(ra) # 80003ce8 <namei>
    80001b1a:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001b1e:	4789                	li	a5,2
    80001b20:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001b22:	8526                	mv	a0,s1
    80001b24:	fffff097          	auipc	ra,0xfffff
    80001b28:	ffe080e7          	jalr	-2(ra) # 80000b22 <release>
}
    80001b2c:	60e2                	ld	ra,24(sp)
    80001b2e:	6442                	ld	s0,16(sp)
    80001b30:	64a2                	ld	s1,8(sp)
    80001b32:	6105                	addi	sp,sp,32
    80001b34:	8082                	ret

0000000080001b36 <growproc>:
{
    80001b36:	1101                	addi	sp,sp,-32
    80001b38:	ec06                	sd	ra,24(sp)
    80001b3a:	e822                	sd	s0,16(sp)
    80001b3c:	e426                	sd	s1,8(sp)
    80001b3e:	e04a                	sd	s2,0(sp)
    80001b40:	1000                	addi	s0,sp,32
    80001b42:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001b44:	00000097          	auipc	ra,0x0
    80001b48:	cfc080e7          	jalr	-772(ra) # 80001840 <myproc>
    80001b4c:	892a                	mv	s2,a0
  sz = p->sz;
    80001b4e:	652c                	ld	a1,72(a0)
    80001b50:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001b54:	00904f63          	bgtz	s1,80001b72 <growproc+0x3c>
  } else if(n < 0){
    80001b58:	0204cc63          	bltz	s1,80001b90 <growproc+0x5a>
  p->sz = sz;
    80001b5c:	1602                	slli	a2,a2,0x20
    80001b5e:	9201                	srli	a2,a2,0x20
    80001b60:	04c93423          	sd	a2,72(s2)
  return 0;
    80001b64:	4501                	li	a0,0
}
    80001b66:	60e2                	ld	ra,24(sp)
    80001b68:	6442                	ld	s0,16(sp)
    80001b6a:	64a2                	ld	s1,8(sp)
    80001b6c:	6902                	ld	s2,0(sp)
    80001b6e:	6105                	addi	sp,sp,32
    80001b70:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001b72:	9e25                	addw	a2,a2,s1
    80001b74:	1602                	slli	a2,a2,0x20
    80001b76:	9201                	srli	a2,a2,0x20
    80001b78:	1582                	slli	a1,a1,0x20
    80001b7a:	9181                	srli	a1,a1,0x20
    80001b7c:	6928                	ld	a0,80(a0)
    80001b7e:	fffff097          	auipc	ra,0xfffff
    80001b82:	7dc080e7          	jalr	2012(ra) # 8000135a <uvmalloc>
    80001b86:	0005061b          	sext.w	a2,a0
    80001b8a:	fa69                	bnez	a2,80001b5c <growproc+0x26>
      return -1;
    80001b8c:	557d                	li	a0,-1
    80001b8e:	bfe1                	j	80001b66 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001b90:	9e25                	addw	a2,a2,s1
    80001b92:	1602                	slli	a2,a2,0x20
    80001b94:	9201                	srli	a2,a2,0x20
    80001b96:	1582                	slli	a1,a1,0x20
    80001b98:	9181                	srli	a1,a1,0x20
    80001b9a:	6928                	ld	a0,80(a0)
    80001b9c:	fffff097          	auipc	ra,0xfffff
    80001ba0:	77a080e7          	jalr	1914(ra) # 80001316 <uvmdealloc>
    80001ba4:	0005061b          	sext.w	a2,a0
    80001ba8:	bf55                	j	80001b5c <growproc+0x26>

0000000080001baa <fork>:
{
    80001baa:	7179                	addi	sp,sp,-48
    80001bac:	f406                	sd	ra,40(sp)
    80001bae:	f022                	sd	s0,32(sp)
    80001bb0:	ec26                	sd	s1,24(sp)
    80001bb2:	e84a                	sd	s2,16(sp)
    80001bb4:	e44e                	sd	s3,8(sp)
    80001bb6:	e052                	sd	s4,0(sp)
    80001bb8:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001bba:	00000097          	auipc	ra,0x0
    80001bbe:	c86080e7          	jalr	-890(ra) # 80001840 <myproc>
    80001bc2:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001bc4:	00000097          	auipc	ra,0x0
    80001bc8:	d9c080e7          	jalr	-612(ra) # 80001960 <allocproc>
    80001bcc:	c175                	beqz	a0,80001cb0 <fork+0x106>
    80001bce:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001bd0:	04893603          	ld	a2,72(s2)
    80001bd4:	692c                	ld	a1,80(a0)
    80001bd6:	05093503          	ld	a0,80(s2)
    80001bda:	00000097          	auipc	ra,0x0
    80001bde:	858080e7          	jalr	-1960(ra) # 80001432 <uvmcopy>
    80001be2:	04054863          	bltz	a0,80001c32 <fork+0x88>
  np->sz = p->sz;
    80001be6:	04893783          	ld	a5,72(s2)
    80001bea:	04f9b423          	sd	a5,72(s3) # 4000048 <_entry-0x7bffffb8>
  np->parent = p;
    80001bee:	0329b023          	sd	s2,32(s3)
  *(np->tf) = *(p->tf);
    80001bf2:	05893683          	ld	a3,88(s2)
    80001bf6:	87b6                	mv	a5,a3
    80001bf8:	0589b703          	ld	a4,88(s3)
    80001bfc:	12068693          	addi	a3,a3,288
    80001c00:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001c04:	6788                	ld	a0,8(a5)
    80001c06:	6b8c                	ld	a1,16(a5)
    80001c08:	6f90                	ld	a2,24(a5)
    80001c0a:	01073023          	sd	a6,0(a4)
    80001c0e:	e708                	sd	a0,8(a4)
    80001c10:	eb0c                	sd	a1,16(a4)
    80001c12:	ef10                	sd	a2,24(a4)
    80001c14:	02078793          	addi	a5,a5,32
    80001c18:	02070713          	addi	a4,a4,32
    80001c1c:	fed792e3          	bne	a5,a3,80001c00 <fork+0x56>
  np->tf->a0 = 0;
    80001c20:	0589b783          	ld	a5,88(s3)
    80001c24:	0607b823          	sd	zero,112(a5)
    80001c28:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001c2c:	15000a13          	li	s4,336
    80001c30:	a03d                	j	80001c5e <fork+0xb4>
    freeproc(np);
    80001c32:	854e                	mv	a0,s3
    80001c34:	00000097          	auipc	ra,0x0
    80001c38:	e28080e7          	jalr	-472(ra) # 80001a5c <freeproc>
    release(&np->lock);
    80001c3c:	854e                	mv	a0,s3
    80001c3e:	fffff097          	auipc	ra,0xfffff
    80001c42:	ee4080e7          	jalr	-284(ra) # 80000b22 <release>
    return -1;
    80001c46:	54fd                	li	s1,-1
    80001c48:	a899                	j	80001c9e <fork+0xf4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001c4a:	00002097          	auipc	ra,0x2
    80001c4e:	72a080e7          	jalr	1834(ra) # 80004374 <filedup>
    80001c52:	009987b3          	add	a5,s3,s1
    80001c56:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001c58:	04a1                	addi	s1,s1,8
    80001c5a:	01448763          	beq	s1,s4,80001c68 <fork+0xbe>
    if(p->ofile[i])
    80001c5e:	009907b3          	add	a5,s2,s1
    80001c62:	6388                	ld	a0,0(a5)
    80001c64:	f17d                	bnez	a0,80001c4a <fork+0xa0>
    80001c66:	bfcd                	j	80001c58 <fork+0xae>
  np->cwd = idup(p->cwd);
    80001c68:	15093503          	ld	a0,336(s2)
    80001c6c:	00002097          	auipc	ra,0x2
    80001c70:	8b4080e7          	jalr	-1868(ra) # 80003520 <idup>
    80001c74:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001c78:	4641                	li	a2,16
    80001c7a:	15890593          	addi	a1,s2,344
    80001c7e:	15898513          	addi	a0,s3,344
    80001c82:	fffff097          	auipc	ra,0xfffff
    80001c86:	03e080e7          	jalr	62(ra) # 80000cc0 <safestrcpy>
  pid = np->pid;
    80001c8a:	0389a483          	lw	s1,56(s3)
  np->state = RUNNABLE;
    80001c8e:	4789                	li	a5,2
    80001c90:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001c94:	854e                	mv	a0,s3
    80001c96:	fffff097          	auipc	ra,0xfffff
    80001c9a:	e8c080e7          	jalr	-372(ra) # 80000b22 <release>
}
    80001c9e:	8526                	mv	a0,s1
    80001ca0:	70a2                	ld	ra,40(sp)
    80001ca2:	7402                	ld	s0,32(sp)
    80001ca4:	64e2                	ld	s1,24(sp)
    80001ca6:	6942                	ld	s2,16(sp)
    80001ca8:	69a2                	ld	s3,8(sp)
    80001caa:	6a02                	ld	s4,0(sp)
    80001cac:	6145                	addi	sp,sp,48
    80001cae:	8082                	ret
    return -1;
    80001cb0:	54fd                	li	s1,-1
    80001cb2:	b7f5                	j	80001c9e <fork+0xf4>

0000000080001cb4 <reparent>:
{
    80001cb4:	7179                	addi	sp,sp,-48
    80001cb6:	f406                	sd	ra,40(sp)
    80001cb8:	f022                	sd	s0,32(sp)
    80001cba:	ec26                	sd	s1,24(sp)
    80001cbc:	e84a                	sd	s2,16(sp)
    80001cbe:	e44e                	sd	s3,8(sp)
    80001cc0:	e052                	sd	s4,0(sp)
    80001cc2:	1800                	addi	s0,sp,48
    80001cc4:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001cc6:	00010497          	auipc	s1,0x10
    80001cca:	03a48493          	addi	s1,s1,58 # 80011d00 <proc>
      pp->parent = initproc;
    80001cce:	00024a17          	auipc	s4,0x24
    80001cd2:	342a0a13          	addi	s4,s4,834 # 80026010 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001cd6:	00016997          	auipc	s3,0x16
    80001cda:	a2a98993          	addi	s3,s3,-1494 # 80017700 <tickslock>
    80001cde:	a029                	j	80001ce8 <reparent+0x34>
    80001ce0:	16848493          	addi	s1,s1,360
    80001ce4:	03348363          	beq	s1,s3,80001d0a <reparent+0x56>
    if(pp->parent == p){
    80001ce8:	709c                	ld	a5,32(s1)
    80001cea:	ff279be3          	bne	a5,s2,80001ce0 <reparent+0x2c>
      acquire(&pp->lock);
    80001cee:	8526                	mv	a0,s1
    80001cf0:	fffff097          	auipc	ra,0xfffff
    80001cf4:	dde080e7          	jalr	-546(ra) # 80000ace <acquire>
      pp->parent = initproc;
    80001cf8:	000a3783          	ld	a5,0(s4)
    80001cfc:	f09c                	sd	a5,32(s1)
      release(&pp->lock);
    80001cfe:	8526                	mv	a0,s1
    80001d00:	fffff097          	auipc	ra,0xfffff
    80001d04:	e22080e7          	jalr	-478(ra) # 80000b22 <release>
    80001d08:	bfe1                	j	80001ce0 <reparent+0x2c>
}
    80001d0a:	70a2                	ld	ra,40(sp)
    80001d0c:	7402                	ld	s0,32(sp)
    80001d0e:	64e2                	ld	s1,24(sp)
    80001d10:	6942                	ld	s2,16(sp)
    80001d12:	69a2                	ld	s3,8(sp)
    80001d14:	6a02                	ld	s4,0(sp)
    80001d16:	6145                	addi	sp,sp,48
    80001d18:	8082                	ret

0000000080001d1a <scheduler>:
{
    80001d1a:	7139                	addi	sp,sp,-64
    80001d1c:	fc06                	sd	ra,56(sp)
    80001d1e:	f822                	sd	s0,48(sp)
    80001d20:	f426                	sd	s1,40(sp)
    80001d22:	f04a                	sd	s2,32(sp)
    80001d24:	ec4e                	sd	s3,24(sp)
    80001d26:	e852                	sd	s4,16(sp)
    80001d28:	e456                	sd	s5,8(sp)
    80001d2a:	e05a                	sd	s6,0(sp)
    80001d2c:	0080                	addi	s0,sp,64
    80001d2e:	8792                	mv	a5,tp
  int id = r_tp();
    80001d30:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001d32:	00779a93          	slli	s5,a5,0x7
    80001d36:	00010717          	auipc	a4,0x10
    80001d3a:	bb270713          	addi	a4,a4,-1102 # 800118e8 <pid_lock>
    80001d3e:	9756                	add	a4,a4,s5
    80001d40:	00073c23          	sd	zero,24(a4)
        swtch(&c->scheduler, &p->context);
    80001d44:	00010717          	auipc	a4,0x10
    80001d48:	bc470713          	addi	a4,a4,-1084 # 80011908 <cpus+0x8>
    80001d4c:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001d4e:	4989                	li	s3,2
        p->state = RUNNING;
    80001d50:	4b0d                	li	s6,3
        c->proc = p;
    80001d52:	079e                	slli	a5,a5,0x7
    80001d54:	00010a17          	auipc	s4,0x10
    80001d58:	b94a0a13          	addi	s4,s4,-1132 # 800118e8 <pid_lock>
    80001d5c:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001d5e:	00016917          	auipc	s2,0x16
    80001d62:	9a290913          	addi	s2,s2,-1630 # 80017700 <tickslock>
  asm volatile("csrr %0, sie" : "=r" (x) );
    80001d66:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    80001d6a:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    80001d6e:	10479073          	csrw	sie,a5
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001d72:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001d76:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001d7a:	10079073          	csrw	sstatus,a5
    80001d7e:	00010497          	auipc	s1,0x10
    80001d82:	f8248493          	addi	s1,s1,-126 # 80011d00 <proc>
    80001d86:	a03d                	j	80001db4 <scheduler+0x9a>
        p->state = RUNNING;
    80001d88:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001d8c:	009a3c23          	sd	s1,24(s4)
        swtch(&c->scheduler, &p->context);
    80001d90:	06048593          	addi	a1,s1,96
    80001d94:	8556                	mv	a0,s5
    80001d96:	00000097          	auipc	ra,0x0
    80001d9a:	606080e7          	jalr	1542(ra) # 8000239c <swtch>
        c->proc = 0;
    80001d9e:	000a3c23          	sd	zero,24(s4)
      release(&p->lock);
    80001da2:	8526                	mv	a0,s1
    80001da4:	fffff097          	auipc	ra,0xfffff
    80001da8:	d7e080e7          	jalr	-642(ra) # 80000b22 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001dac:	16848493          	addi	s1,s1,360
    80001db0:	fb248be3          	beq	s1,s2,80001d66 <scheduler+0x4c>
      acquire(&p->lock);
    80001db4:	8526                	mv	a0,s1
    80001db6:	fffff097          	auipc	ra,0xfffff
    80001dba:	d18080e7          	jalr	-744(ra) # 80000ace <acquire>
      if(p->state == RUNNABLE) {
    80001dbe:	4c9c                	lw	a5,24(s1)
    80001dc0:	ff3791e3          	bne	a5,s3,80001da2 <scheduler+0x88>
    80001dc4:	b7d1                	j	80001d88 <scheduler+0x6e>

0000000080001dc6 <sched>:
{
    80001dc6:	7179                	addi	sp,sp,-48
    80001dc8:	f406                	sd	ra,40(sp)
    80001dca:	f022                	sd	s0,32(sp)
    80001dcc:	ec26                	sd	s1,24(sp)
    80001dce:	e84a                	sd	s2,16(sp)
    80001dd0:	e44e                	sd	s3,8(sp)
    80001dd2:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001dd4:	00000097          	auipc	ra,0x0
    80001dd8:	a6c080e7          	jalr	-1428(ra) # 80001840 <myproc>
    80001ddc:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001dde:	fffff097          	auipc	ra,0xfffff
    80001de2:	cb0080e7          	jalr	-848(ra) # 80000a8e <holding>
    80001de6:	c93d                	beqz	a0,80001e5c <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001de8:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001dea:	2781                	sext.w	a5,a5
    80001dec:	079e                	slli	a5,a5,0x7
    80001dee:	00010717          	auipc	a4,0x10
    80001df2:	afa70713          	addi	a4,a4,-1286 # 800118e8 <pid_lock>
    80001df6:	97ba                	add	a5,a5,a4
    80001df8:	0907a703          	lw	a4,144(a5)
    80001dfc:	4785                	li	a5,1
    80001dfe:	06f71763          	bne	a4,a5,80001e6c <sched+0xa6>
  if(p->state == RUNNING)
    80001e02:	4c98                	lw	a4,24(s1)
    80001e04:	478d                	li	a5,3
    80001e06:	06f70b63          	beq	a4,a5,80001e7c <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001e0a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001e0e:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001e10:	efb5                	bnez	a5,80001e8c <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001e12:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001e14:	00010917          	auipc	s2,0x10
    80001e18:	ad490913          	addi	s2,s2,-1324 # 800118e8 <pid_lock>
    80001e1c:	2781                	sext.w	a5,a5
    80001e1e:	079e                	slli	a5,a5,0x7
    80001e20:	97ca                	add	a5,a5,s2
    80001e22:	0947a983          	lw	s3,148(a5)
    80001e26:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->scheduler);
    80001e28:	2781                	sext.w	a5,a5
    80001e2a:	079e                	slli	a5,a5,0x7
    80001e2c:	00010597          	auipc	a1,0x10
    80001e30:	adc58593          	addi	a1,a1,-1316 # 80011908 <cpus+0x8>
    80001e34:	95be                	add	a1,a1,a5
    80001e36:	06048513          	addi	a0,s1,96
    80001e3a:	00000097          	auipc	ra,0x0
    80001e3e:	562080e7          	jalr	1378(ra) # 8000239c <swtch>
    80001e42:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001e44:	2781                	sext.w	a5,a5
    80001e46:	079e                	slli	a5,a5,0x7
    80001e48:	97ca                	add	a5,a5,s2
    80001e4a:	0937aa23          	sw	s3,148(a5)
}
    80001e4e:	70a2                	ld	ra,40(sp)
    80001e50:	7402                	ld	s0,32(sp)
    80001e52:	64e2                	ld	s1,24(sp)
    80001e54:	6942                	ld	s2,16(sp)
    80001e56:	69a2                	ld	s3,8(sp)
    80001e58:	6145                	addi	sp,sp,48
    80001e5a:	8082                	ret
    panic("sched p->lock");
    80001e5c:	00005517          	auipc	a0,0x5
    80001e60:	4a450513          	addi	a0,a0,1188 # 80007300 <userret+0x270>
    80001e64:	ffffe097          	auipc	ra,0xffffe
    80001e68:	6ea080e7          	jalr	1770(ra) # 8000054e <panic>
    panic("sched locks");
    80001e6c:	00005517          	auipc	a0,0x5
    80001e70:	4a450513          	addi	a0,a0,1188 # 80007310 <userret+0x280>
    80001e74:	ffffe097          	auipc	ra,0xffffe
    80001e78:	6da080e7          	jalr	1754(ra) # 8000054e <panic>
    panic("sched running");
    80001e7c:	00005517          	auipc	a0,0x5
    80001e80:	4a450513          	addi	a0,a0,1188 # 80007320 <userret+0x290>
    80001e84:	ffffe097          	auipc	ra,0xffffe
    80001e88:	6ca080e7          	jalr	1738(ra) # 8000054e <panic>
    panic("sched interruptible");
    80001e8c:	00005517          	auipc	a0,0x5
    80001e90:	4a450513          	addi	a0,a0,1188 # 80007330 <userret+0x2a0>
    80001e94:	ffffe097          	auipc	ra,0xffffe
    80001e98:	6ba080e7          	jalr	1722(ra) # 8000054e <panic>

0000000080001e9c <exit>:
{
    80001e9c:	7179                	addi	sp,sp,-48
    80001e9e:	f406                	sd	ra,40(sp)
    80001ea0:	f022                	sd	s0,32(sp)
    80001ea2:	ec26                	sd	s1,24(sp)
    80001ea4:	e84a                	sd	s2,16(sp)
    80001ea6:	e44e                	sd	s3,8(sp)
    80001ea8:	e052                	sd	s4,0(sp)
    80001eaa:	1800                	addi	s0,sp,48
    80001eac:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80001eae:	00000097          	auipc	ra,0x0
    80001eb2:	992080e7          	jalr	-1646(ra) # 80001840 <myproc>
    80001eb6:	89aa                	mv	s3,a0
  if(p == initproc)
    80001eb8:	00024797          	auipc	a5,0x24
    80001ebc:	1587b783          	ld	a5,344(a5) # 80026010 <initproc>
    80001ec0:	0d050493          	addi	s1,a0,208
    80001ec4:	15050913          	addi	s2,a0,336
    80001ec8:	02a79363          	bne	a5,a0,80001eee <exit+0x52>
    panic("init exiting");
    80001ecc:	00005517          	auipc	a0,0x5
    80001ed0:	47c50513          	addi	a0,a0,1148 # 80007348 <userret+0x2b8>
    80001ed4:	ffffe097          	auipc	ra,0xffffe
    80001ed8:	67a080e7          	jalr	1658(ra) # 8000054e <panic>
      fileclose(f);
    80001edc:	00002097          	auipc	ra,0x2
    80001ee0:	4ea080e7          	jalr	1258(ra) # 800043c6 <fileclose>
      p->ofile[fd] = 0;
    80001ee4:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80001ee8:	04a1                	addi	s1,s1,8
    80001eea:	01248563          	beq	s1,s2,80001ef4 <exit+0x58>
    if(p->ofile[fd]){
    80001eee:	6088                	ld	a0,0(s1)
    80001ef0:	f575                	bnez	a0,80001edc <exit+0x40>
    80001ef2:	bfdd                	j	80001ee8 <exit+0x4c>
  begin_op();
    80001ef4:	00002097          	auipc	ra,0x2
    80001ef8:	000080e7          	jalr	ra # 80003ef4 <begin_op>
  iput(p->cwd);
    80001efc:	1509b503          	ld	a0,336(s3)
    80001f00:	00001097          	auipc	ra,0x1
    80001f04:	76c080e7          	jalr	1900(ra) # 8000366c <iput>
  end_op();
    80001f08:	00002097          	auipc	ra,0x2
    80001f0c:	06c080e7          	jalr	108(ra) # 80003f74 <end_op>
  p->cwd = 0;
    80001f10:	1409b823          	sd	zero,336(s3)
  acquire(&initproc->lock);
    80001f14:	00024497          	auipc	s1,0x24
    80001f18:	0fc48493          	addi	s1,s1,252 # 80026010 <initproc>
    80001f1c:	6088                	ld	a0,0(s1)
    80001f1e:	fffff097          	auipc	ra,0xfffff
    80001f22:	bb0080e7          	jalr	-1104(ra) # 80000ace <acquire>
  wakeup1(initproc);
    80001f26:	6088                	ld	a0,0(s1)
    80001f28:	fffff097          	auipc	ra,0xfffff
    80001f2c:	7d8080e7          	jalr	2008(ra) # 80001700 <wakeup1>
  release(&initproc->lock);
    80001f30:	6088                	ld	a0,0(s1)
    80001f32:	fffff097          	auipc	ra,0xfffff
    80001f36:	bf0080e7          	jalr	-1040(ra) # 80000b22 <release>
  acquire(&p->lock);
    80001f3a:	854e                	mv	a0,s3
    80001f3c:	fffff097          	auipc	ra,0xfffff
    80001f40:	b92080e7          	jalr	-1134(ra) # 80000ace <acquire>
  struct proc *original_parent = p->parent;
    80001f44:	0209b483          	ld	s1,32(s3)
  release(&p->lock);
    80001f48:	854e                	mv	a0,s3
    80001f4a:	fffff097          	auipc	ra,0xfffff
    80001f4e:	bd8080e7          	jalr	-1064(ra) # 80000b22 <release>
  acquire(&original_parent->lock);
    80001f52:	8526                	mv	a0,s1
    80001f54:	fffff097          	auipc	ra,0xfffff
    80001f58:	b7a080e7          	jalr	-1158(ra) # 80000ace <acquire>
  acquire(&p->lock);
    80001f5c:	854e                	mv	a0,s3
    80001f5e:	fffff097          	auipc	ra,0xfffff
    80001f62:	b70080e7          	jalr	-1168(ra) # 80000ace <acquire>
  reparent(p);
    80001f66:	854e                	mv	a0,s3
    80001f68:	00000097          	auipc	ra,0x0
    80001f6c:	d4c080e7          	jalr	-692(ra) # 80001cb4 <reparent>
  wakeup1(original_parent);
    80001f70:	8526                	mv	a0,s1
    80001f72:	fffff097          	auipc	ra,0xfffff
    80001f76:	78e080e7          	jalr	1934(ra) # 80001700 <wakeup1>
  p->xstate = status;
    80001f7a:	0349aa23          	sw	s4,52(s3)
  p->state = ZOMBIE;
    80001f7e:	4791                	li	a5,4
    80001f80:	00f9ac23          	sw	a5,24(s3)
  release(&original_parent->lock);
    80001f84:	8526                	mv	a0,s1
    80001f86:	fffff097          	auipc	ra,0xfffff
    80001f8a:	b9c080e7          	jalr	-1124(ra) # 80000b22 <release>
  sched();
    80001f8e:	00000097          	auipc	ra,0x0
    80001f92:	e38080e7          	jalr	-456(ra) # 80001dc6 <sched>
  panic("zombie exit");
    80001f96:	00005517          	auipc	a0,0x5
    80001f9a:	3c250513          	addi	a0,a0,962 # 80007358 <userret+0x2c8>
    80001f9e:	ffffe097          	auipc	ra,0xffffe
    80001fa2:	5b0080e7          	jalr	1456(ra) # 8000054e <panic>

0000000080001fa6 <yield>:
{
    80001fa6:	1101                	addi	sp,sp,-32
    80001fa8:	ec06                	sd	ra,24(sp)
    80001faa:	e822                	sd	s0,16(sp)
    80001fac:	e426                	sd	s1,8(sp)
    80001fae:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80001fb0:	00000097          	auipc	ra,0x0
    80001fb4:	890080e7          	jalr	-1904(ra) # 80001840 <myproc>
    80001fb8:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80001fba:	fffff097          	auipc	ra,0xfffff
    80001fbe:	b14080e7          	jalr	-1260(ra) # 80000ace <acquire>
  p->state = RUNNABLE;
    80001fc2:	4789                	li	a5,2
    80001fc4:	cc9c                	sw	a5,24(s1)
  sched();
    80001fc6:	00000097          	auipc	ra,0x0
    80001fca:	e00080e7          	jalr	-512(ra) # 80001dc6 <sched>
  release(&p->lock);
    80001fce:	8526                	mv	a0,s1
    80001fd0:	fffff097          	auipc	ra,0xfffff
    80001fd4:	b52080e7          	jalr	-1198(ra) # 80000b22 <release>
}
    80001fd8:	60e2                	ld	ra,24(sp)
    80001fda:	6442                	ld	s0,16(sp)
    80001fdc:	64a2                	ld	s1,8(sp)
    80001fde:	6105                	addi	sp,sp,32
    80001fe0:	8082                	ret

0000000080001fe2 <sleep>:
{
    80001fe2:	7179                	addi	sp,sp,-48
    80001fe4:	f406                	sd	ra,40(sp)
    80001fe6:	f022                	sd	s0,32(sp)
    80001fe8:	ec26                	sd	s1,24(sp)
    80001fea:	e84a                	sd	s2,16(sp)
    80001fec:	e44e                	sd	s3,8(sp)
    80001fee:	1800                	addi	s0,sp,48
    80001ff0:	89aa                	mv	s3,a0
    80001ff2:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80001ff4:	00000097          	auipc	ra,0x0
    80001ff8:	84c080e7          	jalr	-1972(ra) # 80001840 <myproc>
    80001ffc:	84aa                	mv	s1,a0
  if(lk != &p->lock){  //DOC: sleeplock0
    80001ffe:	05250663          	beq	a0,s2,8000204a <sleep+0x68>
    acquire(&p->lock);  //DOC: sleeplock1
    80002002:	fffff097          	auipc	ra,0xfffff
    80002006:	acc080e7          	jalr	-1332(ra) # 80000ace <acquire>
    release(lk);
    8000200a:	854a                	mv	a0,s2
    8000200c:	fffff097          	auipc	ra,0xfffff
    80002010:	b16080e7          	jalr	-1258(ra) # 80000b22 <release>
  p->chan = chan;
    80002014:	0334b423          	sd	s3,40(s1)
  p->state = SLEEPING;
    80002018:	4785                	li	a5,1
    8000201a:	cc9c                	sw	a5,24(s1)
  sched();
    8000201c:	00000097          	auipc	ra,0x0
    80002020:	daa080e7          	jalr	-598(ra) # 80001dc6 <sched>
  p->chan = 0;
    80002024:	0204b423          	sd	zero,40(s1)
    release(&p->lock);
    80002028:	8526                	mv	a0,s1
    8000202a:	fffff097          	auipc	ra,0xfffff
    8000202e:	af8080e7          	jalr	-1288(ra) # 80000b22 <release>
    acquire(lk);
    80002032:	854a                	mv	a0,s2
    80002034:	fffff097          	auipc	ra,0xfffff
    80002038:	a9a080e7          	jalr	-1382(ra) # 80000ace <acquire>
}
    8000203c:	70a2                	ld	ra,40(sp)
    8000203e:	7402                	ld	s0,32(sp)
    80002040:	64e2                	ld	s1,24(sp)
    80002042:	6942                	ld	s2,16(sp)
    80002044:	69a2                	ld	s3,8(sp)
    80002046:	6145                	addi	sp,sp,48
    80002048:	8082                	ret
  p->chan = chan;
    8000204a:	03353423          	sd	s3,40(a0)
  p->state = SLEEPING;
    8000204e:	4785                	li	a5,1
    80002050:	cd1c                	sw	a5,24(a0)
  sched();
    80002052:	00000097          	auipc	ra,0x0
    80002056:	d74080e7          	jalr	-652(ra) # 80001dc6 <sched>
  p->chan = 0;
    8000205a:	0204b423          	sd	zero,40(s1)
  if(lk != &p->lock){
    8000205e:	bff9                	j	8000203c <sleep+0x5a>

0000000080002060 <wait>:
{
    80002060:	715d                	addi	sp,sp,-80
    80002062:	e486                	sd	ra,72(sp)
    80002064:	e0a2                	sd	s0,64(sp)
    80002066:	fc26                	sd	s1,56(sp)
    80002068:	f84a                	sd	s2,48(sp)
    8000206a:	f44e                	sd	s3,40(sp)
    8000206c:	f052                	sd	s4,32(sp)
    8000206e:	ec56                	sd	s5,24(sp)
    80002070:	e85a                	sd	s6,16(sp)
    80002072:	e45e                	sd	s7,8(sp)
    80002074:	e062                	sd	s8,0(sp)
    80002076:	0880                	addi	s0,sp,80
    80002078:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000207a:	fffff097          	auipc	ra,0xfffff
    8000207e:	7c6080e7          	jalr	1990(ra) # 80001840 <myproc>
    80002082:	892a                	mv	s2,a0
  acquire(&p->lock);
    80002084:	8c2a                	mv	s8,a0
    80002086:	fffff097          	auipc	ra,0xfffff
    8000208a:	a48080e7          	jalr	-1464(ra) # 80000ace <acquire>
    havekids = 0;
    8000208e:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    80002090:	4a11                	li	s4,4
    for(np = proc; np < &proc[NPROC]; np++){
    80002092:	00015997          	auipc	s3,0x15
    80002096:	66e98993          	addi	s3,s3,1646 # 80017700 <tickslock>
        havekids = 1;
    8000209a:	4a85                	li	s5,1
    havekids = 0;
    8000209c:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    8000209e:	00010497          	auipc	s1,0x10
    800020a2:	c6248493          	addi	s1,s1,-926 # 80011d00 <proc>
    800020a6:	a08d                	j	80002108 <wait+0xa8>
          pid = np->pid;
    800020a8:	0384a983          	lw	s3,56(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800020ac:	000b0e63          	beqz	s6,800020c8 <wait+0x68>
    800020b0:	4691                	li	a3,4
    800020b2:	03448613          	addi	a2,s1,52
    800020b6:	85da                	mv	a1,s6
    800020b8:	05093503          	ld	a0,80(s2)
    800020bc:	fffff097          	auipc	ra,0xfffff
    800020c0:	478080e7          	jalr	1144(ra) # 80001534 <copyout>
    800020c4:	02054263          	bltz	a0,800020e8 <wait+0x88>
          freeproc(np);
    800020c8:	8526                	mv	a0,s1
    800020ca:	00000097          	auipc	ra,0x0
    800020ce:	992080e7          	jalr	-1646(ra) # 80001a5c <freeproc>
          release(&np->lock);
    800020d2:	8526                	mv	a0,s1
    800020d4:	fffff097          	auipc	ra,0xfffff
    800020d8:	a4e080e7          	jalr	-1458(ra) # 80000b22 <release>
          release(&p->lock);
    800020dc:	854a                	mv	a0,s2
    800020de:	fffff097          	auipc	ra,0xfffff
    800020e2:	a44080e7          	jalr	-1468(ra) # 80000b22 <release>
          return pid;
    800020e6:	a8a9                	j	80002140 <wait+0xe0>
            release(&np->lock);
    800020e8:	8526                	mv	a0,s1
    800020ea:	fffff097          	auipc	ra,0xfffff
    800020ee:	a38080e7          	jalr	-1480(ra) # 80000b22 <release>
            release(&p->lock);
    800020f2:	854a                	mv	a0,s2
    800020f4:	fffff097          	auipc	ra,0xfffff
    800020f8:	a2e080e7          	jalr	-1490(ra) # 80000b22 <release>
            return -1;
    800020fc:	59fd                	li	s3,-1
    800020fe:	a089                	j	80002140 <wait+0xe0>
    for(np = proc; np < &proc[NPROC]; np++){
    80002100:	16848493          	addi	s1,s1,360
    80002104:	03348463          	beq	s1,s3,8000212c <wait+0xcc>
      if(np->parent == p){
    80002108:	709c                	ld	a5,32(s1)
    8000210a:	ff279be3          	bne	a5,s2,80002100 <wait+0xa0>
        acquire(&np->lock);
    8000210e:	8526                	mv	a0,s1
    80002110:	fffff097          	auipc	ra,0xfffff
    80002114:	9be080e7          	jalr	-1602(ra) # 80000ace <acquire>
        if(np->state == ZOMBIE){
    80002118:	4c9c                	lw	a5,24(s1)
    8000211a:	f94787e3          	beq	a5,s4,800020a8 <wait+0x48>
        release(&np->lock);
    8000211e:	8526                	mv	a0,s1
    80002120:	fffff097          	auipc	ra,0xfffff
    80002124:	a02080e7          	jalr	-1534(ra) # 80000b22 <release>
        havekids = 1;
    80002128:	8756                	mv	a4,s5
    8000212a:	bfd9                	j	80002100 <wait+0xa0>
    if(!havekids || p->killed){
    8000212c:	c701                	beqz	a4,80002134 <wait+0xd4>
    8000212e:	03092783          	lw	a5,48(s2)
    80002132:	c785                	beqz	a5,8000215a <wait+0xfa>
      release(&p->lock);
    80002134:	854a                	mv	a0,s2
    80002136:	fffff097          	auipc	ra,0xfffff
    8000213a:	9ec080e7          	jalr	-1556(ra) # 80000b22 <release>
      return -1;
    8000213e:	59fd                	li	s3,-1
}
    80002140:	854e                	mv	a0,s3
    80002142:	60a6                	ld	ra,72(sp)
    80002144:	6406                	ld	s0,64(sp)
    80002146:	74e2                	ld	s1,56(sp)
    80002148:	7942                	ld	s2,48(sp)
    8000214a:	79a2                	ld	s3,40(sp)
    8000214c:	7a02                	ld	s4,32(sp)
    8000214e:	6ae2                	ld	s5,24(sp)
    80002150:	6b42                	ld	s6,16(sp)
    80002152:	6ba2                	ld	s7,8(sp)
    80002154:	6c02                	ld	s8,0(sp)
    80002156:	6161                	addi	sp,sp,80
    80002158:	8082                	ret
    sleep(p, &p->lock);  //DOC: wait-sleep
    8000215a:	85e2                	mv	a1,s8
    8000215c:	854a                	mv	a0,s2
    8000215e:	00000097          	auipc	ra,0x0
    80002162:	e84080e7          	jalr	-380(ra) # 80001fe2 <sleep>
    havekids = 0;
    80002166:	bf1d                	j	8000209c <wait+0x3c>

0000000080002168 <wakeup>:
{
    80002168:	7139                	addi	sp,sp,-64
    8000216a:	fc06                	sd	ra,56(sp)
    8000216c:	f822                	sd	s0,48(sp)
    8000216e:	f426                	sd	s1,40(sp)
    80002170:	f04a                	sd	s2,32(sp)
    80002172:	ec4e                	sd	s3,24(sp)
    80002174:	e852                	sd	s4,16(sp)
    80002176:	e456                	sd	s5,8(sp)
    80002178:	0080                	addi	s0,sp,64
    8000217a:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    8000217c:	00010497          	auipc	s1,0x10
    80002180:	b8448493          	addi	s1,s1,-1148 # 80011d00 <proc>
    if(p->state == SLEEPING && p->chan == chan) {
    80002184:	4985                	li	s3,1
      p->state = RUNNABLE;
    80002186:	4a89                	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++) {
    80002188:	00015917          	auipc	s2,0x15
    8000218c:	57890913          	addi	s2,s2,1400 # 80017700 <tickslock>
    80002190:	a821                	j	800021a8 <wakeup+0x40>
      p->state = RUNNABLE;
    80002192:	0154ac23          	sw	s5,24(s1)
    release(&p->lock);
    80002196:	8526                	mv	a0,s1
    80002198:	fffff097          	auipc	ra,0xfffff
    8000219c:	98a080e7          	jalr	-1654(ra) # 80000b22 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800021a0:	16848493          	addi	s1,s1,360
    800021a4:	01248e63          	beq	s1,s2,800021c0 <wakeup+0x58>
    acquire(&p->lock);
    800021a8:	8526                	mv	a0,s1
    800021aa:	fffff097          	auipc	ra,0xfffff
    800021ae:	924080e7          	jalr	-1756(ra) # 80000ace <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    800021b2:	4c9c                	lw	a5,24(s1)
    800021b4:	ff3791e3          	bne	a5,s3,80002196 <wakeup+0x2e>
    800021b8:	749c                	ld	a5,40(s1)
    800021ba:	fd479ee3          	bne	a5,s4,80002196 <wakeup+0x2e>
    800021be:	bfd1                	j	80002192 <wakeup+0x2a>
}
    800021c0:	70e2                	ld	ra,56(sp)
    800021c2:	7442                	ld	s0,48(sp)
    800021c4:	74a2                	ld	s1,40(sp)
    800021c6:	7902                	ld	s2,32(sp)
    800021c8:	69e2                	ld	s3,24(sp)
    800021ca:	6a42                	ld	s4,16(sp)
    800021cc:	6aa2                	ld	s5,8(sp)
    800021ce:	6121                	addi	sp,sp,64
    800021d0:	8082                	ret

00000000800021d2 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800021d2:	7179                	addi	sp,sp,-48
    800021d4:	f406                	sd	ra,40(sp)
    800021d6:	f022                	sd	s0,32(sp)
    800021d8:	ec26                	sd	s1,24(sp)
    800021da:	e84a                	sd	s2,16(sp)
    800021dc:	e44e                	sd	s3,8(sp)
    800021de:	1800                	addi	s0,sp,48
    800021e0:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800021e2:	00010497          	auipc	s1,0x10
    800021e6:	b1e48493          	addi	s1,s1,-1250 # 80011d00 <proc>
    800021ea:	00015997          	auipc	s3,0x15
    800021ee:	51698993          	addi	s3,s3,1302 # 80017700 <tickslock>
    acquire(&p->lock);
    800021f2:	8526                	mv	a0,s1
    800021f4:	fffff097          	auipc	ra,0xfffff
    800021f8:	8da080e7          	jalr	-1830(ra) # 80000ace <acquire>
    if(p->pid == pid){
    800021fc:	5c9c                	lw	a5,56(s1)
    800021fe:	01278d63          	beq	a5,s2,80002218 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002202:	8526                	mv	a0,s1
    80002204:	fffff097          	auipc	ra,0xfffff
    80002208:	91e080e7          	jalr	-1762(ra) # 80000b22 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    8000220c:	16848493          	addi	s1,s1,360
    80002210:	ff3491e3          	bne	s1,s3,800021f2 <kill+0x20>
  }
  return -1;
    80002214:	557d                	li	a0,-1
    80002216:	a821                	j	8000222e <kill+0x5c>
      p->killed = 1;
    80002218:	4785                	li	a5,1
    8000221a:	d89c                	sw	a5,48(s1)
      if(p->state == SLEEPING){
    8000221c:	4c98                	lw	a4,24(s1)
    8000221e:	00f70f63          	beq	a4,a5,8000223c <kill+0x6a>
      release(&p->lock);
    80002222:	8526                	mv	a0,s1
    80002224:	fffff097          	auipc	ra,0xfffff
    80002228:	8fe080e7          	jalr	-1794(ra) # 80000b22 <release>
      return 0;
    8000222c:	4501                	li	a0,0
}
    8000222e:	70a2                	ld	ra,40(sp)
    80002230:	7402                	ld	s0,32(sp)
    80002232:	64e2                	ld	s1,24(sp)
    80002234:	6942                	ld	s2,16(sp)
    80002236:	69a2                	ld	s3,8(sp)
    80002238:	6145                	addi	sp,sp,48
    8000223a:	8082                	ret
        p->state = RUNNABLE;
    8000223c:	4789                	li	a5,2
    8000223e:	cc9c                	sw	a5,24(s1)
    80002240:	b7cd                	j	80002222 <kill+0x50>

0000000080002242 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002242:	7179                	addi	sp,sp,-48
    80002244:	f406                	sd	ra,40(sp)
    80002246:	f022                	sd	s0,32(sp)
    80002248:	ec26                	sd	s1,24(sp)
    8000224a:	e84a                	sd	s2,16(sp)
    8000224c:	e44e                	sd	s3,8(sp)
    8000224e:	e052                	sd	s4,0(sp)
    80002250:	1800                	addi	s0,sp,48
    80002252:	84aa                	mv	s1,a0
    80002254:	892e                	mv	s2,a1
    80002256:	89b2                	mv	s3,a2
    80002258:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000225a:	fffff097          	auipc	ra,0xfffff
    8000225e:	5e6080e7          	jalr	1510(ra) # 80001840 <myproc>
  if(user_dst){
    80002262:	c08d                	beqz	s1,80002284 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002264:	86d2                	mv	a3,s4
    80002266:	864e                	mv	a2,s3
    80002268:	85ca                	mv	a1,s2
    8000226a:	6928                	ld	a0,80(a0)
    8000226c:	fffff097          	auipc	ra,0xfffff
    80002270:	2c8080e7          	jalr	712(ra) # 80001534 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002274:	70a2                	ld	ra,40(sp)
    80002276:	7402                	ld	s0,32(sp)
    80002278:	64e2                	ld	s1,24(sp)
    8000227a:	6942                	ld	s2,16(sp)
    8000227c:	69a2                	ld	s3,8(sp)
    8000227e:	6a02                	ld	s4,0(sp)
    80002280:	6145                	addi	sp,sp,48
    80002282:	8082                	ret
    memmove((char *)dst, src, len);
    80002284:	000a061b          	sext.w	a2,s4
    80002288:	85ce                	mv	a1,s3
    8000228a:	854a                	mv	a0,s2
    8000228c:	fffff097          	auipc	ra,0xfffff
    80002290:	93e080e7          	jalr	-1730(ra) # 80000bca <memmove>
    return 0;
    80002294:	8526                	mv	a0,s1
    80002296:	bff9                	j	80002274 <either_copyout+0x32>

0000000080002298 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002298:	7179                	addi	sp,sp,-48
    8000229a:	f406                	sd	ra,40(sp)
    8000229c:	f022                	sd	s0,32(sp)
    8000229e:	ec26                	sd	s1,24(sp)
    800022a0:	e84a                	sd	s2,16(sp)
    800022a2:	e44e                	sd	s3,8(sp)
    800022a4:	e052                	sd	s4,0(sp)
    800022a6:	1800                	addi	s0,sp,48
    800022a8:	892a                	mv	s2,a0
    800022aa:	84ae                	mv	s1,a1
    800022ac:	89b2                	mv	s3,a2
    800022ae:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800022b0:	fffff097          	auipc	ra,0xfffff
    800022b4:	590080e7          	jalr	1424(ra) # 80001840 <myproc>
  if(user_src){
    800022b8:	c08d                	beqz	s1,800022da <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800022ba:	86d2                	mv	a3,s4
    800022bc:	864e                	mv	a2,s3
    800022be:	85ca                	mv	a1,s2
    800022c0:	6928                	ld	a0,80(a0)
    800022c2:	fffff097          	auipc	ra,0xfffff
    800022c6:	2fe080e7          	jalr	766(ra) # 800015c0 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800022ca:	70a2                	ld	ra,40(sp)
    800022cc:	7402                	ld	s0,32(sp)
    800022ce:	64e2                	ld	s1,24(sp)
    800022d0:	6942                	ld	s2,16(sp)
    800022d2:	69a2                	ld	s3,8(sp)
    800022d4:	6a02                	ld	s4,0(sp)
    800022d6:	6145                	addi	sp,sp,48
    800022d8:	8082                	ret
    memmove(dst, (char*)src, len);
    800022da:	000a061b          	sext.w	a2,s4
    800022de:	85ce                	mv	a1,s3
    800022e0:	854a                	mv	a0,s2
    800022e2:	fffff097          	auipc	ra,0xfffff
    800022e6:	8e8080e7          	jalr	-1816(ra) # 80000bca <memmove>
    return 0;
    800022ea:	8526                	mv	a0,s1
    800022ec:	bff9                	j	800022ca <either_copyin+0x32>

00000000800022ee <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800022ee:	715d                	addi	sp,sp,-80
    800022f0:	e486                	sd	ra,72(sp)
    800022f2:	e0a2                	sd	s0,64(sp)
    800022f4:	fc26                	sd	s1,56(sp)
    800022f6:	f84a                	sd	s2,48(sp)
    800022f8:	f44e                	sd	s3,40(sp)
    800022fa:	f052                	sd	s4,32(sp)
    800022fc:	ec56                	sd	s5,24(sp)
    800022fe:	e85a                	sd	s6,16(sp)
    80002300:	e45e                	sd	s7,8(sp)
    80002302:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002304:	00005517          	auipc	a0,0x5
    80002308:	eac50513          	addi	a0,a0,-340 # 800071b0 <userret+0x120>
    8000230c:	ffffe097          	auipc	ra,0xffffe
    80002310:	28c080e7          	jalr	652(ra) # 80000598 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002314:	00010497          	auipc	s1,0x10
    80002318:	b4448493          	addi	s1,s1,-1212 # 80011e58 <proc+0x158>
    8000231c:	00015917          	auipc	s2,0x15
    80002320:	53c90913          	addi	s2,s2,1340 # 80017858 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002324:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    80002326:	00005997          	auipc	s3,0x5
    8000232a:	04298993          	addi	s3,s3,66 # 80007368 <userret+0x2d8>
    printf("%d %s %s", p->pid, state, p->name);
    8000232e:	00005a97          	auipc	s5,0x5
    80002332:	042a8a93          	addi	s5,s5,66 # 80007370 <userret+0x2e0>
    printf("\n");
    80002336:	00005a17          	auipc	s4,0x5
    8000233a:	e7aa0a13          	addi	s4,s4,-390 # 800071b0 <userret+0x120>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000233e:	00005b97          	auipc	s7,0x5
    80002342:	4eab8b93          	addi	s7,s7,1258 # 80007828 <states.1693>
    80002346:	a00d                	j	80002368 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002348:	ee06a583          	lw	a1,-288(a3)
    8000234c:	8556                	mv	a0,s5
    8000234e:	ffffe097          	auipc	ra,0xffffe
    80002352:	24a080e7          	jalr	586(ra) # 80000598 <printf>
    printf("\n");
    80002356:	8552                	mv	a0,s4
    80002358:	ffffe097          	auipc	ra,0xffffe
    8000235c:	240080e7          	jalr	576(ra) # 80000598 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002360:	16848493          	addi	s1,s1,360
    80002364:	03248163          	beq	s1,s2,80002386 <procdump+0x98>
    if(p->state == UNUSED)
    80002368:	86a6                	mv	a3,s1
    8000236a:	ec04a783          	lw	a5,-320(s1)
    8000236e:	dbed                	beqz	a5,80002360 <procdump+0x72>
      state = "???";
    80002370:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002372:	fcfb6be3          	bltu	s6,a5,80002348 <procdump+0x5a>
    80002376:	1782                	slli	a5,a5,0x20
    80002378:	9381                	srli	a5,a5,0x20
    8000237a:	078e                	slli	a5,a5,0x3
    8000237c:	97de                	add	a5,a5,s7
    8000237e:	6390                	ld	a2,0(a5)
    80002380:	f661                	bnez	a2,80002348 <procdump+0x5a>
      state = "???";
    80002382:	864e                	mv	a2,s3
    80002384:	b7d1                	j	80002348 <procdump+0x5a>
  }
}
    80002386:	60a6                	ld	ra,72(sp)
    80002388:	6406                	ld	s0,64(sp)
    8000238a:	74e2                	ld	s1,56(sp)
    8000238c:	7942                	ld	s2,48(sp)
    8000238e:	79a2                	ld	s3,40(sp)
    80002390:	7a02                	ld	s4,32(sp)
    80002392:	6ae2                	ld	s5,24(sp)
    80002394:	6b42                	ld	s6,16(sp)
    80002396:	6ba2                	ld	s7,8(sp)
    80002398:	6161                	addi	sp,sp,80
    8000239a:	8082                	ret

000000008000239c <swtch>:
    8000239c:	00153023          	sd	ra,0(a0)
    800023a0:	00253423          	sd	sp,8(a0)
    800023a4:	e900                	sd	s0,16(a0)
    800023a6:	ed04                	sd	s1,24(a0)
    800023a8:	03253023          	sd	s2,32(a0)
    800023ac:	03353423          	sd	s3,40(a0)
    800023b0:	03453823          	sd	s4,48(a0)
    800023b4:	03553c23          	sd	s5,56(a0)
    800023b8:	05653023          	sd	s6,64(a0)
    800023bc:	05753423          	sd	s7,72(a0)
    800023c0:	05853823          	sd	s8,80(a0)
    800023c4:	05953c23          	sd	s9,88(a0)
    800023c8:	07a53023          	sd	s10,96(a0)
    800023cc:	07b53423          	sd	s11,104(a0)
    800023d0:	0005b083          	ld	ra,0(a1)
    800023d4:	0085b103          	ld	sp,8(a1)
    800023d8:	6980                	ld	s0,16(a1)
    800023da:	6d84                	ld	s1,24(a1)
    800023dc:	0205b903          	ld	s2,32(a1)
    800023e0:	0285b983          	ld	s3,40(a1)
    800023e4:	0305ba03          	ld	s4,48(a1)
    800023e8:	0385ba83          	ld	s5,56(a1)
    800023ec:	0405bb03          	ld	s6,64(a1)
    800023f0:	0485bb83          	ld	s7,72(a1)
    800023f4:	0505bc03          	ld	s8,80(a1)
    800023f8:	0585bc83          	ld	s9,88(a1)
    800023fc:	0605bd03          	ld	s10,96(a1)
    80002400:	0685bd83          	ld	s11,104(a1)
    80002404:	8082                	ret

0000000080002406 <setTickInterval>:
void kernelvec();

extern int devintr();


void setTickInterval(int interval){
    80002406:	1141                	addi	sp,sp,-16
    80002408:	e422                	sd	s0,8(sp)
    8000240a:	0800                	addi	s0,sp,16
    uint64  *scratch = &mscratch0[0];
    scratch[5] = interval;
    8000240c:	00007797          	auipc	a5,0x7
    80002410:	c0a7be23          	sd	a0,-996(a5) # 80009028 <mscratch0+0x28>
}
    80002414:	6422                	ld	s0,8(sp)
    80002416:	0141                	addi	sp,sp,16
    80002418:	8082                	ret

000000008000241a <trapinit>:

void
trapinit(void)
{
    8000241a:	1141                	addi	sp,sp,-16
    8000241c:	e406                	sd	ra,8(sp)
    8000241e:	e022                	sd	s0,0(sp)
    80002420:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002422:	00005597          	auipc	a1,0x5
    80002426:	f8658593          	addi	a1,a1,-122 # 800073a8 <userret+0x318>
    8000242a:	00015517          	auipc	a0,0x15
    8000242e:	2d650513          	addi	a0,a0,726 # 80017700 <tickslock>
    80002432:	ffffe097          	auipc	ra,0xffffe
    80002436:	58a080e7          	jalr	1418(ra) # 800009bc <initlock>
}
    8000243a:	60a2                	ld	ra,8(sp)
    8000243c:	6402                	ld	s0,0(sp)
    8000243e:	0141                	addi	sp,sp,16
    80002440:	8082                	ret

0000000080002442 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002442:	1141                	addi	sp,sp,-16
    80002444:	e422                	sd	s0,8(sp)
    80002446:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002448:	00003797          	auipc	a5,0x3
    8000244c:	5a878793          	addi	a5,a5,1448 # 800059f0 <kernelvec>
    80002450:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002454:	6422                	ld	s0,8(sp)
    80002456:	0141                	addi	sp,sp,16
    80002458:	8082                	ret

000000008000245a <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    8000245a:	1141                	addi	sp,sp,-16
    8000245c:	e406                	sd	ra,8(sp)
    8000245e:	e022                	sd	s0,0(sp)
    80002460:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002462:	fffff097          	auipc	ra,0xfffff
    80002466:	3de080e7          	jalr	990(ra) # 80001840 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000246a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000246e:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002470:	10079073          	csrw	sstatus,a5
  // turn off interrupts, since we're switching
  // now from kerneltrap() to usertrap().
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002474:	00005617          	auipc	a2,0x5
    80002478:	b8c60613          	addi	a2,a2,-1140 # 80007000 <trampoline>
    8000247c:	00005697          	auipc	a3,0x5
    80002480:	b8468693          	addi	a3,a3,-1148 # 80007000 <trampoline>
    80002484:	8e91                	sub	a3,a3,a2
    80002486:	040007b7          	lui	a5,0x4000
    8000248a:	17fd                	addi	a5,a5,-1
    8000248c:	07b2                	slli	a5,a5,0xc
    8000248e:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002490:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->tf->kernel_satp = r_satp();         // kernel page table
    80002494:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002496:	180026f3          	csrr	a3,satp
    8000249a:	e314                	sd	a3,0(a4)
  p->tf->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    8000249c:	6d38                	ld	a4,88(a0)
    8000249e:	6134                	ld	a3,64(a0)
    800024a0:	6585                	lui	a1,0x1
    800024a2:	96ae                	add	a3,a3,a1
    800024a4:	e714                	sd	a3,8(a4)
  p->tf->kernel_trap = (uint64)usertrap;
    800024a6:	6d38                	ld	a4,88(a0)
    800024a8:	00000697          	auipc	a3,0x0
    800024ac:	14a68693          	addi	a3,a3,330 # 800025f2 <usertrap>
    800024b0:	eb14                	sd	a3,16(a4)
  p->tf->kernel_hartid = r_tp();         // hartid for cpuid()
    800024b2:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800024b4:	8692                	mv	a3,tp
    800024b6:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800024b8:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800024bc:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800024c0:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800024c4:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->tf->epc);
    800024c8:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800024ca:	6f18                	ld	a4,24(a4)
    800024cc:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800024d0:	692c                	ld	a1,80(a0)
    800024d2:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800024d4:	00005717          	auipc	a4,0x5
    800024d8:	bbc70713          	addi	a4,a4,-1092 # 80007090 <userret>
    800024dc:	8f11                	sub	a4,a4,a2
    800024de:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    800024e0:	577d                	li	a4,-1
    800024e2:	177e                	slli	a4,a4,0x3f
    800024e4:	8dd9                	or	a1,a1,a4
    800024e6:	02000537          	lui	a0,0x2000
    800024ea:	157d                	addi	a0,a0,-1
    800024ec:	0536                	slli	a0,a0,0xd
    800024ee:	9782                	jalr	a5
}
    800024f0:	60a2                	ld	ra,8(sp)
    800024f2:	6402                	ld	s0,0(sp)
    800024f4:	0141                	addi	sp,sp,16
    800024f6:	8082                	ret

00000000800024f8 <clockintr>:
}


void
clockintr()
{
    800024f8:	1101                	addi	sp,sp,-32
    800024fa:	ec06                	sd	ra,24(sp)
    800024fc:	e822                	sd	s0,16(sp)
    800024fe:	e426                	sd	s1,8(sp)
    80002500:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002502:	00015497          	auipc	s1,0x15
    80002506:	1fe48493          	addi	s1,s1,510 # 80017700 <tickslock>
    8000250a:	8526                	mv	a0,s1
    8000250c:	ffffe097          	auipc	ra,0xffffe
    80002510:	5c2080e7          	jalr	1474(ra) # 80000ace <acquire>

  cur_time = *(uint64*)CLINT_MTIME;
    80002514:	0200c7b7          	lui	a5,0x200c
    80002518:	ff87b783          	ld	a5,-8(a5) # 200bff8 <_entry-0x7dff4008>
    8000251c:	00024717          	auipc	a4,0x24
    80002520:	b0f73223          	sd	a5,-1276(a4) # 80026020 <cur_time>
  duration = cur_time - prev_time;
    80002524:	00024697          	auipc	a3,0x24
    80002528:	b0468693          	addi	a3,a3,-1276 # 80026028 <prev_time>
    8000252c:	6298                	ld	a4,0(a3)
    8000252e:	40e78733          	sub	a4,a5,a4
    80002532:	00024617          	auipc	a2,0x24
    80002536:	aee63323          	sd	a4,-1306(a2) # 80026018 <duration>
  ticks++;
    8000253a:	00024517          	auipc	a0,0x24
    8000253e:	af650513          	addi	a0,a0,-1290 # 80026030 <ticks>
    80002542:	4118                	lw	a4,0(a0)
    80002544:	2705                	addiw	a4,a4,1
    80002546:	c118                	sw	a4,0(a0)
  prev_time = cur_time;
    80002548:	e29c                	sd	a5,0(a3)
  wakeup(&ticks);
    8000254a:	00000097          	auipc	ra,0x0
    8000254e:	c1e080e7          	jalr	-994(ra) # 80002168 <wakeup>
  release(&tickslock);
    80002552:	8526                	mv	a0,s1
    80002554:	ffffe097          	auipc	ra,0xffffe
    80002558:	5ce080e7          	jalr	1486(ra) # 80000b22 <release>
}
    8000255c:	60e2                	ld	ra,24(sp)
    8000255e:	6442                	ld	s0,16(sp)
    80002560:	64a2                	ld	s1,8(sp)
    80002562:	6105                	addi	sp,sp,32
    80002564:	8082                	ret

0000000080002566 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002566:	1101                	addi	sp,sp,-32
    80002568:	ec06                	sd	ra,24(sp)
    8000256a:	e822                	sd	s0,16(sp)
    8000256c:	e426                	sd	s1,8(sp)
    8000256e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002570:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002574:	00074d63          	bltz	a4,8000258e <devintr+0x28>
      virtio_disk_intr();
    }

    plic_complete(irq);
    return 1;
  } else if(scause == 0x8000000000000001L){
    80002578:	57fd                	li	a5,-1
    8000257a:	17fe                	slli	a5,a5,0x3f
    8000257c:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    8000257e:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002580:	04f70863          	beq	a4,a5,800025d0 <devintr+0x6a>
  }
}
    80002584:	60e2                	ld	ra,24(sp)
    80002586:	6442                	ld	s0,16(sp)
    80002588:	64a2                	ld	s1,8(sp)
    8000258a:	6105                	addi	sp,sp,32
    8000258c:	8082                	ret
     (scause & 0xff) == 9){
    8000258e:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002592:	46a5                	li	a3,9
    80002594:	fed792e3          	bne	a5,a3,80002578 <devintr+0x12>
    int irq = plic_claim();
    80002598:	00003097          	auipc	ra,0x3
    8000259c:	572080e7          	jalr	1394(ra) # 80005b0a <plic_claim>
    800025a0:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800025a2:	47a9                	li	a5,10
    800025a4:	00f50c63          	beq	a0,a5,800025bc <devintr+0x56>
    } else if(irq == VIRTIO0_IRQ){
    800025a8:	4785                	li	a5,1
    800025aa:	00f50e63          	beq	a0,a5,800025c6 <devintr+0x60>
    plic_complete(irq);
    800025ae:	8526                	mv	a0,s1
    800025b0:	00003097          	auipc	ra,0x3
    800025b4:	57e080e7          	jalr	1406(ra) # 80005b2e <plic_complete>
    return 1;
    800025b8:	4505                	li	a0,1
    800025ba:	b7e9                	j	80002584 <devintr+0x1e>
      uartintr();
    800025bc:	ffffe097          	auipc	ra,0xffffe
    800025c0:	278080e7          	jalr	632(ra) # 80000834 <uartintr>
    800025c4:	b7ed                	j	800025ae <devintr+0x48>
      virtio_disk_intr();
    800025c6:	00004097          	auipc	ra,0x4
    800025ca:	9f8080e7          	jalr	-1544(ra) # 80005fbe <virtio_disk_intr>
    800025ce:	b7c5                	j	800025ae <devintr+0x48>
    if(cpuid() == 0){
    800025d0:	fffff097          	auipc	ra,0xfffff
    800025d4:	244080e7          	jalr	580(ra) # 80001814 <cpuid>
    800025d8:	c901                	beqz	a0,800025e8 <devintr+0x82>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800025da:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800025de:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800025e0:	14479073          	csrw	sip,a5
    return 2;
    800025e4:	4509                	li	a0,2
    800025e6:	bf79                	j	80002584 <devintr+0x1e>
      clockintr();
    800025e8:	00000097          	auipc	ra,0x0
    800025ec:	f10080e7          	jalr	-240(ra) # 800024f8 <clockintr>
    800025f0:	b7ed                	j	800025da <devintr+0x74>

00000000800025f2 <usertrap>:
{
    800025f2:	1101                	addi	sp,sp,-32
    800025f4:	ec06                	sd	ra,24(sp)
    800025f6:	e822                	sd	s0,16(sp)
    800025f8:	e426                	sd	s1,8(sp)
    800025fa:	e04a                	sd	s2,0(sp)
    800025fc:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800025fe:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002602:	1007f793          	andi	a5,a5,256
    80002606:	e7bd                	bnez	a5,80002674 <usertrap+0x82>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002608:	00003797          	auipc	a5,0x3
    8000260c:	3e878793          	addi	a5,a5,1000 # 800059f0 <kernelvec>
    80002610:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002614:	fffff097          	auipc	ra,0xfffff
    80002618:	22c080e7          	jalr	556(ra) # 80001840 <myproc>
    8000261c:	84aa                	mv	s1,a0
  p->tf->epc = r_sepc();
    8000261e:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002620:	14102773          	csrr	a4,sepc
    80002624:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002626:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    8000262a:	47a1                	li	a5,8
    8000262c:	06f71263          	bne	a4,a5,80002690 <usertrap+0x9e>
    if(p->killed)
    80002630:	591c                	lw	a5,48(a0)
    80002632:	eba9                	bnez	a5,80002684 <usertrap+0x92>
    p->tf->epc += 4;
    80002634:	6cb8                	ld	a4,88(s1)
    80002636:	6f1c                	ld	a5,24(a4)
    80002638:	0791                	addi	a5,a5,4
    8000263a:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sie" : "=r" (x) );
    8000263c:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    80002640:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    80002644:	10479073          	csrw	sie,a5
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002648:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000264c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002650:	10079073          	csrw	sstatus,a5
    syscall();
    80002654:	00000097          	auipc	ra,0x0
    80002658:	40c080e7          	jalr	1036(ra) # 80002a60 <syscall>
  if(p->killed)
    8000265c:	589c                	lw	a5,48(s1)
    8000265e:	e7e9                	bnez	a5,80002728 <usertrap+0x136>
  usertrapret();
    80002660:	00000097          	auipc	ra,0x0
    80002664:	dfa080e7          	jalr	-518(ra) # 8000245a <usertrapret>
}
    80002668:	60e2                	ld	ra,24(sp)
    8000266a:	6442                	ld	s0,16(sp)
    8000266c:	64a2                	ld	s1,8(sp)
    8000266e:	6902                	ld	s2,0(sp)
    80002670:	6105                	addi	sp,sp,32
    80002672:	8082                	ret
    panic("usertrap: not from user mode");
    80002674:	00005517          	auipc	a0,0x5
    80002678:	d3c50513          	addi	a0,a0,-708 # 800073b0 <userret+0x320>
    8000267c:	ffffe097          	auipc	ra,0xffffe
    80002680:	ed2080e7          	jalr	-302(ra) # 8000054e <panic>
      exit(-1);
    80002684:	557d                	li	a0,-1
    80002686:	00000097          	auipc	ra,0x0
    8000268a:	816080e7          	jalr	-2026(ra) # 80001e9c <exit>
    8000268e:	b75d                	j	80002634 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002690:	00000097          	auipc	ra,0x0
    80002694:	ed6080e7          	jalr	-298(ra) # 80002566 <devintr>
    80002698:	892a                	mv	s2,a0
    8000269a:	c501                	beqz	a0,800026a2 <usertrap+0xb0>
  if(p->killed)
    8000269c:	589c                	lw	a5,48(s1)
    8000269e:	c3a1                	beqz	a5,800026de <usertrap+0xec>
    800026a0:	a815                	j	800026d4 <usertrap+0xe2>
  asm volatile("csrr %0, scause" : "=r" (x) );
    800026a2:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    800026a6:	5c90                	lw	a2,56(s1)
    800026a8:	00005517          	auipc	a0,0x5
    800026ac:	d2850513          	addi	a0,a0,-728 # 800073d0 <userret+0x340>
    800026b0:	ffffe097          	auipc	ra,0xffffe
    800026b4:	ee8080e7          	jalr	-280(ra) # 80000598 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800026b8:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800026bc:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    800026c0:	00005517          	auipc	a0,0x5
    800026c4:	d4050513          	addi	a0,a0,-704 # 80007400 <userret+0x370>
    800026c8:	ffffe097          	auipc	ra,0xffffe
    800026cc:	ed0080e7          	jalr	-304(ra) # 80000598 <printf>
    p->killed = 1;
    800026d0:	4785                	li	a5,1
    800026d2:	d89c                	sw	a5,48(s1)
    exit(-1);
    800026d4:	557d                	li	a0,-1
    800026d6:	fffff097          	auipc	ra,0xfffff
    800026da:	7c6080e7          	jalr	1990(ra) # 80001e9c <exit>
  if(which_dev == 2) {
    800026de:	4789                	li	a5,2
    800026e0:	f8f910e3          	bne	s2,a5,80002660 <usertrap+0x6e>
      yield();
    800026e4:	00000097          	auipc	ra,0x0
    800026e8:	8c2080e7          	jalr	-1854(ra) # 80001fa6 <yield>
      if(duration >= cur_interval - 2000000 ){
    800026ec:	00006717          	auipc	a4,0x6
    800026f0:	95473703          	ld	a4,-1708(a4) # 80008040 <cur_interval>
    800026f4:	ffe187b7          	lui	a5,0xffe18
    800026f8:	b8078793          	addi	a5,a5,-1152 # ffffffffffe17b80 <end+0xffffffff7fdf1b4c>
    800026fc:	97ba                	add	a5,a5,a4
    800026fe:	00024697          	auipc	a3,0x24
    80002702:	91a6b683          	ld	a3,-1766(a3) # 80026018 <duration>
    80002706:	02f6f363          	bgeu	a3,a5,8000272c <usertrap+0x13a>
          if(cur_interval <= MINIMUM_INTERVAL){
    8000270a:	000f47b7          	lui	a5,0xf4
    8000270e:	24078793          	addi	a5,a5,576 # f4240 <_entry-0x7ff0bdc0>
    80002712:	04e7ed63          	bltu	a5,a4,8000276c <usertrap+0x17a>
              cur_interval = MINIMUM_INTERVAL;
    80002716:	000f47b7          	lui	a5,0xf4
    8000271a:	24078793          	addi	a5,a5,576 # f4240 <_entry-0x7ff0bdc0>
    8000271e:	00006717          	auipc	a4,0x6
    80002722:	92f73123          	sd	a5,-1758(a4) # 80008040 <cur_interval>
      if(cur_interval >= MAXIMUM_INTERVAL) {
    80002726:	bf2d                	j	80002660 <usertrap+0x6e>
  int which_dev = 0;
    80002728:	4901                	li	s2,0
    8000272a:	b76d                	j	800026d4 <usertrap+0xe2>
          cur_interval = cur_interval + 100000;
    8000272c:	67e1                	lui	a5,0x18
    8000272e:	6a078793          	addi	a5,a5,1696 # 186a0 <_entry-0x7ffe7960>
    80002732:	973e                	add	a4,a4,a5
    80002734:	00006797          	auipc	a5,0x6
    80002738:	90e7b623          	sd	a4,-1780(a5) # 80008040 <cur_interval>
    scratch[5] = interval;
    8000273c:	2701                	sext.w	a4,a4
    8000273e:	00007797          	auipc	a5,0x7
    80002742:	8ee7b523          	sd	a4,-1814(a5) # 80009028 <mscratch0+0x28>
      if(cur_interval >= MAXIMUM_INTERVAL) {
    80002746:	00006717          	auipc	a4,0x6
    8000274a:	8fa73703          	ld	a4,-1798(a4) # 80008040 <cur_interval>
    8000274e:	009897b7          	lui	a5,0x989
    80002752:	67f78793          	addi	a5,a5,1663 # 98967f <_entry-0x7f676981>
    80002756:	f0e7f5e3          	bgeu	a5,a4,80002660 <usertrap+0x6e>
          cur_interval = MINIMUM_INTERVAL;
    8000275a:	000f47b7          	lui	a5,0xf4
    8000275e:	24078793          	addi	a5,a5,576 # f4240 <_entry-0x7ff0bdc0>
    80002762:	00006717          	auipc	a4,0x6
    80002766:	8cf73f23          	sd	a5,-1826(a4) # 80008040 <cur_interval>
    8000276a:	bddd                	j	80002660 <usertrap+0x6e>
              cur_interval = cur_interval - 100000;
    8000276c:	77a1                	lui	a5,0xfffe8
    8000276e:	96078793          	addi	a5,a5,-1696 # fffffffffffe7960 <end+0xffffffff7ffc192c>
    80002772:	973e                	add	a4,a4,a5
    80002774:	00006797          	auipc	a5,0x6
    80002778:	8ce7b623          	sd	a4,-1844(a5) # 80008040 <cur_interval>
    scratch[5] = interval;
    8000277c:	2701                	sext.w	a4,a4
    8000277e:	00007797          	auipc	a5,0x7
    80002782:	8ae7b523          	sd	a4,-1878(a5) # 80009028 <mscratch0+0x28>
}
    80002786:	b7c1                	j	80002746 <usertrap+0x154>

0000000080002788 <kerneltrap>:
{
    80002788:	7179                	addi	sp,sp,-48
    8000278a:	f406                	sd	ra,40(sp)
    8000278c:	f022                	sd	s0,32(sp)
    8000278e:	ec26                	sd	s1,24(sp)
    80002790:	e84a                	sd	s2,16(sp)
    80002792:	e44e                	sd	s3,8(sp)
    80002794:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002796:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000279a:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000279e:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    800027a2:	1004f793          	andi	a5,s1,256
    800027a6:	cb85                	beqz	a5,800027d6 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800027a8:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800027ac:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    800027ae:	ef85                	bnez	a5,800027e6 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    800027b0:	00000097          	auipc	ra,0x0
    800027b4:	db6080e7          	jalr	-586(ra) # 80002566 <devintr>
    800027b8:	cd1d                	beqz	a0,800027f6 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING) {
    800027ba:	4789                	li	a5,2
    800027bc:	06f50a63          	beq	a0,a5,80002830 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800027c0:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800027c4:	10049073          	csrw	sstatus,s1
}
    800027c8:	70a2                	ld	ra,40(sp)
    800027ca:	7402                	ld	s0,32(sp)
    800027cc:	64e2                	ld	s1,24(sp)
    800027ce:	6942                	ld	s2,16(sp)
    800027d0:	69a2                	ld	s3,8(sp)
    800027d2:	6145                	addi	sp,sp,48
    800027d4:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800027d6:	00005517          	auipc	a0,0x5
    800027da:	c4a50513          	addi	a0,a0,-950 # 80007420 <userret+0x390>
    800027de:	ffffe097          	auipc	ra,0xffffe
    800027e2:	d70080e7          	jalr	-656(ra) # 8000054e <panic>
    panic("kerneltrap: interrupts enabled");
    800027e6:	00005517          	auipc	a0,0x5
    800027ea:	c6250513          	addi	a0,a0,-926 # 80007448 <userret+0x3b8>
    800027ee:	ffffe097          	auipc	ra,0xffffe
    800027f2:	d60080e7          	jalr	-672(ra) # 8000054e <panic>
    printf("scause %p\n", scause);
    800027f6:	85ce                	mv	a1,s3
    800027f8:	00005517          	auipc	a0,0x5
    800027fc:	c7050513          	addi	a0,a0,-912 # 80007468 <userret+0x3d8>
    80002800:	ffffe097          	auipc	ra,0xffffe
    80002804:	d98080e7          	jalr	-616(ra) # 80000598 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002808:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000280c:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002810:	00005517          	auipc	a0,0x5
    80002814:	c6850513          	addi	a0,a0,-920 # 80007478 <userret+0x3e8>
    80002818:	ffffe097          	auipc	ra,0xffffe
    8000281c:	d80080e7          	jalr	-640(ra) # 80000598 <printf>
    panic("kerneltrap");
    80002820:	00005517          	auipc	a0,0x5
    80002824:	c7050513          	addi	a0,a0,-912 # 80007490 <userret+0x400>
    80002828:	ffffe097          	auipc	ra,0xffffe
    8000282c:	d26080e7          	jalr	-730(ra) # 8000054e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING) {
    80002830:	fffff097          	auipc	ra,0xfffff
    80002834:	010080e7          	jalr	16(ra) # 80001840 <myproc>
    80002838:	d541                	beqz	a0,800027c0 <kerneltrap+0x38>
    8000283a:	fffff097          	auipc	ra,0xfffff
    8000283e:	006080e7          	jalr	6(ra) # 80001840 <myproc>
    80002842:	4d18                	lw	a4,24(a0)
    80002844:	478d                	li	a5,3
    80002846:	f6f71de3          	bne	a4,a5,800027c0 <kerneltrap+0x38>
      yield();
    8000284a:	fffff097          	auipc	ra,0xfffff
    8000284e:	75c080e7          	jalr	1884(ra) # 80001fa6 <yield>
      if(duration >= cur_interval - 2000000 ){
    80002852:	00005717          	auipc	a4,0x5
    80002856:	7ee73703          	ld	a4,2030(a4) # 80008040 <cur_interval>
    8000285a:	ffe187b7          	lui	a5,0xffe18
    8000285e:	b8078793          	addi	a5,a5,-1152 # ffffffffffe17b80 <end+0xffffffff7fdf1b4c>
    80002862:	97ba                	add	a5,a5,a4
    80002864:	00023697          	auipc	a3,0x23
    80002868:	7b46b683          	ld	a3,1972(a3) # 80026018 <duration>
    8000286c:	02f6f163          	bgeu	a3,a5,8000288e <kerneltrap+0x106>
          if(cur_interval <= MINIMUM_INTERVAL){
    80002870:	000f47b7          	lui	a5,0xf4
    80002874:	24078793          	addi	a5,a5,576 # f4240 <_entry-0x7ff0bdc0>
    80002878:	04e7eb63          	bltu	a5,a4,800028ce <kerneltrap+0x146>
              cur_interval = MINIMUM_INTERVAL;
    8000287c:	000f47b7          	lui	a5,0xf4
    80002880:	24078793          	addi	a5,a5,576 # f4240 <_entry-0x7ff0bdc0>
    80002884:	00005717          	auipc	a4,0x5
    80002888:	7af73e23          	sd	a5,1980(a4) # 80008040 <cur_interval>
      if(cur_interval >= MAXIMUM_INTERVAL) {
    8000288c:	bf15                	j	800027c0 <kerneltrap+0x38>
          cur_interval = cur_interval + 100000;
    8000288e:	67e1                	lui	a5,0x18
    80002890:	6a078793          	addi	a5,a5,1696 # 186a0 <_entry-0x7ffe7960>
    80002894:	973e                	add	a4,a4,a5
    80002896:	00005797          	auipc	a5,0x5
    8000289a:	7ae7b523          	sd	a4,1962(a5) # 80008040 <cur_interval>
    scratch[5] = interval;
    8000289e:	2701                	sext.w	a4,a4
    800028a0:	00006797          	auipc	a5,0x6
    800028a4:	78e7b423          	sd	a4,1928(a5) # 80009028 <mscratch0+0x28>
      if(cur_interval >= MAXIMUM_INTERVAL) {
    800028a8:	00005717          	auipc	a4,0x5
    800028ac:	79873703          	ld	a4,1944(a4) # 80008040 <cur_interval>
    800028b0:	009897b7          	lui	a5,0x989
    800028b4:	67f78793          	addi	a5,a5,1663 # 98967f <_entry-0x7f676981>
    800028b8:	f0e7f4e3          	bgeu	a5,a4,800027c0 <kerneltrap+0x38>
          cur_interval = MINIMUM_INTERVAL;
    800028bc:	000f47b7          	lui	a5,0xf4
    800028c0:	24078793          	addi	a5,a5,576 # f4240 <_entry-0x7ff0bdc0>
    800028c4:	00005717          	auipc	a4,0x5
    800028c8:	76f73e23          	sd	a5,1916(a4) # 80008040 <cur_interval>
    800028cc:	bdd5                	j	800027c0 <kerneltrap+0x38>
              cur_interval = cur_interval - 100000;
    800028ce:	77a1                	lui	a5,0xfffe8
    800028d0:	96078793          	addi	a5,a5,-1696 # fffffffffffe7960 <end+0xffffffff7ffc192c>
    800028d4:	973e                	add	a4,a4,a5
    800028d6:	00005797          	auipc	a5,0x5
    800028da:	76e7b523          	sd	a4,1898(a5) # 80008040 <cur_interval>
    scratch[5] = interval;
    800028de:	2701                	sext.w	a4,a4
    800028e0:	00006797          	auipc	a5,0x6
    800028e4:	74e7b423          	sd	a4,1864(a5) # 80009028 <mscratch0+0x28>
}
    800028e8:	b7c1                	j	800028a8 <kerneltrap+0x120>

00000000800028ea <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    800028ea:	1101                	addi	sp,sp,-32
    800028ec:	ec06                	sd	ra,24(sp)
    800028ee:	e822                	sd	s0,16(sp)
    800028f0:	e426                	sd	s1,8(sp)
    800028f2:	1000                	addi	s0,sp,32
    800028f4:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800028f6:	fffff097          	auipc	ra,0xfffff
    800028fa:	f4a080e7          	jalr	-182(ra) # 80001840 <myproc>
  switch (n) {
    800028fe:	4795                	li	a5,5
    80002900:	0497e163          	bltu	a5,s1,80002942 <argraw+0x58>
    80002904:	048a                	slli	s1,s1,0x2
    80002906:	00005717          	auipc	a4,0x5
    8000290a:	f4a70713          	addi	a4,a4,-182 # 80007850 <states.1693+0x28>
    8000290e:	94ba                	add	s1,s1,a4
    80002910:	409c                	lw	a5,0(s1)
    80002912:	97ba                	add	a5,a5,a4
    80002914:	8782                	jr	a5
  case 0:
    return p->tf->a0;
    80002916:	6d3c                	ld	a5,88(a0)
    80002918:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->tf->a5;
  }
  panic("argraw");
  return -1;
}
    8000291a:	60e2                	ld	ra,24(sp)
    8000291c:	6442                	ld	s0,16(sp)
    8000291e:	64a2                	ld	s1,8(sp)
    80002920:	6105                	addi	sp,sp,32
    80002922:	8082                	ret
    return p->tf->a1;
    80002924:	6d3c                	ld	a5,88(a0)
    80002926:	7fa8                	ld	a0,120(a5)
    80002928:	bfcd                	j	8000291a <argraw+0x30>
    return p->tf->a2;
    8000292a:	6d3c                	ld	a5,88(a0)
    8000292c:	63c8                	ld	a0,128(a5)
    8000292e:	b7f5                	j	8000291a <argraw+0x30>
    return p->tf->a3;
    80002930:	6d3c                	ld	a5,88(a0)
    80002932:	67c8                	ld	a0,136(a5)
    80002934:	b7dd                	j	8000291a <argraw+0x30>
    return p->tf->a4;
    80002936:	6d3c                	ld	a5,88(a0)
    80002938:	6bc8                	ld	a0,144(a5)
    8000293a:	b7c5                	j	8000291a <argraw+0x30>
    return p->tf->a5;
    8000293c:	6d3c                	ld	a5,88(a0)
    8000293e:	6fc8                	ld	a0,152(a5)
    80002940:	bfe9                	j	8000291a <argraw+0x30>
  panic("argraw");
    80002942:	00005517          	auipc	a0,0x5
    80002946:	b5e50513          	addi	a0,a0,-1186 # 800074a0 <userret+0x410>
    8000294a:	ffffe097          	auipc	ra,0xffffe
    8000294e:	c04080e7          	jalr	-1020(ra) # 8000054e <panic>

0000000080002952 <fetchaddr>:
{
    80002952:	1101                	addi	sp,sp,-32
    80002954:	ec06                	sd	ra,24(sp)
    80002956:	e822                	sd	s0,16(sp)
    80002958:	e426                	sd	s1,8(sp)
    8000295a:	e04a                	sd	s2,0(sp)
    8000295c:	1000                	addi	s0,sp,32
    8000295e:	84aa                	mv	s1,a0
    80002960:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002962:	fffff097          	auipc	ra,0xfffff
    80002966:	ede080e7          	jalr	-290(ra) # 80001840 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    8000296a:	653c                	ld	a5,72(a0)
    8000296c:	02f4f863          	bgeu	s1,a5,8000299c <fetchaddr+0x4a>
    80002970:	00848713          	addi	a4,s1,8
    80002974:	02e7e663          	bltu	a5,a4,800029a0 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002978:	46a1                	li	a3,8
    8000297a:	8626                	mv	a2,s1
    8000297c:	85ca                	mv	a1,s2
    8000297e:	6928                	ld	a0,80(a0)
    80002980:	fffff097          	auipc	ra,0xfffff
    80002984:	c40080e7          	jalr	-960(ra) # 800015c0 <copyin>
    80002988:	00a03533          	snez	a0,a0
    8000298c:	40a00533          	neg	a0,a0
}
    80002990:	60e2                	ld	ra,24(sp)
    80002992:	6442                	ld	s0,16(sp)
    80002994:	64a2                	ld	s1,8(sp)
    80002996:	6902                	ld	s2,0(sp)
    80002998:	6105                	addi	sp,sp,32
    8000299a:	8082                	ret
    return -1;
    8000299c:	557d                	li	a0,-1
    8000299e:	bfcd                	j	80002990 <fetchaddr+0x3e>
    800029a0:	557d                	li	a0,-1
    800029a2:	b7fd                	j	80002990 <fetchaddr+0x3e>

00000000800029a4 <fetchstr>:
{
    800029a4:	7179                	addi	sp,sp,-48
    800029a6:	f406                	sd	ra,40(sp)
    800029a8:	f022                	sd	s0,32(sp)
    800029aa:	ec26                	sd	s1,24(sp)
    800029ac:	e84a                	sd	s2,16(sp)
    800029ae:	e44e                	sd	s3,8(sp)
    800029b0:	1800                	addi	s0,sp,48
    800029b2:	892a                	mv	s2,a0
    800029b4:	84ae                	mv	s1,a1
    800029b6:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    800029b8:	fffff097          	auipc	ra,0xfffff
    800029bc:	e88080e7          	jalr	-376(ra) # 80001840 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    800029c0:	86ce                	mv	a3,s3
    800029c2:	864a                	mv	a2,s2
    800029c4:	85a6                	mv	a1,s1
    800029c6:	6928                	ld	a0,80(a0)
    800029c8:	fffff097          	auipc	ra,0xfffff
    800029cc:	c84080e7          	jalr	-892(ra) # 8000164c <copyinstr>
  if(err < 0)
    800029d0:	00054763          	bltz	a0,800029de <fetchstr+0x3a>
  return strlen(buf);
    800029d4:	8526                	mv	a0,s1
    800029d6:	ffffe097          	auipc	ra,0xffffe
    800029da:	31c080e7          	jalr	796(ra) # 80000cf2 <strlen>
}
    800029de:	70a2                	ld	ra,40(sp)
    800029e0:	7402                	ld	s0,32(sp)
    800029e2:	64e2                	ld	s1,24(sp)
    800029e4:	6942                	ld	s2,16(sp)
    800029e6:	69a2                	ld	s3,8(sp)
    800029e8:	6145                	addi	sp,sp,48
    800029ea:	8082                	ret

00000000800029ec <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    800029ec:	1101                	addi	sp,sp,-32
    800029ee:	ec06                	sd	ra,24(sp)
    800029f0:	e822                	sd	s0,16(sp)
    800029f2:	e426                	sd	s1,8(sp)
    800029f4:	1000                	addi	s0,sp,32
    800029f6:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800029f8:	00000097          	auipc	ra,0x0
    800029fc:	ef2080e7          	jalr	-270(ra) # 800028ea <argraw>
    80002a00:	c088                	sw	a0,0(s1)
  return 0;
}
    80002a02:	4501                	li	a0,0
    80002a04:	60e2                	ld	ra,24(sp)
    80002a06:	6442                	ld	s0,16(sp)
    80002a08:	64a2                	ld	s1,8(sp)
    80002a0a:	6105                	addi	sp,sp,32
    80002a0c:	8082                	ret

0000000080002a0e <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002a0e:	1101                	addi	sp,sp,-32
    80002a10:	ec06                	sd	ra,24(sp)
    80002a12:	e822                	sd	s0,16(sp)
    80002a14:	e426                	sd	s1,8(sp)
    80002a16:	1000                	addi	s0,sp,32
    80002a18:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002a1a:	00000097          	auipc	ra,0x0
    80002a1e:	ed0080e7          	jalr	-304(ra) # 800028ea <argraw>
    80002a22:	e088                	sd	a0,0(s1)
  return 0;
}
    80002a24:	4501                	li	a0,0
    80002a26:	60e2                	ld	ra,24(sp)
    80002a28:	6442                	ld	s0,16(sp)
    80002a2a:	64a2                	ld	s1,8(sp)
    80002a2c:	6105                	addi	sp,sp,32
    80002a2e:	8082                	ret

0000000080002a30 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002a30:	1101                	addi	sp,sp,-32
    80002a32:	ec06                	sd	ra,24(sp)
    80002a34:	e822                	sd	s0,16(sp)
    80002a36:	e426                	sd	s1,8(sp)
    80002a38:	e04a                	sd	s2,0(sp)
    80002a3a:	1000                	addi	s0,sp,32
    80002a3c:	84ae                	mv	s1,a1
    80002a3e:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002a40:	00000097          	auipc	ra,0x0
    80002a44:	eaa080e7          	jalr	-342(ra) # 800028ea <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002a48:	864a                	mv	a2,s2
    80002a4a:	85a6                	mv	a1,s1
    80002a4c:	00000097          	auipc	ra,0x0
    80002a50:	f58080e7          	jalr	-168(ra) # 800029a4 <fetchstr>
}
    80002a54:	60e2                	ld	ra,24(sp)
    80002a56:	6442                	ld	s0,16(sp)
    80002a58:	64a2                	ld	s1,8(sp)
    80002a5a:	6902                	ld	s2,0(sp)
    80002a5c:	6105                	addi	sp,sp,32
    80002a5e:	8082                	ret

0000000080002a60 <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80002a60:	1101                	addi	sp,sp,-32
    80002a62:	ec06                	sd	ra,24(sp)
    80002a64:	e822                	sd	s0,16(sp)
    80002a66:	e426                	sd	s1,8(sp)
    80002a68:	e04a                	sd	s2,0(sp)
    80002a6a:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002a6c:	fffff097          	auipc	ra,0xfffff
    80002a70:	dd4080e7          	jalr	-556(ra) # 80001840 <myproc>
    80002a74:	84aa                	mv	s1,a0

  num = p->tf->a7;
    80002a76:	05853903          	ld	s2,88(a0)
    80002a7a:	0a893783          	ld	a5,168(s2)
    80002a7e:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002a82:	37fd                	addiw	a5,a5,-1
    80002a84:	4751                	li	a4,20
    80002a86:	00f76f63          	bltu	a4,a5,80002aa4 <syscall+0x44>
    80002a8a:	00369713          	slli	a4,a3,0x3
    80002a8e:	00005797          	auipc	a5,0x5
    80002a92:	dda78793          	addi	a5,a5,-550 # 80007868 <syscalls>
    80002a96:	97ba                	add	a5,a5,a4
    80002a98:	639c                	ld	a5,0(a5)
    80002a9a:	c789                	beqz	a5,80002aa4 <syscall+0x44>
    p->tf->a0 = syscalls[num]();
    80002a9c:	9782                	jalr	a5
    80002a9e:	06a93823          	sd	a0,112(s2)
    80002aa2:	a839                	j	80002ac0 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002aa4:	15848613          	addi	a2,s1,344
    80002aa8:	5c8c                	lw	a1,56(s1)
    80002aaa:	00005517          	auipc	a0,0x5
    80002aae:	9fe50513          	addi	a0,a0,-1538 # 800074a8 <userret+0x418>
    80002ab2:	ffffe097          	auipc	ra,0xffffe
    80002ab6:	ae6080e7          	jalr	-1306(ra) # 80000598 <printf>
            p->pid, p->name, num);
    p->tf->a0 = -1;
    80002aba:	6cbc                	ld	a5,88(s1)
    80002abc:	577d                	li	a4,-1
    80002abe:	fbb8                	sd	a4,112(a5)
  }
}
    80002ac0:	60e2                	ld	ra,24(sp)
    80002ac2:	6442                	ld	s0,16(sp)
    80002ac4:	64a2                	ld	s1,8(sp)
    80002ac6:	6902                	ld	s2,0(sp)
    80002ac8:	6105                	addi	sp,sp,32
    80002aca:	8082                	ret

0000000080002acc <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002acc:	1101                	addi	sp,sp,-32
    80002ace:	ec06                	sd	ra,24(sp)
    80002ad0:	e822                	sd	s0,16(sp)
    80002ad2:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002ad4:	fec40593          	addi	a1,s0,-20
    80002ad8:	4501                	li	a0,0
    80002ada:	00000097          	auipc	ra,0x0
    80002ade:	f12080e7          	jalr	-238(ra) # 800029ec <argint>
    return -1;
    80002ae2:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002ae4:	00054963          	bltz	a0,80002af6 <sys_exit+0x2a>
  exit(n);
    80002ae8:	fec42503          	lw	a0,-20(s0)
    80002aec:	fffff097          	auipc	ra,0xfffff
    80002af0:	3b0080e7          	jalr	944(ra) # 80001e9c <exit>
  return 0;  // not reached
    80002af4:	4781                	li	a5,0
}
    80002af6:	853e                	mv	a0,a5
    80002af8:	60e2                	ld	ra,24(sp)
    80002afa:	6442                	ld	s0,16(sp)
    80002afc:	6105                	addi	sp,sp,32
    80002afe:	8082                	ret

0000000080002b00 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002b00:	1141                	addi	sp,sp,-16
    80002b02:	e406                	sd	ra,8(sp)
    80002b04:	e022                	sd	s0,0(sp)
    80002b06:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002b08:	fffff097          	auipc	ra,0xfffff
    80002b0c:	d38080e7          	jalr	-712(ra) # 80001840 <myproc>
}
    80002b10:	5d08                	lw	a0,56(a0)
    80002b12:	60a2                	ld	ra,8(sp)
    80002b14:	6402                	ld	s0,0(sp)
    80002b16:	0141                	addi	sp,sp,16
    80002b18:	8082                	ret

0000000080002b1a <sys_fork>:

uint64
sys_fork(void)
{
    80002b1a:	1141                	addi	sp,sp,-16
    80002b1c:	e406                	sd	ra,8(sp)
    80002b1e:	e022                	sd	s0,0(sp)
    80002b20:	0800                	addi	s0,sp,16
  return fork();
    80002b22:	fffff097          	auipc	ra,0xfffff
    80002b26:	088080e7          	jalr	136(ra) # 80001baa <fork>
}
    80002b2a:	60a2                	ld	ra,8(sp)
    80002b2c:	6402                	ld	s0,0(sp)
    80002b2e:	0141                	addi	sp,sp,16
    80002b30:	8082                	ret

0000000080002b32 <sys_wait>:

uint64
sys_wait(void)
{
    80002b32:	1101                	addi	sp,sp,-32
    80002b34:	ec06                	sd	ra,24(sp)
    80002b36:	e822                	sd	s0,16(sp)
    80002b38:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002b3a:	fe840593          	addi	a1,s0,-24
    80002b3e:	4501                	li	a0,0
    80002b40:	00000097          	auipc	ra,0x0
    80002b44:	ece080e7          	jalr	-306(ra) # 80002a0e <argaddr>
    80002b48:	87aa                	mv	a5,a0
    return -1;
    80002b4a:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002b4c:	0007c863          	bltz	a5,80002b5c <sys_wait+0x2a>
  return wait(p);
    80002b50:	fe843503          	ld	a0,-24(s0)
    80002b54:	fffff097          	auipc	ra,0xfffff
    80002b58:	50c080e7          	jalr	1292(ra) # 80002060 <wait>
}
    80002b5c:	60e2                	ld	ra,24(sp)
    80002b5e:	6442                	ld	s0,16(sp)
    80002b60:	6105                	addi	sp,sp,32
    80002b62:	8082                	ret

0000000080002b64 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002b64:	7179                	addi	sp,sp,-48
    80002b66:	f406                	sd	ra,40(sp)
    80002b68:	f022                	sd	s0,32(sp)
    80002b6a:	ec26                	sd	s1,24(sp)
    80002b6c:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002b6e:	fdc40593          	addi	a1,s0,-36
    80002b72:	4501                	li	a0,0
    80002b74:	00000097          	auipc	ra,0x0
    80002b78:	e78080e7          	jalr	-392(ra) # 800029ec <argint>
    80002b7c:	87aa                	mv	a5,a0
    return -1;
    80002b7e:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002b80:	0207c063          	bltz	a5,80002ba0 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002b84:	fffff097          	auipc	ra,0xfffff
    80002b88:	cbc080e7          	jalr	-836(ra) # 80001840 <myproc>
    80002b8c:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002b8e:	fdc42503          	lw	a0,-36(s0)
    80002b92:	fffff097          	auipc	ra,0xfffff
    80002b96:	fa4080e7          	jalr	-92(ra) # 80001b36 <growproc>
    80002b9a:	00054863          	bltz	a0,80002baa <sys_sbrk+0x46>
    return -1;
  return addr;
    80002b9e:	8526                	mv	a0,s1
}
    80002ba0:	70a2                	ld	ra,40(sp)
    80002ba2:	7402                	ld	s0,32(sp)
    80002ba4:	64e2                	ld	s1,24(sp)
    80002ba6:	6145                	addi	sp,sp,48
    80002ba8:	8082                	ret
    return -1;
    80002baa:	557d                	li	a0,-1
    80002bac:	bfd5                	j	80002ba0 <sys_sbrk+0x3c>

0000000080002bae <sys_sleep>:

uint64
sys_sleep(void)
{
    80002bae:	7139                	addi	sp,sp,-64
    80002bb0:	fc06                	sd	ra,56(sp)
    80002bb2:	f822                	sd	s0,48(sp)
    80002bb4:	f426                	sd	s1,40(sp)
    80002bb6:	f04a                	sd	s2,32(sp)
    80002bb8:	ec4e                	sd	s3,24(sp)
    80002bba:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002bbc:	fcc40593          	addi	a1,s0,-52
    80002bc0:	4501                	li	a0,0
    80002bc2:	00000097          	auipc	ra,0x0
    80002bc6:	e2a080e7          	jalr	-470(ra) # 800029ec <argint>
    return -1;
    80002bca:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002bcc:	06054563          	bltz	a0,80002c36 <sys_sleep+0x88>
  acquire(&tickslock);
    80002bd0:	00015517          	auipc	a0,0x15
    80002bd4:	b3050513          	addi	a0,a0,-1232 # 80017700 <tickslock>
    80002bd8:	ffffe097          	auipc	ra,0xffffe
    80002bdc:	ef6080e7          	jalr	-266(ra) # 80000ace <acquire>
  ticks0 = ticks;
    80002be0:	00023917          	auipc	s2,0x23
    80002be4:	45092903          	lw	s2,1104(s2) # 80026030 <ticks>
  while(ticks - ticks0 < n){
    80002be8:	fcc42783          	lw	a5,-52(s0)
    80002bec:	cf85                	beqz	a5,80002c24 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002bee:	00015997          	auipc	s3,0x15
    80002bf2:	b1298993          	addi	s3,s3,-1262 # 80017700 <tickslock>
    80002bf6:	00023497          	auipc	s1,0x23
    80002bfa:	43a48493          	addi	s1,s1,1082 # 80026030 <ticks>
    if(myproc()->killed){
    80002bfe:	fffff097          	auipc	ra,0xfffff
    80002c02:	c42080e7          	jalr	-958(ra) # 80001840 <myproc>
    80002c06:	591c                	lw	a5,48(a0)
    80002c08:	ef9d                	bnez	a5,80002c46 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002c0a:	85ce                	mv	a1,s3
    80002c0c:	8526                	mv	a0,s1
    80002c0e:	fffff097          	auipc	ra,0xfffff
    80002c12:	3d4080e7          	jalr	980(ra) # 80001fe2 <sleep>
  while(ticks - ticks0 < n){
    80002c16:	409c                	lw	a5,0(s1)
    80002c18:	412787bb          	subw	a5,a5,s2
    80002c1c:	fcc42703          	lw	a4,-52(s0)
    80002c20:	fce7efe3          	bltu	a5,a4,80002bfe <sys_sleep+0x50>
  }
  release(&tickslock);
    80002c24:	00015517          	auipc	a0,0x15
    80002c28:	adc50513          	addi	a0,a0,-1316 # 80017700 <tickslock>
    80002c2c:	ffffe097          	auipc	ra,0xffffe
    80002c30:	ef6080e7          	jalr	-266(ra) # 80000b22 <release>
  return 0;
    80002c34:	4781                	li	a5,0
}
    80002c36:	853e                	mv	a0,a5
    80002c38:	70e2                	ld	ra,56(sp)
    80002c3a:	7442                	ld	s0,48(sp)
    80002c3c:	74a2                	ld	s1,40(sp)
    80002c3e:	7902                	ld	s2,32(sp)
    80002c40:	69e2                	ld	s3,24(sp)
    80002c42:	6121                	addi	sp,sp,64
    80002c44:	8082                	ret
      release(&tickslock);
    80002c46:	00015517          	auipc	a0,0x15
    80002c4a:	aba50513          	addi	a0,a0,-1350 # 80017700 <tickslock>
    80002c4e:	ffffe097          	auipc	ra,0xffffe
    80002c52:	ed4080e7          	jalr	-300(ra) # 80000b22 <release>
      return -1;
    80002c56:	57fd                	li	a5,-1
    80002c58:	bff9                	j	80002c36 <sys_sleep+0x88>

0000000080002c5a <sys_kill>:

uint64
sys_kill(void)
{
    80002c5a:	1101                	addi	sp,sp,-32
    80002c5c:	ec06                	sd	ra,24(sp)
    80002c5e:	e822                	sd	s0,16(sp)
    80002c60:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002c62:	fec40593          	addi	a1,s0,-20
    80002c66:	4501                	li	a0,0
    80002c68:	00000097          	auipc	ra,0x0
    80002c6c:	d84080e7          	jalr	-636(ra) # 800029ec <argint>
    80002c70:	87aa                	mv	a5,a0
    return -1;
    80002c72:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002c74:	0007c863          	bltz	a5,80002c84 <sys_kill+0x2a>
  return kill(pid);
    80002c78:	fec42503          	lw	a0,-20(s0)
    80002c7c:	fffff097          	auipc	ra,0xfffff
    80002c80:	556080e7          	jalr	1366(ra) # 800021d2 <kill>
}
    80002c84:	60e2                	ld	ra,24(sp)
    80002c86:	6442                	ld	s0,16(sp)
    80002c88:	6105                	addi	sp,sp,32
    80002c8a:	8082                	ret

0000000080002c8c <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002c8c:	1101                	addi	sp,sp,-32
    80002c8e:	ec06                	sd	ra,24(sp)
    80002c90:	e822                	sd	s0,16(sp)
    80002c92:	e426                	sd	s1,8(sp)
    80002c94:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002c96:	00015517          	auipc	a0,0x15
    80002c9a:	a6a50513          	addi	a0,a0,-1430 # 80017700 <tickslock>
    80002c9e:	ffffe097          	auipc	ra,0xffffe
    80002ca2:	e30080e7          	jalr	-464(ra) # 80000ace <acquire>
  xticks = ticks;
    80002ca6:	00023497          	auipc	s1,0x23
    80002caa:	38a4a483          	lw	s1,906(s1) # 80026030 <ticks>
  release(&tickslock);
    80002cae:	00015517          	auipc	a0,0x15
    80002cb2:	a5250513          	addi	a0,a0,-1454 # 80017700 <tickslock>
    80002cb6:	ffffe097          	auipc	ra,0xffffe
    80002cba:	e6c080e7          	jalr	-404(ra) # 80000b22 <release>
  return xticks;
}
    80002cbe:	02049513          	slli	a0,s1,0x20
    80002cc2:	9101                	srli	a0,a0,0x20
    80002cc4:	60e2                	ld	ra,24(sp)
    80002cc6:	6442                	ld	s0,16(sp)
    80002cc8:	64a2                	ld	s1,8(sp)
    80002cca:	6105                	addi	sp,sp,32
    80002ccc:	8082                	ret

0000000080002cce <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002cce:	7179                	addi	sp,sp,-48
    80002cd0:	f406                	sd	ra,40(sp)
    80002cd2:	f022                	sd	s0,32(sp)
    80002cd4:	ec26                	sd	s1,24(sp)
    80002cd6:	e84a                	sd	s2,16(sp)
    80002cd8:	e44e                	sd	s3,8(sp)
    80002cda:	e052                	sd	s4,0(sp)
    80002cdc:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002cde:	00004597          	auipc	a1,0x4
    80002ce2:	7ea58593          	addi	a1,a1,2026 # 800074c8 <userret+0x438>
    80002ce6:	00015517          	auipc	a0,0x15
    80002cea:	a3250513          	addi	a0,a0,-1486 # 80017718 <bcache>
    80002cee:	ffffe097          	auipc	ra,0xffffe
    80002cf2:	cce080e7          	jalr	-818(ra) # 800009bc <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002cf6:	0001d797          	auipc	a5,0x1d
    80002cfa:	a2278793          	addi	a5,a5,-1502 # 8001f718 <bcache+0x8000>
    80002cfe:	0001d717          	auipc	a4,0x1d
    80002d02:	d7270713          	addi	a4,a4,-654 # 8001fa70 <bcache+0x8358>
    80002d06:	3ae7b023          	sd	a4,928(a5)
  bcache.head.next = &bcache.head;
    80002d0a:	3ae7b423          	sd	a4,936(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002d0e:	00015497          	auipc	s1,0x15
    80002d12:	a2248493          	addi	s1,s1,-1502 # 80017730 <bcache+0x18>
    b->next = bcache.head.next;
    80002d16:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002d18:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002d1a:	00004a17          	auipc	s4,0x4
    80002d1e:	7b6a0a13          	addi	s4,s4,1974 # 800074d0 <userret+0x440>
    b->next = bcache.head.next;
    80002d22:	3a893783          	ld	a5,936(s2)
    80002d26:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002d28:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002d2c:	85d2                	mv	a1,s4
    80002d2e:	01048513          	addi	a0,s1,16
    80002d32:	00001097          	auipc	ra,0x1
    80002d36:	486080e7          	jalr	1158(ra) # 800041b8 <initsleeplock>
    bcache.head.next->prev = b;
    80002d3a:	3a893783          	ld	a5,936(s2)
    80002d3e:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002d40:	3a993423          	sd	s1,936(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002d44:	46048493          	addi	s1,s1,1120
    80002d48:	fd349de3          	bne	s1,s3,80002d22 <binit+0x54>
  }
}
    80002d4c:	70a2                	ld	ra,40(sp)
    80002d4e:	7402                	ld	s0,32(sp)
    80002d50:	64e2                	ld	s1,24(sp)
    80002d52:	6942                	ld	s2,16(sp)
    80002d54:	69a2                	ld	s3,8(sp)
    80002d56:	6a02                	ld	s4,0(sp)
    80002d58:	6145                	addi	sp,sp,48
    80002d5a:	8082                	ret

0000000080002d5c <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002d5c:	7179                	addi	sp,sp,-48
    80002d5e:	f406                	sd	ra,40(sp)
    80002d60:	f022                	sd	s0,32(sp)
    80002d62:	ec26                	sd	s1,24(sp)
    80002d64:	e84a                	sd	s2,16(sp)
    80002d66:	e44e                	sd	s3,8(sp)
    80002d68:	1800                	addi	s0,sp,48
    80002d6a:	89aa                	mv	s3,a0
    80002d6c:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80002d6e:	00015517          	auipc	a0,0x15
    80002d72:	9aa50513          	addi	a0,a0,-1622 # 80017718 <bcache>
    80002d76:	ffffe097          	auipc	ra,0xffffe
    80002d7a:	d58080e7          	jalr	-680(ra) # 80000ace <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002d7e:	0001d497          	auipc	s1,0x1d
    80002d82:	d424b483          	ld	s1,-702(s1) # 8001fac0 <bcache+0x83a8>
    80002d86:	0001d797          	auipc	a5,0x1d
    80002d8a:	cea78793          	addi	a5,a5,-790 # 8001fa70 <bcache+0x8358>
    80002d8e:	02f48f63          	beq	s1,a5,80002dcc <bread+0x70>
    80002d92:	873e                	mv	a4,a5
    80002d94:	a021                	j	80002d9c <bread+0x40>
    80002d96:	68a4                	ld	s1,80(s1)
    80002d98:	02e48a63          	beq	s1,a4,80002dcc <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002d9c:	449c                	lw	a5,8(s1)
    80002d9e:	ff379ce3          	bne	a5,s3,80002d96 <bread+0x3a>
    80002da2:	44dc                	lw	a5,12(s1)
    80002da4:	ff2799e3          	bne	a5,s2,80002d96 <bread+0x3a>
      b->refcnt++;
    80002da8:	40bc                	lw	a5,64(s1)
    80002daa:	2785                	addiw	a5,a5,1
    80002dac:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002dae:	00015517          	auipc	a0,0x15
    80002db2:	96a50513          	addi	a0,a0,-1686 # 80017718 <bcache>
    80002db6:	ffffe097          	auipc	ra,0xffffe
    80002dba:	d6c080e7          	jalr	-660(ra) # 80000b22 <release>
      acquiresleep(&b->lock);
    80002dbe:	01048513          	addi	a0,s1,16
    80002dc2:	00001097          	auipc	ra,0x1
    80002dc6:	430080e7          	jalr	1072(ra) # 800041f2 <acquiresleep>
      return b;
    80002dca:	a8b9                	j	80002e28 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002dcc:	0001d497          	auipc	s1,0x1d
    80002dd0:	cec4b483          	ld	s1,-788(s1) # 8001fab8 <bcache+0x83a0>
    80002dd4:	0001d797          	auipc	a5,0x1d
    80002dd8:	c9c78793          	addi	a5,a5,-868 # 8001fa70 <bcache+0x8358>
    80002ddc:	00f48863          	beq	s1,a5,80002dec <bread+0x90>
    80002de0:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002de2:	40bc                	lw	a5,64(s1)
    80002de4:	cf81                	beqz	a5,80002dfc <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002de6:	64a4                	ld	s1,72(s1)
    80002de8:	fee49de3          	bne	s1,a4,80002de2 <bread+0x86>
  panic("bget: no buffers");
    80002dec:	00004517          	auipc	a0,0x4
    80002df0:	6ec50513          	addi	a0,a0,1772 # 800074d8 <userret+0x448>
    80002df4:	ffffd097          	auipc	ra,0xffffd
    80002df8:	75a080e7          	jalr	1882(ra) # 8000054e <panic>
      b->dev = dev;
    80002dfc:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80002e00:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80002e04:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002e08:	4785                	li	a5,1
    80002e0a:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002e0c:	00015517          	auipc	a0,0x15
    80002e10:	90c50513          	addi	a0,a0,-1780 # 80017718 <bcache>
    80002e14:	ffffe097          	auipc	ra,0xffffe
    80002e18:	d0e080e7          	jalr	-754(ra) # 80000b22 <release>
      acquiresleep(&b->lock);
    80002e1c:	01048513          	addi	a0,s1,16
    80002e20:	00001097          	auipc	ra,0x1
    80002e24:	3d2080e7          	jalr	978(ra) # 800041f2 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80002e28:	409c                	lw	a5,0(s1)
    80002e2a:	cb89                	beqz	a5,80002e3c <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80002e2c:	8526                	mv	a0,s1
    80002e2e:	70a2                	ld	ra,40(sp)
    80002e30:	7402                	ld	s0,32(sp)
    80002e32:	64e2                	ld	s1,24(sp)
    80002e34:	6942                	ld	s2,16(sp)
    80002e36:	69a2                	ld	s3,8(sp)
    80002e38:	6145                	addi	sp,sp,48
    80002e3a:	8082                	ret
    virtio_disk_rw(b, 0);
    80002e3c:	4581                	li	a1,0
    80002e3e:	8526                	mv	a0,s1
    80002e40:	00003097          	auipc	ra,0x3
    80002e44:	ede080e7          	jalr	-290(ra) # 80005d1e <virtio_disk_rw>
    b->valid = 1;
    80002e48:	4785                	li	a5,1
    80002e4a:	c09c                	sw	a5,0(s1)
  return b;
    80002e4c:	b7c5                	j	80002e2c <bread+0xd0>

0000000080002e4e <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80002e4e:	1101                	addi	sp,sp,-32
    80002e50:	ec06                	sd	ra,24(sp)
    80002e52:	e822                	sd	s0,16(sp)
    80002e54:	e426                	sd	s1,8(sp)
    80002e56:	1000                	addi	s0,sp,32
    80002e58:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002e5a:	0541                	addi	a0,a0,16
    80002e5c:	00001097          	auipc	ra,0x1
    80002e60:	430080e7          	jalr	1072(ra) # 8000428c <holdingsleep>
    80002e64:	cd01                	beqz	a0,80002e7c <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80002e66:	4585                	li	a1,1
    80002e68:	8526                	mv	a0,s1
    80002e6a:	00003097          	auipc	ra,0x3
    80002e6e:	eb4080e7          	jalr	-332(ra) # 80005d1e <virtio_disk_rw>
}
    80002e72:	60e2                	ld	ra,24(sp)
    80002e74:	6442                	ld	s0,16(sp)
    80002e76:	64a2                	ld	s1,8(sp)
    80002e78:	6105                	addi	sp,sp,32
    80002e7a:	8082                	ret
    panic("bwrite");
    80002e7c:	00004517          	auipc	a0,0x4
    80002e80:	67450513          	addi	a0,a0,1652 # 800074f0 <userret+0x460>
    80002e84:	ffffd097          	auipc	ra,0xffffd
    80002e88:	6ca080e7          	jalr	1738(ra) # 8000054e <panic>

0000000080002e8c <brelse>:

// Release a locked buffer.
// Move to the head of the MRU list.
void
brelse(struct buf *b)
{
    80002e8c:	1101                	addi	sp,sp,-32
    80002e8e:	ec06                	sd	ra,24(sp)
    80002e90:	e822                	sd	s0,16(sp)
    80002e92:	e426                	sd	s1,8(sp)
    80002e94:	e04a                	sd	s2,0(sp)
    80002e96:	1000                	addi	s0,sp,32
    80002e98:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002e9a:	01050913          	addi	s2,a0,16
    80002e9e:	854a                	mv	a0,s2
    80002ea0:	00001097          	auipc	ra,0x1
    80002ea4:	3ec080e7          	jalr	1004(ra) # 8000428c <holdingsleep>
    80002ea8:	c92d                	beqz	a0,80002f1a <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80002eaa:	854a                	mv	a0,s2
    80002eac:	00001097          	auipc	ra,0x1
    80002eb0:	39c080e7          	jalr	924(ra) # 80004248 <releasesleep>

  acquire(&bcache.lock);
    80002eb4:	00015517          	auipc	a0,0x15
    80002eb8:	86450513          	addi	a0,a0,-1948 # 80017718 <bcache>
    80002ebc:	ffffe097          	auipc	ra,0xffffe
    80002ec0:	c12080e7          	jalr	-1006(ra) # 80000ace <acquire>
  b->refcnt--;
    80002ec4:	40bc                	lw	a5,64(s1)
    80002ec6:	37fd                	addiw	a5,a5,-1
    80002ec8:	0007871b          	sext.w	a4,a5
    80002ecc:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80002ece:	eb05                	bnez	a4,80002efe <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80002ed0:	68bc                	ld	a5,80(s1)
    80002ed2:	64b8                	ld	a4,72(s1)
    80002ed4:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80002ed6:	64bc                	ld	a5,72(s1)
    80002ed8:	68b8                	ld	a4,80(s1)
    80002eda:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80002edc:	0001d797          	auipc	a5,0x1d
    80002ee0:	83c78793          	addi	a5,a5,-1988 # 8001f718 <bcache+0x8000>
    80002ee4:	3a87b703          	ld	a4,936(a5)
    80002ee8:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80002eea:	0001d717          	auipc	a4,0x1d
    80002eee:	b8670713          	addi	a4,a4,-1146 # 8001fa70 <bcache+0x8358>
    80002ef2:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80002ef4:	3a87b703          	ld	a4,936(a5)
    80002ef8:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80002efa:	3a97b423          	sd	s1,936(a5)
  }
  
  release(&bcache.lock);
    80002efe:	00015517          	auipc	a0,0x15
    80002f02:	81a50513          	addi	a0,a0,-2022 # 80017718 <bcache>
    80002f06:	ffffe097          	auipc	ra,0xffffe
    80002f0a:	c1c080e7          	jalr	-996(ra) # 80000b22 <release>
}
    80002f0e:	60e2                	ld	ra,24(sp)
    80002f10:	6442                	ld	s0,16(sp)
    80002f12:	64a2                	ld	s1,8(sp)
    80002f14:	6902                	ld	s2,0(sp)
    80002f16:	6105                	addi	sp,sp,32
    80002f18:	8082                	ret
    panic("brelse");
    80002f1a:	00004517          	auipc	a0,0x4
    80002f1e:	5de50513          	addi	a0,a0,1502 # 800074f8 <userret+0x468>
    80002f22:	ffffd097          	auipc	ra,0xffffd
    80002f26:	62c080e7          	jalr	1580(ra) # 8000054e <panic>

0000000080002f2a <bpin>:

void
bpin(struct buf *b) {
    80002f2a:	1101                	addi	sp,sp,-32
    80002f2c:	ec06                	sd	ra,24(sp)
    80002f2e:	e822                	sd	s0,16(sp)
    80002f30:	e426                	sd	s1,8(sp)
    80002f32:	1000                	addi	s0,sp,32
    80002f34:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80002f36:	00014517          	auipc	a0,0x14
    80002f3a:	7e250513          	addi	a0,a0,2018 # 80017718 <bcache>
    80002f3e:	ffffe097          	auipc	ra,0xffffe
    80002f42:	b90080e7          	jalr	-1136(ra) # 80000ace <acquire>
  b->refcnt++;
    80002f46:	40bc                	lw	a5,64(s1)
    80002f48:	2785                	addiw	a5,a5,1
    80002f4a:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80002f4c:	00014517          	auipc	a0,0x14
    80002f50:	7cc50513          	addi	a0,a0,1996 # 80017718 <bcache>
    80002f54:	ffffe097          	auipc	ra,0xffffe
    80002f58:	bce080e7          	jalr	-1074(ra) # 80000b22 <release>
}
    80002f5c:	60e2                	ld	ra,24(sp)
    80002f5e:	6442                	ld	s0,16(sp)
    80002f60:	64a2                	ld	s1,8(sp)
    80002f62:	6105                	addi	sp,sp,32
    80002f64:	8082                	ret

0000000080002f66 <bunpin>:

void
bunpin(struct buf *b) {
    80002f66:	1101                	addi	sp,sp,-32
    80002f68:	ec06                	sd	ra,24(sp)
    80002f6a:	e822                	sd	s0,16(sp)
    80002f6c:	e426                	sd	s1,8(sp)
    80002f6e:	1000                	addi	s0,sp,32
    80002f70:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80002f72:	00014517          	auipc	a0,0x14
    80002f76:	7a650513          	addi	a0,a0,1958 # 80017718 <bcache>
    80002f7a:	ffffe097          	auipc	ra,0xffffe
    80002f7e:	b54080e7          	jalr	-1196(ra) # 80000ace <acquire>
  b->refcnt--;
    80002f82:	40bc                	lw	a5,64(s1)
    80002f84:	37fd                	addiw	a5,a5,-1
    80002f86:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80002f88:	00014517          	auipc	a0,0x14
    80002f8c:	79050513          	addi	a0,a0,1936 # 80017718 <bcache>
    80002f90:	ffffe097          	auipc	ra,0xffffe
    80002f94:	b92080e7          	jalr	-1134(ra) # 80000b22 <release>
}
    80002f98:	60e2                	ld	ra,24(sp)
    80002f9a:	6442                	ld	s0,16(sp)
    80002f9c:	64a2                	ld	s1,8(sp)
    80002f9e:	6105                	addi	sp,sp,32
    80002fa0:	8082                	ret

0000000080002fa2 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80002fa2:	1101                	addi	sp,sp,-32
    80002fa4:	ec06                	sd	ra,24(sp)
    80002fa6:	e822                	sd	s0,16(sp)
    80002fa8:	e426                	sd	s1,8(sp)
    80002faa:	e04a                	sd	s2,0(sp)
    80002fac:	1000                	addi	s0,sp,32
    80002fae:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80002fb0:	00d5d59b          	srliw	a1,a1,0xd
    80002fb4:	0001d797          	auipc	a5,0x1d
    80002fb8:	f387a783          	lw	a5,-200(a5) # 8001feec <sb+0x1c>
    80002fbc:	9dbd                	addw	a1,a1,a5
    80002fbe:	00000097          	auipc	ra,0x0
    80002fc2:	d9e080e7          	jalr	-610(ra) # 80002d5c <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80002fc6:	0074f713          	andi	a4,s1,7
    80002fca:	4785                	li	a5,1
    80002fcc:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80002fd0:	14ce                	slli	s1,s1,0x33
    80002fd2:	90d9                	srli	s1,s1,0x36
    80002fd4:	00950733          	add	a4,a0,s1
    80002fd8:	06074703          	lbu	a4,96(a4)
    80002fdc:	00e7f6b3          	and	a3,a5,a4
    80002fe0:	c69d                	beqz	a3,8000300e <bfree+0x6c>
    80002fe2:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80002fe4:	94aa                	add	s1,s1,a0
    80002fe6:	fff7c793          	not	a5,a5
    80002fea:	8ff9                	and	a5,a5,a4
    80002fec:	06f48023          	sb	a5,96(s1)
  log_write(bp);
    80002ff0:	00001097          	auipc	ra,0x1
    80002ff4:	0da080e7          	jalr	218(ra) # 800040ca <log_write>
  brelse(bp);
    80002ff8:	854a                	mv	a0,s2
    80002ffa:	00000097          	auipc	ra,0x0
    80002ffe:	e92080e7          	jalr	-366(ra) # 80002e8c <brelse>
}
    80003002:	60e2                	ld	ra,24(sp)
    80003004:	6442                	ld	s0,16(sp)
    80003006:	64a2                	ld	s1,8(sp)
    80003008:	6902                	ld	s2,0(sp)
    8000300a:	6105                	addi	sp,sp,32
    8000300c:	8082                	ret
    panic("freeing free block");
    8000300e:	00004517          	auipc	a0,0x4
    80003012:	4f250513          	addi	a0,a0,1266 # 80007500 <userret+0x470>
    80003016:	ffffd097          	auipc	ra,0xffffd
    8000301a:	538080e7          	jalr	1336(ra) # 8000054e <panic>

000000008000301e <balloc>:
{
    8000301e:	711d                	addi	sp,sp,-96
    80003020:	ec86                	sd	ra,88(sp)
    80003022:	e8a2                	sd	s0,80(sp)
    80003024:	e4a6                	sd	s1,72(sp)
    80003026:	e0ca                	sd	s2,64(sp)
    80003028:	fc4e                	sd	s3,56(sp)
    8000302a:	f852                	sd	s4,48(sp)
    8000302c:	f456                	sd	s5,40(sp)
    8000302e:	f05a                	sd	s6,32(sp)
    80003030:	ec5e                	sd	s7,24(sp)
    80003032:	e862                	sd	s8,16(sp)
    80003034:	e466                	sd	s9,8(sp)
    80003036:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003038:	0001d797          	auipc	a5,0x1d
    8000303c:	e9c7a783          	lw	a5,-356(a5) # 8001fed4 <sb+0x4>
    80003040:	cbd1                	beqz	a5,800030d4 <balloc+0xb6>
    80003042:	8baa                	mv	s7,a0
    80003044:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003046:	0001db17          	auipc	s6,0x1d
    8000304a:	e8ab0b13          	addi	s6,s6,-374 # 8001fed0 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000304e:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003050:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003052:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003054:	6c89                	lui	s9,0x2
    80003056:	a831                	j	80003072 <balloc+0x54>
    brelse(bp);
    80003058:	854a                	mv	a0,s2
    8000305a:	00000097          	auipc	ra,0x0
    8000305e:	e32080e7          	jalr	-462(ra) # 80002e8c <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003062:	015c87bb          	addw	a5,s9,s5
    80003066:	00078a9b          	sext.w	s5,a5
    8000306a:	004b2703          	lw	a4,4(s6)
    8000306e:	06eaf363          	bgeu	s5,a4,800030d4 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003072:	41fad79b          	sraiw	a5,s5,0x1f
    80003076:	0137d79b          	srliw	a5,a5,0x13
    8000307a:	015787bb          	addw	a5,a5,s5
    8000307e:	40d7d79b          	sraiw	a5,a5,0xd
    80003082:	01cb2583          	lw	a1,28(s6)
    80003086:	9dbd                	addw	a1,a1,a5
    80003088:	855e                	mv	a0,s7
    8000308a:	00000097          	auipc	ra,0x0
    8000308e:	cd2080e7          	jalr	-814(ra) # 80002d5c <bread>
    80003092:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003094:	004b2503          	lw	a0,4(s6)
    80003098:	000a849b          	sext.w	s1,s5
    8000309c:	8662                	mv	a2,s8
    8000309e:	faa4fde3          	bgeu	s1,a0,80003058 <balloc+0x3a>
      m = 1 << (bi % 8);
    800030a2:	41f6579b          	sraiw	a5,a2,0x1f
    800030a6:	01d7d69b          	srliw	a3,a5,0x1d
    800030aa:	00c6873b          	addw	a4,a3,a2
    800030ae:	00777793          	andi	a5,a4,7
    800030b2:	9f95                	subw	a5,a5,a3
    800030b4:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800030b8:	4037571b          	sraiw	a4,a4,0x3
    800030bc:	00e906b3          	add	a3,s2,a4
    800030c0:	0606c683          	lbu	a3,96(a3)
    800030c4:	00d7f5b3          	and	a1,a5,a3
    800030c8:	cd91                	beqz	a1,800030e4 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800030ca:	2605                	addiw	a2,a2,1
    800030cc:	2485                	addiw	s1,s1,1
    800030ce:	fd4618e3          	bne	a2,s4,8000309e <balloc+0x80>
    800030d2:	b759                	j	80003058 <balloc+0x3a>
  panic("balloc: out of blocks");
    800030d4:	00004517          	auipc	a0,0x4
    800030d8:	44450513          	addi	a0,a0,1092 # 80007518 <userret+0x488>
    800030dc:	ffffd097          	auipc	ra,0xffffd
    800030e0:	472080e7          	jalr	1138(ra) # 8000054e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800030e4:	974a                	add	a4,a4,s2
    800030e6:	8fd5                	or	a5,a5,a3
    800030e8:	06f70023          	sb	a5,96(a4)
        log_write(bp);
    800030ec:	854a                	mv	a0,s2
    800030ee:	00001097          	auipc	ra,0x1
    800030f2:	fdc080e7          	jalr	-36(ra) # 800040ca <log_write>
        brelse(bp);
    800030f6:	854a                	mv	a0,s2
    800030f8:	00000097          	auipc	ra,0x0
    800030fc:	d94080e7          	jalr	-620(ra) # 80002e8c <brelse>
  bp = bread(dev, bno);
    80003100:	85a6                	mv	a1,s1
    80003102:	855e                	mv	a0,s7
    80003104:	00000097          	auipc	ra,0x0
    80003108:	c58080e7          	jalr	-936(ra) # 80002d5c <bread>
    8000310c:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000310e:	40000613          	li	a2,1024
    80003112:	4581                	li	a1,0
    80003114:	06050513          	addi	a0,a0,96
    80003118:	ffffe097          	auipc	ra,0xffffe
    8000311c:	a52080e7          	jalr	-1454(ra) # 80000b6a <memset>
  log_write(bp);
    80003120:	854a                	mv	a0,s2
    80003122:	00001097          	auipc	ra,0x1
    80003126:	fa8080e7          	jalr	-88(ra) # 800040ca <log_write>
  brelse(bp);
    8000312a:	854a                	mv	a0,s2
    8000312c:	00000097          	auipc	ra,0x0
    80003130:	d60080e7          	jalr	-672(ra) # 80002e8c <brelse>
}
    80003134:	8526                	mv	a0,s1
    80003136:	60e6                	ld	ra,88(sp)
    80003138:	6446                	ld	s0,80(sp)
    8000313a:	64a6                	ld	s1,72(sp)
    8000313c:	6906                	ld	s2,64(sp)
    8000313e:	79e2                	ld	s3,56(sp)
    80003140:	7a42                	ld	s4,48(sp)
    80003142:	7aa2                	ld	s5,40(sp)
    80003144:	7b02                	ld	s6,32(sp)
    80003146:	6be2                	ld	s7,24(sp)
    80003148:	6c42                	ld	s8,16(sp)
    8000314a:	6ca2                	ld	s9,8(sp)
    8000314c:	6125                	addi	sp,sp,96
    8000314e:	8082                	ret

0000000080003150 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003150:	7179                	addi	sp,sp,-48
    80003152:	f406                	sd	ra,40(sp)
    80003154:	f022                	sd	s0,32(sp)
    80003156:	ec26                	sd	s1,24(sp)
    80003158:	e84a                	sd	s2,16(sp)
    8000315a:	e44e                	sd	s3,8(sp)
    8000315c:	e052                	sd	s4,0(sp)
    8000315e:	1800                	addi	s0,sp,48
    80003160:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003162:	47ad                	li	a5,11
    80003164:	04b7fe63          	bgeu	a5,a1,800031c0 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003168:	ff45849b          	addiw	s1,a1,-12
    8000316c:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003170:	0ff00793          	li	a5,255
    80003174:	0ae7e363          	bltu	a5,a4,8000321a <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003178:	08052583          	lw	a1,128(a0)
    8000317c:	c5ad                	beqz	a1,800031e6 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    8000317e:	00092503          	lw	a0,0(s2)
    80003182:	00000097          	auipc	ra,0x0
    80003186:	bda080e7          	jalr	-1062(ra) # 80002d5c <bread>
    8000318a:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000318c:	06050793          	addi	a5,a0,96
    if((addr = a[bn]) == 0){
    80003190:	02049593          	slli	a1,s1,0x20
    80003194:	9181                	srli	a1,a1,0x20
    80003196:	058a                	slli	a1,a1,0x2
    80003198:	00b784b3          	add	s1,a5,a1
    8000319c:	0004a983          	lw	s3,0(s1)
    800031a0:	04098d63          	beqz	s3,800031fa <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800031a4:	8552                	mv	a0,s4
    800031a6:	00000097          	auipc	ra,0x0
    800031aa:	ce6080e7          	jalr	-794(ra) # 80002e8c <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800031ae:	854e                	mv	a0,s3
    800031b0:	70a2                	ld	ra,40(sp)
    800031b2:	7402                	ld	s0,32(sp)
    800031b4:	64e2                	ld	s1,24(sp)
    800031b6:	6942                	ld	s2,16(sp)
    800031b8:	69a2                	ld	s3,8(sp)
    800031ba:	6a02                	ld	s4,0(sp)
    800031bc:	6145                	addi	sp,sp,48
    800031be:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800031c0:	02059493          	slli	s1,a1,0x20
    800031c4:	9081                	srli	s1,s1,0x20
    800031c6:	048a                	slli	s1,s1,0x2
    800031c8:	94aa                	add	s1,s1,a0
    800031ca:	0504a983          	lw	s3,80(s1)
    800031ce:	fe0990e3          	bnez	s3,800031ae <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800031d2:	4108                	lw	a0,0(a0)
    800031d4:	00000097          	auipc	ra,0x0
    800031d8:	e4a080e7          	jalr	-438(ra) # 8000301e <balloc>
    800031dc:	0005099b          	sext.w	s3,a0
    800031e0:	0534a823          	sw	s3,80(s1)
    800031e4:	b7e9                	j	800031ae <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800031e6:	4108                	lw	a0,0(a0)
    800031e8:	00000097          	auipc	ra,0x0
    800031ec:	e36080e7          	jalr	-458(ra) # 8000301e <balloc>
    800031f0:	0005059b          	sext.w	a1,a0
    800031f4:	08b92023          	sw	a1,128(s2)
    800031f8:	b759                	j	8000317e <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800031fa:	00092503          	lw	a0,0(s2)
    800031fe:	00000097          	auipc	ra,0x0
    80003202:	e20080e7          	jalr	-480(ra) # 8000301e <balloc>
    80003206:	0005099b          	sext.w	s3,a0
    8000320a:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    8000320e:	8552                	mv	a0,s4
    80003210:	00001097          	auipc	ra,0x1
    80003214:	eba080e7          	jalr	-326(ra) # 800040ca <log_write>
    80003218:	b771                	j	800031a4 <bmap+0x54>
  panic("bmap: out of range");
    8000321a:	00004517          	auipc	a0,0x4
    8000321e:	31650513          	addi	a0,a0,790 # 80007530 <userret+0x4a0>
    80003222:	ffffd097          	auipc	ra,0xffffd
    80003226:	32c080e7          	jalr	812(ra) # 8000054e <panic>

000000008000322a <iget>:
{
    8000322a:	7179                	addi	sp,sp,-48
    8000322c:	f406                	sd	ra,40(sp)
    8000322e:	f022                	sd	s0,32(sp)
    80003230:	ec26                	sd	s1,24(sp)
    80003232:	e84a                	sd	s2,16(sp)
    80003234:	e44e                	sd	s3,8(sp)
    80003236:	e052                	sd	s4,0(sp)
    80003238:	1800                	addi	s0,sp,48
    8000323a:	89aa                	mv	s3,a0
    8000323c:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    8000323e:	0001d517          	auipc	a0,0x1d
    80003242:	cb250513          	addi	a0,a0,-846 # 8001fef0 <icache>
    80003246:	ffffe097          	auipc	ra,0xffffe
    8000324a:	888080e7          	jalr	-1912(ra) # 80000ace <acquire>
  empty = 0;
    8000324e:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    80003250:	0001d497          	auipc	s1,0x1d
    80003254:	cb848493          	addi	s1,s1,-840 # 8001ff08 <icache+0x18>
    80003258:	0001e697          	auipc	a3,0x1e
    8000325c:	74068693          	addi	a3,a3,1856 # 80021998 <log>
    80003260:	a039                	j	8000326e <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003262:	02090b63          	beqz	s2,80003298 <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    80003266:	08848493          	addi	s1,s1,136
    8000326a:	02d48a63          	beq	s1,a3,8000329e <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000326e:	449c                	lw	a5,8(s1)
    80003270:	fef059e3          	blez	a5,80003262 <iget+0x38>
    80003274:	4098                	lw	a4,0(s1)
    80003276:	ff3716e3          	bne	a4,s3,80003262 <iget+0x38>
    8000327a:	40d8                	lw	a4,4(s1)
    8000327c:	ff4713e3          	bne	a4,s4,80003262 <iget+0x38>
      ip->ref++;
    80003280:	2785                	addiw	a5,a5,1
    80003282:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    80003284:	0001d517          	auipc	a0,0x1d
    80003288:	c6c50513          	addi	a0,a0,-916 # 8001fef0 <icache>
    8000328c:	ffffe097          	auipc	ra,0xffffe
    80003290:	896080e7          	jalr	-1898(ra) # 80000b22 <release>
      return ip;
    80003294:	8926                	mv	s2,s1
    80003296:	a03d                	j	800032c4 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003298:	f7f9                	bnez	a5,80003266 <iget+0x3c>
    8000329a:	8926                	mv	s2,s1
    8000329c:	b7e9                	j	80003266 <iget+0x3c>
  if(empty == 0)
    8000329e:	02090c63          	beqz	s2,800032d6 <iget+0xac>
  ip->dev = dev;
    800032a2:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800032a6:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800032aa:	4785                	li	a5,1
    800032ac:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800032b0:	04092023          	sw	zero,64(s2)
  release(&icache.lock);
    800032b4:	0001d517          	auipc	a0,0x1d
    800032b8:	c3c50513          	addi	a0,a0,-964 # 8001fef0 <icache>
    800032bc:	ffffe097          	auipc	ra,0xffffe
    800032c0:	866080e7          	jalr	-1946(ra) # 80000b22 <release>
}
    800032c4:	854a                	mv	a0,s2
    800032c6:	70a2                	ld	ra,40(sp)
    800032c8:	7402                	ld	s0,32(sp)
    800032ca:	64e2                	ld	s1,24(sp)
    800032cc:	6942                	ld	s2,16(sp)
    800032ce:	69a2                	ld	s3,8(sp)
    800032d0:	6a02                	ld	s4,0(sp)
    800032d2:	6145                	addi	sp,sp,48
    800032d4:	8082                	ret
    panic("iget: no inodes");
    800032d6:	00004517          	auipc	a0,0x4
    800032da:	27250513          	addi	a0,a0,626 # 80007548 <userret+0x4b8>
    800032de:	ffffd097          	auipc	ra,0xffffd
    800032e2:	270080e7          	jalr	624(ra) # 8000054e <panic>

00000000800032e6 <fsinit>:
fsinit(int dev) {
    800032e6:	7179                	addi	sp,sp,-48
    800032e8:	f406                	sd	ra,40(sp)
    800032ea:	f022                	sd	s0,32(sp)
    800032ec:	ec26                	sd	s1,24(sp)
    800032ee:	e84a                	sd	s2,16(sp)
    800032f0:	e44e                	sd	s3,8(sp)
    800032f2:	1800                	addi	s0,sp,48
    800032f4:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800032f6:	4585                	li	a1,1
    800032f8:	00000097          	auipc	ra,0x0
    800032fc:	a64080e7          	jalr	-1436(ra) # 80002d5c <bread>
    80003300:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003302:	0001d997          	auipc	s3,0x1d
    80003306:	bce98993          	addi	s3,s3,-1074 # 8001fed0 <sb>
    8000330a:	02000613          	li	a2,32
    8000330e:	06050593          	addi	a1,a0,96
    80003312:	854e                	mv	a0,s3
    80003314:	ffffe097          	auipc	ra,0xffffe
    80003318:	8b6080e7          	jalr	-1866(ra) # 80000bca <memmove>
  brelse(bp);
    8000331c:	8526                	mv	a0,s1
    8000331e:	00000097          	auipc	ra,0x0
    80003322:	b6e080e7          	jalr	-1170(ra) # 80002e8c <brelse>
  if(sb.magic != FSMAGIC)
    80003326:	0009a703          	lw	a4,0(s3)
    8000332a:	102037b7          	lui	a5,0x10203
    8000332e:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003332:	02f71263          	bne	a4,a5,80003356 <fsinit+0x70>
  initlog(dev, &sb);
    80003336:	0001d597          	auipc	a1,0x1d
    8000333a:	b9a58593          	addi	a1,a1,-1126 # 8001fed0 <sb>
    8000333e:	854a                	mv	a0,s2
    80003340:	00001097          	auipc	ra,0x1
    80003344:	b12080e7          	jalr	-1262(ra) # 80003e52 <initlog>
}
    80003348:	70a2                	ld	ra,40(sp)
    8000334a:	7402                	ld	s0,32(sp)
    8000334c:	64e2                	ld	s1,24(sp)
    8000334e:	6942                	ld	s2,16(sp)
    80003350:	69a2                	ld	s3,8(sp)
    80003352:	6145                	addi	sp,sp,48
    80003354:	8082                	ret
    panic("invalid file system");
    80003356:	00004517          	auipc	a0,0x4
    8000335a:	20250513          	addi	a0,a0,514 # 80007558 <userret+0x4c8>
    8000335e:	ffffd097          	auipc	ra,0xffffd
    80003362:	1f0080e7          	jalr	496(ra) # 8000054e <panic>

0000000080003366 <iinit>:
{
    80003366:	7179                	addi	sp,sp,-48
    80003368:	f406                	sd	ra,40(sp)
    8000336a:	f022                	sd	s0,32(sp)
    8000336c:	ec26                	sd	s1,24(sp)
    8000336e:	e84a                	sd	s2,16(sp)
    80003370:	e44e                	sd	s3,8(sp)
    80003372:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    80003374:	00004597          	auipc	a1,0x4
    80003378:	1fc58593          	addi	a1,a1,508 # 80007570 <userret+0x4e0>
    8000337c:	0001d517          	auipc	a0,0x1d
    80003380:	b7450513          	addi	a0,a0,-1164 # 8001fef0 <icache>
    80003384:	ffffd097          	auipc	ra,0xffffd
    80003388:	638080e7          	jalr	1592(ra) # 800009bc <initlock>
  for(i = 0; i < NINODE; i++) {
    8000338c:	0001d497          	auipc	s1,0x1d
    80003390:	b8c48493          	addi	s1,s1,-1140 # 8001ff18 <icache+0x28>
    80003394:	0001e997          	auipc	s3,0x1e
    80003398:	61498993          	addi	s3,s3,1556 # 800219a8 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    8000339c:	00004917          	auipc	s2,0x4
    800033a0:	1dc90913          	addi	s2,s2,476 # 80007578 <userret+0x4e8>
    800033a4:	85ca                	mv	a1,s2
    800033a6:	8526                	mv	a0,s1
    800033a8:	00001097          	auipc	ra,0x1
    800033ac:	e10080e7          	jalr	-496(ra) # 800041b8 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800033b0:	08848493          	addi	s1,s1,136
    800033b4:	ff3498e3          	bne	s1,s3,800033a4 <iinit+0x3e>
}
    800033b8:	70a2                	ld	ra,40(sp)
    800033ba:	7402                	ld	s0,32(sp)
    800033bc:	64e2                	ld	s1,24(sp)
    800033be:	6942                	ld	s2,16(sp)
    800033c0:	69a2                	ld	s3,8(sp)
    800033c2:	6145                	addi	sp,sp,48
    800033c4:	8082                	ret

00000000800033c6 <ialloc>:
{
    800033c6:	715d                	addi	sp,sp,-80
    800033c8:	e486                	sd	ra,72(sp)
    800033ca:	e0a2                	sd	s0,64(sp)
    800033cc:	fc26                	sd	s1,56(sp)
    800033ce:	f84a                	sd	s2,48(sp)
    800033d0:	f44e                	sd	s3,40(sp)
    800033d2:	f052                	sd	s4,32(sp)
    800033d4:	ec56                	sd	s5,24(sp)
    800033d6:	e85a                	sd	s6,16(sp)
    800033d8:	e45e                	sd	s7,8(sp)
    800033da:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800033dc:	0001d717          	auipc	a4,0x1d
    800033e0:	b0072703          	lw	a4,-1280(a4) # 8001fedc <sb+0xc>
    800033e4:	4785                	li	a5,1
    800033e6:	04e7fa63          	bgeu	a5,a4,8000343a <ialloc+0x74>
    800033ea:	8aaa                	mv	s5,a0
    800033ec:	8bae                	mv	s7,a1
    800033ee:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800033f0:	0001da17          	auipc	s4,0x1d
    800033f4:	ae0a0a13          	addi	s4,s4,-1312 # 8001fed0 <sb>
    800033f8:	00048b1b          	sext.w	s6,s1
    800033fc:	0044d593          	srli	a1,s1,0x4
    80003400:	018a2783          	lw	a5,24(s4)
    80003404:	9dbd                	addw	a1,a1,a5
    80003406:	8556                	mv	a0,s5
    80003408:	00000097          	auipc	ra,0x0
    8000340c:	954080e7          	jalr	-1708(ra) # 80002d5c <bread>
    80003410:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003412:	06050993          	addi	s3,a0,96
    80003416:	00f4f793          	andi	a5,s1,15
    8000341a:	079a                	slli	a5,a5,0x6
    8000341c:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    8000341e:	00099783          	lh	a5,0(s3)
    80003422:	c785                	beqz	a5,8000344a <ialloc+0x84>
    brelse(bp);
    80003424:	00000097          	auipc	ra,0x0
    80003428:	a68080e7          	jalr	-1432(ra) # 80002e8c <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    8000342c:	0485                	addi	s1,s1,1
    8000342e:	00ca2703          	lw	a4,12(s4)
    80003432:	0004879b          	sext.w	a5,s1
    80003436:	fce7e1e3          	bltu	a5,a4,800033f8 <ialloc+0x32>
  panic("ialloc: no inodes");
    8000343a:	00004517          	auipc	a0,0x4
    8000343e:	14650513          	addi	a0,a0,326 # 80007580 <userret+0x4f0>
    80003442:	ffffd097          	auipc	ra,0xffffd
    80003446:	10c080e7          	jalr	268(ra) # 8000054e <panic>
      memset(dip, 0, sizeof(*dip));
    8000344a:	04000613          	li	a2,64
    8000344e:	4581                	li	a1,0
    80003450:	854e                	mv	a0,s3
    80003452:	ffffd097          	auipc	ra,0xffffd
    80003456:	718080e7          	jalr	1816(ra) # 80000b6a <memset>
      dip->type = type;
    8000345a:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    8000345e:	854a                	mv	a0,s2
    80003460:	00001097          	auipc	ra,0x1
    80003464:	c6a080e7          	jalr	-918(ra) # 800040ca <log_write>
      brelse(bp);
    80003468:	854a                	mv	a0,s2
    8000346a:	00000097          	auipc	ra,0x0
    8000346e:	a22080e7          	jalr	-1502(ra) # 80002e8c <brelse>
      return iget(dev, inum);
    80003472:	85da                	mv	a1,s6
    80003474:	8556                	mv	a0,s5
    80003476:	00000097          	auipc	ra,0x0
    8000347a:	db4080e7          	jalr	-588(ra) # 8000322a <iget>
}
    8000347e:	60a6                	ld	ra,72(sp)
    80003480:	6406                	ld	s0,64(sp)
    80003482:	74e2                	ld	s1,56(sp)
    80003484:	7942                	ld	s2,48(sp)
    80003486:	79a2                	ld	s3,40(sp)
    80003488:	7a02                	ld	s4,32(sp)
    8000348a:	6ae2                	ld	s5,24(sp)
    8000348c:	6b42                	ld	s6,16(sp)
    8000348e:	6ba2                	ld	s7,8(sp)
    80003490:	6161                	addi	sp,sp,80
    80003492:	8082                	ret

0000000080003494 <iupdate>:
{
    80003494:	1101                	addi	sp,sp,-32
    80003496:	ec06                	sd	ra,24(sp)
    80003498:	e822                	sd	s0,16(sp)
    8000349a:	e426                	sd	s1,8(sp)
    8000349c:	e04a                	sd	s2,0(sp)
    8000349e:	1000                	addi	s0,sp,32
    800034a0:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800034a2:	415c                	lw	a5,4(a0)
    800034a4:	0047d79b          	srliw	a5,a5,0x4
    800034a8:	0001d597          	auipc	a1,0x1d
    800034ac:	a405a583          	lw	a1,-1472(a1) # 8001fee8 <sb+0x18>
    800034b0:	9dbd                	addw	a1,a1,a5
    800034b2:	4108                	lw	a0,0(a0)
    800034b4:	00000097          	auipc	ra,0x0
    800034b8:	8a8080e7          	jalr	-1880(ra) # 80002d5c <bread>
    800034bc:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800034be:	06050793          	addi	a5,a0,96
    800034c2:	40c8                	lw	a0,4(s1)
    800034c4:	893d                	andi	a0,a0,15
    800034c6:	051a                	slli	a0,a0,0x6
    800034c8:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800034ca:	04449703          	lh	a4,68(s1)
    800034ce:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800034d2:	04649703          	lh	a4,70(s1)
    800034d6:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800034da:	04849703          	lh	a4,72(s1)
    800034de:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800034e2:	04a49703          	lh	a4,74(s1)
    800034e6:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    800034ea:	44f8                	lw	a4,76(s1)
    800034ec:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800034ee:	03400613          	li	a2,52
    800034f2:	05048593          	addi	a1,s1,80
    800034f6:	0531                	addi	a0,a0,12
    800034f8:	ffffd097          	auipc	ra,0xffffd
    800034fc:	6d2080e7          	jalr	1746(ra) # 80000bca <memmove>
  log_write(bp);
    80003500:	854a                	mv	a0,s2
    80003502:	00001097          	auipc	ra,0x1
    80003506:	bc8080e7          	jalr	-1080(ra) # 800040ca <log_write>
  brelse(bp);
    8000350a:	854a                	mv	a0,s2
    8000350c:	00000097          	auipc	ra,0x0
    80003510:	980080e7          	jalr	-1664(ra) # 80002e8c <brelse>
}
    80003514:	60e2                	ld	ra,24(sp)
    80003516:	6442                	ld	s0,16(sp)
    80003518:	64a2                	ld	s1,8(sp)
    8000351a:	6902                	ld	s2,0(sp)
    8000351c:	6105                	addi	sp,sp,32
    8000351e:	8082                	ret

0000000080003520 <idup>:
{
    80003520:	1101                	addi	sp,sp,-32
    80003522:	ec06                	sd	ra,24(sp)
    80003524:	e822                	sd	s0,16(sp)
    80003526:	e426                	sd	s1,8(sp)
    80003528:	1000                	addi	s0,sp,32
    8000352a:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    8000352c:	0001d517          	auipc	a0,0x1d
    80003530:	9c450513          	addi	a0,a0,-1596 # 8001fef0 <icache>
    80003534:	ffffd097          	auipc	ra,0xffffd
    80003538:	59a080e7          	jalr	1434(ra) # 80000ace <acquire>
  ip->ref++;
    8000353c:	449c                	lw	a5,8(s1)
    8000353e:	2785                	addiw	a5,a5,1
    80003540:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003542:	0001d517          	auipc	a0,0x1d
    80003546:	9ae50513          	addi	a0,a0,-1618 # 8001fef0 <icache>
    8000354a:	ffffd097          	auipc	ra,0xffffd
    8000354e:	5d8080e7          	jalr	1496(ra) # 80000b22 <release>
}
    80003552:	8526                	mv	a0,s1
    80003554:	60e2                	ld	ra,24(sp)
    80003556:	6442                	ld	s0,16(sp)
    80003558:	64a2                	ld	s1,8(sp)
    8000355a:	6105                	addi	sp,sp,32
    8000355c:	8082                	ret

000000008000355e <ilock>:
{
    8000355e:	1101                	addi	sp,sp,-32
    80003560:	ec06                	sd	ra,24(sp)
    80003562:	e822                	sd	s0,16(sp)
    80003564:	e426                	sd	s1,8(sp)
    80003566:	e04a                	sd	s2,0(sp)
    80003568:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    8000356a:	c115                	beqz	a0,8000358e <ilock+0x30>
    8000356c:	84aa                	mv	s1,a0
    8000356e:	451c                	lw	a5,8(a0)
    80003570:	00f05f63          	blez	a5,8000358e <ilock+0x30>
  acquiresleep(&ip->lock);
    80003574:	0541                	addi	a0,a0,16
    80003576:	00001097          	auipc	ra,0x1
    8000357a:	c7c080e7          	jalr	-900(ra) # 800041f2 <acquiresleep>
  if(ip->valid == 0){
    8000357e:	40bc                	lw	a5,64(s1)
    80003580:	cf99                	beqz	a5,8000359e <ilock+0x40>
}
    80003582:	60e2                	ld	ra,24(sp)
    80003584:	6442                	ld	s0,16(sp)
    80003586:	64a2                	ld	s1,8(sp)
    80003588:	6902                	ld	s2,0(sp)
    8000358a:	6105                	addi	sp,sp,32
    8000358c:	8082                	ret
    panic("ilock");
    8000358e:	00004517          	auipc	a0,0x4
    80003592:	00a50513          	addi	a0,a0,10 # 80007598 <userret+0x508>
    80003596:	ffffd097          	auipc	ra,0xffffd
    8000359a:	fb8080e7          	jalr	-72(ra) # 8000054e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000359e:	40dc                	lw	a5,4(s1)
    800035a0:	0047d79b          	srliw	a5,a5,0x4
    800035a4:	0001d597          	auipc	a1,0x1d
    800035a8:	9445a583          	lw	a1,-1724(a1) # 8001fee8 <sb+0x18>
    800035ac:	9dbd                	addw	a1,a1,a5
    800035ae:	4088                	lw	a0,0(s1)
    800035b0:	fffff097          	auipc	ra,0xfffff
    800035b4:	7ac080e7          	jalr	1964(ra) # 80002d5c <bread>
    800035b8:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800035ba:	06050593          	addi	a1,a0,96
    800035be:	40dc                	lw	a5,4(s1)
    800035c0:	8bbd                	andi	a5,a5,15
    800035c2:	079a                	slli	a5,a5,0x6
    800035c4:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800035c6:	00059783          	lh	a5,0(a1)
    800035ca:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800035ce:	00259783          	lh	a5,2(a1)
    800035d2:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800035d6:	00459783          	lh	a5,4(a1)
    800035da:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800035de:	00659783          	lh	a5,6(a1)
    800035e2:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800035e6:	459c                	lw	a5,8(a1)
    800035e8:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800035ea:	03400613          	li	a2,52
    800035ee:	05b1                	addi	a1,a1,12
    800035f0:	05048513          	addi	a0,s1,80
    800035f4:	ffffd097          	auipc	ra,0xffffd
    800035f8:	5d6080e7          	jalr	1494(ra) # 80000bca <memmove>
    brelse(bp);
    800035fc:	854a                	mv	a0,s2
    800035fe:	00000097          	auipc	ra,0x0
    80003602:	88e080e7          	jalr	-1906(ra) # 80002e8c <brelse>
    ip->valid = 1;
    80003606:	4785                	li	a5,1
    80003608:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    8000360a:	04449783          	lh	a5,68(s1)
    8000360e:	fbb5                	bnez	a5,80003582 <ilock+0x24>
      panic("ilock: no type");
    80003610:	00004517          	auipc	a0,0x4
    80003614:	f9050513          	addi	a0,a0,-112 # 800075a0 <userret+0x510>
    80003618:	ffffd097          	auipc	ra,0xffffd
    8000361c:	f36080e7          	jalr	-202(ra) # 8000054e <panic>

0000000080003620 <iunlock>:
{
    80003620:	1101                	addi	sp,sp,-32
    80003622:	ec06                	sd	ra,24(sp)
    80003624:	e822                	sd	s0,16(sp)
    80003626:	e426                	sd	s1,8(sp)
    80003628:	e04a                	sd	s2,0(sp)
    8000362a:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    8000362c:	c905                	beqz	a0,8000365c <iunlock+0x3c>
    8000362e:	84aa                	mv	s1,a0
    80003630:	01050913          	addi	s2,a0,16
    80003634:	854a                	mv	a0,s2
    80003636:	00001097          	auipc	ra,0x1
    8000363a:	c56080e7          	jalr	-938(ra) # 8000428c <holdingsleep>
    8000363e:	cd19                	beqz	a0,8000365c <iunlock+0x3c>
    80003640:	449c                	lw	a5,8(s1)
    80003642:	00f05d63          	blez	a5,8000365c <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003646:	854a                	mv	a0,s2
    80003648:	00001097          	auipc	ra,0x1
    8000364c:	c00080e7          	jalr	-1024(ra) # 80004248 <releasesleep>
}
    80003650:	60e2                	ld	ra,24(sp)
    80003652:	6442                	ld	s0,16(sp)
    80003654:	64a2                	ld	s1,8(sp)
    80003656:	6902                	ld	s2,0(sp)
    80003658:	6105                	addi	sp,sp,32
    8000365a:	8082                	ret
    panic("iunlock");
    8000365c:	00004517          	auipc	a0,0x4
    80003660:	f5450513          	addi	a0,a0,-172 # 800075b0 <userret+0x520>
    80003664:	ffffd097          	auipc	ra,0xffffd
    80003668:	eea080e7          	jalr	-278(ra) # 8000054e <panic>

000000008000366c <iput>:
{
    8000366c:	7139                	addi	sp,sp,-64
    8000366e:	fc06                	sd	ra,56(sp)
    80003670:	f822                	sd	s0,48(sp)
    80003672:	f426                	sd	s1,40(sp)
    80003674:	f04a                	sd	s2,32(sp)
    80003676:	ec4e                	sd	s3,24(sp)
    80003678:	e852                	sd	s4,16(sp)
    8000367a:	e456                	sd	s5,8(sp)
    8000367c:	0080                	addi	s0,sp,64
    8000367e:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003680:	0001d517          	auipc	a0,0x1d
    80003684:	87050513          	addi	a0,a0,-1936 # 8001fef0 <icache>
    80003688:	ffffd097          	auipc	ra,0xffffd
    8000368c:	446080e7          	jalr	1094(ra) # 80000ace <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003690:	4498                	lw	a4,8(s1)
    80003692:	4785                	li	a5,1
    80003694:	02f70663          	beq	a4,a5,800036c0 <iput+0x54>
  ip->ref--;
    80003698:	449c                	lw	a5,8(s1)
    8000369a:	37fd                	addiw	a5,a5,-1
    8000369c:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    8000369e:	0001d517          	auipc	a0,0x1d
    800036a2:	85250513          	addi	a0,a0,-1966 # 8001fef0 <icache>
    800036a6:	ffffd097          	auipc	ra,0xffffd
    800036aa:	47c080e7          	jalr	1148(ra) # 80000b22 <release>
}
    800036ae:	70e2                	ld	ra,56(sp)
    800036b0:	7442                	ld	s0,48(sp)
    800036b2:	74a2                	ld	s1,40(sp)
    800036b4:	7902                	ld	s2,32(sp)
    800036b6:	69e2                	ld	s3,24(sp)
    800036b8:	6a42                	ld	s4,16(sp)
    800036ba:	6aa2                	ld	s5,8(sp)
    800036bc:	6121                	addi	sp,sp,64
    800036be:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800036c0:	40bc                	lw	a5,64(s1)
    800036c2:	dbf9                	beqz	a5,80003698 <iput+0x2c>
    800036c4:	04a49783          	lh	a5,74(s1)
    800036c8:	fbe1                	bnez	a5,80003698 <iput+0x2c>
    acquiresleep(&ip->lock);
    800036ca:	01048a13          	addi	s4,s1,16
    800036ce:	8552                	mv	a0,s4
    800036d0:	00001097          	auipc	ra,0x1
    800036d4:	b22080e7          	jalr	-1246(ra) # 800041f2 <acquiresleep>
    release(&icache.lock);
    800036d8:	0001d517          	auipc	a0,0x1d
    800036dc:	81850513          	addi	a0,a0,-2024 # 8001fef0 <icache>
    800036e0:	ffffd097          	auipc	ra,0xffffd
    800036e4:	442080e7          	jalr	1090(ra) # 80000b22 <release>
{
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800036e8:	05048913          	addi	s2,s1,80
    800036ec:	08048993          	addi	s3,s1,128
    800036f0:	a819                	j	80003706 <iput+0x9a>
    if(ip->addrs[i]){
      bfree(ip->dev, ip->addrs[i]);
    800036f2:	4088                	lw	a0,0(s1)
    800036f4:	00000097          	auipc	ra,0x0
    800036f8:	8ae080e7          	jalr	-1874(ra) # 80002fa2 <bfree>
      ip->addrs[i] = 0;
    800036fc:	00092023          	sw	zero,0(s2)
  for(i = 0; i < NDIRECT; i++){
    80003700:	0911                	addi	s2,s2,4
    80003702:	01390663          	beq	s2,s3,8000370e <iput+0xa2>
    if(ip->addrs[i]){
    80003706:	00092583          	lw	a1,0(s2)
    8000370a:	d9fd                	beqz	a1,80003700 <iput+0x94>
    8000370c:	b7dd                	j	800036f2 <iput+0x86>
    }
  }

  if(ip->addrs[NDIRECT]){
    8000370e:	0804a583          	lw	a1,128(s1)
    80003712:	ed9d                	bnez	a1,80003750 <iput+0xe4>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003714:	0404a623          	sw	zero,76(s1)
  iupdate(ip);
    80003718:	8526                	mv	a0,s1
    8000371a:	00000097          	auipc	ra,0x0
    8000371e:	d7a080e7          	jalr	-646(ra) # 80003494 <iupdate>
    ip->type = 0;
    80003722:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003726:	8526                	mv	a0,s1
    80003728:	00000097          	auipc	ra,0x0
    8000372c:	d6c080e7          	jalr	-660(ra) # 80003494 <iupdate>
    ip->valid = 0;
    80003730:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003734:	8552                	mv	a0,s4
    80003736:	00001097          	auipc	ra,0x1
    8000373a:	b12080e7          	jalr	-1262(ra) # 80004248 <releasesleep>
    acquire(&icache.lock);
    8000373e:	0001c517          	auipc	a0,0x1c
    80003742:	7b250513          	addi	a0,a0,1970 # 8001fef0 <icache>
    80003746:	ffffd097          	auipc	ra,0xffffd
    8000374a:	388080e7          	jalr	904(ra) # 80000ace <acquire>
    8000374e:	b7a9                	j	80003698 <iput+0x2c>
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003750:	4088                	lw	a0,0(s1)
    80003752:	fffff097          	auipc	ra,0xfffff
    80003756:	60a080e7          	jalr	1546(ra) # 80002d5c <bread>
    8000375a:	8aaa                	mv	s5,a0
    for(j = 0; j < NINDIRECT; j++){
    8000375c:	06050913          	addi	s2,a0,96
    80003760:	46050993          	addi	s3,a0,1120
    80003764:	a809                	j	80003776 <iput+0x10a>
        bfree(ip->dev, a[j]);
    80003766:	4088                	lw	a0,0(s1)
    80003768:	00000097          	auipc	ra,0x0
    8000376c:	83a080e7          	jalr	-1990(ra) # 80002fa2 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003770:	0911                	addi	s2,s2,4
    80003772:	01390663          	beq	s2,s3,8000377e <iput+0x112>
      if(a[j])
    80003776:	00092583          	lw	a1,0(s2)
    8000377a:	d9fd                	beqz	a1,80003770 <iput+0x104>
    8000377c:	b7ed                	j	80003766 <iput+0xfa>
    brelse(bp);
    8000377e:	8556                	mv	a0,s5
    80003780:	fffff097          	auipc	ra,0xfffff
    80003784:	70c080e7          	jalr	1804(ra) # 80002e8c <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003788:	0804a583          	lw	a1,128(s1)
    8000378c:	4088                	lw	a0,0(s1)
    8000378e:	00000097          	auipc	ra,0x0
    80003792:	814080e7          	jalr	-2028(ra) # 80002fa2 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003796:	0804a023          	sw	zero,128(s1)
    8000379a:	bfad                	j	80003714 <iput+0xa8>

000000008000379c <iunlockput>:
{
    8000379c:	1101                	addi	sp,sp,-32
    8000379e:	ec06                	sd	ra,24(sp)
    800037a0:	e822                	sd	s0,16(sp)
    800037a2:	e426                	sd	s1,8(sp)
    800037a4:	1000                	addi	s0,sp,32
    800037a6:	84aa                	mv	s1,a0
  iunlock(ip);
    800037a8:	00000097          	auipc	ra,0x0
    800037ac:	e78080e7          	jalr	-392(ra) # 80003620 <iunlock>
  iput(ip);
    800037b0:	8526                	mv	a0,s1
    800037b2:	00000097          	auipc	ra,0x0
    800037b6:	eba080e7          	jalr	-326(ra) # 8000366c <iput>
}
    800037ba:	60e2                	ld	ra,24(sp)
    800037bc:	6442                	ld	s0,16(sp)
    800037be:	64a2                	ld	s1,8(sp)
    800037c0:	6105                	addi	sp,sp,32
    800037c2:	8082                	ret

00000000800037c4 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    800037c4:	1141                	addi	sp,sp,-16
    800037c6:	e422                	sd	s0,8(sp)
    800037c8:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    800037ca:	411c                	lw	a5,0(a0)
    800037cc:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    800037ce:	415c                	lw	a5,4(a0)
    800037d0:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    800037d2:	04451783          	lh	a5,68(a0)
    800037d6:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    800037da:	04a51783          	lh	a5,74(a0)
    800037de:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    800037e2:	04c56783          	lwu	a5,76(a0)
    800037e6:	e99c                	sd	a5,16(a1)
}
    800037e8:	6422                	ld	s0,8(sp)
    800037ea:	0141                	addi	sp,sp,16
    800037ec:	8082                	ret

00000000800037ee <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800037ee:	457c                	lw	a5,76(a0)
    800037f0:	0ed7e563          	bltu	a5,a3,800038da <readi+0xec>
{
    800037f4:	7159                	addi	sp,sp,-112
    800037f6:	f486                	sd	ra,104(sp)
    800037f8:	f0a2                	sd	s0,96(sp)
    800037fa:	eca6                	sd	s1,88(sp)
    800037fc:	e8ca                	sd	s2,80(sp)
    800037fe:	e4ce                	sd	s3,72(sp)
    80003800:	e0d2                	sd	s4,64(sp)
    80003802:	fc56                	sd	s5,56(sp)
    80003804:	f85a                	sd	s6,48(sp)
    80003806:	f45e                	sd	s7,40(sp)
    80003808:	f062                	sd	s8,32(sp)
    8000380a:	ec66                	sd	s9,24(sp)
    8000380c:	e86a                	sd	s10,16(sp)
    8000380e:	e46e                	sd	s11,8(sp)
    80003810:	1880                	addi	s0,sp,112
    80003812:	8baa                	mv	s7,a0
    80003814:	8c2e                	mv	s8,a1
    80003816:	8ab2                	mv	s5,a2
    80003818:	8936                	mv	s2,a3
    8000381a:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    8000381c:	9f35                	addw	a4,a4,a3
    8000381e:	0cd76063          	bltu	a4,a3,800038de <readi+0xf0>
    return -1;
  if(off + n > ip->size)
    80003822:	00e7f463          	bgeu	a5,a4,8000382a <readi+0x3c>
    n = ip->size - off;
    80003826:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000382a:	080b0763          	beqz	s6,800038b8 <readi+0xca>
    8000382e:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003830:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003834:	5cfd                	li	s9,-1
    80003836:	a82d                	j	80003870 <readi+0x82>
    80003838:	02099d93          	slli	s11,s3,0x20
    8000383c:	020ddd93          	srli	s11,s11,0x20
    80003840:	06048613          	addi	a2,s1,96
    80003844:	86ee                	mv	a3,s11
    80003846:	963a                	add	a2,a2,a4
    80003848:	85d6                	mv	a1,s5
    8000384a:	8562                	mv	a0,s8
    8000384c:	fffff097          	auipc	ra,0xfffff
    80003850:	9f6080e7          	jalr	-1546(ra) # 80002242 <either_copyout>
    80003854:	05950d63          	beq	a0,s9,800038ae <readi+0xc0>
      brelse(bp);
      break;
    }
    brelse(bp);
    80003858:	8526                	mv	a0,s1
    8000385a:	fffff097          	auipc	ra,0xfffff
    8000385e:	632080e7          	jalr	1586(ra) # 80002e8c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003862:	01498a3b          	addw	s4,s3,s4
    80003866:	0129893b          	addw	s2,s3,s2
    8000386a:	9aee                	add	s5,s5,s11
    8000386c:	056a7663          	bgeu	s4,s6,800038b8 <readi+0xca>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003870:	000ba483          	lw	s1,0(s7)
    80003874:	00a9559b          	srliw	a1,s2,0xa
    80003878:	855e                	mv	a0,s7
    8000387a:	00000097          	auipc	ra,0x0
    8000387e:	8d6080e7          	jalr	-1834(ra) # 80003150 <bmap>
    80003882:	0005059b          	sext.w	a1,a0
    80003886:	8526                	mv	a0,s1
    80003888:	fffff097          	auipc	ra,0xfffff
    8000388c:	4d4080e7          	jalr	1236(ra) # 80002d5c <bread>
    80003890:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003892:	3ff97713          	andi	a4,s2,1023
    80003896:	40ed07bb          	subw	a5,s10,a4
    8000389a:	414b06bb          	subw	a3,s6,s4
    8000389e:	89be                	mv	s3,a5
    800038a0:	2781                	sext.w	a5,a5
    800038a2:	0006861b          	sext.w	a2,a3
    800038a6:	f8f679e3          	bgeu	a2,a5,80003838 <readi+0x4a>
    800038aa:	89b6                	mv	s3,a3
    800038ac:	b771                	j	80003838 <readi+0x4a>
      brelse(bp);
    800038ae:	8526                	mv	a0,s1
    800038b0:	fffff097          	auipc	ra,0xfffff
    800038b4:	5dc080e7          	jalr	1500(ra) # 80002e8c <brelse>
  }
  return n;
    800038b8:	000b051b          	sext.w	a0,s6
}
    800038bc:	70a6                	ld	ra,104(sp)
    800038be:	7406                	ld	s0,96(sp)
    800038c0:	64e6                	ld	s1,88(sp)
    800038c2:	6946                	ld	s2,80(sp)
    800038c4:	69a6                	ld	s3,72(sp)
    800038c6:	6a06                	ld	s4,64(sp)
    800038c8:	7ae2                	ld	s5,56(sp)
    800038ca:	7b42                	ld	s6,48(sp)
    800038cc:	7ba2                	ld	s7,40(sp)
    800038ce:	7c02                	ld	s8,32(sp)
    800038d0:	6ce2                	ld	s9,24(sp)
    800038d2:	6d42                	ld	s10,16(sp)
    800038d4:	6da2                	ld	s11,8(sp)
    800038d6:	6165                	addi	sp,sp,112
    800038d8:	8082                	ret
    return -1;
    800038da:	557d                	li	a0,-1
}
    800038dc:	8082                	ret
    return -1;
    800038de:	557d                	li	a0,-1
    800038e0:	bff1                	j	800038bc <readi+0xce>

00000000800038e2 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800038e2:	457c                	lw	a5,76(a0)
    800038e4:	10d7e663          	bltu	a5,a3,800039f0 <writei+0x10e>
{
    800038e8:	7159                	addi	sp,sp,-112
    800038ea:	f486                	sd	ra,104(sp)
    800038ec:	f0a2                	sd	s0,96(sp)
    800038ee:	eca6                	sd	s1,88(sp)
    800038f0:	e8ca                	sd	s2,80(sp)
    800038f2:	e4ce                	sd	s3,72(sp)
    800038f4:	e0d2                	sd	s4,64(sp)
    800038f6:	fc56                	sd	s5,56(sp)
    800038f8:	f85a                	sd	s6,48(sp)
    800038fa:	f45e                	sd	s7,40(sp)
    800038fc:	f062                	sd	s8,32(sp)
    800038fe:	ec66                	sd	s9,24(sp)
    80003900:	e86a                	sd	s10,16(sp)
    80003902:	e46e                	sd	s11,8(sp)
    80003904:	1880                	addi	s0,sp,112
    80003906:	8baa                	mv	s7,a0
    80003908:	8c2e                	mv	s8,a1
    8000390a:	8ab2                	mv	s5,a2
    8000390c:	8936                	mv	s2,a3
    8000390e:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003910:	00e687bb          	addw	a5,a3,a4
    80003914:	0ed7e063          	bltu	a5,a3,800039f4 <writei+0x112>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003918:	00043737          	lui	a4,0x43
    8000391c:	0cf76e63          	bltu	a4,a5,800039f8 <writei+0x116>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003920:	0a0b0763          	beqz	s6,800039ce <writei+0xec>
    80003924:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003926:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    8000392a:	5cfd                	li	s9,-1
    8000392c:	a091                	j	80003970 <writei+0x8e>
    8000392e:	02099d93          	slli	s11,s3,0x20
    80003932:	020ddd93          	srli	s11,s11,0x20
    80003936:	06048513          	addi	a0,s1,96
    8000393a:	86ee                	mv	a3,s11
    8000393c:	8656                	mv	a2,s5
    8000393e:	85e2                	mv	a1,s8
    80003940:	953a                	add	a0,a0,a4
    80003942:	fffff097          	auipc	ra,0xfffff
    80003946:	956080e7          	jalr	-1706(ra) # 80002298 <either_copyin>
    8000394a:	07950263          	beq	a0,s9,800039ae <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    8000394e:	8526                	mv	a0,s1
    80003950:	00000097          	auipc	ra,0x0
    80003954:	77a080e7          	jalr	1914(ra) # 800040ca <log_write>
    brelse(bp);
    80003958:	8526                	mv	a0,s1
    8000395a:	fffff097          	auipc	ra,0xfffff
    8000395e:	532080e7          	jalr	1330(ra) # 80002e8c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003962:	01498a3b          	addw	s4,s3,s4
    80003966:	0129893b          	addw	s2,s3,s2
    8000396a:	9aee                	add	s5,s5,s11
    8000396c:	056a7663          	bgeu	s4,s6,800039b8 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003970:	000ba483          	lw	s1,0(s7)
    80003974:	00a9559b          	srliw	a1,s2,0xa
    80003978:	855e                	mv	a0,s7
    8000397a:	fffff097          	auipc	ra,0xfffff
    8000397e:	7d6080e7          	jalr	2006(ra) # 80003150 <bmap>
    80003982:	0005059b          	sext.w	a1,a0
    80003986:	8526                	mv	a0,s1
    80003988:	fffff097          	auipc	ra,0xfffff
    8000398c:	3d4080e7          	jalr	980(ra) # 80002d5c <bread>
    80003990:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003992:	3ff97713          	andi	a4,s2,1023
    80003996:	40ed07bb          	subw	a5,s10,a4
    8000399a:	414b06bb          	subw	a3,s6,s4
    8000399e:	89be                	mv	s3,a5
    800039a0:	2781                	sext.w	a5,a5
    800039a2:	0006861b          	sext.w	a2,a3
    800039a6:	f8f674e3          	bgeu	a2,a5,8000392e <writei+0x4c>
    800039aa:	89b6                	mv	s3,a3
    800039ac:	b749                	j	8000392e <writei+0x4c>
      brelse(bp);
    800039ae:	8526                	mv	a0,s1
    800039b0:	fffff097          	auipc	ra,0xfffff
    800039b4:	4dc080e7          	jalr	1244(ra) # 80002e8c <brelse>
  }

  if(n > 0){
    if(off > ip->size)
    800039b8:	04cba783          	lw	a5,76(s7)
    800039bc:	0127f463          	bgeu	a5,s2,800039c4 <writei+0xe2>
      ip->size = off;
    800039c0:	052ba623          	sw	s2,76(s7)
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
    800039c4:	855e                	mv	a0,s7
    800039c6:	00000097          	auipc	ra,0x0
    800039ca:	ace080e7          	jalr	-1330(ra) # 80003494 <iupdate>
  }

  return n;
    800039ce:	000b051b          	sext.w	a0,s6
}
    800039d2:	70a6                	ld	ra,104(sp)
    800039d4:	7406                	ld	s0,96(sp)
    800039d6:	64e6                	ld	s1,88(sp)
    800039d8:	6946                	ld	s2,80(sp)
    800039da:	69a6                	ld	s3,72(sp)
    800039dc:	6a06                	ld	s4,64(sp)
    800039de:	7ae2                	ld	s5,56(sp)
    800039e0:	7b42                	ld	s6,48(sp)
    800039e2:	7ba2                	ld	s7,40(sp)
    800039e4:	7c02                	ld	s8,32(sp)
    800039e6:	6ce2                	ld	s9,24(sp)
    800039e8:	6d42                	ld	s10,16(sp)
    800039ea:	6da2                	ld	s11,8(sp)
    800039ec:	6165                	addi	sp,sp,112
    800039ee:	8082                	ret
    return -1;
    800039f0:	557d                	li	a0,-1
}
    800039f2:	8082                	ret
    return -1;
    800039f4:	557d                	li	a0,-1
    800039f6:	bff1                	j	800039d2 <writei+0xf0>
    return -1;
    800039f8:	557d                	li	a0,-1
    800039fa:	bfe1                	j	800039d2 <writei+0xf0>

00000000800039fc <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    800039fc:	1141                	addi	sp,sp,-16
    800039fe:	e406                	sd	ra,8(sp)
    80003a00:	e022                	sd	s0,0(sp)
    80003a02:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003a04:	4639                	li	a2,14
    80003a06:	ffffd097          	auipc	ra,0xffffd
    80003a0a:	240080e7          	jalr	576(ra) # 80000c46 <strncmp>
}
    80003a0e:	60a2                	ld	ra,8(sp)
    80003a10:	6402                	ld	s0,0(sp)
    80003a12:	0141                	addi	sp,sp,16
    80003a14:	8082                	ret

0000000080003a16 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003a16:	7139                	addi	sp,sp,-64
    80003a18:	fc06                	sd	ra,56(sp)
    80003a1a:	f822                	sd	s0,48(sp)
    80003a1c:	f426                	sd	s1,40(sp)
    80003a1e:	f04a                	sd	s2,32(sp)
    80003a20:	ec4e                	sd	s3,24(sp)
    80003a22:	e852                	sd	s4,16(sp)
    80003a24:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003a26:	04451703          	lh	a4,68(a0)
    80003a2a:	4785                	li	a5,1
    80003a2c:	00f71a63          	bne	a4,a5,80003a40 <dirlookup+0x2a>
    80003a30:	892a                	mv	s2,a0
    80003a32:	89ae                	mv	s3,a1
    80003a34:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003a36:	457c                	lw	a5,76(a0)
    80003a38:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003a3a:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003a3c:	e79d                	bnez	a5,80003a6a <dirlookup+0x54>
    80003a3e:	a8a5                	j	80003ab6 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003a40:	00004517          	auipc	a0,0x4
    80003a44:	b7850513          	addi	a0,a0,-1160 # 800075b8 <userret+0x528>
    80003a48:	ffffd097          	auipc	ra,0xffffd
    80003a4c:	b06080e7          	jalr	-1274(ra) # 8000054e <panic>
      panic("dirlookup read");
    80003a50:	00004517          	auipc	a0,0x4
    80003a54:	b8050513          	addi	a0,a0,-1152 # 800075d0 <userret+0x540>
    80003a58:	ffffd097          	auipc	ra,0xffffd
    80003a5c:	af6080e7          	jalr	-1290(ra) # 8000054e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003a60:	24c1                	addiw	s1,s1,16
    80003a62:	04c92783          	lw	a5,76(s2)
    80003a66:	04f4f763          	bgeu	s1,a5,80003ab4 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003a6a:	4741                	li	a4,16
    80003a6c:	86a6                	mv	a3,s1
    80003a6e:	fc040613          	addi	a2,s0,-64
    80003a72:	4581                	li	a1,0
    80003a74:	854a                	mv	a0,s2
    80003a76:	00000097          	auipc	ra,0x0
    80003a7a:	d78080e7          	jalr	-648(ra) # 800037ee <readi>
    80003a7e:	47c1                	li	a5,16
    80003a80:	fcf518e3          	bne	a0,a5,80003a50 <dirlookup+0x3a>
    if(de.inum == 0)
    80003a84:	fc045783          	lhu	a5,-64(s0)
    80003a88:	dfe1                	beqz	a5,80003a60 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003a8a:	fc240593          	addi	a1,s0,-62
    80003a8e:	854e                	mv	a0,s3
    80003a90:	00000097          	auipc	ra,0x0
    80003a94:	f6c080e7          	jalr	-148(ra) # 800039fc <namecmp>
    80003a98:	f561                	bnez	a0,80003a60 <dirlookup+0x4a>
      if(poff)
    80003a9a:	000a0463          	beqz	s4,80003aa2 <dirlookup+0x8c>
        *poff = off;
    80003a9e:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003aa2:	fc045583          	lhu	a1,-64(s0)
    80003aa6:	00092503          	lw	a0,0(s2)
    80003aaa:	fffff097          	auipc	ra,0xfffff
    80003aae:	780080e7          	jalr	1920(ra) # 8000322a <iget>
    80003ab2:	a011                	j	80003ab6 <dirlookup+0xa0>
  return 0;
    80003ab4:	4501                	li	a0,0
}
    80003ab6:	70e2                	ld	ra,56(sp)
    80003ab8:	7442                	ld	s0,48(sp)
    80003aba:	74a2                	ld	s1,40(sp)
    80003abc:	7902                	ld	s2,32(sp)
    80003abe:	69e2                	ld	s3,24(sp)
    80003ac0:	6a42                	ld	s4,16(sp)
    80003ac2:	6121                	addi	sp,sp,64
    80003ac4:	8082                	ret

0000000080003ac6 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003ac6:	711d                	addi	sp,sp,-96
    80003ac8:	ec86                	sd	ra,88(sp)
    80003aca:	e8a2                	sd	s0,80(sp)
    80003acc:	e4a6                	sd	s1,72(sp)
    80003ace:	e0ca                	sd	s2,64(sp)
    80003ad0:	fc4e                	sd	s3,56(sp)
    80003ad2:	f852                	sd	s4,48(sp)
    80003ad4:	f456                	sd	s5,40(sp)
    80003ad6:	f05a                	sd	s6,32(sp)
    80003ad8:	ec5e                	sd	s7,24(sp)
    80003ada:	e862                	sd	s8,16(sp)
    80003adc:	e466                	sd	s9,8(sp)
    80003ade:	1080                	addi	s0,sp,96
    80003ae0:	84aa                	mv	s1,a0
    80003ae2:	8b2e                	mv	s6,a1
    80003ae4:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003ae6:	00054703          	lbu	a4,0(a0)
    80003aea:	02f00793          	li	a5,47
    80003aee:	02f70363          	beq	a4,a5,80003b14 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003af2:	ffffe097          	auipc	ra,0xffffe
    80003af6:	d4e080e7          	jalr	-690(ra) # 80001840 <myproc>
    80003afa:	15053503          	ld	a0,336(a0)
    80003afe:	00000097          	auipc	ra,0x0
    80003b02:	a22080e7          	jalr	-1502(ra) # 80003520 <idup>
    80003b06:	89aa                	mv	s3,a0
  while(*path == '/')
    80003b08:	02f00913          	li	s2,47
  len = path - s;
    80003b0c:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003b0e:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003b10:	4c05                	li	s8,1
    80003b12:	a865                	j	80003bca <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003b14:	4585                	li	a1,1
    80003b16:	4505                	li	a0,1
    80003b18:	fffff097          	auipc	ra,0xfffff
    80003b1c:	712080e7          	jalr	1810(ra) # 8000322a <iget>
    80003b20:	89aa                	mv	s3,a0
    80003b22:	b7dd                	j	80003b08 <namex+0x42>
      iunlockput(ip);
    80003b24:	854e                	mv	a0,s3
    80003b26:	00000097          	auipc	ra,0x0
    80003b2a:	c76080e7          	jalr	-906(ra) # 8000379c <iunlockput>
      return 0;
    80003b2e:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003b30:	854e                	mv	a0,s3
    80003b32:	60e6                	ld	ra,88(sp)
    80003b34:	6446                	ld	s0,80(sp)
    80003b36:	64a6                	ld	s1,72(sp)
    80003b38:	6906                	ld	s2,64(sp)
    80003b3a:	79e2                	ld	s3,56(sp)
    80003b3c:	7a42                	ld	s4,48(sp)
    80003b3e:	7aa2                	ld	s5,40(sp)
    80003b40:	7b02                	ld	s6,32(sp)
    80003b42:	6be2                	ld	s7,24(sp)
    80003b44:	6c42                	ld	s8,16(sp)
    80003b46:	6ca2                	ld	s9,8(sp)
    80003b48:	6125                	addi	sp,sp,96
    80003b4a:	8082                	ret
      iunlock(ip);
    80003b4c:	854e                	mv	a0,s3
    80003b4e:	00000097          	auipc	ra,0x0
    80003b52:	ad2080e7          	jalr	-1326(ra) # 80003620 <iunlock>
      return ip;
    80003b56:	bfe9                	j	80003b30 <namex+0x6a>
      iunlockput(ip);
    80003b58:	854e                	mv	a0,s3
    80003b5a:	00000097          	auipc	ra,0x0
    80003b5e:	c42080e7          	jalr	-958(ra) # 8000379c <iunlockput>
      return 0;
    80003b62:	89d2                	mv	s3,s4
    80003b64:	b7f1                	j	80003b30 <namex+0x6a>
  len = path - s;
    80003b66:	40b48633          	sub	a2,s1,a1
    80003b6a:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003b6e:	094cd463          	bge	s9,s4,80003bf6 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003b72:	4639                	li	a2,14
    80003b74:	8556                	mv	a0,s5
    80003b76:	ffffd097          	auipc	ra,0xffffd
    80003b7a:	054080e7          	jalr	84(ra) # 80000bca <memmove>
  while(*path == '/')
    80003b7e:	0004c783          	lbu	a5,0(s1)
    80003b82:	01279763          	bne	a5,s2,80003b90 <namex+0xca>
    path++;
    80003b86:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003b88:	0004c783          	lbu	a5,0(s1)
    80003b8c:	ff278de3          	beq	a5,s2,80003b86 <namex+0xc0>
    ilock(ip);
    80003b90:	854e                	mv	a0,s3
    80003b92:	00000097          	auipc	ra,0x0
    80003b96:	9cc080e7          	jalr	-1588(ra) # 8000355e <ilock>
    if(ip->type != T_DIR){
    80003b9a:	04499783          	lh	a5,68(s3)
    80003b9e:	f98793e3          	bne	a5,s8,80003b24 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003ba2:	000b0563          	beqz	s6,80003bac <namex+0xe6>
    80003ba6:	0004c783          	lbu	a5,0(s1)
    80003baa:	d3cd                	beqz	a5,80003b4c <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003bac:	865e                	mv	a2,s7
    80003bae:	85d6                	mv	a1,s5
    80003bb0:	854e                	mv	a0,s3
    80003bb2:	00000097          	auipc	ra,0x0
    80003bb6:	e64080e7          	jalr	-412(ra) # 80003a16 <dirlookup>
    80003bba:	8a2a                	mv	s4,a0
    80003bbc:	dd51                	beqz	a0,80003b58 <namex+0x92>
    iunlockput(ip);
    80003bbe:	854e                	mv	a0,s3
    80003bc0:	00000097          	auipc	ra,0x0
    80003bc4:	bdc080e7          	jalr	-1060(ra) # 8000379c <iunlockput>
    ip = next;
    80003bc8:	89d2                	mv	s3,s4
  while(*path == '/')
    80003bca:	0004c783          	lbu	a5,0(s1)
    80003bce:	05279763          	bne	a5,s2,80003c1c <namex+0x156>
    path++;
    80003bd2:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003bd4:	0004c783          	lbu	a5,0(s1)
    80003bd8:	ff278de3          	beq	a5,s2,80003bd2 <namex+0x10c>
  if(*path == 0)
    80003bdc:	c79d                	beqz	a5,80003c0a <namex+0x144>
    path++;
    80003bde:	85a6                	mv	a1,s1
  len = path - s;
    80003be0:	8a5e                	mv	s4,s7
    80003be2:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003be4:	01278963          	beq	a5,s2,80003bf6 <namex+0x130>
    80003be8:	dfbd                	beqz	a5,80003b66 <namex+0xa0>
    path++;
    80003bea:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003bec:	0004c783          	lbu	a5,0(s1)
    80003bf0:	ff279ce3          	bne	a5,s2,80003be8 <namex+0x122>
    80003bf4:	bf8d                	j	80003b66 <namex+0xa0>
    memmove(name, s, len);
    80003bf6:	2601                	sext.w	a2,a2
    80003bf8:	8556                	mv	a0,s5
    80003bfa:	ffffd097          	auipc	ra,0xffffd
    80003bfe:	fd0080e7          	jalr	-48(ra) # 80000bca <memmove>
    name[len] = 0;
    80003c02:	9a56                	add	s4,s4,s5
    80003c04:	000a0023          	sb	zero,0(s4)
    80003c08:	bf9d                	j	80003b7e <namex+0xb8>
  if(nameiparent){
    80003c0a:	f20b03e3          	beqz	s6,80003b30 <namex+0x6a>
    iput(ip);
    80003c0e:	854e                	mv	a0,s3
    80003c10:	00000097          	auipc	ra,0x0
    80003c14:	a5c080e7          	jalr	-1444(ra) # 8000366c <iput>
    return 0;
    80003c18:	4981                	li	s3,0
    80003c1a:	bf19                	j	80003b30 <namex+0x6a>
  if(*path == 0)
    80003c1c:	d7fd                	beqz	a5,80003c0a <namex+0x144>
  while(*path != '/' && *path != 0)
    80003c1e:	0004c783          	lbu	a5,0(s1)
    80003c22:	85a6                	mv	a1,s1
    80003c24:	b7d1                	j	80003be8 <namex+0x122>

0000000080003c26 <dirlink>:
{
    80003c26:	7139                	addi	sp,sp,-64
    80003c28:	fc06                	sd	ra,56(sp)
    80003c2a:	f822                	sd	s0,48(sp)
    80003c2c:	f426                	sd	s1,40(sp)
    80003c2e:	f04a                	sd	s2,32(sp)
    80003c30:	ec4e                	sd	s3,24(sp)
    80003c32:	e852                	sd	s4,16(sp)
    80003c34:	0080                	addi	s0,sp,64
    80003c36:	892a                	mv	s2,a0
    80003c38:	8a2e                	mv	s4,a1
    80003c3a:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003c3c:	4601                	li	a2,0
    80003c3e:	00000097          	auipc	ra,0x0
    80003c42:	dd8080e7          	jalr	-552(ra) # 80003a16 <dirlookup>
    80003c46:	e93d                	bnez	a0,80003cbc <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c48:	04c92483          	lw	s1,76(s2)
    80003c4c:	c49d                	beqz	s1,80003c7a <dirlink+0x54>
    80003c4e:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003c50:	4741                	li	a4,16
    80003c52:	86a6                	mv	a3,s1
    80003c54:	fc040613          	addi	a2,s0,-64
    80003c58:	4581                	li	a1,0
    80003c5a:	854a                	mv	a0,s2
    80003c5c:	00000097          	auipc	ra,0x0
    80003c60:	b92080e7          	jalr	-1134(ra) # 800037ee <readi>
    80003c64:	47c1                	li	a5,16
    80003c66:	06f51163          	bne	a0,a5,80003cc8 <dirlink+0xa2>
    if(de.inum == 0)
    80003c6a:	fc045783          	lhu	a5,-64(s0)
    80003c6e:	c791                	beqz	a5,80003c7a <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c70:	24c1                	addiw	s1,s1,16
    80003c72:	04c92783          	lw	a5,76(s2)
    80003c76:	fcf4ede3          	bltu	s1,a5,80003c50 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003c7a:	4639                	li	a2,14
    80003c7c:	85d2                	mv	a1,s4
    80003c7e:	fc240513          	addi	a0,s0,-62
    80003c82:	ffffd097          	auipc	ra,0xffffd
    80003c86:	000080e7          	jalr	ra # 80000c82 <strncpy>
  de.inum = inum;
    80003c8a:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003c8e:	4741                	li	a4,16
    80003c90:	86a6                	mv	a3,s1
    80003c92:	fc040613          	addi	a2,s0,-64
    80003c96:	4581                	li	a1,0
    80003c98:	854a                	mv	a0,s2
    80003c9a:	00000097          	auipc	ra,0x0
    80003c9e:	c48080e7          	jalr	-952(ra) # 800038e2 <writei>
    80003ca2:	872a                	mv	a4,a0
    80003ca4:	47c1                	li	a5,16
  return 0;
    80003ca6:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ca8:	02f71863          	bne	a4,a5,80003cd8 <dirlink+0xb2>
}
    80003cac:	70e2                	ld	ra,56(sp)
    80003cae:	7442                	ld	s0,48(sp)
    80003cb0:	74a2                	ld	s1,40(sp)
    80003cb2:	7902                	ld	s2,32(sp)
    80003cb4:	69e2                	ld	s3,24(sp)
    80003cb6:	6a42                	ld	s4,16(sp)
    80003cb8:	6121                	addi	sp,sp,64
    80003cba:	8082                	ret
    iput(ip);
    80003cbc:	00000097          	auipc	ra,0x0
    80003cc0:	9b0080e7          	jalr	-1616(ra) # 8000366c <iput>
    return -1;
    80003cc4:	557d                	li	a0,-1
    80003cc6:	b7dd                	j	80003cac <dirlink+0x86>
      panic("dirlink read");
    80003cc8:	00004517          	auipc	a0,0x4
    80003ccc:	91850513          	addi	a0,a0,-1768 # 800075e0 <userret+0x550>
    80003cd0:	ffffd097          	auipc	ra,0xffffd
    80003cd4:	87e080e7          	jalr	-1922(ra) # 8000054e <panic>
    panic("dirlink");
    80003cd8:	00004517          	auipc	a0,0x4
    80003cdc:	a2850513          	addi	a0,a0,-1496 # 80007700 <userret+0x670>
    80003ce0:	ffffd097          	auipc	ra,0xffffd
    80003ce4:	86e080e7          	jalr	-1938(ra) # 8000054e <panic>

0000000080003ce8 <namei>:

struct inode*
namei(char *path)
{
    80003ce8:	1101                	addi	sp,sp,-32
    80003cea:	ec06                	sd	ra,24(sp)
    80003cec:	e822                	sd	s0,16(sp)
    80003cee:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003cf0:	fe040613          	addi	a2,s0,-32
    80003cf4:	4581                	li	a1,0
    80003cf6:	00000097          	auipc	ra,0x0
    80003cfa:	dd0080e7          	jalr	-560(ra) # 80003ac6 <namex>
}
    80003cfe:	60e2                	ld	ra,24(sp)
    80003d00:	6442                	ld	s0,16(sp)
    80003d02:	6105                	addi	sp,sp,32
    80003d04:	8082                	ret

0000000080003d06 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003d06:	1141                	addi	sp,sp,-16
    80003d08:	e406                	sd	ra,8(sp)
    80003d0a:	e022                	sd	s0,0(sp)
    80003d0c:	0800                	addi	s0,sp,16
    80003d0e:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003d10:	4585                	li	a1,1
    80003d12:	00000097          	auipc	ra,0x0
    80003d16:	db4080e7          	jalr	-588(ra) # 80003ac6 <namex>
}
    80003d1a:	60a2                	ld	ra,8(sp)
    80003d1c:	6402                	ld	s0,0(sp)
    80003d1e:	0141                	addi	sp,sp,16
    80003d20:	8082                	ret

0000000080003d22 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003d22:	1101                	addi	sp,sp,-32
    80003d24:	ec06                	sd	ra,24(sp)
    80003d26:	e822                	sd	s0,16(sp)
    80003d28:	e426                	sd	s1,8(sp)
    80003d2a:	e04a                	sd	s2,0(sp)
    80003d2c:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003d2e:	0001e917          	auipc	s2,0x1e
    80003d32:	c6a90913          	addi	s2,s2,-918 # 80021998 <log>
    80003d36:	01892583          	lw	a1,24(s2)
    80003d3a:	02892503          	lw	a0,40(s2)
    80003d3e:	fffff097          	auipc	ra,0xfffff
    80003d42:	01e080e7          	jalr	30(ra) # 80002d5c <bread>
    80003d46:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003d48:	02c92683          	lw	a3,44(s2)
    80003d4c:	d134                	sw	a3,96(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003d4e:	02d05763          	blez	a3,80003d7c <write_head+0x5a>
    80003d52:	0001e797          	auipc	a5,0x1e
    80003d56:	c7678793          	addi	a5,a5,-906 # 800219c8 <log+0x30>
    80003d5a:	06450713          	addi	a4,a0,100
    80003d5e:	36fd                	addiw	a3,a3,-1
    80003d60:	1682                	slli	a3,a3,0x20
    80003d62:	9281                	srli	a3,a3,0x20
    80003d64:	068a                	slli	a3,a3,0x2
    80003d66:	0001e617          	auipc	a2,0x1e
    80003d6a:	c6660613          	addi	a2,a2,-922 # 800219cc <log+0x34>
    80003d6e:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003d70:	4390                	lw	a2,0(a5)
    80003d72:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003d74:	0791                	addi	a5,a5,4
    80003d76:	0711                	addi	a4,a4,4
    80003d78:	fed79ce3          	bne	a5,a3,80003d70 <write_head+0x4e>
  }
  bwrite(buf);
    80003d7c:	8526                	mv	a0,s1
    80003d7e:	fffff097          	auipc	ra,0xfffff
    80003d82:	0d0080e7          	jalr	208(ra) # 80002e4e <bwrite>
  brelse(buf);
    80003d86:	8526                	mv	a0,s1
    80003d88:	fffff097          	auipc	ra,0xfffff
    80003d8c:	104080e7          	jalr	260(ra) # 80002e8c <brelse>
}
    80003d90:	60e2                	ld	ra,24(sp)
    80003d92:	6442                	ld	s0,16(sp)
    80003d94:	64a2                	ld	s1,8(sp)
    80003d96:	6902                	ld	s2,0(sp)
    80003d98:	6105                	addi	sp,sp,32
    80003d9a:	8082                	ret

0000000080003d9c <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003d9c:	0001e797          	auipc	a5,0x1e
    80003da0:	c287a783          	lw	a5,-984(a5) # 800219c4 <log+0x2c>
    80003da4:	0af05663          	blez	a5,80003e50 <install_trans+0xb4>
{
    80003da8:	7139                	addi	sp,sp,-64
    80003daa:	fc06                	sd	ra,56(sp)
    80003dac:	f822                	sd	s0,48(sp)
    80003dae:	f426                	sd	s1,40(sp)
    80003db0:	f04a                	sd	s2,32(sp)
    80003db2:	ec4e                	sd	s3,24(sp)
    80003db4:	e852                	sd	s4,16(sp)
    80003db6:	e456                	sd	s5,8(sp)
    80003db8:	0080                	addi	s0,sp,64
    80003dba:	0001ea97          	auipc	s5,0x1e
    80003dbe:	c0ea8a93          	addi	s5,s5,-1010 # 800219c8 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003dc2:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003dc4:	0001e997          	auipc	s3,0x1e
    80003dc8:	bd498993          	addi	s3,s3,-1068 # 80021998 <log>
    80003dcc:	0189a583          	lw	a1,24(s3)
    80003dd0:	014585bb          	addw	a1,a1,s4
    80003dd4:	2585                	addiw	a1,a1,1
    80003dd6:	0289a503          	lw	a0,40(s3)
    80003dda:	fffff097          	auipc	ra,0xfffff
    80003dde:	f82080e7          	jalr	-126(ra) # 80002d5c <bread>
    80003de2:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80003de4:	000aa583          	lw	a1,0(s5)
    80003de8:	0289a503          	lw	a0,40(s3)
    80003dec:	fffff097          	auipc	ra,0xfffff
    80003df0:	f70080e7          	jalr	-144(ra) # 80002d5c <bread>
    80003df4:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80003df6:	40000613          	li	a2,1024
    80003dfa:	06090593          	addi	a1,s2,96
    80003dfe:	06050513          	addi	a0,a0,96
    80003e02:	ffffd097          	auipc	ra,0xffffd
    80003e06:	dc8080e7          	jalr	-568(ra) # 80000bca <memmove>
    bwrite(dbuf);  // write dst to disk
    80003e0a:	8526                	mv	a0,s1
    80003e0c:	fffff097          	auipc	ra,0xfffff
    80003e10:	042080e7          	jalr	66(ra) # 80002e4e <bwrite>
    bunpin(dbuf);
    80003e14:	8526                	mv	a0,s1
    80003e16:	fffff097          	auipc	ra,0xfffff
    80003e1a:	150080e7          	jalr	336(ra) # 80002f66 <bunpin>
    brelse(lbuf);
    80003e1e:	854a                	mv	a0,s2
    80003e20:	fffff097          	auipc	ra,0xfffff
    80003e24:	06c080e7          	jalr	108(ra) # 80002e8c <brelse>
    brelse(dbuf);
    80003e28:	8526                	mv	a0,s1
    80003e2a:	fffff097          	auipc	ra,0xfffff
    80003e2e:	062080e7          	jalr	98(ra) # 80002e8c <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003e32:	2a05                	addiw	s4,s4,1
    80003e34:	0a91                	addi	s5,s5,4
    80003e36:	02c9a783          	lw	a5,44(s3)
    80003e3a:	f8fa49e3          	blt	s4,a5,80003dcc <install_trans+0x30>
}
    80003e3e:	70e2                	ld	ra,56(sp)
    80003e40:	7442                	ld	s0,48(sp)
    80003e42:	74a2                	ld	s1,40(sp)
    80003e44:	7902                	ld	s2,32(sp)
    80003e46:	69e2                	ld	s3,24(sp)
    80003e48:	6a42                	ld	s4,16(sp)
    80003e4a:	6aa2                	ld	s5,8(sp)
    80003e4c:	6121                	addi	sp,sp,64
    80003e4e:	8082                	ret
    80003e50:	8082                	ret

0000000080003e52 <initlog>:
{
    80003e52:	7179                	addi	sp,sp,-48
    80003e54:	f406                	sd	ra,40(sp)
    80003e56:	f022                	sd	s0,32(sp)
    80003e58:	ec26                	sd	s1,24(sp)
    80003e5a:	e84a                	sd	s2,16(sp)
    80003e5c:	e44e                	sd	s3,8(sp)
    80003e5e:	1800                	addi	s0,sp,48
    80003e60:	892a                	mv	s2,a0
    80003e62:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80003e64:	0001e497          	auipc	s1,0x1e
    80003e68:	b3448493          	addi	s1,s1,-1228 # 80021998 <log>
    80003e6c:	00003597          	auipc	a1,0x3
    80003e70:	78458593          	addi	a1,a1,1924 # 800075f0 <userret+0x560>
    80003e74:	8526                	mv	a0,s1
    80003e76:	ffffd097          	auipc	ra,0xffffd
    80003e7a:	b46080e7          	jalr	-1210(ra) # 800009bc <initlock>
  log.start = sb->logstart;
    80003e7e:	0149a583          	lw	a1,20(s3)
    80003e82:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80003e84:	0109a783          	lw	a5,16(s3)
    80003e88:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80003e8a:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80003e8e:	854a                	mv	a0,s2
    80003e90:	fffff097          	auipc	ra,0xfffff
    80003e94:	ecc080e7          	jalr	-308(ra) # 80002d5c <bread>
  log.lh.n = lh->n;
    80003e98:	513c                	lw	a5,96(a0)
    80003e9a:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80003e9c:	02f05563          	blez	a5,80003ec6 <initlog+0x74>
    80003ea0:	06450713          	addi	a4,a0,100
    80003ea4:	0001e697          	auipc	a3,0x1e
    80003ea8:	b2468693          	addi	a3,a3,-1244 # 800219c8 <log+0x30>
    80003eac:	37fd                	addiw	a5,a5,-1
    80003eae:	1782                	slli	a5,a5,0x20
    80003eb0:	9381                	srli	a5,a5,0x20
    80003eb2:	078a                	slli	a5,a5,0x2
    80003eb4:	06850613          	addi	a2,a0,104
    80003eb8:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80003eba:	4310                	lw	a2,0(a4)
    80003ebc:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80003ebe:	0711                	addi	a4,a4,4
    80003ec0:	0691                	addi	a3,a3,4
    80003ec2:	fef71ce3          	bne	a4,a5,80003eba <initlog+0x68>
  brelse(buf);
    80003ec6:	fffff097          	auipc	ra,0xfffff
    80003eca:	fc6080e7          	jalr	-58(ra) # 80002e8c <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(); // if committed, copy from log to disk
    80003ece:	00000097          	auipc	ra,0x0
    80003ed2:	ece080e7          	jalr	-306(ra) # 80003d9c <install_trans>
  log.lh.n = 0;
    80003ed6:	0001e797          	auipc	a5,0x1e
    80003eda:	ae07a723          	sw	zero,-1298(a5) # 800219c4 <log+0x2c>
  write_head(); // clear the log
    80003ede:	00000097          	auipc	ra,0x0
    80003ee2:	e44080e7          	jalr	-444(ra) # 80003d22 <write_head>
}
    80003ee6:	70a2                	ld	ra,40(sp)
    80003ee8:	7402                	ld	s0,32(sp)
    80003eea:	64e2                	ld	s1,24(sp)
    80003eec:	6942                	ld	s2,16(sp)
    80003eee:	69a2                	ld	s3,8(sp)
    80003ef0:	6145                	addi	sp,sp,48
    80003ef2:	8082                	ret

0000000080003ef4 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80003ef4:	1101                	addi	sp,sp,-32
    80003ef6:	ec06                	sd	ra,24(sp)
    80003ef8:	e822                	sd	s0,16(sp)
    80003efa:	e426                	sd	s1,8(sp)
    80003efc:	e04a                	sd	s2,0(sp)
    80003efe:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80003f00:	0001e517          	auipc	a0,0x1e
    80003f04:	a9850513          	addi	a0,a0,-1384 # 80021998 <log>
    80003f08:	ffffd097          	auipc	ra,0xffffd
    80003f0c:	bc6080e7          	jalr	-1082(ra) # 80000ace <acquire>
  while(1){
    if(log.committing){
    80003f10:	0001e497          	auipc	s1,0x1e
    80003f14:	a8848493          	addi	s1,s1,-1400 # 80021998 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80003f18:	4979                	li	s2,30
    80003f1a:	a039                	j	80003f28 <begin_op+0x34>
      sleep(&log, &log.lock);
    80003f1c:	85a6                	mv	a1,s1
    80003f1e:	8526                	mv	a0,s1
    80003f20:	ffffe097          	auipc	ra,0xffffe
    80003f24:	0c2080e7          	jalr	194(ra) # 80001fe2 <sleep>
    if(log.committing){
    80003f28:	50dc                	lw	a5,36(s1)
    80003f2a:	fbed                	bnez	a5,80003f1c <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80003f2c:	509c                	lw	a5,32(s1)
    80003f2e:	0017871b          	addiw	a4,a5,1
    80003f32:	0007069b          	sext.w	a3,a4
    80003f36:	0027179b          	slliw	a5,a4,0x2
    80003f3a:	9fb9                	addw	a5,a5,a4
    80003f3c:	0017979b          	slliw	a5,a5,0x1
    80003f40:	54d8                	lw	a4,44(s1)
    80003f42:	9fb9                	addw	a5,a5,a4
    80003f44:	00f95963          	bge	s2,a5,80003f56 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80003f48:	85a6                	mv	a1,s1
    80003f4a:	8526                	mv	a0,s1
    80003f4c:	ffffe097          	auipc	ra,0xffffe
    80003f50:	096080e7          	jalr	150(ra) # 80001fe2 <sleep>
    80003f54:	bfd1                	j	80003f28 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80003f56:	0001e517          	auipc	a0,0x1e
    80003f5a:	a4250513          	addi	a0,a0,-1470 # 80021998 <log>
    80003f5e:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80003f60:	ffffd097          	auipc	ra,0xffffd
    80003f64:	bc2080e7          	jalr	-1086(ra) # 80000b22 <release>
      break;
    }
  }
}
    80003f68:	60e2                	ld	ra,24(sp)
    80003f6a:	6442                	ld	s0,16(sp)
    80003f6c:	64a2                	ld	s1,8(sp)
    80003f6e:	6902                	ld	s2,0(sp)
    80003f70:	6105                	addi	sp,sp,32
    80003f72:	8082                	ret

0000000080003f74 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80003f74:	7139                	addi	sp,sp,-64
    80003f76:	fc06                	sd	ra,56(sp)
    80003f78:	f822                	sd	s0,48(sp)
    80003f7a:	f426                	sd	s1,40(sp)
    80003f7c:	f04a                	sd	s2,32(sp)
    80003f7e:	ec4e                	sd	s3,24(sp)
    80003f80:	e852                	sd	s4,16(sp)
    80003f82:	e456                	sd	s5,8(sp)
    80003f84:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80003f86:	0001e497          	auipc	s1,0x1e
    80003f8a:	a1248493          	addi	s1,s1,-1518 # 80021998 <log>
    80003f8e:	8526                	mv	a0,s1
    80003f90:	ffffd097          	auipc	ra,0xffffd
    80003f94:	b3e080e7          	jalr	-1218(ra) # 80000ace <acquire>
  log.outstanding -= 1;
    80003f98:	509c                	lw	a5,32(s1)
    80003f9a:	37fd                	addiw	a5,a5,-1
    80003f9c:	0007891b          	sext.w	s2,a5
    80003fa0:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80003fa2:	50dc                	lw	a5,36(s1)
    80003fa4:	efb9                	bnez	a5,80004002 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80003fa6:	06091663          	bnez	s2,80004012 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80003faa:	0001e497          	auipc	s1,0x1e
    80003fae:	9ee48493          	addi	s1,s1,-1554 # 80021998 <log>
    80003fb2:	4785                	li	a5,1
    80003fb4:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80003fb6:	8526                	mv	a0,s1
    80003fb8:	ffffd097          	auipc	ra,0xffffd
    80003fbc:	b6a080e7          	jalr	-1174(ra) # 80000b22 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80003fc0:	54dc                	lw	a5,44(s1)
    80003fc2:	06f04763          	bgtz	a5,80004030 <end_op+0xbc>
    acquire(&log.lock);
    80003fc6:	0001e497          	auipc	s1,0x1e
    80003fca:	9d248493          	addi	s1,s1,-1582 # 80021998 <log>
    80003fce:	8526                	mv	a0,s1
    80003fd0:	ffffd097          	auipc	ra,0xffffd
    80003fd4:	afe080e7          	jalr	-1282(ra) # 80000ace <acquire>
    log.committing = 0;
    80003fd8:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80003fdc:	8526                	mv	a0,s1
    80003fde:	ffffe097          	auipc	ra,0xffffe
    80003fe2:	18a080e7          	jalr	394(ra) # 80002168 <wakeup>
    release(&log.lock);
    80003fe6:	8526                	mv	a0,s1
    80003fe8:	ffffd097          	auipc	ra,0xffffd
    80003fec:	b3a080e7          	jalr	-1222(ra) # 80000b22 <release>
}
    80003ff0:	70e2                	ld	ra,56(sp)
    80003ff2:	7442                	ld	s0,48(sp)
    80003ff4:	74a2                	ld	s1,40(sp)
    80003ff6:	7902                	ld	s2,32(sp)
    80003ff8:	69e2                	ld	s3,24(sp)
    80003ffa:	6a42                	ld	s4,16(sp)
    80003ffc:	6aa2                	ld	s5,8(sp)
    80003ffe:	6121                	addi	sp,sp,64
    80004000:	8082                	ret
    panic("log.committing");
    80004002:	00003517          	auipc	a0,0x3
    80004006:	5f650513          	addi	a0,a0,1526 # 800075f8 <userret+0x568>
    8000400a:	ffffc097          	auipc	ra,0xffffc
    8000400e:	544080e7          	jalr	1348(ra) # 8000054e <panic>
    wakeup(&log);
    80004012:	0001e497          	auipc	s1,0x1e
    80004016:	98648493          	addi	s1,s1,-1658 # 80021998 <log>
    8000401a:	8526                	mv	a0,s1
    8000401c:	ffffe097          	auipc	ra,0xffffe
    80004020:	14c080e7          	jalr	332(ra) # 80002168 <wakeup>
  release(&log.lock);
    80004024:	8526                	mv	a0,s1
    80004026:	ffffd097          	auipc	ra,0xffffd
    8000402a:	afc080e7          	jalr	-1284(ra) # 80000b22 <release>
  if(do_commit){
    8000402e:	b7c9                	j	80003ff0 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004030:	0001ea97          	auipc	s5,0x1e
    80004034:	998a8a93          	addi	s5,s5,-1640 # 800219c8 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004038:	0001ea17          	auipc	s4,0x1e
    8000403c:	960a0a13          	addi	s4,s4,-1696 # 80021998 <log>
    80004040:	018a2583          	lw	a1,24(s4)
    80004044:	012585bb          	addw	a1,a1,s2
    80004048:	2585                	addiw	a1,a1,1
    8000404a:	028a2503          	lw	a0,40(s4)
    8000404e:	fffff097          	auipc	ra,0xfffff
    80004052:	d0e080e7          	jalr	-754(ra) # 80002d5c <bread>
    80004056:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004058:	000aa583          	lw	a1,0(s5)
    8000405c:	028a2503          	lw	a0,40(s4)
    80004060:	fffff097          	auipc	ra,0xfffff
    80004064:	cfc080e7          	jalr	-772(ra) # 80002d5c <bread>
    80004068:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000406a:	40000613          	li	a2,1024
    8000406e:	06050593          	addi	a1,a0,96
    80004072:	06048513          	addi	a0,s1,96
    80004076:	ffffd097          	auipc	ra,0xffffd
    8000407a:	b54080e7          	jalr	-1196(ra) # 80000bca <memmove>
    bwrite(to);  // write the log
    8000407e:	8526                	mv	a0,s1
    80004080:	fffff097          	auipc	ra,0xfffff
    80004084:	dce080e7          	jalr	-562(ra) # 80002e4e <bwrite>
    brelse(from);
    80004088:	854e                	mv	a0,s3
    8000408a:	fffff097          	auipc	ra,0xfffff
    8000408e:	e02080e7          	jalr	-510(ra) # 80002e8c <brelse>
    brelse(to);
    80004092:	8526                	mv	a0,s1
    80004094:	fffff097          	auipc	ra,0xfffff
    80004098:	df8080e7          	jalr	-520(ra) # 80002e8c <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000409c:	2905                	addiw	s2,s2,1
    8000409e:	0a91                	addi	s5,s5,4
    800040a0:	02ca2783          	lw	a5,44(s4)
    800040a4:	f8f94ee3          	blt	s2,a5,80004040 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800040a8:	00000097          	auipc	ra,0x0
    800040ac:	c7a080e7          	jalr	-902(ra) # 80003d22 <write_head>
    install_trans(); // Now install writes to home locations
    800040b0:	00000097          	auipc	ra,0x0
    800040b4:	cec080e7          	jalr	-788(ra) # 80003d9c <install_trans>
    log.lh.n = 0;
    800040b8:	0001e797          	auipc	a5,0x1e
    800040bc:	9007a623          	sw	zero,-1780(a5) # 800219c4 <log+0x2c>
    write_head();    // Erase the transaction from the log
    800040c0:	00000097          	auipc	ra,0x0
    800040c4:	c62080e7          	jalr	-926(ra) # 80003d22 <write_head>
    800040c8:	bdfd                	j	80003fc6 <end_op+0x52>

00000000800040ca <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800040ca:	1101                	addi	sp,sp,-32
    800040cc:	ec06                	sd	ra,24(sp)
    800040ce:	e822                	sd	s0,16(sp)
    800040d0:	e426                	sd	s1,8(sp)
    800040d2:	e04a                	sd	s2,0(sp)
    800040d4:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800040d6:	0001e717          	auipc	a4,0x1e
    800040da:	8ee72703          	lw	a4,-1810(a4) # 800219c4 <log+0x2c>
    800040de:	47f5                	li	a5,29
    800040e0:	08e7c063          	blt	a5,a4,80004160 <log_write+0x96>
    800040e4:	84aa                	mv	s1,a0
    800040e6:	0001e797          	auipc	a5,0x1e
    800040ea:	8ce7a783          	lw	a5,-1842(a5) # 800219b4 <log+0x1c>
    800040ee:	37fd                	addiw	a5,a5,-1
    800040f0:	06f75863          	bge	a4,a5,80004160 <log_write+0x96>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800040f4:	0001e797          	auipc	a5,0x1e
    800040f8:	8c47a783          	lw	a5,-1852(a5) # 800219b8 <log+0x20>
    800040fc:	06f05a63          	blez	a5,80004170 <log_write+0xa6>
    panic("log_write outside of trans");

  acquire(&log.lock);
    80004100:	0001e917          	auipc	s2,0x1e
    80004104:	89890913          	addi	s2,s2,-1896 # 80021998 <log>
    80004108:	854a                	mv	a0,s2
    8000410a:	ffffd097          	auipc	ra,0xffffd
    8000410e:	9c4080e7          	jalr	-1596(ra) # 80000ace <acquire>
  for (i = 0; i < log.lh.n; i++) {
    80004112:	02c92603          	lw	a2,44(s2)
    80004116:	06c05563          	blez	a2,80004180 <log_write+0xb6>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    8000411a:	44cc                	lw	a1,12(s1)
    8000411c:	0001e717          	auipc	a4,0x1e
    80004120:	8ac70713          	addi	a4,a4,-1876 # 800219c8 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004124:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004126:	4314                	lw	a3,0(a4)
    80004128:	04b68d63          	beq	a3,a1,80004182 <log_write+0xb8>
  for (i = 0; i < log.lh.n; i++) {
    8000412c:	2785                	addiw	a5,a5,1
    8000412e:	0711                	addi	a4,a4,4
    80004130:	fec79be3          	bne	a5,a2,80004126 <log_write+0x5c>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004134:	0621                	addi	a2,a2,8
    80004136:	060a                	slli	a2,a2,0x2
    80004138:	0001e797          	auipc	a5,0x1e
    8000413c:	86078793          	addi	a5,a5,-1952 # 80021998 <log>
    80004140:	963e                	add	a2,a2,a5
    80004142:	44dc                	lw	a5,12(s1)
    80004144:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004146:	8526                	mv	a0,s1
    80004148:	fffff097          	auipc	ra,0xfffff
    8000414c:	de2080e7          	jalr	-542(ra) # 80002f2a <bpin>
    log.lh.n++;
    80004150:	0001e717          	auipc	a4,0x1e
    80004154:	84870713          	addi	a4,a4,-1976 # 80021998 <log>
    80004158:	575c                	lw	a5,44(a4)
    8000415a:	2785                	addiw	a5,a5,1
    8000415c:	d75c                	sw	a5,44(a4)
    8000415e:	a83d                	j	8000419c <log_write+0xd2>
    panic("too big a transaction");
    80004160:	00003517          	auipc	a0,0x3
    80004164:	4a850513          	addi	a0,a0,1192 # 80007608 <userret+0x578>
    80004168:	ffffc097          	auipc	ra,0xffffc
    8000416c:	3e6080e7          	jalr	998(ra) # 8000054e <panic>
    panic("log_write outside of trans");
    80004170:	00003517          	auipc	a0,0x3
    80004174:	4b050513          	addi	a0,a0,1200 # 80007620 <userret+0x590>
    80004178:	ffffc097          	auipc	ra,0xffffc
    8000417c:	3d6080e7          	jalr	982(ra) # 8000054e <panic>
  for (i = 0; i < log.lh.n; i++) {
    80004180:	4781                	li	a5,0
  log.lh.block[i] = b->blockno;
    80004182:	00878713          	addi	a4,a5,8
    80004186:	00271693          	slli	a3,a4,0x2
    8000418a:	0001e717          	auipc	a4,0x1e
    8000418e:	80e70713          	addi	a4,a4,-2034 # 80021998 <log>
    80004192:	9736                	add	a4,a4,a3
    80004194:	44d4                	lw	a3,12(s1)
    80004196:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004198:	faf607e3          	beq	a2,a5,80004146 <log_write+0x7c>
  }
  release(&log.lock);
    8000419c:	0001d517          	auipc	a0,0x1d
    800041a0:	7fc50513          	addi	a0,a0,2044 # 80021998 <log>
    800041a4:	ffffd097          	auipc	ra,0xffffd
    800041a8:	97e080e7          	jalr	-1666(ra) # 80000b22 <release>
}
    800041ac:	60e2                	ld	ra,24(sp)
    800041ae:	6442                	ld	s0,16(sp)
    800041b0:	64a2                	ld	s1,8(sp)
    800041b2:	6902                	ld	s2,0(sp)
    800041b4:	6105                	addi	sp,sp,32
    800041b6:	8082                	ret

00000000800041b8 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800041b8:	1101                	addi	sp,sp,-32
    800041ba:	ec06                	sd	ra,24(sp)
    800041bc:	e822                	sd	s0,16(sp)
    800041be:	e426                	sd	s1,8(sp)
    800041c0:	e04a                	sd	s2,0(sp)
    800041c2:	1000                	addi	s0,sp,32
    800041c4:	84aa                	mv	s1,a0
    800041c6:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800041c8:	00003597          	auipc	a1,0x3
    800041cc:	47858593          	addi	a1,a1,1144 # 80007640 <userret+0x5b0>
    800041d0:	0521                	addi	a0,a0,8
    800041d2:	ffffc097          	auipc	ra,0xffffc
    800041d6:	7ea080e7          	jalr	2026(ra) # 800009bc <initlock>
  lk->name = name;
    800041da:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800041de:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800041e2:	0204a423          	sw	zero,40(s1)
}
    800041e6:	60e2                	ld	ra,24(sp)
    800041e8:	6442                	ld	s0,16(sp)
    800041ea:	64a2                	ld	s1,8(sp)
    800041ec:	6902                	ld	s2,0(sp)
    800041ee:	6105                	addi	sp,sp,32
    800041f0:	8082                	ret

00000000800041f2 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800041f2:	1101                	addi	sp,sp,-32
    800041f4:	ec06                	sd	ra,24(sp)
    800041f6:	e822                	sd	s0,16(sp)
    800041f8:	e426                	sd	s1,8(sp)
    800041fa:	e04a                	sd	s2,0(sp)
    800041fc:	1000                	addi	s0,sp,32
    800041fe:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004200:	00850913          	addi	s2,a0,8
    80004204:	854a                	mv	a0,s2
    80004206:	ffffd097          	auipc	ra,0xffffd
    8000420a:	8c8080e7          	jalr	-1848(ra) # 80000ace <acquire>
  while (lk->locked) {
    8000420e:	409c                	lw	a5,0(s1)
    80004210:	cb89                	beqz	a5,80004222 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004212:	85ca                	mv	a1,s2
    80004214:	8526                	mv	a0,s1
    80004216:	ffffe097          	auipc	ra,0xffffe
    8000421a:	dcc080e7          	jalr	-564(ra) # 80001fe2 <sleep>
  while (lk->locked) {
    8000421e:	409c                	lw	a5,0(s1)
    80004220:	fbed                	bnez	a5,80004212 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004222:	4785                	li	a5,1
    80004224:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004226:	ffffd097          	auipc	ra,0xffffd
    8000422a:	61a080e7          	jalr	1562(ra) # 80001840 <myproc>
    8000422e:	5d1c                	lw	a5,56(a0)
    80004230:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004232:	854a                	mv	a0,s2
    80004234:	ffffd097          	auipc	ra,0xffffd
    80004238:	8ee080e7          	jalr	-1810(ra) # 80000b22 <release>
}
    8000423c:	60e2                	ld	ra,24(sp)
    8000423e:	6442                	ld	s0,16(sp)
    80004240:	64a2                	ld	s1,8(sp)
    80004242:	6902                	ld	s2,0(sp)
    80004244:	6105                	addi	sp,sp,32
    80004246:	8082                	ret

0000000080004248 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004248:	1101                	addi	sp,sp,-32
    8000424a:	ec06                	sd	ra,24(sp)
    8000424c:	e822                	sd	s0,16(sp)
    8000424e:	e426                	sd	s1,8(sp)
    80004250:	e04a                	sd	s2,0(sp)
    80004252:	1000                	addi	s0,sp,32
    80004254:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004256:	00850913          	addi	s2,a0,8
    8000425a:	854a                	mv	a0,s2
    8000425c:	ffffd097          	auipc	ra,0xffffd
    80004260:	872080e7          	jalr	-1934(ra) # 80000ace <acquire>
  lk->locked = 0;
    80004264:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004268:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000426c:	8526                	mv	a0,s1
    8000426e:	ffffe097          	auipc	ra,0xffffe
    80004272:	efa080e7          	jalr	-262(ra) # 80002168 <wakeup>
  release(&lk->lk);
    80004276:	854a                	mv	a0,s2
    80004278:	ffffd097          	auipc	ra,0xffffd
    8000427c:	8aa080e7          	jalr	-1878(ra) # 80000b22 <release>
}
    80004280:	60e2                	ld	ra,24(sp)
    80004282:	6442                	ld	s0,16(sp)
    80004284:	64a2                	ld	s1,8(sp)
    80004286:	6902                	ld	s2,0(sp)
    80004288:	6105                	addi	sp,sp,32
    8000428a:	8082                	ret

000000008000428c <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000428c:	7179                	addi	sp,sp,-48
    8000428e:	f406                	sd	ra,40(sp)
    80004290:	f022                	sd	s0,32(sp)
    80004292:	ec26                	sd	s1,24(sp)
    80004294:	e84a                	sd	s2,16(sp)
    80004296:	e44e                	sd	s3,8(sp)
    80004298:	1800                	addi	s0,sp,48
    8000429a:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000429c:	00850913          	addi	s2,a0,8
    800042a0:	854a                	mv	a0,s2
    800042a2:	ffffd097          	auipc	ra,0xffffd
    800042a6:	82c080e7          	jalr	-2004(ra) # 80000ace <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800042aa:	409c                	lw	a5,0(s1)
    800042ac:	ef99                	bnez	a5,800042ca <holdingsleep+0x3e>
    800042ae:	4481                	li	s1,0
  release(&lk->lk);
    800042b0:	854a                	mv	a0,s2
    800042b2:	ffffd097          	auipc	ra,0xffffd
    800042b6:	870080e7          	jalr	-1936(ra) # 80000b22 <release>
  return r;
}
    800042ba:	8526                	mv	a0,s1
    800042bc:	70a2                	ld	ra,40(sp)
    800042be:	7402                	ld	s0,32(sp)
    800042c0:	64e2                	ld	s1,24(sp)
    800042c2:	6942                	ld	s2,16(sp)
    800042c4:	69a2                	ld	s3,8(sp)
    800042c6:	6145                	addi	sp,sp,48
    800042c8:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800042ca:	0284a983          	lw	s3,40(s1)
    800042ce:	ffffd097          	auipc	ra,0xffffd
    800042d2:	572080e7          	jalr	1394(ra) # 80001840 <myproc>
    800042d6:	5d04                	lw	s1,56(a0)
    800042d8:	413484b3          	sub	s1,s1,s3
    800042dc:	0014b493          	seqz	s1,s1
    800042e0:	bfc1                	j	800042b0 <holdingsleep+0x24>

00000000800042e2 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800042e2:	1141                	addi	sp,sp,-16
    800042e4:	e406                	sd	ra,8(sp)
    800042e6:	e022                	sd	s0,0(sp)
    800042e8:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800042ea:	00003597          	auipc	a1,0x3
    800042ee:	36658593          	addi	a1,a1,870 # 80007650 <userret+0x5c0>
    800042f2:	0001d517          	auipc	a0,0x1d
    800042f6:	7ee50513          	addi	a0,a0,2030 # 80021ae0 <ftable>
    800042fa:	ffffc097          	auipc	ra,0xffffc
    800042fe:	6c2080e7          	jalr	1730(ra) # 800009bc <initlock>
}
    80004302:	60a2                	ld	ra,8(sp)
    80004304:	6402                	ld	s0,0(sp)
    80004306:	0141                	addi	sp,sp,16
    80004308:	8082                	ret

000000008000430a <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000430a:	1101                	addi	sp,sp,-32
    8000430c:	ec06                	sd	ra,24(sp)
    8000430e:	e822                	sd	s0,16(sp)
    80004310:	e426                	sd	s1,8(sp)
    80004312:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004314:	0001d517          	auipc	a0,0x1d
    80004318:	7cc50513          	addi	a0,a0,1996 # 80021ae0 <ftable>
    8000431c:	ffffc097          	auipc	ra,0xffffc
    80004320:	7b2080e7          	jalr	1970(ra) # 80000ace <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004324:	0001d497          	auipc	s1,0x1d
    80004328:	7d448493          	addi	s1,s1,2004 # 80021af8 <ftable+0x18>
    8000432c:	0001e717          	auipc	a4,0x1e
    80004330:	76c70713          	addi	a4,a4,1900 # 80022a98 <ftable+0xfb8>
    if(f->ref == 0){
    80004334:	40dc                	lw	a5,4(s1)
    80004336:	cf99                	beqz	a5,80004354 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004338:	02848493          	addi	s1,s1,40
    8000433c:	fee49ce3          	bne	s1,a4,80004334 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004340:	0001d517          	auipc	a0,0x1d
    80004344:	7a050513          	addi	a0,a0,1952 # 80021ae0 <ftable>
    80004348:	ffffc097          	auipc	ra,0xffffc
    8000434c:	7da080e7          	jalr	2010(ra) # 80000b22 <release>
  return 0;
    80004350:	4481                	li	s1,0
    80004352:	a819                	j	80004368 <filealloc+0x5e>
      f->ref = 1;
    80004354:	4785                	li	a5,1
    80004356:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004358:	0001d517          	auipc	a0,0x1d
    8000435c:	78850513          	addi	a0,a0,1928 # 80021ae0 <ftable>
    80004360:	ffffc097          	auipc	ra,0xffffc
    80004364:	7c2080e7          	jalr	1986(ra) # 80000b22 <release>
}
    80004368:	8526                	mv	a0,s1
    8000436a:	60e2                	ld	ra,24(sp)
    8000436c:	6442                	ld	s0,16(sp)
    8000436e:	64a2                	ld	s1,8(sp)
    80004370:	6105                	addi	sp,sp,32
    80004372:	8082                	ret

0000000080004374 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004374:	1101                	addi	sp,sp,-32
    80004376:	ec06                	sd	ra,24(sp)
    80004378:	e822                	sd	s0,16(sp)
    8000437a:	e426                	sd	s1,8(sp)
    8000437c:	1000                	addi	s0,sp,32
    8000437e:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004380:	0001d517          	auipc	a0,0x1d
    80004384:	76050513          	addi	a0,a0,1888 # 80021ae0 <ftable>
    80004388:	ffffc097          	auipc	ra,0xffffc
    8000438c:	746080e7          	jalr	1862(ra) # 80000ace <acquire>
  if(f->ref < 1)
    80004390:	40dc                	lw	a5,4(s1)
    80004392:	02f05263          	blez	a5,800043b6 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004396:	2785                	addiw	a5,a5,1
    80004398:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    8000439a:	0001d517          	auipc	a0,0x1d
    8000439e:	74650513          	addi	a0,a0,1862 # 80021ae0 <ftable>
    800043a2:	ffffc097          	auipc	ra,0xffffc
    800043a6:	780080e7          	jalr	1920(ra) # 80000b22 <release>
  return f;
}
    800043aa:	8526                	mv	a0,s1
    800043ac:	60e2                	ld	ra,24(sp)
    800043ae:	6442                	ld	s0,16(sp)
    800043b0:	64a2                	ld	s1,8(sp)
    800043b2:	6105                	addi	sp,sp,32
    800043b4:	8082                	ret
    panic("filedup");
    800043b6:	00003517          	auipc	a0,0x3
    800043ba:	2a250513          	addi	a0,a0,674 # 80007658 <userret+0x5c8>
    800043be:	ffffc097          	auipc	ra,0xffffc
    800043c2:	190080e7          	jalr	400(ra) # 8000054e <panic>

00000000800043c6 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800043c6:	7139                	addi	sp,sp,-64
    800043c8:	fc06                	sd	ra,56(sp)
    800043ca:	f822                	sd	s0,48(sp)
    800043cc:	f426                	sd	s1,40(sp)
    800043ce:	f04a                	sd	s2,32(sp)
    800043d0:	ec4e                	sd	s3,24(sp)
    800043d2:	e852                	sd	s4,16(sp)
    800043d4:	e456                	sd	s5,8(sp)
    800043d6:	0080                	addi	s0,sp,64
    800043d8:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800043da:	0001d517          	auipc	a0,0x1d
    800043de:	70650513          	addi	a0,a0,1798 # 80021ae0 <ftable>
    800043e2:	ffffc097          	auipc	ra,0xffffc
    800043e6:	6ec080e7          	jalr	1772(ra) # 80000ace <acquire>
  if(f->ref < 1)
    800043ea:	40dc                	lw	a5,4(s1)
    800043ec:	06f05163          	blez	a5,8000444e <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800043f0:	37fd                	addiw	a5,a5,-1
    800043f2:	0007871b          	sext.w	a4,a5
    800043f6:	c0dc                	sw	a5,4(s1)
    800043f8:	06e04363          	bgtz	a4,8000445e <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800043fc:	0004a903          	lw	s2,0(s1)
    80004400:	0094ca83          	lbu	s5,9(s1)
    80004404:	0104ba03          	ld	s4,16(s1)
    80004408:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    8000440c:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004410:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004414:	0001d517          	auipc	a0,0x1d
    80004418:	6cc50513          	addi	a0,a0,1740 # 80021ae0 <ftable>
    8000441c:	ffffc097          	auipc	ra,0xffffc
    80004420:	706080e7          	jalr	1798(ra) # 80000b22 <release>

  if(ff.type == FD_PIPE){
    80004424:	4785                	li	a5,1
    80004426:	04f90d63          	beq	s2,a5,80004480 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    8000442a:	3979                	addiw	s2,s2,-2
    8000442c:	4785                	li	a5,1
    8000442e:	0527e063          	bltu	a5,s2,8000446e <fileclose+0xa8>
    begin_op();
    80004432:	00000097          	auipc	ra,0x0
    80004436:	ac2080e7          	jalr	-1342(ra) # 80003ef4 <begin_op>
    iput(ff.ip);
    8000443a:	854e                	mv	a0,s3
    8000443c:	fffff097          	auipc	ra,0xfffff
    80004440:	230080e7          	jalr	560(ra) # 8000366c <iput>
    end_op();
    80004444:	00000097          	auipc	ra,0x0
    80004448:	b30080e7          	jalr	-1232(ra) # 80003f74 <end_op>
    8000444c:	a00d                	j	8000446e <fileclose+0xa8>
    panic("fileclose");
    8000444e:	00003517          	auipc	a0,0x3
    80004452:	21250513          	addi	a0,a0,530 # 80007660 <userret+0x5d0>
    80004456:	ffffc097          	auipc	ra,0xffffc
    8000445a:	0f8080e7          	jalr	248(ra) # 8000054e <panic>
    release(&ftable.lock);
    8000445e:	0001d517          	auipc	a0,0x1d
    80004462:	68250513          	addi	a0,a0,1666 # 80021ae0 <ftable>
    80004466:	ffffc097          	auipc	ra,0xffffc
    8000446a:	6bc080e7          	jalr	1724(ra) # 80000b22 <release>
  }
}
    8000446e:	70e2                	ld	ra,56(sp)
    80004470:	7442                	ld	s0,48(sp)
    80004472:	74a2                	ld	s1,40(sp)
    80004474:	7902                	ld	s2,32(sp)
    80004476:	69e2                	ld	s3,24(sp)
    80004478:	6a42                	ld	s4,16(sp)
    8000447a:	6aa2                	ld	s5,8(sp)
    8000447c:	6121                	addi	sp,sp,64
    8000447e:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004480:	85d6                	mv	a1,s5
    80004482:	8552                	mv	a0,s4
    80004484:	00000097          	auipc	ra,0x0
    80004488:	372080e7          	jalr	882(ra) # 800047f6 <pipeclose>
    8000448c:	b7cd                	j	8000446e <fileclose+0xa8>

000000008000448e <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    8000448e:	715d                	addi	sp,sp,-80
    80004490:	e486                	sd	ra,72(sp)
    80004492:	e0a2                	sd	s0,64(sp)
    80004494:	fc26                	sd	s1,56(sp)
    80004496:	f84a                	sd	s2,48(sp)
    80004498:	f44e                	sd	s3,40(sp)
    8000449a:	0880                	addi	s0,sp,80
    8000449c:	84aa                	mv	s1,a0
    8000449e:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800044a0:	ffffd097          	auipc	ra,0xffffd
    800044a4:	3a0080e7          	jalr	928(ra) # 80001840 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800044a8:	409c                	lw	a5,0(s1)
    800044aa:	37f9                	addiw	a5,a5,-2
    800044ac:	4705                	li	a4,1
    800044ae:	04f76763          	bltu	a4,a5,800044fc <filestat+0x6e>
    800044b2:	892a                	mv	s2,a0
    ilock(f->ip);
    800044b4:	6c88                	ld	a0,24(s1)
    800044b6:	fffff097          	auipc	ra,0xfffff
    800044ba:	0a8080e7          	jalr	168(ra) # 8000355e <ilock>
    stati(f->ip, &st);
    800044be:	fb840593          	addi	a1,s0,-72
    800044c2:	6c88                	ld	a0,24(s1)
    800044c4:	fffff097          	auipc	ra,0xfffff
    800044c8:	300080e7          	jalr	768(ra) # 800037c4 <stati>
    iunlock(f->ip);
    800044cc:	6c88                	ld	a0,24(s1)
    800044ce:	fffff097          	auipc	ra,0xfffff
    800044d2:	152080e7          	jalr	338(ra) # 80003620 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800044d6:	46e1                	li	a3,24
    800044d8:	fb840613          	addi	a2,s0,-72
    800044dc:	85ce                	mv	a1,s3
    800044de:	05093503          	ld	a0,80(s2)
    800044e2:	ffffd097          	auipc	ra,0xffffd
    800044e6:	052080e7          	jalr	82(ra) # 80001534 <copyout>
    800044ea:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800044ee:	60a6                	ld	ra,72(sp)
    800044f0:	6406                	ld	s0,64(sp)
    800044f2:	74e2                	ld	s1,56(sp)
    800044f4:	7942                	ld	s2,48(sp)
    800044f6:	79a2                	ld	s3,40(sp)
    800044f8:	6161                	addi	sp,sp,80
    800044fa:	8082                	ret
  return -1;
    800044fc:	557d                	li	a0,-1
    800044fe:	bfc5                	j	800044ee <filestat+0x60>

0000000080004500 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004500:	7179                	addi	sp,sp,-48
    80004502:	f406                	sd	ra,40(sp)
    80004504:	f022                	sd	s0,32(sp)
    80004506:	ec26                	sd	s1,24(sp)
    80004508:	e84a                	sd	s2,16(sp)
    8000450a:	e44e                	sd	s3,8(sp)
    8000450c:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000450e:	00854783          	lbu	a5,8(a0)
    80004512:	c3d5                	beqz	a5,800045b6 <fileread+0xb6>
    80004514:	84aa                	mv	s1,a0
    80004516:	89ae                	mv	s3,a1
    80004518:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    8000451a:	411c                	lw	a5,0(a0)
    8000451c:	4705                	li	a4,1
    8000451e:	04e78963          	beq	a5,a4,80004570 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004522:	470d                	li	a4,3
    80004524:	04e78d63          	beq	a5,a4,8000457e <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004528:	4709                	li	a4,2
    8000452a:	06e79e63          	bne	a5,a4,800045a6 <fileread+0xa6>
    ilock(f->ip);
    8000452e:	6d08                	ld	a0,24(a0)
    80004530:	fffff097          	auipc	ra,0xfffff
    80004534:	02e080e7          	jalr	46(ra) # 8000355e <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004538:	874a                	mv	a4,s2
    8000453a:	5094                	lw	a3,32(s1)
    8000453c:	864e                	mv	a2,s3
    8000453e:	4585                	li	a1,1
    80004540:	6c88                	ld	a0,24(s1)
    80004542:	fffff097          	auipc	ra,0xfffff
    80004546:	2ac080e7          	jalr	684(ra) # 800037ee <readi>
    8000454a:	892a                	mv	s2,a0
    8000454c:	00a05563          	blez	a0,80004556 <fileread+0x56>
      f->off += r;
    80004550:	509c                	lw	a5,32(s1)
    80004552:	9fa9                	addw	a5,a5,a0
    80004554:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004556:	6c88                	ld	a0,24(s1)
    80004558:	fffff097          	auipc	ra,0xfffff
    8000455c:	0c8080e7          	jalr	200(ra) # 80003620 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004560:	854a                	mv	a0,s2
    80004562:	70a2                	ld	ra,40(sp)
    80004564:	7402                	ld	s0,32(sp)
    80004566:	64e2                	ld	s1,24(sp)
    80004568:	6942                	ld	s2,16(sp)
    8000456a:	69a2                	ld	s3,8(sp)
    8000456c:	6145                	addi	sp,sp,48
    8000456e:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004570:	6908                	ld	a0,16(a0)
    80004572:	00000097          	auipc	ra,0x0
    80004576:	408080e7          	jalr	1032(ra) # 8000497a <piperead>
    8000457a:	892a                	mv	s2,a0
    8000457c:	b7d5                	j	80004560 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    8000457e:	02451783          	lh	a5,36(a0)
    80004582:	03079693          	slli	a3,a5,0x30
    80004586:	92c1                	srli	a3,a3,0x30
    80004588:	4725                	li	a4,9
    8000458a:	02d76863          	bltu	a4,a3,800045ba <fileread+0xba>
    8000458e:	0792                	slli	a5,a5,0x4
    80004590:	0001d717          	auipc	a4,0x1d
    80004594:	4b070713          	addi	a4,a4,1200 # 80021a40 <devsw>
    80004598:	97ba                	add	a5,a5,a4
    8000459a:	639c                	ld	a5,0(a5)
    8000459c:	c38d                	beqz	a5,800045be <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    8000459e:	4505                	li	a0,1
    800045a0:	9782                	jalr	a5
    800045a2:	892a                	mv	s2,a0
    800045a4:	bf75                	j	80004560 <fileread+0x60>
    panic("fileread");
    800045a6:	00003517          	auipc	a0,0x3
    800045aa:	0ca50513          	addi	a0,a0,202 # 80007670 <userret+0x5e0>
    800045ae:	ffffc097          	auipc	ra,0xffffc
    800045b2:	fa0080e7          	jalr	-96(ra) # 8000054e <panic>
    return -1;
    800045b6:	597d                	li	s2,-1
    800045b8:	b765                	j	80004560 <fileread+0x60>
      return -1;
    800045ba:	597d                	li	s2,-1
    800045bc:	b755                	j	80004560 <fileread+0x60>
    800045be:	597d                	li	s2,-1
    800045c0:	b745                	j	80004560 <fileread+0x60>

00000000800045c2 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    800045c2:	00954783          	lbu	a5,9(a0)
    800045c6:	14078563          	beqz	a5,80004710 <filewrite+0x14e>
{
    800045ca:	715d                	addi	sp,sp,-80
    800045cc:	e486                	sd	ra,72(sp)
    800045ce:	e0a2                	sd	s0,64(sp)
    800045d0:	fc26                	sd	s1,56(sp)
    800045d2:	f84a                	sd	s2,48(sp)
    800045d4:	f44e                	sd	s3,40(sp)
    800045d6:	f052                	sd	s4,32(sp)
    800045d8:	ec56                	sd	s5,24(sp)
    800045da:	e85a                	sd	s6,16(sp)
    800045dc:	e45e                	sd	s7,8(sp)
    800045de:	e062                	sd	s8,0(sp)
    800045e0:	0880                	addi	s0,sp,80
    800045e2:	892a                	mv	s2,a0
    800045e4:	8aae                	mv	s5,a1
    800045e6:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800045e8:	411c                	lw	a5,0(a0)
    800045ea:	4705                	li	a4,1
    800045ec:	02e78263          	beq	a5,a4,80004610 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800045f0:	470d                	li	a4,3
    800045f2:	02e78563          	beq	a5,a4,8000461c <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800045f6:	4709                	li	a4,2
    800045f8:	10e79463          	bne	a5,a4,80004700 <filewrite+0x13e>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800045fc:	0ec05e63          	blez	a2,800046f8 <filewrite+0x136>
    int i = 0;
    80004600:	4981                	li	s3,0
    80004602:	6b05                	lui	s6,0x1
    80004604:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004608:	6b85                	lui	s7,0x1
    8000460a:	c00b8b9b          	addiw	s7,s7,-1024
    8000460e:	a851                	j	800046a2 <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    80004610:	6908                	ld	a0,16(a0)
    80004612:	00000097          	auipc	ra,0x0
    80004616:	254080e7          	jalr	596(ra) # 80004866 <pipewrite>
    8000461a:	a85d                	j	800046d0 <filewrite+0x10e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    8000461c:	02451783          	lh	a5,36(a0)
    80004620:	03079693          	slli	a3,a5,0x30
    80004624:	92c1                	srli	a3,a3,0x30
    80004626:	4725                	li	a4,9
    80004628:	0ed76663          	bltu	a4,a3,80004714 <filewrite+0x152>
    8000462c:	0792                	slli	a5,a5,0x4
    8000462e:	0001d717          	auipc	a4,0x1d
    80004632:	41270713          	addi	a4,a4,1042 # 80021a40 <devsw>
    80004636:	97ba                	add	a5,a5,a4
    80004638:	679c                	ld	a5,8(a5)
    8000463a:	cff9                	beqz	a5,80004718 <filewrite+0x156>
    ret = devsw[f->major].write(1, addr, n);
    8000463c:	4505                	li	a0,1
    8000463e:	9782                	jalr	a5
    80004640:	a841                	j	800046d0 <filewrite+0x10e>
    80004642:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004646:	00000097          	auipc	ra,0x0
    8000464a:	8ae080e7          	jalr	-1874(ra) # 80003ef4 <begin_op>
      ilock(f->ip);
    8000464e:	01893503          	ld	a0,24(s2)
    80004652:	fffff097          	auipc	ra,0xfffff
    80004656:	f0c080e7          	jalr	-244(ra) # 8000355e <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    8000465a:	8762                	mv	a4,s8
    8000465c:	02092683          	lw	a3,32(s2)
    80004660:	01598633          	add	a2,s3,s5
    80004664:	4585                	li	a1,1
    80004666:	01893503          	ld	a0,24(s2)
    8000466a:	fffff097          	auipc	ra,0xfffff
    8000466e:	278080e7          	jalr	632(ra) # 800038e2 <writei>
    80004672:	84aa                	mv	s1,a0
    80004674:	02a05f63          	blez	a0,800046b2 <filewrite+0xf0>
        f->off += r;
    80004678:	02092783          	lw	a5,32(s2)
    8000467c:	9fa9                	addw	a5,a5,a0
    8000467e:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004682:	01893503          	ld	a0,24(s2)
    80004686:	fffff097          	auipc	ra,0xfffff
    8000468a:	f9a080e7          	jalr	-102(ra) # 80003620 <iunlock>
      end_op();
    8000468e:	00000097          	auipc	ra,0x0
    80004692:	8e6080e7          	jalr	-1818(ra) # 80003f74 <end_op>

      if(r < 0)
        break;
      if(r != n1)
    80004696:	049c1963          	bne	s8,s1,800046e8 <filewrite+0x126>
        panic("short filewrite");
      i += r;
    8000469a:	013489bb          	addw	s3,s1,s3
    while(i < n){
    8000469e:	0349d663          	bge	s3,s4,800046ca <filewrite+0x108>
      int n1 = n - i;
    800046a2:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    800046a6:	84be                	mv	s1,a5
    800046a8:	2781                	sext.w	a5,a5
    800046aa:	f8fb5ce3          	bge	s6,a5,80004642 <filewrite+0x80>
    800046ae:	84de                	mv	s1,s7
    800046b0:	bf49                	j	80004642 <filewrite+0x80>
      iunlock(f->ip);
    800046b2:	01893503          	ld	a0,24(s2)
    800046b6:	fffff097          	auipc	ra,0xfffff
    800046ba:	f6a080e7          	jalr	-150(ra) # 80003620 <iunlock>
      end_op();
    800046be:	00000097          	auipc	ra,0x0
    800046c2:	8b6080e7          	jalr	-1866(ra) # 80003f74 <end_op>
      if(r < 0)
    800046c6:	fc04d8e3          	bgez	s1,80004696 <filewrite+0xd4>
    }
    ret = (i == n ? n : -1);
    800046ca:	8552                	mv	a0,s4
    800046cc:	033a1863          	bne	s4,s3,800046fc <filewrite+0x13a>
  } else {
    panic("filewrite");
  }

  return ret;
}
    800046d0:	60a6                	ld	ra,72(sp)
    800046d2:	6406                	ld	s0,64(sp)
    800046d4:	74e2                	ld	s1,56(sp)
    800046d6:	7942                	ld	s2,48(sp)
    800046d8:	79a2                	ld	s3,40(sp)
    800046da:	7a02                	ld	s4,32(sp)
    800046dc:	6ae2                	ld	s5,24(sp)
    800046de:	6b42                	ld	s6,16(sp)
    800046e0:	6ba2                	ld	s7,8(sp)
    800046e2:	6c02                	ld	s8,0(sp)
    800046e4:	6161                	addi	sp,sp,80
    800046e6:	8082                	ret
        panic("short filewrite");
    800046e8:	00003517          	auipc	a0,0x3
    800046ec:	f9850513          	addi	a0,a0,-104 # 80007680 <userret+0x5f0>
    800046f0:	ffffc097          	auipc	ra,0xffffc
    800046f4:	e5e080e7          	jalr	-418(ra) # 8000054e <panic>
    int i = 0;
    800046f8:	4981                	li	s3,0
    800046fa:	bfc1                	j	800046ca <filewrite+0x108>
    ret = (i == n ? n : -1);
    800046fc:	557d                	li	a0,-1
    800046fe:	bfc9                	j	800046d0 <filewrite+0x10e>
    panic("filewrite");
    80004700:	00003517          	auipc	a0,0x3
    80004704:	f9050513          	addi	a0,a0,-112 # 80007690 <userret+0x600>
    80004708:	ffffc097          	auipc	ra,0xffffc
    8000470c:	e46080e7          	jalr	-442(ra) # 8000054e <panic>
    return -1;
    80004710:	557d                	li	a0,-1
}
    80004712:	8082                	ret
      return -1;
    80004714:	557d                	li	a0,-1
    80004716:	bf6d                	j	800046d0 <filewrite+0x10e>
    80004718:	557d                	li	a0,-1
    8000471a:	bf5d                	j	800046d0 <filewrite+0x10e>

000000008000471c <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    8000471c:	7179                	addi	sp,sp,-48
    8000471e:	f406                	sd	ra,40(sp)
    80004720:	f022                	sd	s0,32(sp)
    80004722:	ec26                	sd	s1,24(sp)
    80004724:	e84a                	sd	s2,16(sp)
    80004726:	e44e                	sd	s3,8(sp)
    80004728:	e052                	sd	s4,0(sp)
    8000472a:	1800                	addi	s0,sp,48
    8000472c:	84aa                	mv	s1,a0
    8000472e:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004730:	0005b023          	sd	zero,0(a1)
    80004734:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004738:	00000097          	auipc	ra,0x0
    8000473c:	bd2080e7          	jalr	-1070(ra) # 8000430a <filealloc>
    80004740:	e088                	sd	a0,0(s1)
    80004742:	c551                	beqz	a0,800047ce <pipealloc+0xb2>
    80004744:	00000097          	auipc	ra,0x0
    80004748:	bc6080e7          	jalr	-1082(ra) # 8000430a <filealloc>
    8000474c:	00aa3023          	sd	a0,0(s4)
    80004750:	c92d                	beqz	a0,800047c2 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004752:	ffffc097          	auipc	ra,0xffffc
    80004756:	20a080e7          	jalr	522(ra) # 8000095c <kalloc>
    8000475a:	892a                	mv	s2,a0
    8000475c:	c125                	beqz	a0,800047bc <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    8000475e:	4985                	li	s3,1
    80004760:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004764:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004768:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    8000476c:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004770:	00003597          	auipc	a1,0x3
    80004774:	f3058593          	addi	a1,a1,-208 # 800076a0 <userret+0x610>
    80004778:	ffffc097          	auipc	ra,0xffffc
    8000477c:	244080e7          	jalr	580(ra) # 800009bc <initlock>
  (*f0)->type = FD_PIPE;
    80004780:	609c                	ld	a5,0(s1)
    80004782:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004786:	609c                	ld	a5,0(s1)
    80004788:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    8000478c:	609c                	ld	a5,0(s1)
    8000478e:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004792:	609c                	ld	a5,0(s1)
    80004794:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004798:	000a3783          	ld	a5,0(s4)
    8000479c:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    800047a0:	000a3783          	ld	a5,0(s4)
    800047a4:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    800047a8:	000a3783          	ld	a5,0(s4)
    800047ac:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    800047b0:	000a3783          	ld	a5,0(s4)
    800047b4:	0127b823          	sd	s2,16(a5)
  return 0;
    800047b8:	4501                	li	a0,0
    800047ba:	a025                	j	800047e2 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    800047bc:	6088                	ld	a0,0(s1)
    800047be:	e501                	bnez	a0,800047c6 <pipealloc+0xaa>
    800047c0:	a039                	j	800047ce <pipealloc+0xb2>
    800047c2:	6088                	ld	a0,0(s1)
    800047c4:	c51d                	beqz	a0,800047f2 <pipealloc+0xd6>
    fileclose(*f0);
    800047c6:	00000097          	auipc	ra,0x0
    800047ca:	c00080e7          	jalr	-1024(ra) # 800043c6 <fileclose>
  if(*f1)
    800047ce:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    800047d2:	557d                	li	a0,-1
  if(*f1)
    800047d4:	c799                	beqz	a5,800047e2 <pipealloc+0xc6>
    fileclose(*f1);
    800047d6:	853e                	mv	a0,a5
    800047d8:	00000097          	auipc	ra,0x0
    800047dc:	bee080e7          	jalr	-1042(ra) # 800043c6 <fileclose>
  return -1;
    800047e0:	557d                	li	a0,-1
}
    800047e2:	70a2                	ld	ra,40(sp)
    800047e4:	7402                	ld	s0,32(sp)
    800047e6:	64e2                	ld	s1,24(sp)
    800047e8:	6942                	ld	s2,16(sp)
    800047ea:	69a2                	ld	s3,8(sp)
    800047ec:	6a02                	ld	s4,0(sp)
    800047ee:	6145                	addi	sp,sp,48
    800047f0:	8082                	ret
  return -1;
    800047f2:	557d                	li	a0,-1
    800047f4:	b7fd                	j	800047e2 <pipealloc+0xc6>

00000000800047f6 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    800047f6:	1101                	addi	sp,sp,-32
    800047f8:	ec06                	sd	ra,24(sp)
    800047fa:	e822                	sd	s0,16(sp)
    800047fc:	e426                	sd	s1,8(sp)
    800047fe:	e04a                	sd	s2,0(sp)
    80004800:	1000                	addi	s0,sp,32
    80004802:	84aa                	mv	s1,a0
    80004804:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004806:	ffffc097          	auipc	ra,0xffffc
    8000480a:	2c8080e7          	jalr	712(ra) # 80000ace <acquire>
  if(writable){
    8000480e:	02090d63          	beqz	s2,80004848 <pipeclose+0x52>
    pi->writeopen = 0;
    80004812:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004816:	21848513          	addi	a0,s1,536
    8000481a:	ffffe097          	auipc	ra,0xffffe
    8000481e:	94e080e7          	jalr	-1714(ra) # 80002168 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004822:	2204b783          	ld	a5,544(s1)
    80004826:	eb95                	bnez	a5,8000485a <pipeclose+0x64>
    release(&pi->lock);
    80004828:	8526                	mv	a0,s1
    8000482a:	ffffc097          	auipc	ra,0xffffc
    8000482e:	2f8080e7          	jalr	760(ra) # 80000b22 <release>
    kfree((char*)pi);
    80004832:	8526                	mv	a0,s1
    80004834:	ffffc097          	auipc	ra,0xffffc
    80004838:	02c080e7          	jalr	44(ra) # 80000860 <kfree>
  } else
    release(&pi->lock);
}
    8000483c:	60e2                	ld	ra,24(sp)
    8000483e:	6442                	ld	s0,16(sp)
    80004840:	64a2                	ld	s1,8(sp)
    80004842:	6902                	ld	s2,0(sp)
    80004844:	6105                	addi	sp,sp,32
    80004846:	8082                	ret
    pi->readopen = 0;
    80004848:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    8000484c:	21c48513          	addi	a0,s1,540
    80004850:	ffffe097          	auipc	ra,0xffffe
    80004854:	918080e7          	jalr	-1768(ra) # 80002168 <wakeup>
    80004858:	b7e9                	j	80004822 <pipeclose+0x2c>
    release(&pi->lock);
    8000485a:	8526                	mv	a0,s1
    8000485c:	ffffc097          	auipc	ra,0xffffc
    80004860:	2c6080e7          	jalr	710(ra) # 80000b22 <release>
}
    80004864:	bfe1                	j	8000483c <pipeclose+0x46>

0000000080004866 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004866:	7159                	addi	sp,sp,-112
    80004868:	f486                	sd	ra,104(sp)
    8000486a:	f0a2                	sd	s0,96(sp)
    8000486c:	eca6                	sd	s1,88(sp)
    8000486e:	e8ca                	sd	s2,80(sp)
    80004870:	e4ce                	sd	s3,72(sp)
    80004872:	e0d2                	sd	s4,64(sp)
    80004874:	fc56                	sd	s5,56(sp)
    80004876:	f85a                	sd	s6,48(sp)
    80004878:	f45e                	sd	s7,40(sp)
    8000487a:	f062                	sd	s8,32(sp)
    8000487c:	ec66                	sd	s9,24(sp)
    8000487e:	1880                	addi	s0,sp,112
    80004880:	84aa                	mv	s1,a0
    80004882:	8b2e                	mv	s6,a1
    80004884:	8ab2                	mv	s5,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    80004886:	ffffd097          	auipc	ra,0xffffd
    8000488a:	fba080e7          	jalr	-70(ra) # 80001840 <myproc>
    8000488e:	8c2a                	mv	s8,a0

  acquire(&pi->lock);
    80004890:	8526                	mv	a0,s1
    80004892:	ffffc097          	auipc	ra,0xffffc
    80004896:	23c080e7          	jalr	572(ra) # 80000ace <acquire>
  for(i = 0; i < n; i++){
    8000489a:	0b505063          	blez	s5,8000493a <pipewrite+0xd4>
    8000489e:	8926                	mv	s2,s1
    800048a0:	fffa8b9b          	addiw	s7,s5,-1
    800048a4:	1b82                	slli	s7,s7,0x20
    800048a6:	020bdb93          	srli	s7,s7,0x20
    800048aa:	001b0793          	addi	a5,s6,1
    800048ae:	9bbe                	add	s7,s7,a5
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || myproc()->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    800048b0:	21848a13          	addi	s4,s1,536
      sleep(&pi->nwrite, &pi->lock);
    800048b4:	21c48993          	addi	s3,s1,540
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800048b8:	5cfd                	li	s9,-1
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    800048ba:	2184a783          	lw	a5,536(s1)
    800048be:	21c4a703          	lw	a4,540(s1)
    800048c2:	2007879b          	addiw	a5,a5,512
    800048c6:	02f71e63          	bne	a4,a5,80004902 <pipewrite+0x9c>
      if(pi->readopen == 0 || myproc()->killed){
    800048ca:	2204a783          	lw	a5,544(s1)
    800048ce:	c3d9                	beqz	a5,80004954 <pipewrite+0xee>
    800048d0:	ffffd097          	auipc	ra,0xffffd
    800048d4:	f70080e7          	jalr	-144(ra) # 80001840 <myproc>
    800048d8:	591c                	lw	a5,48(a0)
    800048da:	efad                	bnez	a5,80004954 <pipewrite+0xee>
      wakeup(&pi->nread);
    800048dc:	8552                	mv	a0,s4
    800048de:	ffffe097          	auipc	ra,0xffffe
    800048e2:	88a080e7          	jalr	-1910(ra) # 80002168 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    800048e6:	85ca                	mv	a1,s2
    800048e8:	854e                	mv	a0,s3
    800048ea:	ffffd097          	auipc	ra,0xffffd
    800048ee:	6f8080e7          	jalr	1784(ra) # 80001fe2 <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    800048f2:	2184a783          	lw	a5,536(s1)
    800048f6:	21c4a703          	lw	a4,540(s1)
    800048fa:	2007879b          	addiw	a5,a5,512
    800048fe:	fcf706e3          	beq	a4,a5,800048ca <pipewrite+0x64>
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004902:	4685                	li	a3,1
    80004904:	865a                	mv	a2,s6
    80004906:	f9f40593          	addi	a1,s0,-97
    8000490a:	050c3503          	ld	a0,80(s8)
    8000490e:	ffffd097          	auipc	ra,0xffffd
    80004912:	cb2080e7          	jalr	-846(ra) # 800015c0 <copyin>
    80004916:	03950263          	beq	a0,s9,8000493a <pipewrite+0xd4>
      break;
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    8000491a:	21c4a783          	lw	a5,540(s1)
    8000491e:	0017871b          	addiw	a4,a5,1
    80004922:	20e4ae23          	sw	a4,540(s1)
    80004926:	1ff7f793          	andi	a5,a5,511
    8000492a:	97a6                	add	a5,a5,s1
    8000492c:	f9f44703          	lbu	a4,-97(s0)
    80004930:	00e78c23          	sb	a4,24(a5)
  for(i = 0; i < n; i++){
    80004934:	0b05                	addi	s6,s6,1
    80004936:	f97b12e3          	bne	s6,s7,800048ba <pipewrite+0x54>
  }
  wakeup(&pi->nread);
    8000493a:	21848513          	addi	a0,s1,536
    8000493e:	ffffe097          	auipc	ra,0xffffe
    80004942:	82a080e7          	jalr	-2006(ra) # 80002168 <wakeup>
  release(&pi->lock);
    80004946:	8526                	mv	a0,s1
    80004948:	ffffc097          	auipc	ra,0xffffc
    8000494c:	1da080e7          	jalr	474(ra) # 80000b22 <release>
  return n;
    80004950:	8556                	mv	a0,s5
    80004952:	a039                	j	80004960 <pipewrite+0xfa>
        release(&pi->lock);
    80004954:	8526                	mv	a0,s1
    80004956:	ffffc097          	auipc	ra,0xffffc
    8000495a:	1cc080e7          	jalr	460(ra) # 80000b22 <release>
        return -1;
    8000495e:	557d                	li	a0,-1
}
    80004960:	70a6                	ld	ra,104(sp)
    80004962:	7406                	ld	s0,96(sp)
    80004964:	64e6                	ld	s1,88(sp)
    80004966:	6946                	ld	s2,80(sp)
    80004968:	69a6                	ld	s3,72(sp)
    8000496a:	6a06                	ld	s4,64(sp)
    8000496c:	7ae2                	ld	s5,56(sp)
    8000496e:	7b42                	ld	s6,48(sp)
    80004970:	7ba2                	ld	s7,40(sp)
    80004972:	7c02                	ld	s8,32(sp)
    80004974:	6ce2                	ld	s9,24(sp)
    80004976:	6165                	addi	sp,sp,112
    80004978:	8082                	ret

000000008000497a <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    8000497a:	715d                	addi	sp,sp,-80
    8000497c:	e486                	sd	ra,72(sp)
    8000497e:	e0a2                	sd	s0,64(sp)
    80004980:	fc26                	sd	s1,56(sp)
    80004982:	f84a                	sd	s2,48(sp)
    80004984:	f44e                	sd	s3,40(sp)
    80004986:	f052                	sd	s4,32(sp)
    80004988:	ec56                	sd	s5,24(sp)
    8000498a:	e85a                	sd	s6,16(sp)
    8000498c:	0880                	addi	s0,sp,80
    8000498e:	84aa                	mv	s1,a0
    80004990:	892e                	mv	s2,a1
    80004992:	8a32                	mv	s4,a2
  int i;
  struct proc *pr = myproc();
    80004994:	ffffd097          	auipc	ra,0xffffd
    80004998:	eac080e7          	jalr	-340(ra) # 80001840 <myproc>
    8000499c:	8aaa                	mv	s5,a0
  char ch;

  acquire(&pi->lock);
    8000499e:	8b26                	mv	s6,s1
    800049a0:	8526                	mv	a0,s1
    800049a2:	ffffc097          	auipc	ra,0xffffc
    800049a6:	12c080e7          	jalr	300(ra) # 80000ace <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800049aa:	2184a703          	lw	a4,536(s1)
    800049ae:	21c4a783          	lw	a5,540(s1)
    if(myproc()->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800049b2:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800049b6:	02f71763          	bne	a4,a5,800049e4 <piperead+0x6a>
    800049ba:	2244a783          	lw	a5,548(s1)
    800049be:	c39d                	beqz	a5,800049e4 <piperead+0x6a>
    if(myproc()->killed){
    800049c0:	ffffd097          	auipc	ra,0xffffd
    800049c4:	e80080e7          	jalr	-384(ra) # 80001840 <myproc>
    800049c8:	591c                	lw	a5,48(a0)
    800049ca:	ebc1                	bnez	a5,80004a5a <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800049cc:	85da                	mv	a1,s6
    800049ce:	854e                	mv	a0,s3
    800049d0:	ffffd097          	auipc	ra,0xffffd
    800049d4:	612080e7          	jalr	1554(ra) # 80001fe2 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800049d8:	2184a703          	lw	a4,536(s1)
    800049dc:	21c4a783          	lw	a5,540(s1)
    800049e0:	fcf70de3          	beq	a4,a5,800049ba <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800049e4:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800049e6:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800049e8:	05405363          	blez	s4,80004a2e <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    800049ec:	2184a783          	lw	a5,536(s1)
    800049f0:	21c4a703          	lw	a4,540(s1)
    800049f4:	02f70d63          	beq	a4,a5,80004a2e <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    800049f8:	0017871b          	addiw	a4,a5,1
    800049fc:	20e4ac23          	sw	a4,536(s1)
    80004a00:	1ff7f793          	andi	a5,a5,511
    80004a04:	97a6                	add	a5,a5,s1
    80004a06:	0187c783          	lbu	a5,24(a5)
    80004a0a:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004a0e:	4685                	li	a3,1
    80004a10:	fbf40613          	addi	a2,s0,-65
    80004a14:	85ca                	mv	a1,s2
    80004a16:	050ab503          	ld	a0,80(s5)
    80004a1a:	ffffd097          	auipc	ra,0xffffd
    80004a1e:	b1a080e7          	jalr	-1254(ra) # 80001534 <copyout>
    80004a22:	01650663          	beq	a0,s6,80004a2e <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004a26:	2985                	addiw	s3,s3,1
    80004a28:	0905                	addi	s2,s2,1
    80004a2a:	fd3a11e3          	bne	s4,s3,800049ec <piperead+0x72>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004a2e:	21c48513          	addi	a0,s1,540
    80004a32:	ffffd097          	auipc	ra,0xffffd
    80004a36:	736080e7          	jalr	1846(ra) # 80002168 <wakeup>
  release(&pi->lock);
    80004a3a:	8526                	mv	a0,s1
    80004a3c:	ffffc097          	auipc	ra,0xffffc
    80004a40:	0e6080e7          	jalr	230(ra) # 80000b22 <release>
  return i;
}
    80004a44:	854e                	mv	a0,s3
    80004a46:	60a6                	ld	ra,72(sp)
    80004a48:	6406                	ld	s0,64(sp)
    80004a4a:	74e2                	ld	s1,56(sp)
    80004a4c:	7942                	ld	s2,48(sp)
    80004a4e:	79a2                	ld	s3,40(sp)
    80004a50:	7a02                	ld	s4,32(sp)
    80004a52:	6ae2                	ld	s5,24(sp)
    80004a54:	6b42                	ld	s6,16(sp)
    80004a56:	6161                	addi	sp,sp,80
    80004a58:	8082                	ret
      release(&pi->lock);
    80004a5a:	8526                	mv	a0,s1
    80004a5c:	ffffc097          	auipc	ra,0xffffc
    80004a60:	0c6080e7          	jalr	198(ra) # 80000b22 <release>
      return -1;
    80004a64:	59fd                	li	s3,-1
    80004a66:	bff9                	j	80004a44 <piperead+0xca>

0000000080004a68 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004a68:	df010113          	addi	sp,sp,-528
    80004a6c:	20113423          	sd	ra,520(sp)
    80004a70:	20813023          	sd	s0,512(sp)
    80004a74:	ffa6                	sd	s1,504(sp)
    80004a76:	fbca                	sd	s2,496(sp)
    80004a78:	f7ce                	sd	s3,488(sp)
    80004a7a:	f3d2                	sd	s4,480(sp)
    80004a7c:	efd6                	sd	s5,472(sp)
    80004a7e:	ebda                	sd	s6,464(sp)
    80004a80:	e7de                	sd	s7,456(sp)
    80004a82:	e3e2                	sd	s8,448(sp)
    80004a84:	ff66                	sd	s9,440(sp)
    80004a86:	fb6a                	sd	s10,432(sp)
    80004a88:	f76e                	sd	s11,424(sp)
    80004a8a:	0c00                	addi	s0,sp,528
    80004a8c:	84aa                	mv	s1,a0
    80004a8e:	dea43c23          	sd	a0,-520(s0)
    80004a92:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004a96:	ffffd097          	auipc	ra,0xffffd
    80004a9a:	daa080e7          	jalr	-598(ra) # 80001840 <myproc>
    80004a9e:	892a                	mv	s2,a0

  begin_op();
    80004aa0:	fffff097          	auipc	ra,0xfffff
    80004aa4:	454080e7          	jalr	1108(ra) # 80003ef4 <begin_op>

  if((ip = namei(path)) == 0){
    80004aa8:	8526                	mv	a0,s1
    80004aaa:	fffff097          	auipc	ra,0xfffff
    80004aae:	23e080e7          	jalr	574(ra) # 80003ce8 <namei>
    80004ab2:	c92d                	beqz	a0,80004b24 <exec+0xbc>
    80004ab4:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004ab6:	fffff097          	auipc	ra,0xfffff
    80004aba:	aa8080e7          	jalr	-1368(ra) # 8000355e <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004abe:	04000713          	li	a4,64
    80004ac2:	4681                	li	a3,0
    80004ac4:	e4840613          	addi	a2,s0,-440
    80004ac8:	4581                	li	a1,0
    80004aca:	8526                	mv	a0,s1
    80004acc:	fffff097          	auipc	ra,0xfffff
    80004ad0:	d22080e7          	jalr	-734(ra) # 800037ee <readi>
    80004ad4:	04000793          	li	a5,64
    80004ad8:	00f51a63          	bne	a0,a5,80004aec <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004adc:	e4842703          	lw	a4,-440(s0)
    80004ae0:	464c47b7          	lui	a5,0x464c4
    80004ae4:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004ae8:	04f70463          	beq	a4,a5,80004b30 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004aec:	8526                	mv	a0,s1
    80004aee:	fffff097          	auipc	ra,0xfffff
    80004af2:	cae080e7          	jalr	-850(ra) # 8000379c <iunlockput>
    end_op();
    80004af6:	fffff097          	auipc	ra,0xfffff
    80004afa:	47e080e7          	jalr	1150(ra) # 80003f74 <end_op>
  }
  return -1;
    80004afe:	557d                	li	a0,-1
}
    80004b00:	20813083          	ld	ra,520(sp)
    80004b04:	20013403          	ld	s0,512(sp)
    80004b08:	74fe                	ld	s1,504(sp)
    80004b0a:	795e                	ld	s2,496(sp)
    80004b0c:	79be                	ld	s3,488(sp)
    80004b0e:	7a1e                	ld	s4,480(sp)
    80004b10:	6afe                	ld	s5,472(sp)
    80004b12:	6b5e                	ld	s6,464(sp)
    80004b14:	6bbe                	ld	s7,456(sp)
    80004b16:	6c1e                	ld	s8,448(sp)
    80004b18:	7cfa                	ld	s9,440(sp)
    80004b1a:	7d5a                	ld	s10,432(sp)
    80004b1c:	7dba                	ld	s11,424(sp)
    80004b1e:	21010113          	addi	sp,sp,528
    80004b22:	8082                	ret
    end_op();
    80004b24:	fffff097          	auipc	ra,0xfffff
    80004b28:	450080e7          	jalr	1104(ra) # 80003f74 <end_op>
    return -1;
    80004b2c:	557d                	li	a0,-1
    80004b2e:	bfc9                	j	80004b00 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004b30:	854a                	mv	a0,s2
    80004b32:	ffffd097          	auipc	ra,0xffffd
    80004b36:	dd2080e7          	jalr	-558(ra) # 80001904 <proc_pagetable>
    80004b3a:	8c2a                	mv	s8,a0
    80004b3c:	d945                	beqz	a0,80004aec <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004b3e:	e6842983          	lw	s3,-408(s0)
    80004b42:	e8045783          	lhu	a5,-384(s0)
    80004b46:	c7fd                	beqz	a5,80004c34 <exec+0x1cc>
  sz = 0;
    80004b48:	e0043423          	sd	zero,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004b4c:	4b81                	li	s7,0
    if(ph.vaddr % PGSIZE != 0)
    80004b4e:	6b05                	lui	s6,0x1
    80004b50:	fffb0793          	addi	a5,s6,-1 # fff <_entry-0x7ffff001>
    80004b54:	def43823          	sd	a5,-528(s0)
    80004b58:	a0a5                	j	80004bc0 <exec+0x158>
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004b5a:	00003517          	auipc	a0,0x3
    80004b5e:	b4e50513          	addi	a0,a0,-1202 # 800076a8 <userret+0x618>
    80004b62:	ffffc097          	auipc	ra,0xffffc
    80004b66:	9ec080e7          	jalr	-1556(ra) # 8000054e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004b6a:	8756                	mv	a4,s5
    80004b6c:	012d86bb          	addw	a3,s11,s2
    80004b70:	4581                	li	a1,0
    80004b72:	8526                	mv	a0,s1
    80004b74:	fffff097          	auipc	ra,0xfffff
    80004b78:	c7a080e7          	jalr	-902(ra) # 800037ee <readi>
    80004b7c:	2501                	sext.w	a0,a0
    80004b7e:	10aa9163          	bne	s5,a0,80004c80 <exec+0x218>
  for(i = 0; i < sz; i += PGSIZE){
    80004b82:	6785                	lui	a5,0x1
    80004b84:	0127893b          	addw	s2,a5,s2
    80004b88:	77fd                	lui	a5,0xfffff
    80004b8a:	01478a3b          	addw	s4,a5,s4
    80004b8e:	03997263          	bgeu	s2,s9,80004bb2 <exec+0x14a>
    pa = walkaddr(pagetable, va + i);
    80004b92:	02091593          	slli	a1,s2,0x20
    80004b96:	9181                	srli	a1,a1,0x20
    80004b98:	95ea                	add	a1,a1,s10
    80004b9a:	8562                	mv	a0,s8
    80004b9c:	ffffc097          	auipc	ra,0xffffc
    80004ba0:	3ca080e7          	jalr	970(ra) # 80000f66 <walkaddr>
    80004ba4:	862a                	mv	a2,a0
    if(pa == 0)
    80004ba6:	d955                	beqz	a0,80004b5a <exec+0xf2>
      n = PGSIZE;
    80004ba8:	8ada                	mv	s5,s6
    if(sz - i < PGSIZE)
    80004baa:	fd6a70e3          	bgeu	s4,s6,80004b6a <exec+0x102>
      n = sz - i;
    80004bae:	8ad2                	mv	s5,s4
    80004bb0:	bf6d                	j	80004b6a <exec+0x102>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004bb2:	2b85                	addiw	s7,s7,1
    80004bb4:	0389899b          	addiw	s3,s3,56
    80004bb8:	e8045783          	lhu	a5,-384(s0)
    80004bbc:	06fbde63          	bge	s7,a5,80004c38 <exec+0x1d0>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004bc0:	2981                	sext.w	s3,s3
    80004bc2:	03800713          	li	a4,56
    80004bc6:	86ce                	mv	a3,s3
    80004bc8:	e1040613          	addi	a2,s0,-496
    80004bcc:	4581                	li	a1,0
    80004bce:	8526                	mv	a0,s1
    80004bd0:	fffff097          	auipc	ra,0xfffff
    80004bd4:	c1e080e7          	jalr	-994(ra) # 800037ee <readi>
    80004bd8:	03800793          	li	a5,56
    80004bdc:	0af51263          	bne	a0,a5,80004c80 <exec+0x218>
    if(ph.type != ELF_PROG_LOAD)
    80004be0:	e1042783          	lw	a5,-496(s0)
    80004be4:	4705                	li	a4,1
    80004be6:	fce796e3          	bne	a5,a4,80004bb2 <exec+0x14a>
    if(ph.memsz < ph.filesz)
    80004bea:	e3843603          	ld	a2,-456(s0)
    80004bee:	e3043783          	ld	a5,-464(s0)
    80004bf2:	08f66763          	bltu	a2,a5,80004c80 <exec+0x218>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004bf6:	e2043783          	ld	a5,-480(s0)
    80004bfa:	963e                	add	a2,a2,a5
    80004bfc:	08f66263          	bltu	a2,a5,80004c80 <exec+0x218>
    if((sz = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004c00:	e0843583          	ld	a1,-504(s0)
    80004c04:	8562                	mv	a0,s8
    80004c06:	ffffc097          	auipc	ra,0xffffc
    80004c0a:	754080e7          	jalr	1876(ra) # 8000135a <uvmalloc>
    80004c0e:	e0a43423          	sd	a0,-504(s0)
    80004c12:	c53d                	beqz	a0,80004c80 <exec+0x218>
    if(ph.vaddr % PGSIZE != 0)
    80004c14:	e2043d03          	ld	s10,-480(s0)
    80004c18:	df043783          	ld	a5,-528(s0)
    80004c1c:	00fd77b3          	and	a5,s10,a5
    80004c20:	e3a5                	bnez	a5,80004c80 <exec+0x218>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004c22:	e1842d83          	lw	s11,-488(s0)
    80004c26:	e3042c83          	lw	s9,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004c2a:	f80c84e3          	beqz	s9,80004bb2 <exec+0x14a>
    80004c2e:	8a66                	mv	s4,s9
    80004c30:	4901                	li	s2,0
    80004c32:	b785                	j	80004b92 <exec+0x12a>
  sz = 0;
    80004c34:	e0043423          	sd	zero,-504(s0)
  iunlockput(ip);
    80004c38:	8526                	mv	a0,s1
    80004c3a:	fffff097          	auipc	ra,0xfffff
    80004c3e:	b62080e7          	jalr	-1182(ra) # 8000379c <iunlockput>
  end_op();
    80004c42:	fffff097          	auipc	ra,0xfffff
    80004c46:	332080e7          	jalr	818(ra) # 80003f74 <end_op>
  p = myproc();
    80004c4a:	ffffd097          	auipc	ra,0xffffd
    80004c4e:	bf6080e7          	jalr	-1034(ra) # 80001840 <myproc>
    80004c52:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004c54:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004c58:	6585                	lui	a1,0x1
    80004c5a:	15fd                	addi	a1,a1,-1
    80004c5c:	e0843783          	ld	a5,-504(s0)
    80004c60:	00b78b33          	add	s6,a5,a1
    80004c64:	75fd                	lui	a1,0xfffff
    80004c66:	00bb75b3          	and	a1,s6,a1
  if((sz = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004c6a:	6609                	lui	a2,0x2
    80004c6c:	962e                	add	a2,a2,a1
    80004c6e:	8562                	mv	a0,s8
    80004c70:	ffffc097          	auipc	ra,0xffffc
    80004c74:	6ea080e7          	jalr	1770(ra) # 8000135a <uvmalloc>
    80004c78:	e0a43423          	sd	a0,-504(s0)
  ip = 0;
    80004c7c:	4481                	li	s1,0
  if((sz = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004c7e:	ed01                	bnez	a0,80004c96 <exec+0x22e>
    proc_freepagetable(pagetable, sz);
    80004c80:	e0843583          	ld	a1,-504(s0)
    80004c84:	8562                	mv	a0,s8
    80004c86:	ffffd097          	auipc	ra,0xffffd
    80004c8a:	d7e080e7          	jalr	-642(ra) # 80001a04 <proc_freepagetable>
  if(ip){
    80004c8e:	e4049fe3          	bnez	s1,80004aec <exec+0x84>
  return -1;
    80004c92:	557d                	li	a0,-1
    80004c94:	b5b5                	j	80004b00 <exec+0x98>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004c96:	75f9                	lui	a1,0xffffe
    80004c98:	84aa                	mv	s1,a0
    80004c9a:	95aa                	add	a1,a1,a0
    80004c9c:	8562                	mv	a0,s8
    80004c9e:	ffffd097          	auipc	ra,0xffffd
    80004ca2:	864080e7          	jalr	-1948(ra) # 80001502 <uvmclear>
  stackbase = sp - PGSIZE;
    80004ca6:	7afd                	lui	s5,0xfffff
    80004ca8:	9aa6                	add	s5,s5,s1
  for(argc = 0; argv[argc]; argc++) {
    80004caa:	e0043783          	ld	a5,-512(s0)
    80004cae:	6388                	ld	a0,0(a5)
    80004cb0:	c135                	beqz	a0,80004d14 <exec+0x2ac>
    80004cb2:	e8840993          	addi	s3,s0,-376
    80004cb6:	f8840c93          	addi	s9,s0,-120
    80004cba:	4901                	li	s2,0
    sp -= strlen(argv[argc]) + 1;
    80004cbc:	ffffc097          	auipc	ra,0xffffc
    80004cc0:	036080e7          	jalr	54(ra) # 80000cf2 <strlen>
    80004cc4:	2505                	addiw	a0,a0,1
    80004cc6:	8c89                	sub	s1,s1,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004cc8:	98c1                	andi	s1,s1,-16
    if(sp < stackbase)
    80004cca:	0f54ea63          	bltu	s1,s5,80004dbe <exec+0x356>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004cce:	e0043b03          	ld	s6,-512(s0)
    80004cd2:	000b3a03          	ld	s4,0(s6)
    80004cd6:	8552                	mv	a0,s4
    80004cd8:	ffffc097          	auipc	ra,0xffffc
    80004cdc:	01a080e7          	jalr	26(ra) # 80000cf2 <strlen>
    80004ce0:	0015069b          	addiw	a3,a0,1
    80004ce4:	8652                	mv	a2,s4
    80004ce6:	85a6                	mv	a1,s1
    80004ce8:	8562                	mv	a0,s8
    80004cea:	ffffd097          	auipc	ra,0xffffd
    80004cee:	84a080e7          	jalr	-1974(ra) # 80001534 <copyout>
    80004cf2:	0c054863          	bltz	a0,80004dc2 <exec+0x35a>
    ustack[argc] = sp;
    80004cf6:	0099b023          	sd	s1,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004cfa:	0905                	addi	s2,s2,1
    80004cfc:	008b0793          	addi	a5,s6,8
    80004d00:	e0f43023          	sd	a5,-512(s0)
    80004d04:	008b3503          	ld	a0,8(s6)
    80004d08:	c909                	beqz	a0,80004d1a <exec+0x2b2>
    if(argc >= MAXARG)
    80004d0a:	09a1                	addi	s3,s3,8
    80004d0c:	fb3c98e3          	bne	s9,s3,80004cbc <exec+0x254>
  ip = 0;
    80004d10:	4481                	li	s1,0
    80004d12:	b7bd                	j	80004c80 <exec+0x218>
  sp = sz;
    80004d14:	e0843483          	ld	s1,-504(s0)
  for(argc = 0; argv[argc]; argc++) {
    80004d18:	4901                	li	s2,0
  ustack[argc] = 0;
    80004d1a:	00391793          	slli	a5,s2,0x3
    80004d1e:	f9040713          	addi	a4,s0,-112
    80004d22:	97ba                	add	a5,a5,a4
    80004d24:	ee07bc23          	sd	zero,-264(a5) # ffffffffffffeef8 <end+0xffffffff7ffd8ec4>
  sp -= (argc+1) * sizeof(uint64);
    80004d28:	00190693          	addi	a3,s2,1
    80004d2c:	068e                	slli	a3,a3,0x3
    80004d2e:	8c95                	sub	s1,s1,a3
  sp -= sp % 16;
    80004d30:	ff04f993          	andi	s3,s1,-16
  ip = 0;
    80004d34:	4481                	li	s1,0
  if(sp < stackbase)
    80004d36:	f559e5e3          	bltu	s3,s5,80004c80 <exec+0x218>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004d3a:	e8840613          	addi	a2,s0,-376
    80004d3e:	85ce                	mv	a1,s3
    80004d40:	8562                	mv	a0,s8
    80004d42:	ffffc097          	auipc	ra,0xffffc
    80004d46:	7f2080e7          	jalr	2034(ra) # 80001534 <copyout>
    80004d4a:	06054e63          	bltz	a0,80004dc6 <exec+0x35e>
  p->tf->a1 = sp;
    80004d4e:	058bb783          	ld	a5,88(s7) # 1058 <_entry-0x7fffefa8>
    80004d52:	0737bc23          	sd	s3,120(a5)
  for(last=s=path; *s; s++)
    80004d56:	df843783          	ld	a5,-520(s0)
    80004d5a:	0007c703          	lbu	a4,0(a5)
    80004d5e:	cf11                	beqz	a4,80004d7a <exec+0x312>
    80004d60:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004d62:	02f00693          	li	a3,47
    80004d66:	a029                	j	80004d70 <exec+0x308>
  for(last=s=path; *s; s++)
    80004d68:	0785                	addi	a5,a5,1
    80004d6a:	fff7c703          	lbu	a4,-1(a5)
    80004d6e:	c711                	beqz	a4,80004d7a <exec+0x312>
    if(*s == '/')
    80004d70:	fed71ce3          	bne	a4,a3,80004d68 <exec+0x300>
      last = s+1;
    80004d74:	def43c23          	sd	a5,-520(s0)
    80004d78:	bfc5                	j	80004d68 <exec+0x300>
  safestrcpy(p->name, last, sizeof(p->name));
    80004d7a:	4641                	li	a2,16
    80004d7c:	df843583          	ld	a1,-520(s0)
    80004d80:	158b8513          	addi	a0,s7,344
    80004d84:	ffffc097          	auipc	ra,0xffffc
    80004d88:	f3c080e7          	jalr	-196(ra) # 80000cc0 <safestrcpy>
  oldpagetable = p->pagetable;
    80004d8c:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80004d90:	058bb823          	sd	s8,80(s7)
  p->sz = sz;
    80004d94:	e0843783          	ld	a5,-504(s0)
    80004d98:	04fbb423          	sd	a5,72(s7)
  p->tf->epc = elf.entry;  // initial program counter = main
    80004d9c:	058bb783          	ld	a5,88(s7)
    80004da0:	e6043703          	ld	a4,-416(s0)
    80004da4:	ef98                	sd	a4,24(a5)
  p->tf->sp = sp; // initial stack pointer
    80004da6:	058bb783          	ld	a5,88(s7)
    80004daa:	0337b823          	sd	s3,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004dae:	85ea                	mv	a1,s10
    80004db0:	ffffd097          	auipc	ra,0xffffd
    80004db4:	c54080e7          	jalr	-940(ra) # 80001a04 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004db8:	0009051b          	sext.w	a0,s2
    80004dbc:	b391                	j	80004b00 <exec+0x98>
  ip = 0;
    80004dbe:	4481                	li	s1,0
    80004dc0:	b5c1                	j	80004c80 <exec+0x218>
    80004dc2:	4481                	li	s1,0
    80004dc4:	bd75                	j	80004c80 <exec+0x218>
    80004dc6:	4481                	li	s1,0
    80004dc8:	bd65                	j	80004c80 <exec+0x218>

0000000080004dca <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80004dca:	7179                	addi	sp,sp,-48
    80004dcc:	f406                	sd	ra,40(sp)
    80004dce:	f022                	sd	s0,32(sp)
    80004dd0:	ec26                	sd	s1,24(sp)
    80004dd2:	e84a                	sd	s2,16(sp)
    80004dd4:	1800                	addi	s0,sp,48
    80004dd6:	892e                	mv	s2,a1
    80004dd8:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80004dda:	fdc40593          	addi	a1,s0,-36
    80004dde:	ffffe097          	auipc	ra,0xffffe
    80004de2:	c0e080e7          	jalr	-1010(ra) # 800029ec <argint>
    80004de6:	04054063          	bltz	a0,80004e26 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80004dea:	fdc42703          	lw	a4,-36(s0)
    80004dee:	47bd                	li	a5,15
    80004df0:	02e7ed63          	bltu	a5,a4,80004e2a <argfd+0x60>
    80004df4:	ffffd097          	auipc	ra,0xffffd
    80004df8:	a4c080e7          	jalr	-1460(ra) # 80001840 <myproc>
    80004dfc:	fdc42703          	lw	a4,-36(s0)
    80004e00:	01a70793          	addi	a5,a4,26
    80004e04:	078e                	slli	a5,a5,0x3
    80004e06:	953e                	add	a0,a0,a5
    80004e08:	611c                	ld	a5,0(a0)
    80004e0a:	c395                	beqz	a5,80004e2e <argfd+0x64>
    return -1;
  if(pfd)
    80004e0c:	00090463          	beqz	s2,80004e14 <argfd+0x4a>
    *pfd = fd;
    80004e10:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80004e14:	4501                	li	a0,0
  if(pf)
    80004e16:	c091                	beqz	s1,80004e1a <argfd+0x50>
    *pf = f;
    80004e18:	e09c                	sd	a5,0(s1)
}
    80004e1a:	70a2                	ld	ra,40(sp)
    80004e1c:	7402                	ld	s0,32(sp)
    80004e1e:	64e2                	ld	s1,24(sp)
    80004e20:	6942                	ld	s2,16(sp)
    80004e22:	6145                	addi	sp,sp,48
    80004e24:	8082                	ret
    return -1;
    80004e26:	557d                	li	a0,-1
    80004e28:	bfcd                	j	80004e1a <argfd+0x50>
    return -1;
    80004e2a:	557d                	li	a0,-1
    80004e2c:	b7fd                	j	80004e1a <argfd+0x50>
    80004e2e:	557d                	li	a0,-1
    80004e30:	b7ed                	j	80004e1a <argfd+0x50>

0000000080004e32 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80004e32:	1101                	addi	sp,sp,-32
    80004e34:	ec06                	sd	ra,24(sp)
    80004e36:	e822                	sd	s0,16(sp)
    80004e38:	e426                	sd	s1,8(sp)
    80004e3a:	1000                	addi	s0,sp,32
    80004e3c:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80004e3e:	ffffd097          	auipc	ra,0xffffd
    80004e42:	a02080e7          	jalr	-1534(ra) # 80001840 <myproc>
    80004e46:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80004e48:	0d050793          	addi	a5,a0,208
    80004e4c:	4501                	li	a0,0
    80004e4e:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80004e50:	6398                	ld	a4,0(a5)
    80004e52:	cb19                	beqz	a4,80004e68 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80004e54:	2505                	addiw	a0,a0,1
    80004e56:	07a1                	addi	a5,a5,8
    80004e58:	fed51ce3          	bne	a0,a3,80004e50 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80004e5c:	557d                	li	a0,-1
}
    80004e5e:	60e2                	ld	ra,24(sp)
    80004e60:	6442                	ld	s0,16(sp)
    80004e62:	64a2                	ld	s1,8(sp)
    80004e64:	6105                	addi	sp,sp,32
    80004e66:	8082                	ret
      p->ofile[fd] = f;
    80004e68:	01a50793          	addi	a5,a0,26
    80004e6c:	078e                	slli	a5,a5,0x3
    80004e6e:	963e                	add	a2,a2,a5
    80004e70:	e204                	sd	s1,0(a2)
      return fd;
    80004e72:	b7f5                	j	80004e5e <fdalloc+0x2c>

0000000080004e74 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80004e74:	715d                	addi	sp,sp,-80
    80004e76:	e486                	sd	ra,72(sp)
    80004e78:	e0a2                	sd	s0,64(sp)
    80004e7a:	fc26                	sd	s1,56(sp)
    80004e7c:	f84a                	sd	s2,48(sp)
    80004e7e:	f44e                	sd	s3,40(sp)
    80004e80:	f052                	sd	s4,32(sp)
    80004e82:	ec56                	sd	s5,24(sp)
    80004e84:	0880                	addi	s0,sp,80
    80004e86:	89ae                	mv	s3,a1
    80004e88:	8ab2                	mv	s5,a2
    80004e8a:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80004e8c:	fb040593          	addi	a1,s0,-80
    80004e90:	fffff097          	auipc	ra,0xfffff
    80004e94:	e76080e7          	jalr	-394(ra) # 80003d06 <nameiparent>
    80004e98:	892a                	mv	s2,a0
    80004e9a:	12050e63          	beqz	a0,80004fd6 <create+0x162>
    return 0;

  ilock(dp);
    80004e9e:	ffffe097          	auipc	ra,0xffffe
    80004ea2:	6c0080e7          	jalr	1728(ra) # 8000355e <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80004ea6:	4601                	li	a2,0
    80004ea8:	fb040593          	addi	a1,s0,-80
    80004eac:	854a                	mv	a0,s2
    80004eae:	fffff097          	auipc	ra,0xfffff
    80004eb2:	b68080e7          	jalr	-1176(ra) # 80003a16 <dirlookup>
    80004eb6:	84aa                	mv	s1,a0
    80004eb8:	c921                	beqz	a0,80004f08 <create+0x94>
    iunlockput(dp);
    80004eba:	854a                	mv	a0,s2
    80004ebc:	fffff097          	auipc	ra,0xfffff
    80004ec0:	8e0080e7          	jalr	-1824(ra) # 8000379c <iunlockput>
    ilock(ip);
    80004ec4:	8526                	mv	a0,s1
    80004ec6:	ffffe097          	auipc	ra,0xffffe
    80004eca:	698080e7          	jalr	1688(ra) # 8000355e <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80004ece:	2981                	sext.w	s3,s3
    80004ed0:	4789                	li	a5,2
    80004ed2:	02f99463          	bne	s3,a5,80004efa <create+0x86>
    80004ed6:	0444d783          	lhu	a5,68(s1)
    80004eda:	37f9                	addiw	a5,a5,-2
    80004edc:	17c2                	slli	a5,a5,0x30
    80004ede:	93c1                	srli	a5,a5,0x30
    80004ee0:	4705                	li	a4,1
    80004ee2:	00f76c63          	bltu	a4,a5,80004efa <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80004ee6:	8526                	mv	a0,s1
    80004ee8:	60a6                	ld	ra,72(sp)
    80004eea:	6406                	ld	s0,64(sp)
    80004eec:	74e2                	ld	s1,56(sp)
    80004eee:	7942                	ld	s2,48(sp)
    80004ef0:	79a2                	ld	s3,40(sp)
    80004ef2:	7a02                	ld	s4,32(sp)
    80004ef4:	6ae2                	ld	s5,24(sp)
    80004ef6:	6161                	addi	sp,sp,80
    80004ef8:	8082                	ret
    iunlockput(ip);
    80004efa:	8526                	mv	a0,s1
    80004efc:	fffff097          	auipc	ra,0xfffff
    80004f00:	8a0080e7          	jalr	-1888(ra) # 8000379c <iunlockput>
    return 0;
    80004f04:	4481                	li	s1,0
    80004f06:	b7c5                	j	80004ee6 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80004f08:	85ce                	mv	a1,s3
    80004f0a:	00092503          	lw	a0,0(s2)
    80004f0e:	ffffe097          	auipc	ra,0xffffe
    80004f12:	4b8080e7          	jalr	1208(ra) # 800033c6 <ialloc>
    80004f16:	84aa                	mv	s1,a0
    80004f18:	c521                	beqz	a0,80004f60 <create+0xec>
  ilock(ip);
    80004f1a:	ffffe097          	auipc	ra,0xffffe
    80004f1e:	644080e7          	jalr	1604(ra) # 8000355e <ilock>
  ip->major = major;
    80004f22:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80004f26:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80004f2a:	4a05                	li	s4,1
    80004f2c:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    80004f30:	8526                	mv	a0,s1
    80004f32:	ffffe097          	auipc	ra,0xffffe
    80004f36:	562080e7          	jalr	1378(ra) # 80003494 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80004f3a:	2981                	sext.w	s3,s3
    80004f3c:	03498a63          	beq	s3,s4,80004f70 <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    80004f40:	40d0                	lw	a2,4(s1)
    80004f42:	fb040593          	addi	a1,s0,-80
    80004f46:	854a                	mv	a0,s2
    80004f48:	fffff097          	auipc	ra,0xfffff
    80004f4c:	cde080e7          	jalr	-802(ra) # 80003c26 <dirlink>
    80004f50:	06054b63          	bltz	a0,80004fc6 <create+0x152>
  iunlockput(dp);
    80004f54:	854a                	mv	a0,s2
    80004f56:	fffff097          	auipc	ra,0xfffff
    80004f5a:	846080e7          	jalr	-1978(ra) # 8000379c <iunlockput>
  return ip;
    80004f5e:	b761                	j	80004ee6 <create+0x72>
    panic("create: ialloc");
    80004f60:	00002517          	auipc	a0,0x2
    80004f64:	76850513          	addi	a0,a0,1896 # 800076c8 <userret+0x638>
    80004f68:	ffffb097          	auipc	ra,0xffffb
    80004f6c:	5e6080e7          	jalr	1510(ra) # 8000054e <panic>
    dp->nlink++;  // for ".."
    80004f70:	04a95783          	lhu	a5,74(s2)
    80004f74:	2785                	addiw	a5,a5,1
    80004f76:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80004f7a:	854a                	mv	a0,s2
    80004f7c:	ffffe097          	auipc	ra,0xffffe
    80004f80:	518080e7          	jalr	1304(ra) # 80003494 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80004f84:	40d0                	lw	a2,4(s1)
    80004f86:	00002597          	auipc	a1,0x2
    80004f8a:	75258593          	addi	a1,a1,1874 # 800076d8 <userret+0x648>
    80004f8e:	8526                	mv	a0,s1
    80004f90:	fffff097          	auipc	ra,0xfffff
    80004f94:	c96080e7          	jalr	-874(ra) # 80003c26 <dirlink>
    80004f98:	00054f63          	bltz	a0,80004fb6 <create+0x142>
    80004f9c:	00492603          	lw	a2,4(s2)
    80004fa0:	00002597          	auipc	a1,0x2
    80004fa4:	74058593          	addi	a1,a1,1856 # 800076e0 <userret+0x650>
    80004fa8:	8526                	mv	a0,s1
    80004faa:	fffff097          	auipc	ra,0xfffff
    80004fae:	c7c080e7          	jalr	-900(ra) # 80003c26 <dirlink>
    80004fb2:	f80557e3          	bgez	a0,80004f40 <create+0xcc>
      panic("create dots");
    80004fb6:	00002517          	auipc	a0,0x2
    80004fba:	73250513          	addi	a0,a0,1842 # 800076e8 <userret+0x658>
    80004fbe:	ffffb097          	auipc	ra,0xffffb
    80004fc2:	590080e7          	jalr	1424(ra) # 8000054e <panic>
    panic("create: dirlink");
    80004fc6:	00002517          	auipc	a0,0x2
    80004fca:	73250513          	addi	a0,a0,1842 # 800076f8 <userret+0x668>
    80004fce:	ffffb097          	auipc	ra,0xffffb
    80004fd2:	580080e7          	jalr	1408(ra) # 8000054e <panic>
    return 0;
    80004fd6:	84aa                	mv	s1,a0
    80004fd8:	b739                	j	80004ee6 <create+0x72>

0000000080004fda <sys_dup>:
{
    80004fda:	7179                	addi	sp,sp,-48
    80004fdc:	f406                	sd	ra,40(sp)
    80004fde:	f022                	sd	s0,32(sp)
    80004fe0:	ec26                	sd	s1,24(sp)
    80004fe2:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80004fe4:	fd840613          	addi	a2,s0,-40
    80004fe8:	4581                	li	a1,0
    80004fea:	4501                	li	a0,0
    80004fec:	00000097          	auipc	ra,0x0
    80004ff0:	dde080e7          	jalr	-546(ra) # 80004dca <argfd>
    return -1;
    80004ff4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80004ff6:	02054363          	bltz	a0,8000501c <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80004ffa:	fd843503          	ld	a0,-40(s0)
    80004ffe:	00000097          	auipc	ra,0x0
    80005002:	e34080e7          	jalr	-460(ra) # 80004e32 <fdalloc>
    80005006:	84aa                	mv	s1,a0
    return -1;
    80005008:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000500a:	00054963          	bltz	a0,8000501c <sys_dup+0x42>
  filedup(f);
    8000500e:	fd843503          	ld	a0,-40(s0)
    80005012:	fffff097          	auipc	ra,0xfffff
    80005016:	362080e7          	jalr	866(ra) # 80004374 <filedup>
  return fd;
    8000501a:	87a6                	mv	a5,s1
}
    8000501c:	853e                	mv	a0,a5
    8000501e:	70a2                	ld	ra,40(sp)
    80005020:	7402                	ld	s0,32(sp)
    80005022:	64e2                	ld	s1,24(sp)
    80005024:	6145                	addi	sp,sp,48
    80005026:	8082                	ret

0000000080005028 <sys_read>:
{
    80005028:	7179                	addi	sp,sp,-48
    8000502a:	f406                	sd	ra,40(sp)
    8000502c:	f022                	sd	s0,32(sp)
    8000502e:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005030:	fe840613          	addi	a2,s0,-24
    80005034:	4581                	li	a1,0
    80005036:	4501                	li	a0,0
    80005038:	00000097          	auipc	ra,0x0
    8000503c:	d92080e7          	jalr	-622(ra) # 80004dca <argfd>
    return -1;
    80005040:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005042:	04054163          	bltz	a0,80005084 <sys_read+0x5c>
    80005046:	fe440593          	addi	a1,s0,-28
    8000504a:	4509                	li	a0,2
    8000504c:	ffffe097          	auipc	ra,0xffffe
    80005050:	9a0080e7          	jalr	-1632(ra) # 800029ec <argint>
    return -1;
    80005054:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005056:	02054763          	bltz	a0,80005084 <sys_read+0x5c>
    8000505a:	fd840593          	addi	a1,s0,-40
    8000505e:	4505                	li	a0,1
    80005060:	ffffe097          	auipc	ra,0xffffe
    80005064:	9ae080e7          	jalr	-1618(ra) # 80002a0e <argaddr>
    return -1;
    80005068:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000506a:	00054d63          	bltz	a0,80005084 <sys_read+0x5c>
  return fileread(f, p, n);
    8000506e:	fe442603          	lw	a2,-28(s0)
    80005072:	fd843583          	ld	a1,-40(s0)
    80005076:	fe843503          	ld	a0,-24(s0)
    8000507a:	fffff097          	auipc	ra,0xfffff
    8000507e:	486080e7          	jalr	1158(ra) # 80004500 <fileread>
    80005082:	87aa                	mv	a5,a0
}
    80005084:	853e                	mv	a0,a5
    80005086:	70a2                	ld	ra,40(sp)
    80005088:	7402                	ld	s0,32(sp)
    8000508a:	6145                	addi	sp,sp,48
    8000508c:	8082                	ret

000000008000508e <sys_write>:
{
    8000508e:	7179                	addi	sp,sp,-48
    80005090:	f406                	sd	ra,40(sp)
    80005092:	f022                	sd	s0,32(sp)
    80005094:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005096:	fe840613          	addi	a2,s0,-24
    8000509a:	4581                	li	a1,0
    8000509c:	4501                	li	a0,0
    8000509e:	00000097          	auipc	ra,0x0
    800050a2:	d2c080e7          	jalr	-724(ra) # 80004dca <argfd>
    return -1;
    800050a6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800050a8:	04054163          	bltz	a0,800050ea <sys_write+0x5c>
    800050ac:	fe440593          	addi	a1,s0,-28
    800050b0:	4509                	li	a0,2
    800050b2:	ffffe097          	auipc	ra,0xffffe
    800050b6:	93a080e7          	jalr	-1734(ra) # 800029ec <argint>
    return -1;
    800050ba:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800050bc:	02054763          	bltz	a0,800050ea <sys_write+0x5c>
    800050c0:	fd840593          	addi	a1,s0,-40
    800050c4:	4505                	li	a0,1
    800050c6:	ffffe097          	auipc	ra,0xffffe
    800050ca:	948080e7          	jalr	-1720(ra) # 80002a0e <argaddr>
    return -1;
    800050ce:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800050d0:	00054d63          	bltz	a0,800050ea <sys_write+0x5c>
  return filewrite(f, p, n);
    800050d4:	fe442603          	lw	a2,-28(s0)
    800050d8:	fd843583          	ld	a1,-40(s0)
    800050dc:	fe843503          	ld	a0,-24(s0)
    800050e0:	fffff097          	auipc	ra,0xfffff
    800050e4:	4e2080e7          	jalr	1250(ra) # 800045c2 <filewrite>
    800050e8:	87aa                	mv	a5,a0
}
    800050ea:	853e                	mv	a0,a5
    800050ec:	70a2                	ld	ra,40(sp)
    800050ee:	7402                	ld	s0,32(sp)
    800050f0:	6145                	addi	sp,sp,48
    800050f2:	8082                	ret

00000000800050f4 <sys_close>:
{
    800050f4:	1101                	addi	sp,sp,-32
    800050f6:	ec06                	sd	ra,24(sp)
    800050f8:	e822                	sd	s0,16(sp)
    800050fa:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800050fc:	fe040613          	addi	a2,s0,-32
    80005100:	fec40593          	addi	a1,s0,-20
    80005104:	4501                	li	a0,0
    80005106:	00000097          	auipc	ra,0x0
    8000510a:	cc4080e7          	jalr	-828(ra) # 80004dca <argfd>
    return -1;
    8000510e:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005110:	02054463          	bltz	a0,80005138 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005114:	ffffc097          	auipc	ra,0xffffc
    80005118:	72c080e7          	jalr	1836(ra) # 80001840 <myproc>
    8000511c:	fec42783          	lw	a5,-20(s0)
    80005120:	07e9                	addi	a5,a5,26
    80005122:	078e                	slli	a5,a5,0x3
    80005124:	97aa                	add	a5,a5,a0
    80005126:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    8000512a:	fe043503          	ld	a0,-32(s0)
    8000512e:	fffff097          	auipc	ra,0xfffff
    80005132:	298080e7          	jalr	664(ra) # 800043c6 <fileclose>
  return 0;
    80005136:	4781                	li	a5,0
}
    80005138:	853e                	mv	a0,a5
    8000513a:	60e2                	ld	ra,24(sp)
    8000513c:	6442                	ld	s0,16(sp)
    8000513e:	6105                	addi	sp,sp,32
    80005140:	8082                	ret

0000000080005142 <sys_fstat>:
{
    80005142:	1101                	addi	sp,sp,-32
    80005144:	ec06                	sd	ra,24(sp)
    80005146:	e822                	sd	s0,16(sp)
    80005148:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000514a:	fe840613          	addi	a2,s0,-24
    8000514e:	4581                	li	a1,0
    80005150:	4501                	li	a0,0
    80005152:	00000097          	auipc	ra,0x0
    80005156:	c78080e7          	jalr	-904(ra) # 80004dca <argfd>
    return -1;
    8000515a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000515c:	02054563          	bltz	a0,80005186 <sys_fstat+0x44>
    80005160:	fe040593          	addi	a1,s0,-32
    80005164:	4505                	li	a0,1
    80005166:	ffffe097          	auipc	ra,0xffffe
    8000516a:	8a8080e7          	jalr	-1880(ra) # 80002a0e <argaddr>
    return -1;
    8000516e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005170:	00054b63          	bltz	a0,80005186 <sys_fstat+0x44>
  return filestat(f, st);
    80005174:	fe043583          	ld	a1,-32(s0)
    80005178:	fe843503          	ld	a0,-24(s0)
    8000517c:	fffff097          	auipc	ra,0xfffff
    80005180:	312080e7          	jalr	786(ra) # 8000448e <filestat>
    80005184:	87aa                	mv	a5,a0
}
    80005186:	853e                	mv	a0,a5
    80005188:	60e2                	ld	ra,24(sp)
    8000518a:	6442                	ld	s0,16(sp)
    8000518c:	6105                	addi	sp,sp,32
    8000518e:	8082                	ret

0000000080005190 <sys_link>:
{
    80005190:	7169                	addi	sp,sp,-304
    80005192:	f606                	sd	ra,296(sp)
    80005194:	f222                	sd	s0,288(sp)
    80005196:	ee26                	sd	s1,280(sp)
    80005198:	ea4a                	sd	s2,272(sp)
    8000519a:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000519c:	08000613          	li	a2,128
    800051a0:	ed040593          	addi	a1,s0,-304
    800051a4:	4501                	li	a0,0
    800051a6:	ffffe097          	auipc	ra,0xffffe
    800051aa:	88a080e7          	jalr	-1910(ra) # 80002a30 <argstr>
    return -1;
    800051ae:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800051b0:	10054e63          	bltz	a0,800052cc <sys_link+0x13c>
    800051b4:	08000613          	li	a2,128
    800051b8:	f5040593          	addi	a1,s0,-176
    800051bc:	4505                	li	a0,1
    800051be:	ffffe097          	auipc	ra,0xffffe
    800051c2:	872080e7          	jalr	-1934(ra) # 80002a30 <argstr>
    return -1;
    800051c6:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800051c8:	10054263          	bltz	a0,800052cc <sys_link+0x13c>
  begin_op();
    800051cc:	fffff097          	auipc	ra,0xfffff
    800051d0:	d28080e7          	jalr	-728(ra) # 80003ef4 <begin_op>
  if((ip = namei(old)) == 0){
    800051d4:	ed040513          	addi	a0,s0,-304
    800051d8:	fffff097          	auipc	ra,0xfffff
    800051dc:	b10080e7          	jalr	-1264(ra) # 80003ce8 <namei>
    800051e0:	84aa                	mv	s1,a0
    800051e2:	c551                	beqz	a0,8000526e <sys_link+0xde>
  ilock(ip);
    800051e4:	ffffe097          	auipc	ra,0xffffe
    800051e8:	37a080e7          	jalr	890(ra) # 8000355e <ilock>
  if(ip->type == T_DIR){
    800051ec:	04449703          	lh	a4,68(s1)
    800051f0:	4785                	li	a5,1
    800051f2:	08f70463          	beq	a4,a5,8000527a <sys_link+0xea>
  ip->nlink++;
    800051f6:	04a4d783          	lhu	a5,74(s1)
    800051fa:	2785                	addiw	a5,a5,1
    800051fc:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005200:	8526                	mv	a0,s1
    80005202:	ffffe097          	auipc	ra,0xffffe
    80005206:	292080e7          	jalr	658(ra) # 80003494 <iupdate>
  iunlock(ip);
    8000520a:	8526                	mv	a0,s1
    8000520c:	ffffe097          	auipc	ra,0xffffe
    80005210:	414080e7          	jalr	1044(ra) # 80003620 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005214:	fd040593          	addi	a1,s0,-48
    80005218:	f5040513          	addi	a0,s0,-176
    8000521c:	fffff097          	auipc	ra,0xfffff
    80005220:	aea080e7          	jalr	-1302(ra) # 80003d06 <nameiparent>
    80005224:	892a                	mv	s2,a0
    80005226:	c935                	beqz	a0,8000529a <sys_link+0x10a>
  ilock(dp);
    80005228:	ffffe097          	auipc	ra,0xffffe
    8000522c:	336080e7          	jalr	822(ra) # 8000355e <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005230:	00092703          	lw	a4,0(s2)
    80005234:	409c                	lw	a5,0(s1)
    80005236:	04f71d63          	bne	a4,a5,80005290 <sys_link+0x100>
    8000523a:	40d0                	lw	a2,4(s1)
    8000523c:	fd040593          	addi	a1,s0,-48
    80005240:	854a                	mv	a0,s2
    80005242:	fffff097          	auipc	ra,0xfffff
    80005246:	9e4080e7          	jalr	-1564(ra) # 80003c26 <dirlink>
    8000524a:	04054363          	bltz	a0,80005290 <sys_link+0x100>
  iunlockput(dp);
    8000524e:	854a                	mv	a0,s2
    80005250:	ffffe097          	auipc	ra,0xffffe
    80005254:	54c080e7          	jalr	1356(ra) # 8000379c <iunlockput>
  iput(ip);
    80005258:	8526                	mv	a0,s1
    8000525a:	ffffe097          	auipc	ra,0xffffe
    8000525e:	412080e7          	jalr	1042(ra) # 8000366c <iput>
  end_op();
    80005262:	fffff097          	auipc	ra,0xfffff
    80005266:	d12080e7          	jalr	-750(ra) # 80003f74 <end_op>
  return 0;
    8000526a:	4781                	li	a5,0
    8000526c:	a085                	j	800052cc <sys_link+0x13c>
    end_op();
    8000526e:	fffff097          	auipc	ra,0xfffff
    80005272:	d06080e7          	jalr	-762(ra) # 80003f74 <end_op>
    return -1;
    80005276:	57fd                	li	a5,-1
    80005278:	a891                	j	800052cc <sys_link+0x13c>
    iunlockput(ip);
    8000527a:	8526                	mv	a0,s1
    8000527c:	ffffe097          	auipc	ra,0xffffe
    80005280:	520080e7          	jalr	1312(ra) # 8000379c <iunlockput>
    end_op();
    80005284:	fffff097          	auipc	ra,0xfffff
    80005288:	cf0080e7          	jalr	-784(ra) # 80003f74 <end_op>
    return -1;
    8000528c:	57fd                	li	a5,-1
    8000528e:	a83d                	j	800052cc <sys_link+0x13c>
    iunlockput(dp);
    80005290:	854a                	mv	a0,s2
    80005292:	ffffe097          	auipc	ra,0xffffe
    80005296:	50a080e7          	jalr	1290(ra) # 8000379c <iunlockput>
  ilock(ip);
    8000529a:	8526                	mv	a0,s1
    8000529c:	ffffe097          	auipc	ra,0xffffe
    800052a0:	2c2080e7          	jalr	706(ra) # 8000355e <ilock>
  ip->nlink--;
    800052a4:	04a4d783          	lhu	a5,74(s1)
    800052a8:	37fd                	addiw	a5,a5,-1
    800052aa:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800052ae:	8526                	mv	a0,s1
    800052b0:	ffffe097          	auipc	ra,0xffffe
    800052b4:	1e4080e7          	jalr	484(ra) # 80003494 <iupdate>
  iunlockput(ip);
    800052b8:	8526                	mv	a0,s1
    800052ba:	ffffe097          	auipc	ra,0xffffe
    800052be:	4e2080e7          	jalr	1250(ra) # 8000379c <iunlockput>
  end_op();
    800052c2:	fffff097          	auipc	ra,0xfffff
    800052c6:	cb2080e7          	jalr	-846(ra) # 80003f74 <end_op>
  return -1;
    800052ca:	57fd                	li	a5,-1
}
    800052cc:	853e                	mv	a0,a5
    800052ce:	70b2                	ld	ra,296(sp)
    800052d0:	7412                	ld	s0,288(sp)
    800052d2:	64f2                	ld	s1,280(sp)
    800052d4:	6952                	ld	s2,272(sp)
    800052d6:	6155                	addi	sp,sp,304
    800052d8:	8082                	ret

00000000800052da <sys_unlink>:
{
    800052da:	7151                	addi	sp,sp,-240
    800052dc:	f586                	sd	ra,232(sp)
    800052de:	f1a2                	sd	s0,224(sp)
    800052e0:	eda6                	sd	s1,216(sp)
    800052e2:	e9ca                	sd	s2,208(sp)
    800052e4:	e5ce                	sd	s3,200(sp)
    800052e6:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800052e8:	08000613          	li	a2,128
    800052ec:	f3040593          	addi	a1,s0,-208
    800052f0:	4501                	li	a0,0
    800052f2:	ffffd097          	auipc	ra,0xffffd
    800052f6:	73e080e7          	jalr	1854(ra) # 80002a30 <argstr>
    800052fa:	18054163          	bltz	a0,8000547c <sys_unlink+0x1a2>
  begin_op();
    800052fe:	fffff097          	auipc	ra,0xfffff
    80005302:	bf6080e7          	jalr	-1034(ra) # 80003ef4 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005306:	fb040593          	addi	a1,s0,-80
    8000530a:	f3040513          	addi	a0,s0,-208
    8000530e:	fffff097          	auipc	ra,0xfffff
    80005312:	9f8080e7          	jalr	-1544(ra) # 80003d06 <nameiparent>
    80005316:	84aa                	mv	s1,a0
    80005318:	c979                	beqz	a0,800053ee <sys_unlink+0x114>
  ilock(dp);
    8000531a:	ffffe097          	auipc	ra,0xffffe
    8000531e:	244080e7          	jalr	580(ra) # 8000355e <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005322:	00002597          	auipc	a1,0x2
    80005326:	3b658593          	addi	a1,a1,950 # 800076d8 <userret+0x648>
    8000532a:	fb040513          	addi	a0,s0,-80
    8000532e:	ffffe097          	auipc	ra,0xffffe
    80005332:	6ce080e7          	jalr	1742(ra) # 800039fc <namecmp>
    80005336:	14050a63          	beqz	a0,8000548a <sys_unlink+0x1b0>
    8000533a:	00002597          	auipc	a1,0x2
    8000533e:	3a658593          	addi	a1,a1,934 # 800076e0 <userret+0x650>
    80005342:	fb040513          	addi	a0,s0,-80
    80005346:	ffffe097          	auipc	ra,0xffffe
    8000534a:	6b6080e7          	jalr	1718(ra) # 800039fc <namecmp>
    8000534e:	12050e63          	beqz	a0,8000548a <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005352:	f2c40613          	addi	a2,s0,-212
    80005356:	fb040593          	addi	a1,s0,-80
    8000535a:	8526                	mv	a0,s1
    8000535c:	ffffe097          	auipc	ra,0xffffe
    80005360:	6ba080e7          	jalr	1722(ra) # 80003a16 <dirlookup>
    80005364:	892a                	mv	s2,a0
    80005366:	12050263          	beqz	a0,8000548a <sys_unlink+0x1b0>
  ilock(ip);
    8000536a:	ffffe097          	auipc	ra,0xffffe
    8000536e:	1f4080e7          	jalr	500(ra) # 8000355e <ilock>
  if(ip->nlink < 1)
    80005372:	04a91783          	lh	a5,74(s2)
    80005376:	08f05263          	blez	a5,800053fa <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000537a:	04491703          	lh	a4,68(s2)
    8000537e:	4785                	li	a5,1
    80005380:	08f70563          	beq	a4,a5,8000540a <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005384:	4641                	li	a2,16
    80005386:	4581                	li	a1,0
    80005388:	fc040513          	addi	a0,s0,-64
    8000538c:	ffffb097          	auipc	ra,0xffffb
    80005390:	7de080e7          	jalr	2014(ra) # 80000b6a <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005394:	4741                	li	a4,16
    80005396:	f2c42683          	lw	a3,-212(s0)
    8000539a:	fc040613          	addi	a2,s0,-64
    8000539e:	4581                	li	a1,0
    800053a0:	8526                	mv	a0,s1
    800053a2:	ffffe097          	auipc	ra,0xffffe
    800053a6:	540080e7          	jalr	1344(ra) # 800038e2 <writei>
    800053aa:	47c1                	li	a5,16
    800053ac:	0af51563          	bne	a0,a5,80005456 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800053b0:	04491703          	lh	a4,68(s2)
    800053b4:	4785                	li	a5,1
    800053b6:	0af70863          	beq	a4,a5,80005466 <sys_unlink+0x18c>
  iunlockput(dp);
    800053ba:	8526                	mv	a0,s1
    800053bc:	ffffe097          	auipc	ra,0xffffe
    800053c0:	3e0080e7          	jalr	992(ra) # 8000379c <iunlockput>
  ip->nlink--;
    800053c4:	04a95783          	lhu	a5,74(s2)
    800053c8:	37fd                	addiw	a5,a5,-1
    800053ca:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800053ce:	854a                	mv	a0,s2
    800053d0:	ffffe097          	auipc	ra,0xffffe
    800053d4:	0c4080e7          	jalr	196(ra) # 80003494 <iupdate>
  iunlockput(ip);
    800053d8:	854a                	mv	a0,s2
    800053da:	ffffe097          	auipc	ra,0xffffe
    800053de:	3c2080e7          	jalr	962(ra) # 8000379c <iunlockput>
  end_op();
    800053e2:	fffff097          	auipc	ra,0xfffff
    800053e6:	b92080e7          	jalr	-1134(ra) # 80003f74 <end_op>
  return 0;
    800053ea:	4501                	li	a0,0
    800053ec:	a84d                	j	8000549e <sys_unlink+0x1c4>
    end_op();
    800053ee:	fffff097          	auipc	ra,0xfffff
    800053f2:	b86080e7          	jalr	-1146(ra) # 80003f74 <end_op>
    return -1;
    800053f6:	557d                	li	a0,-1
    800053f8:	a05d                	j	8000549e <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800053fa:	00002517          	auipc	a0,0x2
    800053fe:	30e50513          	addi	a0,a0,782 # 80007708 <userret+0x678>
    80005402:	ffffb097          	auipc	ra,0xffffb
    80005406:	14c080e7          	jalr	332(ra) # 8000054e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000540a:	04c92703          	lw	a4,76(s2)
    8000540e:	02000793          	li	a5,32
    80005412:	f6e7f9e3          	bgeu	a5,a4,80005384 <sys_unlink+0xaa>
    80005416:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000541a:	4741                	li	a4,16
    8000541c:	86ce                	mv	a3,s3
    8000541e:	f1840613          	addi	a2,s0,-232
    80005422:	4581                	li	a1,0
    80005424:	854a                	mv	a0,s2
    80005426:	ffffe097          	auipc	ra,0xffffe
    8000542a:	3c8080e7          	jalr	968(ra) # 800037ee <readi>
    8000542e:	47c1                	li	a5,16
    80005430:	00f51b63          	bne	a0,a5,80005446 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005434:	f1845783          	lhu	a5,-232(s0)
    80005438:	e7a1                	bnez	a5,80005480 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000543a:	29c1                	addiw	s3,s3,16
    8000543c:	04c92783          	lw	a5,76(s2)
    80005440:	fcf9ede3          	bltu	s3,a5,8000541a <sys_unlink+0x140>
    80005444:	b781                	j	80005384 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005446:	00002517          	auipc	a0,0x2
    8000544a:	2da50513          	addi	a0,a0,730 # 80007720 <userret+0x690>
    8000544e:	ffffb097          	auipc	ra,0xffffb
    80005452:	100080e7          	jalr	256(ra) # 8000054e <panic>
    panic("unlink: writei");
    80005456:	00002517          	auipc	a0,0x2
    8000545a:	2e250513          	addi	a0,a0,738 # 80007738 <userret+0x6a8>
    8000545e:	ffffb097          	auipc	ra,0xffffb
    80005462:	0f0080e7          	jalr	240(ra) # 8000054e <panic>
    dp->nlink--;
    80005466:	04a4d783          	lhu	a5,74(s1)
    8000546a:	37fd                	addiw	a5,a5,-1
    8000546c:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005470:	8526                	mv	a0,s1
    80005472:	ffffe097          	auipc	ra,0xffffe
    80005476:	022080e7          	jalr	34(ra) # 80003494 <iupdate>
    8000547a:	b781                	j	800053ba <sys_unlink+0xe0>
    return -1;
    8000547c:	557d                	li	a0,-1
    8000547e:	a005                	j	8000549e <sys_unlink+0x1c4>
    iunlockput(ip);
    80005480:	854a                	mv	a0,s2
    80005482:	ffffe097          	auipc	ra,0xffffe
    80005486:	31a080e7          	jalr	794(ra) # 8000379c <iunlockput>
  iunlockput(dp);
    8000548a:	8526                	mv	a0,s1
    8000548c:	ffffe097          	auipc	ra,0xffffe
    80005490:	310080e7          	jalr	784(ra) # 8000379c <iunlockput>
  end_op();
    80005494:	fffff097          	auipc	ra,0xfffff
    80005498:	ae0080e7          	jalr	-1312(ra) # 80003f74 <end_op>
  return -1;
    8000549c:	557d                	li	a0,-1
}
    8000549e:	70ae                	ld	ra,232(sp)
    800054a0:	740e                	ld	s0,224(sp)
    800054a2:	64ee                	ld	s1,216(sp)
    800054a4:	694e                	ld	s2,208(sp)
    800054a6:	69ae                	ld	s3,200(sp)
    800054a8:	616d                	addi	sp,sp,240
    800054aa:	8082                	ret

00000000800054ac <sys_open>:

uint64
sys_open(void)
{
    800054ac:	7131                	addi	sp,sp,-192
    800054ae:	fd06                	sd	ra,184(sp)
    800054b0:	f922                	sd	s0,176(sp)
    800054b2:	f526                	sd	s1,168(sp)
    800054b4:	f14a                	sd	s2,160(sp)
    800054b6:	ed4e                	sd	s3,152(sp)
    800054b8:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800054ba:	08000613          	li	a2,128
    800054be:	f5040593          	addi	a1,s0,-176
    800054c2:	4501                	li	a0,0
    800054c4:	ffffd097          	auipc	ra,0xffffd
    800054c8:	56c080e7          	jalr	1388(ra) # 80002a30 <argstr>
    return -1;
    800054cc:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800054ce:	0a054763          	bltz	a0,8000557c <sys_open+0xd0>
    800054d2:	f4c40593          	addi	a1,s0,-180
    800054d6:	4505                	li	a0,1
    800054d8:	ffffd097          	auipc	ra,0xffffd
    800054dc:	514080e7          	jalr	1300(ra) # 800029ec <argint>
    800054e0:	08054e63          	bltz	a0,8000557c <sys_open+0xd0>

  begin_op();
    800054e4:	fffff097          	auipc	ra,0xfffff
    800054e8:	a10080e7          	jalr	-1520(ra) # 80003ef4 <begin_op>

  if(omode & O_CREATE){
    800054ec:	f4c42783          	lw	a5,-180(s0)
    800054f0:	2007f793          	andi	a5,a5,512
    800054f4:	c3cd                	beqz	a5,80005596 <sys_open+0xea>
    ip = create(path, T_FILE, 0, 0);
    800054f6:	4681                	li	a3,0
    800054f8:	4601                	li	a2,0
    800054fa:	4589                	li	a1,2
    800054fc:	f5040513          	addi	a0,s0,-176
    80005500:	00000097          	auipc	ra,0x0
    80005504:	974080e7          	jalr	-1676(ra) # 80004e74 <create>
    80005508:	892a                	mv	s2,a0
    if(ip == 0){
    8000550a:	c149                	beqz	a0,8000558c <sys_open+0xe0>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    8000550c:	04491703          	lh	a4,68(s2)
    80005510:	478d                	li	a5,3
    80005512:	00f71763          	bne	a4,a5,80005520 <sys_open+0x74>
    80005516:	04695703          	lhu	a4,70(s2)
    8000551a:	47a5                	li	a5,9
    8000551c:	0ce7e263          	bltu	a5,a4,800055e0 <sys_open+0x134>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005520:	fffff097          	auipc	ra,0xfffff
    80005524:	dea080e7          	jalr	-534(ra) # 8000430a <filealloc>
    80005528:	89aa                	mv	s3,a0
    8000552a:	c175                	beqz	a0,8000560e <sys_open+0x162>
    8000552c:	00000097          	auipc	ra,0x0
    80005530:	906080e7          	jalr	-1786(ra) # 80004e32 <fdalloc>
    80005534:	84aa                	mv	s1,a0
    80005536:	0c054763          	bltz	a0,80005604 <sys_open+0x158>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    8000553a:	04491703          	lh	a4,68(s2)
    8000553e:	478d                	li	a5,3
    80005540:	0af70b63          	beq	a4,a5,800055f6 <sys_open+0x14a>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005544:	4789                	li	a5,2
    80005546:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    8000554a:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    8000554e:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005552:	f4c42783          	lw	a5,-180(s0)
    80005556:	0017c713          	xori	a4,a5,1
    8000555a:	8b05                	andi	a4,a4,1
    8000555c:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005560:	8b8d                	andi	a5,a5,3
    80005562:	00f037b3          	snez	a5,a5
    80005566:	00f984a3          	sb	a5,9(s3)

  iunlock(ip);
    8000556a:	854a                	mv	a0,s2
    8000556c:	ffffe097          	auipc	ra,0xffffe
    80005570:	0b4080e7          	jalr	180(ra) # 80003620 <iunlock>
  end_op();
    80005574:	fffff097          	auipc	ra,0xfffff
    80005578:	a00080e7          	jalr	-1536(ra) # 80003f74 <end_op>

  return fd;
}
    8000557c:	8526                	mv	a0,s1
    8000557e:	70ea                	ld	ra,184(sp)
    80005580:	744a                	ld	s0,176(sp)
    80005582:	74aa                	ld	s1,168(sp)
    80005584:	790a                	ld	s2,160(sp)
    80005586:	69ea                	ld	s3,152(sp)
    80005588:	6129                	addi	sp,sp,192
    8000558a:	8082                	ret
      end_op();
    8000558c:	fffff097          	auipc	ra,0xfffff
    80005590:	9e8080e7          	jalr	-1560(ra) # 80003f74 <end_op>
      return -1;
    80005594:	b7e5                	j	8000557c <sys_open+0xd0>
    if((ip = namei(path)) == 0){
    80005596:	f5040513          	addi	a0,s0,-176
    8000559a:	ffffe097          	auipc	ra,0xffffe
    8000559e:	74e080e7          	jalr	1870(ra) # 80003ce8 <namei>
    800055a2:	892a                	mv	s2,a0
    800055a4:	c905                	beqz	a0,800055d4 <sys_open+0x128>
    ilock(ip);
    800055a6:	ffffe097          	auipc	ra,0xffffe
    800055aa:	fb8080e7          	jalr	-72(ra) # 8000355e <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800055ae:	04491703          	lh	a4,68(s2)
    800055b2:	4785                	li	a5,1
    800055b4:	f4f71ce3          	bne	a4,a5,8000550c <sys_open+0x60>
    800055b8:	f4c42783          	lw	a5,-180(s0)
    800055bc:	d3b5                	beqz	a5,80005520 <sys_open+0x74>
      iunlockput(ip);
    800055be:	854a                	mv	a0,s2
    800055c0:	ffffe097          	auipc	ra,0xffffe
    800055c4:	1dc080e7          	jalr	476(ra) # 8000379c <iunlockput>
      end_op();
    800055c8:	fffff097          	auipc	ra,0xfffff
    800055cc:	9ac080e7          	jalr	-1620(ra) # 80003f74 <end_op>
      return -1;
    800055d0:	54fd                	li	s1,-1
    800055d2:	b76d                	j	8000557c <sys_open+0xd0>
      end_op();
    800055d4:	fffff097          	auipc	ra,0xfffff
    800055d8:	9a0080e7          	jalr	-1632(ra) # 80003f74 <end_op>
      return -1;
    800055dc:	54fd                	li	s1,-1
    800055de:	bf79                	j	8000557c <sys_open+0xd0>
    iunlockput(ip);
    800055e0:	854a                	mv	a0,s2
    800055e2:	ffffe097          	auipc	ra,0xffffe
    800055e6:	1ba080e7          	jalr	442(ra) # 8000379c <iunlockput>
    end_op();
    800055ea:	fffff097          	auipc	ra,0xfffff
    800055ee:	98a080e7          	jalr	-1654(ra) # 80003f74 <end_op>
    return -1;
    800055f2:	54fd                	li	s1,-1
    800055f4:	b761                	j	8000557c <sys_open+0xd0>
    f->type = FD_DEVICE;
    800055f6:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800055fa:	04691783          	lh	a5,70(s2)
    800055fe:	02f99223          	sh	a5,36(s3)
    80005602:	b7b1                	j	8000554e <sys_open+0xa2>
      fileclose(f);
    80005604:	854e                	mv	a0,s3
    80005606:	fffff097          	auipc	ra,0xfffff
    8000560a:	dc0080e7          	jalr	-576(ra) # 800043c6 <fileclose>
    iunlockput(ip);
    8000560e:	854a                	mv	a0,s2
    80005610:	ffffe097          	auipc	ra,0xffffe
    80005614:	18c080e7          	jalr	396(ra) # 8000379c <iunlockput>
    end_op();
    80005618:	fffff097          	auipc	ra,0xfffff
    8000561c:	95c080e7          	jalr	-1700(ra) # 80003f74 <end_op>
    return -1;
    80005620:	54fd                	li	s1,-1
    80005622:	bfa9                	j	8000557c <sys_open+0xd0>

0000000080005624 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005624:	7175                	addi	sp,sp,-144
    80005626:	e506                	sd	ra,136(sp)
    80005628:	e122                	sd	s0,128(sp)
    8000562a:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    8000562c:	fffff097          	auipc	ra,0xfffff
    80005630:	8c8080e7          	jalr	-1848(ra) # 80003ef4 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005634:	08000613          	li	a2,128
    80005638:	f7040593          	addi	a1,s0,-144
    8000563c:	4501                	li	a0,0
    8000563e:	ffffd097          	auipc	ra,0xffffd
    80005642:	3f2080e7          	jalr	1010(ra) # 80002a30 <argstr>
    80005646:	02054963          	bltz	a0,80005678 <sys_mkdir+0x54>
    8000564a:	4681                	li	a3,0
    8000564c:	4601                	li	a2,0
    8000564e:	4585                	li	a1,1
    80005650:	f7040513          	addi	a0,s0,-144
    80005654:	00000097          	auipc	ra,0x0
    80005658:	820080e7          	jalr	-2016(ra) # 80004e74 <create>
    8000565c:	cd11                	beqz	a0,80005678 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000565e:	ffffe097          	auipc	ra,0xffffe
    80005662:	13e080e7          	jalr	318(ra) # 8000379c <iunlockput>
  end_op();
    80005666:	fffff097          	auipc	ra,0xfffff
    8000566a:	90e080e7          	jalr	-1778(ra) # 80003f74 <end_op>
  return 0;
    8000566e:	4501                	li	a0,0
}
    80005670:	60aa                	ld	ra,136(sp)
    80005672:	640a                	ld	s0,128(sp)
    80005674:	6149                	addi	sp,sp,144
    80005676:	8082                	ret
    end_op();
    80005678:	fffff097          	auipc	ra,0xfffff
    8000567c:	8fc080e7          	jalr	-1796(ra) # 80003f74 <end_op>
    return -1;
    80005680:	557d                	li	a0,-1
    80005682:	b7fd                	j	80005670 <sys_mkdir+0x4c>

0000000080005684 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005684:	7135                	addi	sp,sp,-160
    80005686:	ed06                	sd	ra,152(sp)
    80005688:	e922                	sd	s0,144(sp)
    8000568a:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    8000568c:	fffff097          	auipc	ra,0xfffff
    80005690:	868080e7          	jalr	-1944(ra) # 80003ef4 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005694:	08000613          	li	a2,128
    80005698:	f7040593          	addi	a1,s0,-144
    8000569c:	4501                	li	a0,0
    8000569e:	ffffd097          	auipc	ra,0xffffd
    800056a2:	392080e7          	jalr	914(ra) # 80002a30 <argstr>
    800056a6:	04054a63          	bltz	a0,800056fa <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    800056aa:	f6c40593          	addi	a1,s0,-148
    800056ae:	4505                	li	a0,1
    800056b0:	ffffd097          	auipc	ra,0xffffd
    800056b4:	33c080e7          	jalr	828(ra) # 800029ec <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800056b8:	04054163          	bltz	a0,800056fa <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    800056bc:	f6840593          	addi	a1,s0,-152
    800056c0:	4509                	li	a0,2
    800056c2:	ffffd097          	auipc	ra,0xffffd
    800056c6:	32a080e7          	jalr	810(ra) # 800029ec <argint>
     argint(1, &major) < 0 ||
    800056ca:	02054863          	bltz	a0,800056fa <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800056ce:	f6841683          	lh	a3,-152(s0)
    800056d2:	f6c41603          	lh	a2,-148(s0)
    800056d6:	458d                	li	a1,3
    800056d8:	f7040513          	addi	a0,s0,-144
    800056dc:	fffff097          	auipc	ra,0xfffff
    800056e0:	798080e7          	jalr	1944(ra) # 80004e74 <create>
     argint(2, &minor) < 0 ||
    800056e4:	c919                	beqz	a0,800056fa <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800056e6:	ffffe097          	auipc	ra,0xffffe
    800056ea:	0b6080e7          	jalr	182(ra) # 8000379c <iunlockput>
  end_op();
    800056ee:	fffff097          	auipc	ra,0xfffff
    800056f2:	886080e7          	jalr	-1914(ra) # 80003f74 <end_op>
  return 0;
    800056f6:	4501                	li	a0,0
    800056f8:	a031                	j	80005704 <sys_mknod+0x80>
    end_op();
    800056fa:	fffff097          	auipc	ra,0xfffff
    800056fe:	87a080e7          	jalr	-1926(ra) # 80003f74 <end_op>
    return -1;
    80005702:	557d                	li	a0,-1
}
    80005704:	60ea                	ld	ra,152(sp)
    80005706:	644a                	ld	s0,144(sp)
    80005708:	610d                	addi	sp,sp,160
    8000570a:	8082                	ret

000000008000570c <sys_chdir>:

uint64
sys_chdir(void)
{
    8000570c:	7135                	addi	sp,sp,-160
    8000570e:	ed06                	sd	ra,152(sp)
    80005710:	e922                	sd	s0,144(sp)
    80005712:	e526                	sd	s1,136(sp)
    80005714:	e14a                	sd	s2,128(sp)
    80005716:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005718:	ffffc097          	auipc	ra,0xffffc
    8000571c:	128080e7          	jalr	296(ra) # 80001840 <myproc>
    80005720:	892a                	mv	s2,a0
  
  begin_op();
    80005722:	ffffe097          	auipc	ra,0xffffe
    80005726:	7d2080e7          	jalr	2002(ra) # 80003ef4 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    8000572a:	08000613          	li	a2,128
    8000572e:	f6040593          	addi	a1,s0,-160
    80005732:	4501                	li	a0,0
    80005734:	ffffd097          	auipc	ra,0xffffd
    80005738:	2fc080e7          	jalr	764(ra) # 80002a30 <argstr>
    8000573c:	04054b63          	bltz	a0,80005792 <sys_chdir+0x86>
    80005740:	f6040513          	addi	a0,s0,-160
    80005744:	ffffe097          	auipc	ra,0xffffe
    80005748:	5a4080e7          	jalr	1444(ra) # 80003ce8 <namei>
    8000574c:	84aa                	mv	s1,a0
    8000574e:	c131                	beqz	a0,80005792 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005750:	ffffe097          	auipc	ra,0xffffe
    80005754:	e0e080e7          	jalr	-498(ra) # 8000355e <ilock>
  if(ip->type != T_DIR){
    80005758:	04449703          	lh	a4,68(s1)
    8000575c:	4785                	li	a5,1
    8000575e:	04f71063          	bne	a4,a5,8000579e <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005762:	8526                	mv	a0,s1
    80005764:	ffffe097          	auipc	ra,0xffffe
    80005768:	ebc080e7          	jalr	-324(ra) # 80003620 <iunlock>
  iput(p->cwd);
    8000576c:	15093503          	ld	a0,336(s2)
    80005770:	ffffe097          	auipc	ra,0xffffe
    80005774:	efc080e7          	jalr	-260(ra) # 8000366c <iput>
  end_op();
    80005778:	ffffe097          	auipc	ra,0xffffe
    8000577c:	7fc080e7          	jalr	2044(ra) # 80003f74 <end_op>
  p->cwd = ip;
    80005780:	14993823          	sd	s1,336(s2)
  return 0;
    80005784:	4501                	li	a0,0
}
    80005786:	60ea                	ld	ra,152(sp)
    80005788:	644a                	ld	s0,144(sp)
    8000578a:	64aa                	ld	s1,136(sp)
    8000578c:	690a                	ld	s2,128(sp)
    8000578e:	610d                	addi	sp,sp,160
    80005790:	8082                	ret
    end_op();
    80005792:	ffffe097          	auipc	ra,0xffffe
    80005796:	7e2080e7          	jalr	2018(ra) # 80003f74 <end_op>
    return -1;
    8000579a:	557d                	li	a0,-1
    8000579c:	b7ed                	j	80005786 <sys_chdir+0x7a>
    iunlockput(ip);
    8000579e:	8526                	mv	a0,s1
    800057a0:	ffffe097          	auipc	ra,0xffffe
    800057a4:	ffc080e7          	jalr	-4(ra) # 8000379c <iunlockput>
    end_op();
    800057a8:	ffffe097          	auipc	ra,0xffffe
    800057ac:	7cc080e7          	jalr	1996(ra) # 80003f74 <end_op>
    return -1;
    800057b0:	557d                	li	a0,-1
    800057b2:	bfd1                	j	80005786 <sys_chdir+0x7a>

00000000800057b4 <sys_exec>:

uint64
sys_exec(void)
{
    800057b4:	7145                	addi	sp,sp,-464
    800057b6:	e786                	sd	ra,456(sp)
    800057b8:	e3a2                	sd	s0,448(sp)
    800057ba:	ff26                	sd	s1,440(sp)
    800057bc:	fb4a                	sd	s2,432(sp)
    800057be:	f74e                	sd	s3,424(sp)
    800057c0:	f352                	sd	s4,416(sp)
    800057c2:	ef56                	sd	s5,408(sp)
    800057c4:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800057c6:	08000613          	li	a2,128
    800057ca:	f4040593          	addi	a1,s0,-192
    800057ce:	4501                	li	a0,0
    800057d0:	ffffd097          	auipc	ra,0xffffd
    800057d4:	260080e7          	jalr	608(ra) # 80002a30 <argstr>
    800057d8:	0e054663          	bltz	a0,800058c4 <sys_exec+0x110>
    800057dc:	e3840593          	addi	a1,s0,-456
    800057e0:	4505                	li	a0,1
    800057e2:	ffffd097          	auipc	ra,0xffffd
    800057e6:	22c080e7          	jalr	556(ra) # 80002a0e <argaddr>
    800057ea:	0e054763          	bltz	a0,800058d8 <sys_exec+0x124>
    return -1;
  }
  memset(argv, 0, sizeof(argv));
    800057ee:	10000613          	li	a2,256
    800057f2:	4581                	li	a1,0
    800057f4:	e4040513          	addi	a0,s0,-448
    800057f8:	ffffb097          	auipc	ra,0xffffb
    800057fc:	372080e7          	jalr	882(ra) # 80000b6a <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005800:	e4040913          	addi	s2,s0,-448
  memset(argv, 0, sizeof(argv));
    80005804:	89ca                	mv	s3,s2
    80005806:	4481                	li	s1,0
    if(i >= NELEM(argv)){
    80005808:	02000a13          	li	s4,32
    8000580c:	00048a9b          	sext.w	s5,s1
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005810:	00349513          	slli	a0,s1,0x3
    80005814:	e3040593          	addi	a1,s0,-464
    80005818:	e3843783          	ld	a5,-456(s0)
    8000581c:	953e                	add	a0,a0,a5
    8000581e:	ffffd097          	auipc	ra,0xffffd
    80005822:	134080e7          	jalr	308(ra) # 80002952 <fetchaddr>
    80005826:	02054a63          	bltz	a0,8000585a <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    8000582a:	e3043783          	ld	a5,-464(s0)
    8000582e:	c7a1                	beqz	a5,80005876 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005830:	ffffb097          	auipc	ra,0xffffb
    80005834:	12c080e7          	jalr	300(ra) # 8000095c <kalloc>
    80005838:	85aa                	mv	a1,a0
    8000583a:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    8000583e:	c92d                	beqz	a0,800058b0 <sys_exec+0xfc>
      panic("sys_exec kalloc");
    if(fetchstr(uarg, argv[i], PGSIZE) < 0){
    80005840:	6605                	lui	a2,0x1
    80005842:	e3043503          	ld	a0,-464(s0)
    80005846:	ffffd097          	auipc	ra,0xffffd
    8000584a:	15e080e7          	jalr	350(ra) # 800029a4 <fetchstr>
    8000584e:	00054663          	bltz	a0,8000585a <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005852:	0485                	addi	s1,s1,1
    80005854:	09a1                	addi	s3,s3,8
    80005856:	fb449be3          	bne	s1,s4,8000580c <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000585a:	10090493          	addi	s1,s2,256
    8000585e:	00093503          	ld	a0,0(s2)
    80005862:	cd39                	beqz	a0,800058c0 <sys_exec+0x10c>
    kfree(argv[i]);
    80005864:	ffffb097          	auipc	ra,0xffffb
    80005868:	ffc080e7          	jalr	-4(ra) # 80000860 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000586c:	0921                	addi	s2,s2,8
    8000586e:	fe9918e3          	bne	s2,s1,8000585e <sys_exec+0xaa>
  return -1;
    80005872:	557d                	li	a0,-1
    80005874:	a889                	j	800058c6 <sys_exec+0x112>
      argv[i] = 0;
    80005876:	0a8e                	slli	s5,s5,0x3
    80005878:	fc040793          	addi	a5,s0,-64
    8000587c:	9abe                	add	s5,s5,a5
    8000587e:	e80ab023          	sd	zero,-384(s5) # ffffffffffffee80 <end+0xffffffff7ffd8e4c>
  int ret = exec(path, argv);
    80005882:	e4040593          	addi	a1,s0,-448
    80005886:	f4040513          	addi	a0,s0,-192
    8000588a:	fffff097          	auipc	ra,0xfffff
    8000588e:	1de080e7          	jalr	478(ra) # 80004a68 <exec>
    80005892:	84aa                	mv	s1,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005894:	10090993          	addi	s3,s2,256
    80005898:	00093503          	ld	a0,0(s2)
    8000589c:	c901                	beqz	a0,800058ac <sys_exec+0xf8>
    kfree(argv[i]);
    8000589e:	ffffb097          	auipc	ra,0xffffb
    800058a2:	fc2080e7          	jalr	-62(ra) # 80000860 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800058a6:	0921                	addi	s2,s2,8
    800058a8:	ff3918e3          	bne	s2,s3,80005898 <sys_exec+0xe4>
  return ret;
    800058ac:	8526                	mv	a0,s1
    800058ae:	a821                	j	800058c6 <sys_exec+0x112>
      panic("sys_exec kalloc");
    800058b0:	00002517          	auipc	a0,0x2
    800058b4:	e9850513          	addi	a0,a0,-360 # 80007748 <userret+0x6b8>
    800058b8:	ffffb097          	auipc	ra,0xffffb
    800058bc:	c96080e7          	jalr	-874(ra) # 8000054e <panic>
  return -1;
    800058c0:	557d                	li	a0,-1
    800058c2:	a011                	j	800058c6 <sys_exec+0x112>
    return -1;
    800058c4:	557d                	li	a0,-1
}
    800058c6:	60be                	ld	ra,456(sp)
    800058c8:	641e                	ld	s0,448(sp)
    800058ca:	74fa                	ld	s1,440(sp)
    800058cc:	795a                	ld	s2,432(sp)
    800058ce:	79ba                	ld	s3,424(sp)
    800058d0:	7a1a                	ld	s4,416(sp)
    800058d2:	6afa                	ld	s5,408(sp)
    800058d4:	6179                	addi	sp,sp,464
    800058d6:	8082                	ret
    return -1;
    800058d8:	557d                	li	a0,-1
    800058da:	b7f5                	j	800058c6 <sys_exec+0x112>

00000000800058dc <sys_pipe>:

uint64
sys_pipe(void)
{
    800058dc:	7139                	addi	sp,sp,-64
    800058de:	fc06                	sd	ra,56(sp)
    800058e0:	f822                	sd	s0,48(sp)
    800058e2:	f426                	sd	s1,40(sp)
    800058e4:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    800058e6:	ffffc097          	auipc	ra,0xffffc
    800058ea:	f5a080e7          	jalr	-166(ra) # 80001840 <myproc>
    800058ee:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    800058f0:	fd840593          	addi	a1,s0,-40
    800058f4:	4501                	li	a0,0
    800058f6:	ffffd097          	auipc	ra,0xffffd
    800058fa:	118080e7          	jalr	280(ra) # 80002a0e <argaddr>
    return -1;
    800058fe:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005900:	0e054063          	bltz	a0,800059e0 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005904:	fc840593          	addi	a1,s0,-56
    80005908:	fd040513          	addi	a0,s0,-48
    8000590c:	fffff097          	auipc	ra,0xfffff
    80005910:	e10080e7          	jalr	-496(ra) # 8000471c <pipealloc>
    return -1;
    80005914:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005916:	0c054563          	bltz	a0,800059e0 <sys_pipe+0x104>
  fd0 = -1;
    8000591a:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    8000591e:	fd043503          	ld	a0,-48(s0)
    80005922:	fffff097          	auipc	ra,0xfffff
    80005926:	510080e7          	jalr	1296(ra) # 80004e32 <fdalloc>
    8000592a:	fca42223          	sw	a0,-60(s0)
    8000592e:	08054c63          	bltz	a0,800059c6 <sys_pipe+0xea>
    80005932:	fc843503          	ld	a0,-56(s0)
    80005936:	fffff097          	auipc	ra,0xfffff
    8000593a:	4fc080e7          	jalr	1276(ra) # 80004e32 <fdalloc>
    8000593e:	fca42023          	sw	a0,-64(s0)
    80005942:	06054863          	bltz	a0,800059b2 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005946:	4691                	li	a3,4
    80005948:	fc440613          	addi	a2,s0,-60
    8000594c:	fd843583          	ld	a1,-40(s0)
    80005950:	68a8                	ld	a0,80(s1)
    80005952:	ffffc097          	auipc	ra,0xffffc
    80005956:	be2080e7          	jalr	-1054(ra) # 80001534 <copyout>
    8000595a:	02054063          	bltz	a0,8000597a <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    8000595e:	4691                	li	a3,4
    80005960:	fc040613          	addi	a2,s0,-64
    80005964:	fd843583          	ld	a1,-40(s0)
    80005968:	0591                	addi	a1,a1,4
    8000596a:	68a8                	ld	a0,80(s1)
    8000596c:	ffffc097          	auipc	ra,0xffffc
    80005970:	bc8080e7          	jalr	-1080(ra) # 80001534 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005974:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005976:	06055563          	bgez	a0,800059e0 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    8000597a:	fc442783          	lw	a5,-60(s0)
    8000597e:	07e9                	addi	a5,a5,26
    80005980:	078e                	slli	a5,a5,0x3
    80005982:	97a6                	add	a5,a5,s1
    80005984:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005988:	fc042503          	lw	a0,-64(s0)
    8000598c:	0569                	addi	a0,a0,26
    8000598e:	050e                	slli	a0,a0,0x3
    80005990:	9526                	add	a0,a0,s1
    80005992:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005996:	fd043503          	ld	a0,-48(s0)
    8000599a:	fffff097          	auipc	ra,0xfffff
    8000599e:	a2c080e7          	jalr	-1492(ra) # 800043c6 <fileclose>
    fileclose(wf);
    800059a2:	fc843503          	ld	a0,-56(s0)
    800059a6:	fffff097          	auipc	ra,0xfffff
    800059aa:	a20080e7          	jalr	-1504(ra) # 800043c6 <fileclose>
    return -1;
    800059ae:	57fd                	li	a5,-1
    800059b0:	a805                	j	800059e0 <sys_pipe+0x104>
    if(fd0 >= 0)
    800059b2:	fc442783          	lw	a5,-60(s0)
    800059b6:	0007c863          	bltz	a5,800059c6 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    800059ba:	01a78513          	addi	a0,a5,26
    800059be:	050e                	slli	a0,a0,0x3
    800059c0:	9526                	add	a0,a0,s1
    800059c2:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    800059c6:	fd043503          	ld	a0,-48(s0)
    800059ca:	fffff097          	auipc	ra,0xfffff
    800059ce:	9fc080e7          	jalr	-1540(ra) # 800043c6 <fileclose>
    fileclose(wf);
    800059d2:	fc843503          	ld	a0,-56(s0)
    800059d6:	fffff097          	auipc	ra,0xfffff
    800059da:	9f0080e7          	jalr	-1552(ra) # 800043c6 <fileclose>
    return -1;
    800059de:	57fd                	li	a5,-1
}
    800059e0:	853e                	mv	a0,a5
    800059e2:	70e2                	ld	ra,56(sp)
    800059e4:	7442                	ld	s0,48(sp)
    800059e6:	74a2                	ld	s1,40(sp)
    800059e8:	6121                	addi	sp,sp,64
    800059ea:	8082                	ret
    800059ec:	0000                	unimp
	...

00000000800059f0 <kernelvec>:
    800059f0:	7111                	addi	sp,sp,-256
    800059f2:	e006                	sd	ra,0(sp)
    800059f4:	e40a                	sd	sp,8(sp)
    800059f6:	e80e                	sd	gp,16(sp)
    800059f8:	ec12                	sd	tp,24(sp)
    800059fa:	f016                	sd	t0,32(sp)
    800059fc:	f41a                	sd	t1,40(sp)
    800059fe:	f81e                	sd	t2,48(sp)
    80005a00:	fc22                	sd	s0,56(sp)
    80005a02:	e0a6                	sd	s1,64(sp)
    80005a04:	e4aa                	sd	a0,72(sp)
    80005a06:	e8ae                	sd	a1,80(sp)
    80005a08:	ecb2                	sd	a2,88(sp)
    80005a0a:	f0b6                	sd	a3,96(sp)
    80005a0c:	f4ba                	sd	a4,104(sp)
    80005a0e:	f8be                	sd	a5,112(sp)
    80005a10:	fcc2                	sd	a6,120(sp)
    80005a12:	e146                	sd	a7,128(sp)
    80005a14:	e54a                	sd	s2,136(sp)
    80005a16:	e94e                	sd	s3,144(sp)
    80005a18:	ed52                	sd	s4,152(sp)
    80005a1a:	f156                	sd	s5,160(sp)
    80005a1c:	f55a                	sd	s6,168(sp)
    80005a1e:	f95e                	sd	s7,176(sp)
    80005a20:	fd62                	sd	s8,184(sp)
    80005a22:	e1e6                	sd	s9,192(sp)
    80005a24:	e5ea                	sd	s10,200(sp)
    80005a26:	e9ee                	sd	s11,208(sp)
    80005a28:	edf2                	sd	t3,216(sp)
    80005a2a:	f1f6                	sd	t4,224(sp)
    80005a2c:	f5fa                	sd	t5,232(sp)
    80005a2e:	f9fe                	sd	t6,240(sp)
    80005a30:	d59fc0ef          	jal	ra,80002788 <kerneltrap>
    80005a34:	6082                	ld	ra,0(sp)
    80005a36:	6122                	ld	sp,8(sp)
    80005a38:	61c2                	ld	gp,16(sp)
    80005a3a:	7282                	ld	t0,32(sp)
    80005a3c:	7322                	ld	t1,40(sp)
    80005a3e:	73c2                	ld	t2,48(sp)
    80005a40:	7462                	ld	s0,56(sp)
    80005a42:	6486                	ld	s1,64(sp)
    80005a44:	6526                	ld	a0,72(sp)
    80005a46:	65c6                	ld	a1,80(sp)
    80005a48:	6666                	ld	a2,88(sp)
    80005a4a:	7686                	ld	a3,96(sp)
    80005a4c:	7726                	ld	a4,104(sp)
    80005a4e:	77c6                	ld	a5,112(sp)
    80005a50:	7866                	ld	a6,120(sp)
    80005a52:	688a                	ld	a7,128(sp)
    80005a54:	692a                	ld	s2,136(sp)
    80005a56:	69ca                	ld	s3,144(sp)
    80005a58:	6a6a                	ld	s4,152(sp)
    80005a5a:	7a8a                	ld	s5,160(sp)
    80005a5c:	7b2a                	ld	s6,168(sp)
    80005a5e:	7bca                	ld	s7,176(sp)
    80005a60:	7c6a                	ld	s8,184(sp)
    80005a62:	6c8e                	ld	s9,192(sp)
    80005a64:	6d2e                	ld	s10,200(sp)
    80005a66:	6dce                	ld	s11,208(sp)
    80005a68:	6e6e                	ld	t3,216(sp)
    80005a6a:	7e8e                	ld	t4,224(sp)
    80005a6c:	7f2e                	ld	t5,232(sp)
    80005a6e:	7fce                	ld	t6,240(sp)
    80005a70:	6111                	addi	sp,sp,256
    80005a72:	10200073          	sret
    80005a76:	00000013          	nop
    80005a7a:	00000013          	nop
    80005a7e:	0001                	nop

0000000080005a80 <timervec>:
    80005a80:	34051573          	csrrw	a0,mscratch,a0
    80005a84:	e10c                	sd	a1,0(a0)
    80005a86:	e510                	sd	a2,8(a0)
    80005a88:	e914                	sd	a3,16(a0)
    80005a8a:	710c                	ld	a1,32(a0)
    80005a8c:	7510                	ld	a2,40(a0)
    80005a8e:	6194                	ld	a3,0(a1)
    80005a90:	96b2                	add	a3,a3,a2
    80005a92:	e194                	sd	a3,0(a1)
    80005a94:	4589                	li	a1,2
    80005a96:	14459073          	csrw	sip,a1
    80005a9a:	6914                	ld	a3,16(a0)
    80005a9c:	6510                	ld	a2,8(a0)
    80005a9e:	610c                	ld	a1,0(a0)
    80005aa0:	34051573          	csrrw	a0,mscratch,a0
    80005aa4:	30200073          	mret
	...

0000000080005aaa <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005aaa:	1141                	addi	sp,sp,-16
    80005aac:	e422                	sd	s0,8(sp)
    80005aae:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005ab0:	0c0007b7          	lui	a5,0xc000
    80005ab4:	4705                	li	a4,1
    80005ab6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005ab8:	c3d8                	sw	a4,4(a5)
}
    80005aba:	6422                	ld	s0,8(sp)
    80005abc:	0141                	addi	sp,sp,16
    80005abe:	8082                	ret

0000000080005ac0 <plicinithart>:

void
plicinithart(void)
{
    80005ac0:	1141                	addi	sp,sp,-16
    80005ac2:	e406                	sd	ra,8(sp)
    80005ac4:	e022                	sd	s0,0(sp)
    80005ac6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005ac8:	ffffc097          	auipc	ra,0xffffc
    80005acc:	d4c080e7          	jalr	-692(ra) # 80001814 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005ad0:	0085171b          	slliw	a4,a0,0x8
    80005ad4:	0c0027b7          	lui	a5,0xc002
    80005ad8:	97ba                	add	a5,a5,a4
    80005ada:	40200713          	li	a4,1026
    80005ade:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005ae2:	00d5151b          	slliw	a0,a0,0xd
    80005ae6:	0c2017b7          	lui	a5,0xc201
    80005aea:	953e                	add	a0,a0,a5
    80005aec:	00052023          	sw	zero,0(a0)
}
    80005af0:	60a2                	ld	ra,8(sp)
    80005af2:	6402                	ld	s0,0(sp)
    80005af4:	0141                	addi	sp,sp,16
    80005af6:	8082                	ret

0000000080005af8 <plic_pending>:

// return a bitmap of which IRQs are waiting
// to be served.
uint64
plic_pending(void)
{
    80005af8:	1141                	addi	sp,sp,-16
    80005afa:	e422                	sd	s0,8(sp)
    80005afc:	0800                	addi	s0,sp,16
  //mask = *(uint32*)(PLIC + 0x1000);
  //mask |= (uint64)*(uint32*)(PLIC + 0x1004) << 32;
  mask = *(uint64*)PLIC_PENDING;

  return mask;
}
    80005afe:	0c0017b7          	lui	a5,0xc001
    80005b02:	6388                	ld	a0,0(a5)
    80005b04:	6422                	ld	s0,8(sp)
    80005b06:	0141                	addi	sp,sp,16
    80005b08:	8082                	ret

0000000080005b0a <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005b0a:	1141                	addi	sp,sp,-16
    80005b0c:	e406                	sd	ra,8(sp)
    80005b0e:	e022                	sd	s0,0(sp)
    80005b10:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005b12:	ffffc097          	auipc	ra,0xffffc
    80005b16:	d02080e7          	jalr	-766(ra) # 80001814 <cpuid>
  //int irq = *(uint32*)(PLIC + 0x201004);
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005b1a:	00d5179b          	slliw	a5,a0,0xd
    80005b1e:	0c201537          	lui	a0,0xc201
    80005b22:	953e                	add	a0,a0,a5
  return irq;
}
    80005b24:	4148                	lw	a0,4(a0)
    80005b26:	60a2                	ld	ra,8(sp)
    80005b28:	6402                	ld	s0,0(sp)
    80005b2a:	0141                	addi	sp,sp,16
    80005b2c:	8082                	ret

0000000080005b2e <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005b2e:	1101                	addi	sp,sp,-32
    80005b30:	ec06                	sd	ra,24(sp)
    80005b32:	e822                	sd	s0,16(sp)
    80005b34:	e426                	sd	s1,8(sp)
    80005b36:	1000                	addi	s0,sp,32
    80005b38:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005b3a:	ffffc097          	auipc	ra,0xffffc
    80005b3e:	cda080e7          	jalr	-806(ra) # 80001814 <cpuid>
  //*(uint32*)(PLIC + 0x201004) = irq;
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005b42:	00d5151b          	slliw	a0,a0,0xd
    80005b46:	0c2017b7          	lui	a5,0xc201
    80005b4a:	97aa                	add	a5,a5,a0
    80005b4c:	c3c4                	sw	s1,4(a5)
}
    80005b4e:	60e2                	ld	ra,24(sp)
    80005b50:	6442                	ld	s0,16(sp)
    80005b52:	64a2                	ld	s1,8(sp)
    80005b54:	6105                	addi	sp,sp,32
    80005b56:	8082                	ret

0000000080005b58 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005b58:	1141                	addi	sp,sp,-16
    80005b5a:	e406                	sd	ra,8(sp)
    80005b5c:	e022                	sd	s0,0(sp)
    80005b5e:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005b60:	479d                	li	a5,7
    80005b62:	04a7cc63          	blt	a5,a0,80005bba <free_desc+0x62>
    panic("virtio_disk_intr 1");
  if(disk.free[i])
    80005b66:	0001d797          	auipc	a5,0x1d
    80005b6a:	49a78793          	addi	a5,a5,1178 # 80023000 <disk>
    80005b6e:	00a78733          	add	a4,a5,a0
    80005b72:	6789                	lui	a5,0x2
    80005b74:	97ba                	add	a5,a5,a4
    80005b76:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005b7a:	eba1                	bnez	a5,80005bca <free_desc+0x72>
    panic("virtio_disk_intr 2");
  disk.desc[i].addr = 0;
    80005b7c:	00451713          	slli	a4,a0,0x4
    80005b80:	0001f797          	auipc	a5,0x1f
    80005b84:	4807b783          	ld	a5,1152(a5) # 80025000 <disk+0x2000>
    80005b88:	97ba                	add	a5,a5,a4
    80005b8a:	0007b023          	sd	zero,0(a5)
  disk.free[i] = 1;
    80005b8e:	0001d797          	auipc	a5,0x1d
    80005b92:	47278793          	addi	a5,a5,1138 # 80023000 <disk>
    80005b96:	97aa                	add	a5,a5,a0
    80005b98:	6509                	lui	a0,0x2
    80005b9a:	953e                	add	a0,a0,a5
    80005b9c:	4785                	li	a5,1
    80005b9e:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005ba2:	0001f517          	auipc	a0,0x1f
    80005ba6:	47650513          	addi	a0,a0,1142 # 80025018 <disk+0x2018>
    80005baa:	ffffc097          	auipc	ra,0xffffc
    80005bae:	5be080e7          	jalr	1470(ra) # 80002168 <wakeup>
}
    80005bb2:	60a2                	ld	ra,8(sp)
    80005bb4:	6402                	ld	s0,0(sp)
    80005bb6:	0141                	addi	sp,sp,16
    80005bb8:	8082                	ret
    panic("virtio_disk_intr 1");
    80005bba:	00002517          	auipc	a0,0x2
    80005bbe:	b9e50513          	addi	a0,a0,-1122 # 80007758 <userret+0x6c8>
    80005bc2:	ffffb097          	auipc	ra,0xffffb
    80005bc6:	98c080e7          	jalr	-1652(ra) # 8000054e <panic>
    panic("virtio_disk_intr 2");
    80005bca:	00002517          	auipc	a0,0x2
    80005bce:	ba650513          	addi	a0,a0,-1114 # 80007770 <userret+0x6e0>
    80005bd2:	ffffb097          	auipc	ra,0xffffb
    80005bd6:	97c080e7          	jalr	-1668(ra) # 8000054e <panic>

0000000080005bda <virtio_disk_init>:
{
    80005bda:	1101                	addi	sp,sp,-32
    80005bdc:	ec06                	sd	ra,24(sp)
    80005bde:	e822                	sd	s0,16(sp)
    80005be0:	e426                	sd	s1,8(sp)
    80005be2:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005be4:	00002597          	auipc	a1,0x2
    80005be8:	ba458593          	addi	a1,a1,-1116 # 80007788 <userret+0x6f8>
    80005bec:	0001f517          	auipc	a0,0x1f
    80005bf0:	4bc50513          	addi	a0,a0,1212 # 800250a8 <disk+0x20a8>
    80005bf4:	ffffb097          	auipc	ra,0xffffb
    80005bf8:	dc8080e7          	jalr	-568(ra) # 800009bc <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005bfc:	100017b7          	lui	a5,0x10001
    80005c00:	4398                	lw	a4,0(a5)
    80005c02:	2701                	sext.w	a4,a4
    80005c04:	747277b7          	lui	a5,0x74727
    80005c08:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005c0c:	0ef71163          	bne	a4,a5,80005cee <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005c10:	100017b7          	lui	a5,0x10001
    80005c14:	43dc                	lw	a5,4(a5)
    80005c16:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005c18:	4705                	li	a4,1
    80005c1a:	0ce79a63          	bne	a5,a4,80005cee <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005c1e:	100017b7          	lui	a5,0x10001
    80005c22:	479c                	lw	a5,8(a5)
    80005c24:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005c26:	4709                	li	a4,2
    80005c28:	0ce79363          	bne	a5,a4,80005cee <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005c2c:	100017b7          	lui	a5,0x10001
    80005c30:	47d8                	lw	a4,12(a5)
    80005c32:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005c34:	554d47b7          	lui	a5,0x554d4
    80005c38:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005c3c:	0af71963          	bne	a4,a5,80005cee <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005c40:	100017b7          	lui	a5,0x10001
    80005c44:	4705                	li	a4,1
    80005c46:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005c48:	470d                	li	a4,3
    80005c4a:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005c4c:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005c4e:	c7ffe737          	lui	a4,0xc7ffe
    80005c52:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd872b>
    80005c56:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005c58:	2701                	sext.w	a4,a4
    80005c5a:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005c5c:	472d                	li	a4,11
    80005c5e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005c60:	473d                	li	a4,15
    80005c62:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005c64:	6705                	lui	a4,0x1
    80005c66:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005c68:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005c6c:	5bdc                	lw	a5,52(a5)
    80005c6e:	2781                	sext.w	a5,a5
  if(max == 0)
    80005c70:	c7d9                	beqz	a5,80005cfe <virtio_disk_init+0x124>
  if(max < NUM)
    80005c72:	471d                	li	a4,7
    80005c74:	08f77d63          	bgeu	a4,a5,80005d0e <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005c78:	100014b7          	lui	s1,0x10001
    80005c7c:	47a1                	li	a5,8
    80005c7e:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005c80:	6609                	lui	a2,0x2
    80005c82:	4581                	li	a1,0
    80005c84:	0001d517          	auipc	a0,0x1d
    80005c88:	37c50513          	addi	a0,a0,892 # 80023000 <disk>
    80005c8c:	ffffb097          	auipc	ra,0xffffb
    80005c90:	ede080e7          	jalr	-290(ra) # 80000b6a <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005c94:	0001d717          	auipc	a4,0x1d
    80005c98:	36c70713          	addi	a4,a4,876 # 80023000 <disk>
    80005c9c:	00c75793          	srli	a5,a4,0xc
    80005ca0:	2781                	sext.w	a5,a5
    80005ca2:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct VRingDesc *) disk.pages;
    80005ca4:	0001f797          	auipc	a5,0x1f
    80005ca8:	35c78793          	addi	a5,a5,860 # 80025000 <disk+0x2000>
    80005cac:	e398                	sd	a4,0(a5)
  disk.avail = (uint16*)(((char*)disk.desc) + NUM*sizeof(struct VRingDesc));
    80005cae:	0001d717          	auipc	a4,0x1d
    80005cb2:	3d270713          	addi	a4,a4,978 # 80023080 <disk+0x80>
    80005cb6:	e798                	sd	a4,8(a5)
  disk.used = (struct UsedArea *) (disk.pages + PGSIZE);
    80005cb8:	0001e717          	auipc	a4,0x1e
    80005cbc:	34870713          	addi	a4,a4,840 # 80024000 <disk+0x1000>
    80005cc0:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005cc2:	4705                	li	a4,1
    80005cc4:	00e78c23          	sb	a4,24(a5)
    80005cc8:	00e78ca3          	sb	a4,25(a5)
    80005ccc:	00e78d23          	sb	a4,26(a5)
    80005cd0:	00e78da3          	sb	a4,27(a5)
    80005cd4:	00e78e23          	sb	a4,28(a5)
    80005cd8:	00e78ea3          	sb	a4,29(a5)
    80005cdc:	00e78f23          	sb	a4,30(a5)
    80005ce0:	00e78fa3          	sb	a4,31(a5)
}
    80005ce4:	60e2                	ld	ra,24(sp)
    80005ce6:	6442                	ld	s0,16(sp)
    80005ce8:	64a2                	ld	s1,8(sp)
    80005cea:	6105                	addi	sp,sp,32
    80005cec:	8082                	ret
    panic("could not find virtio disk");
    80005cee:	00002517          	auipc	a0,0x2
    80005cf2:	aaa50513          	addi	a0,a0,-1366 # 80007798 <userret+0x708>
    80005cf6:	ffffb097          	auipc	ra,0xffffb
    80005cfa:	858080e7          	jalr	-1960(ra) # 8000054e <panic>
    panic("virtio disk has no queue 0");
    80005cfe:	00002517          	auipc	a0,0x2
    80005d02:	aba50513          	addi	a0,a0,-1350 # 800077b8 <userret+0x728>
    80005d06:	ffffb097          	auipc	ra,0xffffb
    80005d0a:	848080e7          	jalr	-1976(ra) # 8000054e <panic>
    panic("virtio disk max queue too short");
    80005d0e:	00002517          	auipc	a0,0x2
    80005d12:	aca50513          	addi	a0,a0,-1334 # 800077d8 <userret+0x748>
    80005d16:	ffffb097          	auipc	ra,0xffffb
    80005d1a:	838080e7          	jalr	-1992(ra) # 8000054e <panic>

0000000080005d1e <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005d1e:	7119                	addi	sp,sp,-128
    80005d20:	fc86                	sd	ra,120(sp)
    80005d22:	f8a2                	sd	s0,112(sp)
    80005d24:	f4a6                	sd	s1,104(sp)
    80005d26:	f0ca                	sd	s2,96(sp)
    80005d28:	ecce                	sd	s3,88(sp)
    80005d2a:	e8d2                	sd	s4,80(sp)
    80005d2c:	e4d6                	sd	s5,72(sp)
    80005d2e:	e0da                	sd	s6,64(sp)
    80005d30:	fc5e                	sd	s7,56(sp)
    80005d32:	f862                	sd	s8,48(sp)
    80005d34:	f466                	sd	s9,40(sp)
    80005d36:	f06a                	sd	s10,32(sp)
    80005d38:	0100                	addi	s0,sp,128
    80005d3a:	892a                	mv	s2,a0
    80005d3c:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005d3e:	00c52c83          	lw	s9,12(a0)
    80005d42:	001c9c9b          	slliw	s9,s9,0x1
    80005d46:	1c82                	slli	s9,s9,0x20
    80005d48:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80005d4c:	0001f517          	auipc	a0,0x1f
    80005d50:	35c50513          	addi	a0,a0,860 # 800250a8 <disk+0x20a8>
    80005d54:	ffffb097          	auipc	ra,0xffffb
    80005d58:	d7a080e7          	jalr	-646(ra) # 80000ace <acquire>
  for(int i = 0; i < 3; i++){
    80005d5c:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80005d5e:	4c21                	li	s8,8
      disk.free[i] = 0;
    80005d60:	0001db97          	auipc	s7,0x1d
    80005d64:	2a0b8b93          	addi	s7,s7,672 # 80023000 <disk>
    80005d68:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80005d6a:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80005d6c:	8a4e                	mv	s4,s3
    80005d6e:	a051                	j	80005df2 <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80005d70:	00fb86b3          	add	a3,s7,a5
    80005d74:	96da                	add	a3,a3,s6
    80005d76:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80005d7a:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80005d7c:	0207c563          	bltz	a5,80005da6 <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80005d80:	2485                	addiw	s1,s1,1
    80005d82:	0711                	addi	a4,a4,4
    80005d84:	1b548863          	beq	s1,s5,80005f34 <virtio_disk_rw+0x216>
    idx[i] = alloc_desc();
    80005d88:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80005d8a:	0001f697          	auipc	a3,0x1f
    80005d8e:	28e68693          	addi	a3,a3,654 # 80025018 <disk+0x2018>
    80005d92:	87d2                	mv	a5,s4
    if(disk.free[i]){
    80005d94:	0006c583          	lbu	a1,0(a3)
    80005d98:	fde1                	bnez	a1,80005d70 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80005d9a:	2785                	addiw	a5,a5,1
    80005d9c:	0685                	addi	a3,a3,1
    80005d9e:	ff879be3          	bne	a5,s8,80005d94 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80005da2:	57fd                	li	a5,-1
    80005da4:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    80005da6:	02905a63          	blez	s1,80005dda <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005daa:	f9042503          	lw	a0,-112(s0)
    80005dae:	00000097          	auipc	ra,0x0
    80005db2:	daa080e7          	jalr	-598(ra) # 80005b58 <free_desc>
      for(int j = 0; j < i; j++)
    80005db6:	4785                	li	a5,1
    80005db8:	0297d163          	bge	a5,s1,80005dda <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005dbc:	f9442503          	lw	a0,-108(s0)
    80005dc0:	00000097          	auipc	ra,0x0
    80005dc4:	d98080e7          	jalr	-616(ra) # 80005b58 <free_desc>
      for(int j = 0; j < i; j++)
    80005dc8:	4789                	li	a5,2
    80005dca:	0097d863          	bge	a5,s1,80005dda <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005dce:	f9842503          	lw	a0,-104(s0)
    80005dd2:	00000097          	auipc	ra,0x0
    80005dd6:	d86080e7          	jalr	-634(ra) # 80005b58 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80005dda:	0001f597          	auipc	a1,0x1f
    80005dde:	2ce58593          	addi	a1,a1,718 # 800250a8 <disk+0x20a8>
    80005de2:	0001f517          	auipc	a0,0x1f
    80005de6:	23650513          	addi	a0,a0,566 # 80025018 <disk+0x2018>
    80005dea:	ffffc097          	auipc	ra,0xffffc
    80005dee:	1f8080e7          	jalr	504(ra) # 80001fe2 <sleep>
  for(int i = 0; i < 3; i++){
    80005df2:	f9040713          	addi	a4,s0,-112
    80005df6:	84ce                	mv	s1,s3
    80005df8:	bf41                	j	80005d88 <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80005dfa:	0001f717          	auipc	a4,0x1f
    80005dfe:	20673703          	ld	a4,518(a4) # 80025000 <disk+0x2000>
    80005e02:	973e                	add	a4,a4,a5
    80005e04:	00071623          	sh	zero,12(a4)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80005e08:	0001d517          	auipc	a0,0x1d
    80005e0c:	1f850513          	addi	a0,a0,504 # 80023000 <disk>
    80005e10:	0001f717          	auipc	a4,0x1f
    80005e14:	1f070713          	addi	a4,a4,496 # 80025000 <disk+0x2000>
    80005e18:	6310                	ld	a2,0(a4)
    80005e1a:	963e                	add	a2,a2,a5
    80005e1c:	00c65583          	lhu	a1,12(a2) # 200c <_entry-0x7fffdff4>
    80005e20:	0015e593          	ori	a1,a1,1
    80005e24:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[1]].next = idx[2];
    80005e28:	f9842683          	lw	a3,-104(s0)
    80005e2c:	6310                	ld	a2,0(a4)
    80005e2e:	97b2                	add	a5,a5,a2
    80005e30:	00d79723          	sh	a3,14(a5)

  disk.info[idx[0]].status = 0;
    80005e34:	20048613          	addi	a2,s1,512 # 10001200 <_entry-0x6fffee00>
    80005e38:	0612                	slli	a2,a2,0x4
    80005e3a:	962a                	add	a2,a2,a0
    80005e3c:	02060823          	sb	zero,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80005e40:	00469793          	slli	a5,a3,0x4
    80005e44:	630c                	ld	a1,0(a4)
    80005e46:	95be                	add	a1,a1,a5
    80005e48:	6689                	lui	a3,0x2
    80005e4a:	03068693          	addi	a3,a3,48 # 2030 <_entry-0x7fffdfd0>
    80005e4e:	96ce                	add	a3,a3,s3
    80005e50:	96aa                	add	a3,a3,a0
    80005e52:	e194                	sd	a3,0(a1)
  disk.desc[idx[2]].len = 1;
    80005e54:	6314                	ld	a3,0(a4)
    80005e56:	96be                	add	a3,a3,a5
    80005e58:	4585                	li	a1,1
    80005e5a:	c68c                	sw	a1,8(a3)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80005e5c:	6314                	ld	a3,0(a4)
    80005e5e:	96be                	add	a3,a3,a5
    80005e60:	4509                	li	a0,2
    80005e62:	00a69623          	sh	a0,12(a3)
  disk.desc[idx[2]].next = 0;
    80005e66:	6314                	ld	a3,0(a4)
    80005e68:	97b6                	add	a5,a5,a3
    80005e6a:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80005e6e:	00b92223          	sw	a1,4(s2)
  disk.info[idx[0]].b = b;
    80005e72:	03263423          	sd	s2,40(a2)

  // avail[0] is flags
  // avail[1] tells the device how far to look in avail[2...].
  // avail[2...] are desc[] indices the device should process.
  // we only tell device the first index in our chain of descriptors.
  disk.avail[2 + (disk.avail[1] % NUM)] = idx[0];
    80005e76:	6714                	ld	a3,8(a4)
    80005e78:	0026d783          	lhu	a5,2(a3)
    80005e7c:	8b9d                	andi	a5,a5,7
    80005e7e:	0789                	addi	a5,a5,2
    80005e80:	0786                	slli	a5,a5,0x1
    80005e82:	97b6                	add	a5,a5,a3
    80005e84:	00979023          	sh	s1,0(a5)
  __sync_synchronize();
    80005e88:	0ff0000f          	fence
  disk.avail[1] = disk.avail[1] + 1;
    80005e8c:	6718                	ld	a4,8(a4)
    80005e8e:	00275783          	lhu	a5,2(a4)
    80005e92:	2785                	addiw	a5,a5,1
    80005e94:	00f71123          	sh	a5,2(a4)

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80005e98:	100017b7          	lui	a5,0x10001
    80005e9c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80005ea0:	00492783          	lw	a5,4(s2)
    80005ea4:	02b79163          	bne	a5,a1,80005ec6 <virtio_disk_rw+0x1a8>
    sleep(b, &disk.vdisk_lock);
    80005ea8:	0001f997          	auipc	s3,0x1f
    80005eac:	20098993          	addi	s3,s3,512 # 800250a8 <disk+0x20a8>
  while(b->disk == 1) {
    80005eb0:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80005eb2:	85ce                	mv	a1,s3
    80005eb4:	854a                	mv	a0,s2
    80005eb6:	ffffc097          	auipc	ra,0xffffc
    80005eba:	12c080e7          	jalr	300(ra) # 80001fe2 <sleep>
  while(b->disk == 1) {
    80005ebe:	00492783          	lw	a5,4(s2)
    80005ec2:	fe9788e3          	beq	a5,s1,80005eb2 <virtio_disk_rw+0x194>
  }

  disk.info[idx[0]].b = 0;
    80005ec6:	f9042483          	lw	s1,-112(s0)
    80005eca:	20048793          	addi	a5,s1,512
    80005ece:	00479713          	slli	a4,a5,0x4
    80005ed2:	0001d797          	auipc	a5,0x1d
    80005ed6:	12e78793          	addi	a5,a5,302 # 80023000 <disk>
    80005eda:	97ba                	add	a5,a5,a4
    80005edc:	0207b423          	sd	zero,40(a5)
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    80005ee0:	0001f917          	auipc	s2,0x1f
    80005ee4:	12090913          	addi	s2,s2,288 # 80025000 <disk+0x2000>
    free_desc(i);
    80005ee8:	8526                	mv	a0,s1
    80005eea:	00000097          	auipc	ra,0x0
    80005eee:	c6e080e7          	jalr	-914(ra) # 80005b58 <free_desc>
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    80005ef2:	0492                	slli	s1,s1,0x4
    80005ef4:	00093783          	ld	a5,0(s2)
    80005ef8:	94be                	add	s1,s1,a5
    80005efa:	00c4d783          	lhu	a5,12(s1)
    80005efe:	8b85                	andi	a5,a5,1
    80005f00:	c781                	beqz	a5,80005f08 <virtio_disk_rw+0x1ea>
      i = disk.desc[i].next;
    80005f02:	00e4d483          	lhu	s1,14(s1)
    free_desc(i);
    80005f06:	b7cd                	j	80005ee8 <virtio_disk_rw+0x1ca>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80005f08:	0001f517          	auipc	a0,0x1f
    80005f0c:	1a050513          	addi	a0,a0,416 # 800250a8 <disk+0x20a8>
    80005f10:	ffffb097          	auipc	ra,0xffffb
    80005f14:	c12080e7          	jalr	-1006(ra) # 80000b22 <release>
}
    80005f18:	70e6                	ld	ra,120(sp)
    80005f1a:	7446                	ld	s0,112(sp)
    80005f1c:	74a6                	ld	s1,104(sp)
    80005f1e:	7906                	ld	s2,96(sp)
    80005f20:	69e6                	ld	s3,88(sp)
    80005f22:	6a46                	ld	s4,80(sp)
    80005f24:	6aa6                	ld	s5,72(sp)
    80005f26:	6b06                	ld	s6,64(sp)
    80005f28:	7be2                	ld	s7,56(sp)
    80005f2a:	7c42                	ld	s8,48(sp)
    80005f2c:	7ca2                	ld	s9,40(sp)
    80005f2e:	7d02                	ld	s10,32(sp)
    80005f30:	6109                	addi	sp,sp,128
    80005f32:	8082                	ret
  if(write)
    80005f34:	01a037b3          	snez	a5,s10
    80005f38:	f8f42023          	sw	a5,-128(s0)
  buf0.reserved = 0;
    80005f3c:	f8042223          	sw	zero,-124(s0)
  buf0.sector = sector;
    80005f40:	f9943423          	sd	s9,-120(s0)
  disk.desc[idx[0]].addr = (uint64) kvmpa((uint64) &buf0);
    80005f44:	f9042483          	lw	s1,-112(s0)
    80005f48:	00449993          	slli	s3,s1,0x4
    80005f4c:	0001fa17          	auipc	s4,0x1f
    80005f50:	0b4a0a13          	addi	s4,s4,180 # 80025000 <disk+0x2000>
    80005f54:	000a3a83          	ld	s5,0(s4)
    80005f58:	9ace                	add	s5,s5,s3
    80005f5a:	f8040513          	addi	a0,s0,-128
    80005f5e:	ffffb097          	auipc	ra,0xffffb
    80005f62:	04a080e7          	jalr	74(ra) # 80000fa8 <kvmpa>
    80005f66:	00aab023          	sd	a0,0(s5)
  disk.desc[idx[0]].len = sizeof(buf0);
    80005f6a:	000a3783          	ld	a5,0(s4)
    80005f6e:	97ce                	add	a5,a5,s3
    80005f70:	4741                	li	a4,16
    80005f72:	c798                	sw	a4,8(a5)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80005f74:	000a3783          	ld	a5,0(s4)
    80005f78:	97ce                	add	a5,a5,s3
    80005f7a:	4705                	li	a4,1
    80005f7c:	00e79623          	sh	a4,12(a5)
  disk.desc[idx[0]].next = idx[1];
    80005f80:	f9442783          	lw	a5,-108(s0)
    80005f84:	000a3703          	ld	a4,0(s4)
    80005f88:	974e                	add	a4,a4,s3
    80005f8a:	00f71723          	sh	a5,14(a4)
  disk.desc[idx[1]].addr = (uint64) b->data;
    80005f8e:	0792                	slli	a5,a5,0x4
    80005f90:	000a3703          	ld	a4,0(s4)
    80005f94:	973e                	add	a4,a4,a5
    80005f96:	06090693          	addi	a3,s2,96
    80005f9a:	e314                	sd	a3,0(a4)
  disk.desc[idx[1]].len = BSIZE;
    80005f9c:	000a3703          	ld	a4,0(s4)
    80005fa0:	973e                	add	a4,a4,a5
    80005fa2:	40000693          	li	a3,1024
    80005fa6:	c714                	sw	a3,8(a4)
  if(write)
    80005fa8:	e40d19e3          	bnez	s10,80005dfa <virtio_disk_rw+0xdc>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80005fac:	0001f717          	auipc	a4,0x1f
    80005fb0:	05473703          	ld	a4,84(a4) # 80025000 <disk+0x2000>
    80005fb4:	973e                	add	a4,a4,a5
    80005fb6:	4689                	li	a3,2
    80005fb8:	00d71623          	sh	a3,12(a4)
    80005fbc:	b5b1                	j	80005e08 <virtio_disk_rw+0xea>

0000000080005fbe <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80005fbe:	1101                	addi	sp,sp,-32
    80005fc0:	ec06                	sd	ra,24(sp)
    80005fc2:	e822                	sd	s0,16(sp)
    80005fc4:	e426                	sd	s1,8(sp)
    80005fc6:	e04a                	sd	s2,0(sp)
    80005fc8:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80005fca:	0001f517          	auipc	a0,0x1f
    80005fce:	0de50513          	addi	a0,a0,222 # 800250a8 <disk+0x20a8>
    80005fd2:	ffffb097          	auipc	ra,0xffffb
    80005fd6:	afc080e7          	jalr	-1284(ra) # 80000ace <acquire>

  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    80005fda:	0001f717          	auipc	a4,0x1f
    80005fde:	02670713          	addi	a4,a4,38 # 80025000 <disk+0x2000>
    80005fe2:	02075783          	lhu	a5,32(a4)
    80005fe6:	6b18                	ld	a4,16(a4)
    80005fe8:	00275683          	lhu	a3,2(a4)
    80005fec:	8ebd                	xor	a3,a3,a5
    80005fee:	8a9d                	andi	a3,a3,7
    80005ff0:	cab9                	beqz	a3,80006046 <virtio_disk_intr+0x88>
    int id = disk.used->elems[disk.used_idx].id;

    if(disk.info[id].status != 0)
    80005ff2:	0001d917          	auipc	s2,0x1d
    80005ff6:	00e90913          	addi	s2,s2,14 # 80023000 <disk>
      panic("virtio_disk_intr status");
    
    disk.info[id].b->disk = 0;   // disk is done with buf
    wakeup(disk.info[id].b);

    disk.used_idx = (disk.used_idx + 1) % NUM;
    80005ffa:	0001f497          	auipc	s1,0x1f
    80005ffe:	00648493          	addi	s1,s1,6 # 80025000 <disk+0x2000>
    int id = disk.used->elems[disk.used_idx].id;
    80006002:	078e                	slli	a5,a5,0x3
    80006004:	97ba                	add	a5,a5,a4
    80006006:	43dc                	lw	a5,4(a5)
    if(disk.info[id].status != 0)
    80006008:	20078713          	addi	a4,a5,512
    8000600c:	0712                	slli	a4,a4,0x4
    8000600e:	974a                	add	a4,a4,s2
    80006010:	03074703          	lbu	a4,48(a4)
    80006014:	e739                	bnez	a4,80006062 <virtio_disk_intr+0xa4>
    disk.info[id].b->disk = 0;   // disk is done with buf
    80006016:	20078793          	addi	a5,a5,512
    8000601a:	0792                	slli	a5,a5,0x4
    8000601c:	97ca                	add	a5,a5,s2
    8000601e:	7798                	ld	a4,40(a5)
    80006020:	00072223          	sw	zero,4(a4)
    wakeup(disk.info[id].b);
    80006024:	7788                	ld	a0,40(a5)
    80006026:	ffffc097          	auipc	ra,0xffffc
    8000602a:	142080e7          	jalr	322(ra) # 80002168 <wakeup>
    disk.used_idx = (disk.used_idx + 1) % NUM;
    8000602e:	0204d783          	lhu	a5,32(s1)
    80006032:	2785                	addiw	a5,a5,1
    80006034:	8b9d                	andi	a5,a5,7
    80006036:	02f49023          	sh	a5,32(s1)
  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    8000603a:	6898                	ld	a4,16(s1)
    8000603c:	00275683          	lhu	a3,2(a4)
    80006040:	8a9d                	andi	a3,a3,7
    80006042:	fcf690e3          	bne	a3,a5,80006002 <virtio_disk_intr+0x44>
  }

  release(&disk.vdisk_lock);
    80006046:	0001f517          	auipc	a0,0x1f
    8000604a:	06250513          	addi	a0,a0,98 # 800250a8 <disk+0x20a8>
    8000604e:	ffffb097          	auipc	ra,0xffffb
    80006052:	ad4080e7          	jalr	-1324(ra) # 80000b22 <release>
}
    80006056:	60e2                	ld	ra,24(sp)
    80006058:	6442                	ld	s0,16(sp)
    8000605a:	64a2                	ld	s1,8(sp)
    8000605c:	6902                	ld	s2,0(sp)
    8000605e:	6105                	addi	sp,sp,32
    80006060:	8082                	ret
      panic("virtio_disk_intr status");
    80006062:	00001517          	auipc	a0,0x1
    80006066:	79650513          	addi	a0,a0,1942 # 800077f8 <userret+0x768>
    8000606a:	ffffa097          	auipc	ra,0xffffa
    8000606e:	4e4080e7          	jalr	1252(ra) # 8000054e <panic>
	...

0000000080007000 <trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
