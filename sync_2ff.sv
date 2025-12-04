module sync_2ff
  (
   input logic clk ,
   input logic rst_n ,
   input logic data_in ,
   output logic data_out 
  );
  
  logic q1;
  
  always_ff @(posedge clk or negedge rst_n) begin 
   if (!rst_n) begin 
     q1         <= 1'b0;
     data_out   <= 1'b0;
   end else begin
     q1         <= data_in;
     data_out   <= q1;
    end
   end
  
endmodule


