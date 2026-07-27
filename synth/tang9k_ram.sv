
module tang9k_ram #(
    parameter bit [31:0] ADDRESS,
    parameter bit [31:0] SIZE,
    parameter INIT_FILE_0_0 = "tang9k_mem_inits/c0.mem",
    parameter INIT_FILE_0_1 = "tang9k_mem_inits/c1.mem",
    parameter INIT_FILE_0_2 = "tang9k_mem_inits/c2.mem",
    parameter INIT_FILE_0_3 = "tang9k_mem_inits/c3.mem",
    parameter INIT_FILE_1_0 = "tang9k_mem_inits/c4.mem",
    parameter INIT_FILE_1_1 = "tang9k_mem_inits/c5.mem",
    parameter INIT_FILE_1_2 = "tang9k_mem_inits/c6.mem",
    parameter INIT_FILE_1_3 = "tang9k_mem_inits/c7.mem",
    parameter INIT_FILE_2_0 = "tang9k_mem_inits/c8.mem",
    parameter INIT_FILE_2_1 = "tang9k_mem_inits/c9.mem",
    parameter INIT_FILE_2_2 = "tang9k_mem_inits/c10.mem",
    parameter INIT_FILE_2_3 = "tang9k_mem_inits/c11.mem",
    parameter INIT_FILE_3_0 = "tang9k_mem_inits/c12.mem",
    parameter INIT_FILE_3_1 = "tang9k_mem_inits/c13.mem",
    parameter INIT_FILE_3_2 = "tang9k_mem_inits/c14.mem",
    parameter INIT_FILE_3_3 = "tang9k_mem_inits/c15.mem"
)(
    input logic clk,
    input logic rst,

    wishbone_interface.slave port_a,
    wishbone_interface.slave port_b
);

    logic [31:0] dout_a, dout_b;

/* -------------------------------------------------- */
 /* -------------------------------------------------- */
  /* -------------------------------------------------- */    
   /* -------------------------------------------------- */
                /* TANG NANO SRAM 32KiB */
/* -------------------------------------------------- */    
    tang9k_ram_32kib #(
        .INIT_FILE_0_0(INIT_FILE_0_0),
        .INIT_FILE_0_1(INIT_FILE_0_1),
        .INIT_FILE_0_2(INIT_FILE_0_2),
        .INIT_FILE_0_3(INIT_FILE_0_3),
        .INIT_FILE_1_0(INIT_FILE_1_0),
        .INIT_FILE_1_1(INIT_FILE_1_1),
        .INIT_FILE_1_2(INIT_FILE_1_2),
        .INIT_FILE_1_3(INIT_FILE_1_3),
        .INIT_FILE_2_0(INIT_FILE_2_0),
        .INIT_FILE_2_1(INIT_FILE_2_1),
        .INIT_FILE_2_2(INIT_FILE_2_2),
        .INIT_FILE_2_3(INIT_FILE_2_3),
        .INIT_FILE_3_0(INIT_FILE_3_0),
        .INIT_FILE_3_1(INIT_FILE_3_1),
        .INIT_FILE_3_2(INIT_FILE_3_2),
        .INIT_FILE_3_3(INIT_FILE_3_3)
    ) ram_32kib (
        .clk   (clk),
        .rst_n (~rst), /* ram employs active low reset*/

        .ce_a  (port_a.we),
        .oce_a (1'b1),
        .we_a  (port_a.sel),
        .addr_a(port_a.adr),
        .din_a (port_a.dat_mosi),
        .dout_a(dout_a),

        .ce_b  (port_b.we),
        .oce_b (1'b1),
        .we_b  (port_b.sel),
        .addr_b(port_b.adr),
        .din_b (port_b.dat_mosi),
        .dout_b(dout_b)
    );


  /* -------------------------------------------------- */    
   /* -------------------------------------------------- */
                        /* Port A */
/* -------------------------------------------------- */

    assign port_a.dat_miso = dout_a;

    always_ff @(posedge clk) begin
        if (rst) begin
            port_a.ack      <= 0;
            port_a.err      <= 0;
            // port_a.dat_miso <= 0;
        end
        else begin
            // default output
            port_a.ack      <= 0;
            port_a.err      <= 0;
            // port_a.dat_miso <= 0;
            // wishbone access
            if (port_a.cyc && port_a.stb) begin
                // check address space
                if (port_a.adr >= ADDRESS && port_a.adr < ADDRESS + SIZE) begin
                    port_a.ack <= 1;
                    port_a.err <= 0;
                end
                else begin
                    port_a.ack <= 0;
                    port_a.err <= 1;
                end
            end
        end
    end
    
    
    /* -------------------------------------------------- */    
   /* -------------------------------------------------- */
                        /* Port B */
/* -------------------------------------------------- */

    assign port_b.dat_miso = dout_b;

    always_ff @(posedge clk) begin
        if (rst) begin
            port_b.ack      <= 0;
            port_b.err      <= 0;
        end
        else begin
            // default output
            port_b.ack      <= 0;
            port_b.err      <= 0;
            // wishbone access
            if (port_b.cyc && port_b.stb) begin
                // check address space
                if (port_b.adr >= ADDRESS && port_b.adr < ADDRESS + SIZE) begin
                    port_b.ack <= 1;
                    port_b.err <= 0;
                end
                else begin
                    port_b.ack <= 0;
                    port_b.err <= 1;
                end
            end
        end
    end


endmodule
