`timescale 1ns/1ps

//======================================================================
// 4-BIT CARRY LOOKAHEAD ADDER
//======================================================================
module cla_4bit (
    input  logic [3:0] a,
    input  logic [3:0] b,
    input  logic       cin,

    output logic [3:0] sum,
    output logic       cout,

    output logic       group_p,
    output logic       group_g
);

    // -----------------------------------------------------------------
    // Bit propagate and generate
    // -----------------------------------------------------------------
    logic [3:0] p;
    logic [3:0] g;

    // Carry signals
    logic [4:0] c;

    // -----------------------------------------------------------------
    // Propagate / Generate
    // -----------------------------------------------------------------
    assign p = a ^ b;
    assign g = a & b;

    assign c[0] = cin;

    // -----------------------------------------------------------------
    // Carry Lookahead Equations
    // -----------------------------------------------------------------

    // C1 = G0 + P0*C0
    assign c[1] =
          g[0]
        | (p[0] & c[0]);

    // C2 = G1 + P1*G0 + P1*P0*C0
    assign c[2] =
          g[1]
        | (p[1] & g[0])
        | (p[1] & p[0] & c[0]);

    // C3 = G2 + P2*G1 + P2*P1*G0 + P2*P1*P0*C0
    assign c[3] =
          g[2]
        | (p[2] & g[1])
        | (p[2] & p[1] & g[0])
        | (p[2] & p[1] & p[0] & c[0]);

    // C4 = G3 + P3*G2 + P3*P2*G1
    //          + P3*P2*P1*G0
    //          + P3*P2*P1*P0*C0
    assign c[4] =
          g[3]
        | (p[3] & g[2])
        | (p[3] & p[2] & g[1])
        | (p[3] & p[2] & p[1] & g[0])
        | (p[3] & p[2] & p[1] & p[0] & c[0]);

    // -----------------------------------------------------------------
    // Sum
    // -----------------------------------------------------------------
    assign sum = p ^ c[3:0];

    // -----------------------------------------------------------------
    // 4-bit block carry-out
    // -----------------------------------------------------------------
    assign cout = c[4];

    // -----------------------------------------------------------------
    // Group Propagate
    //
    // PG = P3*P2*P1*P0
    // -----------------------------------------------------------------
    assign group_p =
          p[3]
        & p[2]
        & p[1]
        & p[0];

    // -----------------------------------------------------------------
    // Group Generate
    //
    // GG = G3
    //    + P3*G2
    //    + P3*P2*G1
    //    + P3*P2*P1*G0
    // -----------------------------------------------------------------
    assign group_g =
          g[3]
        | (p[3] & g[2])
        | (p[3] & p[2] & g[1])
        | (p[3] & p[2] & p[1] & g[0]);

endmodule



//======================================================================
// PARAMETERIZED N-BIT HIERARCHICAL CARRY LOOKAHEAD ADDER
//
// Architecture:
//
//                    N-BIT CLA
//                        |
//          +-------------+-------------+
//          |             |             |
//        CLA-4         CLA-4         CLA-4
//        Block 0       Block 1       Block 2
//          |             |             |
//          +------ GROUP CARRY --------+
//
// N must be a multiple of 4.
//
// Valid examples:
//     N = 4
//     N = 8
//     N = 12
//     N = 16
//     N = 32
//======================================================================
module cla_adder #(
    parameter int N = 8
)(
    input  logic [N-1:0] a,
    input  logic [N-1:0] b,
    input  logic         cin,

    output logic [N-1:0] sum,
    output logic         cout
);

    // -----------------------------------------------------------------
    // Number of 4-bit CLA blocks
    // -----------------------------------------------------------------
    localparam int NUM_BLOCKS = N / 4;

    // -----------------------------------------------------------------
    // Compile-time / elaboration-time parameter checking
    // -----------------------------------------------------------------
    initial begin

        if (N < 4) begin
            $error(
                "CLA ERROR: N=%0d is invalid. N must be >= 4.",
                N
            );
        end

        if ((N % 4) != 0) begin
            $error(
                "CLA ERROR: N=%0d is invalid. N must be a multiple of 4.",
                N
            );
        end

    end

    // -----------------------------------------------------------------
    // Group propagate and group generate for every 4-bit block
    // -----------------------------------------------------------------
    logic [NUM_BLOCKS-1:0] group_p;
    logic [NUM_BLOCKS-1:0] group_g;

    // -----------------------------------------------------------------
    // Carry entering every CLA block
    //
    // block_carry[0]           = external CIN
    // block_carry[1]           = carry into block 1
    // block_carry[2]           = carry into block 2
    // ...
    // block_carry[NUM_BLOCKS]  = final COUT
    // -----------------------------------------------------------------
    logic [NUM_BLOCKS:0] block_carry;

    // -----------------------------------------------------------------
    // Individual 4-bit block carry-out
    //
    // Used for observation/debugging.
    // -----------------------------------------------------------------
    logic [NUM_BLOCKS-1:0] block_cout;

    // -----------------------------------------------------------------
    // External carry input
    // -----------------------------------------------------------------
    assign block_carry[0] = cin;

    // -----------------------------------------------------------------
    // Hierarchical Group Carry Lookahead
    //
    // C(block+1) = GG(block) + PG(block)*C(block)
    // -----------------------------------------------------------------
    genvar k;

    generate

        for (k = 0; k < NUM_BLOCKS; k++) begin : GEN_GROUP_CARRY

            assign block_carry[k+1] =
                  group_g[k]
                | (group_p[k] & block_carry[k]);

        end

    endgenerate


    // -----------------------------------------------------------------
    // Instantiate 4-bit CLA blocks
    // -----------------------------------------------------------------
    genvar i;

    generate

        for (i = 0; i < NUM_BLOCKS; i++) begin : GEN_CLA_BLOCK

            cla_4bit u_cla_4bit (

                .a (
                    a[(i*4) +: 4]
                ),

                .b (
                    b[(i*4) +: 4]
                ),

                .cin (
                    block_carry[i]
                ),

                .sum (
                    sum[(i*4) +: 4]
                ),

                .cout (
                    block_cout[i]
                ),

                .group_p (
                    group_p[i]
                ),

                .group_g (
                    group_g[i]
                )

            );

        end

    endgenerate


    // -----------------------------------------------------------------
    // Final carry output
    // -----------------------------------------------------------------
    assign cout = block_carry[NUM_BLOCKS];

endmodule