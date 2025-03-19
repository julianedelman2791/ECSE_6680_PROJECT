// File: fir_pipelined.v
module fir_pipelined (
    input                    clk,
    input                    reset,
    input      signed [15:0] data_in,
    output reg signed [31:0] data_out
);
    parameter TAP_NUM = 321;      // Total number of taps (coefficients)
    parameter PIPE_STAGES = 4;    // Number of pipeline stages

    // Compute the number of taps per stage (rounding up if necessary)
    localparam TAPS_PER_STAGE = (TAP_NUM + PIPE_STAGES - 1) / PIPE_STAGES;

    // Shift register for input samples
    reg signed [15:0] shift_reg [0:TAP_NUM-1];
    // Coefficient ROM loaded from file
    reg signed [15:0] coeff [0:TAP_NUM-1];

    // Pipeline registers for partial sums (PIPE_STAGES+1 entries)
    reg signed [31:0] stage_sum [0:PIPE_STAGES];

    // Temporary variables declared at module scope (used only within the always block)
    reg signed [31:0] partial;
    integer i, j, k;

    // Read coefficients from file (ensure the file is in the simulation directory)
    initial begin
        $readmemb("fir_coefficients.txt", coeff);
    end

    // Combined always block for shift register update and pipelined MAC computation.
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Clear the shift register
            for (i = 0; i < TAP_NUM; i = i + 1)
                shift_reg[i] <= 16'd0;
            // Clear the pipeline partial sum registers
            for (i = 0; i <= PIPE_STAGES; i = i + 1)
                stage_sum[i] <= 32'd0;
            // Clear output
            data_out <= 32'd0;
        end else begin
            // Shift in the new sample
            shift_reg[0] <= data_in;
            for (i = 1; i < TAP_NUM; i = i + 1)
                shift_reg[i] <= shift_reg[i-1];
                
            // Initialize the first stage of partial sums to zero
            stage_sum[0] <= 32'd0;
            
            // Compute partial sums for each pipeline stage
            for (j = 0; j < PIPE_STAGES; j = j + 1) begin
                partial = 32'd0;
                for (k = j * TAPS_PER_STAGE; (k < (j+1) * TAPS_PER_STAGE) && (k < TAP_NUM); k = k + 1) begin
                    partial = partial + shift_reg[k] * coeff[k];
                end
                stage_sum[j+1] <= stage_sum[j] + partial;
            end
            
            // Output is the sum from the last pipeline stage
            data_out <= stage_sum[PIPE_STAGES];
        end
    end

endmodule
