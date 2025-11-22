// Lightweight realtime data store for demo and development
// In production, replace with DB + Redis pub/sub

const TYPES = ['household', 'recyclable', 'bulky']

function rnd(a,b){ return a + Math.random()*(b-a) }

class RealtimeStore {
  constructor(){
    this.points = new Map() // id -> {id, lon, lat, type, level, ts}
    this.vehicles = new Map() // id -> {id, lon, lat, speed, heading, ts}
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
}

const store = new RealtimeStore()

module.exports = { store }

