// Seconds countdown. load -> value = load_value.
// While run=1, value decreases by 1 on every 1-second tick, stops at 0.
module countdown_timer #(parameter WIDTH = 8)(
    input              clk,
    input              rst,
    input              load,
    input  [WIDTH-1:0] load_value,
    input              tick,
    input              run,
    output reg [WIDTH-1:0] value,
    output             done
);
    always @(posedge clk) begin
        if (rst)
            value <= 0;
        else if (load)
            value <= load_value;
        else if (run && tick && value != 0)
            value <= value - 1;
    end
    assign done = (value == 0);
endmodule
