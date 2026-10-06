class GoalModel {
  final String id;
  final String title;
  final double targetAmount;
  final double currentAmount;
  final String targetDate;
  final double monthlyContribution;
  final String category;
  final String status;
  final DateTime? createdAt;

  const GoalModel({
    required this.id,
    required this.title,
    required this.targetAmount,
    required this.currentAmount,
    this.targetDate = '',
    this.monthlyContribution = 0.0,
    this.category = 'General',
    this.status = 'ACTIVE',
    this.createdAt,
  });

  double get progress {
    if (targetAmount <= 0) return 0.0;
    return (currentAmount / targetAmount).clamp(0.0, 1.0);
  }

  double get percentage => progress * 100;

  double get remaining => (targetAmount - currentAmount).clamp(0.0, double.infinity);

  factory GoalModel.fromJson(Map<String, dynamic> json) {
    return GoalModel(
      id: json['id'] as String? ?? 'goal_${DateTime.now().millisecondsSinceEpoch}',
      title: json['title'] as String? ?? json['name'] as String? ?? 'Financial Goal',
      targetAmount: (json['targetAmount'] is num)
          ? (json['targetAmount'] as num).toDouble()
          : (double.tryParse(json['targetAmount']?.toString() ?? '') ??
              (json['target'] is num ? (json['target'] as num).toDouble() : 0.0)),
      currentAmount: (json['currentAmount'] is num)
          ? (json['currentAmount'] as num).toDouble()
          : (double.tryParse(json['currentAmount']?.toString() ?? '') ??
              (json['current'] is num ? (json['current'] as num).toDouble() : 0.0)),
      targetDate: json['targetDate'] as String? ?? '',
      monthlyContribution: (json['monthlyContribution'] is num)
          ? (json['monthlyContribution'] as num).toDouble()
          : (double.tryParse(json['monthlyContribution']?.toString() ?? '') ??
              (json['monthlyContrib'] is num ? (json['monthlyContrib'] as num).toDouble() : 0.0)),
      category: json['category'] as String? ?? 'General',
      status: json['status'] as String? ?? 'ACTIVE',
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'targetDate': targetDate,
      'monthlyContribution': monthlyContribution,
      'category': category,
      'status': status,
    };
  }
}
