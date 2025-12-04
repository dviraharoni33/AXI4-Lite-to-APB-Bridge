`timescale 1ns/1ns

module testbench;
  
  logic aclk = 0;
  logic aresetn = 0;
  logic pclk = 0;
  logic presetn =0;
  
  logic [31:0] awaddr, wdata, araddr;
  logic awvalid, wvalid, bready;
  logic arvalid, rready;
  
  logic awready,wready, bvalid;
  logic arready, rvalid;
  logic [1:0] bresp, rresp;
  logic [31:0] rdata;
  
  logic [31:0] PADDR, PWDATA, PRDATA =0;
  logic PSEL, PENABLE, PWRITE, PREADY =0;
  
  always #5 aclk = ~aclk;
  always #10 pclk = ~pclk;
  
  axi_lite_to_apb_bridge dut
  (
    .awaddr(awaddr), .awvalid(awvalid), .awready(awready),
    .aclk(aclk), .aresetn(aresetn), .wdata(wdata),
    .wvalid(wvalid), .wready(wready), .bresp(bresp), 
    .bvalid(bvalid), .bready(bready), .araddr(araddr), 
    .arvalid(arvalid), .arready(arready), .rdata(rdata),
    .rresp(rresp), .rvalid(rvalid), .rready(rready),
  
    .pclk(pclk), .presetn(presetn), .PADDR(PADDR),
    .PWDATA(PWDATA), .PWRITE(PWRITE), .PSEL(PSEL),
    .PENABLE(PENABLE), .PRDATA(PRDATA), .PREADY(PREADY)
  );
    
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, testbench);
    
    awvalid = 0;
    wvalid = 0;
    bready = 0;
    arvalid = 0;
    rready = 0;
    
    aresetn = 0;
    presetn = 0;
    
    #50;
    
    aresetn = 1;
    presetn = 1;
    
    #20;
  
    $display("Time %0t: Staring Write Transaction...", $time);
    
    awvalid = 1;
    awaddr = 32'h10;
    wvalid = 1;
    wdata = 32'h55;
    bready = 1;
    
    wait(awready && wready);
    
    @(posedge aclk);
    
    awvalid = 0;
    wvalid = 0;
    awaddr = 0;
    wdata = 0;
    
    $display("Time %0t: Write Sent to FIFO. Waiting for   APB...", $time);
    
    #200;
 
    
    $display("Time %0t: Starting Read Transaction...", $time);
    
    arvalid =1;
    araddr = 32'h10;
    rready = 1;
    
    wait(arready);
    @(posedge aclk);
    
    arvalid = 0;
    araddr = 0;
    
    wait(rvalid);
    #1;
    
    if(rdata === 32'hDEADBEEF)
    
      $display("Time %0t: SUCCESS! Received Data: %h (DEADBEEF)", $time, rdata);
    else
      $display("Time %0t: ERROR! Received Data: %h (Expected DEADBEEF)", $time, rdata);
    
    @(posedge aclk);
    
    #100;
    
    $finish;
  end         
  
  
  always @(posedge pclk) begin
    PREADY <= 0;
    
    if (PSEL && PENABLE) begin
      PREADY <= 1;
      
      if (PWRITE == 0) begin
        PRDATA <= 32'hDEADBEEF;
      end
    end
  end
  
endmodule 
