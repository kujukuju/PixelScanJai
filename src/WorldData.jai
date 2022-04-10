WorldData :: struct {
    data: *u8;
    width: int;
    height: int;
    offset: int;
    stride: int;
}

get_pixel :: (world: WorldData, x: int, y: int) -> bool {
    if x < 0 || y < 0 || x >= world.width || y >= world.height {
        return false;
    }

    index := y * world.width + x;
    return world.data[index * world.stride + world.offset] > 0;
}