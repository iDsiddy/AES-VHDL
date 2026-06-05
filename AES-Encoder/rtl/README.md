# AES-128 VHDL RTL Implementation

This folder contains the Register Transfer Level (RTL) implementation of the AES-128 encryption algorithm in VHDL. The design follows a pipeline architecture with 11 rounds of AES transformations.

## Architecture Overview

The AES-128 encoder uses a **pipelined datapath architecture** with:
- **Rounds**: 11 total (1 initial round + 9 main rounds + 1 final round)
- **Pipeline Stages**: 4-stage pipeline per round (SubBytes → ShiftRows → MixColumns → AddRoundKey)
- **Key Expansion**: On-the-fly round key generation synchronized with datapath
- **Control**: Finite State Machine (FSM) managing round sequencing and control signals

### System Block Diagram

```
┌─────────────┐
│  plaintext  │
│ master_key  │
└──────┬──────┘
       │
       ▼
┌──────────────────────────────────────────────────┐
│  device (top-level module)                       │
│  ┌────────────────────────────────────────────┐  │
│  │ controller (FSM)                           │  │
│  │ ├─ IDLE → INIT → ROUND → FINAL → DONE      │  │
│  │ └─ Controls: init, state_en, key_en, ...   │  │
│  └────────────────────────────────────────────┘  │
│                       │                          │
│  ┌────────────────────▼────────────────────────┐ │
│  │ datapath (4-stage pipeline)                 │ │
│  │ ├─ SubBytes                                 │ │
│  │ ├─ ShiftRows                                │ │
│  │ ├─ MixColumns (bypassed in final round)     │ │
│  │ └─ AddRoundKey                              │ │
│  └────────────────────┬────────────────────────┘ │
│                       │                          │
│  ┌────────────────────▼────────────────────────┐ │
│  │ key_schedule (round key generation)         │ │
│  │ ├─ RotWord (byte rotation)                  │ │
│  │ ├─ SubWord (SBox application)               │ │
│  │ ├─ Rcon (round constant)                    │ │
│  │ └─ Word-wise XOR chain                      │ │
│  └─────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────┘
       │
       ▼
┌─────────────┐
│ ciphertext  │
│    done     │
└─────────────┘
```

---

## Module Descriptions

### 1. **device.vhd** - Top-Level AES Encoder
**Type**: Structural (hierarchical container)  
**Purpose**: Integrates controller, datapath, and key schedule into a unified AES-128 encoder

#### Entity Interface
```vhdl
port (
    plaintext, master_key : in std_logic_vector(127 downto 0);  -- 128-bit inputs
    ciphertext : out std_logic_vector(127 downto 0);             -- 128-bit output
    clk, rst, start : in std_logic;                               -- Control inputs
    done : out std_logic                                          -- Completion flag
);
```

#### Architecture
- **Hierarchical Design**: Instantiates 3 components (controller, datapath, key_schedule)
- **Signal Routing**: Routes control signals from controller to datapath and key_schedule
- **Pipeline Synchronization**: Coordinates all three components via registered interfaces
- **Key Flow**: `master_key` → `key_schedule` → `key_out` → `next_key` (feedback to datapath)
- **State Flow**: `plaintext XOR master_key` → `datapath` → `state_out` → `ciphertext`

#### Key Features
- Clean separation between control (FSM) and data (pipeline) paths
- Standard AES-128 interface (128-bit plaintext/key/ciphertext)
- Synchronous reset and start control
- Status indication via `done` output

---

### 2. **controller.vhd** - Finite State Machine
**Type**: Sequential (FSM implementation)  
**Purpose**: Manages encryption flow through 11 AES rounds with proper control signaling

#### Entity Interface
```vhdl
port (
    clk, rst, start : in std_logic;
    init, state_en, key_en, final_rnd, done : out std_logic;
    rnd_no : out std_logic_vector(3 downto 0)
);
```

#### FSM States

