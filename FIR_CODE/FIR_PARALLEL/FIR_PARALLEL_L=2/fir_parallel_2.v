// File: fir_parallel_2.v
// L = 2 Parallel (Polyphase) FIR Filter Implementation
// Uses 321 taps (coefficients) loaded from fir_coefficients.txt,
// then partitions the coefficients into even and odd arrays.

module fir_parallel_2 (
    input                    clk,
    input                    reset,
    input      signed [15:0] data_in,
    output reg signed [31:0] data_out
);
    parameter TAP_NUM = 321;  // Total number of taps (coefficients)
    // For 321 taps: EVEN_TAPS = 161, ODD_TAPS = 160
    localparam EVEN_TAPS = (TAP_NUM + 1) / 2;
    localparam ODD_TAPS  = TAP_NUM / 2;
    
    // Full coefficient array, then partitioned arrays
    reg signed [15:0] coeff_full [0:TAP_NUM-1];
    reg signed [15:0] coeff_even [0:EVEN_TAPS-1];
    reg signed [15:0] coeff_odd  [0:ODD_TAPS-1];
    
    // Shift register for input samples
    reg signed [15:0] shift_reg [0:TAP_NUM-1];
    
    // Temporary MAC sum variables
    reg signed [31:0] sum_even, sum_odd;
    reg signed [31:0] odd_delay;  // Register to delay odd branch by one clock cycle
    
    integer i, j;
    
    // Load full coefficients from file and partition into even/odd branches.
    // The file fir_coefficients.txt should contain 321 lines of 16-bit binary numbers.
    initial begin
        $readmemb("fir_coefficients.txt", coeff_full);
        for (i = 0; i < TAP_NUM; i = i + 1) begin
            if (i % 2 == 0)
                coeff_even[i/2] = coeff_full[i];
            else
                coeff_odd[(i-1)/2] = coeff_full[i];
        end
    end
    
    // FIR filter operation: shift register update and MAC computation.
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Initialize shift register and outputs
            for (i = 0; i < TAP_NUM; i = i + 1)
                shift_reg[i] <= 16'd0;
            odd_delay <= 32'd0;
            data_out <= 32'd0;
        end else begin
            // Update shift register: new sample in index 0; shift previous values.
            shift_reg[0] <= data_in;
            for (i = 1; i < TAP_NUM; i = i + 1)
                shift_reg[i] <= shift_reg[i-1];
            
            // Compute even branch sum: sum_{j=0}^{EVEN_TAPS-1} shift_reg[2*j] * coeff_even[j]
            sum_even = 32'd0;
            for (j = 0; j < EVEN_TAPS; j = j + 1) begin
                sum_even = sum_even + shift_reg[2*j] * coeff_even[j];
            end
            
            // Compute odd branch sum: sum_{j=0}^{ODD_TAPS-1} shift_reg[2*j+1] * coeff_odd[j]
            sum_odd = 32'd0;
            for (j = 0; j < ODD_TAPS; j = j + 1) begin
                sum_odd = sum_odd + shift_reg[2*j+1] * coeff_odd[j];
            end
            
            // Delay the odd branch sum by one clock cycle
            odd_delay <= sum_odd;
            // Final output: sum of even branch and delayed odd branch
            data_out <= sum_even + odd_delay;
        end
    end

endmodule
