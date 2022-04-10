#import "Basic";
#import "Math";
#import "JaiMath";

// TODO normals should just be a fixed array of size 100 or something
GroundController :: struct {
    position: Vector2;
    velocity: Vector2;
    jumping: bool;
    normals: [..] Vector2;
    ground_normal_slope: float = 0.7;
    allowed_step_height: int = 12;
}

resolve_physics :: (world: WorldData, controller: *GroundController, aabb: AABB2) {
    // TODO do this with the outline of the shape or something
    bounding: BoundingPoints;
    bounding.lower = point(aabb.lower);
    bounding.upper = point(aabb.upper);

    resolve_physics(world, controller, bounding);
}

// walls are gonna be like:
// step through the pixels, when you collide with a pixel adjust yourself to be outside that pixel in a way that resolves the
// collision (doesn’t just go backwards) (this is hard, does it move in directions normal to the velocity line only? and if a valid position isnt found it reverses to the previous valid point?)
// when you collide with a pixel, after youve resolved it, adjust your velocity to be normal tangent to the line of pixels
// stop stepping when your next step will go past the length of your velocity for this tick
// this isnt right
// your final position will be a floating point that includes the entireity of your velocity length

// today I do wall physics

resolve_physics :: (world: WorldData, controller: *GroundController, bounding: BoundingPoints) {
    gravity := Vector2.{0, 0.35};
    body_falling_speed := length(projectOnto(controller.velocity, gravity)) * 0.01;
    if dot(controller.velocity, gravity) <= 0 {
        body_falling_speed = 0;
    }

    gravity_speed := length(gravity);
    gravity_scale := 1.0;
    applied_gravity := normalize(gravity) * max(gravity_speed - body_falling_speed * body_falling_speed, 0) * gravity_scale;
    controller.velocity += applied_gravity;

    if length(controller.velocity) == 0 {
        return;
    }

    position := controller.position;
    velocity := controller.velocity;

    remaining_length := length(controller.velocity);
    step := normalize(controller.velocity);
    while remaining_length > 0 {
        new_position: Vector2;
        if remaining_length >= 1 {
            new_position.x = position.x + step.x;
            new_position.y = position.y + step.y;
        } else {
            new_position.x = position.x + step.x * remaining_length;
            new_position.y = position.y + step.y * remaining_length;
        }

        pixel_new_position := point(new_position);

        aabb := bounding + pixel_new_position;
        collision, collision_pixel := check_collisions(world, aabb);
        if collision {
            step_up_offset, step_collision_pixel, step_normal := step_up(world, controller, aabb);
            if step_up_offset != 0 {
                controller.jumping = false;
                new_position.y -= step_up_offset;
    
                // if youve been teleported up a step subtract this from the remaining movement length
                // basically calculate the difference in the y value would make to equal the hypotenuse considering we're already subtracting one
                // we need to calculate the distance that this vertical line would be to the actual velocity line, and use that as one of the
                // edges of the triangle to calculate the hypotenuse
                // const travelDirection = Vec2.copy(velocity).normalize();
                // const verticalStep = new Vec2(0, stepUpOffset);
                // const stepAngle = Math.acos(travelDirection.dot(verticalStep) / (travelDirection.length() * verticalStep.length()));
                // const minimumStepDistance = 1 / Math.tan(Math.PI / 2 - stepAngle);

                slope_penalty := sqrt(1.0 + step_up_offset * step_up_offset) - 1.0;
                remaining_length = max(remaining_length - slope_penalty, 0);

                if step_normal.y <= -controller.ground_normal_slope {
                    velocity.y = 0;
                } else {
                    velocity = project_velocity_if_necessary(step_normal, velocity);
                }
            } else {
                aabb := bounding + pixel_new_position;
                normal := get_normal(world, aabb, collision_pixel);
                if normal.y <= -controller.ground_normal_slope {
                    velocity.y = 0;
                } else {
                    velocity = project_velocity_if_necessary(normal, velocity);
                }

                attempt_clear_distance := 4;
                found_empty := false;
                for distance: 1..attempt_clear_distance {
                    aabb = bounding + point(new_position + normal * distance);
                    collision, collision_pixel = check_collisions(world, aabb);
                    if !collision {
                        found_empty = true;
                        break;
                    }
                }

                if !found_empty {
                    break;
                }

                // bounding instead
                // I think new_position is already good at this point
            }
        }

        position = new_position;
        remaining_length = max(remaining_length - 1, 0);
    }

    controller.position = position;
    controller.velocity = velocity;

    controller.normals.count = 0;
    expanded_aabb := bounding + point(position);
    expanded_aabb.lower -= Point.{1, 1};
    expanded_aabb.upper += Point.{1, 1};

    for x: expanded_aabb.lower.x..expanded_aabb.upper.x {
        if get_pixel(world, x, expanded_aabb.lower.y) {
            array_add(*controller.normals, get_normal(world, expanded_aabb, point(x, expanded_aabb.lower.y)));
        }
        if get_pixel(world, x, expanded_aabb.upper.y) {
            array_add(*controller.normals, get_normal(world, expanded_aabb, point(x, expanded_aabb.upper.y)));
        }
    }

    for y: expanded_aabb.lower.y..expanded_aabb.upper.y {
        if get_pixel(world, expanded_aabb.lower.x, y) {
            array_add(*controller.normals, get_normal(world, expanded_aabb, point(expanded_aabb.lower.x, y)));
        }
        if get_pixel(world, expanded_aabb.upper.x, y) {
            array_add(*controller.normals, get_normal(world, expanded_aabb, point(expanded_aabb.upper.x, y)));
        }
    }
}

