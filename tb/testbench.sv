`timescale 1ns/1ps

//============================================================
// PARAMETERIZED N-BIT CLA
// CLASS-BASED VERIFICATION TESTBENCH
//============================================================


//============================================================
// INTERFACE
//============================================================
interface cla_if #(parameter int N = 8);

    logic [N-1:0] a;
    logic [N-1:0] b;
    logic         cin;

    logic [N-1:0] sum;
    logic         cout;

    logic         clk;

endinterface


//============================================================
// TRANSACTION
//============================================================
class cla_transaction #(parameter int N = 8);

    // ---------------------------------------------------------
    // Random stimulus
    // ---------------------------------------------------------
    rand logic [N-1:0] a;
    rand logic [N-1:0] b;
    rand logic         cin;

    // ---------------------------------------------------------
    // Observed DUT output
    // ---------------------------------------------------------
    logic [N-1:0] sum;
    logic         cout;


    constraint valid_cin {

        cin inside {1'b0, 1'b1};

    }


    function new();

        a    = '0;
        b    = '0;
        cin  = 1'b0;
        sum  = '0;
        cout = 1'b0;

    endfunction


    function automatic logic [N:0] expected_result();

        expected_result =
            {1'b0, a} +
            {1'b0, b} +
            cin;

    endfunction


    function void display(string tag = "TRANSACTION");

        logic [N:0] expected;

        expected = expected_result();

        $display(
            "[%s] A=%0h B=%0h CIN=%0b | EXPECTED={%0b,%0h} ACTUAL={%0b,%0h}",
            tag,
            a,
            b,
            cin,
            expected[N],
            expected[N-1:0],
            cout,
            sum
        );

    endfunction

endclass


//============================================================
// GENERATOR
//============================================================
class cla_generator #(parameter int N = 8);

    mailbox #(cla_transaction #(N)) gen2drv;

    int num_transactions;


    function new(
        mailbox #(cla_transaction #(N)) gen2drv,
        int num_transactions
    );

        this.gen2drv = gen2drv;
        this.num_transactions = num_transactions;

    endfunction


    task run();

        cla_transaction #(N) tr;

        for (int i = 0; i < num_transactions; i++) begin

            tr = new();

            if (!tr.randomize()) begin

                $fatal(
                    1,
                    "[GENERATOR] Randomization failed at transaction %0d",
                    i + 1
                );

            end

            gen2drv.put(tr);

        end

        $display(
            "[GENERATOR] Generated %0d random transactions",
            num_transactions
        );

    endtask

endclass


//============================================================
// DRIVER
//============================================================
class cla_driver #(parameter int N = 8);

    virtual cla_if #(N) vif;

    mailbox #(cla_transaction #(N)) gen2drv;


    function new(
        virtual cla_if #(N) vif,
        mailbox #(cla_transaction #(N)) gen2drv
    );

        this.vif = vif;
        this.gen2drv = gen2drv;

    endfunction


    task run();

        cla_transaction #(N) tr;

        forever begin

            gen2drv.get(tr);

            @(negedge vif.clk);

            vif.a   <= tr.a;
            vif.b   <= tr.b;
            vif.cin <= tr.cin;

        end

    endtask

endclass


//============================================================
// MONITOR
//============================================================
class cla_monitor #(parameter int N = 8);

    virtual cla_if #(N) vif;

    mailbox #(cla_transaction #(N)) mon2scb;


    function new(
        virtual cla_if #(N) vif,
        mailbox #(cla_transaction #(N)) mon2scb
    );

        this.vif = vif;
        this.mon2scb = mon2scb;

    endfunction


    task run();

        cla_transaction #(N) tr;

        forever begin

            @(posedge vif.clk);

            #1;

            tr = new();

            tr.a   = vif.a;
            tr.b   = vif.b;
            tr.cin = vif.cin;

            tr.sum  = vif.sum;
            tr.cout = vif.cout;

            mon2scb.put(tr);

        end

    endtask

endclass


//============================================================
// SCOREBOARD
//============================================================
class cla_scoreboard #(parameter int N = 8);

    mailbox #(cla_transaction #(N)) mon2scb;

    int pass_count;
    int fail_count;


    function new(
        mailbox #(cla_transaction #(N)) mon2scb
    );

        this.mon2scb = mon2scb;

        pass_count = 0;
        fail_count = 0;

    endfunction


    task run();

        cla_transaction #(N) tr;

        logic [N:0] expected;

        forever begin

            mon2scb.get(tr);

            expected =
                {1'b0, tr.a} +
                {1'b0, tr.b} +
                tr.cin;


            if ({tr.cout, tr.sum} === expected) begin

                pass_count++;

                $display(
                    "[SCOREBOARD][PASS] A=%0h B=%0h CIN=%0b | EXPECTED={%0b,%0h} GOT={%0b,%0h}",
                    tr.a,
                    tr.b,
                    tr.cin,
                    expected[N],
                    expected[N-1:0],
                    tr.cout,
                    tr.sum
                );

            end
            else begin

                fail_count++;

                $error(
                    "[SCOREBOARD][FAIL] A=%0h B=%0h CIN=%0b | EXPECTED={%0b,%0h} GOT={%0b,%0h}",
                    tr.a,
                    tr.b,
                    tr.cin,
                    expected[N],
                    expected[N-1:0],
                    tr.cout,
                    tr.sum
                );

            end

        end

    endtask


    function void report();

        $display("");
        $display("============================================================");
        $display("                    SCOREBOARD REPORT");
        $display("============================================================");
        $display("PASS COUNT : %0d", pass_count);
        $display("FAIL COUNT : %0d", fail_count);
        $display("TOTAL      : %0d", pass_count + fail_count);
        $display("============================================================");

    endfunction

endclass


//============================================================
// FUNCTIONAL COVERAGE
//============================================================
class cla_coverage #(parameter int N = 8);

    virtual cla_if #(N) vif;


    covergroup cla_cg;

        cp_a : coverpoint vif.a {

            bins zero = {0};

            bins max = {(2**N)-1};

            bins low = {
                [1:(2**(N/2))-1]
            };

            bins high = {
                [2**(N/2):(2**N)-2]
            };

        }


        cp_b : coverpoint vif.b {

            bins zero = {0};

            bins max = {(2**N)-1};

            bins low = {
                [1:(2**(N/2))-1]
            };

            bins high = {
                [2**(N/2):(2**N)-2]
            };

        }


        cp_cin : coverpoint vif.cin {

            bins zero = {0};

            bins one = {1};

        }


        cp_cout : coverpoint vif.cout {

            bins zero = {0};

            bins one = {1};

        }


        carry_behavior :
        cross cp_cin, cp_cout;

    endgroup


    function new(
        virtual cla_if #(N) vif
    );

        this.vif = vif;

        cla_cg = new();

    endfunction


    task run();

        forever begin

            @(posedge vif.clk);

            #1;

            cla_cg.sample();

        end

    endtask


    function void report();

        $display("");
        $display("============================================================");
        $display("                    COVERAGE REPORT");
        $display("============================================================");
        $display(
            "FUNCTIONAL COVERAGE : %0.2f%%",
            cla_cg.get_coverage()
        );
        $display("============================================================");

    endfunction

endclass


//============================================================
// ENVIRONMENT
//============================================================
class cla_environment #(parameter int N = 8);

    virtual cla_if #(N) vif;

    mailbox #(cla_transaction #(N)) gen2drv;
    mailbox #(cla_transaction #(N)) mon2scb;

    cla_generator  #(N) generator;
    cla_driver     #(N) driver;
    cla_monitor    #(N) monitor;
    cla_scoreboard #(N) scoreboard;
    cla_coverage   #(N) coverage;

    int num_transactions;


    function new(
        virtual cla_if #(N) vif,
        int num_transactions
    );

        this.vif = vif;
        this.num_transactions = num_transactions;

        gen2drv = new();
        mon2scb = new();

        generator =
            new(
                gen2drv,
                num_transactions
            );

        driver =
            new(
                vif,
                gen2drv
            );

        monitor =
            new(
                vif,
                mon2scb
            );

        scoreboard =
            new(
                mon2scb
            );

        coverage =
            new(
                vif
            );

    endfunction


    task run();

        fork

            generator.run();

            driver.run();

            monitor.run();

            scoreboard.run();

            coverage.run();

        join_none

    endtask


    task wait_for_completion();

        wait (
            (scoreboard.pass_count +
             scoreboard.fail_count)
            ==
            num_transactions
        );

        #10;

    endtask


    function void report();

        scoreboard.report();

        coverage.report();

    endfunction

endclass


//============================================================
// TESTBENCH
//============================================================
module cla_adder_tb;

    parameter int N = 8;

    parameter int NUM_RANDOM_TESTS = 500;


    //========================================================
    // CLOCK
    //========================================================
    logic clk;

    initial begin

        clk = 1'b0;

        forever begin

            #5;

            clk = ~clk;

        end

    end


    //========================================================
    // INTERFACE
    //========================================================
    cla_if #(N) vif();

    assign vif.clk = clk;


    //========================================================
    // DUT
    //========================================================
    cla_adder #(
        .N(N)
    ) dut (

        .a    (vif.a),
        .b    (vif.b),
        .cin  (vif.cin),
        .sum  (vif.sum),
        .cout (vif.cout)

    );


    //========================================================
    // REFERENCE MODEL SIGNAL
    //========================================================
    logic [N:0] reference_result;


    always_comb begin

        reference_result =
            {1'b0, vif.a} +
            {1'b0, vif.b} +
            vif.cin;

    end


    //========================================================
    // ASSERTION 1
    // COMPLETE FUNCTIONAL CORRECTNESS
    //========================================================
    property p_cla_correct;

        @(posedge clk)
        ({vif.cout, vif.sum} == reference_result);

    endproperty


    a_cla_correct :
    assert property (p_cla_correct)

    else begin

        $error(
            "[ASSERTION FAILED] CLA mismatch | A=%0h B=%0h CIN=%0b | EXPECTED={%0b,%0h} GOT={%0b,%0h}",
            vif.a,
            vif.b,
            vif.cin,
            reference_result[N],
            reference_result[N-1:0],
            vif.cout,
            vif.sum
        );

    end


    //========================================================
    // ASSERTION 2
    // ZERO ADDITION
    //========================================================
    property p_zero_addition;

        @(posedge clk)

        (
            (vif.a == '0) &&
            (vif.b == '0) &&
            (vif.cin == 1'b0)
        )

        |->
        (
            (vif.sum == '0) &&
            (vif.cout == 1'b0)
        );

    endproperty


    a_zero_addition :
    assert property (p_zero_addition)

    else begin

        $error(
            "[ASSERTION FAILED] 0 + 0 + 0 != 0"
        );

    end


    //========================================================
    // ASSERTION 3
    // A + 0 = A
    //========================================================
    property p_a_plus_zero;

        @(posedge clk)

        (
            (vif.b == '0) &&
            (vif.cin == 1'b0)
        )

        |->
        (
            (vif.sum == vif.a) &&
            (vif.cout == 1'b0)
        );

    endproperty


    a_a_plus_zero :
    assert property (p_a_plus_zero)

    else begin

        $error(
            "[ASSERTION FAILED] A + 0 != A"
        );

    end


    //========================================================
    // ASSERTION 4
    // 0 + B = B
    //========================================================
    property p_zero_plus_b;

        @(posedge clk)

        (
            (vif.a == '0) &&
            (vif.cin == 1'b0)
        )

        |->
        (
            (vif.sum == vif.b) &&
            (vif.cout == 1'b0)
        );

    endproperty


    a_zero_plus_b :
    assert property (p_zero_plus_b)

    else begin

        $error(
            "[ASSERTION FAILED] 0 + B != B"
        );

    end


    //========================================================
    // ASSERTION 5
    // MAX + MAX + 1
    //========================================================
    property p_maximum_addition;

        @(posedge clk)

        (
            (vif.a == {N{1'b1}}) &&
            (vif.b == {N{1'b1}}) &&
            (vif.cin == 1'b1)
        )

        |->
        (
            (vif.sum == {N{1'b1}}) &&
            (vif.cout == 1'b1)
        );

    endproperty


    a_maximum_addition :
    assert property (p_maximum_addition)

    else begin

        $error(
            "[ASSERTION FAILED] MAX + MAX + 1 failed"
        );

    end


    //========================================================
    // ENVIRONMENT
    //========================================================
    cla_environment #(N) env;


    //========================================================
    // DIRECTED TEST TASK
    //========================================================
    task automatic directed_test(
        input logic [N-1:0] test_a,
        input logic [N-1:0] test_b,
        input logic         test_cin
    );

        @(negedge clk);

        vif.a   = test_a;
        vif.b   = test_b;
        vif.cin = test_cin;

        @(posedge clk);

        #1;

        $display(
            "[DIRECTED] A=%0h B=%0h CIN=%0b | SUM=%0h COUT=%0b",
            vif.a,
            vif.b,
            vif.cin,
            vif.sum,
            vif.cout
        );

    endtask


    //========================================================
    // MAIN TEST
    //========================================================
    initial begin

        logic [N-1:0] alternating_a;
        logic [N-1:0] alternating_b;


        // ----------------------------------------------------
        // Parameter validation
        // ----------------------------------------------------
        if (N < 4) begin

            $fatal(
                1,
                "TESTBENCH ERROR: N must be >= 4."
            );

        end


        if ((N % 4) != 0) begin

            $fatal(
                1,
                "TESTBENCH ERROR: N must be a multiple of 4."
            );

        end


        // ----------------------------------------------------
        // Initial values
        // ----------------------------------------------------
        vif.a   = '0;
        vif.b   = '0;
        vif.cin = 1'b0;


        // ----------------------------------------------------
        // Create alternating patterns
        // ----------------------------------------------------
        alternating_a = '0;
        alternating_b = '0;

        for (int i = 0; i < N; i++) begin

            if ((i % 2) == 0) begin

                alternating_a[i] = 1'b1;
                alternating_b[i] = 1'b0;

            end
            else begin

                alternating_a[i] = 1'b0;
                alternating_b[i] = 1'b1;

            end

        end


        // ----------------------------------------------------
        // Environment
        // ----------------------------------------------------
        env = new(
            vif,
            NUM_RANDOM_TESTS
        );


        //====================================================
        // HEADER
        //====================================================
        $display("");
        $display("============================================================");
        $display("        PARAMETERIZED HIERARCHICAL CLA VERIFICATION");
        $display("============================================================");
        $display("CLA WIDTH       : %0d bits", N);
        $display("CLA BLOCK SIZE  : 4 bits");
        $display("CLA BLOCKS      : %0d", N / 4);
        $display("RANDOM TESTS    : %0d", NUM_RANDOM_TESTS);
        $display("============================================================");
        $display("");


        //====================================================
        // DIRECTED TESTS
        //====================================================
        $display("");
        $display("------------------------------------------------------------");
        $display("                    DIRECTED TESTS");
        $display("------------------------------------------------------------");


        // 0 + 0
        directed_test(
            '0,
            '0,
            1'b0
        );


        // 1 + 1
        directed_test(
            {{(N-1){1'b0}}, 1'b1},
            {{(N-1){1'b0}}, 1'b1},
            1'b0
        );


        // MAX + 0
        directed_test(
            {N{1'b1}},
            '0,
            1'b0
        );


        // 0 + MAX
        directed_test(
            '0,
            {N{1'b1}},
            1'b0
        );


        // MAX + MAX
        directed_test(
            {N{1'b1}},
            {N{1'b1}},
            1'b0
        );


        // MAX + MAX + 1
        directed_test(
            {N{1'b1}},
            {N{1'b1}},
            1'b1
        );


        // Alternating patterns
        directed_test(
            alternating_a,
            alternating_b,
            1'b0
        );


        // Alternating patterns + CIN
        directed_test(
            alternating_a,
            alternating_b,
            1'b1
        );


        // Carry propagation case
        directed_test(
            {N{1'b1}},
            {{(N-1){1'b0}}, 1'b1},
            1'b0
        );


        //====================================================
        // RANDOM TESTING
        //====================================================
        $display("");
        $display("------------------------------------------------------------");
        $display("                CONSTRAINED RANDOM TESTING");
        $display("------------------------------------------------------------");


        env.run();


        //====================================================
        // WAIT FOR SCOREBOARD
        //====================================================
        env.wait_for_completion();


        //====================================================
        // REPORT
        //====================================================
        env.report();


        //====================================================
        // FINAL RESULT
        //====================================================
        if (env.scoreboard.fail_count == 0) begin

            $display("");
            $display("============================================================");
            $display("                    TEST PASSED");
            $display("============================================================");
            $display(
                "All %0d random transactions passed.",
                NUM_RANDOM_TESTS
            );
            $display("============================================================");
            $display("");

        end
        else begin

            $display("");
            $display("============================================================");
            $display("                    TEST FAILED");
            $display("============================================================");
            $display(
                "Passed : %0d",
                env.scoreboard.pass_count
            );
            $display(
                "Failed : %0d",
                env.scoreboard.fail_count
            );
            $display("============================================================");
            $display("");

        end


        #20;

        $finish;

    end


    //========================================================
    // WAVEFORM
    //========================================================
    initial begin

        $dumpfile("cla_adder.vcd");

        $dumpvars(0, cla_adder_tb);

    end

endmodule