abstract final class BackupLimits {
  static const maxBytes = 16 * 1024 * 1024;
  static const exceededMessage = '备份超过16 MiB，请缩短备注后再导出或导入。';
}