// paint_edges :: (x: int, y: int, velocity: Vector2) -> float {
//     // okay first probably I will just draw all the pixels along a wall red to see what happens, if this algorithm even works for finding edges
//     normal_angle := atan2(-velocity.y, -velocity.x);

//     SetPixelColor(LEVEL.world, RED, x, y);

//     current_pixel, valid_pixel := get_next_wall_pixel(x, y, normal_angle);
//     color := get_pixelColor(LEVEL.world, current_pixel.x, current_pixel.y);
//     while valid_pixel && color != RED {
//         SetPixelColor(LEVEL.world, RED, current_pixel.x, current_pixel.y);

//         current_pixel, valid_pixel = get_next_wall_pixel(current_pixel.x, current_pixel.y, normal_angle);
//         color = get_pixelColor(LEVEL.world, current_pixel.x, current_pixel.y);
//     }
// }

project_velocity_if_necessary :: (normal: Vector2, velocity: Vector2) -> Vector2 {
    if dot(normal, velocity) >= 0 {
        return velocity;
    }

    normal_orthogonal := orthogonal(normal);
    return projectOnto(velocity, normal_orthogonal);
}

// TODO this function should return the same normal on a line given any point along that line
// TODO except maybe edges I guess
get_normal :: (world: WorldData, aabb: BoundingPoints, pixel: Point) -> Vector2 {
    required_line_accuracy :: 16;

    center := aabb.lower / 2.0 + aabb.upper / 2.0;

    // check for additional pixels on the side that this is colliding with
    // top wall
    if pixel.y == aabb.lower.y && !get_pixel(world, pixel.x, pixel.y + 1) {
        for x: aabb.lower.x..aabb.upper.x {
            if x == pixel.x {
                continue;
            }
            
            if get_pixel(world, x, pixel.y) && !get_pixel(world, x, pixel.y + 1) {
                return xy(0.0, 1.0);
            }
        }
    }
    // bottom wall
    if pixel.y == aabb.upper.y && !get_pixel(world, pixel.x, pixel.y - 1) {
        for x: aabb.lower.x..aabb.upper.x {
            if x == pixel.x {
                continue;
            }
            
            if get_pixel(world, x, pixel.y) && !get_pixel(world, x, pixel.y - 1) {
                return xy(0.0, -1.0);
            }
        }
    }
    // left wall
    if pixel.x == aabb.lower.x && !get_pixel(world, pixel.x + 1, pixel.y) {
        for y: aabb.lower.y..aabb.upper.y {
            if y == pixel.y {
                continue;
            }
            
            if get_pixel(world, pixel.x, y) && !get_pixel(world, pixel.x + 1, y) {
                return xy(1.0, 0.0);
            }
        }
    }
    // right wall
    if pixel.x == aabb.upper.x && !get_pixel(world, pixel.x - 1, pixel.y) {
        for y: aabb.lower.y..aabb.upper.y {
            if y == pixel.y {
                continue;
            }
            
            if get_pixel(world, pixel.x, y) && !get_pixel(world, pixel.x - 1, y) {
                return xy(-1.0, 0.0);
            }
        }
    }

    // left means, if your character is falling down to the ground, the left direction of the surface
    // pixel - character center gets you an approximation of what the normal probably is
    left_pixel := orthogonal(pixel - center);
    left_angle := atan2(left_pixel);
    right_angle := atan2(-left_pixel);

    start := pixel + 0.5;
    start_pixel := pixel;
    valid_pixel, next_pixel := get_next_wall_pixel(world, start_pixel, left_angle);
    if valid_pixel {
        // here we know that the next_pixel is valid because its only the second, so skip the corner check
        // ccw most
        left_most_angle := atan2(next_pixel - pixel_offsets[0] - start);
        // cw most
        right_most_angle := left_most_angle;

        // this is just the first pixel along the line, so get the widest angle possible
        for i: 1..pixel_offsets.count - 1 {
            corner := next_pixel + pixel_offsets[i];

            new_angle := atan2(corner - start);
            if radians_between(left_most_angle, new_angle) < 0 {
                left_most_angle = new_angle;
            }
            if radians_between(right_most_angle, new_angle) > 0 {
                right_most_angle = new_angle;
            }
        }

        // get the average of the possible line angle range
        // TODO why is this one + 0.5 if the previous one isnt
        left_angle = atan2(next_pixel + 0.5 - start);

        count := 0;
        while count < required_line_accuracy {
            start_pixel = next_pixel;

            valid_pixel, next_pixel = get_next_wall_pixel(world, start_pixel, left_angle);
            if !valid_pixel {
                break;
            } else {
                if !validate_corners(start, next_pixel, left_most_angle, right_most_angle) {
                    break;
                }

                next_left_most_angle := atan2(next_pixel + pixel_offsets[0] - start);
                next_right_most_angle := next_left_most_angle;

                for i: 0..pixel_offsets.count - 1 {
                    corner := next_pixel + pixel_offsets[i];
        
                    new_angle := atan2(corner - start);
                    if radians_between(next_left_most_angle, new_angle) < 0 {
                        next_left_most_angle = new_angle;
                    }
                    if radians_between(next_right_most_angle, new_angle) > 0 {
                        next_right_most_angle = new_angle;
                    }
                }

                // this is more restricting, so update it
                if radians_between(left_most_angle, next_left_most_angle) > 0 {
                    left_most_angle = next_left_most_angle;
                }
                if radians_between(right_most_angle, next_right_most_angle) < 0 {
                    right_most_angle = next_right_most_angle;
                }

                left_angle = atan2(next_pixel + 0.5 - start);
            }

            count += 1;
        }
    }
    
    start_pixel = pixel;
    valid_pixel, next_pixel = get_next_wall_pixel(world, start_pixel, right_angle);
    if valid_pixel {
        // here we know that the next_pixel is valid because its only the second, so skip the corner check
        // ccw most
        left_most_angle := atan2(next_pixel + pixel_offsets[0] - start);
        // cw most
        right_most_angle := left_most_angle;

        // this is just the first pixel along the line, so get the widest angle possible
        for i: 1..pixel_offsets.count - 1 {
            corner := next_pixel + pixel_offsets[i];

            new_angle := atan2(corner - start);
            if radians_between(left_most_angle, new_angle) < 0 {
                left_most_angle = new_angle;
            }
            if radians_between(right_most_angle, new_angle) > 0 {
                right_most_angle = new_angle;
            }
        }

        // get the average of the possible line angle range
        right_angle = atan2(next_pixel + 0.5 - start);

        count := 0;
        while count < required_line_accuracy {
            start_pixel = next_pixel;

            valid_pixel, next_pixel = get_next_wall_pixel(world, start_pixel, right_angle);
            if !valid_pixel {
                break;
            } else {
                if !validate_corners(start, next_pixel, left_most_angle, right_most_angle) {
                    break;
                }

                next_left_most_angle := atan2(next_pixel + pixel_offsets[0] - start);
                next_right_most_angle := next_left_most_angle;

                for i: 0..pixel_offsets.count - 1 {
                    corner := next_pixel + pixel_offsets[i];
        
                    new_angle := atan2(corner - start);
                    if radians_between(next_left_most_angle, new_angle) < 0 {
                        next_left_most_angle = new_angle;
                    }
                    if radians_between(next_right_most_angle, new_angle) > 0 {
                        next_right_most_angle = new_angle;
                    }
                }

                // this is more restricting, so update it
                if radians_between(left_most_angle, next_left_most_angle) > 0 {
                    left_most_angle = next_left_most_angle;
                }
                if radians_between(right_most_angle, next_right_most_angle) < 0 {
                    right_most_angle = next_right_most_angle;
                }

                right_angle = atan2(next_pixel + 0.5 - start);
            }

            count += 1;
        }
    }

    // TODO temporary
    left_normal := orthogonal(xy(cos(left_angle), sin(left_angle)));
    right_normal := -orthogonal(xy(cos(right_angle), sin(right_angle)));
    averaged_normal := normalize(left_normal + right_normal);
    if left_normal.y <= right_normal.y && left_normal.y <= averaged_normal.y {
        return left_normal;
    } else if right_normal.y <= left_normal.y && right_normal.y <= averaged_normal.y {
        return right_normal;
    } else {
        return averaged_normal;
    }
}

