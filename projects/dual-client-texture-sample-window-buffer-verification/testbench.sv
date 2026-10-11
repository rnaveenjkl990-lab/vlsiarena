`timescale 1ns/1ps

// ==========================================================
// REFERENCE MODEL (provided - do not modify)
// ==========================================================
module tex_window_buffer_ref (
  input  logic       clk,
  input  logic       rst_n,
  input  logic       req0,
  input  logic       req1,
  input  logic [1:0] cmd0,
  input  logic [1:0] cmd1,
  input  logic [7:0] data_in0,
  input  logic [7:0] data_in1,
  output logic       gnt0,
  output logic       gnt1,
  output logic       resp_valid,
  output logic       resp_client,
  output logic [7:0] resp_data,
  output logic [2:0] buf_count,
  output logic       buf_full,
  output logic       buf_empty,
  output logic       err_pulse
);

  logic [7:0] ram [0:3];
  logic [1:0] head;
  logic [1:0] tail;
  logic [1:0] offset0;
  logic [1:0] offset1;
  logic       last_served;

  logic       serv_req;
  logic       serv_client;
  logic [1:0] serv_cmd;
  logic [7:0] serv_data;
  logic [1:0] serv_offset;

  always_comb begin
    gnt0 = 1'b0;
    gnt1 = 1'b0;
    if (req0 && req1) begin
      if (last_served == 1'b1) begin
        gnt0 = 1'b1;
      end else begin
        gnt1 = 1'b1;
      end
    end else if (req0) begin
      gnt0 = 1'b1;
    end else if (req1) begin
      gnt1 = 1'b1;
    end
  end

  assign serv_req    = gnt0 || gnt1;
  assign serv_client = gnt1;
  assign serv_cmd    = gnt1 ? cmd1 : cmd0;
  assign serv_data   = gnt1 ? data_in1 : data_in0;
  assign serv_offset = gnt1 ? offset1 : offset0;

  assign buf_full  = (buf_count == 3'd4);
  assign buf_empty = (buf_count == 3'd0);

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      head        <= 2'b00;
      tail        <= 2'b00;
      buf_count   <= 3'd0;
      offset0     <= 2'b00;
      offset1     <= 2'b00;
      last_served <= 1'b1;
      resp_valid  <= 1'b0;
      resp_client <= 1'b0;
      resp_data   <= 8'h00;
      err_pulse   <= 1'b0;
      ram[0]      <= 8'h00;
      ram[1]      <= 8'h00;
      ram[2]      <= 8'h00;
      ram[3]      <= 8'h00;
    end else begin
      resp_valid  <= 1'b0;
      err_pulse   <= 1'b0;
      resp_data   <= 8'h00;
      resp_client <= 1'b0;

      if (serv_req) begin
        last_served <= serv_client;

        case (serv_cmd)
          2'b00: begin
            if ({1'b0, serv_offset} < buf_count) begin
              resp_valid  <= 1'b1;
              resp_client <= serv_client;
              resp_data   <= ram[head + serv_offset];
            end else begin
              err_pulse   <= 1'b1;
            end
          end

          2'b01: begin
            if (buf_count < 3'd4) begin
              ram[tail] <= serv_data;
              tail      <= tail + 2'b01;
              buf_count <= buf_count + 3'd1;
            end else begin
              err_pulse <= 1'b1;
            end
          end

          2'b10: begin
            if (buf_count > 3'd0) begin
              head      <= head + 2'b01;
              buf_count <= buf_count - 3'd1;
            end else begin
              err_pulse <= 1'b1;
            end
          end

          2'b11: begin
            if (serv_client == 1'b0) begin
              offset0 <= serv_data[1:0];
            end else begin
              offset1 <= serv_data[1:0];
            end
          end

          default: begin
          end
        endcase
      end
    end
  end

endmodule

// ==========================================================
// INTERFACE (provided — do not modify)
// ==========================================================
interface tex_window_buffer_if;
  logic clk;
  logic rst_n;
  logic req0;
  logic req1;
  logic [1:0] cmd0;
  logic [1:0] cmd1;
  logic [7:0] data_in0;
  logic [7:0] data_in1;
  logic gnt0;
  logic gnt1;
  logic resp_valid;
  logic resp_client;
  logic [7:0] resp_data;
  logic [2:0] buf_count;
  logic buf_full;
  logic buf_empty;
  logic err_pulse;

  logic gnt0_ref;
  logic gnt1_ref;
  logic resp_valid_ref;
  logic resp_client_ref;
  logic [7:0] resp_data_ref;
  logic [2:0] buf_count_ref;
  logic buf_full_ref;
  logic buf_empty_ref;
  logic err_pulse_ref;
endinterface

// ==========================================================
// TRANSACTION
// ==========================================================
class tex_window_buffer_transaction;
  rand logic       req0;
  rand logic       req1;
  rand logic [1:0] cmd0;
  rand logic [1:0] cmd1;
  rand logic [7:0] data_in0;
  rand logic [7:0] data_in1;

  logic rst_n;

  logic       gnt0;
  logic       gnt1;
  logic       resp_valid;
  logic       resp_client;
  logic [7:0] resp_data;
  logic [2:0] buf_count;
  logic       buf_full;
  logic       buf_empty;
  logic       err_pulse;

  logic       gnt0_ref;
  logic       gnt1_ref;
  logic       resp_valid_ref;
  logic       resp_client_ref;
  logic [7:0] resp_data_ref;
  logic [2:0] buf_count_ref;
  logic       buf_full_ref;
  logic       buf_empty_ref;
  logic       err_pulse_ref;

  constraint c_req_dist {
    req0 dist {1'b1 := 65, 1'b0 := 35};
    req1 dist {1'b1 := 65, 1'b0 := 35};
  }

  constraint c_cmd_dist {
    cmd0 dist {2'b00 := 25, 2'b01 := 35, 2'b10 := 25, 2'b11 := 15};
    cmd1 dist {2'b00 := 25, 2'b01 := 35, 2'b10 := 25, 2'b11 := 15};
  }

  constraint c_setoff_data {
    if (cmd0 == 2'b11) data_in0[7:2] == 6'b0;
    if (cmd1 == 2'b11) data_in1[7:2] == 6'b0;
  }

  function new();
    req0      = 1'b0;
    req1      = 1'b0;
    cmd0      = 2'b00;
    cmd1      = 2'b00;
    data_in0  = 8'h00;
    data_in1  = 8'h00;
  endfunction

  function string sprint();
    return $sformatf(
      "req0=%0b cmd0=%0b d0=0x%02h | req1=%0b cmd1=%0b d1=0x%02h || gnt0=%0b(%0b) gnt1=%0b(%0b) cnt=%0d(%0d) resp_v=%0b(%0b) err=%0b(%0b)",
      req0, cmd0, data_in0, req1, cmd1, data_in1,
      gnt0, gnt0_ref, gnt1, gnt1_ref,
      buf_count, buf_count_ref,
      resp_valid, resp_valid_ref, err_pulse, err_pulse_ref
    );
  endfunction
endclass

// ==========================================================
// GENERATOR
// ==========================================================
class tex_window_buffer_generator;
  mailbox #(tex_window_buffer_transaction) gen2drv;
  int unsigned num_transactions;

  function new(mailbox #(tex_window_buffer_transaction) gen2drv, int unsigned num_transactions = 8);
    this.gen2drv = gen2drv;
    this.num_transactions = num_transactions;
  endfunction

  task push_directed(
    logic r0, logic r1,
    logic [1:0] c0, logic [1:0] c1,
    logic [7:0] d0, logic [7:0] d1
  );
    tex_window_buffer_transaction tr = new();
    tr.req0     = r0;
    tr.req1     = r1;
    tr.cmd0     = c0;
    tr.cmd1     = c1;
    tr.data_in0 = d0;
    tr.data_in1 = d1;
    gen2drv.put(tr);
  endtask

  task run();
    int generated_count = 0;
    tex_window_buffer_transaction tr;

    // -------------------------------------------------------------
    // PHASE 1: DIRECTED CONTRACT & ANTECEDENT SEQUENCES
    // -------------------------------------------------------------

    // S1: POP on empty buffer (expect err_pulse)
    push_directed(1'b1, 1'b0, 2'b10, 2'b00, 8'h00, 8'h00);
    generated_count++;

    // Contract: check_push_sample_client0
    // Drive PUSH 8'h3A for Client 0
    push_directed(1'b1, 1'b0, 2'b01, 2'b00, 8'h3A, 8'h00);
    generated_count++;

    // Contract: check_buf_occupancy_after_push
    // Drive IDLE cycle immediately following PUSH: req0=0, req1=0, cmd0=0, cmd1=0, d0=0, d1=0
    // Expected at this cycle: buf_count=1, buf_empty=0, buf_full=0
    push_directed(1'b0, 1'b0, 2'b00, 2'b00, 8'h00, 8'h00);
    generated_count++;

    // Contract: check_simultaneous_contention_client1_wins
    // Since last_served was updated to 0 (when Client 0 was served with 8'h3A),
    // next simultaneous contention will be WON by Client 1!
    // req0=1, req1=1, cmd0=2'b01, cmd1=2'b01, d0=8'h4B, d1=8'h5C -> gnt0=0, gnt1=1
    push_directed(1'b1, 1'b1, 2'b01, 2'b01, 8'h4B, 8'h5C);
    generated_count++;

    // IDLE observation cycle (buf_count is now 2)
    push_directed(1'b0, 1'b0, 2'b00, 2'b00, 8'h00, 8'h00);
    generated_count++;

    // Simultaneous contention where Client 0 wins (last_served is now 1)
    push_directed(1'b1, 1'b1, 2'b01, 2'b01, 8'h4B, 8'h5C);
    generated_count++;

    // Push 4th entry to make buffer full
    push_directed(1'b1, 1'b0, 2'b01, 2'b00, 8'h77, 8'h00);
    generated_count++;

    // IDLE observation cycle with full buffer (buf_count=4, buf_full=1)
    push_directed(1'b0, 1'b0, 2'b00, 2'b00, 8'h00, 8'h00);
    generated_count++;

    // S5: PUSH into full buffer (expect err_pulse)
    push_directed(1'b1, 1'b0, 2'b01, 2'b00, 8'hEE, 8'h00);
    generated_count++;

    // S3: SETOFF for Client 0 (offset 0) and Client 1 (offset 1)
    push_directed(1'b1, 1'b0, 2'b11, 2'b00, 8'h00, 8'h00);
    generated_count++;
    push_directed(1'b0, 1'b1, 2'b00, 2'b11, 8'h00, 8'h01);
    generated_count++;

    // READ for Client 0 and Client 1
    push_directed(1'b1, 1'b0, 2'b00, 2'b00, 8'h00, 8'h00);
    generated_count++;
    push_directed(1'b0, 1'b1, 2'b00, 2'b00, 8'h00, 8'h00);
    generated_count++;

    // Drain buffer via POPs and verify circular wrap-around
    repeat (4) begin
      push_directed(1'b1, 1'b0, 2'b10, 2'b00, 8'h00, 8'h00);
      generated_count++;
    end

    // IDLE observation cycle after buffer emptied (buf_count=0, buf_empty=1)
    push_directed(1'b0, 1'b0, 2'b00, 2'b00, 8'h00, 8'h00);
    generated_count++;

    // S4: Continuous alternating contention over multiple cycles
    repeat (6) begin
      push_directed(1'b1, 1'b1, 2'b01, 2'b01, 8'hA1, 8'hB2);
      generated_count++;
    end

    // Out-of-bounds READ: SETOFF to offset 2, then READ on empty buffer
    push_directed(1'b1, 1'b0, 2'b11, 2'b00, 8'h03, 8'h00);
    generated_count++;
    push_directed(1'b1, 1'b0, 2'b00, 2'b00, 8'h00, 8'h00);
    generated_count++;

    // -------------------------------------------------------------
    // PHASE 2: RANDOMIZED STIMULUS (for remaining transactions)
    // -------------------------------------------------------------
    while (generated_count < num_transactions) begin
      tr = new();
      if (!tr.randomize()) begin
        $fatal(1, "[GENERATOR] Randomization failure at count %0d", generated_count);
      end
      gen2drv.put(tr);
      generated_count++;
    end
  endtask
endclass

// ==========================================================
// DRIVER
// ==========================================================
class tex_window_buffer_driver;
  virtual tex_window_buffer_if vif;
  mailbox #(tex_window_buffer_transaction) gen2drv;
  int unsigned num_transactions;

  function new(virtual tex_window_buffer_if vif, mailbox #(tex_window_buffer_transaction) gen2drv, int unsigned num_transactions = 8);
    this.vif = vif;
    this.gen2drv = gen2drv;
    this.num_transactions = num_transactions;
  endfunction

  task reset_signals();
    vif.req0     <= 1'b0;
    vif.req1     <= 1'b0;
    vif.cmd0     <= 2'b00;
    vif.cmd1     <= 2'b00;
    vif.data_in0 <= 8'h00;
    vif.data_in1 <= 8'h00;
  endtask

  task run();
    tex_window_buffer_transaction tr;
    reset_signals();
    wait (vif.rst_n == 1'b1);

    for (int i = 0; i < num_transactions; i++) begin
      gen2drv.get(tr);
      @(negedge vif.clk);
      vif.req0     <= tr.req0;
      vif.req1     <= tr.req1;
      vif.cmd0     <= tr.cmd0;
      vif.cmd1     <= tr.cmd1;
      vif.data_in0 <= tr.data_in0;
      vif.data_in1 <= tr.data_in1;
    end

    @(negedge vif.clk);
    reset_signals();
  endtask
endclass

// ==========================================================
// MONITOR
// ==========================================================
class tex_window_buffer_monitor;
  virtual tex_window_buffer_if vif;
  mailbox #(tex_window_buffer_transaction) mon2sb;
  int unsigned num_transactions;

  function new(virtual tex_window_buffer_if vif, mailbox #(tex_window_buffer_transaction) mon2sb, int unsigned num_transactions = 8);
    this.vif = vif;
    this.mon2sb = mon2sb;
    this.num_transactions = num_transactions;
  endfunction

  task run();
    tex_window_buffer_transaction tr;
    wait (vif.rst_n == 1'b1);

    for (int i = 0; i < num_transactions; i++) begin
      @(posedge vif.clk);
      #1ps;
      tr = new();

      tr.rst_n          = vif.rst_n;
      tr.req0           = vif.req0;
      tr.req1           = vif.req1;
      tr.cmd0           = vif.cmd0;
      tr.cmd1           = vif.cmd1;
      tr.data_in0       = vif.data_in0;
      tr.data_in1       = vif.data_in1;

      tr.gnt0           = vif.gnt0;
      tr.gnt1           = vif.gnt1;
      tr.resp_valid     = vif.resp_valid;
      tr.resp_client    = vif.resp_client;
      tr.resp_data      = vif.resp_data;
      tr.buf_count      = vif.buf_count;
      tr.buf_full       = vif.buf_full;
      tr.buf_empty      = vif.buf_empty;
      tr.err_pulse      = vif.err_pulse;

      tr.gnt0_ref       = vif.gnt0_ref;
      tr.gnt1_ref       = vif.gnt1_ref;
      tr.resp_valid_ref = vif.resp_valid_ref;
      tr.resp_client_ref= vif.resp_client_ref;
      tr.resp_data_ref  = vif.resp_data_ref;
      tr.buf_count_ref  = vif.buf_count_ref;
      tr.buf_full_ref   = vif.buf_full_ref;
      tr.buf_empty_ref  = vif.buf_empty_ref;
      tr.err_pulse_ref  = vif.err_pulse_ref;

      mon2sb.put(tr);
    end
  endtask
endclass

// ==========================================================
// SCOREBOARD
// ==========================================================
class tex_window_buffer_scoreboard;
  mailbox #(tex_window_buffer_transaction) mon2sb;
  int unsigned checked_count;
  int unsigned mismatch_count;
  int unsigned num_transactions;
  int contract_index = 0;
  int contract_antecedent_count = 0;
  bit contract_armed [0:6];
  int contract_due [0:6];
  int contract_hold_remaining [0:6];

  function new(mailbox #(tex_window_buffer_transaction) mon2sb, int unsigned num_transactions = 8);
    this.mon2sb = mon2sb;
    this.num_transactions = num_transactions;
    this.checked_count = 0;
    this.mismatch_count = 0;
  endfunction

  task run();
    tex_window_buffer_transaction tr;
    for (int i = 0; i < num_transactions; i++) begin
      mon2sb.get(tr);

      // Invariant: mutual exclusion of grants
      if (tr.gnt0 && tr.gnt1) begin
        $error("[SCOREBOARD] Cycle %0d: Invariant violation: gnt0 and gnt1 asserted concurrently!", checked_count);
        mismatch_count++;
      end

      // Combinational grant check
      if (tr.gnt0 !== tr.gnt0_ref || tr.gnt1 !== tr.gnt1_ref) begin
        $error("[SCOREBOARD] Cycle %0d: Grant mismatch! DUT=(%0b,%0b) REF=(%0b,%0b)",
               checked_count, tr.gnt0, tr.gnt1, tr.gnt0_ref, tr.gnt1_ref);
        mismatch_count++;
      end

      // Buffer state check
      if (tr.buf_count !== tr.buf_count_ref ||
          tr.buf_full  !== tr.buf_full_ref  ||
          tr.buf_empty !== tr.buf_empty_ref) begin
        $error("[SCOREBOARD] Cycle %0d: Buffer status mismatch! count DUT=%0d REF=%0d, full DUT=%0b REF=%0b, empty DUT=%0b REF=%0b",
               checked_count, tr.buf_count, tr.buf_count_ref, tr.buf_full, tr.buf_full_ref, tr.buf_empty, tr.buf_empty_ref);
        mismatch_count++;
      end

      // Read response pipeline check
      if (tr.resp_valid !== tr.resp_valid_ref) begin
        $error("[SCOREBOARD] Cycle %0d: resp_valid mismatch! DUT=%0b REF=%0b",
               checked_count, tr.resp_valid, tr.resp_valid_ref);
        mismatch_count++;
      end

      if (tr.resp_valid_ref && (tr.resp_client !== tr.resp_client_ref || tr.resp_data !== tr.resp_data_ref)) begin
        $error("[SCOREBOARD] Cycle %0d: Response payload mismatch! client DUT=%0b REF=%0b, data DUT=0x%02h REF=0x%02h",
               checked_count, tr.resp_client, tr.resp_client_ref, tr.resp_data, tr.resp_data_ref);
        mismatch_count++;
      end

      // Error pulse check
      if (tr.err_pulse !== tr.err_pulse_ref) begin
        $error("[SCOREBOARD] Cycle %0d: err_pulse mismatch! DUT=%0b REF=%0b",
               checked_count, tr.err_pulse, tr.err_pulse_ref);
        mismatch_count++;
      end

      checked_count++;
    end
  endtask
endclass

// ==========================================================
// COVERAGECOLLECTOR
// ==========================================================
class tex_window_buffer_coverage_collector;
  virtual tex_window_buffer_if vif;
  int unsigned num_transactions;

  covergroup cg;
    option.per_instance = 1;

    cp_req0: coverpoint vif.req0 {
      bins deasserted = {1'b0};
      bins asserted   = {1'b1};
    }

    cp_req1: coverpoint vif.req1 {
      bins deasserted = {1'b0};
      bins asserted   = {1'b1};
    }

    cp_cmd0: coverpoint vif.cmd0 {
      bins cmd_read   = {2'b00};
      bins cmd_push   = {2'b01};
      bins cmd_pop    = {2'b10};
      bins cmd_setoff = {2'b11};
    }

    cp_cmd1: coverpoint vif.cmd1 {
      bins cmd_read   = {2'b00};
      bins cmd_push   = {2'b01};
      bins cmd_pop    = {2'b10};
      bins cmd_setoff = {2'b11};
    }

    cp_gnt0: coverpoint vif.gnt0 {
      bins no_grant = {1'b0};
      bins granted  = {1'b1};
    }

    cp_gnt1: coverpoint vif.gnt1 {
      bins no_grant = {1'b0};
      bins granted  = {1'b1};
    }

    cp_buf_count: coverpoint vif.buf_count {
      bins empty = {3'd0};
      bins part  = {[3'd1:3'd3]};
      bins full  = {3'd4};
    }

    cp_err_pulse: coverpoint vif.err_pulse {
      bins no_err = {1'b0};
      bins err    = {1'b1};
    }

    cross_contention: cross cp_req0, cp_req1, cp_gnt0, cp_gnt1;
    cross_fifo_ops:   cross cp_cmd0, cp_buf_count;
  endgroup

  function new(virtual tex_window_buffer_if vif, int unsigned num_transactions = 8);
    this.vif = vif;
    this.num_transactions = num_transactions;
    cg = new();
  endfunction

  task run();
    wait (vif.rst_n == 1'b1);
    repeat (num_transactions) begin
      @(posedge vif.clk);
      #1ps;
      cg.sample();
    end
  endtask
endclass

// ==========================================================
// AGENT
// ==========================================================
class tex_window_buffer_agent;
  virtual tex_window_buffer_if vif;
  mailbox #(tex_window_buffer_transaction) gen2drv;
  mailbox #(tex_window_buffer_transaction) mon2sb;
  tex_window_buffer_generator gen;
  tex_window_buffer_driver    drv;
  tex_window_buffer_monitor   mon;

  function new(virtual tex_window_buffer_if vif, mailbox #(tex_window_buffer_transaction) gen2drv, mailbox #(tex_window_buffer_transaction) mon2sb, int unsigned num_transactions = 8);
    this.vif      = vif;
    this.gen2drv  = gen2drv;
    this.mon2sb   = mon2sb;
    this.gen      = new(gen2drv, num_transactions);
    this.drv      = new(vif, gen2drv, num_transactions);
    this.mon      = new(vif, mon2sb, num_transactions);
  endfunction

  task run();
    fork
      gen.run();
      drv.run();
      mon.run();
    join
  endtask
endclass

// ==========================================================
// ENVIRONMENT
// ==========================================================
class tex_window_buffer_environment;
  virtual tex_window_buffer_if vif;
  mailbox #(tex_window_buffer_transaction) gen2drv;
  mailbox #(tex_window_buffer_transaction) mon2sb;
  tex_window_buffer_agent              agent;
  tex_window_buffer_scoreboard         sb;
  tex_window_buffer_coverage_collector cov;

  function new(virtual tex_window_buffer_if vif, int unsigned num_transactions = 8);
    this.vif     = vif;
    this.gen2drv = new();
    this.mon2sb  = new();
    this.agent   = new(vif, gen2drv, mon2sb, num_transactions);
    this.sb      = new(mon2sb, num_transactions);
    this.cov     = new(vif, num_transactions);
  endfunction

  task run();
    fork
      agent.run();
      sb.run();
      cov.run();
    join
  endtask
endclass

// ==========================================================
// TEST
// ==========================================================
class tex_window_buffer_test;
  virtual tex_window_buffer_if vif;
  tex_window_buffer_environment env;
  int unsigned num_transactions;

  function new(virtual tex_window_buffer_if vif, int unsigned num_transactions = 8);
    this.vif              = vif;
    this.num_transactions = num_transactions;
    this.env              = new(vif, num_transactions);
  endfunction

  task run();
    fork
      begin
        env.run();
      end
      begin
        #(num_transactions * 100ns + 2000ns);
        $fatal(1, "[TEST] Watchdog timeout triggered!");
      end
    join_any
    disable fork;

    if (env.sb.mismatch_count == 0 && env.sb.checked_count == num_transactions) begin
      $display("[TEST] All %0d transactions passed successfully with ZERO mismatches.", env.sb.checked_count);
    end else begin
      $error("[TEST] Finished with %0d errors across %0d checked transactions.",
             env.sb.mismatch_count, env.sb.checked_count);
    end
  endtask
endclass

// ==========================================================
// TOP-LEVEL TESTBENCH (provided — do not modify)
// ==========================================================
module tb_tex_window_buffer;
  tex_window_buffer_if vif();
  tex_window_buffer_test test;

  tex_window_buffer dut (
    .clk(vif.clk),
    .rst_n(vif.rst_n),
    .req0(vif.req0),
    .req1(vif.req1),
    .cmd0(vif.cmd0),
    .cmd1(vif.cmd1),
    .data_in0(vif.data_in0),
    .data_in1(vif.data_in1),
    .gnt0(vif.gnt0),
    .gnt1(vif.gnt1),
    .resp_valid(vif.resp_valid),
    .resp_client(vif.resp_client),
    .resp_data(vif.resp_data),
    .buf_count(vif.buf_count),
    .buf_full(vif.buf_full),
    .buf_empty(vif.buf_empty),
    .err_pulse(vif.err_pulse)
  );

  tex_window_buffer_ref ref_model (
    .clk(vif.clk),
    .rst_n(vif.rst_n),
    .req0(vif.req0),
    .req1(vif.req1),
    .cmd0(vif.cmd0),
    .cmd1(vif.cmd1),
    .data_in0(vif.data_in0),
    .data_in1(vif.data_in1),
    .gnt0(vif.gnt0_ref),
    .gnt1(vif.gnt1_ref),
    .resp_valid(vif.resp_valid_ref),
    .resp_client(vif.resp_client_ref),
    .resp_data(vif.resp_data_ref),
    .buf_count(vif.buf_count_ref),
    .buf_full(vif.buf_full_ref),
    .buf_empty(vif.buf_empty_ref),
    .err_pulse(vif.err_pulse_ref)
  );

  initial begin
    vif.clk = 1'b0;
    forever #5 vif.clk = ~vif.clk;
  end

  initial begin
    automatic int unsigned num_transactions = 48;
    $dumpfile("sim.vcd");
    $dumpvars(0, tb_tex_window_buffer);
    vif.rst_n = 1'b0;
    #20;
    vif.rst_n = 1'b1;
    test = new(vif, num_transactions);
    test.run();
    $finish;
  end
endmodule