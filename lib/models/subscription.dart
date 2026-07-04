enum SubscriptionStatus {
  active,
  inactive,
  pastDue,
  canceled,
  trialing,
}

enum SubscriptionTier {
  free,
  creator,
  pro,
  power,
}

class Subscription {
  final String id;
  final String userId;
  final SubscriptionStatus status;
  final SubscriptionTier tier;
  final String? stripeCustomerId;
  final String? stripeSubscriptionId;
  final String? stripePriceId;
  final DateTime? currentPeriodStart;
  final DateTime? currentPeriodEnd;
  final bool cancelAtPeriodEnd;
  final DateTime createdAt;
  final DateTime updatedAt;

  Subscription({
    required this.id,
    required this.userId,
    required this.status,
    required this.tier,
    this.stripeCustomerId,
    this.stripeSubscriptionId,
    this.stripePriceId,
    this.currentPeriodStart,
    this.currentPeriodEnd,
    this.cancelAtPeriodEnd = false,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isActive => status == SubscriptionStatus.active || status == SubscriptionStatus.trialing;
  bool get isPro => tier == SubscriptionTier.pro || tier == SubscriptionTier.power;
  bool get isPower => tier == SubscriptionTier.power;
}
