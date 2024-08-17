module priority_encoder(
    input [7:0] in, 
    output reg [3:0] out,  
    output reg valid 
);
    always @(*) begin
        valid = 1'b1; // Assume valid is true
        casex (in)
            8'b1xxxxxxx: out = 3'b111; 
            8'b01xx: out = 3'b110;
            8'b001x: out = 3'b101;
            8'b0001: out = 3'b100; 
            8'b1xxx: out = 3'b011; 
            8'b01xx: out = 3'b010;
            8'b001x: out = 3'b001;
            8'b0001: out = 3'b000; 
            default: begin
                out = 3'b0000; 
                valid = 1'b0;
            end
        endcase
    end
endmodule
