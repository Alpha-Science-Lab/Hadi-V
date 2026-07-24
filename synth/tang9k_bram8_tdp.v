
module tang9k_bram8_tdp #(
    parameter integer DEPTH = 2048,
    parameter string INIT_FILE = ""
)(
    input  wire        clk,
    input  wire        rst,

    // Port A
    input  wire        en_a,
    input  wire        we_a,
    input  wire [10:0] addr_a,
    input  wire [7:0]  din_a,
    output reg  [7:0]  dout_a,

    // Port B
    input  wire        en_b,
    input  wire        we_b,
    input  wire [10:0] addr_b,
    input  wire [7:0]  din_b,
    output reg  [7:0]  dout_b
);

    // Ask the synthesizer to use block RAM
    (* ram_style = "block" *)
    reg [7:0] mem [0:DEPTH-1];

    initial begin
        if (INIT_FILE != "")
            $readmemh(INIT_FILE, mem);
    end

    // ----------------------------------------------------------
    // Port A
    // ----------------------------------------------------------
    always_ff @(posedge clk) begin
        if(rst) begin
            dout_a <= 8'b0;
        end else if (en_a) begin
            if (we_a)
                mem[addr_a] <= din_a;
            
            dout_a <= mem[addr_a];
        end
    end

    // ----------------------------------------------------------
    // Port B
    // ----------------------------------------------------------
    always_ff @(posedge clk) begin
        if(rst) begin
            dout_b <= 8'b0;
        end else if (en_b) begin
            if (we_b)
                mem[addr_b] <= din_b;

            dout_b <= mem[addr_b];
        end
    end

endmodule
