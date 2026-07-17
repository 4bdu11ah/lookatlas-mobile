part of '../../dashboard/presentation/screens/dashboard_screen.dart';

const _shoots = [
  _Shoot(
    name: 'Tan Leather Bag',
    status: 'completed',
    renders: 15,
    date: 'Jul 17, 2026',
    productAsset: '$_img/showcase-bag-before.jpg',
    modelAsset: '$_img/showcase-dress-after.jpg',
  ),
  _Shoot(
    name: 'Gold Evening Heels',
    status: 'processing',
    renders: 6,
    date: 'Today',
    productAsset: '$_img/showcase-shoes-before.jpg',
    modelAsset: '$_img/showcase-tshirt-after.jpg',
    progress: 0.64,
  ),
  _Shoot(
    name: 'Gold Evening Heels',
    status: 'failed',
    renders: 0,
    date: 'Jul 16, 2026',
    productAsset: '$_img/showcase-shoes-before.jpg',
    modelAsset: '$_img/showcase-dress-after.jpg',
    progress: 0,
    supportTicketId: 'job_7f2a9c13',
  ),
];

const _shotAssets = [
  '$_img/showcase-bag-after.jpg',
  '$_img/showcase-tshirt-after.jpg',
  '$_img/showcase-dress-after.jpg',
  '$_img/showcase-shoes-after.jpg',
];
