`timescale 1ns/1ps
// States: 0=UNOCC 1=ARM 2=OCC 3=WAIT 4=STBY
// All timings shrunk: 1 "second" = 100 clock cycles.
module tb_smart_room_top;
    reg  clk = 0, rst_btn = 0, rfid_btn = 0, door_sw = 0, pir_sensor = 0, window_sw = 0;
    wire lights_relay, ac_relay, warn_led, fault_led, lights_led, ac_led;
    wire [7:0] seg; wire [3:0] an;

    smart_room_top #(.CLK_FREQ(100), .DEBOUNCE_CYCLES(5),
                     .T1_SEC(5), .T2_SEC(5), .T_ENTRY_SEC(5),
                     .REQUIRE_RFID(0), .PIR_WARMUP_SEC(1), .PIR_STUCK_SEC(8),
                     .REFRESH_BITS(4)) dut (
        .clk(clk), .rst_btn(rst_btn), .rfid_btn(rfid_btn), .door_sw(door_sw),
        .pir_sensor(pir_sensor), .window_sw(window_sw),
        .lights_relay(lights_relay), .ac_relay(ac_relay),
        .lights_led(lights_led), .ac_led(ac_led), .warn_led(warn_led), .fault_led(fault_led), .seg(seg), .an(an));

    always #5 clk = ~clk;

    task wait_clk(input integer n); begin repeat (n) @(posedge clk); end endtask
    task press_rfid; begin rfid_btn = 1; wait_clk(20); rfid_btn = 0; wait_clk(20); end endtask
    task door_cycle; begin door_sw = 1; wait_clk(20); door_sw = 0; wait_clk(20); end endtask
    task check(input cond, input [255:0] msg);
        begin if (cond) $display("PASS: %0s", msg); else $display("FAIL: %0s", msg); end
    endtask

    initial begin
        rst_btn = 1; wait_clk(5); rst_btn = 0; wait_clk(250);   // reset + PIR warm-up
        check(dut.u_fsm.state==0 && lights_relay==0 && ac_relay==0, "power-up: everything OFF");

        // 1. AUTOMATIC ON: door event + motion
        door_cycle;
        check(dut.u_fsm.state==1 && lights_relay==0, "door event -> ARM, still off");
        pir_sensor = 1; wait_clk(30); pir_sensor = 0; wait_clk(30);
        check(dut.u_fsm.state==2 && lights_relay==1 && ac_relay==1, "motion after door -> AUTO ON");

        // 2. window exception
        window_sw = 1; wait_clk(30);
        check(lights_relay==1 && ac_relay==0, "window open -> AC off, lights on");
        window_sw = 0; wait_clk(30);
        check(ac_relay==1, "window closed -> AC back on");

        // 3. glitch exception
        door_sw = 1; wait_clk(2); door_sw = 0; wait_clk(30);
        check(dut.u_fsm.state==2, "2-cycle door glitch ignored");

        // 4. rapid door toggling exception
        door_cycle; door_cycle; door_cycle;
        check(dut.u_fsm.state==3 && lights_relay==1, "rapid door toggling -> WAIT, power stays on");

        // 5. automatic OFF path: WAIT -> STBY, then motion rescues
        wait_clk(700);
        check(dut.u_fsm.state==4 && lights_relay==1, "no motion -> STANDBY");
        wait_clk(150);
        $display("warn_led sample = %b", warn_led);
        pir_sensor = 1; wait_clk(30); pir_sensor = 0; wait_clk(30);
        check(dut.u_fsm.state==2, "motion in STANDBY -> OCC (sleeping person rescued)");

        // 6. door left open, nobody inside -> AUTOMATIC OFF
        door_sw = 1; wait_clk(40);
        check(dut.u_fsm.state==3, "door left open, no motion -> WAIT");
        wait_clk(700);
        check(dut.u_fsm.state==4, "-> STANDBY");
        wait_clk(600);
        check(dut.u_fsm.state==0 && lights_relay==0 && ac_relay==0, "-> AUTOMATIC OFF");
        door_sw = 0; wait_clk(700);
        check(dut.u_fsm.state==0, "false alarm (no motion after door) ignored");

        // 7. manual RFID in / out still works
        press_rfid; wait_clk(10);
        check(dut.u_fsm.state==2, "RFID scan in");
        press_rfid; wait_clk(10);
        check(dut.u_fsm.state==0, "RFID scan out");

        // 8. stuck PIR exception
        door_cycle;
        pir_sensor = 1; wait_clk(60);
        check(dut.u_fsm.state==2, "entry with PIR high");
        wait_clk(1000);
        check(fault_led==1, "PIR stuck high -> fault flagged");
        door_cycle;
        wait_clk(1400);
        check(dut.u_fsm.state==0, "stuck PIR ignored -> still powers off");
        pir_sensor = 0;
        $finish;
    end
endmodule