| State | Duration | Purpose | Control Outputs |
|-------|----------|---------|-----------------|
| **IDLE** | Variable | Waits for `start` signal | All '0' |
| **INIT** | 1 cycle | Loads plaintext XOR key into state register | init='1', state_en='1', key_en='1' |
| **ROUND** | 9 cycles (round 1-9) | Main AES rounds with SubBytes→ShiftRows→MixColumns→AddRoundKey | state_en='1', key_en='1' |
| **FINAL** | 1 cycle | Final round without MixColumns | state_en='1', key_en='1', final_rnd='1' |
| **DONE_ST** | Variable | Indicates completion, waits for new `start` or reset | done='1' |

#### Round Counter
- Initialized to 0 in IDLE
- Set to 1 in INIT
- Incremented 1-9 in ROUND states
- Transition to FINAL when rnd_no = 9
- Reset on return to IDLE or after DONE_ST

#### State Transitions
```
IDLE --[start='1']--> INIT --[automatic]--> ROUND --[rnd_no<9]--> ROUND
                                              ▲       ▲
                                              └───────┘ (loops 1-9)
                                              
                                            --[rnd_no=9]--> FINAL --[automatic]--> DONE_ST
                                            
DONE_ST --[start='1']--> INIT
   ▲
   └─[start='0']----- (stays in DONE_ST)
```

#### Output Control Signals
- **init**: High during INIT to select plaintext XOR key into state register
- **state_en**: High during INIT, ROUND, FINAL to enable state register updates
- **key_en**: High during INIT, ROUND, FINAL to enable key register updates
- **final_rnd**: High during FINAL to bypass MixColumns in datapath
- **done**: High during DONE_ST to indicate encryption completion
- **rnd_no**: 4-bit round number (0-10) output as std_logic_vector

---

### 3. **datapath.vhd** - 4-Stage AES Pipeline
**Type**: Structural (hierarchical pipeline)  
**Purpose**: Implements the main AES transformation pipeline with state and key registers

#### Entity Interface
```vhdl
port (
    clk, rst : in std_logic;
    state_en, key_en, final_rnd, init : in std_logic;
    plaintext, master_key : in std_logic_vector(127 downto 0);
    next_key : in std_logic_vector(127 downto 0);
    state_out, key_out : out std_logic_vector(127 downto 0)
);
```

#### Architecture

**State Register (sreg)**
```
Input Mux:
  sreg_in = (plaintext XOR master_key)  when init='1'
          = ark_out                      when init='0'
          
Control: Updates on rising_edge(clk) when state_en='1'
Output: sreg_out (connects to SubBytes input)
```

**Key Register (kreg)**
```
Input Mux:
  kreg_in = master_key   when init='1'
          = next_key     when init='0'
          
Control: Updates on rising_edge(clk) when key_en='1'
Output: kreg_out (connects to AddRoundKey)
```

**4-Stage Pipeline**
```
sreg_out (input) 
    ▼ [Stage 1]
SubBytes (combinational SBox substitution)
    ▼ sb_out
ShiftRows (combinational byte permutation)
    ▼ sr_out
MixColumns (4× parallel GF multiplications)
    ▼ mc_out
[Mux: bypass MixColumns if final_rnd='1']
    ▼ pre_ark
AddRoundKey (128-bit XOR with kreg_out)
    ▼ ark_out
[Feedback to state register or output as state_out]
```

#### Key Features
- **Fully Pipelined**: All stages are combinational (data flows every cycle)
- **Register Control**: Separate enables for state and key registers
- **Initial XOR**: Built-in plaintext XOR master_key via mux
- **MixColumns Bypass**: Final round skips MixColumns for efficiency
- **Registered I/O**: Synchronous register interfaces for timing closure

---

### 4. **sub_bytes.vhd** - S-Box Substitution Layer
**Type**: Combinational (parallel lookup)  
**Purpose**: Applies AES S-box (Rijndael S-box) to all 16 bytes in parallel

#### Entity Interface
```vhdl
port (
    data_in  : in  std_logic_vector(127 downto 0);
    data_out : out std_logic_vector(127 downto 0)
);
```

#### Architecture
- **16 Parallel Instances**: One Sbox component per byte
- **Byte Extraction**: `data_in((i+1)*8-1 downto i*8)` for byte i
- **Throughput**: 128 bits substituted per clock cycle (no latency)
- **LUT-Based**: Uses S-box component (see Sbox.vhd)

