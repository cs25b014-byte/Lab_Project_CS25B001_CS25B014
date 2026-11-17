// Combinational relay logic: AC is cut when the window is open.
module power_logic (
    input  powered,
    input  window_open,
    output lights_relay,
    output ac_relay
);
    assign lights_relay = powered;
    assign ac_relay     = powered & ~window_open;
endmodule
