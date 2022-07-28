World :: struct {
    width: int;
    height: int;
    pixels: [..] bool;
}

// just assumes it goes in 0,0
load_physics_image :: (world: *World, image_path: string) {
    image_data, success := read_entire_file(image_path, false);
    defer free(image_data);

    assert(success, "Could not load texture data.");

    // comp is stride
    width: s32;
    height: s32;
    comp: s32;
    byte_data: *u8 = stbi_load_from_memory(image_data.data, xx image_data.count, *width, *height, *comp, 0);
    assert(!!byte_data, "Could not parse texture data.");

    world.width = width;
    world.height = height;

    array_resize(*world.pixels, width * height);
    
    for y: 0..height - 1 {
        for x: 0..width - 1 {
            pixel_index := y * world.width + x;
            alpha_index := (y * width + x) * comp + (comp - 1);

            world.pixels.data[pixel_index] = !!byte_data[alpha_index];
        }
    }

    // if comp == 1 {
    //     texture_data.format = .PIXELFORMAT_UNCOMPRESSED_GRAYSCALE;
    // } else if comp == 2 {
    //     texture_data.format = .PIXELFORMAT_UNCOMPRESSED_GRAY_ALPHA;
    // } else if comp == 3 {
    //     texture_data.format = .PIXELFORMAT_UNCOMPRESSED_R8G8B8;
    // } else if comp == 4 {
    //     texture_data.format = .PIXELFORMAT_UNCOMPRESSED_R8G8B8A8;
    // }
}

world_check_aabb_collisions :: (world: World, aabb: AABB) -> bool {
    for y: 0..cast(int) aabb.height - 1 {
        for x: 0..cast(int) aabb.width - 1 {
            point: Point = ---;
            point.x = cast(int) aabb.x + x;
            point.y = cast(int) aabb.y + y;

            if world_get_pixel(world, point) {
                return true;
            }
        }
    }

    return false;
}

world_get_pixel :: (world: World, pixel: Point) -> bool {
    if pixel.x < 0 || pixel.y < 0 || pixel.x >= world.width || pixel.y >= world.height {
        return false;
    }

    return world.pixels[pixel.y * world.width + pixel.x];
}

#scope_file

#import "stb_image";
#import "File";