#### Mathematical Background
The S-box implements:
1. **Multiplicative Inverse** in GF(2^8): `x ← x^(-1)` (with special case for 0)
2. **Affine Transformation**: `y = Ax ⊕ b` where A is an 8×8 matrix, b=0x63

This provides non-linearity and diffusion against linear cryptanalysis.

#### Pipeline Position
```
State Input → SubBytes → ShiftRows → MixColumns → AddRoundKey → State Output
(combinational, runs every cycle)
```

---

### 5. **shift_rows.vhd** - Row-Wise Byte Shifting
**Type**: Combinational (wiring/permutation)  
**Purpose**: Provides diffusion by cyclically shifting bytes within each row of the AES state matrix

#### Entity Interface
```vhdl
port (
    input  : in  std_logic_vector(127 downto 0);
    output : out std_logic_vector(127 downto 0)
);
```

#### Architecture
The 128-bit state is viewed as a 4×4 byte matrix in column-major order:
```
Input bytes b0, b1, ..., b15 arranged as:
┌──────┬──────┬──────┬──────┐
│ b0   │ b4   │ b8   │ b12  │ (Column 0,1,2,3)
│ b1   │ b5   │ b9   │ b13  │
│ b2   │ b6   │ b10  │ b14  │
│ b3   │ b7   │ b11  │ b15  │
└──────┴──────┴──────┴──────┘

Row shifts:
Row 0: no shift (b0, b4, b8, b12) → (b0, b4, b8, b12)
Row 1: shift left 1 (b1, b5, b9, b13) → (b5, b9, b13, b1)
Row 2: shift left 2 (b2, b6, b10, b14) → (b10, b14, b2, b6)
Row 3: shift left 3 (b3, b7, b11, b15) → (b15, b3, b7, b11)
```

#### Implementation
- **Direct Wiring**: 16 concurrent signal assignments (100% combinational)
- **No Latency**: Runs every clock cycle with zero delay
- **Reversible**: ShiftRows has an inverse (used in AES decryption)

#### Pipeline Position
```
State Input → SubBytes → ShiftRows → MixColumns → AddRoundKey → State Output
(combinational, runs every cycle, zero delay)
```

---

### 6. **mix_columns.vhd** - Galois Field Polynomial Multiplication
**Type**: Combinational (polynomial arithmetic)  
**Purpose**: Provides strong diffusion via matrix multiplication in GF(2^8)

#### Entity Interface
```vhdl
port (
    in_word  : in  std_logic_vector(31 downto 0);  -- 4 bytes [b0, b1, b2, b3]
    out_word : out std_logic_vector(31 downto 0)   -- 4 output bytes
);
```

#### Galois Field Arithmetic

**xtime (Multiply by 2 in GF(2^8))**
```
xtime(b) = (b << 1) XOR 0x1B   if MSB(b)=1
         = (b << 1)             if MSB(b)=0
```
- Implements reduction polynomial: x^8 + x^4 + x^3 + x + 1

**Multiply by 3 in GF(2^8)**
```
×3(b) = xtime(b) XOR b  (equivalent to 2*b + b = 3*b)
```

#### MixColumns Matrix Multiplication
```
┌─────┐   ┌──────────────────────────┐   ┌─────┐
│ o0  │   │ 2  3  1  1 │   | b0      │   │ i0  │
│ o1  │ = │ 1  2  3  1 │ × │ b1      │ = │ i1  │
│ o2  │   │ 1  1  2  3 │   │ b2      │   │ i2  │
│ o3  │   │ 3  1  1  2 │   │ b3      │   │ i3  │
└─────┘   └──────────────────────────┘   └─────┘
GF(2^8)                 Matrix                State
```

Expanded equations:
```
o0 = 2*b0 ⊕ 3*b1 ⊕ b2 ⊕ b3
o1 = b0 ⊕ 2*b1 ⊕ 3*b2 ⊕ b3
o2 = b0 ⊕ b1 ⊕ 2*b2 ⊕ 3*b3
o3 = 3*b0 ⊕ b1 ⊕ b2 ⊕ 2*b3
```

