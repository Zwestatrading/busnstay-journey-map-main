import { useState, useEffect, useCallback, useRef } from 'react';
import { supabase } from '@/integrations/supabase/client';
import { parsePostGISPoint } from '@/types/database';

interface GPSSource {
  sourceId: string;
  sourceType: 'bus' | 'passenger' | 'rider';
  position: [number, number];
  accuracy: number;
  timestamp: Date;
  trustScore: number;
  heading?: number;
  speed?: number;
}

interface FusedPosition {
  position: [number, number];
  confidence: number;
  primarySource: string;
  sources: GPSSource[];
  isSpoofed: boolean;
  heading: number;
  speed: number;
}

interface TrustScore {
  sourceId: string;
  sourceType: string;
  score: number;
  spoofingFlags: number;
}

const SPOOFING_THRESHOLD = 500; // Max 500m/s (1800 km/h) - catches teleportation
const MIN_TRUST_SCORE = 0.1;
const MAX_TRUST_SCORE = 1.0;
const TRUST_DECAY = 0.01;
const TRUST_GAIN = 0.05;

export const useMultiGPSFusion = (journeyId: string | null) => {
  const [fusedPosition, setFusedPosition] = useState<FusedPosition | null>(null);
  const [sources, setSources] = useState<GPSSource[]>([]);
  const [trustScores, setTrustScores] = useState<Map<string, TrustScore>>(new Map());
  const lastPositionsRef = useRef<Map<string, { position: [number, number]; timestamp: Date }>>(new Map());

  // Calculate distance between two coordinates (Haversine)
  const calculateDistance = useCallback((
    lat1: number, lon1: number,
    lat2: number, lon2: number
  ): number => {
    const R = 6371000; // Earth radius in meters
    const dLat = (lat2 - lat1) * Math.PI / 180;
    const dLon = (lon2 - lon1) * Math.PI / 180;
    const a = 
      Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
      Math.sin(dLon / 2) * Math.sin(dLon / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c;
  }, []);

  // Detect spoofing based on impossible movement
  const detectSpoofing = useCallback((
    sourceId: string,
    newPosition: [number, number],
    timestamp: Date
  ): boolean => {
    const lastData = lastPositionsRef.current.get(sourceId);
    if (!lastData) return false;

    const distance = calculateDistance(
      lastData.position[0], lastData.position[1],
      newPosition[0], newPosition[1]
    );
    const timeDiff = (timestamp.getTime() - lastData.timestamp.getTime()) / 1000;

    if (timeDiff <= 0) return false;

    const speed = distance / timeDiff;
    return speed > SPOOFING_THRESHOLD;
  }, [calculateDistance]);

  // Update trust score for a source
  const updateTrustScore = useCallback(async (
    sourceId: string,
    sourceType: string,
    isSpoofed: boolean,
    accuracy: number
  ) => {
    const current = trustScores.get(sourceId) || {
      sourceId,
      sourceType,
      score: 0.5,
      spoofingFlags: 0,
    };

    let newScore = current.score;
    let newFlags = current.spoofingFlags;

    if (isSpoofed) {
      newScore = Math.max(MIN_TRUST_SCORE, newScore - 0.2);
      newFlags++;
    } else {
      // Adjust based on accuracy
      const accuracyBonus = accuracy < 10 ? TRUST_GAIN : accuracy < 50 ? TRUST_GAIN / 2 : 0;
      newScore = Math.min(MAX_TRUST_SCORE, newScore + accuracyBonus - TRUST_DECAY);
    }

    const updated: TrustScore = {
      ...current,
      score: newScore,
      spoofingFlags: newFlags,
    };

    setTrustScores(prev => new Map(prev).set(sourceId, updated));

    // Persist to database
    if (journeyId) {
      await supabase
        .from('gps_trust_scores')
        .upsert({
          journey_id: journeyId,
          source_id: sourceId,
          source_type: sourceType,
          trust_score: newScore,
          spoofing_flags: newFlags,
          last_validated_at: new Date().toISOString(),
        }, { onConflict: 'journey_id,source_id' });
    }

    return updated;
  }, [trustScores, journeyId]);

  // Process incoming GPS update
  const processGPSUpdate = useCallback((
    sourceId: string,
    sourceType: 'bus' | 'passenger' | 'rider',
    position: [number, number],
    accuracy: number,
    heading?: number,
    speed?: number
  ) => {
    const timestamp = new Date();
    const isSpoofed = detectSpoofing(sourceId, position, timestamp);

    // Update last position
    lastPositionsRef.current.set(sourceId, { position, timestamp });

    // Update trust score
    updateTrustScore(sourceId, sourceType, isSpoofed, accuracy);

    const trustScore = trustScores.get(sourceId)?.score || 0.5;

    const newSource: GPSSource = {
      sourceId,
      sourceType,
      position,
      accuracy,
      timestamp,
      trustScore: isSpoofed ? MIN_TRUST_SCORE : trustScore,
      heading,
      speed,
    };

    setSources(prev => {
      const filtered = prev.filter(s => s.sourceId !== sourceId);
      return [...filtered, newSource].slice(-20); // Keep last 20 sources
    });
  }, [detectSpoofing, updateTrustScore, trustScores]);

  // Fuse positions from multiple sources
  const fusePositions = useCallback(() => {
    if (sources.length === 0) return null;

    // Filter recent sources (last 30 seconds)
    const recentSources = sources.filter(
      s => Date.now() - s.timestamp.getTime() < 30000
    );

    if (recentSources.length === 0) return null;

    // Calculate weighted average position
    let totalWeight = 0;
    let weightedLat = 0;
    let weightedLng = 0;
    let weightedHeading = 0;
    let weightedSpeed = 0;

    // Prioritize bus GPS, then passengers with high trust
    const sortedSources = recentSources.sort((a, b) => {
      if (a.sourceType === 'bus' && b.sourceType !== 'bus') return -1;
      if (b.sourceType === 'bus' && a.sourceType !== 'bus') return 1;
      return b.trustScore - a.trustScore;
    });

    sortedSources.forEach(source => {
      // Weight = trust score / accuracy (lower accuracy = higher weight)
      const weight = source.trustScore / Math.max(source.accuracy, 1);
      totalWeight += weight;
      weightedLat += source.position[0] * weight;
      weightedLng += source.position[1] * weight;
      if (source.heading !== undefined) {
        weightedHeading += source.heading * weight;
      }
      if (source.speed !== undefined) {
        weightedSpeed += source.speed * weight;
      }
    });

    const fusedLat = weightedLat / totalWeight;
    const fusedLng = weightedLng / totalWeight;
    const fusedHeading = weightedHeading / totalWeight;
    const fusedSpeed = weightedSpeed / totalWeight;

    // Calculate confidence based on source agreement
    let maxDeviation = 0;
    sortedSources.forEach(source => {
      const distance = calculateDistance(
        fusedLat, fusedLng,
        source.position[0], source.position[1]
      );
      maxDeviation = Math.max(maxDeviation, distance);
    });

    // Confidence: 1.0 if all sources agree perfectly, decreases with deviation
    const confidence = Math.max(0, 1 - maxDeviation / 1000);

    // Check if any source is spoofed
    const isSpoofed = sortedSources.some(s => s.trustScore <= MIN_TRUST_SCORE);

    const fused: FusedPosition = {
      position: [fusedLat, fusedLng],
      confidence,
      primarySource: sortedSources[0].sourceId,
      sources: sortedSources,
      isSpoofed,
      heading: fusedHeading,
      speed: fusedSpeed,
    };

    setFusedPosition(fused);
    return fused;
  }, [sources, calculateDistance]);

  // Auto-fuse when sources change
  useEffect(() => {
    if (sources.length > 0) {
      fusePositions();
    }
  }, [sources, fusePositions]);

  // Subscribe to realtime GPS updates
  useEffect(() => {
    if (!journeyId) return;

    const channel = supabase
      .channel(`gps-fusion-${journeyId}`)
      .on(
        'postgres_changes',
        {
          event: 'INSERT',
          schema: 'public',
          table: 'gps_history',
          filter: `journey_id=eq.${journeyId}`,
        },
        (payload) => {
          const record = payload.new as {
            source_id: string;
            source_type: string;
            position: string;
            accuracy: number;
            heading: number;
            speed: number;
          };
          const position = parsePostGISPoint(record.position);
          if (position) {
            processGPSUpdate(
              record.source_id,
              record.source_type as 'bus' | 'passenger' | 'rider',
              position,
              record.accuracy || 10,
              record.heading,
              record.speed
            );
          }
        }
      )
      .subscribe();

    return () => {
      channel.unsubscribe();
    };
  }, [journeyId, processGPSUpdate]);

  // Load initial trust scores
  useEffect(() => {
    if (!journeyId) return;

    const loadTrustScores = async () => {
      const { data } = await supabase
        .from('gps_trust_scores')
        .select('*')
        .eq('journey_id', journeyId);

      if (data) {
        const scores = new Map<string, TrustScore>();
        data.forEach((row: { source_id: string; source_type: string; trust_score: number; spoofing_flags: number }) => {
          scores.set(row.source_id, {
            sourceId: row.source_id,
            sourceType: row.source_type,
            score: row.trust_score,
            spoofingFlags: row.spoofing_flags,
          });
        });
        setTrustScores(scores);
      }
    };

    loadTrustScores();
  }, [journeyId]);

  return {
    fusedPosition,
    sources,
    trustScores,
    processGPSUpdate,
    fusePositions,
  };
};

export default useMultiGPSFusion;
