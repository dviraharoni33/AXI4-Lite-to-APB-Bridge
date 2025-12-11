module async_fifo
 #(
   parameter DATA_WIDTH = 32,
   parameter ADDR_WIDTH = 2
   )
  (
   //AXI
   input logic wclk, 
   input logic wrst_n,
   input logic winc,
   input logic [DATA_WIDTH-1:0] wdata,
   output logic wfull,
  
   //APB
   input logic rclk,
   input logic rrst_n,
   input logic rinc, 
   output logic [DATA_WIDTH-1:0] rdata,
   output logic rempty
  );

 //memory
 localparam DEPTH = 1 << ADDR_WIDTH;
 logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];
  
 //pointers
 logic [ADDR_WIDTH:0] wptr_bin, wptr_gray;
 logic [ADDR_WIDTH:0] rptr_bin, rptr_gray;
 
 //Synchronization
  logic [ADDR_WIDTH:0] wq2_rptr_gray;
  logic [ADDR_WIDTH:0] rq2_wptr_gray;
  
 genvar i;
 generate
   for (i=0; i<= ADDR_WIDTH; i++) begin : sync_loop
     sync_2ff sync_r2w 
      (
       .clk(wclk), .rst_n(wrst_n),
        .data_in(rptr_gray[i]),
       .data_out(wq2_rptr_gray[i])
       );
     sync_2ff sync_w2r 
      (
       .clk(rclk), .rst_n(rrst_n),
        .data_in(wptr_gray[i]),
       .data_out(rq2_wptr_gray[i])
       );   
   end    
 endgenerate     

 always_ff @(posedge wclk or negedge wrst_n) begin
   if (!wrst_n) begin
     wptr_bin <= 0;
     wptr_gray <= 0;
    end else begin
   if (winc && !wfull) begin
     mem[wptr_bin[ADDR_WIDTH-1:0]] <= wdata;
     wptr_bin <= wptr_bin +1;
     wptr_gray <= (wptr_bin +1) ^ ((wptr_bin +1) >> 1);
     end
    end
   end     
          
  assign wfull = (wptr_gray ==              {~wq2_rptr_gray[ADDR_WIDTH:ADDR_WIDTH-1],      wq2_rptr_gray[ADDR_WIDTH-2:0]});       
 
 
        always_ff @(posedge rclk or negedge rrst_n) begin 
          if (!rrst_n) begin
            rptr_bin <= 0;
            rptr_gray <= 0;
          end else begin
            if (rinc && !rempty) begin
              rptr_bin <= rptr_bin +1;
              rptr_gray <= (rptr_bin +1) ^ ((rptr_bin +1) >> 1);
            end
          end
        end
        
        assign rdata = mem[rptr_bin[ADDR_WIDTH-1:0]];
        assign rempty = (rptr_gray == rq2_wptr_gray);
          
            

endmodule

