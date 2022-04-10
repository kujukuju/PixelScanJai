main :: () {
    found := false;
    v := Vector2.{0, 0};

    {
        found, v = blah();
    }

    print("%\n", v);
}

blah :: () -> bool, Vector2 {
    return true, .{1, 1};
}

#import "Basic";
#import "Math";