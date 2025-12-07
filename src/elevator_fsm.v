// elevator.v
// 4-floor elevator FSM (floors 0..3)
// Synth-friendly two-process FSM style.
// Top-level ports match your XDC mapping.

module elevator(
    input  wire        clk,        // clock
    input  wire        rst,        // synchronous reset (active high)
    input  wire [3:0]  floor_req,  // external floor request inputs (4 buttons)
    output wire        move_up,    // move up command (drives LED)
    output wire        move_down,  // move down command (drives LED)
    output wire        door_open   // door open command (drives LED)
);

    // state encoding
    localparam IDLE = 2'b00;
    localparam UP   = 2'b01;
    localparam DOWN = 2'b10;
    localparam DOOR = 2'b11;

    // door time (clock cycles)
    localparam integer DOOR_TIME = 8;

    // registers
    reg [1:0] state, next_state;
    reg [1:0] current_floor;
    reg [3:0] req_reg;        // latched requests
    reg [7:0] door_cnt;

    // registered outputs
    reg move_up_r, move_down_r, door_open_r;
    assign move_up   = move_up_r;
    assign move_down = move_down_r;
    assign door_open = door_open_r;

    // helpers (combinational)
    reg any_request;
    reg any_above;
    reg any_below;

    integer i;

    // Sequential: registers + outputs (synchronous)
    always @(posedge clk) begin
        if (rst) begin
            state         <= IDLE;
            current_floor <= 2'd0;
            req_reg       <= 4'b0000;
            door_cnt      <= 8'd0;
            move_up_r     <= 1'b0;
            move_down_r   <= 1'b0;
            door_open_r   <= 1'b0;
        end else begin
            // capture requests (buttons are level; latch until served)
            req_reg <= req_reg | floor_req;

            // update state
            state <= next_state;

            // update current_floor only when transitioning to UP or DOWN
            if (next_state == UP && state != UP) begin
                // entering UP: move one floor next clock
                current_floor <= current_floor + 1'b1;
            end else if (next_state == UP && state == UP) begin
                // if we're already UP, still increment each cycle
                current_floor <= current_floor + 1'b1;
            end else if (next_state == DOWN && state != DOWN) begin
                current_floor <= current_floor - 1'b1;
            end else if (next_state == DOWN && state == DOWN) begin
                current_floor <= current_floor - 1'b1;
            end else begin
                current_floor <= current_floor;
            end

            // door counter: reset when entering DOOR, count while DOOR
            if (state != DOOR && next_state == DOOR) begin
                door_cnt <= 8'd0;
            end else if (next_state == DOOR) begin
                door_cnt <= door_cnt + 1'b1;
            end else begin
                door_cnt <= 8'd0;
            end

            // clear request when entering DOOR (serving current floor)
            if (state != DOOR && next_state == DOOR) begin
                req_reg[current_floor] <= 1'b0;
            end

            // registered outputs reflect next_state (aligns control with move)
            move_up_r   <= (next_state == UP);
            move_down_r <= (next_state == DOWN);
            door_open_r <= (next_state == DOOR);
        end
    end

    // Combinational: next state logic
    always @(*) begin
        // defaults
        next_state = state;
        any_request = 1'b0;
        any_above = 1'b0;
        any_below = 1'b0;

        // compute any_request, any_above, any_below using current req_reg
        for (i = 0; i < 4; i = i + 1) begin
            if (req_reg[i]) any_request = 1'b1;
            if (i > current_floor && req_reg[i]) any_above = 1'b1;
            if (i < current_floor && req_reg[i]) any_below = 1'b1;
        end

        case (state)
            IDLE: begin
                if (req_reg[current_floor]) next_state = DOOR;
                else if (any_above) next_state = UP;
                else if (any_below) next_state = DOWN;
                else next_state = IDLE;
            end

            UP: begin
                // if a request at this floor (after moving) stop
                if (req_reg[current_floor]) next_state = DOOR;
                else if (any_above) next_state = UP;
                else if (any_below) next_state = DOWN;
                else next_state = IDLE;
            end

            DOWN: begin
                if (req_reg[current_floor]) next_state = DOOR;
                else if (any_below) next_state = DOWN;
                else if (any_above) next_state = UP;
                else next_state = IDLE;
            end

            DOOR: begin
                if (door_cnt >= (DOOR_TIME - 1)) begin
                    if (any_above) next_state = UP;
                    else if (any_below) next_state = DOWN;
                    else next_state = IDLE;
                end else begin
                    next_state = DOOR;
                end
            end

            default: next_state = IDLE;
        endcase
    end

endmodule
