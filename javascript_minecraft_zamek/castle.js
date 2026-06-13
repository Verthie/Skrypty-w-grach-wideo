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

    // windows - two per wall
    // 1 block wide x 2 blocks tall

    let winY1 = 5  // bottom of window
    let winY2 = 6  // top of window

    // north wall (z=0): windows at x=5 and x=11
    let northWins = [5, 11]
    for (let wx of northWins) {
        blocks.fill(AIR, positions.add(origin, pos(wx, winY1, 0)), positions.add(origin, pos(wx, winY2, 0)))
    }

    // south wall (z=size): windows at x=5 and x=11
    let southWins = [5, 11]
    for (let wx of southWins) {
        blocks.fill(AIR, positions.add(origin, pos(wx, winY1, size)), positions.add(origin, pos(wx, winY2, size)))
    }

    // west wall (x=0): windows at z=5 and z=11
    let westWins = [5, 11]
    for (let wz of westWins) {
        blocks.fill(AIR, positions.add(origin, pos(0, winY1, wz)), positions.add(origin, pos(0, winY2, wz)))
    }

    // east wall (x=size): windows at z=5 and z=11
    let eastWins = [5, 11]
    for (let wz of eastWins) {
        blocks.fill(AIR, positions.add(origin, pos(size, winY1, wz)), positions.add(origin, pos(size, winY2, wz)))
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
