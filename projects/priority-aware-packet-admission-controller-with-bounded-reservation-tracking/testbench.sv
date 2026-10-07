// ==========================================================
// REFERENCE MODEL (provided - do not modify)
// ==========================================================
module packet_admission_controller_ref #(
    parameter MAX_ACTIVE = 4
) (
    input  logic       clk,
    input  logic       rst_n,
    input  logic       req_valid,
    output logic       req_ready,
    input  logic [3:0] req_id,
    input  logic [1:0] req_class,
    output logic       resp_valid,
    input  logic       resp_ready,
    output logic [3:0] resp_id,
    output logic       resp_accept,
    output logic [2:0] queue_level,
    output logic       overflow
);

    logic [2:0] active_count;
    logic [3:0] resp_id_reg;
    logic resp_accept_reg;
    logic overflow_reg;
    logic resp_valid_reg;

    assign req_ready = !resp_valid_reg;
    assign resp_valid = resp_valid_reg;
    assign resp_id = resp_id_reg;
    assign resp_accept = resp_accept_reg;
    assign overflow = overflow_reg;
    assign queue_level = active_count;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            active_count <= 3'd0;
            resp_id_reg <= 4'd0;
            resp_accept_reg <= 1'b0;
            overflow_reg <= 1'b0;
            resp_valid_reg <= 1'b0;
        end
        else begin
            if (resp_valid_reg && resp_ready) begin
                resp_valid_reg <= 1'b0;
                if (resp_accept_reg) begin
                    active_count <= active_count - 3'd1;
                end
            end

            if (req_valid && req_ready) begin
                resp_id_reg <= req_id;
                resp_valid_reg <= 1'b1;
                if (active_count < MAX_ACTIVE) begin
                    resp_accept_reg <= 1'b1;
                    overflow_reg <= 1'b0;
                    active_count <= active_count + 3'd1;
                end
                else begin
                    resp_accept_reg <= 1'b0;
                    overflow_reg <= 1'b1;
                end
            end
        end
    end

endmodule

// ==========================================================
// INTERFACE (provided — do not modify)
// ==========================================================
interface packet_admission_controller_if;
  logic clk;
  logic rst_n;
  logic req_valid;
  logic req_ready;
  logic [3:0] req_id;
  logic [1:0] req_class;
  logic resp_valid;
  logic resp_ready;
  logic [3:0] resp_id;
  logic resp_accept;
  logic [2:0] queue_level;
  logic overflow;

  logic req_ready_ref;
  logic resp_valid_ref;
  logic [3:0] resp_id_ref;
  logic resp_accept_ref;
  logic [2:0] queue_level_ref;
  logic overflow_ref;
endinterface

// ==========================================================
// TRANSACTION
// ==========================================================
class packet_admission_controller_transaction;
  rand logic req_valid;
  rand logic [3:0] req_id;
  rand logic [1:0] req_class;
  rand logic resp_ready;

  logic req_ready;
  logic resp_valid;
  logic [3:0] resp_id;
  logic resp_accept;
  logic [2:0] queue_level;
  logic overflow;

  logic req_ready_ref;
  logic resp_valid_ref;
  logic [3:0] resp_id_ref;
  logic resp_accept_ref;
  logic [2:0] queue_level_ref;
  logic overflow_ref;

  constraint c_stimulus {
    req_valid dist {0:/20, 1:/80};
    resp_ready dist {0:/30, 1:/70};
  }

  function new();
  endfunction

  function string sprint();
    return $sformatf("req_valid: %b, req_id: %0h, req_class: %0h, resp_ready: %b", req_valid, req_id, req_class, resp_ready);
  endfunction
endclass

