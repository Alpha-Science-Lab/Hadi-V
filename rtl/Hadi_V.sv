/* 
 * File: Hadi_V.sv
 * Alternate implementation for iverilog compatibility
 */

module Hadi_V (
    input logic clk,
    input logic rst,

    // memory_fetch_port (discrete master)
    output logic [31:0] fetch_adr,
    output logic [3:0]  fetch_sel,
    output logic [31:0] fetch_dat_mosi,
    input  logic [31:0] fetch_dat_miso,
    output logic        fetch_cyc,
    output logic        fetch_stb,
    output logic        fetch_we,
    input  logic        fetch_ack,
    input  logic        fetch_err,

    // memory_mem_port (discrete master)
    output logic [31:0] mem_adr,
    output logic [3:0]  mem_sel,
    output logic [31:0] mem_dat_mosi,
    input  logic [31:0] mem_dat_miso,
    output logic        mem_cyc,
    output logic        mem_stb,
    output logic        mem_we,
    input  logic        mem_ack,
    input  logic        mem_err,

    input logic external_interrupt_in,
    input logic timer_interrupt_in
);
    /* Internal wiring*/
    logic [31:0] f_insto_insti_d;
    logic [31:0] f_progco_progci_d;
    pipeline_status::forwards_t f_statfo_statfi_d;
    pipeline_status::backwards_t f_statbi_statbo_d;
    logic [31:0] f_jaddri_jaddro_d;
    forwarding::t d_wbfi_fo_w;
    forwarding::t d_memfi_fo_m;
    forwarding::t d_exefi_fo_e;
    instruction::t d_insto_insti_e;
    logic [31:0] d_progco_progci_e;
    logic [31:0] d_rsoneo_rsonei_e;
    logic [31:0] d_rstwoo_rstwoi_e;
    branch_pred_pkg::pred_t f_predo_predi_d;
    branch_pred_pkg::pred_t d_predo_predi_e;
    branch_pred_pkg::update_t f_updi_updo_e;
    pipeline_status::forwards_t d_statfo_statfi_e;
    pipeline_status::backwards_t d_statbi_statbo_e;
    logic [31:0] d_jaddri_jaddro_e;
    instruction::t e_insto_insti_m;
    logic [31:0] e_progco_progci_m;
    logic [31:0] e_nxtprogco_nxtprogci_m;
    logic [31:0] e_rdo_rdi_m;
    logic [31:0] e_srco_srci_m;
    pipeline_status::forwards_t e_statfo_statfi_m;
    pipeline_status::backwards_t e_statbi_statbo_m;
    logic [31:0] e_jaddri_jaddro_m;
    instruction::t m_insto_insti_w;
    logic [31:0] m_progco_progci_w;
    logic [31:0] m_nxtprogco_nxtprogci_w;
    logic [31:0] m_rdo_rdi_w;
    logic [31:0] m_srco_srci_w;
    pipeline_status::forwards_t m_statfo_statfi_w;
    pipeline_status::backwards_t m_statbi_statbo_w;
    logic [31:0] m_jaddri_jaddro_w;

    /* Pipeline stages*/

    fetch_stage s_fetch(
        .clk(clk),
        .rst(rst),

        .wb_adr(fetch_adr),
        .wb_sel(fetch_sel),
        .wb_dat_mosi(fetch_dat_mosi),
        .wb_dat_miso(fetch_dat_miso),
        .wb_cyc(fetch_cyc),
        .wb_stb(fetch_stb),
        .wb_we(fetch_we),
        .wb_ack(fetch_ack),
        .wb_err(fetch_err),

        .instruction_reg_out(f_insto_insti_d),
        .program_counter_reg_out(f_progco_progci_d),

        .status_forwards_out(f_statfo_statfi_d),
        .status_backwards_in(f_statbi_statbo_d),
        .jump_address_backwards_in(f_jaddri_jaddro_d),

        .branch_pred_update_in(f_updi_updo_e),
        .branch_pred_out(f_predo_predi_d)
    );

    decode_stage s_decode(
        .clk(clk),
        .rst(rst),

        .instruction_in(f_insto_insti_d),
        .program_counter_in(f_progco_progci_d),
        .exe_forwarding_in(d_exefi_fo_e),
        .mem_forwarding_in(d_memfi_fo_m),
        .wb_forwarding_in(d_wbfi_fo_w),

        .rs1_data_reg_out(d_rsoneo_rsonei_e),
        .rs2_data_reg_out(d_rstwoo_rstwoi_e),
        .program_counter_reg_out(d_progco_progci_e),
        .instruction_reg_out(d_insto_insti_e),

        .branch_pred_in(f_predo_predi_d),
        .branch_pred_out(d_predo_predi_e),

        .status_forwards_in(f_statfo_statfi_d),
        .status_forwards_out(d_statfo_statfi_e),
        .status_backwards_in(d_statbi_statbo_e),
        .status_backwards_out(f_statbi_statbo_d),
        .jump_address_backwards_in(d_jaddri_jaddro_e),
        .jump_address_backwards_out(f_jaddri_jaddro_d)
    );

    execute_stage s_execute(
        .clk(clk),
        .rst(rst),

        .rs1_data_in(d_rsoneo_rsonei_e),
        .rs2_data_in(d_rstwoo_rstwoi_e),
        .instruction_in(d_insto_insti_e),
        .program_counter_in(d_progco_progci_e),

        .source_data_reg_out(e_srco_srci_m),
        .rd_data_reg_out(e_rdo_rdi_m),
        .instruction_reg_out(e_insto_insti_m),
        .program_counter_reg_out(e_progco_progci_m),
        .next_program_counter_reg_out(e_nxtprogco_nxtprogci_m),
        .forwarding_out(d_exefi_fo_e),

        .branch_pred_in(d_predo_predi_e),
        .branch_pred_update_out(f_updi_updo_e),

        .status_forwards_in(d_statfo_statfi_e),
        .status_forwards_out(e_statfo_statfi_m),
        .status_backwards_in(e_statbi_statbo_m),
        .status_backwards_out(d_statbi_statbo_e),
        .jump_address_backwards_in(e_jaddri_jaddro_m),
        .jump_address_backwards_out(d_jaddri_jaddro_e)
    );

    memory_stage s_memory(
        .clk(clk),
        .rst(rst),

        .wb_adr(mem_adr),
        .wb_sel(mem_sel),
        .wb_dat_mosi(mem_dat_mosi),
        .wb_dat_miso(mem_dat_miso),
        .wb_cyc(mem_cyc),
        .wb_stb(mem_stb),
        .wb_we(mem_we),
        .wb_ack(mem_ack),
        .wb_err(mem_err),

        .source_data_in(e_srco_srci_m),
        .rd_data_in(e_rdo_rdi_m),
        .instruction_in(e_insto_insti_m),
        .program_counter_in(e_progco_progci_m),
        .next_program_counter_in(e_nxtprogco_nxtprogci_m),

        .source_data_reg_out(m_srco_srci_w),
        .rd_data_reg_out(m_rdo_rdi_w),
        .instruction_reg_out(m_insto_insti_w),
        .program_counter_reg_out(m_progco_progci_w),
        .next_program_counter_reg_out(m_nxtprogco_nxtprogci_w),
        .forwarding_out(d_memfi_fo_m),

        .status_forwards_in(e_statfo_statfi_m),
        .status_forwards_out(m_statfo_statfi_w),
        .status_backwards_in(m_statbi_statbo_w),
        .status_backwards_out(e_statbi_statbo_m),
        .jump_address_backwards_in(m_jaddri_jaddro_w),
        .jump_address_backwards_out(e_jaddri_jaddro_m)
    );

    writeback_stage s_writeback(
        .clk(clk),
        .rst(rst),

        .source_data_in(m_srco_srci_w),
        .rd_data_in(m_rdo_rdi_w),
        .instruction_in(m_insto_insti_w),
        .program_counter_in(m_progco_progci_w),
        .next_program_counter_in(m_nxtprogco_nxtprogci_w),

        .external_interrupt_in(external_interrupt_in),
        .timer_interrupt_in(timer_interrupt_in),

        .forwarding_out(d_wbfi_fo_w),
        
        .status_forwards_in(m_statfo_statfi_w),
        .status_backwards_out(m_statbi_statbo_w),
        .jump_address_backwards_out(m_jaddri_jaddro_w)
    );

endmodule
