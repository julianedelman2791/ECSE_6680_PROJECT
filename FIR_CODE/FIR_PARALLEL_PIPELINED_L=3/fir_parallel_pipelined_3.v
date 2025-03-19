// File: fir_parallel_pipelined_3.v
// Combined Pipelining and L=3 Parallel (Polyphase) FIR Filter
// This design uses 321 taps. The coefficients are loaded from 
// "fir_coefficients.txt" (one 16-bit binary number per line).
// The filter partitions the coefficients into 3 branches and computes 
// each branch’s dot product using a two-stage pipelined accumulation.
// Branch1 is delayed by 1 clock cycle and Branch2 by 2 clock cycles before
// summing with Branch0 to produce the final output.

module fir_parallel_pipelined_3 (
    input                    clk,
    input                    reset,
    input      signed [15:0] data_in,
    output reg signed [31:0] data_out
);

    // Parameters
    parameter TAP_NUM = 321;        // Total number of taps (coefficients)
    parameter PIPE_STAGES = 2;      // Number of pipeline stages per branch accumulation

    // Partition sizes for L=3 splitting
    localparam SIZE0 = (TAP_NUM+2)/3; // Branch0: indices 0, 3, 6, ...
    localparam SIZE1 = (TAP_NUM+1)/3; // Branch1: indices 1, 4, 7, ...
    localparam SIZE2 = TAP_NUM/3;     // Branch2: indices 2, 5, 8, ...

    // For pipelining within each branch, compute the stage length.
    localparam stageLen0 = (SIZE0 + PIPE_STAGES - 1) / PIPE_STAGES;
    localparam stageLen1 = (SIZE1 + PIPE_STAGES - 1) / PIPE_STAGES;
    localparam stageLen2 = (SIZE2 + PIPE_STAGES - 1) / PIPE_STAGES;

    // Coefficient arrays
    reg signed [15:0] coeff_full [0:TAP_NUM-1];
    reg signed [15:0] coeff0 [0:SIZE0-1];
    reg signed [15:0] coeff1 [0:SIZE1-1];
    reg signed [15:0] coeff2 [0:SIZE2-1];
    
    // Shift register for input samples
    reg signed [15:0] shift_reg [0:TAP_NUM-1];

    // Registers to hold each branch’s computed dot product
    reg signed [31:0] branch0_sum, branch1_sum, branch2_sum;
    
    // Delay registers for aligning branch outputs:
    // Branch1 delayed by 1 cycle; Branch2 delayed by 2 cycles.
    reg signed [31:0] delay_branch1;
    reg signed [31:0] delay_branch2_stage1, delay_branch2_stage2;
    
    // Temporary accumulators for pipelined accumulation (declared at module level)
    reg signed [31:0] temp0_1, temp0_2;
    reg signed [31:0] temp1_1, temp1_2;
    reg signed [31:0] temp2_1, temp2_2;
    
    integer i, j;

    // Load full coefficient array from file and partition into 3 branches.
    initial begin
        $readmemb("fir_coefficients.txt", coeff_full);
        for (i = 0; i < TAP_NUM; i = i + 1) begin
            if (i % 3 == 0)
                coeff0[i/3] = coeff_full[i];
            else if (i % 3 == 1)
                coeff1[(i-1)/3] = coeff_full[i];
            else
                coeff2[(i-2)/3] = coeff_full[i];
        end
    end

    // Combined always block: update shift register, compute pipelined MAC for each branch,
    // update alignment delays, and produce final output.
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Clear the shift register
            for (i = 0; i < TAP_NUM; i = i + 1)
                shift_reg[i] <= 16'd0;
            branch0_sum <= 32'd0;
            branch1_sum <= 32'd0;
            branch2_sum <= 32'd0;
            delay_branch1 <= 32'd0;
            delay_branch2_stage1 <= 32'd0;
            delay_branch2_stage2 <= 32'd0;
            data_out <= 32'd0;
        end else begin
            // Update shift register: new sample enters at index 0; shift all others
            shift_reg[0] <= data_in;
            for (i = 1; i < TAP_NUM; i = i + 1)
                shift_reg[i] <= shift_reg[i-1];
                
            // --- Compute Branch0 (indices 0,3,6,...): pipelined into 2 segments ---
            temp0_1 = 32'd0;
            for (j = 0; (j < stageLen0) && (j < SIZE0); j = j + 1) begin
                temp0_1 = temp0_1 + shift_reg[3*j] * coeff0[j];
            end
            temp0_2 = 32'd0;
            for (j = stageLen0; j < SIZE0; j = j + 1) begin
                temp0_2 = temp0_2 + shift_reg[3*j] * coeff0[j];
            end
            branch0_sum <= temp0_1 + temp0_2;
            
            // --- Compute Branch1 (indices 1,4,7,...): pipelined into 2 segments ---
            temp1_1 = 32'd0;
            for (j = 0; (j < stageLen1) && (j < SIZE1); j = j + 1) begin
                temp1_1 = temp1_1 + shift_reg[3*j+1] * coeff1[j];
            end
            temp1_2 = 32'd0;
            for (j = stageLen1; j < SIZE1; j = j + 1) begin
                temp1_2 = temp1_2 + shift_reg[3*j+1] * coeff1[j];
            end
            branch1_sum <= temp1_1 + temp1_2;
            
            // --- Compute Branch2 (indices 2,5,8,...): pipelined into 2 segments ---
            temp2_1 = 32'd0;
            for (j = 0; (j < stageLen2) && (j < SIZE2); j = j + 1) begin
                temp2_1 = temp2_1 + shift_reg[3*j+2] * coeff2[j];
            end
            temp2_2 = 32'd0;
            for (j = stageLen2; j < SIZE2; j = j + 1) begin
                temp2_2 = temp2_2 + shift_reg[3*j+2] * coeff2[j];
            end
            branch2_sum <= temp2_1 + temp2_2;
            
            // --- Update alignment delays ---
            delay_branch1 <= branch1_sum;               // branch1 delayed by 1 cycle
            delay_branch2_stage1 <= branch2_sum;          // branch2 first delay stage
            delay_branch2_stage2 <= delay_branch2_stage1; // branch2 second delay stage (total 2-cycle delay)
            
            // --- Final Output: sum branch0 (no delay) + delayed branch1 + delayed branch2 ---
            data_out <= branch0_sum + delay_branch1 + delay_branch2_stage2;
        end
    end

endmodule
