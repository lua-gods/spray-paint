---FROM: Simon#255
---@alias quaternion {_w:number, _x:number, _y:number, _z:number}
local doubleEpsilon = 2.22044604925031308e-16
local quaternion_util = {}
---@param quat quaternion
function quaternion_util.length(quat)
    return math.sqrt(quat._x * quat._x + quat._y * quat._y + quat._z * quat._z + quat._w * quat._w);
end

---@param quat quaternion
function quaternion_util.normalize(quat)
    local l = quaternion_util.length(quat)
    local this = quat
    if (l == 0) then
        this._x = 0;
        this._y = 0;
        this._z = 0;
        this._w = 1;
    else
        l = 1 / l;

        this._x = this._x * l;
        this._y = this._y * l;
        this._z = this._z * l;
        this._w = this._w * l;
    end

    return this;
end

---@param mat Matrix4
---@return quaternion
function quaternion_util.setFromRotationMatrix(mat)
    local m11 = mat.v11
    local m12 = mat.v12
    local m13 = mat.v13
    local m21 = mat.v21
    local m22 = mat.v22
    local m23 = mat.v23
    local m31 = mat.v31
    local m32 = mat.v32
    local m33 = mat.v33
    local trace = m11 + m22 + m33
    local this = { _w = 0, _x = 0, _y = 0, _z = 0 }
    if (trace > 0) then
        local s = 0.5 / math.sqrt(trace + 1.0)

        this._w = 0.25 / s
        this._x = (m32 - m23) * s
        this._y = (m13 - m31) * s
        this._z = (m21 - m12) * s
    elseif (m11 > m22 and m11 > m33) then
        local s = 2.0 * math.sqrt(1.0 + m11 - m22 - m33)

        this._w = (m32 - m23) / s
        this._x = 0.25 * s
        this._y = (m12 + m21) / s
        this._z = (m13 + m31) / s
    elseif (m22 > m33) then
        local s = 2.0 * math.sqrt(1.0 + m22 - m11 - m33)

        this._w = (m13 - m31) / s
        this._x = (m12 + m21) / s
        this._y = 0.25 * s
        this._z = (m23 + m32) / s
    else
        local s = 2.0 * math.sqrt(1.0 + m33 - m11 - m22)

        this._w = (m21 - m12) / s
        this._x = (m13 + m31) / s
        this._y = (m23 + m32) / s
        this._z = 0.25 * s
    end
    return this
end

---@param this quaternion
---@param qt quaternion
---@param t number
function quaternion_util.lerp(this, qt, t)
    if (t == 0) then return this end
    if (t == 1) then return qt end
    local x = this._x
    local y = this._y
    local z = this._z
    local w = this._w
    local cosHalfTheta = w * qt._w + x * qt._x + y * qt._y + z * qt._z
    if (cosHalfTheta < 0) then
        this._w = -qt._w
        this._x = -qt._x
        this._y = -qt._y
        this._z = -qt._z
        cosHalfTheta = -cosHalfTheta
    else
        this = qt
    end
    if (cosHalfTheta >= 1.0) then
        this._w = w
        this._x = x
        this._y = y
        this._z = z
        return this
    end
    local sqrSinHalfTheta = 1.0 - cosHalfTheta * cosHalfTheta
    if (sqrSinHalfTheta <= doubleEpsilon) then
        local s = 1 - t
        this._w = s * w + t * this._w
        this._x = s * x + t * this._x
        this._y = s * y + t * this._y
        this._z = s * z + t * this._z
        return quaternion_util.normalize(this)
    end
    local sinHalfTheta = math.sqrt(sqrSinHalfTheta)
    local halfTheta = math.atan2(sinHalfTheta, cosHalfTheta)
    local ratioA = math.sin((1 - t) * halfTheta) / sinHalfTheta
    local ratioB = math.sin(t * halfTheta) / sinHalfTheta
    this._w = w * ratioA + this._w * ratioB
    this._x = x * ratioA + this._x * ratioB
    this._y = y * ratioA + this._y * ratioB
    this._z = z * ratioA + this._z * ratioB
    return this
end

local matrix_util = {}
---@param mat Matrix4
---@return {position:Vector3,quaternion:quaternion,scale:Vector3}
function matrix_util.decompose(mat)
    local sx = vec(mat.v11, mat.v21, mat.v31):length()
    local sy = vec(mat.v12, mat.v22, mat.v32):length()
    local sz = vec(mat.v13, mat.v23, mat.v33):length()
    local det = mat:det()
    if (det < 0) then sx = -sx end

    local _m1 = mat:copy()
    local invSX = 1 / sx
    local invSY = 1 / sy
    local invSZ = 1 / sz

    _m1.v11 = _m1.v11 * invSX
    _m1.v21 = _m1.v21 * invSX
    _m1.v31 = _m1.v31 * invSX
    _m1.v12 = _m1.v12 * invSY
    _m1.v22 = _m1.v22 * invSY
    _m1.v32 = _m1.v32 * invSY
    _m1.v13 = _m1.v13 * invSZ
    _m1.v23 = _m1.v23 * invSZ
    _m1.v33 = _m1.v33 * invSZ
    return {
        position = vec(mat.v14, mat.v24, mat.v34),
        quaternion = quaternion_util
            .setFromRotationMatrix(_m1),
        scale = vec(sx, sy, sz),
    }
end

---@param position Vector3
---@param quaternion quaternion
---@param scale Vector3
---@return Matrix4
function matrix_util.compose(position, quaternion, scale)
    local x = quaternion._x
    local y = quaternion._y
    local z = quaternion._z
    local w = quaternion._w
    local x2 = x + x
    local y2 = y + y
    local z2 = z + z
    local xx = x * x2
    local xy = x * y2
    local xz = x * z2
    local yy = y * y2
    local yz = y * z2
    local zz = z * z2
    local wx = w * x2
    local wy = w * y2
    local wz = w * z2
    local sx = scale.x
    local sy = scale.y
    local sz = scale.z
    local te = matrices.mat4()
    te.v11 = (1 - (yy + zz)) * sx
    te.v21 = (xy + wz) * sx
    te.v31 = (xz - wy) * sx
    te.v41 = 0

    te.v12 = (xy - wz) * sy
    te.v22 = (1 - (xx + zz)) * sy
    te.v32 = (yz + wx) * sy
    te.v42 = 0

    te.v13 = (xz + wy) * sz
    te.v23 = (yz - wx) * sz
    te.v33 = (1 - (xx + yy)) * sz
    te.v43 = 0

    te.v14 = position.x
    te.v24 = position.y
    te.v34 = position.z
    te.v44 = 1
    return te
end

function matrix_util.lerp(mf, mt, t)
    local mfd = matrix_util.decompose(mf)
    local mtd = matrix_util.decompose(mt)
    return matrix_util.compose(
        math.lerp(mfd.position, mtd.position, t),
        quaternion_util.lerp(mfd.quaternion, mtd.quaternion, t),
        math.lerp(mfd.scale, mtd.scale, t)
    )
end

return { matrix = matrix_util, quaternion = quaternion_util }
