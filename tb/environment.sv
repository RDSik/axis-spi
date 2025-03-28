`ifndef ENV_SV
`define ENV_SV

class environment;

    local virtual axis_spi_master_if dut_if;
    local virtual axis_if            s_axis;
    local virtual axis_if            m_axis;

    int clk_per;
    int sim_time;
    int data_width;
    int max_delay;
    int min_delay;

    function new(virtual axis_spi_master_if dut_if, virtual axis_if s_axis, virtual axis_if m_axis,
                int clk_per, int sim_time, int data_width, int max_delay, int min_delay);
        this.dut_if     = dut_if;
        this.s_axis     = s_axis;
        this.m_axis     = m_axis;
        this.clk_per    = clk_per;
        this.sim_time   = sim_time;
        this.data_width = data_width;
        this.max_delay  = max_delay;
        this.min_delay  = min_delay;
    endfunction

    task run();
        begin
            fork
                clock_gen();
                reset_gen(max_delay);
                master_drive(max_delay, min_delay);
                slave_drive(max_delay, min_delay);
            join_none
            time_out(sim_time);
        end
    endtask

    task master_drive(int max_delay, int min_delay);
        logic [7:0] tmp_data;
        int delay;
        begin
            wait(~dut_if.arstn_i);
            s_axis.tvalid = 1'b0;
            s_axis.tdata  = '0;
            wait(dut_if.arstn_i);
            forever begin
                void'(std::randomize(delay) with {delay inside {[min_delay:max_delay]};});
                repeat (delay) @(posedge dut_if.clk_i);
                s_axis.tvalid = 1'b1;
                s_axis.tlast  = $urandom_range(0, 1);
                if (!std::randomize(tmp_data) with {tmp_data inside {[0:(2**data_width)-1]};})
                    $error("tdata was not randomized!");
                s_axis.tdata  = tmp_data;
                do begin
                    @(posedge dut_if.clk_i);
                end
                while (~s_axis.tready);
                s_axis.tvalid = 1'b0;
            end
        end
    endtask

    task slave_drive(int max_delay, int min_delay);
        int delay;
        begin
            wait(~dut_if.arstn_i);
            m_axis.tready = 1'b0;
            wait(dut_if.arstn_i);
            forever begin
                void'(std::randomize(delay) with {delay inside {[min_delay:max_delay]};});
                repeat (delay) @(posedge dut_if.clk_i);
                m_axis.tready = 1'b1;
                @(posedge dut_if.clk_i);
                m_axis.tready = 1'b0;
            end
        end
    endtask

    task reset_gen(int max_delay);
        begin
            dut_if.arstn_i = 1'b0;
            repeat (max_delay) @(posedge dut_if.clk_i);
            dut_if.arstn_i = 1'b1;
            $display("Reset done in %g ns\n.", $time);
        end
    endtask

    task clock_gen();
        begin
            dut_if.clk_i = 1'b0;
            forever begin
                #(clk_per/2) dut_if.clk_i = ~dut_if.clk_i;
            end
        end
    endtask

    task time_out(int sim_time);
        begin
            repeat (sim_time) @(posedge dut_if.clk_i);
            $display("Stop simulation at: %g ns\n", $time);
            `ifdef VERILATOR
            $finish();
            `else
            $stop();
            `endif
        end
    endtask

endclass

`endif
