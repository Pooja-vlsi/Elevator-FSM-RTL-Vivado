`timescale 1ns/1ps

module elevator_tb();

    reg clk;
    reg rst;
    reg [3:0] floor_req;

    wire move_up;
    wire move_down;
    wire door_open;

    elevator uut (
        .clk(clk),
        .rst(rst),
        .floor_req(floor_req),
        .move_up(move_up),
        .move_down(move_down),
        .door_open(door_open)
    );

    initial clk = 0;
    always #10 clk = ~clk;   // 50 MHz clock

    initial begin
        rst = 1;
        floor_req = 0;
        #100;

        rst = 0;   // release reset
        #100;

        // Request floor 2
        floor_req = 4'b0100; 
        #40; 
        floor_req = 0;
        #1000;

        // Request floor 3
        floor_req = 4'b1000;
        #40; 
        floor_req = 0;
        #2000;

        // Request floor 0
        floor_req = 4'b0001;
        #40; 
        floor_req = 0;
        #2000;

        #1000;
        $stop;
    end

endmodule
