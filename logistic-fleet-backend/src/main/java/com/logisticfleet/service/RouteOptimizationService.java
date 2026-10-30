package com.logisticfleet.service;

import com.logisticfleet.dto.RouteOptimizationDtos.OptimizeRouteRequest;
import com.logisticfleet.dto.RouteOptimizationDtos.OptimizeRouteResponse;
import com.logisticfleet.dto.RouteOptimizationDtos.OptimizedStop;
import com.logisticfleet.dto.TripDtos.RouteStopDto;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.ArrayList;
import java.util.List;

/**
 * Works out the shortest order to visit a driver's stops in.
 * <p>
 * This is a nearest-neighbour construction followed by 2-opt local search
 * over great-circle (haversine) distances — not a full VRP solver (no live
 * traffic, no delivery time windows, no multi-vehicle splitting). For the
 * handful of stops a single trip typically has (well under a hundred),
 * this heuristic gets close to optimal in milliseconds with no external
 * routing API or API key required.
 */
@Slf4j
@Service
public class RouteOptimizationService {

    /** Assumed average moving speed, used only to turn distance into a rough ETA. */
    private static final double AVERAGE_SPEED_KMPH = 30.0;
    private static final double EARTH_RADIUS_KM = 6371.0;
    /** Safety valve so a large, pathological stop list can't hang a request. */
    private static final int MAX_2OPT_SWEEPS = 40;

    public OptimizeRouteResponse optimize(OptimizeRouteRequest req) {
        List<RouteStopDto> stops = req.getStops();
        boolean hasOrigin = req.getOriginLat() != null && req.getOriginLng() != null;

        List<RouteStopDto> routable = new ArrayList<>();
        List<RouteStopDto> unroutable = new ArrayList<>();
        for (RouteStopDto s : stops) {
            if (s.getLatitude() != null && s.getLongitude() != null) {
                routable.add(s);
            } else {
                unroutable.add(s);
            }
        }

        if (routable.size() + (hasOrigin ? 1 : 0) < 2) {
            throw new IllegalArgumentException(
                    "Add latitude/longitude for at least two stops (or an origin point) to optimize a route");
        }

        int offset = hasOrigin ? 1 : 0;
        int n = routable.size() + offset;
        double[] lats = new double[n];
        double[] lngs = new double[n];
        if (hasOrigin) {
            lats[0] = req.getOriginLat().doubleValue();
            lngs[0] = req.getOriginLng().doubleValue();
        }
        for (int i = 0; i < routable.size(); i++) {
            lats[i + offset] = routable.get(i).getLatitude().doubleValue();
            lngs[i + offset] = routable.get(i).getLongitude().doubleValue();
        }

        int[] order = nearestNeighbourOrder(lats, lngs);
        order = twoOptImprove(order, lats, lngs, hasOrigin);

        List<OptimizedStop> result = new ArrayList<>();
        int sequence = 1;
        double totalKm = 0;

        for (int idx = 0; idx < order.length; idx++) {
            int pointIndex = order[idx];
            if (hasOrigin && pointIndex == 0) {
                continue; // the origin is the starting point, not a stop on the trip
            }

            BigDecimal legKm = null;
            if (idx > 0) {
                double d = haversine(lats[order[idx - 1]], lngs[order[idx - 1]], lats[pointIndex], lngs[pointIndex]);
                legKm = round(d);
                totalKm += d;
            }

            RouteStopDto stopDto = routable.get(pointIndex - offset);
            result.add(new OptimizedStop(stopDto, sequence++, legKm));
        }

        // Stops we couldn't place geographically (no coordinates) still get a
        // sequence number so they aren't silently dropped from the trip —
        // they just go last, in the order the dispatcher originally entered them.
        for (RouteStopDto s : unroutable) {
            result.add(new OptimizedStop(s, sequence++, null));
        }

        int etaMinutes = (int) Math.round((totalKm / AVERAGE_SPEED_KMPH) * 60);
        log.info("Route optimized: {} routable stop(s), {} unplaced, {} km total",
                routable.size(), unroutable.size(), totalKm);

        return new OptimizeRouteResponse(result, round(totalKm), etaMinutes);
    }

    /** Greedy nearest-neighbour construction starting at point 0 (the origin, when present). */
    private int[] nearestNeighbourOrder(double[] lats, double[] lngs) {
        int n = lats.length;
        boolean[] visited = new boolean[n];
        int[] order = new int[n];
        int current = 0;
        order[0] = current;
        visited[current] = true;

        for (int step = 1; step < n; step++) {
            int nearest = -1;
            double bestDist = Double.MAX_VALUE;
            for (int j = 0; j < n; j++) {
                if (visited[j]) continue;
                double d = haversine(lats[current], lngs[current], lats[j], lngs[j]);
                if (d < bestDist) {
                    bestDist = d;
                    nearest = j;
                }
            }
            order[step] = nearest;
            visited[nearest] = true;
            current = nearest;
        }
        return order;
    }

    /**
     * Classic 2-opt: repeatedly reverses a segment of the route whenever doing
     * so shortens the total path, until no improving swap is found (or the
     * sweep cap is hit). The origin, when present, is pinned at index 0 and
     * never moved.
     */
    private int[] twoOptImprove(int[] order, double[] lats, double[] lngs, boolean hasOrigin) {
        int n = order.length;
        int start = hasOrigin ? 1 : 0;
        boolean improved = true;
        int sweeps = 0;

        while (improved && sweeps < MAX_2OPT_SWEEPS) {
            improved = false;
            for (int i = start; i < n - 1; i++) {
                for (int k = i + 1; k < n; k++) {
                    double before = legLength(order, lats, lngs, i - 1, i) + legLength(order, lats, lngs, k, k + 1);
                    double after = legLength(order, lats, lngs, i - 1, k) + legLength(order, lats, lngs, i, k + 1);
                    if (after + 1e-9 < before) {
                        reverse(order, i, k);
                        improved = true;
                    }
                }
            }
            sweeps++;
        }
        return order;
    }

    private double legLength(int[] order, double[] lats, double[] lngs, int a, int b) {
        if (a < 0 || b >= order.length) return 0;
        int pa = order[a], pb = order[b];
        return haversine(lats[pa], lngs[pa], lats[pb], lngs[pb]);
    }

    private void reverse(int[] order, int i, int k) {
        while (i < k) {
            int tmp = order[i];
            order[i] = order[k];
            order[k] = tmp;
            i++;
            k--;
        }
    }

    private double haversine(double lat1, double lon1, double lat2, double lon2) {
        double dLat = Math.toRadians(lat2 - lat1);
        double dLon = Math.toRadians(lon2 - lon1);
        double a = Math.sin(dLat / 2) * Math.sin(dLat / 2)
                + Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2))
                * Math.sin(dLon / 2) * Math.sin(dLon / 2);
        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        return EARTH_RADIUS_KM * c;
    }

    private BigDecimal round(double value) {
        return BigDecimal.valueOf(value).setScale(2, RoundingMode.HALF_UP);
    }
}
