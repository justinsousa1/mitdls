output "static_files_efs_drive_arn" {
  value = aws_efs_file_system.static_files_drive.arn
}

output "static_files_efs_drive_id" {
  value = aws_efs_file_system.static_files_drive.id
}
