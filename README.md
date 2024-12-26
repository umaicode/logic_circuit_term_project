# 2024-2 : 논리회로 설계 및 실험 텀프로젝트 : 전자시계
브랜치 도어 한번 해봤습니다.
도어를 삭제하고 싶습니다.

## 1. top_module.v
* **모든 .v 파일 모듈화**
* top_module을 통해 FSM 구성 후 제어
* 1 MHz
    * stopwatch.v
    * piezo.v
* 1 MHz -> 1 kHz
    * watch.v
    * timer.v
* 1 MHz -> 1 kHz -> 100 Hz
  * textlcd.v


---
## 2. watch.v
  * 1 kHz 사용
  * HH:MM:SS 출력
  * 키패드 입력 처리, 시간 설정, 시계 동작 로직 구현
  * 키패드 입력 숫자로 변환하는 함수 구현


---
## 3. stopwatch.v
  * 1 MHz 사용
  * HH:MM:SS:MSMS 출력
  * watch.v와 로직 동일


---
## 4. timer.v
  * 1 kHz 사용
  * HH:MM:SS 출력
  * watch.v는 증가시키는 로직. timer.v는 감소시키는 로직 구현
  * LED control : timer_done 트리거 발생 시 LED 5회 Blink
  * timer_done 트리거 top_module로 넘겨서 piezo_melody.v에 전달


---
## 5. textlcd.v
  * 100 Hz 사용
  * FSM 구현하여 MODE에 따라 다른 텍스트 출력 (MODE 0 : watch, MODE 1 : stopwatch, MODE 2 : timer)


---
## 6. clock_divider_1k.v
  * 1 MHz -> 1 kHz 분주기
  * 시계는 1초를 세기 떄문에 1 kHz가 필요하나 Piezo의 경우 1 MHz가 필요하여 분주기 설정


---
## 7. peizo_melody.v
  * FSM 구현 (0 : IDLE, 1 : PLAY, 2 : DONE)
  * C4 -> D4 -> E4 -> F4 -> G4 -> A4 -> B4 -> C5 (0.5초 후 다음 음으로 가는 로직)


---
## 8. seg_decode.v
  * 입력받은 숫자 7-segment로 디코딩
  * a, b, c, d, e, f, g, com -> 8b'00000000 방식


---
## I/O ports
|포트이름|핀 번호|하드웨어 설명|
|:--------------:|:--------------:|:--------------:|
||||
||__INPUT__||
||||
|rst|U4|dip_sw_8|
|clk_1mhz|B6|main_clock1|
|mode|L7|Number : *|
|start|K6|Number : #|
|dip_sw|Y1|Time Setting|
|dip_sw_timer|W3|Timer Setting|
||||
||__KEYPAD__||
||||
|keypad[9]|K2|Number : 9|
|keypad[8]|J2|Number : 8|
|keypad[7]|L5|Number : 7|
|keypad[6]|N5|Number : 6|
|keypad[5]|P6|Number : 5|
|keypad[4]|N1|Number : 4|
|keypad[3]|N4|Number : 3|
|keypad[2]|N8|Number : 2|
|keypad[1]|K4|Number : 1|
|keypad[0]|L1|Number : 0|
||||
||__TEXT_LCD__||
||||
|lcd_data[7]|D1|LCD_D7|
|lcd_data[6]|C1|LCD_D6|
|lcd_data[5]|C5|LCD_D5|
|lcd_data[4]|A2|LCD_D4|
|lcd_data[3]|D4|LCD_D3|
|lcd_data[2]|C3|LCD_D2|
|lcd_data[1]|B2|LCD_D1|
|lcd_data[0]|A4|LCD_D0|
|lcd_e|A6|LCD_E|
|lcd_rs|G6|LCD_RS|
|lcd_rw|D6|LCD_RW|
||||
||__PIEZO__||
|piezo_out|Y21|piezo|
||||
||__8-LED__||
||||
|led[7]|N5|LED_7|
|led[6]|M1|LED_6|
|led[5]|M3|LED_5|
|led[4]|M7|LED_4|
|led[3]|N7|LED_3|
|led[2]|M2|LED_2|
|led[1]|M4|LED_1|
|led[0]|L4|LED_0|
||||
||__7-SEGMENT__||
||||
|seg_com[7]|H4|AR_SEG_S0|
|seg_com[6]|H6|AR_SEG_S1|
|seg_com[5]|G1|AR_SEG_S2|
|seg_com[4]|G3|AR_SEG_S3|
|seg_com[3]|L6|AR_SEG_S4|
|seg_com[2]|K1|AR_SEG_S5|
|seg_com[1]|K3|AR_SEG_S6|
|seg_com[0]|K5|AR_SEG_S7|
|seg_data[7]|F1|AR_SEG_A|
|seg_data[6]|F5|AR_SEG_B|
|seg_data[5]|E2|AR_SEG_C|
|seg_data[4]|E4|AR_SEG_D|
|seg_data[3]|J1|AR_SEG_E|
|seg_data[2]|J3|AR_SEG_F|
|seg_data[1]|J7|AR_SEG_G|
|seg_data[0]|H2|AR_SEG_DP|


## Project Structure
```
.
├── README.md
├── final
│   ├── clock_divider_1k.v
│   ├── piezo_melody.v
│   ├── seg_decode.v
│   ├── stopwatch.v
│   ├── textlcd.v
│   ├── timer.v
│   ├── top_module.v
│   └── watch.v
├── original_code
│   ├── clock_divider_original.v
│   ├── peizo_original.v
│   ├── seg_decode.v
│   ├── state_app_original.v
│   ├── stopwatch_original.v
│   ├── textlcd_original.v
│   └── watch.v
└── test_final
    ├── seg_decode.v
    ├── state_app.v
    ├── stopwatch.v
    ├── textlcd.v
    ├── timer.v
    └── watch.v
```