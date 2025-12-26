extends CharacterBody2D
# 'extends CharacterBody2D' tells Godot that this script controls a 2D character
# that can move and collide with things. It inherits all functionality from the
# built-in CharacterBody2D class.

# --- Configuration Variables ---
# @export makes these variables visible in the Godot Inspector, so you can
# tweak them without changing the code.

# How fast the player moves in pixels per second.
@export var speed :int = 200

# --- Bullet / Combat Settings ---
# PackedScene is a reference to another scene file (the bullet) that we can
# spawn (instantiate) in the game. preload() loads it into memory when the game starts.
@export var bullet_scene: PackedScene = preload("res://scenes/bullet.tscn")

# How fast the bullet travels.
@export var bullet_speed :int = 2000

# The time delay (in seconds) between shots. 0.25 = 4 shots per second.
@export var fire_rate :float = 0.25

# Toggle to enable/disable the shooting sound effect.
@export var shoot_sound :bool = true

# If true, the fire_rate is bypassed and you will fire as fast as your system can.
@export var rapid_fire :bool = false

# Internal variable to track if the cooldown has finished and we can shoot again.
var can_fire :bool = true

# --- Animation State ---
# We store the last direction the player moved to keep them facing that way
# when they stop moving. Default is DOWN.
var last_direction := Vector2.DOWN

# --- Mobile Controls ---
# 모바일 컨트롤 UI 참조
var mobile_controls: CanvasLayer = null

# _ready() is called once when the node enters the scene tree (when the game starts).
func _ready() -> void:
	# Start playing the "idle_down" animation immediately so the player isn't invisible
	# or stuck on the first frame.
	$PlayerSprite.play("idle_down")

	# 모바일 컨트롤 찾기
	await get_tree().process_frame
	mobile_controls = get_tree().get_first_node_in_group("mobile_controls")
	if not mobile_controls:
		var parent = get_parent()
		if parent:
			mobile_controls = parent.get_node_or_null("MobileControls")

# _process() is called every single visual frame. 
# Use this for things that need to look smooth, like updating animations or UI.
# 'delta' is the time in seconds since the last frame.
func _process(_delta: float) -> void:
	# 1. Aim the Gun
	# $GunPivot gets the node named "GunPivot".
	# look_at() rotates the node so its positive X-axis points towards the target.
	# get_global_mouse_position() gives us the mouse cursor's coordinates in the game world.
	$GunPivot.look_at(get_global_mouse_position())
	
	# 2. Update the character's sprite animation
	update_animation()

# _physics_process() is called at a fixed time interval (usually 60 times/sec).
# Use this for all physics calculations, movement, and collision logic.
# 'delta' is constant here, ensuring consistent movement speed regardless of frame rate.
func _physics_process(delta: float) -> void:
	# 1. Get Input
	# 키보드 입력 받기
	var direction := Input.get_vector("left", "right", "up", "down")

	# 모바일 조이스틱 입력도 받기 (키보드 입력이 없을 때)
	if direction == Vector2.ZERO and mobile_controls:
		direction = mobile_controls.get_joystick_direction()
	
	if direction != Vector2.ZERO:
		# Calculate the velocity we WANT to have based on input speed.
		var potential_vel = direction * speed
		
		# --- Custom Terrain Collision Check ---
		# We want to prevent the player from walking into Water or unexpected tiles.
		# get_parent() assumes the player is a child of the main Level scene.
		var level = get_parent()
		
		# Check if the level script has the 'is_tile_walkable' function.
		# This prevents the game from crashing if we test the player in a standalone scene.
		if level.has_method("is_tile_walkable"):
			
			# We check X and Y axes independently. This allows "wall sliding".
			# If you run into a wall diagonally, you will still slide along it 
			# instead of stopping completely.
			
			# Predict where we will be on the X axis in the next frame.
			var target_x = global_position + Vector2(potential_vel.x * delta, 0)
			
			# Check if that new position is safe (not water).
			if not _is_position_safe(target_x, level):
				# If not safe, cancel X movement.
				potential_vel.x = 0
				
			# Predict where we will be on the Y axis in the next frame.
			var target_y = global_position + Vector2(0, potential_vel.y * delta)
			
			# Check if that new position is safe.
			if not _is_position_safe(target_y, level):
				# If not safe, cancel Y movement.
				potential_vel.y = 0
		
		# Apply the filtered velocity to the character.
		velocity = potential_vel
		
		# Update last_direction so we know which way to face when we stop.
		last_direction = direction
	else:
		# No input? Stop moving.
		velocity = Vector2.ZERO
		
	# 2. Apply Movement
	# move_and_slide() is a special Godot function for CharacterBody2D.
	# It takes the 'velocity' variable, moves the body, and handles 
	# collisions with other physics objects (like walls or rocks).
	move_and_slide()
	
	# 3. Handle Shooting Input
	# Input.is_action_pressed() returns true as long as the button is held down.
	if Input.is_action_pressed("fire") and can_fire:
		shoot()

