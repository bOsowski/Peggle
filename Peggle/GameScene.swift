import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var scoreLabel: SKLabelNode!
    var editLabel: SKLabelNode!
    var ballsLabel: SKLabelNode!
    var ballInfo = [SKNode:Ball]()
    var amountOfBalls = 5 {
        didSet{
            ballsLabel.text = "Balls: \(amountOfBalls)"
        }
    }

    var score = 0 {
        didSet {
            scoreLabel.text = "Score: \(score)"
        }
    }
    

    
    var editingMode: Bool = false {
        didSet {
            if editingMode {
                editLabel.text = "Done"
            } else {
                editLabel.text = "Edit"
            }
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        guard let nodeA = contact.bodyA.node else { return }
        guard let nodeB = contact.bodyB.node else { return }
        
        if nodeA.name == "ball" {
            collisionBetween(ball: nodeA, object: nodeB)
        } else if nodeB.name == "ball" {
            collisionBetween(ball: nodeB, object: nodeA)
        }
    }

    override func didMove(to view: SKView) {
        let background = SKSpriteNode(imageNamed: "background.jpg")
        background.position = CGPoint(x: 512, y: 384)
        background.blendMode = .replace
        background.zPosition = -1
        addChild(background)
        physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
        physicsWorld.contactDelegate = self
        
        makeSlot(at: CGPoint(x: 128, y: 0), isGood: true)
        makeSlot(at: CGPoint(x: 384, y: 0), isGood: false)
        makeSlot(at: CGPoint(x: 640, y: 0), isGood: true)
        makeSlot(at: CGPoint(x: 896, y: 0), isGood: false)
        
        makeBouncer(at: CGPoint(x: 0, y: 0))
        makeBouncer(at: CGPoint(x: 256, y: 0))
        makeBouncer(at: CGPoint(x: 512, y: 0))
        makeBouncer(at: CGPoint(x: 768, y: 0))
        makeBouncer(at: CGPoint(x: 1024, y: 0))
        
        scoreLabel = SKLabelNode(fontNamed: "Chalkduster")
        scoreLabel.text = "Score: 0"
        scoreLabel.horizontalAlignmentMode = .right
        scoreLabel.position = CGPoint(x: 980, y: 700)
        addChild(scoreLabel)
        
        editLabel = SKLabelNode(fontNamed: "Chalkduster")
        editLabel.text = "Edit"
        editLabel.position = CGPoint(x: 80, y: 700)
        addChild(editLabel)
        
        ballsLabel = SKLabelNode(fontNamed: "Chalkduster")
        ballsLabel.text = "Balls: \(amountOfBalls)"
        ballsLabel.position = CGPoint(x: 240, y: 700)
        addChild(ballsLabel)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let location = touch.location(in: self)
            let objects = nodes(at: location)
            
            if objects.contains(editLabel) {
                editingMode = !editingMode
            } else {
                if editingMode {
                    var touchedBox = false
                        enumerateChildNodes(withName: "box") {(node, _) in
                            if(node.contains(touch.location(in: self))){
                                print("touching node!")
                                node.removeFromParent()
                                touchedBox = true
                            }
                        }
                    if touchedBox == false{
                        let size = CGSize(width: GKRandomDistribution(lowestValue: 16, highestValue: 128).nextInt(), height: 16)
                        let box = SKSpriteNode(color: RandomColor(), size: size)
                        box.name = "box"
                        box.zRotation = RandomCGFloat(min: 0, max: 3)
                        box.position = location
                        
                        box.physicsBody = SKPhysicsBody(rectangleOf: box.size)
                        box.physicsBody?.isDynamic = false
                        addChild(box)
                    }
                } else if(amountOfBalls > 0){
                    // create a ball
                    let ballColour = ["ballGrey", "ballBlue", "ballPurple", "ballRed", "ballCyan", "ballYellow", "ballGreen"]
                    let pickedColour = ballColour[Int.random(in: 0 ..< ballColour.count)]
                    let ball = SKSpriteNode(imageNamed: pickedColour)

                    ball.name = "ball"
                    ball.physicsBody = SKPhysicsBody(circleOfRadius: ball.size.width / 2.0)
                    ball.physicsBody?.restitution = 0.4
                    ball.physicsBody!.contactTestBitMask = ball.physicsBody!.collisionBitMask
                    ball.position = CGPoint(x: location.x, y: 650)
                    ballInfo[ball] = Ball(colour: pickedColour)
                    addChild(ball)
                    amountOfBalls -= 1
                }
            }
        }
    }

    
    func makeSlot(at position: CGPoint, isGood: Bool) {
        var slotBase: SKSpriteNode
        var slotGlow: SKSpriteNode
        
        if isGood {
            slotBase = SKSpriteNode(imageNamed: "slotBaseGood")
            slotGlow = SKSpriteNode(imageNamed: "slotGlowGood")
            slotBase.name = "good"
        } else {
            slotBase = SKSpriteNode(imageNamed: "slotBaseBad")
            slotGlow = SKSpriteNode(imageNamed: "slotGlowBad")
            slotBase.name = "bad"
        }
        
        slotBase.position = position
        slotGlow.position = position
        
        slotBase.physicsBody = SKPhysicsBody(rectangleOf: slotBase.size)
        slotBase.physicsBody?.isDynamic = false
        
        addChild(slotBase)
        addChild(slotGlow)
        let spin = SKAction.rotate(byAngle: .pi, duration: 10)
        let spinForever = SKAction.repeatForever(spin)
        slotGlow.run(spinForever)
    }
    
    func makeBouncer(at position: CGPoint) {
        let bouncer = SKSpriteNode(imageNamed: "bouncer")
        bouncer.position = position
        bouncer.physicsBody = SKPhysicsBody(circleOfRadius: bouncer.size.width / 2.0)
        bouncer.physicsBody?.isDynamic = false
        bouncer.name = "bouncer"
        addChild(bouncer)
    }
    
    func collisionBetween(ball: SKNode, object: SKNode) {
        if object.name == "good" {
            score += (ballInfo[ball]?.boxHits)!
            ballInfo[ball] = nil
            destroy(ball: ball)
            amountOfBalls += 1
        } else if object.name == "bad" {
            score -= 1
            ballInfo[ball] = nil
            destroy(ball: ball)
        } else if object.name == "box" {
            ballInfo[ball]?.boxHits += 1
            object.removeFromParent()
        } else if object.name == "bouncer" {
            print("collided with bouncer")
            ballInfo[ball]?.bouncerHits.insert(object)
            if (ballInfo[ball]?.bouncerHits.count)! > 1{
                print("collided with 2 different bouncers. teleporting.")
                ball.run(SKAction.move(to:  CGPoint(x: ball.position.x, y: 650), duration: 0))
                ballInfo[ball]?.bouncerHits.removeAll()
            }
        }
    }
    
    func destroy(ball: SKNode) {
        if let fireParticles = SKEmitterNode(fileNamed: "FireParticles") {
            fireParticles.position = ball.position
            addChild(fireParticles)
        }
        
        ball.removeFromParent()
    }
    
    class Ball{
        var boxHits:Int
        var bouncerHits:Set<SKNode>
        var colour:String
        
        init(colour: String) {
            self.boxHits = 0
            self.bouncerHits = []
            self.colour = colour
        }
    }
}
