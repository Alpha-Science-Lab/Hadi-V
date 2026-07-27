
module tang9k_bram8_tdp #(
    parameter DEPTH = 2048,
    parameter INIT_FILE = ""
)(
    input  wire        clk,
    input  wire        rst_n,

    // Port A
    input  wire        ce_a,
    input  wire        oce_a,
    input  wire        we_a,
    input  wire [10:0] addr_a,
    input  wire [7:0]  din_a,
    output wire [7:0]  dout_a,

    // Port B
    input  wire        ce_b,
    input  wire        oce_b,
    input  wire        we_b,
    input  wire [10:0] addr_b,
    input  wire [7:0]  din_b,
    output wire [7:0]  dout_b
);

    // Ask the synthesizer to use block RAM
    (* ram_style = "block" *)
    reg [7:0] mem [0:DEPTH-1];
    reg [7:0] dout_ar, dout_br;

    initial begin
        if (INIT_FILE != "")
            $readmemh(INIT_FILE, mem);
    end

    // ----------------------------------------------------------
    // Port A
    // ----------------------------------------------------------
    always @(posedge clk) begin
        if(~rst_n) begin
            dout_ar <= 8'b0;
        end else begin
            if (ce_a & oce_a & !we_a) begin
                dout_ar <= mem[addr_a];
            end
        end
    end

    always @(posedge clk) begin
        if(ce_a & we_a) begin
            mem[addr_a] <= din_a;
        end
    end

    assign dout_a = dout_ar;

    // ----------------------------------------------------------
    // Port B
    // ----------------------------------------------------------
    always @(posedge clk) begin
        if(~rst_n) begin
            dout_br <= 8'b0;
        end else begin
            if (ce_b & oce_b & !we_b) begin
                dout_br <= mem[addr_b];
            end
        end
    end

    always @(posedge clk) begin
        if(ce_b & we_b) begin
            mem[addr_b] <= din_b;
        end
    end

    assign dout_b = dout_br;

endmodule
