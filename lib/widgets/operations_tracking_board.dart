import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TrackingBoardEntity {
  final String id;
  final String label;
  final String status;
  final Color color;
  final double progress;
  final String detail;

  const TrackingBoardEntity({
    required this.id,
    required this.label,
    required this.status,
    required this.color,
    required this.progress,
    required this.detail,
  });
}

class OperationsTrackingBoard extends StatelessWidget {
  final String title;
  final String originLabel;
  final String destinationLabel;
  final List<TrackingBoardEntity> entities;
  final Color accentColor;

  const OperationsTrackingBoard({
    super.key,
    required this.title,
    required this.originLabel,
    required this.destinationLabel,
    required this.entities,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0F172A),
            accentColor.withValues(alpha: 0.92),
          ],
        ),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Live operations board',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 18),
          ...entities.asMap().entries.map((entry) {
            final laneIndex = entry.key;
            final entity = entry.value;
            return Padding(
              padding: EdgeInsets.only(bottom: laneIndex == entities.length - 1 ? 0 : 16),
              child: _TrackingLane(
                entity: entity,
                laneIndex: laneIndex,
                originLabel: originLabel,
                destinationLabel: destinationLabel,
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _TrackingLane extends StatelessWidget {
  final TrackingBoardEntity entity;
  final int laneIndex;
  final String originLabel;
  final String destinationLabel;

  const _TrackingLane({
    required this.entity,
    required this.laneIndex,
    required this.originLabel,
    required this.destinationLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              entity.label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            Text(
              entity.status,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final clampedProgress = entity.progress.clamp(0.02, 0.98);
            final markerLeft = (width - 28) * clampedProgress;

            return SizedBox(
              height: 50,
              child: Stack(
                children: [
                  Positioned(
                    left: 8,
                    right: 8,
                    top: 21,
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: Colors.white.withValues(alpha: 0.18),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 8,
                    right: width - ((width - 16) * clampedProgress),
                    top: 21,
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: entity.color,
                      ),
                    ),
                  ),
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeInOut,
                    left: markerLeft,
                    top: 8,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: entity.color,
                        boxShadow: [
                          BoxShadow(
                            color: entity.color.withValues(alpha: 0.45),
                            blurRadius: 14,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.navigation, size: 15, color: Colors.white),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    top: 0,
                    child: Text(
                      originLabel,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Colors.white60,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Text(
                      destinationLabel,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Colors.white60,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 6),
        Text(
          entity.detail,
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}

class CountdownBadge extends StatelessWidget {
  final String label;
  final Duration duration;
  final Color color;

  const CountdownBadge({
    super.key,
    required this.label,
    required this.duration,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final totalSeconds = duration.inSeconds;
    final safeSeconds = totalSeconds < 0 ? 0 : totalSeconds;
    final minutes = safeSeconds ~/ 60;
    final seconds = safeSeconds % 60;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        '$label ${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class ReportMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const ReportMetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}