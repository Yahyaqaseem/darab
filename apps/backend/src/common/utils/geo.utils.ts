export class GeoUtils {
  /**
   * Calculate distance between two coordinates in meters using Haversine formula
   */
  static haversineDistance(lat1: number, lon1: number, lat2: number, lon2: number): number {
    const R = 6371e3; // Earth radius in meters
    const φ1 = (lat1 * Math.PI) / 180;
    const φ2 = (lat2 * Math.PI) / 180;
    const Δφ = ((lat2 - lat1) * Math.PI) / 180;
    const Δλ = ((lon2 - lon1) * Math.PI) / 180;

    const a =
      Math.sin(Δφ / 2) * Math.sin(Δφ / 2) +
      Math.cos(φ1) * Math.cos(φ2) * Math.sin(Δλ / 2) * Math.sin(Δλ / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

    return R * c;
  }

  /**
   * Calculate initial compass bearing from Point A to Point B (0 to 360 degrees)
   */
  static calculateBearing(lat1: number, lon1: number, lat2: number, lon2: number): number {
    const φ1 = (lat1 * Math.PI) / 180;
    const φ2 = (lat2 * Math.PI) / 180;
    const Δλ = ((lon2 - lon1) * Math.PI) / 180;

    const y = Math.sin(Δλ) * Math.cos(φ2);
    const x =
      Math.cos(φ1) * Math.sin(φ2) -
      Math.sin(φ1) * Math.cos(φ2) * Math.cos(Δλ);
    const θ = Math.atan2(y, x);

    return (θ * 180 / Math.PI + 360) % 360;
  }

  /**
   * Check if target driver is in front of requester along travel vector
   * @param requesterLat Requester latitude
   * @param requesterLng Requester longitude
   * @param requesterBearing Requester driving direction (degrees)
   * @param targetLat Target driver latitude
   * @param targetLng Target driver longitude
   * @param targetBearing Target driver driving direction (degrees)
   * @param maxAngleDiff Max bearing difference in degrees (default 35 deg)
   */
  static isDriverAheadOnSameRoad(
    requesterLat: number,
    requesterLng: number,
    requesterBearing: number,
    targetLat: number,
    targetLng: number,
    targetBearing?: number,
    maxAngleDiff: number = 35
  ): boolean {
    // 1. Vector bearing from requester to target
    const vectorToTarget = this.calculateBearing(requesterLat, requesterLng, targetLat, targetLng);
    
    // Angle difference between driving direction and target position
    let diff = Math.abs(requesterBearing - vectorToTarget);
    if (diff > 180) diff = 360 - diff;

    if (diff > maxAngleDiff) {
      return false;
    }

    // 2. If target bearing is known, ensure they are traveling in the same direction
    if (targetBearing !== undefined) {
      let bearingDiff = Math.abs(requesterBearing - targetBearing);
      if (bearingDiff > 180) bearingDiff = 360 - bearingDiff;
      if (bearingDiff > 45) {
        return false;
      }
    }

    return true;
  }

  /**
   * Filter GPS speed anomalies and compute trusted max speed
   */
  static calculateTrustedMaxSpeed(speedReadings: number[]): { trustedMaxSpeed: number; averageSpeed: number } {
    if (!speedReadings || speedReadings.length === 0) {
      return { trustedMaxSpeed: 0, averageSpeed: 0 };
    }

    // Filter out physically implausible speeds for Iraqi roads (> 180 km/h or negative)
    const validSpeeds = speedReadings.filter((s) => s >= 0 && s <= 190);
    if (validSpeeds.length === 0) return { trustedMaxSpeed: 0, averageSpeed: 0 };

    // Sort speeds
    const sorted = [...validSpeeds].sort((a, b) => a - b);

    // Use 95th percentile to eliminate single point GPS spike (e.g. 250 km/h glitch)
    const p95Index = Math.min(Math.floor(sorted.length * 0.95), sorted.length - 1);
    const trustedMaxSpeed = Math.round(sorted[p95Index] * 10) / 10;

    const sum = validSpeeds.reduce((acc, curr) => acc + curr, 0);
    const averageSpeed = Math.round((sum / validSpeeds.length) * 10) / 10;

    return { trustedMaxSpeed, averageSpeed };
  }
}
