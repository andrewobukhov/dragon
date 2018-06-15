//
//  GameScene.swift
//  DragAndDrop
//
//  Created by Andrew Obukhov on 24/05/2018.
//  Copyright © 2018 Andrew Obukhov. All rights reserved.
//

import SpriteKit
import GameplayKit
import AVFoundation

class GameScene: SKScene {
    
    private var capitan : SKSpriteNode?
    
    private var box : SKSpriteNode?
    
    private var master : SKNode?
    
    private var grounds = [SKSpriteNode]()
    
    private var currentLetter = ""
    
    private var knownLetters:[String] = []
    
    private var letters:[String] = []
    
    private let successPhrases = ["Молодец", "Отлично", "Супер"]
    
    private let faildPhrases =  ["Ошибочка", "Ой", "Будь внимателен", "Не торопись"]
    
    override func didMove(to view: SKView) {
        reinit()
    }
    
    func reinit() {
        guard let master = self.childNode(withName: "master") else {return}
        self.master = master
        
        initCapitan()
        initGrounds()
        initBox()
        shuffleLetters()
        
        demo()
    }
    
    func initCapitan() {
        guard let capitan = getChild( "capitan") as? SKSpriteNode else {
            print("capitan NOT found")
            return
            
        }
        self.capitan = capitan
        self.capitan?.position = CGPoint(x: 53, y: 100)
        
        
        restCapitan()
    }
    
    func restCapitan() {
        let animation = SKAction.repeatForever(SKAction.animate(with: getTexturesByAtlas("rest"), timePerFrame: 0.1))
        self.capitan?.removeAllActions()
        self.capitan?.run(animation, withKey: "rest")
    }
    
    func initBox() {
        guard let box = getChild( "box") as? SKSpriteNode else {return}
        box.texture = SKTexture(imageNamed: "dark-wood-closed")
        self.box = box
    }
    
    func moveGround(node: SKSpriteNode, shift: CGFloat, duration: TimeInterval) {
        let sequence =  [SKAction.moveBy(x: 0, y: shift, duration: duration),
                         SKAction.moveBy(x: 0, y: -shift, duration: duration)]
        
        node.run(SKAction.repeatForever(SKAction.sequence(sequence)))
    }
    
    func speakPhrase(phrases: [String]) {
        speak(text: phrases[GKRandomSource.sharedRandom().nextInt(upperBound: phrases.count)])
    }
    
    func getChild(_ name: String) -> SKNode? {
        return self.master?.childNode(withName: name)
    }
    
    func initGrounds() {
        self.grounds = []
        for i in 0 ..< 4 {
            if let g = getChild("ground\(i + 1)") as? SKSpriteNode {
                moveGround(node: g, shift: 25, duration: (Double(i) / 2.0) + 1)
                grounds.append(g)
            }
        }
    }
    
    func getTexturesByAtlas(_ atlasName: String) -> [SKTexture] {
       let atlas = SKTextureAtlas(named: atlasName)
       return atlas.textureNames.sorted().map { name in atlas.textureNamed(name) }
    }
    
    func shuffleLetters() {
        let allLetters = ["Э", "И", "У", "Ы", "А", "О"]
        self.knownLetters = []
        self.letters = []
        
        let shuffled = GKRandomSource.sharedRandom().arrayByShufflingObjects(in: allLetters).prefix(grounds.count)
    
        for (index, node) in grounds.enumerated() {
            if let letter = node.childNode(withName: "letter") as? SKLabelNode {
                letter.text = shuffled[index] as? String
                self.letters.append(letter.text!)
                 print(letter.text!, self.letters)
            }
        }
        
        setNewCurrentLetter()
    }
    
    func setNewCurrentLetter() {
        let letters = self.letters.filter { !knownLetters.contains($0) }
        
        if(!letters.isEmpty){
            self.currentLetter = letters[GKRandomSource.sharedRandom().nextInt(upperBound: letters.count)]
            
            //DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
            //    self.speak(text: self.currentLetter)
           // })
        }
    }
    
