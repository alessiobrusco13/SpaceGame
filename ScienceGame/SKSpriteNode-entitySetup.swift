//
//  SKSpriteNode-entitySetup.swift
//  ScienceGame
//
//  Created by Alessio Garzia Marotta Brusco on 23/01/22.
//

import SpriteKit

extension SKSpriteNode {
    static func setUp(enemy: Bool) -> SKSpriteNode {
        let sprite = SKSpriteNode(imageNamed: enemy ? "asteroid.png" : "energy.png")

        sprite.position = CGPoint(x: 1200, y: .random(in: -350...350))
        sprite.name = enemy ? "enemy" : "bonus"
        sprite.zPosition = 1

        sprite.physicsBody = SKPhysicsBody(texture: sprite.texture!, size: sprite.size)
        sprite.physicsBody?.velocity = CGVector(dx: enemy ? -400 : -350, dy: 0)
        sprite.physicsBody?.affectedByGravity = false
        sprite.physicsBody?.linearDamping = 0
        sprite.physicsBody?.contactTestBitMask = enemy ? PhysicsCategory.player|PhysicsCategory.projectile : PhysicsCategory.player
        sprite.physicsBody?.categoryBitMask = PhysicsCategory.standard

        if  !enemy {
            sprite.physicsBody?.collisionBitMask = PhysicsCategory.standard
        }

        return sprite
    }
}