# Logic to pick the correct animation frame based on movement.
func update_animation() -> void:
	var anim_name = "idle"
	
	# If we are moving, switch to "walk".
	if velocity.length() > 0:
		anim_name = "walk"
	
	# Determine which way the character should face.
	# Use current velocity if moving, otherwise use the last known direction.
	var dir = last_direction
	if velocity.length() > 0:
		dir = velocity.normalized()
		
	var final_anim = ""
	var flip = false
	
	# We only have animations for Right, Up, and Down.
	# We prioritize Horizontal (Left/Right) over Vertical (Up/Down) for diagonals.
	if abs(dir.x) > abs(dir.y):
		# Horizontal movement
		final_anim = anim_name + "_right"
		
		# If moving Left (negative X), we use the "Right" animation but flip the sprite.
		if dir.x < 0:
			flip = true 
	else:
		# Vertical movement
		if dir.y < 0:
			final_anim = anim_name + "_up" # Negative Y is UP in 2D games.
		else:
			final_anim = anim_name + "_down" # Positive Y is DOWN.
			
	# Apply the flip setting to the sprite.
	$PlayerSprite.flip_h = flip
	
	# Only tell the sprite to play the animation if it's different from the current one.
	# Calling play() every frame restarts the animation, causing it to freeze on frame 1.
	if $PlayerSprite.animation != final_anim:
		$PlayerSprite.play(final_anim)

# Handles the logic for firing a projectile.
func shoot() -> void:
	can_fire = false # Prevent shooting again immediately.
	
	if shoot_sound:
		$ShootSound.play()
	
	# 1. Create the bullet
	# instantiate() creates a new copy of the bullet scene in memory.
	var bullet_instance = bullet_scene.instantiate()
	
	# 2. Position the bullet
	# We want the bullet to appear at the end of the gun barrel.
	# $GunPivot/BulletOrigin is a Marker2D node we placed exactly at the barrel tip.
	var spawn_pos = $GunPivot/BulletOrigin.global_position
	bullet_instance.global_position = spawn_pos
	
	# 3. Rotate the bullet
	# Match the bullet's rotation to the gun's current rotation.
	var direction_rotation = $GunPivot.rotation
	bullet_instance.rotation = direction_rotation
	
	# 4. Fire the bullet
	# Calculate a direction vector (normalized) from the rotation angle.
	# Vector2.RIGHT is (1, 0), the default direction for 0 rotation.
	var direction_vector = Vector2.RIGHT.rotated(direction_rotation)
	
	# apply_impulse() pushes the RigidBody2D bullet instantly.
	bullet_instance.apply_impulse(direction_vector * bullet_speed)
	
	# 5. Add to the World
	# We add the bullet to the Scene Root (get_tree().root).
	# IMPORTANT: We don't add it as a child of the Player, because if we did, 
	# the bullet would move WITH the player as they walked.
	get_tree().root.add_child(bullet_instance)
	
	# 6. Handle Cooldown
	if !rapid_fire:
		# Create a temporary timer that waits for 'fire_rate' seconds.
		# 'await' pauses this function here until the timer finishes (timeout).
		await get_tree().create_timer(fire_rate).timeout
		can_fire = true
	else:
		# If rapid fire is on (cheat mode?), allow firing next frame.
		can_fire = true

# Helper function to check if the player's collision box is fully on safe terrain.
# Returns true if all corners are safe, false if any corner touches water.
func _is_position_safe(target_pos: Vector2, level: Node) -> bool:
	# Safety check: If for some reason the CollisionShape is missing, fall back 
	# to a simple single-point check.
	if not has_node("CollisionShape2D"):
		return level.is_tile_walkable(target_pos)
		
	var col = $CollisionShape2D
	var shape = col.shape
	
	# If the shape isn't a rectangle, checking corners is hard.
	# Fall back to checking just the center position.
	if not shape is RectangleShape2D:
		return level.is_tile_walkable(target_pos + col.position)
		
	# Calculate the dimensions of the rectangle relative to the player.
	# We multiply by scale in case the shape was resized in the editor.
	var half_size = (shape.size * col.scale) / 2
	var center = col.position
	
	# Define the 4 corners of the box in global coordinates.
	# target_pos is where the player body is.
	# center is the local offset of the shape (e.g., at the feet).
	# +/- half_size adds the width/height of the box.
	var corners = [
		target_pos + center + Vector2(-half_size.x, -half_size.y), # Top-Left
		target_pos + center + Vector2(half_size.x, -half_size.y),  # Top-Right
		target_pos + center + Vector2(half_size.x, half_size.y),   # Bottom-Right
		target_pos + center + Vector2(-half_size.x, half_size.y)   # Bottom-Left
	]
	
	# Loop through each corner point.
	for p in corners:
		# Ask the Level script if this specific point is on a walkable tile.
		if not level.is_tile_walkable(p):
			return false # If ANY corner is unsafe, the whole move is unsafe.
			
	return true # All 4 corners are safe.
