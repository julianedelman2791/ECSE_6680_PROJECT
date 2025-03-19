// File: fir_standard.v
module fir_standard (
    input                    clk,
    input                    reset,
    input      signed [15:0] data_in,
    output reg signed [31:0] data_out
);
    parameter TAP_NUM = 321;
    // Shift register for input samples
    reg signed [15:0] shift_reg [0:TAP_NUM-1];
    // Coefficient ROM – coefficients loaded from file
    reg signed [15:0] coeff [0:TAP_NUM-1];
    integer i, j;
    reg signed [31:0] acc;

    // Initialize coefficients from file (ensure the file "fir_coefficients.txt" is in the simulation working directory)
    initial begin
        $readmemb("fir_coefficients.txt", coeff);
        // Print first few coefficients:
        for (i = 0; i < 5; i = i + 1)
            $display("Coefficient[%0d] = %b", i, coeff[i]);
    end

    // Combined always block for shift register update and MAC computation
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            for (i = 0; i < TAP_NUM; i = i + 1)
                shift_reg[i] <= 16'd0;
            data_out <= 32'd0;
        end else begin
            // Shift register
            shift_reg[0] <= data_in;
            for (i = 1; i < TAP_NUM; i = i + 1)
                shift_reg[i] <= shift_reg[i-1];
                
            // Compute the MAC using the shift register values from the previous clock edge
            acc = 32'd0;
            for (j = 0; j < TAP_NUM; j = j + 1) begin
                acc = acc + shift_reg[j] * coeff[j];
            end
            data_out <= acc;
        end
    end

endmodule
