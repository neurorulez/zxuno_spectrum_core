`timescale 1ns / 1ps
`default_nettype none

//    This file is part of the ZXUNO Spectrum core. 
//    Creation date is 23:26:34 2015-10-17 by Miguel Angel Rodriguez Jodar
//    (c)2014-2020 ZXUNO association.
//    ZXUNO official repository: http://svn.zxuno.com/svn/zxuno
//    Username: guest   Password: zxuno
//    Github repository for this core: https://github.com/mcleod-ideafix/zxuno_spectrum_core
//
//    ZXUNO Spectrum core is free software: you can redistribute it and/or modify
//    it under the terms of the GNU General Public License as published by
//    the Free Software Foundation, either version 3 of the License, or
//    (at your option) any later version.
//
//    ZXUNO Spectrum core is distributed in the hope that it will be useful,
//    but WITHOUT ANY WARRANTY; without even the implied warranty of
//    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//    GNU General Public License for more details.
//
//    You should have received a copy of the GNU General Public License
//    along with the ZXUNO Spectrum core.  If not, see <https://www.gnu.org/licenses/>.
//
//    Any distributed copy of this file must keep this notice intact.

module zxunouart (
    input wire clk,
    input wire [7:0] zxuno_addr,
    input wire zxuno_regrd,
    input wire zxuno_regwr,
    input wire [7:0] din,
    output reg [7:0] dout,
    output reg oe_n,
    output wire uart_tx,
    input wire uart_rx,
    output wire uart_rts
    );

`include "config.vh"

    wire txbusy;
    wire data_received;
    wire [7:0] rxdata;

    reg comenzar_trans = 1'b0;
    reg rxrecv = 1'b0;
    reg leyendo_estado = 1'b0;

    wire data_read;

    uart uartchip (
        .clk(clk),
        .txdata(din),
        .txbegin(comenzar_trans),
        .txbusy(txbusy),
        .rxdata(rxdata),
        .rxrecv(data_received),
        .data_read(data_read),
        .rx(uart_rx),
        .tx(uart_tx),
        .rts(uart_rts)
    );

    assign data_read = (zxuno_addr == UARTDATA && zxuno_regrd == 1'b1);

    always @* begin
        oe_n = 1'b1;
        dout = 8'hZZ;
        if (zxuno_addr == UARTDATA && zxuno_regrd == 1'b1) begin
            dout = rxdata;
            oe_n = 1'b0;
        end
        else if (zxuno_addr == UARTSTAT && zxuno_regrd == 1'b1) begin
            dout = {rxrecv, txbusy, 6'h00};
            oe_n = 1'b0;
        end
    end

    always @(posedge clk) begin
        if (zxuno_addr == UARTDATA && zxuno_regwr == 1'b1 && comenzar_trans == 1'b0 && txbusy == 1'b0) begin
            comenzar_trans <= 1'b1;
        end
        if (comenzar_trans == 1'b1 && txbusy == 1'b1) begin
            comenzar_trans <= 1'b0;
        end

        if (data_received == 1'b1)
            rxrecv <= 1'b1;

        if (data_received == 1'b0) begin
            if (zxuno_addr == UARTSTAT && zxuno_regrd == 1'b1)
                leyendo_estado <= 1'b1;
            if (leyendo_estado == 1'b1 && (zxuno_addr != UARTSTAT || zxuno_regrd == 1'b0)) begin
                leyendo_estado <= 1'b0;
                rxrecv <= 1'b0;
            end
        end
    end
endmodule
