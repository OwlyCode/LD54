class_name Block

enum {RED, BLUE}
enum {UNDECIDED, UP, DOWN, RIGHT, LEFT}

var color = RED
var active = false
var direction = UNDECIDED

func get_color():
    match color:
        RED:
            return Vector2i(0,0)
        _:
            return Vector2i(1,0)



static func new_blue() -> Block:
    var b = Block.new()
    b.color = BLUE

    return b