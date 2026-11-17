// Fully automatic room controller.
//
// UNOCC : power OFF. Waits for an entry.
// ARM   : power OFF. A door event was seen; waits T_ENTRY_SEC for motion (real entry)
//         or an RFID scan. No motion -> false alarm -> back to UNOCC.
// OCC   : power ON, room in use.
// WAIT  : power ON, T1 countdown, nobody seen after a door event.
// STBY  : power ON, warning LED, T2 countdown, then power OFF automatically.
//
// REQUIRE_RFID = 1 : entry only by RFID scan (door/motion cannot switch the room on).
// REQUIRE_RFID = 0 : entry is automatic (door event + motion); RFID still works.
//
// Priority when events coincide:  scan  >  motion  >  door event  >  timer.
module room_fsm #(
    parameter T1_SEC        = 10,
    parameter T2_SEC        = 10,
    parameter T_ENTRY_SEC   = 10,
    parameter REQUIRE_RFID  = 0
)(
    input            clk,
    input            rst,
    input            scan_pulse,         // RFID pressed (1 cycle)
    input            door_change_pulse,  // door opened OR closed (1 cycle)
    input            door_open,          // door level, 1 = open
    input            pir,                // guarded motion signal
    input            timer_done,
    output reg       timer_load,
    output reg [7:0] timer_load_value,
    output           powered,
    output           standby,
    output           counting
);
    localparam UNOCC = 3'd0, ARM = 3'd1, OCC = 3'd2, WAIT = 3'd3, STBY = 3'd4;
    reg [2:0] state, next;

    always @(posedge clk) begin
        if (rst) state <= UNOCC;           // fail-safe: power-up = OFF
        else     state <= next;
    end

    always @* begin
        next             = state;
        timer_load       = 1'b0;
        timer_load_value = T1_SEC;
        case (state)
            UNOCC: begin
                if (scan_pulse) next = OCC;
                else if (!REQUIRE_RFID && door_change_pulse) begin
                    next = ARM;
                    timer_load = 1'b1;
                    timer_load_value = T_ENTRY_SEC;
                end
            end
            ARM: begin
                if (scan_pulse)      next = OCC;
                else if (pir)        next = OCC;      // someone really came in
                else if (timer_done) next = UNOCC;    // false alarm
            end
            OCC: begin
                if (scan_pulse) next = UNOCC;         // scan-out
                else if (door_change_pulse || (door_open && !pir)) begin
                    // door activity, or door LEFT OPEN with no motion
                    next = WAIT;
                    timer_load = 1'b1;
                    timer_load_value = T1_SEC;
                end
            end
            WAIT: begin
                if (scan_pulse)               next = UNOCC;
                else if (pir)                 next = OCC;
                else if (door_change_pulse) begin     // door toggled again: restart T1
                    timer_load = 1'b1;
                    timer_load_value = T1_SEC;
                end
                else if (timer_done) begin
                    next = STBY;
                    timer_load = 1'b1;
                    timer_load_value = T2_SEC;
                end
            end
            STBY: begin
                if (scan_pulse)               next = UNOCC;
                else if (pir)                 next = OCC;    // person woke up / moved
                else if (door_change_pulse) begin            // someone at the door
                    next = WAIT;
                    timer_load = 1'b1;
                    timer_load_value = T1_SEC;
                end
                else if (timer_done)          next = UNOCC;  // automatic power OFF
            end
            default: next = UNOCC;
        endcase
    end

    assign powered  = (state == OCC) || (state == WAIT) || (state == STBY);
    assign standby  = (state == STBY);
    assign counting = (state == ARM) || (state == WAIT) || (state == STBY);
endmodule
