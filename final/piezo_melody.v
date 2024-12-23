module piezo_melody(
    input clk,           // 1MHz
    input rst,
    input start_melody,  // 1이면 멜로디 시작
    output reg piezo_out
);
    // 각 음에 대응하는 토글 주기 (1MHz 기준)
    // 도(C4) ≈ 1MHz/(2*261.63) ~ 1911
    // 레(D4) ≈ 1703
    // 미(E4) ≈ 1517
    // 파(F4) ≈ 1432
    // 솔(G4) ≈ 1276
    // 라(A4) ≈ 1136
    // 시(B4) ≈ 1012
    // 다음 옥타브 도(C5) ≈ 956 (또는 955)

    parameter C4 = 1911;
    parameter D4 = 1703;
    parameter E4 = 1517;
    parameter F4 = 1432;
    parameter G4 = 1276;
    parameter A4 = 1136;
    parameter B4 = 1012;
    parameter C5 =  956;

    // 내부 FSM 제어용
    reg [15:0] tone_period;
    reg [31:0] cnt;
    reg [3:0] melody_step;         // 0~7
    reg [23:0] note_duration_cnt;  // 한 음을 재생하는 시간 카운터

    // 2비트 상태: IDLE, PLAY, DONE
    reg [1:0] state;
    parameter IDLE = 2'd0, PLAY = 2'd1, DONE = 2'd2;

    always @(posedge clk or posedge rst) begin
        if(rst) begin
            state <= IDLE;
            piezo_out <= 1'b0;
            tone_period <= C4;
            cnt <= 0;
            melody_step <= 0;
            note_duration_cnt <= 0;
        end 
        else begin
            case (state)
                //----------------------------------
                // (A) IDLE
                //----------------------------------
                IDLE: begin
                    // 준비 상태
                    piezo_out <= 1'b0;
                    cnt <= 0;
                    note_duration_cnt <= 0;
                    melody_step <= 0;
                    // start_melody 신호가 1이면 PLAY로
                    if (start_melody) begin
                        state <= PLAY;
                    end
                end

                //----------------------------------
                // (B) PLAY
                //----------------------------------
                PLAY: begin
                    // 1) 톤 생성
                    if (cnt >= tone_period) begin
                        cnt <= 0;
                        piezo_out <= ~piezo_out;
                    end else begin
                        cnt <= cnt + 1;
                    end

                    // 2) 일정 시간(약 0.5초) 후 다음 음으로
                    if(note_duration_cnt >= 500_000) begin
                        note_duration_cnt <= 0;
                        melody_step <= melody_step + 1;
                    end else begin
                        note_duration_cnt <= note_duration_cnt + 1;
                    end

                    // 3) 음(tone_period) 결정
                    case(melody_step)
                        4'd0: tone_period <= C4;  // 도
                        4'd1: tone_period <= D4;  // 레
                        4'd2: tone_period <= E4;  // 미
                        4'd3: tone_period <= F4;  // 파
                        4'd4: tone_period <= G4;  // 솔
                        4'd5: tone_period <= A4;  // 라
                        4'd6: tone_period <= B4;  // 시
                        4'd7: tone_period <= C5;  // 다음옥타브 도
                        // 7번째 음까지 재생 후 다음이면 DONE
                        4'd8: begin
                            state <= DONE;
                        end
                        default: tone_period <= C4;
                    endcase
                end

                //----------------------------------
                // (C) DONE
                //----------------------------------
                DONE: begin
                    // 한 바퀴 후 종료
                    piezo_out <= 1'b0;
                    // start_melody 계속 1이어도 무시
                    if (!start_melody) state <= IDLE; // start_melody=0이면 대기
                end
            endcase
        end
    end
endmodule
