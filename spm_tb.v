module spm_tb;

	//Inputs
	reg clk;
	reg rst;
	reg [7: 0] x;

    reg[7:0] Y;
    reg[15:0] P;

	//Outputs
	wire p;

    reg[3:0] cnt;

	//Instantiation of Unit Under Test
	spm #(8) uut (
		.clk(clk),
		.rst(rst),
		.y(Y[0]),
		.x(x),
		.p(p)
	);

    always #5 clk = ~clk;

    always @ (posedge clk)
        if(rst) Y = -50;
        else Y <= {1'b0,Y[7:1]};

    always @ (posedge clk)
        if(rst) P = 0;
        else P <= {p, P[15:1]};

	always @ (posedge clk)
        if(rst) cnt = 0;
        else cnt <= cnt + 1;

	initial begin
	//Inputs initialization
		clk = 0;
		rst = 0;
		x = 50;

	//Reset
		#20 rst = 1;
		#20 rst = 0;
        #1000;
        $finish;
	end

endmodule
