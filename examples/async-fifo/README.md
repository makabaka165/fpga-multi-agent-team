# Async FIFO Example

这个示例用于展示 `fpga-multi-agent-team` skill 的完整闭环：需求拆解、异步 FIFO 架构、CDC-aware RTL、自检 testbench、XDC 约束、Vivado 仿真/综合/实现/CDC/时序检查，以及 Orchestrator 最终交付判断。

## 文件

```text
rtl/async_fifo.v                 # 参数化异步 FIFO
tb/tb_async_fifo.v               # 自检 testbench
constraints/async_fifo.xdc       # 两个异步时钟和 clock-group 约束
scripts/run_async_fifo_vivado.tcl # 可复现 Vivado batch flow
reports/                         # 已捕获的 Vivado 报告快照
```

## 设计假设

- `wr_clk` 和 `rd_clk` 是无关异步时钟。
- `DATA_WIDTH=8`，`ADDR_WIDTH=4` 时深度为 16。
- 每个时钟域使用同步、高有效 reset。
- binary pointer 留在本地时钟域，跨域只传 Gray pointer。
- 跨域 Gray pointer 使用两级同步器，并添加 `ASYNC_REG` 属性。
- `set_clock_groups -asynchronous` 只对该受保护 CDC 结构成立，不是通用 waiver。

## 已捕获结果

- XSim 行为仿真 PASS：`PASS: async FIFO self-check completed writes=177 reads=177`
- synthesis passed
- implementation passed
- post-route timing met declared constraints：WNS 6.391 ns，WHS 0.116 ns
- CDC report：18 个 recognized endpoints 全部 safe，0 unsafe，0 unknown，0 missing ASYNC_REG

完整摘要见 `reports/vivado-validation-summary.md`。

## 重新运行

从仓库根目录运行：

```powershell
vivado -mode batch -source examples/async-fifo/scripts/run_async_fifo_vivado.tcl -nojournal -log examples/async-fifo/build/vivado_batch.log
```

如果 `vivado` 不在 `PATH` 中：

```powershell
& 'E:\Xilinx\Vivado\2024.2\bin\vivado.bat' -mode batch -source examples/async-fifo/scripts/run_async_fifo_vivado.tcl -nojournal -log examples/async-fifo/build/vivado_batch.log
```

生成输出位于 `examples/async-fifo/build/`。仓库中的 `reports/` 是一次已捕获的报告快照，用于审阅，不会被脚本自动覆盖。

## 边界

这是 standalone IP-level demo，不是板级 signoff。没有提供真实板卡 pin、IOSTANDARD、configuration voltage 或外部 input/output delay，因此 DRC/methodology 中保留相关 warning 是预期行为。
