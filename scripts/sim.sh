#!/bin/bash
set -euo pipefail

ROOTDIR=$(cd "$(dirname "$0")/.." && pwd)
WORKDIR="$ROOTDIR/work"
rm -f "$WORKDIR"/*.o "$WORKDIR"/*.cf "$ROOTDIR"/tb_top "$ROOTDIR"/topmodule "$ROOTDIR"/sim.log "$ROOTDIR"/sim.vcd
mkdir -p "$WORKDIR"

MICRO_DIR="$ROOTDIR/microwatt"
SHA_DIR="$ROOTDIR/sha256"
HW_DIR="$ROOTDIR/top"

(
    cd "$MICRO_DIR"
    ./scripts/make_version.sh git.vhdl
)


ghdl -i --workdir="$WORKDIR" --std=08 "$MICRO_DIR/sim-unisim"/BSCANE2.vhdl
ghdl -i --workdir="$WORKDIR" --std=08 "$MICRO_DIR/sim-unisim"/BUFG.vhdl
ghdl -i --workdir="$WORKDIR" --std=08 "$MICRO_DIR/sim-unisim"/unisim_vcomponents.vhdl

for file in decode_types.vhdl utils.vhdl common.vhdl wishbone_types.vhdl fetch1.vhdl \
            plrufn.vhdl cache_ram.vhdl insn_helpers.vhdl predecode.vhdl icache.vhdl helpers.vhdl \
            decode1.vhdl control.vhdl decode2.vhdl register_file.vhdl cr_file.vhdl crhelpers.vhdl \
            ppc_fx_insns.vhdl rotator.vhdl logical.vhdl countbits.vhdl multiply.vhdl multiply-32s.vhdl \
            divider.vhdl bitsort.vhdl pmu.vhdl loadstore1.vhdl mmu.vhdl dcache.vhdl writeback.vhdl \
            core_debug.vhdl fpu.vhdl glibc_random_helpers.vhdl glibc_random.vhdl foreign_random.vhdl \
            execute1.vhdl core.vhdl
do
    ghdl -a --workdir="$WORKDIR" --std=08 "$MICRO_DIR/$file"
done

SOC_FILES=( wishbone_arbiter.vhdl sim_bram_helpers.vhdl sim_bram.vhdl wishbone_bram_wrapper.vhdl \
            sync_fifo.vhdl wishbone_debug_master.vhdl xics.vhdl git.vhdl syscon.vhdl gpio.vhdl \
            spi_rxtx.vhdl spi_flash_ctrl.vhdl dmi_dtm_dummy.vhdl sim_console.vhdl sim_pp_uart.vhdl soc.vhdl )

for file in "${SOC_FILES[@]}"; do
    ghdl -a --workdir="$WORKDIR" --std=08 "$MICRO_DIR/$file"
done

ghdl -a --workdir="$WORKDIR" --std=08 "$SHA_DIR"/sha_256_pkg.vhdl
ghdl -a --workdir="$WORKDIR" --std=08 "$SHA_DIR"/sha_256_core.vhdl

for file in sha256_wb_wrapper.vhdl topmodule.vhdl tb_top.vhdl; do
    ghdl -a --workdir="$WORKDIR" --std=08 "$HW_DIR/$file"
done

ghdl -e --workdir="$WORKDIR" --std=08 tb_top
ghdl -r --workdir="$WORKDIR" --std=08 tb_top --vcd="$ROOTDIR/sim.vcd" | tee "$ROOTDIR/sim.log"


