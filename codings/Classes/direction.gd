extends Resource
class_name Direction

static var UP: Direction = from(Vector2.UP)
static var DOWN: Direction = from(Vector2.DOWN)
static var LEFT: Direction = from(Vector2.LEFT)
static var RIGHT: Direction = from(Vector2.RIGHT)
static var CENTER: Direction = from(Vector2.ZERO)

@export var vector: Vector2:
	set(x):
		vector = snap_vector(x)

static func from(vec: Vector2) -> Direction:
	vec = snap_vector(vec)
	
	var dir: Direction = Direction.new()
	dir.vector = vec
	return dir

static func snap_vector(v: Vector2 = Global.PlayerDir, allow_zero := false) -> Vector2:
	if v == Vector2.ZERO and allow_zero: return Vector2.ZERO
	if abs(v.x) > abs(v.y):
		if v.x > 0:
			return Vector2.RIGHT
		else:
			return Vector2.LEFT
	else:
		if v.y > 0:
			return Vector2.DOWN
		else:
			return Vector2.UP

static func get_letter_from_vector(d: Vector2 = Global.PlayerDir) -> String:
	match snap_vector(d):
		Vector2.RIGHT:
			return "R"
		Vector2.LEFT:
			return "L"
		Vector2.UP:
			return "U"
		Vector2.DOWN:
			return "D"
		_: return "C"

func get_letter() -> String:
	match vector:
		Vector2.RIGHT:
			return "R"
		Vector2.LEFT:
			return "L"
		Vector2.UP:
			return "U"
		Vector2.DOWN:
			return "D"
		_: return "C"

static func from_letter(d: String) -> Direction:
	match d:
		"R", "Right":
			return RIGHT
		"L", "Left":
			return LEFT
		"U", "Up":
			return UP
		"D", "Down":
			return DOWN
		_:
			return CENTER

static func get_name_from_vector(d: Vector2 = Global.PlayerDir) -> String:
	var dir := snap_vector(d)
	
	if dir == Vector2.RIGHT:
		return "Right"
	elif dir == Vector2.LEFT:
		return "Left"
	elif dir == Vector2.UP:
		return "Up"
	elif dir == Vector2.DOWN:
		return "Down"
	else: return "Center"

func get_name() -> String:
	match vector:
		Vector2.RIGHT:
			return "Right"
		Vector2.LEFT:
			return "Left"
		Vector2.UP:
			return "Up"
		Vector2.DOWN:
			return "Down"
		_: return "Center"

func equals(dir: Direction) -> bool:
	return vector == dir.vector

func is_vector(dir: Vector2) -> bool:
	return vector == dir

func is_letter(string: String) -> bool:
	return get_letter() == string

func set_to(vec: Vector2) -> void:
	vector = snap_vector(vec)
