# Kết quả kiểm chứng

Ngày kiểm tra: **22/10/2026**.

## Mở project Quartus

Đã tái hiện lỗi `125048` khi mở project thật: dòng `if` trong
`quartus/vending_machine.qsf` không được bộ đọc QSF chấp nhận. Đã bỏ dòng này và
sửa script build để ghi trực tiếp assignment `DEVICE` vào QSF.

Chạy `quartus_sh -t scripts/check_project.tcl` sau khi sửa:
**PASS project_open: vending_machine; 0 errors, 0 warnings**.
Kiểm tra này mở đúng project người dùng `quartus/vending_machine.qpf` và đọc cả
file gán chân, độc lập với project tạm dùng để kiểm tra tổng hợp logic.

## Mô phỏng

Bản RTL cuối cùng đã chạy thành công bằng cả **ModelSim Intel FPGA Edition 2020.1**
và **Icarus Verilog 12.0** qua `scripts/run_tests.ps1`.

| Testbench | Kết quả |
|---|---|
| `tb_vending_core` | PASS, 56 kiểm tra có thông báo và các kiểm tra bất biến liên tục |
| `tb_vending_top` | PASS, 14 kiểm tra giao diện board mô phỏng |
| `tb_primitives` | PASS, 16 mã giải mã ở hai cực tính và cấu hình chống dội tối thiểu |

ModelSim biên dịch và chạy các testbench với **0 errors, 0 warnings**. Chạy lại có thể
thấy thông báo `vlib-34` vì thư viện `work` đã tồn tại; đó không phải cảnh báo RTL.
Icarus thông báo rằng constant selects trong `always_comb` dùng toàn bộ các bit cho
sensitivity list; không có lỗi biên dịch hay mô phỏng.

Log ở `build/sim/ModelSim/` và `build/sim/Icarus/`, được bỏ qua trong Git.
Trong môi trường thực hiện này, các simulator cần chạy ngoài sandbox Windows của
agent; ở trong sandbox đã gặp lỗi DLL hoặc exit code của tiến trình. Không thay đổi
cấu hình bảo mật Windows, không chỉnh sửa cài đặt ModelSim. Bản Icarus bổ sung nằm
cục bộ trong `.tools/`, không đưa vào Git.

## Full compile theo schematic

Đã cập nhật theo `STEP-MAX10 Schematic.pdf` V2.0 trang 3–4:

- Device: **10M08SCM153C7G**.
- Sửa thứ tự 8 LED theo net schematic thay vì bảng Lab2.
- LED thường và RGB active low; segment active high; common active low.
- Chạy lại cả 3 testbench ModelSim với cực tính mới: PASS.

**Quartus Prime Lite 20.1.0, Full Compilation: Successful, 0 errors, 11 warnings.**
Đã chạy Analysis & Synthesis, Fitter, Assembler, Power Analyzer và Timing Analyzer.

Lệnh tái lập:

```powershell
./scripts/build_quartus.ps1 -Device 10M08SCM153C7G
```

File nạp đã tạo: `quartus/output_files/vending_machine.sof`. Chưa nạp lên board thật.

| Chỉ số sau fitter | Giá trị |
|---|---:|
| Logic elements | 345 |
| Registers | 126 |
| I/O pins | 41 |
| Memory bits | 0 |
| PLL | 0 |
| Errors | 0 |
| Warnings toàn flow | 11 |
| Worst setup slack | +72.999 ns |
| Worst hold slack | +0.150 ns |

Năm warning synthesis là thông báo `13024` và bốn `13410` về đầu ra cố định:
hai dấu chấm luôn tắt và hai common luôn bật. Các warning còn lại liên quan tới
license LogicLock, output drive strength để mặc định, yêu cầu điện áp input MAX 10,
và mô hình ước lượng công suất. Warning `15714` không phải thiếu vị trí chân:
I/O Assignment Warnings ghi rõ **Missing drive strength** cho output; toàn bộ 41
cổng đã được gán vị trí và chuẩn I/O `3.3-V LVTTL`.

Có critical warning `16562` yêu cầu xem công suất cho chip single-supply.
Power Analyzer đã chạy, ước lượng **148.33 mW**, confidence thấp do dùng vectorless
activity và chưa có board thermal model; đây không phải phép đo trên phần cứng.

Timing Analyzer: **0 errors, 0 warnings**, không có đường input/output thiếu ràng buộc
trong báo cáo (các tín hiệu thao tác tay/LED được khai báo false path trong SDC).
Các báo cáo đầy đủ ở `quartus/output_files/vending_machine.{fit,sta,pow}.rpt`.

Lần kiểm tra logic ban đầu với part đại diện `10M08SAE144C8G` ở `build/synthesis/`
là kết quả trước khi đối chiếu schematic; báo cáo full compile trên là kết quả cập nhật.

## Chưa kiểm chứng trên phần cứng

- Chưa đối chiếu revision và ký hiệu chip trên board thực với schematic V2.0.
- Chưa nạp `.sof` và chưa thử trực tiếp nút/LED; thứ tự vật lý hai digit cần kiểm tra khi demo.
- Schematic trang 4 đảo số designator RGB so với tên net; xem `docs/PINOUT.md`.

Mô phỏng và synthesis chứng minh hành vi logic trong phạm vi các kiểm tra đã nêu;
không thay thế bước chạy thử trên board.
