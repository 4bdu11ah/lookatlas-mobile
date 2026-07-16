part of '../../dashboard/presentation/screens/dashboard_screen.dart';

const _creditPackSize = 80;
const _creditPackPrice = 20.0;

const _billingPlans = <_BillingPlan, _BillingPlanDetails>{
  _BillingPlan.starter: _BillingPlanDetails(
    name: 'Starter',
    monthlyPrice: 49,
    yearlyPrice: 40.83,
    credits: 80,
    tagline: 'For one drop a month',
    features: [
      '80 monthly credits (≈ 80 images)',
      'AI model photo generation',
      'Studio, lifestyle, and street styles',
      'High-resolution commercial exports',
    ],
    excludedFeatures: [
      'AI posing controls',
      'AI-generated product videos',
    ],
  ),
  _BillingPlan.pro: _BillingPlanDetails(
    name: 'Pro',
    monthlyPrice: 99,
    yearlyPrice: 82.50,
    credits: 200,
    tagline: 'For your catalog',
    isPopular: true,
    features: [
      '200 monthly credits (≈ 200 images or 3 videos)',
      'Everything in Starter',
      'AI posing controls',
      'AI-generated product videos',
      'Faster rendering and priority processing',
    ],
  ),
  _BillingPlan.business: _BillingPlanDetails(
    name: 'Business',
    monthlyPrice: 179,
    yearlyPrice: 149.17,
    credits: 800,
    tagline: 'For your catalog, ads, and social',
    features: [
      '800 monthly credits (≈ 800 images or 12 videos)',
      'Everything in Pro',
      'AI-generated product videos',
      'Priority rendering and priority processing',
      'Priority customer support',
    ],
  ),
};

const _billingHistory = [
  _BillingHistoryEntry(
    date: 'Jul 1, 2026, 9:14 AM',
    description: 'Pro plan renewal',
    amount: r'$99.00',
    credits: '+200',
    balance: '200',
  ),
  _BillingHistoryEntry(
    date: 'Jun 18, 2026, 2:36 PM',
    description: '80 credit pack',
    amount: r'$20.00',
    credits: '+80',
    balance: '137',
  ),
];

const _billingMockState = _BillingScreenState(
  creditsRemaining: 137,
  currentPlan: _BillingPlan.pro,
  currentCycle: _BillingCycle.monthly,
  selectedCycle: _BillingCycle.monthly,
  quantity: 1,
  action: _BillingAction.idle,
  cancellation: _BillingCancellationState(),
  historyRefreshing: false,
);
