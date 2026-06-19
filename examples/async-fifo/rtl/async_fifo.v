`timescale 1ns/1ps
`default_nettype none

module async_fifo #(
  parameter DATA_WIDTH = 8,
  parameter ADDR_WIDTH = 4
) (
  input  wire                  wr_clk,
  input  wire                  wr_rst,
  input  wire                  wr_en,
  input  wire [DATA_WIDTH-1:0] wr_data,
  output wire                  full,

  input  wire                  rd_clk,
  input  wire                  rd_rst,
  input  wire                  rd_en,
  output reg  [DATA_WIDTH-1:0] rd_data,
  output wire                  empty
);

  localparam PTR_WIDTH = ADDR_WIDTH + 1;
  localparam DEPTH = (1 << ADDR_WIDTH);

  reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

  reg [PTR_WIDTH-1:0] wr_bin;
  reg [PTR_WIDTH-1:0] wr_gray;
  reg [PTR_WIDTH-1:0] rd_bin;
  reg [PTR_WIDTH-1:0] rd_gray;
  reg full_reg;
  reg empty_reg;

  (* ASYNC_REG = "TRUE" *) reg [PTR_WIDTH-1:0] rd_gray_wr_sync_0;
  (* ASYNC_REG = "TRUE" *) reg [PTR_WIDTH-1:0] rd_gray_wr_sync_1;
  (* ASYNC_REG = "TRUE" *) reg [PTR_WIDTH-1:0] wr_gray_rd_sync_0;
  (* ASYNC_REG = "TRUE" *) reg [PTR_WIDTH-1:0] wr_gray_rd_sync_1;

  wire wr_do = wr_en && !full_reg;
  wire rd_do = rd_en && !empty_reg;

  wire [PTR_WIDTH-1:0] wr_bin_next = wr_bin + {{(PTR_WIDTH-1){1'b0}}, wr_do};
  wire [PTR_WIDTH-1:0] rd_bin_next = rd_bin + {{(PTR_WIDTH-1){1'b0}}, rd_do};
  wire [PTR_WIDTH-1:0] wr_gray_next = (wr_bin_next >> 1) ^ wr_bin_next;
  wire [PTR_WIDTH-1:0] rd_gray_next = (rd_bin_next >> 1) ^ rd_bin_next;

  wire full_next = (wr_gray_next == {
    ~rd_gray_wr_sync_1[PTR_WIDTH-1:PTR_WIDTH-2],
     rd_gray_wr_sync_1[PTR_WIDTH-3:0]
  });

  wire empty_next = (rd_gray_next == wr_gray_rd_sync_1);

  assign full = full_reg;
  assign empty = empty_reg;

  always @(posedge wr_clk) begin
    if (wr_rst) begin
      wr_bin  <= {PTR_WIDTH{1'b0}};
      wr_gray <= {PTR_WIDTH{1'b0}};
      full_reg <= 1'b0;
    end else begin
      if (wr_do) begin
        mem[wr_bin[ADDR_WIDTH-1:0]] <= wr_data;
      end
      wr_bin  <= wr_bin_next;
      wr_gray <= wr_gray_next;
      full_reg <= full_next;
    end
  end

  always @(posedge rd_clk) begin
    if (rd_rst) begin
      rd_bin  <= {PTR_WIDTH{1'b0}};
      rd_gray <= {PTR_WIDTH{1'b0}};
      rd_data <= {DATA_WIDTH{1'b0}};
      empty_reg <= 1'b1;
    end else begin
      if (rd_do) begin
        rd_data <= mem[rd_bin[ADDR_WIDTH-1:0]];
      end
      rd_bin  <= rd_bin_next;
      rd_gray <= rd_gray_next;
      empty_reg <= empty_next;
    end
  end

  always @(posedge wr_clk) begin
    if (wr_rst) begin
      rd_gray_wr_sync_0 <= {PTR_WIDTH{1'b0}};
      rd_gray_wr_sync_1 <= {PTR_WIDTH{1'b0}};
    end else begin
      rd_gray_wr_sync_0 <= rd_gray;
      rd_gray_wr_sync_1 <= rd_gray_wr_sync_0;
    end
  end

  always @(posedge rd_clk) begin
    if (rd_rst) begin
      wr_gray_rd_sync_0 <= {PTR_WIDTH{1'b0}};
      wr_gray_rd_sync_1 <= {PTR_WIDTH{1'b0}};
    end else begin
      wr_gray_rd_sync_0 <= wr_gray;
      wr_gray_rd_sync_1 <= wr_gray_rd_sync_0;
    end
  end

endmodule

`default_nettype wire
