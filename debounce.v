// Cleans a mechanical/noisy input. The output changes only after the input
// has stayed at a new value for STABLE_CYCLES clock cycles.
// 2 flip-flops at the start also synchronise the async input to clk.
module debounce #(parameter STABLE_CYCLES = 2_000_000)(  // 20 ms @ 100 MHz
    input  clk,
    input  rst,
    input  noisy,
    output reg clean
);
    reg s0, s1;
    reg [$clog2(STABLE_CYCLES+1)-1:0] cnt;
    always @(posedge clk) begin
        s0 <= noisy;
        s1 <= s0;
        if (rst) begin
            clean <= 0;
            cnt   <= 0;
        end else if (s1 != clean) begin
            if (cnt == STABLE_CYCLES-1) begin
                clean <= s1;
                cnt   <= 0;
            end else
                cnt <= cnt + 1;
        end else
            cnt <= 0;
    end
endmodule
