# Gán chân STEP-MAX10 theo schematic

Nguồn: `STEP-MAX10 Schematic.pdf`, revision V2.0, trang 3 (FPGA) và trang 4
(LED, nút, switch, LED 7 đoạn). Ký hiệu chip trong schematic là
`MAX10M08SCM153C7G`; tên Device trong Quartus là **10M08SCM153C7G**.

File `quartus/step_max10_pins.qsf` đã chứa toàn bộ assignment bên dưới và được
`quartus/vending_machine.qsf` nạp bằng `source`. Không cần gán lại từng chân.
Tên trong cột Cổng RTL phải khớp chính xác module top `vending_top`.

## Xem chân trong Quartus

1. Nếu project đang mở, đóng rồi mở lại `quartus/vending_machine.qpf` để đọc cấu hình mới.
2. Vào **Assignments → Device**, kiểm tra **10M08SCM153C7G** nếu board đúng schematic này.
3. Chạy **Processing → Start → Start Analysis & Elaboration** để nhận các cổng top.
4. Vào **Assignments → Pin Planner**, kiểm tra cột **Location** và **I/O Standard**.
5. Tất cả I/O trong bảng dùng **3.3-V LVTTL**. Chạy **Start Compilation** để tạo `.sof`.

Các vị trí như `J5` là tọa độ chân chip FPGA; trong file QSF ghi `PIN_J5`.
Các ngoại vi này đã được nối sẵn trên board, không cần nối dây jumper bên ngoài.

## Clock, switch, nút nhấn

| Cổng RTL | Net schematic | Location | Chức năng |
|---|---|---|---|
| `clk_12mhz` | CLK | J5 | Clock 12 MHz |
| `sw[0]` | SW1 | J12 | Bit thấp chọn sản phẩm |
| `sw[1]` | SW2 | H11 | Bit cao chọn sản phẩm |
| `sw[2]` | SW3 | H12 | Bit thấp chọn mệnh giá |
| `sw[3]` | SW4 | H13 | Bit cao chọn mệnh giá |
| `key[0]` | KEY1 | J9 | Nạp tiền |
| `key[1]` | KEY2 | K14 | Mua |
| `key[2]` | KEY3 | J11 | Hủy và hoàn tiền |
| `key[3]` | KEY4 | J14 | Reset |

Nút có điện trở kéo lên 3.3 V; nhấn nút kéo xuống GND, nên `KEY_ACTIVE_LOW=1`.
Switch có điện trở kéo xuống; đóng công tắc nối 3.3 V, nên ON tương ứng logic 1.

## LED thường

| Cổng RTL | Net schematic | Location | Chức năng |
|---|---|---|---|
| `led[0]` | LED1 | M12 | Sản phẩm A / bit 0 mã lỗi |
| `led[1]` | LED2 | N15 | Sản phẩm B / bit 1 mã lỗi |
| `led[2]` | LED3 | L11 | Sản phẩm C / bit 2 mã lỗi |
| `led[3]` | LED4 | N14 | Sẵn sàng |
| `led[4]` | LED5 | K11 | Đang nhả hàng |
| `led[5]` | LED6 | M14 | Đang hoàn tiền |
| `led[6]` | LED7 | K12 | Lỗi |
| `led[7]` | LED8 | L15 | Bận |

Trang 4 nối anode LED qua điện trở đến 3.3 V, cathode đến FPGA: xuất **0 để sáng**,
**1 để tắt**. Vì vậy `LED_ACTIVE_LOW=1`. Thứ tự LED ở đây khác bảng Lab2 trang 19;
cấu hình mới ưu tiên schematic bạn cung cấp.

## LED RGB

Vector dùng thứ tự `{red, green, blue}`.

| Cổng RTL | Net schematic | Location |
|---|---|---|
| `rgb1[2]` | R-LED1 | G15 |
| `rgb1[1]` | G-LED1 | E15 |
| `rgb1[0]` | B-LED1 | E14 |
| `rgb2[2]` | R-LED2 | C15 |
| `rgb2[1]` | G-LED2 | C14 |
| `rgb2[0]` | B-LED2 | D12 |

RGB có common anode nối 3.3 V, nên `RGB_ACTIVE_LOW=1`. Ví dụ xanh lá:
giá trị điện ở chân `{R,G,B}=101`; tắt hoàn toàn là `111`.

Schematic có điểm dễ nhầm: ở trang 4, ký hiệu linh kiện **LED1** dùng nhóm net
`R/G/B-LED2`, còn linh kiện **LED2** dùng nhóm net `R/G/B-LED1`.
Code `rgb1/rgb2` theo **tên net FPGA ở trang 3**, không theo số designator linh kiện
ở trang 4. Vì vậy vị trí vật lý hai đèn có thể trông đảo thứ tự so với tên cổng RTL.

## LED 7 đoạn

Mỗi vector có thứ tự **`[6:0] = {a,b,c,d,e,f,g}`**.

| Cổng hàng chục | Net | Pin | Cổng hàng đơn vị | Net | Pin |
|---|---|---|---|---|---|
| `seg_tens[6]` | SEG-A1 | E1 | `seg_ones[6]` | SEG-A2 | A3 |
| `seg_tens[5]` | SEG-B1 | D2 | `seg_ones[5]` | SEG-B2 | A2 |
| `seg_tens[4]` | SEG-C1 | K2 | `seg_ones[4]` | SEG-C2 | P2 |
| `seg_tens[3]` | SEG-D1 | J2 | `seg_ones[3]` | SEG-D2 | P1 |
| `seg_tens[2]` | SEG-E1 | G2 | `seg_ones[2]` | SEG-E2 | N1 |
| `seg_tens[1]` | SEG-F1 | F5 | `seg_ones[1]` | SEG-F2 | C1 |
| `seg_tens[0]` | SEG-G1 | G5 | `seg_ones[0]` | SEG-G2 | C2 |
| `dp_tens` | SEG-DP1 | L1 | `dp_ones` | SEG-DP2 | R2 |
| `digit_tens` | SEG-DIG1 | E2 | `digit_ones` | SEG-DIG2 | B1 |

Schematic vẽ common cathode: segment **1 sáng**, common **0 bật**.
Do đó `SEG_ACTIVE_LOW=0`, `DIGIT_ACTIVE_LOW=1`; dấu chấm tắt ở mức 0.
Ví dụ số 0 có `{a,b,c,d,e,f,g}=1111110`.

Hai nhóm segment có chân FPGA độc lập nên luôn bật cả hai common, không cần quét.
Việc gọi nhóm 1 là hàng chục và nhóm 2 là hàng đơn vị là quy ước của project;
nếu board bố trí ngược, đổi hai nhóm assignment hoặc đổi dữ liệu hai bộ giải mã.

## Tham số đã chỉnh trong RTL

```systemverilog
parameter bit KEY_ACTIVE_LOW   = 1'b1;
parameter bit SEG_ACTIVE_LOW   = 1'b0;
parameter bit DIGIT_ACTIVE_LOW = 1'b1;
parameter bit LED_ACTIVE_LOW   = 1'b1;
parameter bit RGB_ACTIVE_LOW   = 1'b1;
```

Sau khi nạp, bấm KEY4: màn hình `00`, LED sẵn sàng sáng. Đó là phép thử nhanh
để kiểm tra clock, reset, cực tính và hai nhóm LED 7 đoạn trên phần cứng.
