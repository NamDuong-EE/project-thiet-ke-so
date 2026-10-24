# Máy bán hàng tự động mini trên FPGA

Project môn Thiết kế số bằng **SystemVerilog**, dựa trên Lab 2–8 trong `docs/`.
Mục tiêu: có FSM, mạch tổ hợp, thanh ghi/bộ đếm và tương tác với ngoại vi trên board.

Máy bán 3 sản phẩm **A = 5, B = 10, C = 15** đơn vị tiền. Người dùng chọn sản phẩm,
nạp tiền 1/2/5, mua hoặc hủy giao dịch. LED mô phỏng nhả hàng; LED 7 đoạn hiển thị
số dư, giá hàng đang nhả hoặc tiền hoàn. Không có cơ cấu nhả hàng hay trả tiền thật.

## Bắt đầu

Mở PowerShell ở thư mục dự án và chạy mô phỏng bằng ModelSim:

```powershell
./scripts/run_tests.ps1 -Simulator ModelSim -ToolDirectory C:/intelFPGA_lite/20.1/modelsim_ase/win32aloem
```

Nếu simulator đã có trên `PATH`, có thể bỏ `-ToolDirectory`. Với Icarus Verilog:

```powershell
./scripts/run_tests.ps1 -Simulator Icarus
```

Script không tải hay cài phần mềm. Nó tìm công cụ trên `PATH`, hoặc bản Icarus cục bộ
ở `.tools/mingw64/bin`. Các file mô phỏng và log được lưu dưới `build/sim/`.
Mỗi testbench phải có dòng `PASS` và thoát thành công; nếu không, script báo lỗi.

Muốn xem waveform trong ModelSim, chạy trong cửa sổ Transcript:

```tcl
do C:/Users/admin/Documents/GitHub/project-Thiet-ke-so/sim/wave.do
```

Đổi đường dẫn trên nếu di chuyển dự án. Testbench dùng thời gian chờ rút ngắn;
thời gian chờ mặc định trên board vẫn là 2 giây.

## Cấu trúc

| File/thư mục | Vai trò |
|---|---|
| `rtl/vending_core.sv` | FSM và datapath giao dịch, độc lập board |
| `rtl/button_conditioner.sv` | Đồng bộ nút, chống dội, tạo một xung mỗi lần nhấn |
| `rtl/seven_segment.sv` | Giải mã số 0–9, hỗ trợ hai cực tính |
| `rtl/vending_top.sv` | Ghép ngoại vi STEP-MAX10 với bộ điều khiển |
| `tb/` | Ba testbench tự kiểm tra |
| `sim/` | Script ModelSim batch và waveform |
| `quartus/vending_machine.qpf` | Project mở bằng Quartus |
| `quartus/step_max10_pins.qsf` | Gán chân theo schematic STEP-MAX10 V2.0, trang 3–4 |
| `quartus/vending_machine.sdc` | Ràng buộc clock 12 MHz và tín hiệu bất đồng bộ |
| `scripts/` | Chạy mô phỏng, kiểm tra tổng hợp, build Quartus |
| `docs/DESIGN.md` | Kiến trúc, sơ đồ FSM và nội dung chuẩn bị vấn đáp |
| `docs/PINOUT.md` | Bảng chân đầy đủ, cực tính điện và cách xem trong Pin Planner |

## Thao tác trên board

Quy ước switch logic 1 là mức cao. KEY1 tương ứng `key[0]`, SW1 tương ứng `sw[0]`.
Đổi switch và để ổn định trước khi bấm nút. Sau khi nạp FPGA, **bấm KEY4 để reset**.

| Đầu vào | Chức năng |
|---|---|
| `{SW2, SW1}` = `00` / `01` / `10` | Chọn A / B / C |
| `{SW2, SW1}` = `11` | Sản phẩm không hợp lệ |
| `{SW4, SW3}` = `00` / `01` / `10` | Chọn mệnh giá 1 / 2 / 5 |
| `{SW4, SW3}` = `11` | Mệnh giá không hợp lệ |
| KEY1 | Nạp một đồng theo mệnh giá đã chọn |
| KEY2 | Mua sản phẩm đã chọn |
| KEY3 | Hủy, hoàn toàn bộ số dư |
| KEY4 | Reset hệ thống, xóa số dư và giao dịch |

