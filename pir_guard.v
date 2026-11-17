// Protects the design from a misbehaving PIR sensor.
//  1) WARM-UP : real PIR modules output garbage for ~30-60 s after power-up -> ignored.
//  2) STUCK   : if the PIR stays high for STUCK_SEC seconds it is assumed faulty
//               -> ignored (fail-safe: power-saving still works) and fault is raised.
module pir_guard #(
    parameter WARMUP_SEC = 30,
    parameter STUCK_SEC  = 600
)(
    input  clk,
    input  rst,
    input  tick,      // 1-second pulse
    input  pir_in,
    output pir_out,
    output fault
);
    reg [15:0] warm, stuck;
    wire warming = (warm < WARMUP_SEC);

    always @(posedge clk) begin
        if (rst) begin
            warm  <= 0;
            stuck <= 0;
        end else begin
            if (tick && warming) warm <= warm + 1;
            if (!pir_in)                          stuck <= 0;
            else if (tick && stuck < STUCK_SEC)   stuck <= stuck + 1;
        end
    end

    assign fault   = (stuck >= STUCK_SEC);
    assign pir_out = pir_in & ~warming & ~fault;
endmodule
