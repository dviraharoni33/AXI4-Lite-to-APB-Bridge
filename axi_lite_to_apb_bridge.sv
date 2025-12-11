`include "sync_2ff.sv"
`include "async_fifo.sv"
`include "apb_master_fsm.sv"

module axi_lite_to_apb_bridge #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 5 
)
  (
    input  logic aclk, aresetn,
    input  logic [31:0] awaddr, 
    input logic awvalid, 
    output logic awready,
    input  logic [31:0] wdata,  
    input logic wvalid,  
    output logic wready,
    output logic [1:0] bresp,   
    output logic bvalid, 
    input logic bready,
    input  logic [31:0] araddr, 
    input logic arvalid, 
    output logic arready,
    output logic [31:0] rdata,  
    output logic [1:0] rresp, 
    output logic rvalid, 
    input logic rready,
    
    input  logic pclk, presetn,
    output logic [31:0] PADDR, PWDATA,
    output logic PWRITE, PSEL, PENABLE,
    input  logic [31:0] PRDATA, 
    input logic PREADY
);

    logic cmd_empty, cmd_pop, cmd_write, cmd_full;
    logic [31:0] cmd_addr, cmd_wdata;
    logic resp_full, resp_empty, resp_push;
    logic [31:0] resp_rdata;

    async_fifo #(.DATA_WIDTH(65), .ADDR_WIDTH(ADDR_WIDTH)) 
       fifo_cmd (
        .wclk(aclk), .wrst_n(aresetn),
        .winc((awvalid && wvalid) || arvalid),
        .wdata({(awvalid ? awaddr : araddr), wdata, (awvalid && wvalid)}),
        .wfull(cmd_full),
        .rclk(pclk), .rrst_n(presetn),
        .rinc(cmd_pop),
        .rdata({cmd_addr, cmd_wdata, cmd_write}),
        .rempty(cmd_empty)
                 );

    
    async_fifo #(.DATA_WIDTH(32), .ADDR_WIDTH(ADDR_WIDTH)) 
       fifo_resp (
        .wclk(pclk), .wrst_n(presetn),
        .winc(resp_push), .wdata(PRDATA), .wfull(resp_full),
        .rclk(aclk), .rrst_n(aresetn),
        .rinc((rready || bready) && !resp_empty),  
        .rdata(resp_rdata), .rempty(resp_empty)
                  );

    apb_master_fsm fsm_inst (
        .pclk(pclk), .presetn(presetn),
        .fifo_empty(cmd_empty), .cmd_addr(cmd_addr), .cmd_wdata(cmd_wdata), .cmd_write(cmd_write),
        .fifo_pop(cmd_pop),
        .PADDR(PADDR), .PWDATA(PWDATA), .PWRITE(PWRITE), .PSEL(PSEL), .PENABLE(PENABLE),
        .PRDATA(PRDATA), .PREADY(PREADY)
                             );

    assign awready = !cmd_full;
    assign wready  = !cmd_full;
    assign arready = !cmd_full;
    assign resp_push = cmd_pop;
    assign rvalid = !resp_empty;
    assign rdata  = resp_rdata;
    assign rresp  = 0;
    assign bvalid = !resp_empty;
    assign bresp  = 0;

endmodule