    let synthesizer = AVSpeechSynthesizer()
    
    func speak(text: String) {
        let utterance = AVSpeechUtterance(string: text + "!")
        utterance.voice = AVSpeechSynthesisVoice(language: "ru-RUS")
        
        //let synthesizer = AVSpeechSynthesizer()
        synthesizer.pauseSpeaking(at: .word)
        synthesizer.speak(utterance)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let location = touch.location(in: self.master!)
            
            let ground = self.grounds.first {$0.contains(location)}
            
            if self.capitan!.contains(location) {
                speak(text: currentLetter)
            } else if let groundNode = ground {
                guard let letterNode = groundNode.childNode(withName: "letter") as? SKLabelNode else {return}
                
                if letterNode.text == currentLetter {
                    foundLetter(groundNode, letterNode: letterNode)
                } else if letterNode.text != nil {
                    speakPhrase(phrases: self.faildPhrases)
                }
            }
        }
    }
    
    func foundLetter(_ ground: SKSpriteNode, letterNode: SKLabelNode) {
        speakPhrase(phrases: self.successPhrases)
        ground.removeAllActions();
        letterNode.text = nil
    
        ground.run(SKAction.moveTo(y: CGFloat(44), duration: 1))
        self.knownLetters.append(currentLetter)
        
        if(self.knownLetters.count >= self.letters.count){
            onFinish()
        }
        else {
            setNewCurrentLetter()
        }
    }
    
    func moveCapitanToFinish() {
        if capitan?.action(forKey: "walk") == nil {
            let animation = SKAction.repeatForever(SKAction.animate(with: getTexturesByAtlas("walk"), timePerFrame: 0.1))
            capitan?.run(animation, withKey: "walk")
        }
        
        let moveActionForward = SKAction.moveTo(x: 500, duration: 3)
        let moveActionTop = SKAction.move(to: CGPoint(x: 602, y: 131), duration: 1)
        
        let doneAction = SKAction.run({ [weak self] in
            self?.goToNextLevel()
        })
        
        let moveActionWithDone = SKAction.sequence([moveActionForward, moveActionTop, doneAction])
        capitan?.run(moveActionWithDone, withKey: "capitanMoving")
    }
    
    func goToNextLevel() {
        guard let box = getChild( "box") as? SKSpriteNode else {return}
        box.texture = SKTexture(imageNamed: "dark-wood-open")
        self.capitan?.removeAllActions()
        self.speak(text: "Ура. Ты выйграл!")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
            
            //self.reinit()
            self.moveMaster(-660)
            
            if self.capitan?.action(forKey: "walk") == nil {
                let animation = SKAction.repeatForever(SKAction.animate(with: self.getTexturesByAtlas("walk"), timePerFrame: 0.1))
                self.capitan?.run(animation, withKey: "walk")
            }
            
            let move = SKAction.move(to: CGPoint(x: 660, y: 131), duration: 1)
            let moveToBottom = SKAction.move(to: CGPoint(x: 750, y: 100), duration: 1)
            
            let doneAction = SKAction.run({ [weak self] in
                self?.restCapitan()
            })
            
            self.capitan?.run(SKAction.sequence([move, moveToBottom, doneAction]))
        })
    }
    
    func demo() {
        DispatchQueue.main.async {
            self.speak(text: "Привет, мой друг! Тебе нужно добраться до сундука на другой стороне острова. Помоги капитану отгадать все буквы.")
        }
    
        let offset:CGFloat = 667 * 2
        let actions = SKAction.sequence([SKAction.moveTo(x: -offset, duration: 5), SKAction.moveTo(x: 0, duration: 5)])
        
        master?.run(actions)
        
    }
    
    func moveMaster(_ offset: CGFloat) {
        
       
        master?.run( SKAction.moveTo(x: offset, duration: 3))
        //let p = self.master!.position
        //self.master?.position = CGPoint(x: p.x + offset, y: p.y)
    }
    
    func onFinish() {
        moveCapitanToFinish()
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
}
