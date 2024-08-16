module Interrupt_Controller_TB;

    reg             clk_in;         
    reg             rst_in;         
    reg     [7:0]   intr_rq;        
    reg     [7:0]   intr_bus_in;    
    reg             intr_in;        
    wire            intr_out;       
    wire            bus_oe;         

    wire    [7:0]   intr_bus_test;
    wire    [7:0]   intr_bus_out;
    Interrupt_Controller DUT (
        .clk_in     (clk_in         ),
        .rst_in     (rst_in         ),
        .intr_rq    (intr_rq        ),
        .intr_bus   (intr_bus_test  ),
        .intr_in    (intr_in        ),
        .intr_out   (intr_out       ),
        .bus_oe     (bus_oe         )
        );
        
    assign intr_bus_test    =   (bus_oe == 0) ? intr_bus_in : 8'bz;
    assign intr_bus_out     =   (bus_oe == 1) ? intr_bus_test : 8'bz;

    reg     [2:0]   currentService;     
    integer j;

    initial begin
        clk_in          =   1'b0;
        rst_in          =   1'b1;
        intr_rq         =   8'b0;
        intr_bus_in     =   8'b0;
        intr_in         =   1'b1;
        #20;
        rst_in          =   1'b0;
        #20;
        intr_bus_in     =   8'b0000_0001;   
        #40;                                
        intr_rq         =   8'b1010_1010;   

        $display ("=================================================================="); 
        $display ("========                 Beginning Polling                ========");
        $display ("=================================================================="); 

        for (j = 0; j < 8; j = j + 1) begin
            if (j == 4) begin               
                intr_rq = 8'b0101_0101;
            end
            $display ("==================================================================");
            $display ("Servicing Interrupt Number %d / 8", (j+1));
            $display ("=================================================================="); 
            $display ("Interrupt Request = %b", intr_rq);

            $display ("Waiting for interrupt from controller");
            wait(intr_out);                     
            #60;                                
            intr_in     =   1'b0;               
            #10                                 
            intr_in     =   1'b1;                      
            $display ("Interrupt Acknowledged by processor.");
            $display("Currently servicing %b", intr_bus_out[2:0]);
            $display ("The controller is driving the bus, %b", intr_bus_out);
            currentService          =   intr_bus_out[2:0];
            intr_rq[currentService] =   1'b0;   
            
            if (intr_bus_out == {5'b01011, currentService}) begin
                $display ("Proper address on the bus");
            end else begin
                $display ("ERROR: Wrong address on the bus");
                $finish;
            end

            #60                                 
            intr_in     =   1'b0;               
            #10                                 
            intr_in     =   1'b1;               
            $display ("Address acknowledged by processor");

            #60                                                 
            intr_bus_in     =   {5'b10100, currentService};     
            intr_in         =   1'b0;                           
            #10                                                 
            intr_in         =   1'b1;                           
            $display ("ISR Routine complete by processor");
            $display ("The processor is driving the bus, %b", intr_bus_in);
            $display ("==================================================================\n\n\n"); 
            #100; 
        end

        #100;
        rst_in          =   1'b1;
        intr_rq         =   8'b0;
        intr_bus_in     =   8'b0;
        intr_in         =   1'b1;
        #50;
        rst_in          =   1'b0;
        #50;

        intr_bus_in     =   8'b101_011_10;
        #10;
        intr_bus_in     =   8'b111_000_10;
        #10;
        intr_bus_in     =   8'b100_010_10;
        #10;
        intr_bus_in     =   8'b110_001_10;
        #40;
        intr_rq         =   8'b1111_1111;   
        
        $display ("=================================================================="); 
        $display ("========                 Beginning Priority               ========");
        $display ("=================================================================="); 
        $display ("=================================================================="); 
        $display ("Proper Order - 5 -> 3 -> 7 -> 0 -> 4 -> 3 -> 2 -> 5 -> 6 -> 1");
        $display ("=================================================================="); 

        for (j = 0; j < 10; j = j + 1) begin
            if (j == 4) begin
                intr_rq [3] = 1'b1;
            end
            if (j == 6) begin
                intr_rq [5] = 1'b1;
            end
            $display ("==================================================================");
            $display ("Servicing Interrupt Number %d / 10", (j+1));
            $display ("=================================================================="); 
            $display ("Interrupt Request = %b", intr_rq);

            $display ("Waiting for interrupt from controller");
            wait(intr_out);                     
            #60;                                
            intr_in     =   1'b0;               
            #10                                 
            intr_in     =   1'b1;                      
            $display ("Interrupt Acknowledged by processor.");
            $display("Currently servicing %b", intr_bus_out[2:0]);
            $display ("The controller is driving the bus, %b", intr_bus_out);
            currentService          =   intr_bus_out[2:0];
            intr_rq[currentService] =   1'b0;   
            
            if (intr_bus_out == {5'b10011, currentService}) begin
                $display ("Proper address on the bus");
            end else begin
                $display ("ERROR: Wrong address on the bus");
                $finish;
            end

            #60                                 
            intr_in     =   1'b0;               
            #10                                 
            intr_in     =   1'b1;               
            $display ("Address acknowledged by processor");

            #60                                                 
            intr_bus_in     =   {5'b01100, currentService};     
            intr_in         =   1'b0;                           
            #10                                                 
            intr_in         =   1'b1;                           
            $display ("ISR Routine complete by processor");
            $display ("The processor is driving the bus, %b", intr_bus_in);
            $display ("==================================================================\n\n\n"); 
            #100; 
        end
        #100;

        $display ("=================================================================="); 
        $display ("========         All tests completed successfully         ========");
        $display ("=================================================================="); 
        $finish;
     
    end

    always
        #5 clk_in   =   ~clk_in;

endmodule // INTR_CNTRL_TB
