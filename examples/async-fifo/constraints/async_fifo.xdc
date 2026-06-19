create_clock -name wr_clk -period 10.000 [get_ports wr_clk]
create_clock -name rd_clk -period 14.000 [get_ports rd_clk]

# The clocks are asynchronous only when all functional crossings use the
# gray-pointer synchronizers in async_fifo.v. Do not use this exception if
# integration adds unprotected paths between wr_clk and rd_clk domains.
set_clock_groups -asynchronous \
  -group [get_clocks wr_clk] \
  -group [get_clocks rd_clk]
