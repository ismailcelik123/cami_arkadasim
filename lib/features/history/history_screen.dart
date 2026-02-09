import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  // Dummy veri
  static const List<VisitedMosque> visitedMosques = [
    VisitedMosque(
      name: 'Kocatepe Camii',
      visitCount: 12,
      lastPrayer: 'Öğle',
      lastVisit: '5 dakika önce',
    ),
    VisitedMosque(
      name: 'Diyanet İşleri Camii',
      visitCount: 8,
      lastPrayer: 'İkindi',
      lastVisit: '2 saat önce',
    ),
    VisitedMosque(
      name: 'Hacı Bayram Camii',
      visitCount: 15,
      lastPrayer: 'Sabah',
      lastVisit: '1 gün önce',
    ),
    VisitedMosque(
      name: 'Fatih Camii',
      visitCount: 6,
      lastPrayer: 'Akşam',
      lastVisit: '3 gün önce',
    ),
    VisitedMosque(
      name: 'Ulus Camii',
      visitCount: 10,
      lastPrayer: 'Yatsı',
      lastVisit: '1 hafta önce',
    ),
    VisitedMosque(
      name: 'Ankara Merkez Camii',
      visitCount: 4,
      lastPrayer: 'Öğle',
      lastVisit: '2 hafta önce',
    ),
    VisitedMosque(
      name: 'Ahmet Hamdi Akseki Camii',
      visitCount: 9,
      lastPrayer: 'İkindi',
      lastVisit: '10 gün önce',
    ),
    VisitedMosque(
      name: 'Zafer Camii',
      visitCount: 7,
      lastPrayer: 'Akşam',
      lastVisit: '1 ay önce',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Geçmiş'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(12.0),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.9,
              ),
              delegate: SliverChildBuilderDelegate(
                (BuildContext context, int index) {
                  final mosque = visitedMosques[index];
                  return MosqueCard(mosque: mosque);
                },
                childCount: visitedMosques.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MosqueCard extends StatelessWidget {
  final VisitedMosque mosque;

  const MosqueCard({
    super.key,
    required this.mosque,
  });

  Color _getPrayerColor(String prayer) {
    switch (prayer) {
      case 'Sabah':
        return Colors.amber;
      case 'Öğle':
        return Colors.orange;
      case 'İkindi':
        return Colors.orange.shade800;
      case 'Akşam':
        return Colors.purple;
      case 'Yatsı':
        return Colors.indigo;
      default:
        return Colors.teal;
    }
  }

  IconData _getPrayerIcon(String prayer) {
    switch (prayer) {
      case 'Sabah':
        return FontAwesomeIcons.sun;
      case 'Öğle':
        return FontAwesomeIcons.cloud;
      case 'İkindi':
        return FontAwesomeIcons.cloudSun;
      case 'Akşam':
        return FontAwesomeIcons.moon;
      case 'Yatsı':
        return FontAwesomeIcons.moon;
      default:
        return FontAwesomeIcons.mosque;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      shadowColor: Colors.teal.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Colors.teal.withOpacity(0.05),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cami İkonu ve Adı
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.teal.withOpacity(0.15),
                    ),
                    child: const Center(
                      child: Icon(
                        FontAwesomeIcons.mosque,
                        color: Colors.teal,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mosque.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          mosque.lastVisit,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Ziyaret Sayısı
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.trending_up,
                      size: 14,
                      color: Colors.teal,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${mosque.visitCount} ziyaret',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.teal,
                      ),
                    ),
                  ],
                ),
              ),
              // Son Namaz Vakti
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _getPrayerColor(mosque.lastPrayer).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getPrayerIcon(mosque.lastPrayer),
                      size: 14,
                      color: _getPrayerColor(mosque.lastPrayer),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Son: ${mosque.lastPrayer}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _getPrayerColor(mosque.lastPrayer),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class VisitedMosque {
  final String name;
  final int visitCount;
  final String lastPrayer;
  final String lastVisit;

  const VisitedMosque({
    required this.name,
    required this.visitCount,
    required this.lastPrayer,
    required this.lastVisit,
  });
}