#### Implementation Details
- **Word-Parallel**: Processes 4 bytes (one column) per instance
- **4× Instances**: Instantiated 4 times in datapath (one per column)
- **Combinational**: No latency, runs every cycle
- **Pipeline Bypassed**: In final round (controlled by `final_rnd` signal)

#### Pipeline Position
```
State Input → SubBytes → ShiftRows → MixColumns → AddRoundKey → State Output
(combinational, runs every cycle, zero delay, bypassed in final round)
```

---

### 7. **add_rndkey.vhd** - Round Key Addition
**Type**: Combinational (XOR operation)  
**Purpose**: Combines the current state with the round key via bitwise XOR

#### Entity Interface
```vhdl
port (
    in_word : in  std_logic_vector(127 downto 0);  -- State (4 words)
    key     : in  std_logic_vector(127 downto 0);  -- Round key (4 words)
    output  : out std_logic_vector(127 downto 0)   -- Output state
);
```

#### Architecture
```vhdl
output <= in_word XOR key;  -- Bitwise XOR of all 128 bits
```

#### Mathematical Significance
- **XOR Property**: `a XOR a = 0` (self-inverse)
- **Symmetric**: `d = c XOR k` implies `c = d XOR k` (decryption uses same operation)
- **Linear**: Only operation with key in forward cipher (all others key-independent)

#### Security Role
- Combines state with round key
- Only key-dependent operation in each round
- Complemented by non-linear SubBytes layer

#### Pipeline Position
```
State Input → SubBytes → ShiftRows → MixColumns → AddRoundKey → State Output
(combinational, runs every cycle, zero delay)
```

---

### 8. **key_schedule.vhd** - Round Key Generation
**Type**: Sequential (registered key expansion)  
**Purpose**: Generates all 11 round keys on-the-fly synchronized with datapath pipeline

#### Entity Interface
```vhdl
port (
    clk, rst : in std_logic;
    key_en : in std_logic;
    rnd_no : in std_logic_vector(3 downto 0);
    prev_key : in std_logic_vector(127 downto 0);
    next_key : out std_logic_vector(127 downto 0)
);
```

#### Key Schedule Algorithm

**Round Key Word Layout**
```
prev_key = [w0 | w1 | w2 | w3]  (MSB to LSB, 4 words of 32 bits each)
```

**Key Expansion (per round)**
```
1. RotWord(w3): Rotate w3 left by 1 byte
   [b0, b1, b2, b3] → [b1, b2, b3, b0]

2. SubWord(RotWord(w3)): Apply S-box to each byte

3. Rcon[round]: Round constant
   {0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80, 0x1B, 0x36}
   (powers of 2 in GF(2^8))

4. g-function: SubWord(RotWord(w3)) XOR Rcon[round]

5. Word XOR chain:
   nw0 = w0 XOR g_val
   nw1 = w1 XOR nw0
   nw2 = w2 XOR nw1
   nw3 = w3 XOR nw2

6. Output: next_key_reg = [nw0 | nw1 | nw2 | nw3]
```

#### Architecture

**Combinational Logic (per-cycle)**
```
w0-w3 ← prev_key (split into 4 words)
RotWord(w3) ← byte rotation
SubWord(...) ← apply S-box to rotated result
Rcon lookup ← table-based on rnd_no
g_val ← SubWord XOR Rcon
nw0-nw3 ← word XOR chain
```

**Sequential Register**
```
On rising_edge(clk) when key_en='1':
  w0_reg, w1_reg, w2_reg, w3_reg ← nw0, nw1, nw2, nw3
```

**Output**
```
next_key ← [w0_reg | w1_reg | w2_reg | w3_reg]
```

#### Rcon Table (10 values for rounds 1-10)
```
Round 1:  0x01000000
Round 2:  0x02000000
Round 3:  0x04000000
Round 4:  0x08000000
Round 5:  0x10000000
Round 6:  0x20000000
Round 7:  0x40000000
Round 8:  0x80000000
Round 9:  0x1B000000
Round 10: 0x36000000
```

