# Bảng chân calculator · STEP-MAX10

Trong Quartus, mở `calculator.qpf`, chạy **Processing → Start → Start Analysis & Elaboration**, rồi mở **Assignments → Pin Planner**. Tìm tên ở cột **Node Name**, điền giá trị **Location** tương ứng và chọn **I/O Standard** là `3.3-V LVTTL` cho cả 41 chân. Top là `calculator_top`, device của project là `10M02SCM153I7G`. Nếu cột Location đã có giá trị, bạn có thể đối chiếu trực tiếp với bảng dưới.

## Clock, switch và nút nhấn

Switch ON có giá trị 1. Nút KEY khi nhấn có giá trị 0. Ở bước chọn phép, đọc mã theo thứ tự **SW2 SW1**: `00` cộng, `01` trừ, `10` nhân, `11` chia.

| Node Name | Location | Nhãn board | Chức năng |
|---|---|---|---|
| `clk_12mhz` | `PIN_J5` | CLK | Clock 12 MHz |
| `sw[0]` | `PIN_J12` | SW1 | Bit 0 của độ lớn hoặc bit 0 của mã phép |
| `sw[1]` | `PIN_H11` | SW2 | Bit 1 của độ lớn hoặc bit 1 của mã phép |
| `sw[2]` | `PIN_H12` | SW3 | Bit 2 của độ lớn |
| `sw[3]` | `PIN_H13` | SW4 | Bit dấu khi nhập A hoặc B (1 = âm) |
| `key[0]` | `PIN_J9` | KEY1 | Chốt bước nhập hoặc bắt đầu lượt mới |
| `key[1]` | `PIN_K14` | KEY2 | Xóa phép tính, về nhập A |
| `key[2]` | `PIN_J11` | KEY3 | Quay lại một bước hoặc sửa B |
| `key[3]` | `PIN_J14` | KEY4 | Reset |

## LED đơn

Mức 0 làm LED sáng. Số LED trong bảng là số in trên board.

| Node Name | Location | Nhãn board | Khi sáng |
|---|---|---|---|
| `led[0]` | `PIN_N15` | LED1 | Chọn phép cộng |
| `led[1]` | `PIN_N14` | LED2 | Chọn phép trừ |
| `led[2]` | `PIN_M14` | LED3 | Chọn phép nhân |
| `led[3]` | `PIN_M12` | LED4 | Chọn phép chia |
| `led[4]` | `PIN_L15` | LED5 | Đang nhập A |
| `led[5]` | `PIN_K12` | LED6 | Đang chọn phép |
| `led[6]` | `PIN_L11` | LED7 | Đang nhập B |
| `led[7]` | `PIN_K11` | LED8 | Số đang hiển thị là số âm |

## Hai LED RGB

Mỗi kênh sáng ở mức 0. RGB1 báo trạng thái máy, RGB2 báo dấu của số đang hiển thị. Các tên RGB1/RGB2 dưới đây theo nhãn vật lý trên board; trên schematic trang 4, RGB1 nối nhóm net `R/G/B-LED2`, còn RGB2 nối nhóm `R/G/B-LED1`.

| Kênh | Node Name RGB1 | Location | Node Name RGB2 | Location |
|---|---|---|---|---|
| Đỏ | `rgb1[2]` | `PIN_C15` | `rgb2[2]` | `PIN_G15` |
| Xanh lá | `rgb1[1]` | `PIN_C14` | `rgb2[1]` | `PIN_E15` |
| Xanh dương | `rgb1[0]` | `PIN_D12` | `rgb2[0]` | `PIN_E14` |

## Hai LED 7 đoạn

Mỗi chữ số có bus riêng, theo thứ tự `[6:0] = {a,b,c,d,e,f,g}`. Một đoạn sáng ở mức 1. Hai dấu chấm luôn tắt (0); hai chân common luôn bật (0).

| Đoạn | Node Name hàng chục | Location | Node Name hàng đơn vị | Location |
|---|---|---|---|---|
| a | `seg_tens[6]` | `PIN_E1` | `seg_ones[6]` | `PIN_A3` |
| b | `seg_tens[5]` | `PIN_D2` | `seg_ones[5]` | `PIN_A2` |
| c | `seg_tens[4]` | `PIN_K2` | `seg_ones[4]` | `PIN_P2` |
| d | `seg_tens[3]` | `PIN_J2` | `seg_ones[3]` | `PIN_P1` |
| e | `seg_tens[2]` | `PIN_G2` | `seg_ones[2]` | `PIN_N1` |
| f | `seg_tens[1]` | `PIN_F5` | `seg_ones[1]` | `PIN_C1` |
| g | `seg_tens[0]` | `PIN_G5` | `seg_ones[0]` | `PIN_C2` |
| Dấu chấm | `dp_tens` | `PIN_L1` | `dp_ones` | `PIN_R2` |
| Common | `digit_tens` | `PIN_E2` | `digit_ones` | `PIN_B1` |

**Kiểm tra sau khi nạp:** đặt cả bốn switch về 0, nhấn rồi thả KEY4. Calculator về bước nhập A: LED5 sáng, hai digit hiện `00`, RGB1 và RGB2 cùng xanh dương.
