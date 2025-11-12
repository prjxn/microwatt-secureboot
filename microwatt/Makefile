GHDL ?= ghdl
GHDLFLAGS=--std=08
CFLAGS=-O3 -Wall
# Need to investigate why yosys is hitting verilator warnings, and eventually turn on -Wall
VERILATOR_FLAGS=-O3 -Wno-fatal -Wno-CASEOVERLAP -Wno-UNOPTFLAT
VERILATOR_TRACE=0

ifeq ($(VERILATOR_TRACE),1)
VERILATOR_FLAGS += --trace
verilator_extra_link =  -Wl,obj_dir/verilated_vcd_c.o
endif

# It takes forever to build with optimisation, so disable by default
#VERILATOR_CFLAGS=-O3

# some yosys builds have ghdl plugin built in, otherwise need "-m ghdl"
GHDLSYNTH ?= $(shell ($(YOSYS) -H | grep -q ghdl) || echo -m ghdl)
YOSYS     ?= yosys
NEXTPNR   ?= nextpnr-ecp5
ECPPACK   ?= ecppack
ECPPROG   ?= ecpprog
OPENOCD   ?= openocd
VUNITRUN  ?= python3 ./run.py
VERILATOR ?= verilator
DFUUTIL   ?= dfu-util
DFUSUFFIX ?= dfu-suffix

# We need a version of GHDL built with either the LLVM or gcc backend.
# Fedora provides this, but other distros may not. Another option is to use
# the Docker image.
DOCKER ?= 0
PODMAN ?= 0

ifeq ($(DOCKER), 1)
DOCKERBIN=docker
USE_DOCKER=1
endif

ifeq ($(PODMAN), 1)
DOCKERBIN=podman
USE_DOCKER=1
endif

ifeq ($(USE_DOCKER), 1)
PWD = $(shell pwd)
DOCKERARGS = run --rm -v $(PWD):/src:z -w /src
GHDL      = $(DOCKERBIN) $(DOCKERARGS) ghdl/ghdl:buster-llvm-7 ghdl
CC        = $(DOCKERBIN) $(DOCKERARGS) ghdl/ghdl:buster-llvm-7 gcc
GHDLSYNTH = -m ghdl
YOSYS     = $(DOCKERBIN) $(DOCKERARGS) hdlc/ghdl:yosys yosys
NEXTPNR   = $(DOCKERBIN) $(DOCKERARGS) hdlc/nextpnr:ecp5 nextpnr-ecp5
ECPPACK   = $(DOCKERBIN) $(DOCKERARGS) hdlc/prjtrellis ecppack
OPENOCD   = $(DOCKERBIN) $(DOCKERARGS) --device /dev/bus/usb hdlc/prog openocd
VUNITRUN  = $(DOCKERBIN) $(DOCKERARGS) ghdl/vunit:llvm python3 ./run.py
VERILATOR = $(DOCKERBIN) $(DOCKERARGS) verilator/verilator:latest
endif

VUNITARGS += -p10

all = core_tb icache_tb dcache_tb dmi_dtm_tb \
	wishbone_bram_tb soc_reset_tb

all: $(all)

# This updates git.vhdl only when needed. Make runs this before doing
# dependancy checks hence make will only rebuild dependancies if the
# git status has actually changed.
$(shell scripts/make_version.sh git.vhdl)

core_files = decode_types.vhdl common.vhdl wishbone_types.vhdl fetch1.vhdl \
	utils.vhdl plrufn.vhdl cache_ram.vhdl icache.vhdl \
	predecode.vhdl decode1.vhdl helpers.vhdl insn_helpers.vhdl \
	control.vhdl decode2.vhdl register_file.vhdl \
	cr_file.vhdl crhelpers.vhdl ppc_fx_insns.vhdl rotator.vhdl \
	logical.vhdl countbits.vhdl multiply.vhdl multiply-32s.vhdl divider.vhdl \
	execute1.vhdl loadstore1.vhdl mmu.vhdl dcache.vhdl writeback.vhdl \
	core_debug.vhdl core.vhdl fpu.vhdl pmu.vhdl bitsort.vhdl

