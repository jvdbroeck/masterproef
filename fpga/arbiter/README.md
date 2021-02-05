# FPGA implementation

## component
* `arbiter.vhd`
* > `user_logic.vhd`
* >> `sram_controller.vhd`
* >> `sampler_fifo.vhd`
* >> `arbiter_fifo.vhd`
* >> `Sampler.vhd`

## testing
* `sram_tester.vhd`
* > `tristatebuffer.vhd`
* > `mt55l256l32p.vhd`
* > `sram_controller.vhd`

Test with ModelSim 10.0 using file `sram_controller_do.do`

