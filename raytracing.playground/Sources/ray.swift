
import Foundation
import simd

struct Ray {
    var origin: float3
    var direction: float3
    func point_at_parameter(t: Float) -> float3 {
        return origin + t * direction
    }
}

struct Camera {
    let lower_left_corner, horizontal, vertical, origin, u, v, w: float3
    var lens_radius: Float = 0.1
    init(lookFrom: float3, lookAt: float3, vup: float3, vfov: Float, aspect: Float) {
        let theta = vfov * Float(M_PI) / 180
        let half_height = tan(theta / 2)
        let half_width = aspect * half_height
        origin = lookFrom
        w = normalize(lookFrom - lookAt)
        u = normalize(cross(vup, w))
        v = cross(w, u)
        lower_left_corner = origin - half_width * u - half_height * v - w
        horizontal = 2 * half_width * u
        vertical = 2 * half_height * v
    }
    func get_ray(s: Float, _ t: Float) -> Ray {
        return Ray(origin: origin, direction: lower_left_corner + s * horizontal + t * vertical - origin)
    }
}

func random_in_unit_sphere() -> float3 {
    var p = float3()
    repeat {
        p = 2.0 * float3(Float(drand48()), Float(drand48()), Float(drand48())) - float3(1, 1, 1)
    } while dot(p, p) >= 1.0
    return p
}

func color(r: Ray, _ world: Hitable, _ depth: Int) -> float3 {
    if let hit = world.hit(r: r, 0.001, Float.infinity) {
        var scattered = r
        var attenuantion = float3()
        if depth < 5 && hit.mat_ptr.scatter(ray_in: r, hit, &attenuantion, &scattered) { // depth = 50
            return attenuantion * color(r: scattered, world, depth + 1)
        } else {
            return float3(0, 0, 0)
        }
    }
    let unit_direction = normalize(r.direction)
    let t = 0.5 * unit_direction.y + 1
    return (1 - t) * float3(1, 1, 1) + t * float3(0.5, 0.7, 1.0)
}