validate_corners :: (start: Vector2, end: Point, left_most_angle: float, right_most_angle: float) -> bool {
    for i: 0..pixel_offsets.count - 1 {
        corner := end + pixel_offsets[i];

        angle := atan2(corner - start);
        if radians_between(left_most_angle, angle) >= 0 && radians_between(right_most_angle, angle) <= 0 {
            return true;
        }
    }

    return false;
}

check_collisions :: (world: WorldData, aabb: BoundingPoints) -> bool, Point {
    for x: aabb.lower.x..aabb.upper.x {
        if get_pixel(world, x, aabb.lower.y) {
            return true, point(x, aabb.lower.y);
        }
        if get_pixel(world, x, aabb.upper.y) {
            return true, point(x, aabb.upper.y);
        }
    }

    for y: aabb.lower.y..aabb.upper.y {
        if get_pixel(world, aabb.lower.x, y) {
            return true, point(aabb.lower.x, y);
        }
        if get_pixel(world, aabb.upper.x, y) {
            return true, point(aabb.upper.x, y);
        }
    }

    return false, .{};
}

// tries to step up from your current position, returns the necessary offset
step_up :: (world: WorldData, controller: *GroundController, aabb: BoundingPoints) -> int, Point, Vector2 {
    previous_collided := false;
    previous_step_pixel: Point = ---;
    previous_step_aabb: BoundingPoints = ---;

    for y: 0..controller.allowed_step_height {
        step_aabb := aabb - point(0, y);

        collided, step_pixel := check_collisions(world, step_aabb);
        if !collided && previous_collided {
            step_up_center := step_aabb.lower / 2.0 + step_aabb.upper / 2.0;
            normal := get_normal(world, previous_step_aabb, previous_step_pixel);

            if normal.y <= -controller.ground_normal_slope {
                return y, previous_step_pixel, normal;
            }
        }

        if collided {
            previous_collided = true;
            previous_step_pixel = step_pixel;
            previous_step_aabb = step_aabb;
        }
    }

    return 0, .{}, .{};
}

