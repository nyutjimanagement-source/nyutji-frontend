import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../providers/sentiment_provider.dart';

class AdminSentimentScreen extends StatelessWidget {
  const AdminSentimentScreen({Key? key}) : super(key: key);


  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SentimentProvider>();
    final summary = provider.summary;
    final sentiments = provider.sentiments;

    return Container(
      color: const Color(0xFFF3F4F6),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildHeader(),
          SliverToBoxAdapter(child: _buildSummaryGrid(summary)),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildSentimentCard(sentiments[index]),
                childCount: sentiments.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(24),
        color: const Color(0xFF111827),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "SENTIMENT AI ANALYSIS",
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Hasil Crawling Opini Media Sosial (X, IG, FB)",
              style: GoogleFonts.montserrat(fontSize: 11, color: Colors.grey[400]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryGrid(Map<String, dynamic> summary) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildSummaryBox("Positif", summary['POSITIVE']?.toString() ?? '0', Colors.green),
          const SizedBox(width: 10),
          _buildSummaryBox("Netral", summary['NEUTRAL']?.toString() ?? '0', Colors.blue),
          const SizedBox(width: 10),
          _buildSummaryBox("Negatif", summary['NEGATIVE']?.toString() ?? '0', Colors.red),
        ],
      ),
    );
  }

  Widget _buildSummaryBox(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3), width: 2),
        ),
        child: Column(
          children: [
            Text(label, style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text(value, style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildSentimentCard(dynamic item) {
    final sentiment = item['sentiment'];
    Color sentimentColor = Colors.blue;
    IconData icon = LucideIcons.meh;

    if (sentiment == 'POSITIVE') {
      sentimentColor = Colors.green;
      icon = LucideIcons.smile;
    } else if (sentiment == 'NEGATIVE') {
      sentimentColor = Colors.red;
      icon = LucideIcons.frown;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(LucideIcons.user, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    item['author'] ?? 'Anonymous',
                    style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: sentimentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(icon, size: 10, color: sentimentColor),
                    const SizedBox(width: 4),
                    Text(
                      sentiment,
                      style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.bold, color: sentimentColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            item['content'] ?? '',
            style: GoogleFonts.montserrat(fontSize: 13, color: Colors.grey[800], height: 1.4),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item['platform'] ?? 'SOCIAL',
                style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue[800]),
              ),
              Text(
                item['crawled_at'] != null 
                    ? item['crawled_at'].toString().split('T')[0] 
                    : '',
                style: GoogleFonts.montserrat(fontSize: 9, color: Colors.grey[500]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
