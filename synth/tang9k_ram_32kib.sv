
module tang9k_ram_32kib #(
    parameter INIT_FILE_0_0 = "",
    parameter INIT_FILE_0_1 = "",
    parameter INIT_FILE_0_2 = "",
    parameter INIT_FILE_0_3 = "",
    parameter INIT_FILE_1_0 = "",
    parameter INIT_FILE_1_1 = "",
    parameter INIT_FILE_1_2 = "",
    parameter INIT_FILE_1_3 = "",
    parameter INIT_FILE_2_0 = "",
    parameter INIT_FILE_2_1 = "",
    parameter INIT_FILE_2_2 = "",
    parameter INIT_FILE_2_3 = "",
    parameter INIT_FILE_3_0 = "",
    parameter INIT_FILE_3_1 = "",
    parameter INIT_FILE_3_2 = "",
    parameter INIT_FILE_3_3 = ""
)(
    input  wire         clk,
    input  wire         rst_n,

    // Port A
    input  wire         ce_a,
    input  wire         oce_a,
    input  wire [3:0]   we_a,       // byte enable
    input  wire [12:0]  addr_a,     // word address
    input  wire [31:0]  din_a,
    output wire [31:0]  dout_a,

    // Port B
    input  wire         ce_b,
    input  wire         oce_b,
    input  wire [3:0]   we_b,
    input  wire [12:0]  addr_b,
    input  wire [31:0]  din_b,
    output wire [31:0]  dout_b
);

    //---------------------------------------------------------
    // Row decode
    //---------------------------------------------------------

    wire [1:0] row_a = addr_a[12:11];
    wire [1:0] row_b = addr_b[12:11];

    wire [10:0] bank_addr_a = addr_a[10:0];
    wire [10:0] bank_addr_b = addr_b[10:0];

    //---------------------------------------------------------
    // Outputs from every BRAM
    //---------------------------------------------------------

    wire [7:0] dout_a_bank [0:3][0:3];
    wire [7:0] dout_b_bank [0:3][0:3];

    //---------------------------------------------------------
    // Generate 4 rows × 4 banks = 16 BRAMs
    //---------------------------------------------------------

    genvar r, b;
    generate
        for (r=0; r<4; r=r+1) begin : ROW

            for (b=0; b<4; b=b+1) begin : BANK

                tang9k_bram8_tdp #(
                    .DEPTH(2048),
                    .INIT_FILE
                    (
                    (r==0 && b==0) ? INIT_FILE_0_0 :
                    (r==0 && b==1) ? INIT_FILE_0_1 :
                    (r==0 && b==2) ? INIT_FILE_0_2 :
                    (r==0 && b==3) ? INIT_FILE_0_3 :

                    (r==1 && b==0) ? INIT_FILE_1_0 :
                    (r==1 && b==1) ? INIT_FILE_1_1 :
                    (r==1 && b==2) ? INIT_FILE_1_2 :
                    (r==1 && b==3) ? INIT_FILE_1_3 :

                    (r==2 && b==0) ? INIT_FILE_2_0 :
                    (r==2 && b==1) ? INIT_FILE_2_1 :
                    (r==2 && b==2) ? INIT_FILE_2_2 :
                    (r==2 && b==3) ? INIT_FILE_2_3 :

                    (r==3 && b==0) ? INIT_FILE_3_0 :
                    (r==3 && b==1) ? INIT_FILE_3_1 :
                    (r==3 && b==2) ? INIT_FILE_3_2 :
                                     INIT_FILE_3_3
                    )
                ) bram (

                    .clk(clk),
                    .rst_n(rst_n),

                    // Port A
                    .ce_a (ce_a  && (row_a == r)),
                    .oce_a(oce_a),
                    .we_a (we_a[b] && (row_a == r)),
                    .addr_a(bank_addr_a),
                    .din_a(din_a[8*b +: 8]),
                    .dout_a(dout_a_bank[r][b]),

                    // Port B
                    .ce_b (ce_b  && (row_b == r)),
                    .oce_b(oce_b),
                    .we_b (we_b[b] && (row_b == r)),
                    .addr_b(bank_addr_b),
                    .din_b(din_b[8*b +: 8]),
                    .dout_b(dout_b_bank[r][b])
                );

            end
        end
    endgenerate

    //---------------------------------------------------------
    // Read mux - Port A
    //---------------------------------------------------------

    reg [31:0] dout_a_r;

    always @(*) begin
        case(row_a)
            2'd0:
                dout_a_r = {
                    dout_a_bank[0][3],
                    dout_a_bank[0][2],
                    dout_a_bank[0][1],
                    dout_a_bank[0][0]
                };

            2'd1:
                dout_a_r = {
                    dout_a_bank[1][3],
                    dout_a_bank[1][2],
                    dout_a_bank[1][1],
                    dout_a_bank[1][0]
                };

            2'd2:
                dout_a_r = {
                    dout_a_bank[2][3],
                    dout_a_bank[2][2],
                    dout_a_bank[2][1],
                    dout_a_bank[2][0]
                };

            default:
                dout_a_r = {
                    dout_a_bank[3][3],
                    dout_a_bank[3][2],
                    dout_a_bank[3][1],
                    dout_a_bank[3][0]
                };
        endcase
    end

    assign dout_a = dout_a_r;

    //---------------------------------------------------------
    // Read mux - Port B
    //---------------------------------------------------------

    reg [31:0] dout_b_r;

    always @(*) begin
        case(row_b)
            2'd0:
                dout_b_r = {
                    dout_b_bank[0][3],
                    dout_b_bank[0][2],
                    dout_b_bank[0][1],
                    dout_b_bank[0][0]
                };

            2'd1:
                dout_b_r = {
                    dout_b_bank[1][3],
                    dout_b_bank[1][2],
                    dout_b_bank[1][1],
                    dout_b_bank[1][0]
                };

            2'd2:
                dout_b_r = {
                    dout_b_bank[2][3],
                    dout_b_bank[2][2],
                    dout_b_bank[2][1],
                    dout_b_bank[2][0]
                };

            default:
                dout_b_r = {
                    dout_b_bank[3][3],
                    dout_b_bank[3][2],
                    dout_b_bank[3][1],
                    dout_b_bank[3][0]
                };
        endcase
    end

    assign dout_b = dout_b_r;

endmodule
