
module icarus_soc #(
    parameter real CLK_FREQUENCY_MHZ = 9.0
) (
    // Main system clk
    input logic clk,

    // Buttons
    input logic [4:0] buttons_async
);
    import constants::*;

    logic [4:0] buttons;
    for (genvar i = 0; i < 5; i++) begin: button_conditioning
        synchronizer button_sync(
            .clk(clk),
            .async_in(buttons_async[i]),
            .sync_out(buttons[i])
        );
    end

    logic rst = 1;

    // Use button0 as reset
    always_ff @(posedge clk) begin
        rst <= buttons[0];
    end

    // Fetch bus signals (CPU -> RAM port A)
    logic [31:0] fetch_adr;
    logic [3:0]  fetch_sel;
    logic [31:0] fetch_dat_mosi;
    logic [31:0] fetch_dat_miso;
    logic        fetch_cyc;
    logic        fetch_stb;
    logic        fetch_we;
    logic        fetch_ack;
    logic        fetch_err;

    // Mem bus signals (CPU -> Interconnect Master)
    logic [31:0] mem_adr;
    logic [3:0]  mem_sel;
    logic [31:0] mem_dat_mosi;
    logic [31:0] mem_dat_miso;
    logic        mem_cyc;
    logic        mem_stb;
    logic        mem_we;
    logic        mem_ack;
    logic        mem_err;

    // Slave 0 (Interconnect -> RAM port B)
    logic [31:0] s0_adr, s0_dat_mosi, s0_dat_miso;
    logic [3:0]  s0_sel;
    logic        s0_cyc, s0_stb, s0_we, s0_ack, s0_err;

    // Slave 1 (Interconnect -> Buttons)
    logic [31:0] s1_adr, s1_dat_mosi, s1_dat_miso;
    logic [3:0]  s1_sel;
    logic        s1_cyc, s1_stb, s1_we, s1_ack, s1_err;

    // Slave 2 (Interconnect -> Timer)
    logic [31:0] s2_adr, s2_dat_mosi, s2_dat_miso;
    logic [3:0]  s2_sel;
    logic        s2_cyc, s2_stb, s2_we, s2_ack, s2_err;

    // Slave 3 (Interconnect -> Test)
    logic [31:0] s3_adr, s3_dat_mosi, s3_dat_miso;
    logic [3:0]  s3_sel;
    logic        s3_cyc, s3_stb, s3_we, s3_ack, s3_err;

    // Interrupts    
    logic test_interrupt;
    logic timer_interrupt;

    logic external_interrupt;
    assign external_interrupt = test_interrupt;

    // Instantiate CPU
    Hadi_V cpu(
        .clk(clk),
        .rst(rst),

        .fetch_adr(fetch_adr),
        .fetch_sel(fetch_sel),
        .fetch_dat_mosi(fetch_dat_mosi),
        .fetch_dat_miso(fetch_dat_miso),
        .fetch_cyc(fetch_cyc),
        .fetch_stb(fetch_stb),
        .fetch_we(fetch_we),
        .fetch_ack(fetch_ack),
        .fetch_err(fetch_err),

        .mem_adr(mem_adr),
        .mem_sel(mem_sel),
        .mem_dat_mosi(mem_dat_mosi),
        .mem_dat_miso(mem_dat_miso),
        .mem_cyc(mem_cyc),
        .mem_stb(mem_stb),
        .mem_we(mem_we),
        .mem_ack(mem_ack),
        .mem_err(mem_err),

        .external_interrupt_in(external_interrupt),
        .timer_interrupt_in(timer_interrupt)
    );

    // Interconnect
    wishbone_interconnect #(
        .NUM_SLAVES(4),
        .SLAVE_ADDRESS({
            TEST_START,
            TIMER_START,
            BUTTONS_START,
            MEMORY_START
        }),
        .SLAVE_SIZE({
            TEST_SIZE,
            TIMER_SIZE,
            BUTTONS_SIZE,
            MEMORY_SIZE
        })
    ) peripheral_bus_interconnect (
        .clk(clk),
        .rst(rst),

        .master_adr(mem_adr),
        .master_sel(mem_sel),
        .master_dat_mosi(mem_dat_mosi),
        .master_dat_miso(mem_dat_miso),
        .master_cyc(mem_cyc),
        .master_stb(mem_stb),
        .master_we(mem_we),
        .master_ack(mem_ack),
        .master_err(mem_err),

        .s0_adr(s0_adr), .s0_sel(s0_sel), .s0_dat_mosi(s0_dat_mosi), .s0_dat_miso(s0_dat_miso),
        .s0_cyc(s0_cyc), .s0_stb(s0_stb), .s0_we(s0_we), .s0_ack(s0_ack), .s0_err(s0_err),

        .s1_adr(s1_adr), .s1_sel(s1_sel), .s1_dat_mosi(s1_dat_mosi), .s1_dat_miso(s1_dat_miso),
        .s1_cyc(s1_cyc), .s1_stb(s1_stb), .s1_we(s1_we), .s1_ack(s1_ack), .s1_err(s1_err),

        .s2_adr(s2_adr), .s2_sel(s2_sel), .s2_dat_mosi(s2_dat_mosi), .s2_dat_miso(s2_dat_miso),
        .s2_cyc(s2_cyc), .s2_stb(s2_stb), .s2_we(s2_we), .s2_ack(s2_ack), .s2_err(s2_err),

        .s3_adr(s3_adr), .s3_sel(s3_sel), .s3_dat_mosi(s3_dat_mosi), .s3_dat_miso(s3_dat_miso),
        .s3_cyc(s3_cyc), .s3_stb(s3_stb), .s3_we(s3_we), .s3_ack(s3_ack), .s3_err(s3_err)
    );

    wishbone_ram #(
        .ADDRESS(MEMORY_START),
        .SIZE(MEMORY_SIZE)
    ) ram (
        .clk(~clk),
        .rst(rst),

        .port_a_adr(fetch_adr),
        .port_a_sel(fetch_sel),
        .port_a_dat_mosi(fetch_dat_mosi),
        .port_a_dat_miso(fetch_dat_miso),
        .port_a_cyc(fetch_cyc),
        .port_a_stb(fetch_stb),
        .port_a_we(fetch_we),
        .port_a_ack(fetch_ack),
        .port_a_err(fetch_err),

        .port_b_adr(s0_adr),
        .port_b_sel(s0_sel),
        .port_b_dat_mosi(s0_dat_mosi),
        .port_b_dat_miso(s0_dat_miso),
        .port_b_cyc(s0_cyc),
        .port_b_stb(s0_stb),
        .port_b_we(s0_we),
        .port_b_ack(s0_ack),
        .port_b_err(s0_err)
    );

    wishbone_buttons #(
        .ADDRESS(BUTTONS_START),
        .SIZE(BUTTONS_SIZE)
    ) wb_buttons (
        .clk(clk),
        .rst(rst),
        .buttons(buttons),

        .wb_adr(s1_adr),
        .wb_sel(s1_sel),
        .wb_dat_mosi(s1_dat_mosi),
        .wb_dat_miso(s1_dat_miso),
        .wb_cyc(s1_cyc),
        .wb_stb(s1_stb),
        .wb_we(s1_we),
        .wb_ack(s1_ack),
        .wb_err(s1_err)
    );

    wishbone_timer #(
        .ADDRESS(TIMER_START),
        .SIZE(TIMER_SIZE),
        .CLK_FREQUENCY_MHZ(CLK_FREQUENCY_MHZ)
    ) wb_timer (
        .clk(clk),
        .rst(rst),
        .interrupt(timer_interrupt),

        .wb_adr(s2_adr),
        .wb_sel(s2_sel),
        .wb_dat_mosi(s2_dat_mosi),
        .wb_dat_miso(s2_dat_miso),
        .wb_cyc(s2_cyc),
        .wb_stb(s2_stb),
        .wb_we(s2_we),
        .wb_ack(s2_ack),
        .wb_err(s2_err)
    );

    wishbone_test #(
        .ADDRESS(TEST_START),
        .SIZE(TEST_SIZE)
    ) wb_test (
        .clk(clk),
        .rst(rst),
        .interrupt(test_interrupt),

        .wb_adr(s3_adr),
        .wb_sel(s3_sel),
        .wb_dat_mosi(s3_dat_mosi),
        .wb_dat_miso(s3_dat_miso),
        .wb_cyc(s3_cyc),
        .wb_stb(s3_stb),
        .wb_we(s3_we),
        .wb_ack(s3_ack),
        .wb_err(s3_err)
    );

endmodule
