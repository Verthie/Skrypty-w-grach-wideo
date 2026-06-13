player.onChat("castle", function () {
    const origin = player.position()
    player.teleport(positions.add(origin, pos(0, 60, 0)))

    let size = 16
    let height = 10
    let moatWidth = 4
    let moatDepth = 3
    let entranceWidth = 4
    let entranceHeight = 5

    // block types
    const wall = STONE_BRICKS
    const castle_bottom = COBBLESTONE
    const floor = PLANKS_OAK
    const fence = OAK_FENCE
    const flag = RED_WOOL

    // castle origin is 2 blocks lower than moat origin
    const castleOrigin = positions.add(origin, pos(0, -2, 0))

    // foundation (bottom 2 rows)
    blocks.fill(castle_bottom, castleOrigin, positions.add(castleOrigin, pos(size, 1, 0)))
    blocks.fill(castle_bottom, positions.add(castleOrigin, pos(0, 0, size)), positions.add(castleOrigin, pos(size, 1, size)))
    blocks.fill(castle_bottom, castleOrigin, positions.add(castleOrigin, pos(0, 1, size)))
    blocks.fill(castle_bottom, positions.add(castleOrigin, pos(size, 0, 0)), positions.add(castleOrigin, pos(size, 1, size)))

    // wall
    blocks.fill(wall, positions.add(castleOrigin, pos(0, 2, 0)), positions.add(castleOrigin, pos(size, height, 0)))
    blocks.fill(wall, positions.add(castleOrigin, pos(0, 2, size)), positions.add(castleOrigin, pos(size, height, size)))
    blocks.fill(wall, positions.add(castleOrigin, pos(0, 2, 0)), positions.add(castleOrigin, pos(0, height, size)))
    blocks.fill(wall, positions.add(castleOrigin, pos(size, 2, 0)), positions.add(castleOrigin, pos(size, height, size)))

    // floor
    blocks.fill(floor, positions.add(origin, pos(1, -1, 1)), positions.add(origin, pos(size - 1, -1, size - 1)))

    // empty interior
    blocks.fill(AIR,
        positions.add(origin, pos(1, 1, 1)),
        positions.add(origin, pos(size - 1, height, size - 1))
    )
    
    // battlements -> _|-|_|-|_
    for (let x = 0; x <= size; x++) {
        if (x % 2 == 0) {
            blocks.place(wall, positions.add(castleOrigin, pos(x, height + 1, 0)))
            blocks.place(wall, positions.add(castleOrigin, pos(x, height + 1, size)))
        }
    }
    for (let z = 0; z <= size; z++) {
        if (z % 2 == 0) {
            blocks.place(wall, positions.add(castleOrigin, pos(0, height + 1, z)))
            blocks.place(wall, positions.add(castleOrigin, pos(size, height + 1, z)))
        }
    }

    // windows - two per wall
    // 1 block wide x 2 blocks tall

    let winY1 = 5
    let winY2 = 6

    for (let wx of [5, 11]) {
        blocks.fill(AIR, positions.add(castleOrigin, pos(wx, winY1, 0)), positions.add(castleOrigin, pos(wx, winY2, 0)))
        blocks.fill(AIR, positions.add(castleOrigin, pos(wx, winY1, size)), positions.add(castleOrigin, pos(wx, winY2, size)))
    }
    for (let wz of [5, 11]) {
        blocks.fill(AIR, positions.add(castleOrigin, pos(0, winY1, wz)), positions.add(castleOrigin, pos(0, winY2, wz)))
        blocks.fill(AIR, positions.add(castleOrigin, pos(size, winY1, wz)), positions.add(castleOrigin, pos(size, winY2, wz)))
    }

    // moat
    blocks.fill(WATER,
        positions.add(origin, pos(-moatWidth, -moatDepth, -moatWidth)),
        positions.add(origin, pos(size + moatWidth, -1, -1))
    )
    blocks.fill(WATER,
        positions.add(origin, pos(-moatWidth, -moatDepth, size + 1)),
        positions.add(origin, pos(size + moatWidth, -1, size + moatWidth))
    )
    blocks.fill(WATER,
        positions.add(origin, pos(-moatWidth, -moatDepth, 0)),
        positions.add(origin, pos(-1, -1, size))
    )
    blocks.fill(WATER,
        positions.add(origin, pos(size + 1, -moatDepth, 0)),
        positions.add(origin, pos(size + moatWidth, -1, size))
    )

    blocks.fill(STONE,
        positions.add(origin, pos(-moatWidth, -moatDepth - 1, -moatWidth)),
        positions.add(origin, pos(size + moatWidth, -moatDepth - 1, -1))
    )
    blocks.fill(STONE,
        positions.add(origin, pos(-moatWidth, -moatDepth - 1, size + 1)),
        positions.add(origin, pos(size + moatWidth, -moatDepth - 1, size + moatWidth))
    )
    blocks.fill(STONE,
        positions.add(origin, pos(-moatWidth, -moatDepth - 1, 0)),
        positions.add(origin, pos(-1, -moatDepth - 1, size))
    )
    blocks.fill(STONE,
        positions.add(origin, pos(size + 1, -moatDepth - 1, 0)),
        positions.add(origin, pos(size + moatWidth, -moatDepth - 1, size))
    )

    // entrance
    let entranceX = Math.floor(size / 2)
    blocks.fill(wall,
        positions.add(castleOrigin, pos(entranceX - Math.floor(entranceWidth / 2), 2, size)),
        positions.add(castleOrigin, pos(entranceX + Math.floor(entranceWidth / 2), entranceHeight + 1, size))
    )
    blocks.fill(AIR,
        positions.add(castleOrigin, pos(entranceX - Math.floor(entranceWidth / 2) + 1, 2, size)),
        positions.add(castleOrigin, pos(entranceX + Math.floor(entranceWidth / 2) - 1, entranceHeight, size))
    )

    // bridge
    let bridgeCenter = Math.floor(size / 2)
    let bridgeHalfWidth = 2

    blocks.fill(floor,
        positions.add(origin, pos(bridgeCenter - bridgeHalfWidth, -1, size + 1)),
        positions.add(origin, pos(bridgeCenter + bridgeHalfWidth, -1, size + moatWidth))
    )
    blocks.fill(fence,
        positions.add(origin, pos(bridgeCenter - bridgeHalfWidth, 0, size + 1)),
        positions.add(origin, pos(bridgeCenter - bridgeHalfWidth, 0, size + moatWidth))
    )
    blocks.fill(fence,
        positions.add(origin, pos(bridgeCenter + bridgeHalfWidth, 0, size + 1)),
        positions.add(origin, pos(bridgeCenter + bridgeHalfWidth, 0, size + moatWidth))
    )

    // flags
    const polePositions = [
        positions.add(castleOrigin, pos(Math.floor(size / 4), height + 1, 0)),
        positions.add(castleOrigin, pos(Math.floor(3 * size / 4), height + 1, 0)),
        positions.add(castleOrigin, pos(Math.floor(size / 4), height + 1, size)),
        positions.add(castleOrigin, pos(Math.floor(3 * size / 4), height + 1, size)),
        positions.add(castleOrigin, pos(0, height + 1, Math.floor(size / 4))),
        positions.add(castleOrigin, pos(0, height + 1, Math.floor(3 * size / 4))),
        positions.add(castleOrigin, pos(size, height + 1, Math.floor(size / 4))),
        positions.add(castleOrigin, pos(size, height + 1, Math.floor(3 * size / 4))),
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
