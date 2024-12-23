module piezo_melody(
    input clk,           // 1MHz
    input rst,
    input start_melody,  // 1이면 멜로디 시작
    output reg piezo_out
);

    // 예: 각 음에 대응하는 토글 주기 값
    // 도(C4) ≈ 1MHz/(2*261.63) ~ 1911
    // 레(D4) ≈ 1703 ...
    parameter C4 = 1911; 
    parameter D4 = 1703;
    parameter E4 = 1517;
    // ... 등등

    // 멜로디 구간
    reg [15:0] tone_period;
    reg [31:0] cnt;
    reg [3:0] melody_step;
    reg [23:0] note_duration_cnt;  // 한 음을 재생할 시간

    always @(posedge clk or posedge rst) begin
        if(rst) begin
            piezo_out <= 1'b0;
            tone_period <= C4;
            cnt <= 0;
            melody_step <= 0;
            note_duration_cnt <= 0;
        end else begin
            if (!start_melody) begin
                // 멜로디 off 상태
                piezo_out <= 1'b0;
                cnt <= 0;
                note_duration_cnt <= 0;
                melody_step <= 0;
            end else begin
                // 멜로디 on 상태
                // 1) 톤 생성
                if(cnt >= tone_period) begin
                    cnt <= 0;
                    piezo_out <= ~piezo_out;
                end else begin
                    cnt <= cnt + 1;
                end

                // 2) 일정 시간 후 다음 음으로 넘어가기
                if(note_duration_cnt >= 500000) begin
                    // 예: 약 0.5초마다 다음 음
                    note_duration_cnt <= 0;
                    melody_step <= melody_step + 1;
                end else begin
                    note_duration_cnt <= note_duration_cnt + 1;
                end

                // 3) 음 결정
                case(melody_step)
                    0: tone_period <= C4;
                    1: tone_period <= D4;
                    2: tone_period <= E4;
                    3: tone_period <= C4;
                    // ...
                    8: begin
                        // 다 끝났으면 다시 멈추거나 반복
                        melody_step <= 0;
                    end
                    default: tone_period <= C4;
                endcase
            end
        end
    end
endmodule
