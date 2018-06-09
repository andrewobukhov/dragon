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
        initCapitan()
        initGrounds()
        initBox()
        shuffleLetters()
    }
    
    func initCapitan() {
        guard let capitan = self.childNode(withName: "capitan") as? SKSpriteNode else {return}
        self.capitan = capitan
        self.capitan?.position = CGPoint(x: 53, y: 127)
        
        
        let animation = SKAction.repeatForever(SKAction.animate(with: getTexturesByAtlas("rest"), timePerFrame: 0.1))
        self.capitan?.removeAllActions()
        self.capitan?.run(animation, withKey: "rest")
    }
    
    func initBox() {
        guard let box = self.childNode(withName: "box") as? SKSpriteNode else {return}
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
    
    func initGrounds() {
        self.grounds = []
        for i in 0 ..< 4 {
            if let g = self.childNode(withName: "ground\(i + 1)") as? SKSpriteNode {
                moveGround(node: g, shift: 50, duration: (Double(i) / 2.0) + 1)
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
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                self.speak(text: self.currentLetter)
            })
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
            let location = touch.location(in: self)
            
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
    
        ground.run(SKAction.moveTo(y: CGFloat(55), duration: 1))
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
        let moveActionTop = SKAction.move(to: CGPoint(x: 560, y: 141), duration: 1)
        
        let doneAction = SKAction.run({ [weak self] in
            self?.goToNextLevel()
        })
        
        let moveActionWithDone = SKAction.sequence([moveActionForward, moveActionTop, doneAction])
        capitan?.run(moveActionWithDone, withKey: "capitanMoving")
    }
    
    func goToNextLevel() {
        guard let box = self.childNode(withName: "box") as? SKSpriteNode else {return}
        box.texture = SKTexture(imageNamed: "dark-wood-open")
        self.capitan?.removeAllActions()
        self.speak(text: "Ура. Ты выйграл!")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
            self.reinit()
        })
    }
    
    func onFinish() {
        moveCapitanToFinish()
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
}
