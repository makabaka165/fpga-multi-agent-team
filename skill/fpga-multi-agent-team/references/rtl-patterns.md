# RTL Patterns

Use this reference when generating common FPGA logic.

## Pattern Selection

- 1-bit async input to clock domain: 2FF synchronizer.
- Mechanical button: synchronize, debounce, then edge-detect.
- One-cycle event in same clock domain: edge detector.
- Slow periodic action: counter tick/clock enable, not fabric-generated clock.
- Streaming data: valid/ready with registered data and valid.
- Same-clock buffering: synchronous FIFO.
- Cross-clock stream: asynchronous FIFO.
- Cross-clock infrequent multi-bit command: request/ack handshake.
- Long combinational transform: pipeline stage(s).

## Counter Tick

```verilog
reg [CNT_WIDTH-1:0] cnt;
reg tick;

always @(posedge clk) begin
  if (rst) begin
    cnt  <= {CNT_WIDTH{1'b0}};
    tick <= 1'b0;
  end else if (cnt == TERMINAL_COUNT-1) begin
    cnt  <= {CNT_WIDTH{1'b0}};
    tick <= 1'b1;
  end else begin
    cnt  <= cnt + {{(CNT_WIDTH-1){1'b0}}, 1'b1};
    tick <= 1'b0;
  end
end
```

## Edge Detector

```verilog
reg sig_d;
always @(posedge clk) begin
  if (rst) sig_d <= 1'b0;
  else     sig_d <= sig;
end

assign rise_pulse = sig & ~sig_d;
assign fall_pulse = ~sig & sig_d;
```

## 2FF Synchronizer

```verilog
(* ASYNC_REG = "TRUE" *) reg sync_0;
(* ASYNC_REG = "TRUE" *) reg sync_1;

always @(posedge clk_dst) begin
  if (rst_dst) begin
    sync_0 <= 1'b0;
    sync_1 <= 1'b0;
  end else begin
    sync_0 <= async_in;
    sync_1 <= sync_0;
  end
end

assign sync_out = sync_1;
```

## Valid/Ready Register Slice

```verilog
assign s_ready = !m_valid || m_ready;

always @(posedge clk) begin
  if (rst) begin
    m_valid <= 1'b0;
    m_data  <= {WIDTH{1'b0}};
  end else if (s_ready) begin
    m_valid <= s_valid;
    m_data  <= s_data;
  end
end
```

## FSM Skeleton

```verilog
localparam ST_IDLE = 2'd0;
localparam ST_RUN  = 2'd1;
localparam ST_DONE = 2'd2;

reg [1:0] state;
reg [1:0] state_next;

always @* begin
  state_next = state;
  case (state)
    ST_IDLE: if (start) state_next = ST_RUN;
    ST_RUN:  if (last)  state_next = ST_DONE;
    ST_DONE:           state_next = ST_IDLE;
    default:           state_next = ST_IDLE;
  endcase
end

always @(posedge clk) begin
  if (rst) state <= ST_IDLE;
  else     state <= state_next;
end
```

## PWM

- Use a counter and compare register.
- Define period and duty in the same clock domain.
- Register `pwm_out`.
- Decide whether duty `0` means always low and duty `PERIOD` means always high.

## UART

- Use a baud tick clock enable, not a generated UART clock.
- RX should synchronize input first, sample near bit center, and validate stop bit.
- TX FSM states: idle, start, data bits, stop.
- Parameterize `CLK_FREQ_HZ` and `BAUD_RATE`.

## FIFO

- Sync FIFO: use extra pointer bit for full/empty or a count register.
- Async FIFO: use gray-coded pointers crossing domains; do not build casually without verification.
- Always define behavior for simultaneous read/write.
