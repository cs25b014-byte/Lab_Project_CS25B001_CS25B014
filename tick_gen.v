// Produces ONE clock-cycle-wide pulse ("tick") every second.
// CLK_FREQ = board clock in Hz (100 MHz on the Boolean Board).
module tick_gen #(parameter CLK_FREQ = 100_000_000)(
    input  clk,
    input  rst,
    output reg tick
);
    reg [$clog2(CLK_FREQ)-1:0] cnt;
    always @(posedge clk) begin
        if (rst) begin
            cnt  <= 0;
            tick <= 0;
        end else if (cnt == CLK_FREQ-1) begin
            cnt  <= 0;
            tick <= 1;          // one-cycle pulse
        end else begin
            cnt  <= cnt + 1;
            tick <= 0;
        end
    end
endmodule
