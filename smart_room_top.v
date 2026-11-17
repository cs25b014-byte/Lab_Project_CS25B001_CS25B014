// Top level: FPGA-Based Smart Hostel Room Energy Management System
module smart_room_top #(
    parameter CLK_FREQ        = 100_000_000,
    parameter DEBOUNCE_CYCLES = 2_000_000,   // 20 ms
    parameter T1_SEC          = 10,          // no-motion wait after door activity
    parameter T2_SEC          = 10,          // standby countdown
    parameter T_ENTRY_SEC     = 10,          // window to detect motion after a door event
    parameter REQUIRE_RFID    = 0,           // 0 = automatic entry, 1 = RFID only
    parameter PIR_WARMUP_SEC  = 30,
    parameter PIR_STUCK_SEC   = 600,
    parameter REFRESH_BITS    = 17,
    parameter SEG_ACTIVE_LOW  = 1,           // flip if the display looks wrong
    parameter AN_ACTIVE_LOW   = 1            // flip if the display is blank
)(
    input        clk,
    input        rst_btn,
    input        rfid_btn,    // RFID scan simulation
    input        door_sw,     // 1 = door open
    input        pir_sensor,  // 1 = motion
    input        window_sw,   // 1 = window open
    output       lights_relay, // to relay module 1 (Servo header S0)
    output       ac_relay,     // to relay module 2 (Servo header S1)
    output       lights_led,   // on-board LED mirror of lights_relay
    output       ac_led,       // on-board LED mirror of ac_relay
    output       warn_led,    // flashes in STANDBY
    output       fault_led,   // PIR faulty (stuck high)
    output [7:0] seg,         // {dp,g,f,e,d,c,b,a}
    output [3:0] an
);
    // synchronised reset
    reg r0, r1;
    always @(posedge clk) begin r0 <= rst_btn; r1 <= r0; end
    wire rst = r1;

    // 1-second tick
    wire tick_1hz;
    tick_gen #(.CLK_FREQ(CLK_FREQ)) u_tick (.clk(clk), .rst(rst), .tick(tick_1hz));

    // input conditioning
    wire rfid_c, door_c, pir_c, win_c;
    debounce #(.STABLE_CYCLES(DEBOUNCE_CYCLES)) u_db_rfid (.clk(clk), .rst(rst), .noisy(rfid_btn),   .clean(rfid_c));
    debounce #(.STABLE_CYCLES(DEBOUNCE_CYCLES)) u_db_door (.clk(clk), .rst(rst), .noisy(door_sw),    .clean(door_c));
    debounce #(.STABLE_CYCLES(DEBOUNCE_CYCLES)) u_db_pir  (.clk(clk), .rst(rst), .noisy(pir_sensor), .clean(pir_c));
    debounce #(.STABLE_CYCLES(DEBOUNCE_CYCLES)) u_db_win  (.clk(clk), .rst(rst), .noisy(window_sw),  .clean(win_c));

    // PIR warm-up and stuck-sensor protection
    wire pir_g;
    pir_guard #(.WARMUP_SEC(PIR_WARMUP_SEC), .STUCK_SEC(PIR_STUCK_SEC)) u_guard (
        .clk(clk), .rst(rst), .tick(tick_1hz), .pir_in(pir_c), .pir_out(pir_g), .fault(fault_led));

    // edge detection
    reg rfid_d, door_d;
    always @(posedge clk) begin
        rfid_d <= rfid_c;
        door_d <= door_c;
    end
    wire scan_pulse        = rfid_c & ~rfid_d;   // button pressed
    wire door_change_pulse = door_c ^ door_d;    // door opened or closed

    // FSM + timer
    wire       timer_load, timer_done, powered, standby, counting;
    wire [7:0] timer_load_value, timer_value;

    room_fsm #(.T1_SEC(T1_SEC), .T2_SEC(T2_SEC),
               .T_ENTRY_SEC(T_ENTRY_SEC), .REQUIRE_RFID(REQUIRE_RFID)) u_fsm (
        .clk(clk), .rst(rst),
        .scan_pulse(scan_pulse), .door_change_pulse(door_change_pulse),
        .door_open(door_c), .pir(pir_g), .timer_done(timer_done),
        .timer_load(timer_load), .timer_load_value(timer_load_value),
        .powered(powered), .standby(standby), .counting(counting)
    );

    countdown_timer #(.WIDTH(8)) u_timer (
        .clk(clk), .rst(rst),
        .load(timer_load), .load_value(timer_load_value),
        .tick(tick_1hz), .run(counting),
        .value(timer_value), .done(timer_done)
    );

    // relays (AC is cut whenever the window is open)
    power_logic u_power (
        .powered(powered), .window_open(win_c),
        .lights_relay(lights_relay), .ac_relay(ac_relay)
    );

    // warning LED flashes during standby
    reg blink;
    always @(posedge clk) begin
        if (rst)            blink <= 0;
        else if (tick_1hz)  blink <= ~blink;
    end
    assign warn_led = standby & blink;

    // display: countdown while counting, otherwise "0"
    wire [11:0] bcd;
    bin2bcd u_bcd (.bin(timer_value), .bcd(bcd));
    wire [15:0] digits = counting ? {4'hF, bcd} : 16'hFFF0;

    assign lights_led = lights_relay;
    assign ac_led     = ac_relay;

    wire [6:0] seg7;
    seg_mux #(.REFRESH_BITS(REFRESH_BITS),
              .SEG_ACTIVE_LOW(SEG_ACTIVE_LOW),
              .AN_ACTIVE_LOW(AN_ACTIVE_LOW)) u_seg (
        .clk(clk), .rst(rst), .digits(digits), .seg(seg7), .an(an)
    );
    // decimal point (bit 7) kept OFF
    assign seg = {SEG_ACTIVE_LOW ? 1'b1 : 1'b0, seg7};
endmodule
