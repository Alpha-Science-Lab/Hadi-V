
module tang9k_ram #(
    parameter bit [31:0] ADDRESS, // start address
    parameter bit [31:0] SIZE, // size in bytes
    parameter string INIT_FILE_B0 = "init0.mem",
    parameter string INIT_FILE_B1 = "init1.mem",
    parameter string INIT_FILE_B2 = "init2.mem",
    parameter string INIT_FILE_B3 = "init3.mem"
)(
    input logic clk,
    input logic rst,

    wishbone_interface.slave port_a,
    wishbone_interface.slave port_b
);
    localparam int DEPTH = SIZE / 4;
    localparam int ADDR_W = $clog2(DEPTH);

    logic [31:0] dout_a, dout_b;
    logic [ADDR_W-1:0] addr_a, addr_b;

    assign addr_a = port_a.adr - ADDRESS;
    assign addr_b = port_b.adr - ADDRESS;

    always_ff @(posedge clk) begin
        if (rst) begin
            port_a.ack <= 0;
            port_a.err <= 0;
        end
        else begin
            // default output
            port_a.ack <= 0;
            port_a.err <= 0;
            // wishbone access
            if (port_a.cyc && port_a.stb) begin
                // check address space
                if (port_a.adr >= ADDRESS && port_a.adr < ADDRESS + SIZE) begin
                    port_a.ack <= 1;
                    port_a.err <= 0;
                end else begin
                    port_a.ack <= 0;
                    port_a.err <= 1;
                end
            end
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            port_b.ack <= 0;
            port_b.err <= 0;
        end
        else begin
            // default output
            port_b.ack <= 0;
            port_b.err <= 0;
            // wishbone access
            if (port_b.cyc && port_b.stb) begin
                // check address space
                if (port_b.adr >= ADDRESS && port_b.adr < ADDRESS + SIZE) begin
                    port_b.ack <= 1;
                    port_b.err <= 0;
                end else begin
                    port_b.ack <= 0;
                    port_b.err <= 1;
                end
            end
        end
    end

    assign port_a.dat_miso = dout_a;
    assign port_b.dat_miso = dout_b;

    // ----------------------------------------------------------
    // Memory Banks (4 × 8-bit = 32-bit)
    // ----------------------------------------------------------

    genvar i;
    generate
        for (i = 0; i < 4; i++) begin : g_banks
            tang9k_bram8_tdp #(
                .DEPTH(DEPTH),
                .INIT_FILE(
                    (i == 0) ? INIT_FILE_B0 :
                    (i == 1) ? INIT_FILE_B1 :
                    (i == 2) ? INIT_FILE_B2 :
                            INIT_FILE_B3
                )
            ) bank (
                .clk(clk),
                .rst(rst),

                // Port A
                .en_a  (port_a.cyc && port_a.stb),
                .we_a  (port_a.cyc && port_a.stb && port_a.we && port_a.sel[i]),
                .addr_a(addr_a),
                .din_a (port_a.dat_mosi[i*8 +: 8]),
                .dout_a(dout_a[i*8 +: 8]),

                // Port B
                .en_b  (port_b.cyc && port_b.stb),
                .we_b  (port_b.cyc && port_b.stb && port_b.we && port_b.sel[i]),
                .addr_b(addr_b),
                .din_b (port_b.dat_mosi[i*8 +: 8]),
                .dout_b(dout_b[i*8 +: 8])
            );
        end
    endgenerate

endmodule
