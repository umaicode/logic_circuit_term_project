# 2024-2 : 논리회로 설계 및 실험 텀프로젝트

## watch.v

### line 1 ~ 16
시계 로직의 Top Project 파일로 입/출력 포트와 로직에서 사용할 변수를 선언한 부분이다.

### line 22 ~ 49
위의 로직은 clk의 입려을 받아 카운트하는 에제이다. 1kHz의 클러 입력을 받기 때문에 첫번째 always 문에서는 1초를 카운트하도록 1000번을 카운트한다. 두번째 always 문에서는 앞의 1초를 카운트할 때 마다 s_one를 카운트하여, 1의 자리의 초를 카운트하도록 설계하였고, 아래의 로직들도 이와 비슷하게 각각 10의 자리의 초, 1의 자리의 분, 10의 자리의 분을 카운트 하도록 설계하였다.

### line 53 ~ 56
위의 로직은 앞에서 카운트한 초, 분의 값을 7-segment에서 표시할 데이터로 디코딩하는 seg_decode 파일과 연결하는 부분이다. 이 디코딩 로직은 아래에서 다시 설명한다.

### line 61 ~ 85
위의 로직은 앞에서 디코딩한 데이터를 7-segment에 표시하기 위한 블록이다. 클럭을 이용해 카운트하여, 7-segment을 선택하고(seg_com), 각 선택하였을 때의 데이터를 전달(seg_data)하도록 설계되어 있다.

### TODO
시간 구현 로직 추가함.

## watch_2.v
### 주요 변경 사항
1. keypad 기반 시간 설정:
   - '*' 키로 설정 시작, '#' 키로 완료.
   - 설정 중에는 시간 카운트가 멈춤
2. 각 자리별 always 블록 분리:
   - 초, 분, 시를 독립적으로 처리.
3. 코드의 가독성 및 유지보수성 개선:
   - 시간 설정 로직과 시간 카운트 로직이 명확히 분리됨.
### 추가 수정 사항
keypad decoder 필요. 

## watch_3.v
### 주요 변경 사항
1. 스톱워치 구현
2. mode[00] = watch, mode[01] = stop_watch => 알람 구현 아직 안함. mode도 되는지 모름.
3. mode 변경은 reset button처럼 버튼으로 구현하고자 함.
4. LCD는 책을 먼저 보고 결정.

## watch_4.v
### 주요 변경 사항
1. lcd 구현

## textlcd.v
1. watch_4.v, lcd_control.v 와 세트

## textlcd_original.v
1. textlcd.v의 원본


## seg_decode.v

이 로직은 앞의 예제에서 설계한 7-segment decoder의 회로이다. data_in이라는 4비트의 포트의 입력이 들어왔을 때, 해당 값을 표시할 수 있는 7-segment 디코딩 값이 출력되도록 설계되었다.

## I/O ports
### watch.v
|포트이름|핀 번호|하드웨어 설명|
|:------------:|:------------:|:------------:|
|rst|K4|SW_1|
|clk|B6|main_clock1|
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

### textlcd.v
|포트이름|핀 번호|하드웨어 설명|
|:------------:|:------------:|:------------:|
|rst|K4|SW_1|
|clk|B6|main_clock1|
||||
|lcd_data[7]|D1|LCD_D7|
|lcd_data[6]|C1|LCD_D6|
|lcd_data[5]|C5|LCD_D5|
|lcd_data[4]|A2|LCD_D4|
|lcd_data[3]|D4|LCD_D3|
|lcd_data[2]|C3|LCD_D2|
|lcd_data[1]|B2|LCD_D1|
|lcd_data[0]|A4|LCD_D0|
|lcd_e|F5|LCD_E|
|lcd_rs|E2|LCD_RS|
|lcd_rw|E4|LCD_RW|