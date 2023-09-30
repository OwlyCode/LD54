class_name Block

enum {RED, BLUE, GREEN, VIOLET}
enum {UNDECIDED, UP, DOWN, RIGHT, LEFT}

var color = RED
var active = false
var direction = UNDECIDED

func get_color():
    match color:
        RED:
            return Vector2i(0,0)
        BLUE:
            return Vector2i(1,0)
        GREEN:
            return Vector2i(2,0)
        VIOLET:
            return Vector2i(3,0)

static func new_random() -> Block:
    var b = Block.new()

    var colors = [RED, BLUE, GREEN, VIOLET]

    b.color = colors[randi() % colors.size()]

    return b