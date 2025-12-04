module apb_master_fsm 
  (
   input logic pclk,
   input logic presetn,
    
   input logic fifo_empty,
   input logic [31:0] cmd_addr,
   input logic [31:0] cmd_wdata,
   input logic cmd_write, 
   output logic fifo_pop,
    
   output logic [31:0] PADDR,
   output logic [31:0] PWDATA,
   output logic PWRITE,
   output logic PSEL,
   output logic PENABLE,
   input logic [31:0] PRDATA,
   input logic PREADY
  );
  
 
  typedef enum logic [1:0] 
   {
    IDLE,
    SETUP,
    ACCESS
   } state_t;
  
  state_t current_state, next_state;
  
  always_ff @(posedge pclk or negedge presetn) begin
    if (!presetn) begin
      current_state <= IDLE;
    end else begin
      
      current_state <= next_state;
    end 
  end
  
  
  always_comb begin
    next_state = current_state;
    PSEL = 0;
    PENABLE = 0;
    PWRITE = 0;
    PADDR = 0;
    PWDATA = 0;
    fifo_pop = 0;
   
    case (current_state)
      IDLE:begin
        if (!fifo_empty) begin
          next_state = SETUP;
        end
      end
      
     SETUP: begin
       PSEL = 1;
       PWRITE = cmd_write;
       PADDR = cmd_addr;
       PWDATA = cmd_wdata;
       
       next_state = ACCESS;
     end
      
      ACCESS: begin
        PSEL =1;
        PENABLE = 1;
        PWRITE = cmd_write;
        PADDR = cmd_addr;
        PWDATA = cmd_wdata;
        
        if (PREADY) begin
          fifo_pop =1;
          next_state = IDLE;
        end
      end
    endcase
  end
      
  
  endmodule
  
  
  
  
  
  
  
  