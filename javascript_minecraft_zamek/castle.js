player.onChat("castle", function () {
    const origin = player.position()
    player.teleport(positions.add(origin, pos(0, 60, 0)))

    let size = 16
    let height = 10

    // block types
    const wall = STONE_BRICKS
    const castle_bottom = COBBLESTONE
    const floor = PLANKS_OAK
    const fence = OAK_FENCE
    const flag = RED_WOOL

    // foundation (bottom 2 rows)
    blocks.fill(castle_bottom, origin, positions.add(origin, pos(size, 1, 0)))
    blocks.fill(castle_bottom, positions.add(origin, pos(0, 0, size)), positions.add(origin, pos(size, 1, size)))
    blocks.fill(castle_bottom, origin, positions.add(origin, pos(0, 1, size)))
    blocks.fill(castle_bottom, positions.add(origin, pos(size, 0, 0)), positions.add(origin, pos(size, 1, size)))

    // wall
    blocks.fill(wall, positions.add(origin, pos(0, 2, 0)), positions.add(origin, pos(size, height, 0)))
    blocks.fill(wall, positions.add(origin, pos(0, 2, size)), positions.add(origin, pos(size, height, size)))
    blocks.fill(wall, positions.add(origin, pos(0, 2, 0)), positions.add(origin, pos(0, height, size)))
    blocks.fill(wall, positions.add(origin, pos(size, 2, 0)), positions.add(origin, pos(size, height, size)))

    // floor
    blocks.fill(floor, positions.add(origin, pos(1, 0, 1)), positions.add(origin, pos(size - 1, 0, size - 1)))

    // battlements -> _|-|_|-|_
    for (let x = 0; x <= size; x++) {
        if (x % 2 == 0) {
            blocks.place(wall, positions.add(origin, pos(x, height + 1, 0)))
            blocks.place(wall, positions.add(origin, pos(x, height + 1, size)))
        }
    }
    for (let z = 0; z <= size; z++) {
        if (z % 2 == 0) {
            blocks.place(wall, positions.add(origin, pos(0, height + 1, z)))
            blocks.place(wall, positions.add(origin, pos(size, height + 1, z)))
        }
    }

    // flags
    const polePositions = [
        positions.add(origin, pos(Math.floor(size / 4), height + 1, 0)),
        positions.add(origin, pos(Math.floor(3 * size / 4), height + 1, 0)),
        positions.add(origin, pos(Math.floor(size / 4), height + 1, size)),
        positions.add(origin, pos(Math.floor(3 * size / 4), height + 1, size)),
        positions.add(origin, pos(0, height + 1, Math.floor(size / 4))),
        positions.add(origin, pos(0, height + 1, Math.floor(3 * size / 4))),
        positions.add(origin, pos(size, height + 1, Math.floor(size / 4))),
        positions.add(origin, pos(size, height + 1, Math.floor(3 * size / 4))),
    ]

    for (let p of polePositions) {
        for (let i = 0; i < 4; i++) {
            blocks.place(fence, positions.add(p, pos(0, i, 0)))
        }

        let flagBase = positions.add(p, pos(0, 3, 0))
        blocks.place(flag, positions.add(flagBase, pos(1, 0, 0)))
        blocks.place(flag, positions.add(flagBase, pos(2, 0, 0)))
        blocks.place(flag, positions.add(flagBase, pos(1, -1, 0)))
        blocks.place(flag, positions.add(flagBase, pos(2, -1, 0)))
    }
})
