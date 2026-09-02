/* 
* File: csr_file.sv
* Alternate implementation for iverilog compatibility
*/

module csr_file (

    input  logic clk,
    input  logic rst,

    // CSR access
    input  logic        csr_write_en,
    input  csr_pkg::t   csr_addr,
    input  logic [31:0] csr_write_data,
    output logic [31:0] csr_read_data,

    // Performance
    input  logic instruction_retired,

    // Interrupts
    input  logic external_interrupt,
    input  logic timer_interrupt,

    // Trap interface
    input  logic        trap_taken,
    input  logic [31:0] trap_pc,
    input  logic [31:0] trap_cause,

    // Return
    input  logic mret,

    // Outputs
    output logic [31:0] mtvec_out,
    output logic [31:0] mepc_out,
    output logic [31:0] mstatus_out,
    output logic [31:0] mie_out,
    output logic [31:0] mip_out
);
    import csr_pkg::*;

    bit [31:0] mstatus, mie, mip;
    bit [31:0] mtvec, mepc, mcause, mscratch;

    bit [63:0] mcycle, minstret;
    bit [63:0] mcycle_next, minstret_next;

    logic mie_eff, meie_eff, mtie_eff;
    bit trap_history;

    assign mstatus_out  = mstatus;
    assign mie_out      = mie;
    assign mip_out      = mip;
    assign mtvec_out    = mtvec;
    assign mepc_out     = mepc;

    always_ff @(posedge clk) begin
        if (rst) begin
            mip <= '0;
        end else begin
            mip[11] <= external_interrupt;
            mip[7]  <= timer_interrupt;
        end
    end

    always_comb begin
        mcycle_next   = mcycle + 1;
        minstret_next = minstret;

        if (instruction_retired)
            minstret_next = minstret + 1;

        if (csr_write_en) begin
            case (csr_addr)

                csr_pkg::MCYCLE: begin
                    mcycle_next[31:0] = csr_write_data;
                end

                csr_pkg::MCYCLEH:
                    mcycle_next[63:32] = csr_write_data;

                csr_pkg::MINSTRET: begin
                    minstret_next[31:0] = csr_write_data;
                end

                csr_pkg::MINSTRETH:
                    minstret_next[63:32] = csr_write_data;

                default: ;
            endcase
        end
    end

    always_comb begin
        meie_eff = mie[11];
        mtie_eff = mie[7];
        mie_eff = mstatus[3];

        if (csr_write_en && csr_addr == csr_pkg::MSTATUS) begin
            mie_eff = csr_write_data[3];
        end
        else if (csr_write_en && csr_addr == csr_pkg::MIE) begin
            meie_eff = csr_write_data[11];
            mtie_eff = csr_write_data[7];
        end
        else if (mret) begin
            mie_eff = mstatus[7];
        end

        if (trap_history && trap_taken) begin
            mie_eff = mstatus[7];
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin

            trap_history <= 0;

            mstatus  <= '0;
            mie      <= '0;
            mtvec    <= '0;
            mepc     <= '0;
            mcause   <= '0;
            mscratch <= '0;

            mcycle   <= '0;
            minstret <= '0;

        end else begin

            mcycle   <= mcycle_next;
            minstret <= minstret_next;

            if (trap_taken) begin

                if (!mret) mepc <= {trap_pc[31:2], 2'b00};
                
                mcause <= trap_cause;

                mstatus[7] <= mie_eff;
                mstatus[3] <= 1'b0;

                mie[11] <= meie_eff;
                mie[7] <= mtie_eff;

                trap_history <= 1'b1;

            end

            else if (mret) begin
                mstatus[3] <= mstatus[7];
                mstatus[7] <= 1'b1;

                trap_history <= 1'b0;
            end

            else if (csr_write_en) begin
                case (csr_addr)

                    csr_pkg::MSTATUS:
                        mstatus <= csr_write_data & 32'h00000088;

                    csr_pkg::MIE:
                        mie <= csr_write_data & 32'h00000880;

                    csr_pkg::MTVEC:
                        mtvec <= {csr_write_data[31:2], 2'b00};

                    csr_pkg::MEPC:
                        mepc <= {csr_write_data[31:2], 2'b00};

                    csr_pkg::MCAUSE:
                        mcause <= csr_write_data;

                    csr_pkg::MSCRATCH:
                        mscratch <= csr_write_data;

                    default: ;
                endcase
            end
        end
    end

    always_comb begin
        csr_read_data = 32'd0;

        case (csr_addr)
            csr_pkg::MSTATUS  : csr_read_data = mstatus;
            csr_pkg::MIE      : csr_read_data = mie;
            csr_pkg::MIP      : csr_read_data = mip;
            csr_pkg::MTVEC    : csr_read_data = mtvec;
            csr_pkg::MEPC     : csr_read_data = mepc;
            csr_pkg::MCAUSE   : csr_read_data = mcause;
            csr_pkg::MSCRATCH : csr_read_data = mscratch;

            csr_pkg::MCYCLE   : csr_read_data = mcycle[31:0];
            csr_pkg::MCYCLEH  : csr_read_data = mcycle[63:32];
            csr_pkg::MINSTRET : csr_read_data = minstret[31:0];
            csr_pkg::MINSTRETH: csr_read_data = minstret[63:32];

            default: ;
        endcase
    end

endmodule