| Đầu ra | Ý nghĩa |
|---|---|
| LED 7 đoạn | Chờ: số dư; nhả hàng: giá sản phẩm; hoàn tiền: tiền hoàn; lỗi: số dư giữ lại |
| LED1 / LED2 / LED3 | Sản phẩm A / B / C đang được nhả; khi lỗi, ba LED này là mã lỗi nhị phân |
| LED4 | Sẵn sàng nhận thao tác |
| LED5 | Đang nhả hàng |
| LED6 | Đang hoàn tiền |
| LED7 | Có lỗi |
| LED8 | Đang bận, không nhận thao tác mới |
| RGB1 | Xanh dương: chờ/kiểm tra; xanh lá: nhả hàng; cyan: hoàn tiền; đỏ: lỗi |
| RGB2 | Sản phẩm trên switch: A đỏ, B xanh lá, C xanh dương, không hợp lệ thì tắt |

Trong lúc giao dịch bận, RGB2 vẫn phản ánh switch hiện tại; sản phẩm thực sự được
nhả đã chốt lúc nhấn KEY2 và được thể hiện bằng LED1–3.

Mã lỗi đọc theo thứ tự `{LED3, LED2, LED1}` khi LED7 sáng:

| Mã | Nguyên nhân | Xử lý |
|---|---|---|
| `001` | Sản phẩm không hợp lệ | Giữ số dư |
| `010` | Mệnh giá không hợp lệ | Không cộng tiền |
| `011` | Chưa đủ tiền | Giữ số dư, chờ nạp thêm |
| `100` | Nạp làm số dư vượt 99 | Từ chối toàn bộ đồng vừa nạp, giữ số dư cũ |

Lỗi tự tắt sau 2 giây. Nhấn nút khi đang nhả hàng/hoàn tiền/báo lỗi sẽ bị bỏ qua;
phải nhả và bấm lại khi LED4 sáng. Nếu nhiều xung nút đến cùng một chu kỳ:
**hủy > mua > nạp tiền**. Reset luôn có ưu tiên cao nhất.

## Demo mẫu

1. Bấm KEY4. Màn hình hiển thị `00`, LED4 sáng.
2. Chọn B: `{SW2,SW1}=01`. Chọn tiền 5: `{SW4,SW3}=10`.
3. Bấm KEY1: số dư `05`. Bấm KEY2: báo thiếu tiền, số dư vẫn `05`.
4. Chờ hết lỗi, bấm KEY1 lần nữa: số dư `10`.
5. Đổi `{SW4,SW3}=01`, bấm KEY1: số dư `12`.
6. Bấm KEY2: LED2 và LED5 sáng trong 2 giây, màn hình hiển thị giá `10`.
7. LED6 sáng, màn hình hiển thị tiền dư `02` trong 2 giây, sau đó về `00`.
8. Nạp một khoản bất kỳ, bấm KEY3 để demo hoàn lại toàn bộ tiền.

## Quartus và phần cứng

Mở `quartus/vending_machine.qpf` bằng Quartus Prime Lite. Project đã chọn
**10M08SCM153C7G** theo ký hiệu FPGA trong `docs/STEP-MAX10 Schematic.pdf`.
Bảng chân và cực tính đã được đối chiếu trang 3–4; xem chi tiết `docs/PINOUT.md`.
Nếu chip thực tế trên board là biến thể 10M02 hoặc revision khác, chọn lại Device tương ứng.

Trước khi tạo file nạp:

