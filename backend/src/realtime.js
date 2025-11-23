// Lightweight realtime data store for demo and development
// In production, replace with DB + Redis pub/sub

const TYPES = ['household', 'recyclable', 'bulky']

function rnd(a,b){ return a + Math.random()*(b-a) }

class RealtimeStore {
  constructor(){
    this.points = new Map() // id -> {id, lon, lat, type, level, ts}
        this.vehicles = new Map() // id -> {id, lon, lat, speed, heading, ts}
    this.activeRoutes = new Map() // route_id -> { route_id, vehicle_id, status, points: Map<point_id, {checked, ...}> }
    this.serverTime = Date.now()
    // seed
    for (let i=0;i<400;i++){
      const lon = rnd(106.63,106.78), lat = rnd(10.72,10.86)
      const type = TYPES[Math.floor(Math.random()*TYPES.length)]
      const level = [0.3,0.6,0.9][Math.floor(Math.random()*3)]
      const id = `P${i+1}`
      this.points.set(id, { id, lon, lat, type, level, ts: Date.now()-rnd(0,3.6e6) })
    }
    ;['V01','V02','V03','V04'].forEach((id,i)=>{
      this.vehicles.set(id, { id, lon: 106.68+i*0.02, lat: 10.76+i*0.02, speed: 20+rnd(-5,10), heading: rnd(0,360), ts: Date.now() })
    })
  }

  tickVehicles(){
    const now = Date.now()
    this.vehicles.forEach(v=>{
      const d = rnd(-0.002,0.002)
      v.lon += d; v.lat += rnd(-0.002,0.002)
      v.speed = Math.max(0, v.speed + rnd(-2,2))
      v.heading = (v.heading + rnd(-10,10)+360)%360
      v.ts = now
    })
    this.serverTime = now
  }

  // bbox: [minLng,minLat,maxLng,maxLat]
  getPoints({ bbox, since }){
    const [minLng,minLat,maxLng,maxLat] = bbox || [106.60,10.70,106.85,10.90]
    const added = []
    const updated = []
    const removed = [] // not used in mock
    const limit = 1500
    let count = 0
    this.points.forEach(p=>{
      if (p.lon>=minLng && p.lon<=maxLng && p.lat>=minLat && p.lat<=maxLat){
        if (!since || p.ts > since){ added.push(p) } else { updated.push(p) }
        if (++count>=limit) return
      }
    })
    return { serverTime: this.serverTime, added, updated, removed }
  }

  getVehicles(){
    return Array.from(this.vehicles.values())
  }

  // --- Route Management for CN7 ---

  startRoute(routeId, vehicleId, points = []) {
    if (this.activeRoutes.has(routeId)) {
      console.warn(`[Store] Route ${routeId} is already active.`);
      return;
    }
    const routePoints = new Map();
    // Assuming points is an array of objects with at least a point_id
    points.forEach(p => routePoints.set(p.point_id, { ...p, checked: false, checkin_time: null }));

    this.activeRoutes.set(routeId, {
      route_id: routeId,
      vehicle_id: vehicleId,
      status: 'inprogress', // inprogress, completed
      started_at: Date.now(),
      points: routePoints,
    });
    console.log(`[Store] Route ${routeId} started for vehicle ${vehicleId} with ${points.length} points.`);
  }

  recordCheckin(routeId, pointId) {
    const route = this.activeRoutes.get(routeId);
    if (!route || route.status === 'completed') {
      // This could be a "Late Check-in"
      console.warn(`[Store] Received check-in for inactive/completed route ${routeId}`);
      return { status: 'late_checkin' };
    }

    const point = route.points.get(pointId);
    if (point) {
      if (point.checked) {
        console.warn(`[Store] Duplicate check-in for point ${pointId} on route ${routeId}`);
        return { status: 'duplicate' };
      }
      point.checked = true;
      point.checkin_time = Date.now();
      console.log(`[Store] Check-in recorded for point ${pointId} on route ${routeId}`);
      return { status: 'ok' };
    } else {
      console.warn(`[Store] Point ${pointId} not found on route ${routeId}`);
      return { status: 'point_not_found' };
    }
  }

  completeRoute(routeId) {
    const route = this.activeRoutes.get(routeId);
    if (route) {
      route.status = 'completed';
      route.completed_at = Date.now();
      console.log(`[Store] Route ${routeId} completed.`);
    }
  }

  getActiveRoutes() {
    return Array.from(this.activeRoutes.values());
  }

  getRoute(routeId) {
    return this.activeRoutes.get(routeId);
  }

  getVehicle(vehicleId) {
    return this.vehicles.get(vehicleId);
  }

}

const store = new RealtimeStore()

module.exports = { store }

