module Interrupt_Controller (
        input   wire            clk_in,
        input   wire            rst_in,
        input   wire    [7:0]   intr_rq,
        inout   wire    [7:0]   intr_bus,
        input   wire            intr_in,
        output  wire            intr_out,
        output  wire            bus_oe
    );
 
    localparam  [3:0]   S_Reset                 = 4'b0000,
                        S_GetCommands           = 4'b0001,
                        S_JumpIntMethod         = 4'b0010,
                        S_StartPolling          = 4'b0011,
                        S_TxIntInfoPolling      = 4'b0100,
                        S_AckTxInfoRxPolling    = 4'b0101,
                        S_AckISRDonePolling     = 4'b0110,
                        S_StartPriority         = 4'b0111,
                        S_TxIntInfoPriority     = 4'b1000,
                        S_AckTxInfoRxPriority   = 4'b1001,
                        S_AckISRDonePriority    = 4'b1010,
                        S_Reserved1             = 4'b1011,
                        S_Reserved2             = 4'b1100,
                        S_Reserved3             = 4'b1101,
                        S_Reserved4             = 4'b1110,
                        S_Reserved5             = 4'b1111;
 
    reg     [3:0]   state_reg, state_next;
    reg     [1:0]   cmdMode_reg, cmdMode_next;
    reg     [1:0]   cmdCycle_reg, cmdCycle_next;
    reg     [2:0]   intrIndex_reg, intrIndex_next;
    reg     [2:0]   intrPtr_reg, intrPtr_next;
    reg     [2:0]   prior_table_next [0:7]; 
    reg     [2:0]   prior_table_reg [0:7];
    reg             oe_reg, oe_next;
    reg     [7:0]   intrBus_reg, intrBus_next;
    reg             intrOut_reg, intrOut_next;

    integer         i;

    always @ (posedge clk_in or posedge rst_in) begin
        if (rst_in) begin
            state_reg           <=  S_Reset;
            cmdMode_reg         <=  2'b00;
            cmdCycle_reg        <=  2'b00;
            oe_reg              <=  1'b0;
            intrBus_reg         <=  8'bzzzzzzzz;
            intrOut_reg         <=  1'b0;
            intrIndex_reg       <=  3'b000;
            intrPtr_reg         <=  3'b000;
            for (i = 0; i < 8; i = i + 1) begin
                prior_table_reg[i]  <=  3'b000;
            end
        end
 
        else begin
            state_reg           <=  state_next;
            cmdMode_reg         <=  cmdMode_next;
            cmdCycle_reg        <=  cmdCycle_next;
            intrBus_reg         <=  intrBus_next;
            intrOut_reg         <=  intrOut_next;
            oe_reg              <=  oe_next;
            intrIndex_reg       <=  intrIndex_next;
            intrPtr_reg         <=  intrPtr_next;
            for (i = 0; i < 8; i = i + 1) begin
                prior_table_reg[i]  <=  prior_table_next[i];
            end
        end
    end

    always @(*) begin
        state_next          =   state_reg;
        cmdMode_next        =   cmdMode_reg;
        cmdCycle_next       =   cmdCycle_reg;
        oe_next             =   oe_reg;
        intrOut_next        =   intrOut_reg;
        intrBus_next        =   intrBus_reg;
        intrIndex_next      =   intrIndex_reg;
        intrPtr_next        =   intrPtr_reg;
        for (i = 0; i < 8; i = i + 1) begin
            prior_table_next[i] =   prior_table_reg[i];
        end
 
        case (state_reg)
            S_Reset: begin
                cmdMode_next        =   2'b00;
                cmdCycle_next       =   2'b00;
                intrIndex_next      =   3'b000;
                intrPtr_next        =   3'b000;
                for (i = 0; i < 8; i = i + 1) begin
                    prior_table_next[i] =   3'b000;
                end
                oe_next             =   1'b0;
                state_next  =   S_GetCommands;
            end
 
            S_GetCommands: begin
                oe_next =   1'b0;
                case (intr_bus[1:0])
                    2'b01: begin
                        cmdMode_next    =   2'b01;
                        state_next      =   S_JumpIntMethod;
                    end
 
                    2'b10: begin
                        case (cmdCycle_reg)
                            2'b00: begin
                                prior_table_next[0] =   intr_bus[7:5];
                                prior_table_next[1] =   intr_bus[4:2];
                                state_next          =   S_GetCommands;
                                cmdCycle_next       =   cmdCycle_reg + 1'b1;
                            end
                            2'b01: begin
                                prior_table_next[2] =   intr_bus[7:5];
                                prior_table_next[3] =   intr_bus[4:2];
                                state_next          =   S_GetCommands;
                                cmdCycle_next       =   cmdCycle_reg + 1'b1;
                            end
                            2'b10: begin
                                prior_table_next[4] =   intr_bus[7:5];
                                prior_table_next[5] =   intr_bus[4:2];
                                state_next          =   S_GetCommands;
                                cmdCycle_next       =   cmdCycle_reg + 1'b1;
                            end
                            2'b11: begin
                                prior_table_next[6] =   intr_bus[7:5];
                                prior_table_next[7] =   intr_bus[4:2];
                                state_next          =   S_JumpIntMethod;
                                cmdCycle_next       =   cmdCycle_reg + 1'b1;
                                cmdMode_next        =   2'b10;
                            end
                            default: begin
                                state_next      =   S_GetCommands;
                                cmdCycle_next   =   2'b00;
                                cmdMode_next    =   2'b00;
                            end
                        endcase
 
                    end
                    default: begin
                        state_next  =   S_GetCommands;
                    end
                endcase
            end
 
            S_JumpIntMethod: begin
                intrIndex_next  =   3'b000;
                intrPtr_next    =   3'b000;
 
                case (cmdMode_reg)
                    2'b01: begin
                        state_next  =   S_StartPolling;
                    end
                    2'b10: begin
                        state_next  =   S_StartPriority;
                    end
                    default: begin
                        state_next  =   S_Reset;
                    end
                endcase
 
                oe_next         =   1'b0;
            end
 
            S_StartPolling: begin
                if (intr_rq[intrIndex_reg]) begin
                    intrOut_next    =   1'b1;
                    state_next      =   S_TxIntInfoPolling;
                end
                else begin
                    intrOut_next    =   1'b0;
                    intrIndex_next  =   intrIndex_reg + 1;
                end
                oe_next         =   1'b0;
            end
 
            S_TxIntInfoPolling: begin
                if (~intr_in) begin
                    intrOut_next    =   1'b0;
                    intrBus_next    =   {5'b01011, intrIndex_reg};
                    oe_next         =   1'b1;
                    state_next      =   S_AckTxInfoRxPolling;
                end
                else
                    state_next      =   S_TxIntInfoPolling;
            end

            S_AckTxInfoRxPolling: begin
                if (~intr_in) begin
                    oe_next         =   1'b0;
                    state_next      =   S_AckISRDonePolling;
                end
            end
 
            S_AckISRDonePolling: begin
                if ((~intr_in) && (intr_bus[7:3] == 5'b10100) && (intr_bus[2:0] == intrIndex_reg)) begin
                    state_next  =   S_StartPolling;
                end
                else if ((~intr_in) && (intr_bus[7:3] != 5'b10100) && (intr_bus[2:0] != intrIndex_reg)) begin
                    state_next  =   S_Reset;
                end
                else begin
                    state_next  =   S_AckISRDonePolling;
                end
            end
 
            S_StartPriority: begin
                if (intr_rq[prior_table_reg[0]]) begin
                    intrPtr_next    =   prior_table_reg[0];
                    intrOut_next    =   1'b1;
                    state_next      =   S_TxIntInfoPriority;
                end
                else if (intr_rq[prior_table_reg[1]]) begin
                    intrPtr_next    =   prior_table_reg[1];
                    intrOut_next    =   1'b1;
                    state_next      =   S_TxIntInfoPriority;
                end
                else if (intr_rq[prior_table_reg[2]]) begin
                    intrPtr_next    =   prior_table_reg[2];
                    intrOut_next    =   1'b1;
                    state_next      =   S_TxIntInfoPriority;
                end
                else if (intr_rq[prior_table_reg[3]]) begin
                    intrPtr_next    =   prior_table_reg[3];
                    intrOut_next    =   1'b1;
                    state_next      =   S_TxIntInfoPriority;
                end
                else if (intr_rq[prior_table_reg[4]]) begin
                    intrPtr_next    =   prior_table_reg[4];
                    intrOut_next    =   1'b1;
                    state_next      =   S_TxIntInfoPriority;
                end
                else if (intr_rq[prior_table_reg[5]]) begin
                    intrPtr_next    =   prior_table_reg[5];
                    intrOut_next    =   1'b1;
                    state_next      =   S_TxIntInfoPriority;
                end
                else if (intr_rq[prior_table_reg[6]]) begin
                    intrPtr_next    =   prior_table_reg[6];
                    intrOut_next    =   1'b1;
                    state_next      =   S_TxIntInfoPriority;
                end
                else if (intr_rq[prior_table_reg[7]]) begin
                    intrPtr_next    =   prior_table_reg[7];
                    intrOut_next    =   1'b1;
                    state_next      =   S_TxIntInfoPriority;
                end
                else begin
                    intrOut_next    =   1'b0;
                    state_next      =   S_StartPriority;
                end
                oe_next =   1'b0;
            end
 
            S_TxIntInfoPriority: begin
                if (~intr_in) begin
                    intrOut_next    =   1'b0;
                    intrBus_next    =   {5'b01011, intrPtr_reg};
                    oe_next         =   1'b1;
                    state_next      =   S_AckTxInfoRxPriority;
                end
                else begin
                    state_next      =   S_TxIntInfoPriority;
                end
            end
 
            S_AckTxInfoRxPriority: begin
                if (~intr_in) begin
                    oe_next     =   1'b0;
                    state_next  =   S_AckISRDonePriority;
                end
            end
 
            S_AckISRDonePriority: begin
                if ((~intr_in) && (intr_bus[7:3] == 5'b10100) && (intr_bus[2:0] == intrPtr_reg)) begin
                    state_next  =   S_StartPriority;
                end
                else if ((~intr_in) && (intr_bus[7:3] != 5'b10100) && (intr_bus[2:0] != intrPtr_reg)) begin
                    state_next  =   S_Reset;
                end
                else begin
                    state_next  =   S_AckISRDonePriority;
                end
            end

            default: begin
                state_next  =   S_Reset;
            end
 
        endcase
    end
 
    assign bus_oe =   oe_reg;
    assign intr_out =   intrOut_reg;
    assign intr_bus =   (oe_reg)? intrBus_reg : 8'bzzzzzzzz;
 
endmodule
