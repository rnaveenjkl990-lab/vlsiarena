`timescale 1ns/1ps
`include "uvm_macros.svh"

interface secure_boot_wdg_if;
  logic        clk;
  logic        rst_n;
  logic        wr_en;
  logic [1:0]  byte_en;
  logic [1:0]  addr;
  logic [15:0] wdata;
  logic        hb_strobe;
  logic        boot_complete;
  logic [15:0] rdata;
  logic        wdg_fault;
  logic        sys_reset_req;
endinterface

package secure_boot_wdg_pkg;
  import uvm_pkg::*;

  // -----------------------------------------------------------------
  // Transaction
  // -----------------------------------------------------------------
  class secure_boot_wdg_item extends uvm_sequence_item;
    `uvm_object_utils(secure_boot_wdg_item)

    rand logic        wr_en;
    rand logic [1:0]  byte_en;
    rand logic [1:0]  addr;
    rand logic [15:0] wdata;
    rand logic        hb_strobe;
    rand logic        boot_complete;

    logic [15:0] rdata;
    logic        wdg_fault;
    logic        sys_reset_req;

    function new(string name = "item");
      super.new(name);
    endfunction

    function string convert2string();
      return $sformatf(
        "wr_en=%b byte_en=%0b addr=%0h wdata=%0h hb=%b boot_done=%b | rdata=%0h fault=%b rst_req=%b",
        wr_en, byte_en, addr, wdata, hb_strobe, boot_complete,
        rdata, wdg_fault, sys_reset_req);
    endfunction
  endclass

  // -----------------------------------------------------------------
  // Sequencer
  // -----------------------------------------------------------------
  class secure_boot_wdg_sequencer extends uvm_sequencer #(secure_boot_wdg_item);
    `uvm_component_utils(secure_boot_wdg_sequencer)
    function new(string name = "sequencer", uvm_component parent = null);
      super.new(name, parent);
    endfunction
  endclass

  // -----------------------------------------------------------------
  // Sequence
  // -----------------------------------------------------------------
  class secure_boot_wdg_sequence extends uvm_sequence #(secure_boot_wdg_item);
    `uvm_object_utils(secure_boot_wdg_sequence)

    function new(string name = "sequence");
      super.new(name);
    endfunction

    task body();
      secure_boot_wdg_item req;

      // S1 step 1 : reset condition
      req = secure_boot_wdg_item::type_id::create("req");
      start_item(req);
      req.wr_en = 0; req.byte_en = 2'b00; req.addr = 2'b00;
      req.wdata = 16'h0000; req.hb_strobe = 0; req.boot_complete = 0;
      finish_item(req);

      // S1 step 2 : config write (addr 0 = CFG, wdata 0x0001, byte_en = 3)
      req = secure_boot_wdg_item::type_id::create("req");
      start_item(req);
      req.wr_en = 1; req.byte_en = 2'b11; req.addr = 2'b00;
      req.wdata = 16'h0001; req.hb_strobe = 1; req.boot_complete = 0;
      finish_item(req);

      // S2 : heartbeat refresh
      req = secure_boot_wdg_item::type_id::create("req");
      start_item(req);
      req.wr_en = 0; req.byte_en = 2'b00; req.addr = 2'b00;
      req.wdata = 16'h0000; req.hb_strobe = 1; req.boot_complete = 0;
      finish_item(req);

      // S3 : boot complete disarm
      req = secure_boot_wdg_item::type_id::create("req");
      start_item(req);
      req.wr_en = 0; req.byte_en = 2'b00; req.addr = 2'b00;
      req.wdata = 16'h0000; req.hb_strobe = 0; req.boot_complete = 1;
      finish_item(req);

      // S4 : timeout expiration sequence
      repeat (6) begin
        req = secure_boot_wdg_item::type_id::create("req");
        start_item(req);
        req.wr_en = 0; req.byte_en = 2'b00; req.addr = 2'b00;
        req.wdata = 16'h0000; req.hb_strobe = 0; req.boot_complete = 0;
        finish_item(req);
      end
    endtask
  endclass

  // -----------------------------------------------------------------
  // Driver
  // -----------------------------------------------------------------
  class secure_boot_wdg_driver extends uvm_driver #(secure_boot_wdg_item);
    `uvm_component_utils(secure_boot_wdg_driver)

    virtual secure_boot_wdg_if vif;

    function new(string name = "driver", uvm_component parent = null);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if (!uvm_config_db#(virtual secure_boot_wdg_if)::get(this, "", "vif", vif))
        `uvm_fatal("NOVIF", "driver: missing vif")
    endfunction

    task run_phase(uvm_phase phase);
      secure_boot_wdg_item req;

      // initial reset
      vif.rst_n         <= 1'b0;
      vif.wr_en         <= 1'b0;
      vif.byte_en       <= 2'b00;
      vif.addr          <= 2'b00;
      vif.wdata         <= 16'h0000;
      vif.hb_strobe     <= 1'b0;
      vif.boot_complete <= 1'b0;

      repeat (2) @(posedge vif.clk);
      #1;
      vif.rst_n <= 1'b1;

      forever begin
        seq_item_port.get_next_item(req);
        @(posedge vif.clk);
        #1;
        vif.wr_en         <= req.wr_en;
        vif.byte_en       <= req.byte_en;
        vif.addr          <= req.addr;
        vif.wdata         <= req.wdata;
        vif.hb_strobe     <= req.hb_strobe;
        vif.boot_complete <= req.boot_complete;
        seq_item_port.item_done();
      end
    endtask
  endclass

  // -----------------------------------------------------------------
  // Monitor  (KEY FIX : extends uvm_monitor)
  // -----------------------------------------------------------------
  class secure_boot_wdg_monitor extends uvm_monitor;
    `uvm_component_utils(secure_boot_wdg_monitor)

    virtual secure_boot_wdg_if vif;
    uvm_analysis_port #(secure_boot_wdg_item) ap;

    function new(string name = "monitor", uvm_component parent = null);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      ap = new("ap", this);
      if (!uvm_config_db#(virtual secure_boot_wdg_if)::get(this, "", "vif", vif))
        `uvm_fatal("NOVIF", "monitor: missing vif")
    endfunction

    task run_phase(uvm_phase phase);
      secure_boot_wdg_item tr;
      forever begin
        @(posedge vif.clk);
        #1ps; // explicit post-edge sample (non-racing)
        tr = secure_boot_wdg_item::type_id::create("tr", this);
        tr.wr_en         = vif.wr_en;
        tr.byte_en       = vif.byte_en;
        tr.addr          = vif.addr;
        tr.wdata         = vif.wdata;
        tr.hb_strobe     = vif.hb_strobe;
        tr.boot_complete = vif.boot_complete;
        tr.rdata         = vif.rdata;
        tr.wdg_fault     = vif.wdg_fault;
        tr.sys_reset_req = vif.sys_reset_req;

        ap.write(tr);
      
      end
    endtask
  endclass

  // -----------------------------------------------------------------
  // Agent  (missing previously — required by UVM contract)
  // -----------------------------------------------------------------
  class secure_boot_wdg_agent extends uvm_agent;
    `uvm_component_utils(secure_boot_wdg_agent)

    secure_boot_wdg_sequencer seqr;
    secure_boot_wdg_driver    drv;
    secure_boot_wdg_monitor   mon;

    function new(string name = "agent", uvm_component parent = null);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);

      if (get_is_active() == UVM_ACTIVE) begin
        seqr = secure_boot_wdg_sequencer::type_id::create("seqr", this);
        drv  = secure_boot_wdg_driver   ::type_id::create("drv",  this);
      end
      mon = secure_boot_wdg_monitor::type_id::create("mon", this);
    endfunction

    function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      if (get_is_active() == UVM_ACTIVE)
        drv.seq_item_port.connect(seqr.seq_item_export);
    endfunction
  endclass

  // -----------------------------------------------------------------
  // Scoreboard
  // -----------------------------------------------------------------
  class secure_boot_wdg_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(secure_boot_wdg_scoreboard)

    uvm_analysis_imp #(secure_boot_wdg_item, secure_boot_wdg_scoreboard) imp;

    int unsigned checks;
    int unsigned errors;

    // simple shadow of CFG register (addr 0)
    logic [15:0] cfg_shadow;
    logic        enabled;

    function new(string name = "scoreboard", uvm_component parent = null);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      imp         = new("imp", this);
      checks      = 0;
      errors      = 0;
      cfg_shadow  = 16'h0000;
      enabled     = 1'b0;
    endfunction

    function void write(secure_boot_wdg_item tr);
      checks++;

      // 1) fault / reset_req invariant
      if (tr.wdg_fault !== tr.sys_reset_req) begin
        errors++;
        `uvm_error("SCB", $sformatf(
          "fault/reset_req mismatch: fault=%b rst_req=%b @ %s",
          tr.wdg_fault, tr.sys_reset_req, tr.convert2string()))
      end

      // 2) shadow CFG model
      if (tr.wr_en && tr.addr == 2'b00) begin
        if (tr.byte_en[0]) cfg_shadow[7:0]  = tr.wdata[7:0];
        if (tr.byte_en[1]) cfg_shadow[15:8] = tr.wdata[15:8];
        enabled = cfg_shadow[0];
      end

      // 3) read-back on addr 0 must match shadow
      if (!tr.wr_en && tr.addr == 2'b00) begin
        if (tr.rdata !== cfg_shadow) begin
          errors++;
          `uvm_error("SCB", $sformatf(
            "rdata mismatch: exp=%0h got=%0h @ %s",
            cfg_shadow, tr.rdata, tr.convert2string()))
        end
      end
    endfunction

    function void check_phase(uvm_phase phase);
      super.check_phase(phase);
      if (errors > 0)
        `uvm_error("SCB", $sformatf("%0d errors / %0d checks", errors, checks))
      else
        `uvm_info("SCB", $sformatf("PASS : %0d checks", checks), UVM_LOW)
    endfunction
  endclass

  // -----------------------------------------------------------------
  // Environment
  // -----------------------------------------------------------------
  class secure_boot_wdg_env extends uvm_env;
    `uvm_component_utils(secure_boot_wdg_env)

    secure_boot_wdg_agent      agent;
    secure_boot_wdg_scoreboard scb;

    function new(string name = "env", uvm_component parent = null);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      agent = secure_boot_wdg_agent     ::type_id::create("agent", this);
      scb   = secure_boot_wdg_scoreboard::type_id::create("scb",   this);
    endfunction

    function void connect_phase(uvm_phase phase);
      agent.mon.ap.connect(scb.imp);
    endfunction
  endclass

  // -----------------------------------------------------------------
  // Test
  // -----------------------------------------------------------------
  class secure_boot_wdg_test extends uvm_test;
    `uvm_component_utils(secure_boot_wdg_test)

    secure_boot_wdg_env env;

    function new(string name = "test", uvm_component parent = null);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      env = secure_boot_wdg_env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
      secure_boot_wdg_sequence seq;
      phase.raise_objection(this);

      seq = secure_boot_wdg_sequence::type_id::create("seq");
      seq.start(env.agent.seqr);

      #300;
      phase.drop_objection(this);
    endtask
  endclass
endpackage

// ---------------------------------------------------------------------
// Top-level testbench
// ---------------------------------------------------------------------
module tb_secure_boot_wdg;
  import uvm_pkg::*;
  import secure_boot_wdg_pkg::*;

  secure_boot_wdg_if vif();

  secure_boot_wdg dut (
    .clk            (vif.clk),
    .rst_n          (vif.rst_n),
    .wr_en          (vif.wr_en),
    .byte_en        (vif.byte_en),
    .addr           (vif.addr),
    .wdata          (vif.wdata),
    .hb_strobe      (vif.hb_strobe),
    .boot_complete  (vif.boot_complete),
    .rdata          (vif.rdata),
    .wdg_fault      (vif.wdg_fault),
    .sys_reset_req  (vif.sys_reset_req)
  );

  initial begin
    vif.clk = 1'b0;
    forever #5 vif.clk = ~vif.clk;
  end

  initial begin
    uvm_config_db #(virtual secure_boot_wdg_if)::set(null, "*", "vif", vif);
    run_test("secure_boot_wdg_test");
  end
endmodule