soc_files = wishbone_arbiter.vhdl wishbone_bram_wrapper.vhdl sync_fifo.vhdl \
	wishbone_debug_master.vhdl xics.vhdl syscon.vhdl gpio.vhdl soc.vhdl \
	spi_rxtx.vhdl spi_flash_ctrl.vhdl git.vhdl

uart_files = $(wildcard uart16550/*.v)

soc_sim_files = $(core_files) $(soc_files) sim_console.vhdl sim_pp_uart.vhdl sim_bram_helpers.vhdl \
	sim_bram.vhdl sim_jtag_socket.vhdl sim_jtag.vhdl dmi_dtm_xilinx.vhdl \
	sim_16550_uart.vhdl \
	foreign_random.vhdl glibc_random.vhdl glibc_random_helpers.vhdl

soc_sim_c_files = sim_vhpi_c.c sim_bram_helpers_c.c sim_console_c.c \
	sim_jtag_socket_c.c

soc_sim_obj_files=$(soc_sim_c_files:.c=.o)
comma := ,
soc_sim_link=$(patsubst %,-Wl$(comma)%,$(soc_sim_obj_files))

unisim_dir = sim-unisim
unisim_lib = $(unisim_dir)/unisim-obj08.cf
unisim_lib_files = $(unisim_dir)/BSCANE2.vhdl $(unisim_dir)/BUFG.vhdl \
	$(unisim_dir)/unisim_vcomponents.vhdl
$(unisim_lib): $(unisim_lib_files)
	$(GHDL) -i --std=08 --work=unisim --workdir=$(unisim_dir) $^
GHDLFLAGS += -P$(unisim_dir)

soc_tbs = core_tb icache_tb dcache_tb dmi_dtm_tb wishbone_bram_tb
soc_flash_tbs = core_flash_tb
soc_dram_tbs = dram_tb core_dram_tb

$(soc_flash_tbs): %: $(soc_sim_files) $(soc_sim_obj_files) $(unisim_lib) $(fmf_lib) $(flash_model_files) %.vhdl
	$(GHDL) -c $(GHDLFLAGS) $(soc_sim_link) $(soc_sim_files) $(flash_model_files) $@.vhdl $(unisim_files) -e $@

$(soc_tbs): %: $(soc_sim_files) $(soc_sim_obj_files) $(unisim_lib) %.vhdl
	$(GHDL) -c $(GHDLFLAGS) $(soc_sim_link) $(soc_sim_files) $@.vhdl -e $@

soc_reset_tb: fpga/soc_reset_tb.vhdl fpga/soc_reset.vhdl
	$(GHDL) -c $(GHDLFLAGS) fpga/soc_reset_tb.vhdl fpga/soc_reset.vhdl -e $@

_clean:
	rm -f *.o *.cf $(all)
	rm -f fpga/*.o fpga/*.cf
	rm -f sim-unisim/*.o sim-unisim/*.cf
	rm -f litedram/extras/*.o
	rm -f TAGS
	rm -f scripts/mw_debug/*.o
	rm -f scripts/mw_debug/mw_debug
	rm -f microwatt.bin microwatt.json microwatt.svf microwatt_out.config
	rm -f microwatt.v microwatt-verilator
	rm -f git.vhdl
	rm -rf obj_dir
	rm -rf vunit_out

clean: _clean
	make -f scripts/mw_debug/Makefile clean
	make -f hello_world/Makefile clean

distclean: _clean
	rm -f *~ fpga/*~ lib/*~ console/*~ include/*~
	rm -rf litedram/build
	rm -f litedram/extras/*~
	rm -f litedram/gen-src/*~
	rm -f litedram/gen-src/sdram_init/*~
	make -f scripts/mw_debug/Makefile distclean
	make -f hello_world/Makefile distclean

.PHONY: all prog check check_light clean distclean
.PRECIOUS: microwatt.json microwatt_out.config microwatt.bit
