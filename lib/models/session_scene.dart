import 'package:flutter/material.dart';

/// Bối cảnh hình ảnh cho buổi thiền.
///
/// Hội đồng góp ý rằng một bối cảnh cố định — làng quê Việt Nam — chưa chắc
/// gần gũi với số đông, và nên cho người dùng tự chọn (Dr. Tuan, Dr. Silas).
/// Cả hai bản dùng chung một kịch bản, một mốc beat, một lớp tương tác; chỉ
/// khác phần hình. Cả hai đều sạch chữ: bản quê dùng nguồn Full HD không
/// phụ đề, bản biển vốn dựng riêng nên không có.
enum SessionScene {
  countryside(
    id: 'countryside',
    label: 'Vietnamese countryside',
    description: 'Sunrise courtyards, still water and a quiet village lane',
    asset: 'assets/video/meditation_narration_8min_v4.mp4',
    swatch: Color(0xFFC08A5E),
  ),
  beach(
    id: 'beach',
    label: 'Beach, dawn to night',
    description: 'Open horizon, slow waves, the light changing through the day',
    asset: 'assets/video/beach_narration_8min_v3.mp4',
    swatch: Color(0xFF5A8CB8),
  );

  const SessionScene({
    required this.id,
    required this.label,
    required this.description,
    required this.asset,
    required this.swatch,
  });

  final String id;
  final String label;
  final String description;
  final String asset;

  /// Màu đại diện, dùng cho ô chọn khi chưa có ảnh xem trước.
  final Color swatch;

  static SessionScene fromId(String? id) => SessionScene.values.firstWhere(
    (s) => s.id == id,
    orElse: () => SessionScene.countryside,
  );
}
