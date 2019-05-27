//
//  GameScene.swift
//  FlyBird
//
//  Created by NCIT Mobile Desktop on 2019/5/17.
//  Copyright © 2019 NCIT Mobile Desktop. All rights reserved.
//

import SpriteKit
import GameplayKit

// 设置三个常量来表示小鸟、水管和地面物理体，
let birdCategory: UInt32 = 0x1 << 0
let pipeCategory: UInt32 = 0x1 << 1
let floorCategory: UInt32 = 0x1 << 2

class GameScene: SKScene, SKPhysicsContactDelegate {
    enum GameStatus {
        case idle
        case running
        case over
    }
    
    var gameStatus: GameStatus = .idle
    
    var floor1: SKSpriteNode!
    var floor2: SKSpriteNode!
    
    var bird: SKSpriteNode!
    
    lazy var gameStartLabel: SKLabelNode = {
        let label = SKLabelNode(fontNamed: "Chalkduster")
        label.text = "Tap to start the game"
        label.fontSize = 20.0
        label.position = CGPoint(x: self.size.width * 0.5, y: self.size.height * 0.6)
        label.horizontalAlignmentMode = .center
        return label
    }()
    
    lazy var gameOverLabel: SKLabelNode = {
        let label = SKLabelNode(fontNamed: "Chalkduster")
        label.text = "Game Over"
        return label
    }()
    
    lazy var metersLabel: SKLabelNode = {
        let label = SKLabelNode(text: "meters:0")
        label.verticalAlignmentMode = .top
        label.horizontalAlignmentMode = .center
        
        return label
    }()
    
    var meters = 0 {
        didSet {
            metersLabel.text = "meters:\(meters)"
        }
    }
    
    override func didMove(to view: SKView) {
        self.backgroundColor = SKColor(red: 80.0/255.0, green: 192.0/255.0, blue: 203.0/255.0, alpha: 1.0)
        
        // Set Scene physics 配置场景的物理体
        self.physicsBody = SKPhysicsBody(edgeLoopFrom: self.frame)
        self.physicsWorld.contactDelegate = self //物理世界的碰撞检测代理
        
        // Set Meter Label
        metersLabel.position = CGPoint(x: self.size.width * 0.5, y: self.size.height)
        metersLabel.zPosition = 100
        addChild(metersLabel)
        
        // set floors
        floor1 = SKSpriteNode(imageNamed: "floor")
        floor1.physicsBody = SKPhysicsBody(edgeLoopFrom: CGRect(x:0, y: 0, width: floor1.size.width, height: floor1.size.height))
        floor1.physicsBody?.categoryBitMask = floorCategory
        floor1.anchorPoint = CGPoint(x: 0, y: 0)
        floor1.position = CGPoint(x: 0, y: 0)
        addChild(floor1)
        
        floor2 = SKSpriteNode(imageNamed: "floor")
        floor2.physicsBody = SKPhysicsBody(edgeLoopFrom: CGRect(x:0, y: 0, width: floor2.size.width, height: floor2.size.height))
        floor2.physicsBody?.categoryBitMask = floorCategory
        floor2.anchorPoint = CGPoint(x: 0, y: 0)
        floor2.position = CGPoint(x: floor1.size.width, y: 0)
        addChild(floor2)
        
        // set bird
        bird = SKSpriteNode(imageNamed: "player1")
        bird.physicsBody = SKPhysicsBody(texture: bird.texture!, size: bird.size)
        bird.physicsBody?.allowsRotation = false
        bird.physicsBody?.categoryBitMask = birdCategory
        bird.physicsBody?.contactTestBitMask = floorCategory | pipeCategory //设置可以小鸟碰撞检测的物理体
        addChild(bird)
        
        self.shuffle()
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        if gameStatus == .running {
            meters += 1
        }
        if gameStatus != .over {
            moveSence()
        }
    }
    
    func shuffle() {
        gameStatus = .idle
        
        meters = 0
        
        addChild(gameStartLabel)

        gameOverLabel.removeFromParent()
        removeAllPipesNode()
        
        bird.position = CGPoint(x: self.size.width * 0.5, y: self.size.height * 0.5)
        bird.physicsBody?.isDynamic = false
        birdStartFly()
    }
    
    func startGame() {
        gameStatus = .running
        
        gameStartLabel.removeFromParent();
        bird.physicsBody?.isDynamic = true
        startCreateRandomPipesAction()  //开始循环创建随机水管
    }
    
