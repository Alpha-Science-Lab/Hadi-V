/* File: cpu.sv*/

module cpu (
    input logic clk,
    input logic rst,

    wishbone_interface.master memory_fetch_port,
    wishbone_interface.master memory_mem_port,

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

        .wb(memory_fetch_port), /* Memory interface*/

        .instruction_reg_out(f_insto_insti_d), /* Output data*/
        .program_counter_reg_out(f_progco_progci_d),

        .status_forwards_out(f_statfo_statfi_d), /* Pipeline control*/
        .status_backwards_in(f_statbi_statbo_d),
        .jump_address_backwards_in(f_jaddri_jaddro_d)
    );


    decode_stage s_decode(
        .clk(clk),
        .rst(rst),

        .instruction_in(f_insto_insti_d), /* Inputs*/
        .program_counter_in(f_progco_progci_d),
        .exe_forwarding_in(d_exefi_fo_e),
        .mem_forwarding_in(d_memfi_fo_m),
        .wb_forwarding_in(d_wbfi_fo_w),

        .rs1_data_reg_out(d_rsoneo_rsonei_e), /* Output Registers*/
        .rs2_data_reg_out(d_rstwoo_rstwoi_e),
        .program_counter_reg_out(d_progco_progci_e),
        .instruction_reg_out(d_insto_insti_e),

        .status_forwards_in(f_statfo_statfi_d), /* Pipeline control*/
        .status_forwards_out(d_statfo_statfi_e),
        .status_backwards_in(d_statbi_statbo_e),
        .status_backwards_out(f_statbi_statbo_d),
        .jump_address_backwards_in(d_jaddri_jaddro_e),
        .jump_address_backwards_out(f_jaddri_jaddro_d)
    );


    execute_stage s_execute(
        .clk(clk),
        .rst(rst),

        .rs1_data_in(d_rsoneo_rsonei_e), /* Inputs*/
        .rs2_data_in(d_rstwoo_rstwoi_e),
        .instruction_in(d_insto_insti_e),
        .program_counter_in(d_progco_progci_e),

        .source_data_reg_out(e_srco_srci_m), /* Outputs*/
        .rd_data_reg_out(e_rdo_rdi_m),
        .instruction_reg_out(e_insto_insti_m),
        .program_counter_reg_out(e_progco_progci_m),
        .next_program_counter_reg_out(e_nxtprogco_nxtprogci_m),
        .forwarding_out(d_exefi_fo_e),

        .status_forwards_in(d_statfo_statfi_e), /* Pipeline control*/
        .status_forwards_out(e_statfo_statfi_m),
        .status_backwards_in(e_statbi_statbo_m),
        .status_backwards_out(d_statbi_statbo_e),
        .jump_address_backwards_in(e_jaddri_jaddro_m),
        .jump_address_backwards_out(d_jaddri_jaddro_e)
    );


    memory_stage s_memory(
        .clk(clk),
        .rst(rst),

        .wb(memory_mem_port), /* Memory interface*/

        .source_data_in(e_srco_srci_m), /* Inputs*/
        .rd_data_in(e_rdo_rdi_m),
        .instruction_in(e_insto_insti_m),
        .program_counter_in(e_progco_progci_m),
        .next_program_counter_in(e_nxtprogco_nxtprogci_m),

        .source_data_reg_out(m_srco_srci_w), /* Outputs*/
        .rd_data_reg_out(m_rdo_rdi_w),
        .instruction_reg_out(m_insto_insti_w),
        .program_counter_reg_out(m_progco_progci_w),
        .next_program_counter_reg_out(m_nxtprogco_nxtprogci_w),
        .forwarding_out(d_memfi_fo_m),

        .status_forwards_in(e_statfo_statfi_m), /* Pipeline control*/
        .status_forwards_out(m_statfo_statfi_w),
        .status_backwards_in(m_statbi_statbo_w),
        .status_backwards_out(e_statbi_statbo_m),
        .jump_address_backwards_in(m_jaddri_jaddro_w),
        .jump_address_backwards_out(e_jaddri_jaddro_m)
    );


    writeback_stage s_writeback(
        .clk(clk),
        .rst(rst),

        .source_data_in(m_srco_srci_w), /* Inputs*/
        .rd_data_in(m_rdo_rdi_w),
        .instruction_in(m_insto_insti_w),
        .program_counter_in(m_progco_progci_w),
        .next_program_counter_in(m_nxtprogco_nxtprogci_w),

        .external_interrupt_in(external_interrupt_in), /* Interrupt signals*/
        // .external_interrupt_in(1'b0),
        .timer_interrupt_in(timer_interrupt_in),
        // .timer_interrupt_in(1'b0),

        .forwarding_out(d_wbfi_fo_w), /* Outputs*/
        
        .status_forwards_in(m_statfo_statfi_w), /* Pipeline control*/
        .status_backwards_out(m_statbi_statbo_w),
        .jump_address_backwards_out(m_jaddri_jaddro_w)
    );


    // TODO: Delete the following line and implement this module.
    // ref_cpu golden(.*);

endmodule
