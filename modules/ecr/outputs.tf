
output "arn" {
  description = "ARN of the repository"
  value       = aws_ecr_repository.repo.arn
}

output "name" {
  description = "ARN of the repository"
  value       = aws_ecr_repository.repo.name
}

output "repository_url" {
  description = "repository_url of the repository"
  value       = aws_ecr_repository.repo.repository_url
}

output "id" {
  description = "id of the repository"
  value       = aws_ecr_repository.repo.id
}
