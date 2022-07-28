GridManager :: struct {
    cell_width :: 16;
    cell_height :: 16;
    gap :: 2;

    width: int;
    height: int;
    valid: [..] bool;
}

grid_generate :: (grid: *GridManager, world: World) {
    grid.width = cast(int) ((world.width + grid.gap) / (grid.cell_width + grid.gap));
    grid.height = cast(int) ((world.height + grid.gap) / (grid.cell_height + grid.gap));

    array_resize(*grid.valid, grid.width * grid.height);

    for i: 0..grid.valid.count - 1 {
        point: Point;
        point.x = i / grid.width;
        point.y = i % grid.width;

        aabb := grid_get_aabb(<< grid, point);

        // check aabb pixels
        if world_check_aabb_collisions(world, aabb) {
            grid.valid[i] = false;
        } else {
            grid.valid[i] = true;
        }
    }
}

// TODO probably just make this a singleton
grid_get_aabb :: (grid: GridManager, coord: Point) -> AABB {
    start_x := coord.x * grid.cell_width + coord.x * grid.gap;
    start_y := coord.y * grid.cell_height + coord.y * grid.gap;

    aabb: AABB;
    aabb.x = xx start_x;
    aabb.y = xx start_y;
    aabb.width = xx grid.cell_width;
    aabb.height = xx grid.cell_height;
    return aabb;
}

grid_get_center_position :: (grid: GridManager, coord: Point) -> Vector2 {
    aabb := grid_get_aabb(grid, coord);

    vector: Vector2 = ---;
    vector.x = aabb.x + aabb.width / 2;
    vector.y = aabb.y + aabb.height / 2;

    return vector;
}

grid_is_valid :: (grid: GridManager, coord: Point) -> bool {
    if coord.x < 0 || coord.y < 0 || coord.x >= grid.width || coord.y >= grid.height {
        return false;
    }

    index := coord.y * grid.width + coord.x;
    return grid.valid[index];
}

grid_get_coord_from_position :: (grid: GridManager, position: Vector2) -> Point {
    offset_x := position.x - grid.cell_width - grid.gap / 2.0;
    offset_y := position.y - grid.cell_height - grid.gap / 2.0;

    index_x := cast(int) (offset_x / (grid.cell_width + grid.gap)) + 1;
    index_y := cast(int) (offset_y / (grid.cell_height + grid.gap)) + 1;

    coord: Point;
    coord.x = xx index_x;
    coord.y = xx index_y;
    return coord;
}

grid_get_valid_coord_from_position :: (grid: GridManager, position: Vector2) -> Point {
    starting_coord := grid_get_coord_from_position(grid, position);

    offset_radius := 0;
    while offset_radius < 3 {
        defer offset_radius += 1;

        smallest_found := false;
        smallest_coord := starting_coord;
        smallest_distance := FLOAT32_MAX;

        x := -offset_radius;
        while x <= offset_radius {
            defer x += 1;

            y := -offset_radius;
            while y <= offset_radius {
                defer y += 1;

                new_coord: Point;
                new_coord.x = starting_coord.x + x;
                new_coord.y = starting_coord.y + y;

                if grid_is_valid(grid, new_coord) {
                    grid_aabb := grid_get_aabb(grid, new_coord);
                    grid_position: Vector2;
                    grid_position.x = grid_aabb.x + grid_aabb.width / 2;
                    grid_position.y = grid_aabb.y + grid_aabb.height / 2;

                    current_distance := distance(position, grid_position);
                    if current_distance < smallest_distance {
                        smallest_found = true;
                        smallest_coord = new_coord;
                        smallest_distance = current_distance;
                    }
                }
            }
        }

        if smallest_found {
            return smallest_coord;
        }
    }

    assert(false, "Should have found a valid grid by this point.");
    return .{0, 0};
}

grid_get_coord_from_index :: (grid: GridManager, index: int) -> Point {
    p: Point = ---;
    p.x = index % grid.width;
    p.y = index / grid.width;

    return p;
}

grid_get_index_from_coord :: (grid: GridManager, coord: Point) -> int {
    return coord.y * grid.width + coord.x;
}

grid_get_square_area :: (grid: GridManager, start_coord: Point, half_width: u8, half_height: u8) -> [..] Point {
    QueueEntry :: struct {
        index: int;
        remaining_x: int;
        remaining_y: int;
    }

    visited_indices: [..] int;
    defer array_free(visited_indices);

    queue: [..] QueueEntry;
    defer array_free(queue);

    first_entry: QueueEntry;
    first_entry.index = grid_get_index_from_coord(grid, start_coord);
    first_entry.remaining_x = half_width;
    first_entry.remaining_y = half_height;
    array_add(*queue, first_entry);

    while queue.count > 0 {
        entry := queue[0];
        array_ordered_remove_by_index(*queue, 0);
        
        entry_coord := grid_get_coord_from_index(grid, entry.index);
        if !grid_is_valid(grid, entry_coord) {
            continue;
        }

        index := entry.index;
        if array_find(visited_indices, index) {
            continue;
        }
        array_add(*visited_indices, index);

        if entry.remaining_x > 0 || entry.remaining_y > 0 {
            if entry.remaining_x > 0 {
                if grid_is_valid(grid, point(entry_coord.x - 1, entry_coord.y)) {
                    next_index := grid_get_index_from_coord(grid, point(entry_coord.x - 1, entry_coord.y));

                    if !array_find(visited_indices, next_index) {
                        next_entry: QueueEntry;
                        next_entry.index = next_index;
                        next_entry.remaining_x = entry.remaining_x - 1;
                        next_entry.remaining_y = entry.remaining_y;
                        array_add(*queue, next_entry);
                    }
                }
                if grid_is_valid(grid, point(entry_coord.x + 1, entry_coord.y)) {
                    next_index := grid_get_index_from_coord(grid, point(entry_coord.x + 1, entry_coord.y));

                    if !array_find(visited_indices, next_index) {
                        next_entry: QueueEntry;
                        next_entry.index = next_index;
                        next_entry.remaining_x = entry.remaining_x - 1;
                        next_entry.remaining_y = entry.remaining_y;
                        array_add(*queue, next_entry);
                    }
                }
            }
            if entry.remaining_y > 0 {
                if grid_is_valid(grid, point(entry_coord.x, entry_coord.y - 1)) {
                    next_index := grid_get_index_from_coord(grid, point(entry_coord.x, entry_coord.y - 1));

                    if !array_find(visited_indices, next_index) {
                        next_entry: QueueEntry;
                        next_entry.index = next_index;
                        next_entry.remaining_x = entry.remaining_x;
                        next_entry.remaining_y = entry.remaining_y - 1;
                        array_add(*queue, next_entry);
                    }
                }
                if grid_is_valid(grid, point(entry_coord.x, entry_coord.y + 1)) {
                    next_index := grid_get_index_from_coord(grid, point(entry_coord.x, entry_coord.y + 1));

                    if !array_find(visited_indices, next_index) {
                        next_entry: QueueEntry;
                        next_entry.index = next_index;
                        next_entry.remaining_x = entry.remaining_x;
                        next_entry.remaining_y = entry.remaining_y - 1;
                        array_add(*queue, next_entry);
                    }
                }
            }
        }
    }

    visited_points: [..] Point;
    array_reserve(*visited_points, visited_indices.count);

    for index: visited_indices {
        visited_point := grid_get_coord_from_index(grid, index);
        array_add(*visited_points, visited_point);
    }

    return visited_points;
}

AABB :: struct {
    x: float;
    y: float;
    width: float;
    height: float;
}

#scope_file