#### Integration with Datapath
```
Cycle 0 (INIT):      prev_key = master_key, rnd_no = 0 (unused)
Cycle 1 (ROUND 1):   Expands round 1, key_en=1, outputs registered
Cycle 2 (ROUND 2):   Expands round 2
...
Cycle 10 (ROUND 10): Expands round 10
Output: next_key feeds back to datapath's kreg_in
```

---

### 9. **Sbox.vhd** - S-Box Lookup Table
**Type**: Combinational (read-only LUT)  
**Purpose**: Implements the AES Rijndael S-box as a 256-entry lookup table

#### Entity Interface
```vhdl
port (
    in_byte  : in  std_logic_vector(7 downto 0);   -- 8-bit input (0-255)
    out_byte : out std_logic_vector(7 downto 0)    -- 8-bit output
);
```

#### Architecture
```vhdl
constant SBOX : sbox_array(0 to 255) of std_logic_vector(7 downto 0) := (
    x"63", x"7C", x"77", x"7B", x"F2", x"6B", x"6F", x"C5",  -- 0x00-0x07
    x"30", x"01", x"67", x"2B", x"FE", x"D7", x"AB", x"76",  -- 0x08-0x0F
    ...
    x"41", x"99", x"2D", x"0F", x"B0", x"54", x"BB", x"16"   -- 0xF8-0xFF
);

out_byte <= SBOX(to_integer(unsigned(in_byte)));
```

#### S-Box Properties
- **Bijective**: One-to-one mapping (256 unique outputs for 256 inputs)
- **Non-linear**: Resistant to linear cryptanalysis
- **Algebraic**: Computed via GF(2^8) inverse + affine transformation
- **Avalanche**: Small input change → significant output change

#### Implementation
- **Synthesis**: Synthesizes to distributed RAM or LUTs in FPGAs
- **Latency**: Combinational (0 ns propagation delay)
- **Fanout**: Connected to 16 parallel instances in SubBytes

#### Lookup Table (first/last rows for reference)
```
Input  Output  | Input  Output  | Input  Output  | Input  Output
0x00   0x63    | 0x40   0x8F    | 0x80   0x70    | 0xC0   0xE0
0x01   0x7C    | 0x41   0x92    | 0x81   0x3E    | 0xC1   0x32
...             ...             ...             ...
0x0F   0x76    | 0x4F   0x2F    | 0x8F   0x88    | 0xCF   0x5E
```

---

### 10. **rnd_reg.vhd** - Pipeline Register (Currently Unused)
**Type**: Sequential (registered storage)  
**Purpose**: Generic pipeline register for potential future use in multi-stage pipeline optimization

#### Entity Interface
```vhdl
port (
    clk, rst : in std_logic;
    d : in std_logic_vector(127 downto 0);
    q : out std_logic_vector(127 downto 0)
);
```

#### Architecture
```vhdl
next_state <= d;

process(clk, rst)
begin
    if rst='1' then
        current_state <= (others => '0');
    elsif rising_edge(clk) then
        current_state <= next_state;
    end if;
end process;

q <= current_state;
```

#### Status
- **Currently Unused**: Not instantiated in device.vhd
- **Purpose**: Placeholder for potential pipeline register or testbench use
- **Note**: Datapath already has sreg and kreg; rnd_reg is redundant for current design

---

## Data Flow Example: One Complete Encryption

### Round Initialization (Cycle 0)
```
Controller: INIT → state_en='1', key_en='1', init='1'
Plaintext: 0x00112233445566778899aabbccddeeff
Master Key: 0x000102030405060708090a0b0c0d0e0f

State Register Input: plaintext XOR master_key = 0x00110011...
Key Register Input: master_key
→ Both latched at rising_edge(clk)
```

### Round 1 (Cycle 1)
```
Controller: ROUND (rnd_no=1) → state_en='1', key_en='1', final_rnd='0'
Datapath Input: state_out from prev cycle (XORed plaintext/key)

Pipeline:
  SubBytes(state) → sr_out
  ShiftRows(sr_out) → mc_in
  MixColumns(mc_in) → pre_ark
  AddRoundKey(pre_ark, key) → ark_out

Key Schedule (synchronized):
  prev_key = master_key
  rnd_no = 1
  → Expands to round 1 key, latched into key register
  
Next Cycle Input: ark_out (encrypted data) fed back to state register
```

