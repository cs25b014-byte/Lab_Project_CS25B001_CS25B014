// Drives a 4-digit multiplexed 7-segment display.
// digits = {d3,d2,d1,d0}, each a 4-bit BCD value (4'hF = blank).
// Set the *_ACTIVE_LOW parameters to match your board.
module seg_mux #(
    parameter REFRESH_BITS  = 17,   // ~760 Hz full refresh at 100 MHz
    parameter SEG_ACTIVE_LOW = 1,
    parameter AN_ACTIVE_LOW  = 1
)(
    input             clk,
    input             rst,
    input      [15:0] digits,
    output     [6:0]  seg,          // {g,f,e,d,c,b,a}
    output     [3:0]  an
);
    reg [REFRESH_BITS-1:0] cnt;
    always @(posedge clk) begin
        if (rst) cnt <= 0;
        else     cnt <= cnt + 1;
    end
    wire [1:0] sel = cnt[REFRESH_BITS-1:REFRESH_BITS-2];

    reg [3:0] nib;
    reg [3:0] an_raw;
    reg [6:0] seg_raw;   // active-high: 1 = segment lit

    always @* begin
        case (sel)
            2'd0: begin nib = digits[3:0];   an_raw = 4'b0001; end
            2'd1: begin nib = digits[7:4];   an_raw = 4'b0010; end
            2'd2: begin nib = digits[11:8];  an_raw = 4'b0100; end
            default: begin nib = digits[15:12]; an_raw = 4'b1000; end
        endcase
    end

    always @* begin
        case (nib)
            4'd0: seg_raw = 7'b0111111;
            4'd1: seg_raw = 7'b0000110;
            4'd2: seg_raw = 7'b1011011;
            4'd3: seg_raw = 7'b1001111;
            4'd4: seg_raw = 7'b1100110;
            4'd5: seg_raw = 7'b1101101;
            4'd6: seg_raw = 7'b1111101;
            4'd7: seg_raw = 7'b0000111;
            4'd8: seg_raw = 7'b1111111;
            4'd9: seg_raw = 7'b1101111;
            default: seg_raw = 7'b0000000;   // blank
        endcase
    end

    assign seg = SEG_ACTIVE_LOW ? ~seg_raw : seg_raw;
    assign an  = AN_ACTIVE_LOW  ? ~an_raw  : an_raw;
endmodule
