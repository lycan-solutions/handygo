class WorkerStatsEntity {
  final int completedJobs;
  final int activeJobs;
  final double todayEarnings;
  final int cancellationRate;
  final int? avgResponseMinutes;
  final String? responseLabel;

  const WorkerStatsEntity({
    required this.completedJobs,
    required this.activeJobs,
    this.todayEarnings = 0,
    this.cancellationRate = 0,
    this.avgResponseMinutes,
    this.responseLabel,
  });
}