### Rounds 2-9 (Cycles 2-9)
```
Repeat cycle 1, with rnd_no incrementing 2→9
All 4 pipeline stages active
Key schedule expands new round key each cycle
```

### Final Round (Cycle 10)
```
Controller: FINAL (rnd_no=9) → state_en='1', key_en='1', final_rnd='1'

Pipeline:
  SubBytes(state) → sr_out
  ShiftRows(sr_out) → mc_in
  MixColumns(mc_in) → [BYPASSED due to final_rnd='1']
  AddRoundKey(mc_in, key) → ark_out  (Note: uses mc_in directly, not mc_out)
  
No MixColumns in final round (optimization: reduces last-round latency)
```

### Completion (Cycle 11)
```
Controller: DONE_ST → done='1'
Output: state_out (ciphertext) available at port
```

---

## Timing & Performance

### Clock Frequency
- **Target**: 100+ MHz (10 ns typical clock period)
- **Path**: Longest path through 4-stage pipeline ≈ 8-9 ns
- **Margin**: ~1-2 ns for routing and register setup/hold

### Throughput
- **Per Encryption**: 11 cycles (1 init + 9 main + 1 final)
- **Latency**: 110 ns @ 100 MHz (init + 9 rounds + final = 11 cycles)
- **Throughput**: 1 encryption per 11 cycles (feasible for streaming)

### Resource Usage (Estimated)
| Resource | Count | Notes |
|----------|-------|-------|
| **LUTs** | 1200-1500 | S-box LUTs (256×8), logic |
| **Registers** | 400-500 | State/key registers, FSM |
| **Block RAM** | 0-2 | Optional S-box storage |
| **Multipliers** | 0 | No arithmetic multipliers needed |

---

## Synthesis & Implementation

### Design Constraints
- **Fully Synchronous**: All state changes on clock edges
- **Asynchronous Reset**: Active-high, resets all registers
- **No Asynch Signals**: All inputs synchronized to clock domain
- **Combinational Paths**: Pipeline stages are all combinational

### Simulation Models
All modules have been verified with comprehensive testbenches:
- **Device**: Full encryption verification with NIST vectors
- **Controller**: FSM state transitions and control signals
- **Datapath**: Register control and pipeline flow
- **Components**: Individual module functionality

### Synthesis Recommendations
1. **Optimize for Speed**: Pipelining already implemented
2. **Use Dedicated Carry**: Available in modern FPGAs (not needed here)
3. **S-box Storage**: Distributed RAM recommended (no block RAM needed)
4. **Registers**: Use fast local registers for state/key

---

## Known Limitations

1. **Single Pipeline**: Processes one encryption at a time
2. **No Pipelining Reuse**: Cannot start new encryption before previous completes
3. **11 Cycle Latency**: Minimum time for one block (11 clock cycles)
4. **No Streaming Mode**: Would require multiple pipelines or restructuring
5. **Fixed Key Schedule**: Cannot change master key between encryptions without reset

---

## Extensions & Improvements

### Possible Enhancements
1. **AES Decryption**: Implement inverse transformations (InvSubBytes, InvShiftRows, InvMixColumns)
2. **Key Sizes**: Extend to AES-192, AES-256 (requires different key schedule)
3. **Operating Modes**: ECB, CBC, CTR modes at system level
4. **Parallel Pipelines**: Multiple instances for higher throughput
5. **Partial Unrolling**: Combine 2-3 rounds per stage for higher clock speed

---

## References

- **FIPS 197**: Advanced Encryption Standard (AES) - NIST publication
- **Algorithm**: Rijndael cipher (Joan Daemen, Vincent Rijmen)
- **S-box**: Rijndael S-box (8×8 substitution table)
- **Galois Field**: GF(2^8) with irreducible polynomial x^8 + x^4 + x^3 + x + 1
