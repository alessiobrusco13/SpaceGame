//
//  GameScene.swift
//  ScienceGame
//
//  Created by Alessio Garzia Marotta Brusco on 23/01/2022.
//

import CoreMotion
import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    let motionManager = CMMotionManager()
    var gameTimer: Timer?

    let player = SKSpriteNode(imageNamed: "img1.png")
    var canShoot = true

    let scoreLabel = SKLabelNode(fontNamed: "AvenirNextCondensed-Bold")
    let eraLabel = SKLabelNode(fontNamed: "AvenirNextCondensed-Bold")

    var score = 0 {
        didSet { scoreChanged() }
    }

    var era = 0 {
        didSet { eraChanged() }
    }

    let music = SKAudioNode(fileNamed: "TIE Fighter Attack.aiff")

    var gameOver = false

    override func didMove(to view: SKView) {
        // this method is called when your game scene is ready to run

        physicsWorld.contactDelegate = self

        let background = SKSpriteNode(color: .black, size: UIScreen.main.bounds.size)
        background.zPosition = -1
        addChild(background )

        if let particles = SKEmitterNode(fileNamed: "SpaceDust") {
            particles.advanceSimulationTime(10)
            particles.position.x = 512
            addChild(particles)
        }

        addChild(music)

        player.position.x = -400
        player.zPosition = 1

        player.physicsBody = SKPhysicsBody(texture: player.texture!, size: player.size)
        player.physicsBody?.affectedByGravity = false
        player.physicsBody?.categoryBitMask = PhysicsCategory.player

        player.constraints = [
            .positionX(SKRange(lowerLimit: -size.width/2, upperLimit: size.width/2)),
            .positionY(SKRange(lowerLimit: -size.height/2, upperLimit: size.height/2))
        ]

        addChild(player)

        score = 0
        scoreLabel.zPosition = 2
        scoreLabel.position = CGPoint(x: -scoreLabel.frame.size.width - 10, y: 300)
        addChild(scoreLabel)

        era = 1
        eraLabel.zPosition = 2
        eraLabel.position = CGPoint(x: eraLabel.frame.size.width + 10, y: 300)
        addChild(eraLabel)

        motionManager.startAccelerometerUpdates()

        gameTimer = Timer.scheduledTimer(withTimeInterval: 0.9, repeats: true, block: createEnemy)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // this method is called when the user touches the screen

        if gameOver {
            if let scene = GameScene(fileNamed: "GameScene") {
                scene.scaleMode = .aspectFill
                self.view?.presentScene(scene)
            }
        } else {
            if canShoot { shoot() }
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        // this method is called when the user touches the screen
    }

    override func update(_ currentTime: TimeInterval) {
        // this method is called before each frame is rendered

        if let accelerometerData = motionManager.accelerometerData {
            let changeX = accelerometerData.acceleration.y * 50
            let changeY = accelerometerData.acceleration.x * 50

            player.position.x -= changeX
            player.position.y += changeY
        }

        for node in children {
            if isOutOfBounds(node) {
                node.removeFromParent()
            }
        }
    }

    func createEnemy(_ timer: Timer) {
        createBonus()

        let sprite = SKSpriteNode.setUp(enemy: true)
        addChild(sprite)
    }

    func createBonus() {
        let sprite = SKSpriteNode.setUp(enemy: false)
        addChild(sprite)
    }

    func didBegin(_ contact: SKPhysicsContact) {
        guard let nodeA = contact.bodyA.node else { return }
        guard let nodeB = contact.bodyB.node else { return }

        if nodeA.name == "projectile" {
            projectile(nodeA, hit: nodeB)
            return
        } else if nodeB.name == "projectile" {
            projectile(nodeB, hit: nodeA)
            return
        }

        if nodeA == player {
            playerHit(nodeB)
        } else {
            playerHit(nodeA)
        }
    }

    func playerHit(_ node: SKNode) {
        guard node.name != "projectile" else { return }

        if node.name == "bonus" {
            score += 3
            node.removeFromParent()

            let sound = SKAction.playSoundFileNamed("bonus.wav", waitForCompletion: false)
            run(sound)

            return
        }

        if let particles = SKEmitterNode(fileNamed: "Explosion.sks") {
            particles.position = player.position
            particles.zPosition = 3
            addChild(particles)
        }

        player.removeFromParent()

        let sound = SKAction.playSoundFileNamed("explosion.wav", waitForCompletion: false)
        run(sound)

        music.removeFromParent()

        let gameOver = SKSpriteNode(imageNamed: "gameOver")
        gameOver.zPosition = 10
        addChild(gameOver)
        self.gameOver = true
    }

    func scoreChanged() {
        scoreLabel.text = "SCORE: \(score)"

        if score >= 4 {
            era += 1
        }
    }

    func eraChanged() {
        eraLabel.text = "ERA \(era)"
        score = 0

        if era != 6 {
            let newTexture = SKTexture(imageNamed: "img\(era)")
            let action = SKAction.setTexture(newTexture)
            player.run(action)
        }
    }

    func shoot() {
        let sprite = SKShapeNode()
        sprite.name = "projectile"

        sprite.path = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: 20, height: 5), cornerRadius: 10).cgPath
        sprite.position = player.position
        sprite.zPosition = 1
        sprite.fillColor = .orange
        sprite.strokeColor = .clear
        sprite.lineWidth = 2

        sprite.physicsBody = SKPhysicsBody(polygonFrom: sprite.path!)
        sprite.physicsBody?.velocity = CGVector(dx: 500, dy: 0)
        sprite.physicsBody?.affectedByGravity = false
        sprite.physicsBody?.linearDamping = 0
        sprite.physicsBody?.contactTestBitMask = PhysicsCategory.standard
        sprite.physicsBody?.categoryBitMask = PhysicsCategory.projectile

        addChild(sprite)

        canShoot = false

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.canShoot = true
        }
    }

    func projectile(_ projectile: SKNode, hit node: SKNode) {
        if let particles = SKEmitterNode(fileNamed: "Explosion.sks") {
            particles.position = node.position
            particles.zPosition = 3
            addChild(particles)
        }

        let sound = SKAction.playSoundFileNamed("explosion.wav", waitForCompletion: false)
        run(sound)

        projectile.removeFromParent()
        node.removeFromParent()

        score += 1
    }

    func isOutOfBounds(_ node: SKNode) -> Bool {
        let position = node.position

        let outLeft = position.x < (-self.size.width/2) - 100
        let outBottom = position.y < (-self.size.width/2) - 100
        let outTop = position.y > (self.size.width/2) + 100

        return outLeft || outBottom || outTop
    }
}
