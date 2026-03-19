
#let from-columns(..lists) = {
  return array.zip(..lists).flatten()
}

#let I2C = [I#super[2]C]
#let NA = [N/A]
#let indexes = range(0, 8).map(repr)

#let prepend-indexes(list) = {
  for (i, a) in list.enumerate() {
    ([[#i]], ..a)
  }
}

#let inputs = (
  [0],  [#NA]            , [],
  [1],  [RESUME]         , [If the machine hit a breakpoint (HALT mode), a positive flank will allow it to resume.],
  [2],  [#overline[STOP]], [The processor runs normally while this pin is high.],
  [3],  [DUMP]           , [On a rising edge if the machine is stopped, will dump all internal register information.],
  [4],  [#NA]            , [Bit 3 of low/high nibble of current opcode],
  [5],  [MAN_RDY]        , [On a rising edge while Pin 2 is low, the instruction in the manual register will be executed.],
  [6],  [MAN_SHFT]       , [On a rising edge MAN_BIT will be shifted into the manual instruction register.],
  [7],  [MAN_BIT]        , [The bit to be shifted into the manual instruction register.],
)
#let outputs = (
  [0], [HALT]   , [HIGH if the machine is not resuming due to being stopped or having hit a breakpoint],
  [1], [DMP_CLK], [A rising edge indicates that the next bit of the dump line is ready],
  [2], [DML_DAT], [The next bit to be dumped],
  [3], NA       , [],
  [4], [LED_0]  , [power LED_0],
  [5], [LED_1]  , [power LED_1],
  [6], [LED_2]  , [power LED_2],
  [7], [LED_3]  , [power LED_3],
)
#let inouts  = (
  [0], NA,             [],
  [1], NA,             [],
  [2], NA,             [],
  [3], NA,             [],
  [4], I2C + [ sda_0], [],
  [5], I2C + [ scl_0], [],
  [6], I2C + [ sda_1], [],
  [7], I2C + [ scl_1], [],
)



#figure(caption: [Pinout], [
  #show table.cell.where(y: 0): strong
  #show table.cell.where(y: 1): strong
  #show table.cell.where(y: 10): strong
  #show table.cell.where(y: 19): strong
  #table(columns: 3,
    table.header(level: 1, [Index], [Name], [Description]),
    table.header(level: 2, [Inputs], [], []),
    ..inputs,
    table.header(level: 2, [Outputs], [], []),
    ..outputs,
    table.header(level: 2, [Inouts], [], []),
    ..inouts,
  ) ]
)

#let regs = (
  ([000], [RZ], sym.checkmark, sym.checkmark, [1], [Always reads $0_16$ or $0_8$]),
  ([001], [R1], sym.checkmark, sym.crossmark, [1], [General Purpose register]),
  ([010], [R2], sym.checkmark, sym.crossmark, [1], [General Purpose register]),
  ([011], [R3], sym.checkmark, sym.crossmark, [1], [General Purpose register]),
  ([100], [RE], sym.checkmark, sym.checkmark, [0], [Extended GP: R2 $+$ R3 *or* Anchor]),
  ([101], [B1], sym.crossmark, sym.checkmark, [2], [Anchor for relative memory addressing]),
  ([110], [B2], sym.crossmark, sym.checkmark, [2], [Anchor for relative memory addressing]),
  ([111], [PC], sym.crossmark, sym.checkmark, [2], [Program Counter]),
)

#figure(caption: [Register encoding and availability scheme], [

  #show sym.crossmark: set text(red.darken(50%))
  #show sym.checkmark: set text(green.darken(50%))
  #show table.cell.where(y: 0): strong
  #show table.cell.where(y: 0): set align(bottom + center)

  #let hdr = ([Index],[Encoding],[Name],[ALU],[MEM],[Bytes])

  #table(columns: hdr.len()+1,
    table.header(..hdr.map(x => rotate(-90deg, reflow:true, x)), [Purpose]),
    ..prepend-indexes(regs)
  )
])

