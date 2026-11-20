extends RefCounted
class_name Grid
## Pure isometric grid geometry (no nodes). Shared by the simulation and views.

const N: Vector2i = Vector2i(-1, -1)
const E: Vector2i = Vector2i(1, -1)
const S: Vector2i = Vector2i(1, 1)
const W: Vector2i = Vector2i(-1, 1)
const NE: Vector2i = Vector2i(0, -1)
const SE: Vector2i = Vector2i(1, 0)
const SW: Vector2i = Vector2i(0, 1)
const NW: Vector2i = Vector2i(-1, 0)

const cardinals: Array[Vector2i] = [N, NE, E, SE, S, SW, W, NW]

static func vector_to_cardinal(vector: Vector2) -> Vector2i:
	var result := Vector2i.ZERO
	if abs(vector.x) > abs(vector.y) * .5:
		result.x = signi(int(signf(vector.x)))
	if abs(vector.y) > abs(vector.x) * .5:
		result.y = signi(int(signf(vector.y)))
	return result

static func opposite(vector: Vector2i) -> Vector2i:
	return -vector

## Chebyshev distance (king moves).
static func distance(from: Vector2i, to: Vector2i) -> int:
	var d: Vector2i = from - to
	return maxi(absi(d.x), absi(d.y))

## The two directions next to `dir` (offset 1 = 45 degrees, 2 = 90 degrees),
## clockwise first. Deterministic: use Board.shuffled() when order must be random.
static func side_directions(dir: Vector2i, orthogonal: bool) -> Array[Vector2i]:
	var offset: int = 2 if orthogonal else 1
	var index: int = cardinals.find(dir)
	return [
		cardinals[posmod(index + offset, cardinals.size())],
		cardinals[posmod(index - offset, cardinals.size())],
	]
