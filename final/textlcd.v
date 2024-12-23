module textlcd(
    input rst,             // 리셋 (active high)
    input clk,             // 원본 클록 (예: 1MHz or 50MHz 등) - 내부에서 100Hz로 분주
    input [1:0] msg_sel,   // 추가: 어떤 메시지를 출력할지 선택 (00,01,10,11)
    output lcd_e,          // LCD Enable
    output lcd_rs,         // LCD Register Select
    output lcd_rw,         // LCD Read/Write
    output [7:0] lcd_data  // LCD 데이터 버스
);

    //--------------------------------------
    // 1) LCD 제어선 및 데이터선
    //--------------------------------------
    reg lcd_rs_reg, lcd_rw_reg;
    reg [7:0] lcd_data_reg;
    assign lcd_rs   = lcd_rs_reg;
    assign lcd_rw   = lcd_rw_reg;
    assign lcd_data = lcd_data_reg;

    //--------------------------------------
    // 2) 내부 상태 및 카운터
    //--------------------------------------
    reg [2:0] state;
    reg [9:0] cnt;         // 출력 흐름 제어용 카운터
    reg [3:0] cnt_100hz;   // 100Hz 분주용 카운터
    reg clk_100hz;         // 100Hz 클록

    // 상태 파라미터
    parameter delay         = 3'b000,
              function_set  = 3'b001,
              disp_onoff    = 3'b010,
              entry_mode    = 3'b011,
              line1         = 3'b100,
              line2         = 3'b101,
              delay_t       = 3'b110,
              clear_disp    = 3'b111;

    //--------------------------------------
    // 3) 100Hz 클록 분주
    //    예: 원본 clk이 충분히 빠르다고 가정했을 때
    //--------------------------------------
    always @(posedge rst or posedge clk) begin
        if (rst) begin
            cnt_100hz <= 4'd0;
            clk_100hz <= 1'b0;
        end else begin
            if (cnt_100hz >= 4) begin
                cnt_100hz <= 4'd0;
                clk_100hz <= ~clk_100hz;
            end else begin
                cnt_100hz <= cnt_100hz + 1'b1;
            end
        end
    end

    // LCD Enable 신호로 100Hz 클록을 직접 사용
    assign lcd_e = clk_100hz;

    //--------------------------------------
    // 4) 상태 전환 로직 (FSM)
    //--------------------------------------
    always @(posedge rst or posedge clk_100hz) begin
        if (rst) begin
            state <= delay;
            cnt <= 0;
        end else begin
            case (state)
                // 전원 인가 후 초기 지연
                delay: begin
                    if (cnt == 70) begin
                        state <= function_set;
                        cnt <= 0;
                    end else cnt <= cnt + 1;
                end

                // Function set (8비트 모드, 2라인, 5x8 폰트 등)
                function_set: begin
                    if (cnt == 30) begin
                        state <= disp_onoff;
                        cnt <= 0;
                    end else cnt <= cnt + 1;
                end

                // Display ON/OFF (Disp ON, Cursor OFF 등)
                disp_onoff: begin
                    if (cnt == 30) begin
                        state <= entry_mode;
                        cnt <= 0;
                    end else cnt <= cnt + 1;
                end

                // Entry mode set (커서 이동 방향 설정 등)
                entry_mode: begin
                    if (cnt == 30) begin
                        state <= line1;
                        cnt <= 0;
                    end else cnt <= cnt + 1;
                end

                // 첫째 줄(line1) 문자 출력
                line1: begin
                    if (cnt == 20) begin
                        state <= line2;
                        cnt <= 0;
                    end else cnt <= cnt + 1;
                end

                // 둘째 줄(line2) 문자 출력
                line2: begin
                    if (cnt == 20) begin
                        state <= delay_t;
                        cnt <= 0;
                    end else cnt <= cnt + 1;
                end

                // 어느 정도 딜레이 후 (예: 화면 확인 시간)
                delay_t: begin
                    if (cnt == 400) begin
                        state <= clear_disp;
                        cnt <= 0;
                    end else cnt <= cnt + 1;
                end

                // 화면 지우기(clear display)
                clear_disp: begin
                    if (cnt == 200) begin
                        // 여기선 다시 line1으로 돌아가 반복하거나
                        // 다른 동작으로 넘어가도록 지정 가능
                        state <= line1;
                        cnt <= 0;
                    end else cnt <= cnt + 1;
                end

                default: begin
                    state <= delay;
                    cnt <= 0;
                end
            endcase
        end
    end

    //--------------------------------------
    // 5) LCD 제어 로직 (상태+카운터에 따라 데이터 출력)
    //--------------------------------------
    always @(posedge rst or posedge clk_100hz) begin
        if (rst) begin
            lcd_rs_reg   <= 1'b1;
            lcd_rw_reg   <= 1'b1;
            lcd_data_reg <= 8'b0000_0000;
        end else begin
            case (state)
                // Function set: 8비트/2라인/5x8
                function_set: begin
                    lcd_rs_reg   <= 1'b0;
                    lcd_rw_reg   <= 1'b0;
                    // 0011_1100 = 0x3C : 8비트 모드, 2라인, 폰트 등
                    lcd_data_reg <= 8'b00111100;
                end

                // Display ON/OFF: 0000_1100 = 0x0C : 표시ON, 커서OFF, 블링크OFF
                disp_onoff: begin
                    lcd_rs_reg   <= 1'b0;
                    lcd_rw_reg   <= 1'b0;
                    lcd_data_reg <= 8'b00001100;
                end

                // Entry mode: 0000_0110 = 0x06 : Increment address, no shift
                entry_mode: begin
                    lcd_rs_reg   <= 1'b0;
                    lcd_rw_reg   <= 1'b0;
                    lcd_data_reg <= 8'b00000110;
                end

                //------------------------------------
                // (A) 첫째 줄 (line1) 쓰기
                //------------------------------------
                line1: begin
                    lcd_rw_reg <= 1'b0;
                    case (cnt)
                        // 커서: 라인1 시작 주소 (0x80)
                        0: begin
                            lcd_rs_reg   <= 1'b0;
                            lcd_data_reg <= 8'b10000000; // 0x80
                        end

                        // 실제 문자 출력 구간
                        default: begin
                            lcd_rs_reg <= 1'b1; // 문자 쓰기
                            case (msg_sel)
                                //------------------------------------------------
                                // msg_sel=00 -> "HELLO"
                                //------------------------------------------------
                                2'b00: begin
                                    case (cnt)
                                        1: lcd_data_reg <= "M";
                                        2: lcd_data_reg <= "O";
                                        3: lcd_data_reg <= "D";
                                        4: lcd_data_reg <= "E";
                                        5: lcd_data_reg <= " ";
                                        6: lcd_data_reg <= ":";
                                        default: lcd_data_reg <= " ";
                                    endcase
                                end

                                //------------------------------------------------
                                // msg_sel=01 -> "ABCDE"
                                //------------------------------------------------
                                2'b01: begin
                                    case (cnt)
                                        1: lcd_data_reg <= "M";
                                        2: lcd_data_reg <= "O";
                                        3: lcd_data_reg <= "D";
                                        4: lcd_data_reg <= "E";
                                        5: lcd_data_reg <= " ";
                                        6: lcd_data_reg <= ":";
                                        default: lcd_data_reg <= " ";
                                    endcase
                                end

                                //------------------------------------------------
                                // msg_sel=10 -> "WATCH"
                                //------------------------------------------------
                                2'b10: begin
                                    case (cnt)
                                        1: lcd_data_reg <= "M";
                                        2: lcd_data_reg <= "O";
                                        3: lcd_data_reg <= "D";
                                        4: lcd_data_reg <= "E";
                                        5: lcd_data_reg <= " ";
                                        6: lcd_data_reg <= ":";
                                        default: lcd_data_reg <= " ";
                                    endcase
                                end

                                //------------------------------------------------
                                // msg_sel=11 -> "TIMER"
                                //------------------------------------------------
                                2'b11: begin
                                    case (cnt)
                                        1: lcd_data_reg <= "S";
                                        2: lcd_data_reg <= "E";
                                        3: lcd_data_reg <= "U";
                                        4: lcd_data_reg <= "N";
                                        5: lcd_data_reg <= "G";
                                        6: lcd_data_reg <= "C";
                                        7: lcd_data_reg <= "H";
                                        8: lcd_data_reg <= "A";
                                        9: lcd_data_reg <= "N";
                                        default: lcd_data_reg <= " ";
                                    endcase
                                end
                            endcase
                        end
                    endcase
                end

                //------------------------------------
                // (B) 둘째 줄 (line2) 쓰기
                //------------------------------------
                line2: begin
                    lcd_rw_reg <= 1'b0;
                    case (cnt)
                        // 커서: 라인2 시작 주소 (0xC0)
                        0: begin
                            lcd_rs_reg   <= 1'b0;
                            lcd_data_reg <= 8'b11000000; // 0xC0
                        end

                        // 실제 문자 출력 구간
                        default: begin
                            lcd_rs_reg <= 1'b1;
                            case (msg_sel)
                                //------------------------------------------------
                                // msg_sel=00 -> "WORLD"
                                //------------------------------------------------
                                2'b00: begin
                                    case (cnt)
                                        1: lcd_data_reg <= "W";
                                        2: lcd_data_reg <= "A";
                                        3: lcd_data_reg <= "T";
                                        4: lcd_data_reg <= "C";
                                        5: lcd_data_reg <= "H";
                                        default: lcd_data_reg <= " ";
                                    endcase
                                end

                                //------------------------------------------------
                                // msg_sel=01 -> "12345"
                                //------------------------------------------------
                                2'b01: begin
                                    case (cnt)
                                        1: lcd_data_reg <= "S";
                                        2: lcd_data_reg <= "T";
                                        3: lcd_data_reg <= "O";
                                        4: lcd_data_reg <= "P";
                                        5: lcd_data_reg <= "W";
                                        6: lcd_data_reg <= "A";
                                        7: lcd_data_reg <= "T";
                                        8: lcd_data_reg <= "C";
                                        9: lcd_data_reg <= "H";
                                        default: lcd_data_reg <= " ";
                                    endcase
                                end

                                //------------------------------------------------
                                // msg_sel=10 -> "STOPW"
                                //------------------------------------------------
                                2'b10: begin
                                    case (cnt)
                                        1: lcd_data_reg <= "T";
                                        2: lcd_data_reg <= "I";
                                        3: lcd_data_reg <= "M";
                                        4: lcd_data_reg <= "E";
                                        5: lcd_data_reg <= "R";
                                        default: lcd_data_reg <= " ";
                                    endcase
                                end

                                //------------------------------------------------
                                // msg_sel=11 -> "TIMER"
                                //------------------------------------------------
                                2'b11: begin
                                    case (cnt)
                                        1: lcd_data_reg <= "J";
                                        2: lcd_data_reg <= "O";
                                        3: lcd_data_reg <= "N";
                                        4: lcd_data_reg <= "G";
                                        5: lcd_data_reg <= "M";
                                        6: lcd_data_reg <= "I";
                                        7: lcd_data_reg <= "N";
                                        default: lcd_data_reg <= " ";
                                    endcase
                                end
                            endcase
                        end
                    endcase
                end

                //------------------------------------
                // (C) 임시 딜레이 상태
                //------------------------------------
                delay_t: begin
                    // 커서 홈 이동 명령(옵션)
                    lcd_rs_reg   <= 1'b0;
                    lcd_rw_reg   <= 1'b0;
                    // 0000_0010 = 0x02 : Return Home
                    lcd_data_reg <= 8'b00000010;
                end

                //------------------------------------
                // (D) 화면 지우기 상태
                //------------------------------------
                clear_disp: begin
                    lcd_rs_reg   <= 1'b0;
                    lcd_rw_reg   <= 1'b0;
                    // 0000_0001 = 0x01 : Clear display
                    lcd_data_reg <= 8'b00000001;
                end

                //------------------------------------
                // (E) 기본값
                //------------------------------------
                default: begin
                    lcd_rs_reg   <= 1'b1;
                    lcd_rw_reg   <= 1'b1;
                    lcd_data_reg <= 8'b00000000;
                end
            endcase
        end
    end

endmodule