    func gameOver() {
        gameStatus = .over
        
        birdStopFly()
        stopCreateRandomPipesAction()
        
        isUserInteractionEnabled = false
        
        addChild(gameOverLabel)
        gameOverLabel.position = CGPoint(x: self.size.width * 0.5, y: self.size.height)
        gameOverLabel.run(SKAction.move(by: CGVector(dx:0, dy:-self.size.height * 0.5), duration: 0.5), completion: {
            self.isUserInteractionEnabled = true
        })
    }
    // 触碰屏幕时触发该方法
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        switch gameStatus {
        case .idle:
            startGame()
        case .running:
            bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 20))
        case .over:
            shuffle()
        }
    }
    // 使屏幕向左移动
    func moveSence() {
        // make floor move
        floor1.position = CGPoint(x: floor1.position.x - 1, y: floor1.position.y)
        floor2.position = CGPoint(x: floor2.position.x - 1, y: floor2.position.y)
        // check floor position
        if floor1.position.x < -floor1.size.width {
            floor1.position = CGPoint(x: floor2.position.x + floor2.size.width, y: floor1.position.y)
        }
        
        if floor2.position.x < -floor2.size.width {
            floor2.position = CGPoint(x: floor1.position.x + floor1.size.width, y: floor2.position.y)
        }
        
        for pipeNode in self.children where pipeNode.name == "pipe" {
            //因为我们要用到水管的size，但是SKNode没有size属性，所以我们要把它转成SKSpriteNode
            if let pipeSprite = pipeNode as? SKSpriteNode {
                //将水管左移1
                pipeSprite.position = CGPoint(x: pipeSprite.position.x - 1, y: pipeSprite.position.y)
                //检查水管是否完全超出屏幕左侧了，如果是则将它从场景里移除
                if pipeSprite.position.x < -pipeSprite.size.width * 0.5 {
                    pipeSprite.removeFromParent()
                }
            }
        }
    }
    
    // 使小鸟开始飞
    func birdStartFly() {
        let flyAction = SKAction.animate(with: [SKTexture(imageNamed: "player1"), SKTexture(imageNamed: "player2"), SKTexture(imageNamed: "player3"), SKTexture(imageNamed: "player2")], timePerFrame: 0.15)
        bird.run(SKAction.repeatForever(flyAction), withKey:"fly")
    }
    
    // 小鸟停止飞
    func birdStopFly() {
        bird.removeAction(forKey: "fly")
    }
    
    func addPipes(topSize: CGSize, bottomSize: CGSize) {
        let topTexture = SKTexture(imageNamed: "topPipe")
        let topPipe = SKSpriteNode(texture: topTexture, size: topSize)
        topPipe.physicsBody = SKPhysicsBody(texture: topTexture, size: topSize)
        topPipe.physicsBody?.isDynamic = false
        topPipe.physicsBody?.categoryBitMask = pipeCategory
        topPipe.name = "pipe"
        topPipe.position = CGPoint(x: self.size.width + topPipe.size.width * 0.5, y: self.size.height - topPipe.size.height * 0.5)
        
        let bottomTexture = SKTexture(imageNamed: "bottomPipe")
        let bottomPipe = SKSpriteNode(texture: bottomTexture, size: bottomSize)
        bottomPipe.physicsBody = SKPhysicsBody(texture: bottomTexture, size: bottomSize)
        bottomPipe.physicsBody?.isDynamic = false
        bottomPipe.physicsBody?.categoryBitMask = pipeCategory
        bottomPipe.name = "pipe"
        bottomPipe.position = CGPoint(x: self.size.width + bottomPipe.size.width * 0.5, y: self.floor1.size.height + bottomPipe.size.height * 0.5)
        
        addChild(topPipe)
        addChild(bottomPipe)
    }
    
    func createRandomPipes() {
        // 计算地板顶部到屏幕顶部的可用高度
        let hegiht = self.size.height - self.floor1.size.height
        // 计算上下管道之间的通道宽度，最小为2.5倍的小鸟高度，最大为3.5倍的小鸟高度
        let pipeGap = CGFloat(arc4random_uniform(UInt32(bird.size.height))) + bird.size.height * 2.5
        
        // 管道宽度为60
        let pipeWidth = CGFloat(60.0)
        // let pipeWidth = CGFloat(arc4random_uniform(20) + 60)
        
        // 随机计算顶部pipe的随机高度
        let topPipeHeight = CGFloat(arc4random_uniform(UInt32(hegiht - pipeGap)))
        
        // 总可用高度 - 空挡Gap高度 - 顶部topPipe高度 = 底部可用高度
        let bottomPipeHeight = hegiht - pipeGap - topPipeHeight
        // 调用添加水管到场景方法
        addPipes(topSize: CGSize(width: pipeWidth, height: topPipeHeight), bottomSize: CGSize(width: pipeWidth, height: bottomPipeHeight))
    }
    
    func startCreateRandomPipesAction() {
        // 创建一个等待的Action，等待时间为3.5秒。变化时间为1秒
        let waitAct = SKAction.wait(forDuration: 3.5, withRange: 1.0)
        // 创建一个产生随机水管的action，createRandomPipes()
        let generatePipeAct = SKAction.run {
            self.createRandomPipes()
        }
        // 让场景循环重复执行
        // 并且给这个场景动作设置一个“createPipe”的key来标识它
        run(SKAction.repeatForever(SKAction.sequence([waitAct, generatePipeAct])), withKey: "createPipe")
    }
    
    func stopCreateRandomPipesAction() {
        self.removeAction(forKey: "createPipe")
    }
    
    func removeAllPipesNode() {
        //循环检查场景的子节点，同时这个子节点的名字要为pipe
        for pipe in self.children where pipe.name == "pipe" {
            pipe.removeFromParent() //将水管这个节点从场景里移除掉
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        //先检查游戏状态是否在运行中，如果不在运行中则不做操作，直接return
        if gameStatus != .running { return }
        
        var bodyA : SKPhysicsBody
        var bodyB : SKPhysicsBody
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            bodyA = contact.bodyA
            bodyB = contact.bodyB
        } else {
            bodyA = contact.bodyB
            bodyB = contact.bodyA
        }
        
        if (bodyA.categoryBitMask == birdCategory && bodyB.categoryBitMask == pipeCategory || bodyA.categoryBitMask == birdCategory && bodyB.categoryBitMask == floorCategory ) {
            gameOver()
        }
    }
}