// ==========================================================
// GENERATOR
// ==========================================================
class packet_admission_controller_generator;
  mailbox #(packet_admission_controller_transaction) gen2drv;
  int unsigned num_transactions;

  function new(mailbox #(packet_admission_controller_transaction) gen2drv, int unsigned num_transactions = 8);
    this.gen2drv = gen2drv;
    this.num_transactions = num_transactions;
  endfunction

  task run();
    packet_admission_controller_transaction tx;
    for (int i = 0; i < num_transactions; i++) begin
      tx = new();
      if (!tx.randomize()) begin
        $fatal(1, "Randomization failed in generator.");
      end
      gen2drv.put(tx);
    end
  endtask
endclass

// ==========================================================
// DRIVER
// ==========================================================
class packet_admission_controller_driver;
  virtual packet_admission_controller_if vif;
  mailbox #(packet_admission_controller_transaction) gen2drv;
  int unsigned num_transactions;

  function new(virtual packet_admission_controller_if vif, mailbox #(packet_admission_controller_transaction) gen2drv, int unsigned num_transactions = 8);
    this.vif = vif;
    this.gen2drv = gen2drv;
    this.num_transactions = num_transactions;
  endfunction

  task reset_signals();
    vif.req_valid <= 1'b0;
    vif.req_id <= 4'b0;
    vif.req_class <= 2'b0;
    vif.resp_ready <= 1'b0;
  endtask

  task run();
    packet_admission_controller_transaction tx;
    reset_signals();
    wait(vif.rst_n);
    
    repeat(num_transactions) begin
      gen2drv.get(tx);
      @(posedge vif.clk);
      vif.req_valid <= tx.req_valid;
      vif.req_id <= tx.req_id;
      vif.req_class <= tx.req_class;
      vif.resp_ready <= tx.resp_ready;
    end
    
    @(posedge vif.clk);
    reset_signals();
  endtask
endclass

// ==========================================================
// MONITOR
// ==========================================================
class packet_admission_controller_monitor;
  virtual packet_admission_controller_if vif;
  mailbox #(packet_admission_controller_transaction) mon2sb;
  int unsigned num_transactions;

  function new(virtual packet_admission_controller_if vif, mailbox #(packet_admission_controller_transaction) mon2sb, int unsigned num_transactions = 8);
    this.vif = vif;
    this.mon2sb = mon2sb;
    this.num_transactions = num_transactions;
  endfunction

  task run();
    packet_admission_controller_transaction tx;
    wait(vif.rst_n);
    
    repeat(num_transactions) begin
      @(posedge vif.clk);
      tx = new();
      
      tx.req_valid = vif.req_valid;
      tx.req_id = vif.req_id;
      tx.req_class = vif.req_class;
      tx.resp_ready = vif.resp_ready;
      
      tx.req_ready = vif.req_ready;
      tx.resp_valid = vif.resp_valid;
      tx.resp_id = vif.resp_id;
      tx.resp_accept = vif.resp_accept;
      tx.queue_level = vif.queue_level;
      tx.overflow = vif.overflow;
      
      tx.req_ready_ref = vif.req_ready_ref;
      tx.resp_valid_ref = vif.resp_valid_ref;
      tx.resp_id_ref = vif.resp_id_ref;
      tx.resp_accept_ref = vif.resp_accept_ref;
      tx.queue_level_ref = vif.queue_level_ref;
      tx.overflow_ref = vif.overflow_ref;
      
      mon2sb.put(tx);
    end
  endtask
endclass

// ==========================================================
// SCOREBOARD
// ==========================================================
class packet_admission_controller_scoreboard;
  mailbox #(packet_admission_controller_transaction) mon2sb;
  int unsigned checked_count;
  int unsigned mismatch_count;
  int unsigned num_transactions;

  function new(mailbox #(packet_admission_controller_transaction) mon2sb, int unsigned num_transactions = 8);
    this.mon2sb = mon2sb;
    this.num_transactions = num_transactions;
    this.checked_count = 0;
    this.mismatch_count = 0;
  endfunction

  task run();
    packet_admission_controller_transaction tx;
    
    repeat(num_transactions) begin
      mon2sb.get(tx);
      
      if (tx.req_ready !== tx.req_ready_ref ||
          tx.resp_valid !== tx.resp_valid_ref ||
          tx.resp_id !== tx.resp_id_ref ||
          tx.resp_accept !== tx.resp_accept_ref ||
          tx.queue_level !== tx.queue_level_ref ||
          tx.overflow !== tx.overflow_ref) begin
        
        $error("Scoreboard mismatch detected!");
        $display("DUT Outputs: req_ready=%b, resp_valid=%b, resp_id=%0h, resp_accept=%b, queue_level=%0d, overflow=%b",
                 tx.req_ready, tx.resp_valid, tx.resp_id, tx.resp_accept, tx.queue_level, tx.overflow);
        $display("REF Outputs: req_ready=%b, resp_valid=%b, resp_id=%0h, resp_accept=%b, queue_level=%0d, overflow=%b",
                 tx.req_ready_ref, tx.resp_valid_ref, tx.resp_id_ref, tx.resp_accept_ref, tx.queue_level_ref, tx.overflow_ref);
        mismatch_count++;
      end
      checked_count++;
    end
  endtask
endclass

// ==========================================================
// COVERAGECOLLECTOR
// ==========================================================
class packet_admission_controller_coverage_collector;
  virtual packet_admission_controller_if vif;
  int unsigned num_transactions;

  covergroup cg;
    option.per_instance = 1;
    
    req_valid_cp: coverpoint vif.req_valid {
      bins inactive = {0};
      bins active = {1};
    }
    
    queue_level_cp: coverpoint vif.queue_level {
      bins empty = {0};
      bins partial = {[1:3]};
      bins full = {4};
    }
    
    overflow_cp: coverpoint vif.overflow {
      bins no_overflow = {0};
      bins overflow_occurred = {1};
    }
    
    req_val_x_queue_lvl: cross req_valid_cp, queue_level_cp;
  endgroup

  function new(virtual packet_admission_controller_if vif, int unsigned num_transactions = 8);
    this.vif = vif;
    this.num_transactions = num_transactions;
    cg = new();
  endfunction

  task run();
    wait(vif.rst_n);
    repeat (num_transactions) begin
      @(posedge vif.clk);
      cg.sample();
    end
  endtask
endclass

// ==========================================================
// AGENT
// ==========================================================
class packet_admission_controller_agent;
  virtual packet_admission_controller_if vif;
  mailbox #(packet_admission_controller_transaction) gen2drv;
  mailbox #(packet_admission_controller_transaction) mon2sb;
  packet_admission_controller_generator gen;
  packet_admission_controller_driver drv;
  packet_admission_controller_monitor mon;

  function new(virtual packet_admission_controller_if vif, mailbox #(packet_admission_controller_transaction) gen2drv, mailbox #(packet_admission_controller_transaction) mon2sb, int unsigned num_transactions = 8);
    this.vif = vif;
    this.gen2drv = gen2drv;
    this.mon2sb = mon2sb;
    
    gen = new(gen2drv, num_transactions);
    drv = new(vif, gen2drv, num_transactions);
    mon = new(vif, mon2sb, num_transactions);
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
class packet_admission_controller_environment;
  virtual packet_admission_controller_if vif;
  mailbox #(packet_admission_controller_transaction) gen2drv;
  mailbox #(packet_admission_controller_transaction) mon2sb;
  packet_admission_controller_agent agent;
  packet_admission_controller_scoreboard sb;
  packet_admission_controller_coverage_collector cov;

  function new(virtual packet_admission_controller_if vif, int unsigned num_transactions = 8);
    this.vif = vif;
    gen2drv = new();
    mon2sb = new();
    
    agent = new(vif, gen2drv, mon2sb, num_transactions);
    sb = new(mon2sb, num_transactions);
    cov = new(vif, num_transactions);
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
class packet_admission_controller_test;
  virtual packet_admission_controller_if vif;
  packet_admission_controller_environment env;
  int unsigned num_transactions;

  function new(virtual packet_admission_controller_if vif, int unsigned num_transactions = 8);
    this.vif = vif;
    this.num_transactions = num_transactions;
    env = new(vif, num_transactions);
  endfunction

  task run();
    fork
      env.run();
      begin
        #(num_transactions * 20 + 100);
        $display("Timeout hit - Ending test");
      end
    join_any
    disable fork;
  endtask
endclass

// ==========================================================
// TOP-LEVEL TESTBENCH (provided — do not modify)
// ==========================================================
`timescale 1ns/1ps
module tb_packet_admission_controller;
  packet_admission_controller_if vif();
  packet_admission_controller_test test;

  packet_admission_controller dut (
    .clk(vif.clk),
    .rst_n(vif.rst_n),
    .req_valid(vif.req_valid),
    .req_ready(vif.req_ready),
    .req_id(vif.req_id),
    .req_class(vif.req_class),
    .resp_valid(vif.resp_valid),
    .resp_ready(vif.resp_ready),
    .resp_id(vif.resp_id),
    .resp_accept(vif.resp_accept),
    .queue_level(vif.queue_level),
    .overflow(vif.overflow)
  );

  packet_admission_controller_ref ref_model (
    .clk(vif.clk),
    .rst_n(vif.rst_n),
    .req_valid(vif.req_valid),
    .req_ready(vif.req_ready_ref),
    .req_id(vif.req_id),
    .req_class(vif.req_class),
    .resp_valid(vif.resp_valid_ref),
    .resp_ready(vif.resp_ready),
    .resp_id(vif.resp_id_ref),
    .resp_accept(vif.resp_accept_ref),
    .queue_level(vif.queue_level_ref),
    .overflow(vif.overflow_ref)
  );

  initial begin
    vif.clk = 1'b0;
    forever #5 vif.clk = ~vif.clk;
  end

  initial begin
    automatic int unsigned num_transactions = 1000;
    $dumpfile("sim.vcd");
    $dumpvars(0, tb_packet_admission_controller);
    vif.rst_n = 1'b0;
    #20;
    vif.rst_n = 1'b1;
    test = new(vif, num_transactions);
    test.run();
    $finish;
  end
endmodule