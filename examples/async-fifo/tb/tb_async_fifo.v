`timescale 1ns/1ps
`default_nettype none

module tb_async_fifo;
  localparam DATA_WIDTH = 8;
  localparam ADDR_WIDTH = 4;
  localparam DEPTH = (1 << ADDR_WIDTH);

  reg wr_clk = 1'b0;
  reg rd_clk = 1'b0;
  reg wr_rst = 1'b1;
  reg rd_rst = 1'b1;
  reg wr_en = 1'b0;
  reg [DATA_WIDTH-1:0] wr_data = {DATA_WIDTH{1'b0}};
  wire full;
  reg rd_en = 1'b0;
  wire [DATA_WIDTH-1:0] rd_data;
  wire empty;

  reg [DATA_WIDTH-1:0] expected [0:4095];
  integer exp_wr;
  integer exp_rd;
  integer errors;
  integer accepted_writes;
  integer accepted_reads;
  integer i;
  integer wr_seed;
  integer rd_seed;
  integer target_reads;

  async_fifo #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH)
  ) dut (
    .wr_clk(wr_clk),
    .wr_rst(wr_rst),
    .wr_en(wr_en),
    .wr_data(wr_data),
    .full(full),
    .rd_clk(rd_clk),
    .rd_rst(rd_rst),
    .rd_en(rd_en),
    .rd_data(rd_data),
    .empty(empty)
  );

  always #5 wr_clk = ~wr_clk;
  initial begin
    #3;
    forever #7 rd_clk = ~rd_clk;
  end

  initial begin
    repeat (4) @(posedge wr_clk);
    @(negedge wr_clk);
    wr_rst = 1'b0;
  end

  initial begin
    repeat (5) @(posedge rd_clk);
    @(negedge rd_clk);
    rd_rst = 1'b0;
  end

  initial begin
    exp_wr = 0;
    exp_rd = 0;
    errors = 0;
    accepted_writes = 0;
    accepted_reads = 0;
    wr_seed = 32'h1234abcd;
    rd_seed = 32'h5678dcba;
    target_reads = 0;
    repeat (5000) @(posedge wr_clk);
    $display("FAIL: timeout");
    $finish;
  end

  task push_byte;
    input [DATA_WIDTH-1:0] data;
    begin
      @(negedge wr_clk);
      while (full) begin
        wr_en <= 1'b0;
        @(negedge wr_clk);
      end
      wr_data <= data;
      wr_en <= 1'b1;
      expected[exp_wr] = data;
      exp_wr = exp_wr + 1;
      accepted_writes = accepted_writes + 1;
      @(posedge wr_clk);
      @(negedge wr_clk);
      wr_en <= 1'b0;
    end
  endtask

  task pop_byte;
    reg [DATA_WIDTH-1:0] exp_data;
    begin
      @(negedge rd_clk);
      while (empty) begin
        rd_en <= 1'b0;
        @(negedge rd_clk);
      end
      exp_data = expected[exp_rd];
      rd_en <= 1'b1;
      @(posedge rd_clk);
      #1;
      if (rd_data !== exp_data) begin
        $display("FAIL: read mismatch index=%0d expected=%02x actual=%02x", exp_rd, exp_data, rd_data);
        errors = errors + 1;
      end
      @(negedge rd_clk);
      rd_en <= 1'b0;
      exp_rd = exp_rd + 1;
      accepted_reads = accepted_reads + 1;
    end
  endtask

  task check_read_while_empty;
    integer k;
    integer reads_before;
    reg [DATA_WIDTH-1:0] held_data;
    begin
      @(negedge rd_clk);
      while (!empty) begin
        @(negedge rd_clk);
      end

      reads_before = accepted_reads;
      held_data = rd_data;

      for (k = 0; k < 4; k = k + 1) begin
        rd_en <= 1'b1;
        @(posedge rd_clk);
        #1;
        if (!empty) begin
          $display("FAIL: empty deasserted during read-while-empty cycle=%0d", k);
          errors = errors + 1;
        end
        if (rd_data !== held_data) begin
          $display("FAIL: rd_data changed during read-while-empty cycle=%0d expected=%02x actual=%02x",
                   k, held_data, rd_data);
          errors = errors + 1;
        end
      end

      @(negedge rd_clk);
      rd_en <= 1'b0;
      if (accepted_reads != reads_before) begin
        $display("FAIL: scoreboard changed during read-while-empty before=%0d after=%0d",
                 reads_before, accepted_reads);
        errors = errors + 1;
      end
    end
  endtask

  initial begin
    @(negedge wr_rst);
    @(negedge rd_rst);

    if (!empty || full) begin
      $display("FAIL: reset state empty=%b full=%b", empty, full);
      errors = errors + 1;
    end

    push_byte(8'h11);
    pop_byte();

    for (i = 0; i < DEPTH; i = i + 1) begin
      push_byte(i[DATA_WIDTH-1:0]);
    end

    repeat (2) @(posedge wr_clk);
    if (!full) begin
      $display("FAIL: full did not assert after fill attempt");
      errors = errors + 1;
    end

    for (i = 0; i < 4; i = i + 1) begin
      @(negedge wr_clk);
      wr_data <= (8'hf0 + i[DATA_WIDTH-1:0]);
      wr_en <= 1'b1;
    end
    @(negedge wr_clk);
    wr_en <= 1'b0;

    while (exp_rd < exp_wr) begin
      pop_byte();
    end

    repeat (4) @(posedge rd_clk);
    if (!empty) begin
      $display("FAIL: empty did not assert after drain");
      errors = errors + 1;
    end

    check_read_while_empty();

    fork
      begin
        for (i = 0; i < 64; i = i + 1) begin
          push_byte((8'h80 + i[7:0]));
        end
      end
      begin
        repeat (12) @(posedge rd_clk);
        while (accepted_reads < accepted_writes || exp_rd < 65) begin
          if (!empty) begin
            pop_byte();
          end else begin
            @(posedge rd_clk);
          end
        end
      end
    join

    target_reads = accepted_writes + 96;
    fork
      begin
        for (i = 0; i < 96; i = i + 1) begin
          repeat (($random(wr_seed) & 3)) @(posedge wr_clk);
          push_byte((8'h40 + i[DATA_WIDTH-1:0]));
        end
      end
      begin
        while (accepted_reads < target_reads) begin
          repeat (($random(rd_seed) & 3)) @(posedge rd_clk);
          if (!empty) begin
            pop_byte();
          end else begin
            @(posedge rd_clk);
          end
        end
      end
    join

    repeat (8) @(posedge rd_clk);

    if (errors == 0 && exp_rd == exp_wr) begin
      $display("PASS: async FIFO self-check completed writes=%0d reads=%0d", accepted_writes, accepted_reads);
    end else begin
      $display("FAIL: errors=%0d expected_queue=%0d", errors, exp_wr - exp_rd);
    end
    $finish;
  end

endmodule

`default_nettype wire