1. Đọc part number trên chip hoặc project mẫu của đúng board.
2. Trong Quartus, chọn **Assignments → Device** và chọn đúng part number.
3. Đối chiếu `step_max10_pins.qsf` với revision board; bảng hiện tại theo schematic V2.0.
4. Kiểm tra mức điện áp I/O: file đang đặt `3.3-V LVTTL`.
5. Kiểm tra cực tính nút, LED, segment và chân enable theo sơ đồ board thực tế.
6. Compile Design, xem Timing Analyzer, rồi dùng Programmer để nạp `.sof`.

Cũng có thể build bằng PowerShell, truyền part number thực tế:

```powershell
./scripts/build_quartus.ps1 -Device 10M08SCM153C7G
```

Mã chip trên là mã trong schematic; thay lại nếu board thực tế dùng biến thể khác.
Script ghi một dòng `DEVICE` vào `quartus/vending_machine.qsf` và chạy full compile.
Lựa chọn này chính là Device được hiển thị trong GUI. Script không tự nạp FPGA.

Các tham số trong `vending_top.sv`:

| Tham số | Mặc định | Ý nghĩa |
|---|---|---|
| `CLK_HZ` | 12.000.000 | Clock board, cũng cần khớp file SDC |
| `DEBOUNCE_CYCLES` | `CLK_HZ / 50` | 20 ms chống dội |
| `HOLD_CYCLES` | `CLK_HZ * 2` | 2 giây cho mỗi pha nhả/hoàn/báo lỗi |
| `KEY_ACTIVE_LOW` | 1 | Nút nhấn ở mức thấp |
| `SEG_ACTIVE_LOW` | 0 | Segment sáng ở mức cao (common cathode) |
| `DIGIT_ACTIVE_LOW` | 1 | Enable mỗi digit ở mức thấp |
| `LED_ACTIVE_LOW` | 1 | LED thường sáng ở mức thấp |
| `RGB_ACTIVE_LOW` | 1 | LED RGB sáng ở mức thấp (common anode) |

Các cực tính trên được xác nhận từ trang 4 schematic. Hai digit có bộ chân segment riêng,
nên thiết kế điều khiển trực tiếp,
không quét multiplex. Nếu số hàng chục/hàng đơn vị đảo vị trí trên board, đổi hai nhóm pin.
Các tham số số chu kỳ phải là số nguyên dương.

Kiểm tra Quartus mở được project, bao gồm các file cấu hình và gán chân:

```powershell
& C:/intelFPGA_lite/20.1/quartus/bin64/quartus_sh.exe -t scripts/check_project.tcl
```

Kiểm tra tổng hợp logic độc lập board:

```powershell
& C:/intelFPGA_lite/20.1/quartus/bin64/quartus_sh.exe -t scripts/check_synthesis.tcl
```

Script này chỉ chạy Analysis & Synthesis với part đại diện `10M08SAE144C8G`,
không gán chân, không chạy fitter và không tạo file nạp cho board.

## Kiểm thử và phạm vi

- `tb_vending_core`: 56 kiểm tra có thông báo, kèm các kiểm tra bất biến chạy liên tục.
  Bao gồm đủ tiền, tiền dư, cả ba sản phẩm, thiếu tiền, hủy, lỗi đầu vào, giới hạn 99,
  chốt sản phẩm, thứ tự ưu tiên nút, bỏ qua thao tác khi bận, thời gian hiển thị và reset.
- `tb_vending_top`: 14 kiểm tra qua đầu vào vật lý mô phỏng, gồm dội nút, giữ nút,
  nhả/bấm lại, hiển thị số, lựa chọn switch, đèn lỗi và reset trong khi nhả hàng.
- `tb_primitives`: đủ 16 mã đầu vào bộ giải mã (0–9 và blank), cả hai cực tính,
  và chống dội ở cấu hình tối thiểu một chu kỳ.

Kết quả chạy và giới hạn kiểm chứng được ghi trong `docs/VALIDATION.md`.
Bản này dùng giá cố định, không quản lý tồn kho, không lưu tiền khi mất nguồn/reset.
Hoàn tiền chỉ được biểu diễn bằng số trên LED 7 đoạn. Có thể mở rộng tồn kho sau khi
bản cơ bản chạy ổn trên board.
