
import simd

protocol Material {
    func scatter(ray_in: Ray, _ rec: Hit_record, _ attenuation: inout float3, _ scattered: inout Ray) -> Bool
}

struct Lambertian: Material {
    var albedo = float3()
    
    func scatter(ray_in: Ray, _ rec: Hit_record, _ attenuation: inout float3, _ scattered: inout Ray) -> Bool {
        let target = rec.p + rec.normal + random_in_unit_sphere()
        scattered = Ray(origin: rec.p, direction: target - rec.p)
        attenuation = albedo
        return true
    }
}

struct Metal: Material {
    var albedo = float3()
    var fuzz: Float = 0
    
    func scatter(ray_in: Ray, _ rec: Hit_record, _ attenuation: inout float3, _ scattered: inout Ray) -> Bool {
        let reflected = reflect(normalize(ray_in.direction), n: rec.normal)
        scattered = Ray(origin: rec.p, direction: reflected + fuzz * random_in_unit_sphere())
        attenuation = albedo
        return dot(scattered.direction, rec.normal) > 0
    }
}

struct Dielectric: Material {
    var ref_index: Float = 1
    
    func scatter(ray_in: Ray, _ rec: Hit_record, _ attenuation: inout float3, _ scattered: inout Ray) -> Bool {
        var reflect_prob: Float = 1
        var cosine: Float = 1
        var ni_over_nt: Float = 1
        var outward_normal = float3()
        let reflected = reflect(ray_in.direction, n: rec.normal)
        attenuation = float3(1, 1, 1)
        if dot(ray_in.direction, rec.normal) > 0 {
            outward_normal = -rec.normal
            ni_over_nt = ref_index
            cosine = ref_index * dot(ray_in.direction, rec.normal) / length(ray_in.direction)
        } else {
            outward_normal = rec.normal
            ni_over_nt = 1 / ref_index
            cosine = -dot(ray_in.direction, rec.normal) / length(ray_in.direction)
        }
        let refracted = refract(v: ray_in.direction, n: outward_normal, ni_over_nt: ni_over_nt)
        if refracted != nil {
            reflect_prob = schlick(cosine, ref_index)
        } else {
            scattered = Ray(origin: rec.p, direction: reflected)
            reflect_prob = 1.0
        }
        if Float(drand48()) < reflect_prob {
            scattered = Ray(origin: rec.p, direction: reflected)
        } else {
            scattered = Ray(origin: rec.p, direction: refracted!)
        }
        return true
    }
}

func refract(v: float3, n: float3, ni_over_nt: Float) -> float3? {
    let uv = normalize(v)
    let dt = dot(uv, n)
    let discriminant = 1.0 - ni_over_nt * ni_over_nt * (1.0 - dt * dt)
    if discriminant > 0 {
        return ni_over_nt * (uv - n * dt) - n * sqrt(discriminant)
    }
    return nil
}

func schlick(_ cosine: Float, _ index: Float) -> Float {
    var r0 = (1 - index) / (1 + index)
    r0 = r0 * r0
    return r0 + (1 - r0) * powf(1 - cosine, 5)
}