// the desired angle passed in here should be the opposite of the velocity of the player
// so we can get the wall that is most relevant to them
get_next_wall_pixel :: (world: WorldData, pixel: Point, angle: float) -> bool, Point {
    // view := CreateWorldDataView(LEVEL.world, x - 1, y - 1, 3, 3);
    // we need to find all pixels that have at least one adjacent empty space
    // .[top left, top middle, top right, middle left, middle right, bottom left, bottom middle, bottom right]
    found: [8] bool;
    pixels: [8] Point : .[.{-1, -1}, .{0, -1}, .{1, -1}, .{-1, 0}, .{1, 0}, .{-1, 1}, .{0, 1}, .{1, 1}];
    angles: [8] float : .[#run atan2(pixels[0]), #run atan2(pixels[1]), #run atan2(pixels[2]), #run atan2(pixels[3]), #run atan2(pixels[4]), #run atan2(pixels[5]), #run atan2(pixels[6]), #run atan2(pixels[7])];
    
    // the problem is that this pixel could easily have a wall facing the opposite way of the player, but do we care?
    // no we dont care, I dont think
    if get_pixel(world, pixel.x - 1, pixel.y - 1) {
        // pixel to the right is transparent or pixel below is transparent
        if !get_pixel(world, pixel.x, pixel.y - 1) || !get_pixel(world, pixel.x - 1, pixel.y) {
            found[0] = true;
        }
    }
    if get_pixel(world, pixel.x, pixel.y - 1) {
        // pixel to the left is transparent or pixel to the right is transparent
        if !get_pixel(world, pixel.x - 1, pixel.y - 1) || !get_pixel(world, pixel.x + 1, pixel.y - 1) {
            found[1] = true;
        }
    }
    if get_pixel(world, pixel.x + 1, pixel.y - 1) {
        // pixel to the left is transparent or pixel below is transparent
        if !get_pixel(world, pixel.x, pixel.y - 1) || !get_pixel(world, pixel.x + 1, pixel.y) {
            found[2] = true;
        }
    }
    if get_pixel(world, pixel.x - 1, pixel.y) {
        // pixel above is transparent or pixel below is transparent
        if !get_pixel(world, pixel.x - 1, pixel.y - 1) || !get_pixel(world, pixel.x - 1, pixel.y + 1) {
            found[3] = true;
        }
    }
    if get_pixel(world, pixel.x + 1, pixel.y) {
        // pixel above is transparent or pixel below is transparent
        if !get_pixel(world, pixel.x + 1, pixel.y - 1) || !get_pixel(world, pixel.x + 1, pixel.y + 1) {
            found[4] = true;
        }
    }
    if get_pixel(world, pixel.x - 1, pixel.y + 1) {
        // pixel to the right is transparent or pixel above is transparent
        if !get_pixel(world, pixel.x, pixel.y + 1) || !get_pixel(world, pixel.x - 1, pixel.y) {
            found[5] = true;
        }
    }
    if get_pixel(world, pixel.x, pixel.y + 1) {
        // pixel to the left is transparent or pixel to the right is transparent
        if !get_pixel(world, pixel.x - 1, pixel.y + 1) || !get_pixel(world, pixel.x + 1, pixel.y + 1) {
            found[6] = true;
        }
    }
    if get_pixel(world, pixel.x + 1, pixel.y + 1) {
        // pixel to the left is transparent or pixel above is transparent
        if !get_pixel(world, pixel.x, pixel.y + 1) || !get_pixel(world, pixel.x + 1, pixel.y) {
            found[7] = true;
        }
    }

    valid_pixel := false;
    most_accurate_pixel := Point.{0, 0};
    most_accurate_abs_angle_diff := 0.0;
    for i: 0..7 {
        if !found[i] {
            continue;
        }

        abs_angle_diff := abs(radians_between(angle, angles[i]));
        if !valid_pixel {
            most_accurate_pixel = pixels[i] + pixel;
            most_accurate_abs_angle_diff = abs_angle_diff;
        } else {
            if abs_angle_diff < most_accurate_abs_angle_diff {
                most_accurate_pixel = pixels[i] + pixel;
                most_accurate_abs_angle_diff = abs_angle_diff;
            }
        }

        valid_pixel = true;
    }

    return valid_pixel, most_accurate_pixel;
}

#scope_file

STEP_HEIGHT :: 16;

pixel_offsets :: Point.[.{0, 0}, .{1, 0}, .{1, 1}, .{0, 1}];