#let opcode(..args) = {
  let op_bits = 16
  let fnsze(x) = {
    if type(x) == int {
      1
    } else if type(x) == array {
      x.len()
    } else {
      x.colspan
    }
  }
  let cellify(x) = {
    if type(x) == int {
      table.cell(fill: gray.lighten(60%), [#x])
    } else if type(x) == array {
      assert(false, message: repr(x))
      for v in x {
        // v
      }
    }else {
      x
    }
  }
  let box_count = args.pos().map(fnsze).sum(default:16)
  let cells = args.pos().map(cellify)
  // assert(box_count == op_bits, message: "Expected 16 bits, but obtained: " + repr(box_count) + " | " + repr(args))

  table(rows: (auto, .2em), columns: op_bits, stroke:none, row-gutter: 0.1em, column-gutter:0.2em, ..cells, ..range(0, op_bits).map(_ => table.cell(fill:black.lighten(60%), [])) )
}
#let opbits(size: 1, fill: gray, ..bits) = {
  let cont(x) = if (type(x) == int) { [#x] } else {x};
  bits.pos().map(b => table.cell(colspan: size, fill: fill.lighten(60%), cont(b)))
}

// #figure(caption: [Available Instructions], [
#[
  #show table.cell.where(y: 0): strong
  #show table.cell.where(x: 1): set align(center)
  #let (dst, src1, src2, w12, w8, o8, o6, flags) = (emph[dst], emph[src_1], emph[src_2], emph[word_12], emph[word_8], emph[offset_8], emph[offset_6], [\<flags\>],)

  #let (ALU, MEM, BTH) = ([ALU], [MEM], [ALU \ MEM])
  #let opdst  = table.cell(colspan: 2, align: horizon, fill: color.teal.lighten(60%), text(size: .8em)[DST])
  #let opsrc1 = table.cell(colspan: 2, align: horizon, fill: green.lighten(60%), text(size: .8em)[SRC#sub[1]])
  #let opsrc2 = table.cell(colspan: 2, align: horizon, fill: green.lighten(60%), text(size: .8em)[SRC#sub[2]])

  // #let dc(n) = opbits(size: n, fill: black, [---]).first()
  #let dc(n) = { range(n).map(_ => opbits(fill: black, [--]).first()) }
  #let v0 = opbits(fill: orange, [0]).first()
  #let v1 = opbits(fill: orange, [1]).first()
  #let word8 = opbits(size: 8, fill: orange, [8-Bit WORD]).first()
  // #let offset6 = table.cell(colspan: 6, fill: orange.lighten(60%), [6-Bit OFF])
  #let offset6 = opbits(size: 6, fill:orange, [6-Bit OFF]).first()

  #let op(pseudo: false, x, xs) = { if not pseudo {strong(x)} else { x }; [ #xs ] }

  #let mode = (
    ALU: opbits(0, 0), // any ALU operation
    REG: opbits(0, 1), // Moving immediate data into registers (optionally between registers)
    MEM: opbits(0, 1), // Memory (load/store) operations absolute and relative to the stack
    JMP: opbits(1, 1), // Operations changing control flow
  )
  #let aluctl = (
    AND: opbits(fill: orange, 0, 0, 0),
     OR: opbits(fill: orange, 0, 0, 1),
    ADD: opbits(fill: orange, 0, 1, 0),
    SUB: opbits(fill: orange, 0, 1, 1),
    XOR: opbits(fill: orange, 1, 0, 0),
    NOT: opbits(fill: orange, 1, 0, 1),
    SHL: opbits(fill: orange, 1, 1, 0),
    SHR: opbits(fill: orange, 1, 1, 1),
  )

  // (id: [], asm: [], code: [], dst: [], src: [], info: []),
  #let operations = (
    _and:   (id: "and"  , asm: op[and][#dst #src1]  , code: opcode(..mode.ALU, opdst, ..dc(2), opsrc1, ..dc(2), opsrc2,  ..aluctl.AND, 0), dst: [#ALU], src: [#ALU], info: [$C$ = 0]),
    _or:    (id: " or"  , asm: op[ or][#dst #src1]  , code: opcode(..mode.ALU, opdst, ..dc(2), opsrc1, ..dc(2), opsrc2,  ..aluctl.OR , 0), dst: [#ALU], src: [#ALU], info: [$C$ = 0]),
    _add:   (id: "add"  , asm: op[add][#dst #src1]  , code: opcode(..mode.ALU, opdst, ..dc(2), opsrc1, ..dc(2), opsrc2,  ..aluctl.ADD, 0), dst: [#ALU], src: [#ALU], info: [$C$ = Overflow]),
    _add_c: (id: "add.c", asm: op[add.c][#dst #src1], code: opcode(..mode.ALU, opdst, ..dc(2), opsrc1, ..dc(2), opsrc2,  ..aluctl.ADD, 1), dst: [#ALU], src: [#ALU], info: [$C$ = Overflow; Increments by 1 if $C$ was set before ]),
    _sub:   (id: "sub"  , asm: op[sub][#dst #src1]  , code: opcode(..mode.ALU, opdst, ..dc(2), opsrc1, ..dc(2), opsrc2,  ..aluctl.SUB, 0), dst: [#ALU], src: [#ALU], info: [$C$ = Overflow]),
    _xor:   (id: "xor"  , asm: op[xor][#dst #src1]  , code: opcode(..mode.ALU, opdst, ..dc(2), opsrc1, ..dc(2), opsrc2,  ..aluctl.XOR, 0), dst: [#ALU], src: [#ALU], info: [Sets the $C$ flag if any bit is 1 in both sources]),
    _not:   (id: "not"  , asm: op[not][#dst #src1]  , code: opcode(..mode.ALU, opdst, ..dc(2), opsrc1, ..dc(2), ..dc(2), ..aluctl.NOT, 0), dst: [#ALU], src: [#ALU], info: [$C$ = 0]),
    _shl:   (id: "shl"  , asm: op[shl][#dst #src1]  , code: opcode(..mode.ALU, opdst, ..dc(2), opsrc1, ..dc(2), ..dc(2), ..aluctl.SHL, 0), dst: [#ALU], src: [#ALU], info: [$C$ = LSB]),
    _shr:   (id: "shr"  , asm: op[shr][#dst #src1]  , code: opcode(..mode.ALU, opdst, ..dc(2), opsrc1, ..dc(2), ..dc(2), ..aluctl.SHR, 0), dst: [#ALU], src: [#ALU], info: [$C$ = MSB]),

    _add_i: (id: "add.i", asm: op[add.i][#dst #src1 #w8], code: opcode(..mode.REG, opdst, 0, 0, opsrc1, word8), dst: [#ALU], src: [#ALU], info: [Add immediate word to register]),
    _add_m: (id: "add.m", asm: op[add.m][#dst #src1 #w8], code: opcode(..mode.REG, opdst, 0, 1, opsrc1, word8), dst: [#MEM], src: [#MEM], info: [Copy value from MEM register]),

    _load:  (id: "load" , asm: op[load.i][#dst #src1 #w8]   , code: opcode(..mode.MEM, opdst, 1, 0, opsrc1, word8)      , dst: [#ALU], src: [#MEM], info: [Load the value at $#src1 + #w8$ into #dst (Sign extended)]),
    _store: (id: "store", asm: op[store.i][#dst #src1 #w8]  , code: opcode(..mode.MEM, opdst, 1, 1, opsrc1, word8)      , dst: [#ALU], src: [#MEM], info: [Store the value from #dst into $#src1 + #w8$ (Sign extended)]),

    _jmp: (id: "jmp", asm: op[jmp][#flags #dst #w8]   , code: opcode(..mode.JMP, ..opbits(fill:yellow, [C], [>], [=], [<]), opsrc1, word8), dst: [   ], src: [#MEM], info: [If any of the given flags is set, jumps to #dst + #w8]),
    // _cmp_a:  (id: "cmp.a", asm: op[cmp.a][#src1 #src2], code: opcode(..mode.JMP, 0, 0, dc(3), opsrc1, opsrc2, dc(3))                    , dst: [   ], src: [   ], info: [   ]),
    // _cmp_p:  (id: "cmp.p", asm: op[cmp.p][#src1 #src2], code: opcode(..mode.JMP, 0, 0, dc(3), opsrc1, opsrc2, dc(3))                    , dst: [   ], src: [   ], info: [   ]),
    // _cmp_m:  (id: "cmp.m", asm: op[cmp.m][#src1 #src2], code: opcode(..mode.JMP, 0, 0, dc(3), opsrc1, opsrc2, dc(3))                    , dst: [   ], src: [   ], info: [   ]),
  )
  #let inst = operations.pairs().map(p => {let (k, v) =  p; (k, v.values().slice(1))}).to-dict()
  #pagebreak()

  #table(columns: (auto, 40%, auto, auto, auto),
  table.header[Pseudo Assembler][Opcode][DST][SRC][Additional Info],
    table.cell(colspan: 5, align: center, [*Arithmetic Operations*]),
    ..inst._and,
    ..inst._or,
    ..inst._add,
    ..inst._add_c,
    ..inst._sub,
    ..inst._xor,
    ..inst._not,
    ..inst._shl,
    ..inst._shr,

    table.cell(colspan: 5, align: center, [*Register Operations*]),
    ..inst._add_i,
    ..inst._add_m,

    table.cell(colspan: 5, align: center, [*Memory operations*]),
    ..inst._load,
    ..inst._store,

    table.cell(colspan: 5, align: center, [*Control Flow*]),
    ..inst._jmp,
  )

  #let inst_with_immediates = (operations._add_i, operations._load, operations._store, operations._jmp)
  #let inst_with_src2 = (
    operations._and,
    operations._or,
    operations._add,
    operations._add_c,
    operations._sub,
    operations._xor,
    operations._not,
    operations._shl,
    operations._shr,
  )

  #pagebreak()

  // #table(columns: (auto, 40%), stroke: none,
  // table.header[][],
  //   ..inst_with_immediates.map(v => (v.id, v.code)).flatten(),
  //   // table.hline(),
  //   ..inst_with_src2.map(v => (v.id, v.code)).flatten(),
  // )

  #table(align: alignment.horizon, columns: (auto, 40%), stroke: none, [], [], ..(
    operations._load,
    operations._store,
    operations._add_i,
    operations._add_m,
  ).map(v => (v.id, v.code)).flatten())

  #pagebreak()
  #table(align: center, columns: 40%, stroke: none, ..operations.values().map(v => v.code))

]
// )


  // op(pseudo: true)[cmp][#src1 #src2], opcode(..mode.ALU, ..opbits(0, 0, 0), opsrc1, opsrc2, dc(3)), [Compares src_1 with src_2 and sets the #flags register accordingly],
  // op(pseudo: true)[mov][#dst #src1], opcode(..mode.ALU, opdst, opsrc1, ..opbits(0, 0, 0), ..aluctl.OR), [Copy value from source register to destination],
  // op[asf][#w8]           , opcode(), [Moves the stack frame down by #w8],
  // op[ssf][#w8]           , opcode(), [Moves the stack frame up by #w8],

